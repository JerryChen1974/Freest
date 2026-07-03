// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import CoreGraphics
import Carbon.HIToolbox
import FreestCore

/// Synthesizes keystrokes via Core Graphics events. Used to paste (⌘V) and
/// optionally submit (Return) into whatever app is frontmost.
enum SyntheticKeyboard {

    /// Post a ⌘V key-down/up pair.
    static func pressCommandV() throws {
        try postKey(CGKeyCode(kVK_ANSI_V), flags: .maskCommand)
    }

    /// Post a Return key-down/up pair.
    static func pressReturn() throws {
        try postKey(CGKeyCode(kVK_Return), flags: [])
    }

    private static func postKey(_ key: CGKeyCode, flags: CGEventFlags) throws {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            throw DictationError.outputFailed(reason: "could not create event source")
        }
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        else {
            throw DictationError.outputFailed(reason: "could not create key event")
        }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cgAnnotatedSessionEventTap)
        up.post(tap: .cgAnnotatedSessionEventTap)
    }
}
