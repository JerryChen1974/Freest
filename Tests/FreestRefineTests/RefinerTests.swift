// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import Testing
@testable import FreestRefine
import FreestCore

@Suite("Refiners and factory routing")
struct RefinerTests {

    private func transcript(_ text: String) -> Transcript {
        Transcript(text: text, modelId: "base", durationMs: nil)
    }

    @Test("PassthroughRefiner returns text unchanged, tagged .off")
    func passthrough() async throws {
        let refined = try await PassthroughRefiner().refine(transcript("  raw text  "))
        #expect(refined.text == "  raw text  ")
        #expect(refined.mode == .off)
    }

    @Test("TidyRefiner applies rules, tagged .tidy")
    func tidy() async throws {
        let refined = try await TidyRefiner().refine(transcript("um hello world"))
        #expect(refined.text == "Hello world.")
        #expect(refined.mode == .tidy)
    }

    @Test("factory maps .off and .tidy to the right refiners")
    func factoryOffAndTidy() async throws {
        let factory = RefinerFactory(availability: .neverAvailable)

        let off = try await factory.makeRefiner(for: .off).refine(transcript("as is"))
        #expect(off.mode == .off)

        let tidy = try await factory.makeRefiner(for: .tidy).refine(transcript("as is"))
        #expect(tidy.mode == .tidy)
    }

    @Test("AI mode falls back to tidy when unavailable (observable via .tidy tag)")
    func aiUnavailableFallsBack() async throws {
        let factory = RefinerFactory(availability: .neverAvailable)
        let refiner = factory.makeRefiner(for: .appleIntelligence)
        let refined = try await refiner.refine(transcript("um hello world"))
        // Falls back to local rules and reports the effective mode as .tidy.
        #expect(refined.mode == .tidy)
        #expect(refined.text == "Hello world.")
        #expect(factory.isAppleIntelligenceEffective == false)
    }

    @Test("factory reports AI effective when the seam says available")
    func aiEffectiveWhenAvailable() {
        let factory = RefinerFactory(availability: .alwaysAvailable)
        #expect(factory.isAppleIntelligenceEffective == true)
    }

    @Test("AppleIntelligenceRefiner with unavailable seam yields tidy output")
    func aiRefinerDirectFallback() async throws {
        let refiner = AppleIntelligenceRefiner(availability: .neverAvailable)
        let refined = try await refiner.refine(transcript("uh testing"))
        #expect(refined.mode == .tidy)
        #expect(refined.text == "Testing.")
    }
}
