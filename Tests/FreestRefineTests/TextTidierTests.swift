// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import Testing
@testable import FreestRefine

@Suite("TextTidier rules")
struct TextTidierTests {

    // MARK: - Individual rules

    @Test("trimEnds removes surrounding whitespace and newlines")
    func trimEnds() {
        #expect(TextTidier.trimEnds("  \n hello \t\n") == "hello")
    }

    @Test("collapseWhitespace reduces runs of whitespace to single spaces")
    func collapseWhitespace() {
        #expect(TextTidier.collapseWhitespace("a   b\t\tc\nd") == "a b c d")
    }

    @Test("capitalizeSentences upper-cases the first letter of each sentence")
    func capitalizeSentences() {
        #expect(TextTidier.capitalizeSentences("hello world. how are you? fine!")
                == "Hello world. How are you? Fine!")
    }

    @Test("capitalizeSentences leaves an already-capitalized start alone")
    func capitalizeAlreadyCapital() {
        #expect(TextTidier.capitalizeSentences("Hello there.") == "Hello there.")
    }

    @Test("ensureTerminalPunctuation adds a period when missing")
    func ensureTerminalAdds() {
        #expect(TextTidier.ensureTerminalPunctuation("hello") == "hello.")
    }

    @Test("ensureTerminalPunctuation leaves existing terminal punctuation")
    func ensureTerminalKeeps() {
        #expect(TextTidier.ensureTerminalPunctuation("hello!") == "hello!")
        #expect(TextTidier.ensureTerminalPunctuation("what?") == "what?")
    }

    @Test("ensureTerminalPunctuation leaves empty input empty")
    func ensureTerminalEmpty() {
        #expect(TextTidier.ensureTerminalPunctuation("") == "")
    }

    @Test("stripLeadingFiller removes leading um/uh/er/like at clause start")
    func stripFillerLeading() {
        #expect(TextTidier.stripLeadingFiller("um hello there") == "hello there")
        #expect(TextTidier.stripLeadingFiller("uh, so it works") == "so it works")
    }

    @Test("stripLeadingFiller removes filler after a sentence terminator")
    func stripFillerAfterSentence() {
        #expect(TextTidier.stripLeadingFiller("Hello. um what now") == "Hello. what now")
    }

    @Test("stripLeadingFiller does not remove filler words mid-clause")
    func stripFillerNotMidClause() {
        // "like" here is not at a clause start, so it stays.
        #expect(TextTidier.stripLeadingFiller("I would like that") == "I would like that")
    }

    @Test("stripLeadingFiller only matches whole words, not substrings")
    func stripFillerWholeWord() {
        // "umbrella" starts with "um" but must not be stripped.
        #expect(TextTidier.stripLeadingFiller("umbrella is open") == "umbrella is open")
    }

    // MARK: - Full pipeline

    @Test("tidy runs all rules together")
    func fullPipeline() {
        let tidier = TextTidier()
        let input = "  um   hello world.  uh how   are you  "
        let output = tidier.tidy(input)
        #expect(output == "Hello world. How are you.")
    }

    @Test("tidy on clean input is stable and well-formed")
    func fullPipelineClean() {
        let tidier = TextTidier()
        #expect(tidier.tidy("this is a test") == "This is a test.")
    }
}
