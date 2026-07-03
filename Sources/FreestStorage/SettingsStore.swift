// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import FreestCore

/// Persists `Settings` as JSON at a fixed location, and self-heals a missing or
/// corrupt file by backing it up and rewriting defaults. An actor so concurrent
/// readers/writers can't race on the file.
public actor SettingsStore {
    private let fileSystem: FileSystem
    private let fileURL: URL

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder = JSONDecoder()

    public init(fileSystem: FileSystem, fileURL: URL) {
        self.fileSystem = fileSystem
        self.fileURL = fileURL
    }

    public init(fileSystem: FileSystem = SystemFileSystem(),
                locations: StorageLocations = .defaults()) {
        self.init(fileSystem: fileSystem, fileURL: locations.settingsFile)
    }

    /// Load settings. If the file is absent, write and return defaults. If it is
    /// present but unreadable/corrupt, back it up (`.corrupt-backup`) and
    /// rewrite defaults so the app always starts from a valid state.
    public func load() throws -> Settings {
        guard fileSystem.fileExists(at: fileURL) else {
            let defaults = Settings.defaults
            try save(defaults)
            return defaults
        }
        do {
            let data = try fileSystem.read(fileURL)
            return try decoder.decode(Settings.self, from: data)
        } catch {
            try backupCorruptFile()
            let defaults = Settings.defaults
            try save(defaults)
            return defaults
        }
    }

    /// Persist settings, replacing the file atomically.
    public func save(_ settings: Settings) throws {
        let data = try encoder.encode(settings)
        try fileSystem.write(data, to: fileURL)
    }

    private func backupCorruptFile() throws {
        let backup = fileURL.deletingPathExtension()
            .appendingPathExtension("corrupt-backup")
        // Best effort: if the move fails, the subsequent atomic overwrite of the
        // primary file still restores a valid state.
        try? fileSystem.moveItem(at: fileURL, to: backup)
    }
}
