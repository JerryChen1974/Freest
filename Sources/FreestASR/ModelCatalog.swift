// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// Maps Freest's short model ids to the concrete WhisperKit repository variant
/// strings, and derives on-disk paths. Pure and dependency-free, so it is fully
/// unit-testable without WhisperKit, a network, or any downloaded model.
public struct ModelCatalog: Sendable {

    /// A selectable model: a Freest id plus the WhisperKit variant it resolves
    /// to and a human-facing display name.
    public struct Model: Sendable, Equatable, Identifiable {
        public let id: String          // Freest id, e.g. "base"
        public let variant: String     // WhisperKit variant, e.g. "openai_whisper-base"
        public let displayName: String

        public init(id: String, variant: String, displayName: String) {
            self.id = id
            self.variant = variant
            self.displayName = displayName
        }
    }

    /// The models Freest offers, in ascending size/quality order.
    public static let models: [Model] = [
        Model(id: "tiny", variant: "openai_whisper-tiny", displayName: "Tiny"),
        Model(id: "base", variant: "openai_whisper-base", displayName: "Base"),
        Model(id: "small", variant: "openai_whisper-small", displayName: "Small"),
        Model(id: "medium", variant: "openai_whisper-medium", displayName: "Medium"),
        Model(id: "large-v3", variant: "openai_whisper-large-v3", displayName: "Large v3")
    ]

    /// The default model id when settings are fresh.
    public static let defaultModelId = "base"

    private let modelsDirectory: URL

    public init(modelsDirectory: URL) {
        self.modelsDirectory = modelsDirectory
    }

    /// Look up a model by its Freest id.
    public func model(for id: String) -> Model? {
        Self.models.first { $0.id == id }
    }

    /// The WhisperKit variant string for a Freest id, or nil if unknown.
    public func variant(for id: String) -> String? {
        model(for: id)?.variant
    }

    /// The directory a given model's files live in:
    /// `<modelsDirectory>/<variant>/`.
    public func directory(for id: String) -> URL? {
        guard let variant = variant(for: id) else { return nil }
        return modelsDirectory.appending(path: variant, directoryHint: .isDirectory)
    }
}
