// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import FreestCore

/// The Freest `ASREngine` built on a `TranscriptionBackend`. Owns the policy
/// around models — resolve the id, refuse to transcribe when the model isn't
/// ready, load lazily on first use, and map backend failures onto
/// `DictationError`. The concrete WhisperKit calls live in `WhisperKitBackend`,
/// so everything here is testable with a fake backend.
public actor WhisperKitASREngine: ASREngine {
    private let backend: TranscriptionBackend
    private let catalog: ModelCatalog
    private let readiness: ModelReadiness
    private let modelId: String
    private let modelsDirectory: URL

    private var loaded = false

    public init(
        modelId: String,
        modelsDirectory: URL,
        backend: TranscriptionBackend,
        readiness: ModelReadiness = .system
    ) {
        self.modelId = modelId
        self.modelsDirectory = modelsDirectory
        self.backend = backend
        self.readiness = readiness
        self.catalog = ModelCatalog(modelsDirectory: modelsDirectory)
    }

    /// Whether the selected model's files are present on disk.
    public func isModelReady() -> Bool {
        guard let dir = catalog.directory(for: modelId) else { return false }
        return readiness.isReady(dir)
    }

    /// Ensure the model is loaded, downloading it if `allowDownload` is set. The
    /// composition layer passes `true` only from an explicit user-initiated
    /// download so a stray dictation never triggers a silent multi-hundred-MB
    /// fetch.
    public func prepare(allowDownload: Bool) async throws {
        guard let variant = catalog.variant(for: modelId) else {
            throw DictationError.transcriptionFailed(reason: "unknown model id \"\(modelId)\"")
        }
        if !isModelReady() && !allowDownload {
            throw DictationError.modelNotReady(modelId: modelId)
        }
        do {
            try await backend.loadModel(variant: variant, downloadBase: modelsDirectory)
            loaded = true
        } catch let error as DictationError {
            throw error
        } catch {
            throw DictationError.modelDownloadFailed(reason: String(describing: error))
        }
    }

    public func transcribe(_ audio: AudioFile) async throws -> Transcript {
        // Never attempt to transcribe without a ready, loaded model.
        guard isModelReady() else {
            throw DictationError.modelNotReady(modelId: modelId)
        }
        if !loaded {
            try await prepare(allowDownload: false)
        }
        do {
            let text = try await backend.transcribe(audioAt: audio.url)
            return Transcript(text: text, modelId: modelId, durationMs: audio.durationMs)
        } catch let error as DictationError {
            throw error
        } catch {
            throw DictationError.transcriptionFailed(reason: String(describing: error))
        }
    }
}
