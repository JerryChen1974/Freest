// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
@testable import FreestCore

// Self-contained test doubles conforming to the FreestCore protocols. These
// need no real audio, model, or OS access, so the core state machine is fully
// unit-testable in isolation.

/// A fake microphone that records nothing but a canned `AudioFile`, and can be
/// told to fail on `start` or `stop`.
final class FakeCapture: AudioCapturing, @unchecked Sendable {
    let audio: AudioFile
    let startError: DictationError?
    let stopError: DictationError?

    init(
        audio: AudioFile = AudioFile(url: URL(fileURLWithPath: "/tmp/fake.wav"),
                                     sampleRate: 16_000, channels: 1, durationMs: 1_000),
        startError: DictationError? = nil,
        stopError: DictationError? = nil
    ) {
        self.audio = audio
        self.startError = startError
        self.stopError = stopError
    }

    func start() async throws {
        if let startError { throw startError }
    }

    func stop() async throws -> AudioFile {
        if let stopError { throw stopError }
        return audio
    }
}

/// A fake ASR engine returning canned text, or throwing.
final class FakeEngine: ASREngine, @unchecked Sendable {
    let transcript: Transcript
    let error: Error?

    init(text: String = "hello world", modelId: String = "base", error: Error? = nil) {
        self.transcript = Transcript(text: text, modelId: modelId)
        self.error = error
    }

    func transcribe(_ audio: AudioFile) async throws -> Transcript {
        if let error { throw error }
        return transcript
    }
}

/// A fake refiner: by default upper-cases the text (so a change is observable),
/// or throws.
final class FakeRefiner: Refiner, @unchecked Sendable {
    let mode: RefinementMode
    let error: Error?
    let transform: @Sendable (String) -> String

    init(
        mode: RefinementMode = .tidy,
        error: Error? = nil,
        transform: @escaping @Sendable (String) -> String = { $0.uppercased() }
    ) {
        self.mode = mode
        self.error = error
        self.transform = transform
    }

    func refine(_ transcript: Transcript) async throws -> RefinedText {
        if let error { throw error }
        return RefinedText(text: transform(transcript.text), mode: mode)
    }
}

/// A fake sink that records what it was asked to deliver, or throws. An actor,
/// so its recording buffer is race-free under Swift 6 strict concurrency.
actor FakeSink: Sink {
    private(set) var delivered: [RefinedText] = []
    let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func deliver(_ text: RefinedText) async throws {
        if let error { throw error }
        delivered.append(text)
    }
}

/// A clock that returns a fixed instant, for deterministic timestamps.
struct FixedClock: Clock {
    let instant: Date
    init(_ instant: Date = Date(timeIntervalSince1970: 1_000_000)) { self.instant = instant }
    func now() -> Date { instant }
}

extension DictationSession {
    /// Collect state transitions until `idle` is reached again after the first
    /// non-idle state, or until `max` states have been seen. Used by tests to
    /// assert the transition sequence without hanging on the open stream.
    static func collectStates(
        from stream: AsyncStream<DictationState>,
        max: Int = 16
    ) async -> [DictationState] {
        var result: [DictationState] = []
        var sawNonIdle = false
        for await state in stream {
            result.append(state)
            if state == .idle {
                if sawNonIdle { break }
            } else {
                sawNonIdle = true
            }
            if result.count >= max { break }
        }
        return result
    }
}
