// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
@testable import FreestASR
import FreestCore

/// A fake `TranscriptionBackend` that records calls and returns canned results,
/// so `WhisperKitASREngine`'s readiness/download/error logic is testable with no
/// network and no Core ML models.
actor FakeBackend: TranscriptionBackend {
    private(set) var loadCalls: [(variant: String, base: URL)] = []
    private(set) var transcribeCalls: [URL] = []

    let cannedText: String
    let loadError: Error?
    let transcribeError: Error?

    init(cannedText: String = "hello world",
         loadError: Error? = nil,
         transcribeError: Error? = nil) {
        self.cannedText = cannedText
        self.loadError = loadError
        self.transcribeError = transcribeError
    }

    func loadModel(variant: String, downloadBase: URL) async throws {
        loadCalls.append((variant, downloadBase))
        if let loadError { throw loadError }
    }

    func transcribe(audioAt url: URL) async throws -> String {
        transcribeCalls.append(url)
        if let transcribeError { throw transcribeError }
        return cannedText
    }
}

extension ModelReadiness {
    /// Test helper: pretend a model is always ready / never ready.
    static let alwaysReady = ModelReadiness { _ in true }
    static let neverReady = ModelReadiness { _ in false }
}
