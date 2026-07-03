// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import FreestCore

/// A `Refiner` that applies local `TextTidier` rules. Always reports `.tidy` as
/// the mode it produced.
public struct TidyRefiner: Refiner {
    private let tidier = TextTidier()

    public init() {}

    public func refine(_ transcript: Transcript) async throws -> RefinedText {
        RefinedText(text: tidier.tidy(transcript.text), mode: .tidy)
    }
}

/// A pass-through `Refiner` for `.off`: returns the transcript text unchanged,
/// tagged `.off`.
public struct PassthroughRefiner: Refiner {
    public init() {}

    public func refine(_ transcript: Transcript) async throws -> RefinedText {
        RefinedText(text: transcript.text, mode: .off)
    }
}
