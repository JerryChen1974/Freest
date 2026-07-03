// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import AppKit
import Carbon.HIToolbox
import FreestCore

/// Delivers text by pasting it at the current cursor position: snapshot the
/// pasteboard, write the new text, synthesize ⌘V, then restore the previous
/// pasteboard contents. Conforms to the Core `Sink` protocol.
///
/// OS-gated: synthetic key events require Accessibility (AX) trust, so this is
/// covered by the manual smoke test rather than unit tests. The pure key-event
/// construction is factored into `SyntheticKeyboard` so it can at least be
/// built and reasoned about in isolation.
public struct PasteSink: Sink {
    private let submitAfterPaste: Bool
    private let isTrusted: @Sendable () -> Bool
    private let restoreDelay: Duration

    /// - Parameters:
    ///   - submitAfterPaste: also press Return after pasting (e.g. to send).
    ///   - isTrusted: AX-trust probe; defaults to the real check.
    ///   - restoreDelay: how long to wait before restoring the pasteboard, so
    ///     the target app has time to read the pasted value.
    public init(
        submitAfterPaste: Bool = false,
        isTrusted: @escaping @Sendable () -> Bool = { AXIsProcessTrusted() },
        restoreDelay: Duration = .milliseconds(150)
    ) {
        self.submitAfterPaste = submitAfterPaste
        self.isTrusted = isTrusted
        self.restoreDelay = restoreDelay
    }

    public func deliver(_ text: RefinedText) async throws {
        guard isTrusted() else {
            throw DictationError.accessibilityPermissionDenied
        }

        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(text.text, forType: .string)

        do {
            try SyntheticKeyboard.pressCommandV()
            if submitAfterPaste {
                try SyntheticKeyboard.pressReturn()
            }
        } catch {
            snapshot.restore(into: pasteboard)
            throw DictationError.outputFailed(reason: String(describing: error))
        }

        // Give the frontmost app a moment to consume the paste before we put
        // the user's previous clipboard contents back.
        try? await Task.sleep(for: restoreDelay)
        snapshot.restore(into: pasteboard)
    }
}
