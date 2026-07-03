// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import Testing
@testable import FreestASR

@Suite("ModelCatalog id → variant mapping and paths")
struct ModelCatalogTests {

    private let modelsDir = URL(fileURLWithPath: "/support/Freest/models")

    @Test("known ids map to the expected WhisperKit variants")
    func variantMapping() {
        let catalog = ModelCatalog(modelsDirectory: modelsDir)
        #expect(catalog.variant(for: "tiny") == "openai_whisper-tiny")
        #expect(catalog.variant(for: "base") == "openai_whisper-base")
        #expect(catalog.variant(for: "small") == "openai_whisper-small")
        #expect(catalog.variant(for: "medium") == "openai_whisper-medium")
        #expect(catalog.variant(for: "large-v3") == "openai_whisper-large-v3")
    }

    @Test("an unknown id has no variant and no directory")
    func unknownId() {
        let catalog = ModelCatalog(modelsDirectory: modelsDir)
        #expect(catalog.variant(for: "nope") == nil)
        #expect(catalog.directory(for: "nope") == nil)
    }

    @Test("directory is built as <modelsDir>/<variant>")
    func directoryBuild() {
        let catalog = ModelCatalog(modelsDirectory: modelsDir)
        let dir = catalog.directory(for: "base")
        #expect(dir?.standardizedFileURL.path == "/support/Freest/models/openai_whisper-base")
    }

    @Test("default model id is base and is present in the catalog")
    func defaultModel() {
        #expect(ModelCatalog.defaultModelId == "base")
        let catalog = ModelCatalog(modelsDirectory: modelsDir)
        #expect(catalog.model(for: ModelCatalog.defaultModelId) != nil)
    }
}
