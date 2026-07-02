// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import Testing
@testable import FreestCore

@Suite("DictationSession state machine")
struct DictationSessionTests {

    private func makeSession(
        capture: AudioCapturing = FakeCapture(),
        engine: ASREngine = FakeEngine(),
        refiner: Refiner = FakeRefiner(),
        sink: FakeSink = FakeSink()
    ) -> (DictationSession, FakeSink) {
        let session = DictationSession(
            capture: capture, engine: engine, refiner: refiner, sink: sink,
            clock: FixedClock()
        )
        return (session, sink)
    }

    @Test("happy path runs idle → recording → transcribing → refining → outputting → idle")
    func happyPath() async {
        let (session, sink) = makeSession()

        await session.start()
        #expect(await session.currentState == .recording)

        let refined = await session.finish()
        #expect(await session.currentState == .idle)

        // The refiner upper-cased the fake engine's "hello world".
        #expect(refined?.text == "HELLO WORLD")
        #expect(await sink.delivered.map(\.text) == ["HELLO WORLD"])

        let states = await DictationSession.collectStates(from: session.states)
        #expect(states == [.idle, .recording, .transcribing, .refining, .outputting, .idle])
    }

    @Test("start is a no-op unless idle")
    func startOnlyFromIdle() async {
        let (session, _) = makeSession()
        await session.start()
        #expect(await session.currentState == .recording)
        // Second start should be ignored, state stays recording.
        await session.start()
        #expect(await session.currentState == .recording)
    }

    @Test("finish is a no-op unless recording")
    func finishOnlyFromRecording() async {
        let (session, sink) = makeSession()
        let result = await session.finish()   // called from idle
        #expect(result == nil)
        #expect(await session.currentState == .idle)
        #expect(await sink.delivered.isEmpty)
    }

    @Test("cancel from recording returns to idle without delivering")
    func cancelFromRecording() async {
        let (session, sink) = makeSession()
        await session.start()
        await session.cancel()
        #expect(await session.currentState == .idle)
        #expect(await sink.delivered.isEmpty)

        let states = await DictationSession.collectStates(from: session.states)
        #expect(states == [.idle, .recording, .idle])
    }

    @Test("cancel from idle is a no-op")
    func cancelFromIdle() async {
        let (session, _) = makeSession()
        await session.cancel()
        #expect(await session.currentState == .idle)
    }

    @Test("capture start failure publishes error then returns to idle")
    func startFailurePublishesError() async {
        let (session, _) = makeSession(
            capture: FakeCapture(startError: .microphonePermissionDenied)
        )
        await session.start()
        #expect(await session.currentState == .idle)

        let states = await DictationSession.collectStates(from: session.states)
        #expect(states == [.idle, .error(.microphonePermissionDenied), .idle])
    }

    @Test("transcription failure publishes error then returns to idle")
    func transcriptionFailurePublishesError() async {
        let (session, sink) = makeSession(
            engine: FakeEngine(error: DictationError.transcriptionFailed(reason: "boom"))
        )
        await session.start()
        _ = await session.finish()
        #expect(await session.currentState == .idle)
        #expect(await sink.delivered.isEmpty)

        let states = await DictationSession.collectStates(from: session.states)
        #expect(states == [
            .idle, .recording, .transcribing,
            .error(.transcriptionFailed(reason: "boom")), .idle
        ])
    }

    @Test("a non-DictationError from a stage is mapped to a DictationError")
    func nonDictationErrorIsMapped() async {
        struct Weird: Error {}
        let (session, _) = makeSession(engine: FakeEngine(error: Weird()))
        await session.start()
        _ = await session.finish()
        #expect(await session.currentState == .idle)

        let states = await DictationSession.collectStates(from: session.states)
        // Only assert that an error was published (the wrapped reason is opaque).
        let hadError = states.contains {
            if case .error = $0 { return true } else { return false }
        }
        #expect(hadError)
    }
}
