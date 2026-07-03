// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import AVFoundation
import FreestCore

/// The recording parameters Freest uses, plus the pure logic to turn them into
/// an `AVAudioRecorder` settings dictionary. Kept separate from the recorder
/// actor so the settings-building and validation are unit-testable without any
/// audio hardware.
public struct AudioCaptureConfig: Sendable, Equatable {
    /// Whisper models expect 16 kHz mono PCM.
    public var sampleRate: Int
    public var channels: Int
    /// Optional preferred input device unique id (nil = system default).
    public var inputDeviceUID: String?

    public init(sampleRate: Int = 16_000, channels: Int = 1, inputDeviceUID: String? = nil) {
        self.sampleRate = sampleRate
        self.channels = channels
        self.inputDeviceUID = inputDeviceUID
    }

    /// Validate the configuration, throwing a `DictationError.audioCaptureFailed`
    /// for nonsensical values before any recorder is created.
    public func validate() throws {
        guard sampleRate > 0 else {
            throw DictationError.audioCaptureFailed(reason: "sample rate must be positive")
        }
        guard channels == 1 || channels == 2 else {
            throw DictationError.audioCaptureFailed(reason: "channels must be 1 or 2")
        }
    }

    /// The `AVAudioRecorder` settings dictionary for a 16-bit Linear PCM WAV.
    public func recorderSettings() throws -> [String: Any] {
        try validate()
        return [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: Double(sampleRate),
            AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
    }

    /// Build a config from user `Settings` (carries the chosen input device).
    public init(settings: Settings) {
        self.init(sampleRate: 16_000, channels: 1, inputDeviceUID: settings.inputDeviceUID)
    }
}
