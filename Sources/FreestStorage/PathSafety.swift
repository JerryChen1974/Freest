// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// Guards against path traversal when a sink builds a file URL from a
/// caller-influenced component (a filename or a date-derived note name). The
/// rule: the resolved path must stay inside the intended base directory.
public enum PathSafety {

    public enum Violation: Error, Equatable {
        case emptyComponent
        case traversal(component: String)
    }

    /// Sanitize a single path component (a bare filename, no directory parts).
    /// Rejects empty names, anything containing a path separator, and `.`/`..`.
    public static func safeComponent(_ raw: String) throws -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Violation.emptyComponent }
        guard !trimmed.contains("/"),
              trimmed != ".",
              trimmed != ".."
        else {
            throw Violation.traversal(component: raw)
        }
        return trimmed
    }

    /// Resolve `component` under `base` and confirm the result is genuinely
    /// contained by `base` (defense in depth on top of `safeComponent`).
    public static func resolve(_ component: String, under base: URL) throws -> URL {
        let safe = try safeComponent(component)
        let candidate = base.appending(path: safe, directoryHint: .notDirectory)

        // Compare standardized paths so `..` or symlink-style tricks can't
        // escape the base directory.
        let basePath = base.standardizedFileURL.path
        let candidatePath = candidate.standardizedFileURL.path
        let prefix = basePath.hasSuffix("/") ? basePath : basePath + "/"
        guard candidatePath.hasPrefix(prefix) else {
            throw Violation.traversal(component: component)
        }
        return candidate
    }
}
