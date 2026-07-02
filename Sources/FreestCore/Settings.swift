// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// How dictated text is cleaned up before it is pasted.
public enum RefinementMode: String, Codable, Sendable, CaseIterable {
    /// Paste the raw transcript unchanged.
    case off
    /// Local, rule-based cleanup (`TextTidier`). Fully offline, no model.
    case tidy
    /// On-device LLM cleanup via Apple's FoundationModels. Runtime-gated;
    /// falls back to `tidy` where unavailable.
    case appleIntelligence
}

/// User-configurable settings, persisted as JSON. All fields have defaults so a
/// missing or corrupt file can be healed by writing a fresh default instance.
///
/// Deliberately contains **no** free-form filesystem path fields: sinks derive
/// their own locations, which keeps a corrupt or hostile config file from
/// steering writes to an arbitrary path.
public struct Settings: Codable, Sendable, Equatable {
    /// Freest model id (mapped to a concrete engine variant by the ASR module).
    public var selectedModelId: String
    /// The global hotkey chord.
    public var hotkey: Chord
    /// Which refinement stage to run.
    public var refinementMode: RefinementMode
    /// Preferred input device (by unique id), or nil for the system default.
    public var inputDeviceUID: String?
    /// Whether to paste at the cursor (vs. only copy to the pasteboard).
    public var pasteAtCursor: Bool
    /// Whether to press Return after pasting (e.g. to send a chat message).
    public var submitAfterPaste: Bool
    /// Whether to keep a local transcript history.
    public var historyEnabled: Bool
    /// Maximum retained history entries; 0 means unlimited.
    public var historyLimit: Int

    public init(
        selectedModelId: String = "base",
        hotkey: Chord = .defaultHotkey,
        refinementMode: RefinementMode = .tidy,
        inputDeviceUID: String? = nil,
        pasteAtCursor: Bool = true,
        submitAfterPaste: Bool = false,
        historyEnabled: Bool = true,
        historyLimit: Int = 200
    ) {
        self.selectedModelId = selectedModelId
        self.hotkey = hotkey
        self.refinementMode = refinementMode
        self.inputDeviceUID = inputDeviceUID
        self.pasteAtCursor = pasteAtCursor
        self.submitAfterPaste = submitAfterPaste
        self.historyEnabled = historyEnabled
        self.historyLimit = historyLimit
    }

    /// Freest's default settings.
    public static let defaults = Settings()

    // Decoding is tolerant: any absent key falls back to its default, so a
    // partially-written or older config file still decodes into a usable value
    // rather than throwing.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Settings.defaults
        selectedModelId = try c.decodeIfPresent(String.self, forKey: .selectedModelId) ?? d.selectedModelId
        hotkey = try c.decodeIfPresent(Chord.self, forKey: .hotkey) ?? d.hotkey
        refinementMode = try c.decodeIfPresent(RefinementMode.self, forKey: .refinementMode) ?? d.refinementMode
        inputDeviceUID = try c.decodeIfPresent(String.self, forKey: .inputDeviceUID) ?? d.inputDeviceUID
        pasteAtCursor = try c.decodeIfPresent(Bool.self, forKey: .pasteAtCursor) ?? d.pasteAtCursor
        submitAfterPaste = try c.decodeIfPresent(Bool.self, forKey: .submitAfterPaste) ?? d.submitAfterPaste
        historyEnabled = try c.decodeIfPresent(Bool.self, forKey: .historyEnabled) ?? d.historyEnabled
        historyLimit = try c.decodeIfPresent(Int.self, forKey: .historyLimit) ?? d.historyLimit
    }
}
