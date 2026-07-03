// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import AppKit
import KeyboardShortcuts
import FreestCore

/// Registers the global dictation hotkey via the KeyboardShortcuts library and
/// exposes press/release edges as an `AsyncStream<HotkeyEvent>`. The app drives
/// push-to-talk from this: `.pressed` starts recording, `.released` finishes.
///
/// OS-gated (a real global hotkey), so covered by the manual smoke test.
@MainActor
public final class HotkeyMonitor {
    private var continuation: AsyncStream<HotkeyEvent>.Continuation?

    /// The stream of hotkey press/release edges.
    public let events: AsyncStream<HotkeyEvent>

    public init() {
        var cont: AsyncStream<HotkeyEvent>.Continuation!
        self.events = AsyncStream { cont = $0 }
        self.continuation = cont
    }

    /// Set (or change) the registered chord, then begin delivering events.
    public func start(chord: Chord) {
        setChord(chord)
        KeyboardShortcuts.onKeyDown(for: .toggleDictation) { [weak self] in
            self?.continuation?.yield(.pressed)
        }
        KeyboardShortcuts.onKeyUp(for: .toggleDictation) { [weak self] in
            self?.continuation?.yield(.released)
        }
    }

    /// Update the registered chord (e.g. after the user edits it in Settings).
    public func setChord(_ chord: Chord) {
        KeyboardShortcuts.setShortcut(ChordBridge.shortcut(chord), for: .toggleDictation)
    }

    /// Stop delivering events and clear the registration.
    public func stop() {
        KeyboardShortcuts.disable(.toggleDictation)
        continuation?.finish()
    }
}
