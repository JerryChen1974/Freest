// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// A composable async transform from `Input` to `Output`.
///
/// A pipeline is a thin wrapper over an async throwing function. Two pipelines
/// compose into one with `then(_:)`, which lets the dictation flow be built as
/// `capture |> transcribe |> refine |> deliver` while staying trivially testable
/// stage-by-stage.
///
/// Errors are normalized: any error a stage throws is passed through
/// `mapError` so downstream code always sees a `DictationError`. A stage that
/// already throws a `DictationError` is preserved as-is.
public struct Pipeline<Input, Output>: Sendable {
    private let run: @Sendable (Input) async throws -> Output

    public init(_ run: @escaping @Sendable (Input) async throws -> Output) {
        self.run = run
    }

    /// Execute the pipeline, normalizing any thrown error to `DictationError`.
    public func callAsFunction(_ input: Input) async throws -> Output {
        do {
            return try await run(input)
        } catch {
            throw Pipeline.mapError(error)
        }
    }

    /// Compose with a following pipeline, feeding this stage's output into it.
    public func then<Next>(_ next: Pipeline<Output, Next>) -> Pipeline<Input, Next> {
        Pipeline<Input, Next> { input in
            let mid = try await self.run(input)
            return try await next.rawRun(mid)
        }
    }

    /// Compose with a following async transform closure.
    public func then<Next>(
        _ transform: @escaping @Sendable (Output) async throws -> Next
    ) -> Pipeline<Input, Next> {
        then(Pipeline<Output, Next>(transform))
    }

    // Internal escape hatch so composed stages run without double-wrapping
    // errors; normalization happens once, at the outermost `callAsFunction`.
    fileprivate func rawRun(_ input: Input) async throws -> Output {
        try await run(input)
    }

    /// Normalize an arbitrary error into a `DictationError`. A value that is
    /// already a `DictationError` is returned unchanged; anything else is
    /// wrapped as a transcription failure carrying its description.
    static func mapError(_ error: Error) -> DictationError {
        if let dictationError = error as? DictationError {
            return dictationError
        }
        return .transcriptionFailed(reason: String(describing: error))
    }
}
