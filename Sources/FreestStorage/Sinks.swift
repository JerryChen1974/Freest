// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import FreestCore

/// Appends delivered text to a single fixed file. Conforms to the Core `Sink`
/// protocol so it is interchangeable with the paste sink or a future stdout
/// sink.
public struct TextFileSink: Sink {
    private let fileSystem: FileSystem
    private let fileURL: URL

    public init(fileSystem: FileSystem, fileURL: URL) {
        self.fileSystem = fileSystem
        self.fileURL = fileURL
    }

    public func deliver(_ text: RefinedText) async throws {
        do {
            var data = Data(text.text.utf8)
            data.append(0x0A) // newline between entries
            try fileSystem.append(data, to: fileURL)
        } catch {
            throw DictationError.outputFailed(reason: String(describing: error))
        }
    }
}

/// Appends delivered text to a per-day note file, e.g.
/// `<base>/2026-07-02.md`. The date-derived filename is run through
/// `PathSafety` so it can never escape the base directory.
public struct DailyNoteSink: Sink {
    private let fileSystem: FileSystem
    private let baseDirectory: URL
    private let fileExtension: String
    private let dateProvider: @Sendable () -> Date

    public init(
        fileSystem: FileSystem,
        baseDirectory: URL,
        fileExtension: String = "md",
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.fileSystem = fileSystem
        self.baseDirectory = baseDirectory
        self.fileExtension = fileExtension
        self.dateProvider = dateProvider
    }

    public func deliver(_ text: RefinedText) async throws {
        do {
            let name = Self.filename(for: dateProvider(), extension: fileExtension)
            let url = try PathSafety.resolve(name, under: baseDirectory)
            var data = Data(text.text.utf8)
            data.append(0x0A)
            try fileSystem.append(data, to: url)
        } catch {
            throw DictationError.outputFailed(reason: String(describing: error))
        }
    }

    /// `yyyy-MM-dd.<ext>` in the user's current calendar/timezone.
    static func filename(for date: Date, extension ext: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(formatter.string(from: date)).\(ext)"
    }
}
