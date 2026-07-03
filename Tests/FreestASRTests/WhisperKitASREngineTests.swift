// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import Testing
@testable import FreestASR
import FreestCore

@Suite("WhisperKitASREngine readiness, download policy, and error mapping")
struct WhisperKitASREngineTests {

    private let modelsDir = URL(fileURLWithPath: "/support/Freest/models")
    private let audio = AudioFile(
        url: URL(fileURLWithPath: "/tmp/clip.wav"),
        sampleRate: 16_000, channels: 1, durationMs: 1_200
    )

    private func engine(
        modelId: String = "base",
        backend: FakeBackend = FakeBackend(),
        readiness: ModelReadiness
    ) -> WhisperKitASREngine {
        WhisperKitASREngine(
            modelId: modelId, modelsDirectory: modelsDir,
            backend: backend, readiness: readiness
        )
    }

    @Test("transcribe succeeds when the model is ready")
    func transcribeWhenReady() async throws {
        let backend = FakeBackend(cannedText: "the quick brown fox")
        let asr = engine(backend: backend, readiness: .alwaysReady)

        let transcript = try await asr.transcribe(audio)
        #expect(transcript.text == "the quick brown fox")
        #expect(transcript.modelId == "base")
        #expect(transcript.durationMs == 1_200)
        // The variant passed to the backend must be the mapped WhisperKit id.
        let loads = await backend.loadCalls
        #expect(loads.first?.variant == "openai_whisper-base")
    }

    @Test("transcribe with no model on disk fails as modelNotReady, not a crash")
    func transcribeWhenNotReady() async {
        let backend = FakeBackend()
        let asr = engine(backend: backend, readiness: .neverReady)

        await #expect(throws: DictationError.modelNotReady(modelId: "base")) {
            _ = try await asr.transcribe(audio)
        }
        let transcribes = await backend.transcribeCalls
        #expect(transcribes.isEmpty)   // never attempted the backend
    }

    @Test("prepare without a ready model and no download permission is modelNotReady")
    func prepareRefusesSilentDownload() async {
        let asr = engine(readiness: .neverReady)
        await #expect(throws: DictationError.modelNotReady(modelId: "base")) {
            try await asr.prepare(allowDownload: false)
        }
    }

    @Test("prepare with allowDownload loads the variant")
    func prepareDownloads() async throws {
        let backend = FakeBackend()
        let asr = engine(backend: backend, readiness: .neverReady)
        try await asr.prepare(allowDownload: true)
        let loads = await backend.loadCalls
        #expect(loads.first?.variant == "openai_whisper-base")
        #expect(loads.first?.base == modelsDir)
    }

    @Test("a load failure during download maps to modelDownloadFailed")
    func downloadFailureMapped() async {
        struct Net: Error {}
        let backend = FakeBackend(loadError: Net())
        let asr = engine(backend: backend, readiness: .neverReady)
        await #expect(throws: DictationError.self) {
            do {
                try await asr.prepare(allowDownload: true)
            } catch let error as DictationError {
                if case .modelDownloadFailed = error { throw error }
                Issue.record("expected modelDownloadFailed, got \(error)")
                return
            }
        }
    }

    @Test("a backend transcription failure maps to transcriptionFailed")
    func transcribeFailureMapped() async {
        struct Boom: Error {}
        let backend = FakeBackend(transcribeError: Boom())
        let asr = engine(backend: backend, readiness: .alwaysReady)
        do {
            _ = try await asr.transcribe(audio)
            Issue.record("expected an error")
        } catch let error as DictationError {
            if case .transcriptionFailed = error { /* expected */ }
            else { Issue.record("unexpected case: \(error)") }
        } catch {
            Issue.record("not mapped to DictationError: \(error)")
        }
    }

    @Test("an unknown model id is a clear transcription error")
    func unknownModelId() async {
        let asr = engine(modelId: "bogus", readiness: .alwaysReady)
        await #expect(throws: DictationError.self) {
            try await asr.prepare(allowDownload: true)
        }
    }
}
