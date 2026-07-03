// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import AppKit

/// Captures the current pasteboard items so they can be restored after Freest
/// temporarily overwrites the clipboard to paste. Copies each item's data for
/// every type, so non-string clipboard contents survive a dictation paste.
struct PasteboardSnapshot {
    private let items: [[NSPasteboard.PasteboardType: Data]]

    init(_ pasteboard: NSPasteboard) {
        var captured: [[NSPasteboard.PasteboardType: Data]] = []
        for item in pasteboard.pasteboardItems ?? [] {
            var typeMap: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    typeMap[type] = data
                }
            }
            if !typeMap.isEmpty { captured.append(typeMap) }
        }
        self.items = captured
    }

    /// Restore the snapshot into `pasteboard`, replacing whatever is there now.
    func restore(into pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        guard !items.isEmpty else { return }
        var restored: [NSPasteboardItem] = []
        for typeMap in items {
            let item = NSPasteboardItem()
            for (type, data) in typeMap {
                item.setData(data, forType: type)
            }
            restored.append(item)
        }
        pasteboard.writeObjects(restored)
    }
}
