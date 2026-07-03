// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import FreestCore
import WhisperKit

/// The concrete `TranscriptionBackend` over WhisperKit. This is the *only* file
/// that imports WhisperKit; everything else in `FreestASR` is written against
/// the `TranscriptionBackend` protocol and is unit-tested with a fake. Written
/// from the WhisperKit public API (README + source docs).
///
/// Implemented as a `final class` (rather than an actor) because WhisperKit
/// manages its own internal concurrency and exposes a nonisolated `transcribe`.
/// Serialization of load/transcribe is provided by the `WhisperKitASREngine`
/// actor that owns this backend, so `@unchecked Sendable` is safe here.
public final class WhisperKitBackend: TranscriptionBackend, @unchecked Sendable {
    private var whisperKit: WhisperKit?

    public init() {}

    public func loadModel(variant: String, downloadBase: URL) async throws {
        // Configure WhisperKit to keep model files under Freest's own models
        // directory and load the requested variant. WhisperKit downloads the
        // variant on demand if it isn't already present under `downloadBase`.
        let config = WhisperKitConfig(
            model: variant,
            downloadBase: downloadBase,
            load: true
        )
        whisperKit = try await WhisperKit(config)
    }

    public func transcribe(audioAt url: URL) async throws -> String {
        guard let whisperKit else {
            throw DictationError.transcriptionFailed(reason: "model not loaded")
        }
        let results = try await whisperKit.transcribe(audioPath: url.path)
        // Join the per-window results into a single string and tidy the edges.
        return results.map(\.text).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
