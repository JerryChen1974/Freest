// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import Testing
@testable import FreestStorage
import FreestCore

@Suite("TranscriptLogStore JSONL persistence")
struct TranscriptLogStoreTests {

    private let historyURL = URL(fileURLWithPath: "/support/Freest/history.jsonl")

    private func entry(_ n: Int) -> TranscriptEntry {
        TranscriptEntry(
            raw: "raw\(n)", refined: "refined\(n)",
            date: Date(timeIntervalSince1970: Double(n)), modelId: "base"
        )
    }

    @Test("append persists and reloads entries in order")
    func appendAndReload() async throws {
        let fs = InMemoryFileSystem()
        let store = TranscriptLogStore(fileSystem: fs, fileURL: historyURL, limit: 100)

        try await store.append(entry(1))
        try await store.append(entry(2))

        let reloaded = try await store.load()
        #expect(reloaded.list().map(\.raw) == ["raw1", "raw2"])
    }

    @Test("append enforces the retention limit with FIFO eviction")
    func retentionLimit() async throws {
        let fs = InMemoryFileSystem()
        let store = TranscriptLogStore(fileSystem: fs, fileURL: historyURL, limit: 2)

        for i in 1...4 { try await store.append(entry(i)) }

        let reloaded = try await store.load()
        #expect(reloaded.list().map(\.raw) == ["raw3", "raw4"])
    }

    @Test("corrupt lines are skipped on load")
    func skipsCorruptLines() async throws {
        let fs = InMemoryFileSystem()
        let good = try JSONEncoder().encode(entry(7))
        var seed = Data()
        seed.append(Data("not json\n".utf8))
        seed.append(good); seed.append(0x0A)
        seed.append(Data("{also broken\n".utf8))
        fs.seed(historyURL, seed)

        let store = TranscriptLogStore(fileSystem: fs, fileURL: historyURL, limit: 100)
        let loaded = try await store.load()
        #expect(loaded.list().map(\.raw) == ["raw7"])
    }
}
