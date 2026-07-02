// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// The observable state of a dictation run.
///
/// Happy path: `idle → recording → transcribing → refining → outputting → idle`.
/// `cancel()` from any non-idle state returns to `idle`. Any failure publishes
/// `.error` and then returns to `idle`.
public enum DictationState: Sendable, Equatable {
    case idle
    case recording
    case transcribing
    case refining
    case outputting
    case error(DictationError)
}

/// Orchestrates one dictation run over injected infrastructure. This lives in
/// the core (not the UI) so both the menu-bar app and a future CLI drive the
/// exact same state machine; each just consumes `states` and calls the same
/// three methods.
///
/// It is an `actor`, so its state transitions are serialized and free of data
/// races. State changes are published through the `states` async stream.
public actor DictationSession {
    private let capture: AudioCapturing
    private let engine: ASREngine
    private let refiner: Refiner
    private let sink: Sink
    private let clock: Clock

    private var state: DictationState = .idle
    private let continuation: AsyncStream<DictationState>.Continuation

    /// A stream of state changes, beginning with the current state. UI and CLI
    /// frontends observe this to reflect progress.
    public nonisolated let states: AsyncStream<DictationState>

    public init(
        capture: AudioCapturing,
        engine: ASREngine,
        refiner: Refiner,
        sink: Sink,
        clock: Clock = SystemClock()
    ) {
        self.capture = capture
        self.engine = engine
        self.refiner = refiner
        self.sink = sink
        self.clock = clock

        var cont: AsyncStream<DictationState>.Continuation!
        self.states = AsyncStream { cont = $0 }
        self.continuation = cont
        // Publish the initial state so a subscriber sees `idle` immediately.
        self.continuation.yield(.idle)
    }

    /// The current state (mainly for tests and diagnostics).
    public var currentState: DictationState { state }

    private func transition(to newState: DictationState) {
        state = newState
        continuation.yield(newState)
    }

    /// Begin recording. No-op unless currently idle.
    public func start() async {
        guard state == .idle else { return }
        do {
            try await capture.start()
            transition(to: .recording)
        } catch {
            fail(with: error)
        }
    }

    /// Stop recording and run the transcribe → refine → deliver flow. No-op
    /// unless currently recording. Returns the delivered text on success, or
    /// nil if the run did not complete (wrong state or an error was published).
    @discardableResult
    public func finish() async -> RefinedText? {
        guard state == .recording else { return nil }
        do {
            let audio = try await capture.stop()

            transition(to: .transcribing)
            let transcript = try await engine.transcribe(audio)

            transition(to: .refining)
            let refined = try await refiner.refine(transcript)

            transition(to: .outputting)
            try await sink.deliver(refined)

            transition(to: .idle)
            return refined
        } catch {
            fail(with: error)
            return nil
        }
    }

    /// Cancel an in-progress run. From any non-idle state this returns to idle;
    /// idle is left unchanged. Best-effort: a capture stop failure during
    /// cancellation is ignored, since the user asked to abort anyway.
    public func cancel() async {
        guard state != .idle else { return }
        if state == .recording {
            _ = try? await capture.stop()
        }
        transition(to: .idle)
    }

    /// Publish an error, then return to idle. A cancellation surfaces as `.idle`
    /// rather than an error state.
    private func fail(with error: Error) {
        let mapped = Pipeline<Void, Void>.mapError(error)
        if mapped == .cancelled {
            transition(to: .idle)
            return
        }
        transition(to: .error(mapped))
        transition(to: .idle)
    }
}
