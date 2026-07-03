// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import AppKit
import SwiftUI
import FreestCore
import FreestAudio
import FreestASR
import FreestRefine
import FreestStorage
import FreestOutput
import FreestPermissions
import FreestHotkey
import FreestIndicator
import FreestUI

/// The composition root. Constructs every infrastructure implementation, injects
/// them into a `DictationSession`, and wires the hotkey → session → indicator
/// flows. This is the only place concrete infra types meet; every module below
/// it depends solely on `FreestCore` protocols.
@MainActor
public final class AppController: AppControlling {
    public let model: AppModel

    private let settingsStore: SettingsStore
    private let transcriptStore: TranscriptLogStore
    private let permissions = Permissions()
    private let hotkey = HotkeyMonitor()
    private let indicator = IndicatorPanel()
    private let locations: StorageLocations
    private let clock = SystemClock()

    private var asrEngine: WhisperKitASREngine
    private let backend = WhisperKitBackend()
    private var session: DictationSession?
    private var settingsWindow: NSWindow?

    public init() {
        let locations = StorageLocations.defaults()
        self.locations = locations
        self.settingsStore = SettingsStore(locations: locations)
        // Load settings synchronously up front so the first UI render is correct.
        let loaded = (try? Self.loadSettingsSync(locations: locations)) ?? .defaults
        self.transcriptStore = TranscriptLogStore(locations: locations, limit: loaded.historyLimit)
        self.asrEngine = WhisperKitASREngine(
            modelId: loaded.selectedModelId,
            modelsDirectory: locations.modelsDirectory,
            backend: backend
        )

        let availability = RefinementAvailability.system
        let model = AppModel(settings: loaded, controller: PlaceholderControlling())
        model.appleIntelligenceEffective = availability.isAppleIntelligenceAvailable()
        self.model = model
        // Now that self exists, become the real controller.
        model.rebind(to: self)
    }

    /// Start the app's runtime flows: hotkey registration, state observation,
    /// permission prompts, and model-readiness check.
    public func start() {
        hotkey.start(chord: model.settings.hotkey)
        observeHotkey()
        refreshModelState()
        Task { await requestPermissionsIfNeeded() }
    }

    // MARK: - AppControlling

    public func downloadSelectedModel() {
        model.setModelState(.downloading(fraction: 0))
        Task {
            do {
                try await asrEngine.prepare(allowDownload: true)
                refreshModelState()
            } catch {
                let reason = (error as? DictationError)?.errorDescription ?? "\(error)"
                model.setModelState(.failed(reason))
            }
        }
    }

    public func settingsChanged(_ settings: FreestCore.Settings) {
        Task { try? await settingsStore.save(settings) }
        hotkey.setChord(settings.hotkey)
        // Rebuild the ASR engine if the selected model changed.
        asrEngine = WhisperKitASREngine(
            modelId: settings.selectedModelId,
            modelsDirectory: locations.modelsDirectory,
            backend: backend
        )
        refreshModelState()
    }

    public func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let hosting = NSHostingController(rootView: SettingsView(model: model))
        let window = NSWindow(contentViewController: hosting)
        window.title = "Freest Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        settingsWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func quit() {
        hotkey.stop()
        NSApp.terminate(nil)
    }

    // MARK: - Runtime flows

    private func observeHotkey() {
        Task { [weak self] in
            guard let self else { return }
            for await event in self.hotkey.events {
                await self.handle(event)
            }
        }
    }

    private func handle(_ event: HotkeyEvent) async {
        switch event {
        case .pressed:
            guard await asrEngine.isModelReady() else {
                model.setModelState(.missing)
                return
            }
            let session = makeSession()
            self.session = session
            observeState(of: session)
            await session.start()
        case .released:
            await session?.finish()
        }
    }

    private func makeSession() -> DictationSession {
        let config = AudioCaptureConfig(settings: model.settings)
        let capture = MicrophoneCapture(config: config)
        let refiner = RefinerFactory(availability: .system)
            .makeRefiner(for: model.settings.refinementMode)
        let sink = PasteSink(submitAfterPaste: model.settings.submitAfterPaste)
        return DictationSession(
            capture: capture, engine: asrEngine, refiner: refiner, sink: sink, clock: clock
        )
    }

    private func observeState(of session: DictationSession) {
        Task { [weak self] in
            for await state in session.states {
                guard let self else { return }
                self.model.setDictationState(state)
                self.indicator.update(for: state)
            }
        }
    }

    private func refreshModelState() {
        Task { [weak self] in
            guard let self else { return }
            let ready = await self.asrEngine.isModelReady()
            self.model.setModelState(ready ? .ready : .missing)
        }
    }

    private func requestPermissionsIfNeeded() async {
        _ = await permissions.requestMicrophone()
        if permissions.accessibilityStatus() != .granted {
            _ = permissions.requestAccessibility()
        }
    }

    // MARK: - Helpers

    private static func loadSettingsSync(locations: StorageLocations) throws -> FreestCore.Settings {
        let url = locations.settingsFile
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return .defaults }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FreestCore.Settings.self, from: data)
    }
}

/// A no-op `AppControlling` used only to construct `AppModel` before the real
/// controller (`self`) is fully initialized; immediately replaced via `rebind`.
@MainActor
private final class PlaceholderControlling: AppControlling {
    func downloadSelectedModel() {}
    func settingsChanged(_ settings: FreestCore.Settings) {}
    func openSettings() {}
    func quit() {}
}
