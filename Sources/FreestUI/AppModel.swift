// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import Observation
import FreestCore

/// The observable state the UI binds to. It owns the user `Settings`, the latest
/// `DictationState`, and model-download progress, and forwards user intents to
/// the injected controller. Kept free of concrete infra types so it can be
/// exercised in previews and (via `AppController`) driven by real or fake infra.
@MainActor
@Observable
public final class AppModel {

    /// Model download progress, surfaced in the menu and Settings.
    public enum ModelState: Sendable, Equatable {
        case unknown
        case ready
        case missing
        case downloading(fraction: Double)
        case failed(String)
    }

    public private(set) var dictationState: DictationState = .idle
    public private(set) var modelState: ModelState = .unknown
    public var settings: Settings

    /// Whether Apple Intelligence refinement is actually effective on this
    /// machine (used to annotate the menu choice).
    public var appleIntelligenceEffective: Bool = false

    private var controller: any AppControlling

    public init(settings: Settings, controller: any AppControlling) {
        self.settings = settings
        self.controller = controller
    }

    /// Replace the controller. Used by the composition root to swap in the real
    /// controller (`self`) once it has finished initializing, since the model
    /// must exist before the controller that references it.
    public func rebind(to controller: any AppControlling) {
        self.controller = controller
    }

    // MARK: - State updates (called by the controller)

    public func setDictationState(_ state: DictationState) {
        dictationState = state
    }

    public func setModelState(_ state: ModelState) {
        modelState = state
    }

    // MARK: - Derived view state

    public var isBusy: Bool {
        dictationState != .idle
    }

    public var statusText: String {
        switch dictationState {
        case .idle: return "Ready"
        case .recording: return "Listening…"
        case .transcribing: return "Transcribing…"
        case .refining: return "Refining…"
        case .outputting: return "Pasting…"
        case .error(let error): return error.errorDescription ?? "Error"
        }
    }

    // MARK: - User intents (forwarded to the controller)

    public func downloadModel() {
        controller.downloadSelectedModel()
    }

    public func updateSettings(_ transform: (inout Settings) -> Void) {
        transform(&settings)
        controller.settingsChanged(settings)
    }

    public func openSettings() {
        controller.openSettings()
    }

    public func quit() {
        controller.quit()
    }
}

/// The intents the UI can trigger. Implemented by `AppController` in `FreestApp`
/// (the composition root); a fake conformer drives previews/tests.
@MainActor
public protocol AppControlling: AnyObject {
    func downloadSelectedModel()
    func settingsChanged(_ settings: FreestCore.Settings)
    func openSettings()
    func quit()
}
