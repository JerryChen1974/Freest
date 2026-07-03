// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import AppKit
import SwiftUI
import FreestCore

/// A borderless, non-activating floating panel that hosts the recording pill.
/// It floats above other windows without stealing focus, so dictation into the
/// frontmost app is never interrupted.
@MainActor
public final class IndicatorPanel {
    private var panel: NSPanel?

    public init() {}

    /// Show the pill for the given phase, creating the panel on first use and
    /// positioning it near the bottom-center of the main screen.
    public func show(_ phase: RecordingPillView.Phase) {
        let panel = existingOrNewPanel()
        panel.contentView = NSHostingView(rootView: RecordingPillView(phase: phase))
        reposition(panel)
        panel.orderFrontRegardless()
    }

    /// Hide the pill (idle).
    public func hide() {
        panel?.orderOut(nil)
    }

    /// Drive the panel directly from a Core `DictationState`.
    public func update(for state: DictationState) {
        if let phase = RecordingPillView.Phase(state) {
            show(phase)
        } else {
            hide()
        }
    }

    private func existingOrNewPanel() -> NSPanel {
        if let panel { return panel }
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.panel = panel
        return panel
    }

    private func reposition(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        panel.layoutIfNeeded()
        let size = panel.contentView?.fittingSize ?? NSSize(width: 160, height: 40)
        let visible = screen.visibleFrame
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.minY + 80
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }
}
