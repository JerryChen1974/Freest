// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import Testing
@testable import FreestCore

@Suite("Value types: Settings, Chord, TranscriptLog")
struct ValueTypeTests {

    @Test("Settings round-trips through JSON")
    func settingsRoundTrip() throws {
        let settings = Settings(
            selectedModelId: "small",
            hotkey: Chord(modifiers: [.command, .shift], key: .space),
            refinementMode: .appleIntelligence,
            inputDeviceUID: "device-42",
            pasteAtCursor: false,
            submitAfterPaste: true,
            historyEnabled: false,
            historyLimit: 10
        )
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(Settings.self, from: data)
        #expect(decoded == settings)
    }

    @Test("Settings decoding fills missing keys with defaults")
    func settingsTolerantDecoding() throws {
        // Only one field present; everything else should default.
        let json = #"{"selectedModelId":"medium"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Settings.self, from: json)
        #expect(decoded.selectedModelId == "medium")
        #expect(decoded.refinementMode == Settings.defaults.refinementMode)
        #expect(decoded.hotkey == Settings.defaults.hotkey)
        #expect(decoded.historyLimit == Settings.defaults.historyLimit)
    }

    @Test("default hotkey renders as ⌃⌥D regardless of modifier set order")
    func defaultHotkeyDisplay() {
        #expect(Chord.defaultHotkey.displayString == "\u{2303}\u{2325}D")
        // A set literal in a different order must render identically.
        let reordered = Chord(modifiers: [.option, .control], key: .d)
        #expect(reordered.displayString == "\u{2303}\u{2325}D")
    }

    @Test("TranscriptLog evicts oldest beyond the limit (FIFO)")
    func transcriptLogEviction() {
        var log = TranscriptLog(limit: 2)
        let base = Date(timeIntervalSince1970: 0)
        for i in 0..<3 {
            log.append(TranscriptEntry(
                raw: "raw\(i)", refined: nil,
                date: base.addingTimeInterval(Double(i)), modelId: "base"
            ))
        }
        let texts = log.list().map(\.raw)
        #expect(texts == ["raw1", "raw2"])   // "raw0" evicted
    }

    @Test("TranscriptLog with limit 0 is unlimited")
    func transcriptLogUnlimited() {
        var log = TranscriptLog(limit: 0)
        for i in 0..<50 {
            log.append(TranscriptEntry(raw: "r\(i)", refined: nil, date: Date(), modelId: "base"))
        }
        #expect(log.list().count == 50)
    }

    @Test("DictationError equatability distinguishes cases and payloads")
    func errorEquality() {
        #expect(DictationError.cancelled == DictationError.cancelled)
        #expect(DictationError.modelNotReady(modelId: "base")
                != DictationError.modelNotReady(modelId: "small"))
    }
}
