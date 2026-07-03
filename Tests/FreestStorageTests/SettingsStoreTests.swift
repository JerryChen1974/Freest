// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import Testing
@testable import FreestStorage
import FreestCore

@Suite("SettingsStore self-healing persistence")
struct SettingsStoreTests {

    private let settingsURL = URL(fileURLWithPath: "/config/freest/config.json")

    @Test("absent file yields defaults and writes them")
    func absentFileWritesDefaults() async throws {
        let fs = InMemoryFileSystem()
        let store = SettingsStore(fileSystem: fs, fileURL: settingsURL)

        let loaded = try await store.load()
        #expect(loaded == Settings.defaults)
        #expect(fs.fileExists(at: settingsURL))   // defaults were persisted
    }

    @Test("save then load round-trips a modified settings value")
    func roundTrip() async throws {
        let fs = InMemoryFileSystem()
        let store = SettingsStore(fileSystem: fs, fileURL: settingsURL)

        var settings = Settings.defaults
        settings.selectedModelId = "small"
        settings.refinementMode = .off
        settings.historyLimit = 5
        try await store.save(settings)

        let loaded = try await store.load()
        #expect(loaded == settings)
    }

    @Test("corrupt file is backed up and defaults rewritten")
    func corruptFileHeals() async throws {
        let fs = InMemoryFileSystem()
        fs.seed(settingsURL, Data("this is not json{{{".utf8))
        let store = SettingsStore(fileSystem: fs, fileURL: settingsURL)

        let loaded = try await store.load()
        #expect(loaded == Settings.defaults)

        // A backup of the corrupt content should now exist alongside the file.
        let backup = settingsURL.deletingPathExtension()
            .appendingPathExtension("corrupt-backup")
        #expect(fs.fileExists(at: backup))
        #expect(fs.contents(of: backup) == Data("this is not json{{{".utf8))

        // And the primary file is now valid defaults.
        let reloaded = try await store.load()
        #expect(reloaded == Settings.defaults)
    }
}
