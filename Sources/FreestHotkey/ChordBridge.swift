// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import AppKit
import KeyboardShortcuts
import FreestCore

/// Bridges Freest's storable `Chord` value to the KeyboardShortcuts library's
/// `Shortcut`/modifier representation. Kept separate from the monitor so the
/// mapping (which is pure) is easy to reason about.
enum ChordBridge {

    /// The AppKit modifier flags for a chord.
    static func modifierFlags(_ chord: Chord) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        for modifier in chord.modifiers {
            switch modifier {
            case .control: flags.insert(.control)
            case .option: flags.insert(.option)
            case .command: flags.insert(.command)
            case .shift: flags.insert(.shift)
            }
        }
        return flags
    }

    /// The KeyboardShortcuts `Key` for a chord's main key.
    static func key(_ chord: Chord) -> KeyboardShortcuts.Key {
        switch chord.key {
        case .a: return .a
        case .b: return .b
        case .c: return .c
        case .d: return .d
        case .e: return .e
        case .f: return .f
        case .g: return .g
        case .h: return .h
        case .i: return .i
        case .j: return .j
        case .k: return .k
        case .l: return .l
        case .m: return .m
        case .n: return .n
        case .o: return .o
        case .p: return .p
        case .q: return .q
        case .r: return .r
        case .s: return .s
        case .t: return .t
        case .u: return .u
        case .v: return .v
        case .w: return .w
        case .x: return .x
        case .y: return .y
        case .z: return .z
        case .space: return .space
        }
    }

    /// The KeyboardShortcuts `Shortcut` for a chord.
    static func shortcut(_ chord: Chord) -> KeyboardShortcuts.Shortcut {
        KeyboardShortcuts.Shortcut(key(chord), modifiers: modifierFlags(chord))
    }
}

extension KeyboardShortcuts.Name {
    /// The single named shortcut Freest registers for push-to-talk dictation.
    /// `Name` is a value that is created once and only read thereafter; the
    /// library funnels shortcut handling through the main thread, so
    /// `nonisolated(unsafe)` is the accepted way to expose this constant under
    /// Swift 6 strict concurrency.
    nonisolated(unsafe) static let toggleDictation = Self("freestToggleDictation")
}
