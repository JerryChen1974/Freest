// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// A keyboard chord: a set of modifier keys plus one main key. This is the
/// pure, storable description of a hotkey; the hotkey module bridges it to the
/// concrete registration API at registration time so nothing platform-specific
/// leaks into the core or into persisted settings.
public struct Chord: Codable, Sendable, Equatable {

    /// The modifier keys a chord may require.
    public enum Modifier: String, Codable, Sendable, CaseIterable, Comparable {
        case control
        case option
        case command
        case shift

        // Deterministic ordering, used when rendering a chord as a string.
        private var order: Int {
            switch self {
            case .control: return 0
            case .option: return 1
            case .shift: return 2
            case .command: return 3
            }
        }

        public static func < (lhs: Modifier, rhs: Modifier) -> Bool {
            lhs.order < rhs.order
        }

        /// The symbol conventionally shown in a macOS menu.
        public var symbol: String {
            switch self {
            case .control: return "\u{2303}" // ⌃
            case .option: return "\u{2325}"  // ⌥
            case .shift: return "\u{21E7}"   // ⇧
            case .command: return "\u{2318}" // ⌘
            }
        }
    }

    /// The small set of main keys that make sense for a dictation hotkey.
    public enum Key: String, Codable, Sendable, CaseIterable {
        case a, b, c, d, e, f, g, h, i, j, k, l, m
        case n, o, p, q, r, s, t, u, v, w, x, y, z
        case space

        /// How the key is shown in a menu.
        public var symbol: String {
            switch self {
            case .space: return "Space"
            default: return rawValue.uppercased()
            }
        }
    }

    public var modifiers: Set<Modifier>
    public var key: Key

    public init(modifiers: Set<Modifier>, key: Key) {
        self.modifiers = modifiers
        self.key = key
    }

    /// The chord rendered for display, e.g. `⌃⌥D`. Modifiers appear in the
    /// conventional macOS order regardless of set iteration order.
    public var displayString: String {
        let mods = modifiers.sorted().map(\.symbol).joined()
        return mods + key.symbol
    }

    /// The default Freest hotkey: Control-Option-D (⌃⌥D).
    public static let defaultHotkey = Chord(modifiers: [.control, .option], key: .d)
}
