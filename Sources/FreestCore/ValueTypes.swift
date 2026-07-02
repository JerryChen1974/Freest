// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// A recorded audio clip on disk, ready to be transcribed.
///
/// Freest records mono 16 kHz audio (the input Whisper models expect), but the
/// shape is kept general so the recorder can describe whatever it produced.
public struct AudioFile: Sendable, Equatable {
    public let url: URL
    public let sampleRate: Int
    public let channels: Int
    public let durationMs: Int?

    public init(url: URL, sampleRate: Int, channels: Int, durationMs: Int? = nil) {
        self.url = url
        self.sampleRate = sampleRate
        self.channels = channels
        self.durationMs = durationMs
    }
}

/// The raw result of speech-to-text: the recognized text plus the model that
/// produced it.
public struct Transcript: Sendable, Equatable {
    public let text: String
    public let modelId: String
    public let durationMs: Int?

    public init(text: String, modelId: String, durationMs: Int? = nil) {
        self.text = text
        self.modelId = modelId
        self.durationMs = durationMs
    }
}

/// Text after the (optional) refinement stage, tagged with the mode that
/// produced it. When refinement is off, `text` equals the transcript text and
/// `mode` is `.off`.
public struct RefinedText: Sendable, Equatable {
    public let text: String
    public let mode: RefinementMode

    public init(text: String, mode: RefinementMode) {
        self.text = text
        self.mode = mode
    }
}

/// A press/release edge from the global hotkey.
public enum HotkeyEvent: Sendable, Equatable {
    case pressed
    case released
}
