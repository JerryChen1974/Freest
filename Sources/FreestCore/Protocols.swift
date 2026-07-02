// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// Captures microphone audio to a file. Implemented by the audio module over
/// AVFoundation; faked in tests. `start()` begins recording; `stop()` finalizes
/// and returns the recorded clip.
public protocol AudioCapturing: Sendable {
    func start() async throws
    func stop() async throws -> AudioFile
}

/// Turns a recorded clip into text. Implemented by the ASR module over
/// WhisperKit; faked in tests.
public protocol ASREngine: Sendable {
    func transcribe(_ audio: AudioFile) async throws -> Transcript
}

/// Cleans up a transcript. Implementations range from a no-op (`.off`) to local
/// rules to an on-device LLM. A refiner reports the mode it actually applied so
/// a fallback (e.g. AI unavailable → tidy) is observable.
public protocol Refiner: Sendable {
    func refine(_ transcript: Transcript) async throws -> RefinedText
}

/// Delivers final text somewhere: pasted at the cursor, appended to a file,
/// written to a daily note, or (for a future CLI) printed to stdout.
public protocol Sink: Sendable {
    func deliver(_ text: RefinedText) async throws
}

/// A source of the current time, injected so time-dependent logic (e.g. history
/// timestamps) is deterministic in tests.
public protocol Clock: Sendable {
    func now() -> Date
}

/// The real system clock.
public struct SystemClock: Clock {
    public init() {}
    public func now() -> Date { Date() }
}
