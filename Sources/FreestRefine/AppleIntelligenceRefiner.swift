// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import FreestCore

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Probes the on-device Apple Intelligence language model's availability.
/// Isolated so the availability check and the refiner can share one code path
/// guarded by `#if canImport(FoundationModels)`.
enum AppleIntelligenceProbe {
    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    static func isModelAvailable() -> Bool {
        // `SystemLanguageModel.default.availability` reports whether the model
        // is ready (device eligible, assets downloaded, feature enabled).
        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        default:
            return false
        }
    }
    #endif
}

/// A `Refiner` that cleans up a transcript using Apple's on-device language
/// model (FoundationModels, macOS 26+ / Apple Silicon). If the model is
/// unavailable at runtime — or the framework isn't present at compile time —
/// it falls back to local `TextTidier` rules and reports `.tidy`, so callers
/// always get usable output and the fallback is observable.
public struct AppleIntelligenceRefiner: Refiner {
    private let availability: RefinementAvailability
    private let fallback = TidyRefiner()

    public init(availability: RefinementAvailability = .system) {
        self.availability = availability
    }

    public func refine(_ transcript: FreestCore.Transcript) async throws -> RefinedText {
        guard availability.isAppleIntelligenceAvailable() else {
            // Not available → local rules, tagged .tidy so the UI can show the
            // effective mode.
            return try await fallback.refine(transcript)
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            do {
                let cleaned = try await Self.runModel(on: transcript.text)
                return RefinedText(text: cleaned, mode: .appleIntelligence)
            } catch {
                // Any model error → degrade gracefully to local rules rather
                // than failing the whole dictation.
                return try await fallback.refine(transcript)
            }
        } else {
            return try await fallback.refine(transcript)
        }
        #else
        return try await fallback.refine(transcript)
        #endif
    }

    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private static func runModel(on text: String) async throws -> String {
        let instructions = """
        You clean up dictated text. Fix capitalization, punctuation, and obvious \
        transcription slips. Do not add, remove, or reinterpret content. Return \
        only the cleaned text.
        """
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: text)
        let cleaned = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? text : cleaned
    }
    #endif
}
