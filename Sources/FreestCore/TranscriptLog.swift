// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// One entry in the transcript history.
public struct TranscriptEntry: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let raw: String
    public let refined: String?
    public let date: Date
    public let modelId: String

    public init(id: UUID = UUID(), raw: String, refined: String?, date: Date, modelId: String) {
        self.id = id
        self.raw = raw
        self.refined = refined
        self.date = date
        self.modelId = modelId
    }
}

/// A bounded, in-memory transcript history with FIFO eviction. The storage
/// module wraps this with persistence; keeping the eviction policy here (pure,
/// no I/O) makes it directly unit-testable.
///
/// `limit == 0` means unlimited.
public struct TranscriptLog: Sendable, Equatable {
    public private(set) var entries: [TranscriptEntry]
    public let limit: Int

    public init(entries: [TranscriptEntry] = [], limit: Int = 200) {
        self.limit = max(0, limit)
        // Enforce the bound on any seeded entries too, keeping the newest.
        self.entries = TranscriptLog.trimmed(entries, to: self.limit)
    }

    /// Append an entry, evicting the oldest entries beyond `limit`.
    public mutating func append(_ entry: TranscriptEntry) {
        entries.append(entry)
        entries = TranscriptLog.trimmed(entries, to: limit)
    }

    /// The entries, newest last (insertion order).
    public func list() -> [TranscriptEntry] {
        entries
    }

    private static func trimmed(_ entries: [TranscriptEntry], to limit: Int) -> [TranscriptEntry] {
        guard limit > 0, entries.count > limit else { return entries }
        return Array(entries.suffix(limit))
    }
}
