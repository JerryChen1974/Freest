// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
@testable import FreestStorage

/// An in-memory `FileSystem` for tests: no real disk I/O, so storage logic
/// (self-healing, JSONL append/rewrite, sinks) is exercised deterministically.
/// A class behind a lock, since `FileSystem` is `Sendable` and tests touch it
/// from async contexts.
final class InMemoryFileSystem: FileSystem, @unchecked Sendable {
    private let lock = NSLock()
    private var files: [String: Data] = [:]

    /// Seed a file directly (bypassing write), e.g. to plant a corrupt config.
    func seed(_ url: URL, _ data: Data) {
        lock.lock(); files[url.standardizedFileURL.path] = data; lock.unlock()
    }

    /// Read raw bytes a test previously wrote, or nil.
    func contents(of url: URL) -> Data? {
        lock.lock(); defer { lock.unlock() }
        return files[url.standardizedFileURL.path]
    }

    var allPaths: [String] {
        lock.lock(); defer { lock.unlock() }
        return Array(files.keys).sorted()
    }

    func fileExists(at url: URL) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return files[url.standardizedFileURL.path] != nil
    }

    func read(_ url: URL) throws -> Data {
        lock.lock(); defer { lock.unlock() }
        guard let data = files[url.standardizedFileURL.path] else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return data
    }

    func write(_ data: Data, to url: URL) throws {
        lock.lock(); files[url.standardizedFileURL.path] = data; lock.unlock()
    }

    func append(_ data: Data, to url: URL) throws {
        lock.lock()
        let key = url.standardizedFileURL.path
        files[key, default: Data()].append(data)
        lock.unlock()
    }

    func createDirectory(at url: URL) throws {
        // No-op: directories are implicit in this flat map.
    }

    func moveItem(at source: URL, to destination: URL) throws {
        lock.lock(); defer { lock.unlock() }
        let src = source.standardizedFileURL.path
        guard let data = files[src] else { throw CocoaError(.fileNoSuchFile) }
        files[destination.standardizedFileURL.path] = data
        files[src] = nil
    }
}
