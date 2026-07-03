// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import Testing
@testable import FreestStorage
import FreestCore

@Suite("Sinks and path safety")
struct SinkAndPathSafetyTests {

    @Test("TextFileSink appends each delivery with a newline")
    func textFileSinkAppends() async throws {
        let fs = InMemoryFileSystem()
        let url = URL(fileURLWithPath: "/out/notes.txt")
        let sink = TextFileSink(fileSystem: fs, fileURL: url)

        try await sink.deliver(RefinedText(text: "first", mode: .tidy))
        try await sink.deliver(RefinedText(text: "second", mode: .tidy))

        let written = String(decoding: fs.contents(of: url) ?? Data(), as: UTF8.self)
        #expect(written == "first\nsecond\n")
    }

    @Test("DailyNoteSink writes to a yyyy-MM-dd file under the base directory")
    func dailyNoteSinkFilename() async throws {
        let fs = InMemoryFileSystem()
        let base = URL(fileURLWithPath: "/notes")
        // Fixed date: 2026-07-02 (in UTC-agnostic POSIX formatting).
        let fixed = Date(timeIntervalSince1970: 1_751_500_800)
        let sink = DailyNoteSink(fileSystem: fs, baseDirectory: base, dateProvider: { fixed })

        try await sink.deliver(RefinedText(text: "hello", mode: .off))

        let expectedName = DailyNoteSink.filename(for: fixed, extension: "md")
        let expectedURL = base.appending(path: expectedName, directoryHint: .notDirectory)
        #expect(fs.fileExists(at: expectedURL))
        #expect(String(decoding: fs.contents(of: expectedURL) ?? Data(), as: UTF8.self) == "hello\n")
    }

    @Test("PathSafety rejects traversal and empty components")
    func pathSafetyRejects() {
        let base = URL(fileURLWithPath: "/notes")
        #expect(throws: PathSafety.Violation.self) {
            _ = try PathSafety.resolve("../escape.txt", under: base)
        }
        #expect(throws: PathSafety.Violation.self) {
            _ = try PathSafety.resolve("sub/dir.txt", under: base)
        }
        #expect(throws: PathSafety.Violation.self) {
            _ = try PathSafety.resolve("   ", under: base)
        }
    }

    @Test("PathSafety accepts a plain filename and keeps it under base")
    func pathSafetyAccepts() throws {
        let base = URL(fileURLWithPath: "/notes")
        let url = try PathSafety.resolve("2026-07-02.md", under: base)
        #expect(url.standardizedFileURL.path == "/notes/2026-07-02.md")
    }
}
