// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import AVFoundation
import Testing
@testable import FreestAudio
import FreestCore

@Suite("AudioCaptureConfig")
struct AudioCaptureConfigTests {

    @Test("defaults are 16 kHz mono")
    func defaults() {
        let config = AudioCaptureConfig()
        #expect(config.sampleRate == 16_000)
        #expect(config.channels == 1)
        #expect(config.inputDeviceUID == nil)
    }

    @Test("recorderSettings reflect the config for a 16-bit PCM WAV")
    func recorderSettings() throws {
        let config = AudioCaptureConfig(sampleRate: 16_000, channels: 1)
        let settings = try config.recorderSettings()
        #expect(settings[AVSampleRateKey] as? Double == 16_000)
        #expect(settings[AVNumberOfChannelsKey] as? Int == 1)
        #expect(settings[AVLinearPCMBitDepthKey] as? Int == 16)
        #expect(settings[AVFormatIDKey] as? Int == Int(kAudioFormatLinearPCM))
    }

    @Test("invalid sample rate is rejected as an audio capture error")
    func invalidSampleRate() {
        let config = AudioCaptureConfig(sampleRate: 0, channels: 1)
        #expect(throws: DictationError.audioCaptureFailed(reason: "sample rate must be positive")) {
            try config.validate()
        }
    }

    @Test("invalid channel count is rejected")
    func invalidChannels() {
        let config = AudioCaptureConfig(sampleRate: 16_000, channels: 3)
        #expect(throws: DictationError.audioCaptureFailed(reason: "channels must be 1 or 2")) {
            try config.validate()
        }
    }

    @Test("config built from Settings carries the input device")
    func fromSettings() {
        var settings = Settings.defaults
        settings.inputDeviceUID = "usb-mic-1"
        let config = AudioCaptureConfig(settings: settings)
        #expect(config.inputDeviceUID == "usb-mic-1")
        #expect(config.sampleRate == 16_000)
    }
}
