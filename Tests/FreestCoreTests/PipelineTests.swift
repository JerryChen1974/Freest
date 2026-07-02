// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import Testing
@testable import FreestCore

@Suite("Pipeline composition and error mapping")
struct PipelineTests {

    @Test("two stages compose and feed output into input")
    func chaining() async throws {
        let double = Pipeline<Int, Int> { $0 * 2 }
        let stringify = Pipeline<Int, String> { "n=\($0)" }
        let composed = double.then(stringify)
        let result = try await composed(21)
        #expect(result == "n=42")
    }

    @Test("closure form composes too")
    func chainingWithClosure() async throws {
        let composed = Pipeline<Int, Int> { $0 + 1 }
            .then { $0 * 10 }
            .then { "\($0)" }
        #expect(try await composed(4) == "50")
    }

    @Test("a DictationError thrown by a stage passes through unchanged")
    func dictationErrorPassesThrough() async {
        let failing = Pipeline<Int, Int> { _ in
            throw DictationError.modelNotReady(modelId: "base")
        }
        await #expect(throws: DictationError.modelNotReady(modelId: "base")) {
            _ = try await failing(1)
        }
    }

    @Test("a non-DictationError is normalized to a DictationError")
    func arbitraryErrorIsMapped() async {
        struct Boom: Error {}
        let failing = Pipeline<Int, Int> { _ in throw Boom() }
        do {
            _ = try await failing(1)
            Issue.record("expected an error")
        } catch let error as DictationError {
            if case .transcriptionFailed = error {
                // expected
            } else {
                Issue.record("unexpected DictationError case: \(error)")
            }
        } catch {
            Issue.record("error was not mapped to DictationError: \(error)")
        }
    }

    @Test("error normalization happens once, not per composed stage")
    func errorMappedOnce() async {
        // The first stage throws a DictationError; composing must not re-wrap it
        // into .transcriptionFailed via the intermediate boundary.
        let first = Pipeline<Int, Int> { _ in
            throw DictationError.audioCaptureFailed(reason: "mic")
        }
        let second = Pipeline<Int, String> { "\($0)" }
        let composed = first.then(second)
        await #expect(throws: DictationError.audioCaptureFailed(reason: "mic")) {
            _ = try await composed(1)
        }
    }
}
