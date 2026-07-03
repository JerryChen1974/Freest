// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// Local, rule-based text cleanup. Fully offline, no model. Each rule is a pure
/// `String -> String` transform with its own unit test; `tidy(_:)` runs them in
/// order. Kept free of any Core dependency so the rules are trivially testable.
public struct TextTidier: Sendable {

    public init() {}

    /// Run the full cleanup pipeline.
    public func tidy(_ input: String) -> String {
        var text = input
        text = Self.trimEnds(text)
        text = Self.stripLeadingFiller(text)
        text = Self.collapseWhitespace(text)
        text = Self.capitalizeSentences(text)
        text = Self.ensureTerminalPunctuation(text)
        return text
    }

    // MARK: - Individual rules (each independently unit-tested)

    /// Trim leading and trailing whitespace and newlines.
    static func trimEnds(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Collapse any run of whitespace (spaces, tabs, newlines) to a single
    /// space. Interior only; ends are handled by `trimEnds`.
    static func collapseWhitespace(_ text: String) -> String {
        let parts = text.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" || $0 == "\r" })
        return parts.joined(separator: " ")
    }

    /// Filler words removed when they lead a clause (start of string or right
    /// after sentence-ending punctuation). Case-insensitive, word-boundary only.
    static let fillerWords: Set<String> = ["um", "uh", "er", "like"]

    /// Strip leading filler tokens from the start of the text and after each
    /// sentence terminator. Only removes a filler when it is a whole word.
    static func stripLeadingFiller(_ text: String) -> String {
        // Work sentence-piece by piece: split keeping terminators attached.
        var result = ""
        var clause = ""

        func flushClause() {
            result += stripFillerFromClauseStart(clause)
            clause = ""
        }

        for char in text {
            clause.append(char)
            if char == "." || char == "!" || char == "?" {
                flushClause()
            }
        }
        flushClause()
        return result
    }

    /// Remove one or more leading filler words (and any comma/space right after
    /// them) from a single clause, preserving the clause's leading whitespace.
    private static func stripFillerFromClauseStart(_ clause: String) -> String {
        // Separate leading whitespace so we can restore it after stripping.
        let leadingWhitespace = String(clause.prefix { $0 == " " || $0 == "\t" || $0 == "\n" })
        var body = String(clause.dropFirst(leadingWhitespace.count))

        var changed = true
        while changed {
            changed = false
            // Find the first word token in `body`.
            let firstWordEnd = body.firstIndex { $0 == " " || $0 == "," || $0 == "\t" || $0 == "\n" } ?? body.endIndex
            let firstWord = String(body[body.startIndex..<firstWordEnd])
            let stripped = firstWord.trimmingCharacters(in: .punctuationCharacters)
            if fillerWords.contains(stripped.lowercased()), !stripped.isEmpty {
                // Drop the word plus any immediately-following comma/space.
                var rest = String(body[firstWordEnd...])
                while let f = rest.first, f == " " || f == "," || f == "\t" {
                    rest.removeFirst()
                }
                body = rest
                changed = true
            }
        }
        return leadingWhitespace + body
    }

    /// Capitalize the first alphabetic character of each sentence.
    static func capitalizeSentences(_ text: String) -> String {
        var result = ""
        var atSentenceStart = true
        for char in text {
            if atSentenceStart, char.isLetter {
                result += String(char).uppercased()
                atSentenceStart = false
            } else {
                result.append(char)
                if char == "." || char == "!" || char == "?" {
                    atSentenceStart = true
                }
            }
        }
        return result
    }

    /// Ensure the text ends with terminal punctuation (adds a period if the last
    /// non-space character isn't `.`, `!`, or `?`). Empty input stays empty.
    static func ensureTerminalPunctuation(_ text: String) -> String {
        guard let last = text.last else { return text }
        if last == "." || last == "!" || last == "?" { return text }
        return text + "."
    }
}
