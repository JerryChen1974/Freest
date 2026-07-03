// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import FreestCore

/// Persists transcript history as JSON Lines (one `TranscriptEntry` per line),
/// applying the same bounded FIFO policy as the in-memory `TranscriptLog`.
///
/// JSONL is used so appends are cheap and a single corrupt line doesn't lose
/// the whole history — unreadable lines are skipped on load.
public actor TranscriptLogStore {
    private let fileSystem: FileSystem
    private let fileURL: URL
    private let limit: Int

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(fileSystem: FileSystem, fileURL: URL, limit: Int) {
        self.fileSystem = fileSystem
        self.fileURL = fileURL
        self.limit = max(0, limit)
    }

    public init(fileSystem: FileSystem = SystemFileSystem(),
                locations: StorageLocations = .defaults(),
                limit: Int = 200) {
        self.init(fileSystem: fileSystem, fileURL: locations.historyFile, limit: limit)
    }

    /// Load all persisted entries (oldest first), skipping any corrupt lines and
    /// enforcing the retention limit.
    public func load() throws -> TranscriptLog {
        guard fileSystem.fileExists(at: fileURL) else {
            return TranscriptLog(limit: limit)
        }
        let data = try fileSystem.read(fileURL)
        let text = String(decoding: data, as: UTF8.self)
        var entries: [TranscriptEntry] = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let lineData = line.data(using: .utf8),
                  let entry = try? decoder.decode(TranscriptEntry.self, from: lineData)
            else { continue }
            entries.append(entry)
        }
        return TranscriptLog(entries: entries, limit: limit)
    }

    /// Append one entry, then rewrite the file if the retention limit forced an
    /// eviction (otherwise a plain append). Returns the resulting log.
    @discardableResult
    public func append(_ entry: TranscriptEntry) throws -> TranscriptLog {
        var log = try load()
        let countBefore = log.entries.count
        log.append(entry)

        // If nothing was evicted, a cheap append keeps the file in sync.
        if log.entries.count == countBefore + 1 {
            var line = try encoder.encode(entry)
            line.append(0x0A) // '\n'
            try fileSystem.append(line, to: fileURL)
        } else {
            try rewrite(log)
        }
        return log
    }

    private func rewrite(_ log: TranscriptLog) throws {
        var data = Data()
        for entry in log.list() {
            data.append(try encoder.encode(entry))
            data.append(0x0A)
        }
        try fileSystem.write(data, to: fileURL)
    }
}
