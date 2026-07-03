// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// A minimal filesystem abstraction over the operations Freest's storage layer
/// needs. Injecting this lets the settings store, transcript log, and sinks be
/// unit-tested with an in-memory double instead of touching the real disk.
public protocol FileSystem: Sendable {
    func fileExists(at url: URL) -> Bool
    func read(_ url: URL) throws -> Data
    /// Write `data` to `url`, creating intermediate directories as needed.
    func write(_ data: Data, to url: URL) throws
    /// Append `data` to the file at `url`, creating it (and parents) if absent.
    func append(_ data: Data, to url: URL) throws
    func createDirectory(at url: URL) throws
    /// Move `source` to `destination`, replacing any existing item.
    func moveItem(at source: URL, to destination: URL) throws
}

/// The real, `FileManager`-backed filesystem.
public struct SystemFileSystem: FileSystem {
    public init() {}

    public func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    public func read(_ url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func write(_ data: Data, to url: URL) throws {
        try ensureParent(of: url)
        // Atomic write avoids leaving a half-written config behind on crash.
        try data.write(to: url, options: .atomic)
    }

    public func append(_ data: Data, to url: URL) throws {
        try ensureParent(of: url)
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } else {
            // File doesn't exist yet — create it with this data.
            try data.write(to: url, options: .atomic)
        }
    }

    public func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    public func moveItem(at source: URL, to destination: URL) throws {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: source, to: destination)
    }

    private func ensureParent(of url: URL) throws {
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
}
