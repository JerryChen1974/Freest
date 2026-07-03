// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import AVFoundation
import FreestCore

/// An `AudioCapturing` implementation backed by `AVAudioRecorder`, writing a
/// 16 kHz mono WAV to a temporary file. Being an actor serializes start/stop so
/// the recorder handle is never touched concurrently.
///
/// This type is OS-gated (it needs a real microphone and TCC permission), so it
/// is exercised by the manual smoke test rather than unit tests; its pure
/// configuration logic lives in `AudioCaptureConfig`, which *is* unit-tested.
public actor MicrophoneCapture: AudioCapturing {
    private let config: AudioCaptureConfig
    private let outputDirectory: URL

    private var recorder: AVAudioRecorder?
    private var currentURL: URL?
    private var startedAt: Date?

    public init(config: AudioCaptureConfig = AudioCaptureConfig(),
                outputDirectory: URL = FileManager.default.temporaryDirectory) {
        self.config = config
        self.outputDirectory = outputDirectory
    }

    public func start() async throws {
        guard recorder == nil else {
            throw DictationError.audioCaptureFailed(reason: "already recording")
        }
        let settings = try config.recorderSettings()
        let url = outputDirectory.appending(
            path: "freest-\(UUID().uuidString).wav", directoryHint: .notDirectory
        )
        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            guard recorder.record() else {
                throw DictationError.audioCaptureFailed(reason: "recorder failed to start")
            }
            self.recorder = recorder
            self.currentURL = url
            self.startedAt = Date()
        } catch let error as DictationError {
            throw error
        } catch {
            throw DictationError.audioCaptureFailed(reason: String(describing: error))
        }
    }

    public func stop() async throws -> AudioFile {
        guard let recorder, let url = currentURL else {
            throw DictationError.audioCaptureFailed(reason: "not recording")
        }
        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        self.currentURL = nil
        let started = startedAt
        self.startedAt = nil

        // A wall-clock fallback covers the case where currentTime reads 0.
        let elapsedMs: Int
        if duration > 0 {
            elapsedMs = Int(duration * 1000)
        } else if let started {
            elapsedMs = Int(Date().timeIntervalSince(started) * 1000)
        } else {
            elapsedMs = 0
        }

        return AudioFile(
            url: url,
            sampleRate: config.sampleRate,
            channels: config.channels,
            durationMs: elapsedMs
        )
    }
}
