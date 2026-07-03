// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// The on-disk locations Freest uses. Centralized so paths are derived in one
/// place (and are never read from user-controlled settings — see `PathSafety`).
public struct StorageLocations: Sendable {
    /// Base directory for user config, e.g. `~/.config/freest`.
    public let configDirectory: URL
    /// Base directory for app support data, e.g.
    /// `~/Library/Application Support/Freest`.
    public let appSupportDirectory: URL

    public init(configDirectory: URL, appSupportDirectory: URL) {
        self.configDirectory = configDirectory
        self.appSupportDirectory = appSupportDirectory
    }

    /// The default real locations under the user's home directory.
    public static func defaults() -> StorageLocations {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return StorageLocations(
            configDirectory: home.appending(path: ".config/freest", directoryHint: .isDirectory),
            appSupportDirectory: home.appending(
                path: "Library/Application Support/Freest", directoryHint: .isDirectory
            )
        )
    }

    /// Where `Settings` is persisted: `<config>/config.json`.
    public var settingsFile: URL {
        configDirectory.appending(path: "config.json", directoryHint: .notDirectory)
    }

    /// Where transcript history is persisted: `<appSupport>/history.jsonl`.
    public var historyFile: URL {
        appSupportDirectory.appending(path: "history.jsonl", directoryHint: .notDirectory)
    }

    /// Where downloaded speech models live:
    /// `<appSupport>/models/`. Never committed to the repo.
    public var modelsDirectory: URL {
        appSupportDirectory.appending(path: "models", directoryHint: .isDirectory)
    }
}
