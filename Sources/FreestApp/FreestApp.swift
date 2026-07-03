// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import SwiftUI
import FreestUI

/// The Freest menu-bar app entry point. A `MenuBarExtra`-only app (no main
/// window, no Dock icon — `LSUIElement` is set in Info.plist). The composition
/// root (`AppController`) is created once and started when the app launches.
@main
struct FreestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Freest", systemImage: "waveform") {
            if let model = appDelegate.controller?.model {
                MenuContent(model: model)
            } else {
                Text("Starting…")
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

/// Owns the `AppController` for the app's lifetime and starts it after launch.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var controller: AppController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = AppController()
        self.controller = controller
        controller.start()
    }
}
