// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import SwiftUI
import FreestCore

/// The dropdown shown from the menu-bar icon: current status, model-download
/// affordance when needed, and entries for Settings and Quit.
public struct MenuContent: View {
    @Bindable var model: AppModel

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        Text(model.statusText)
            .font(.headline)

        Divider()

        modelSection

        Divider()

        Button("Settings…") { model.openSettings() }
            .keyboardShortcut(",", modifiers: .command)
        Button("Quit Freest") { model.quit() }
            .keyboardShortcut("q", modifiers: .command)
    }

    @ViewBuilder
    private var modelSection: some View {
        switch model.modelState {
        case .ready:
            Label("Model ready: \(model.settings.selectedModelId)", systemImage: "checkmark.circle")
        case .missing:
            Button("Download model (\(model.settings.selectedModelId))") {
                model.downloadModel()
            }
        case .downloading(let fraction):
            Text("Downloading… \(Int(fraction * 100))%")
        case .failed(let message):
            Label("Download failed: \(message)", systemImage: "exclamationmark.triangle")
            Button("Retry download") { model.downloadModel() }
        case .unknown:
            Text("Checking model…")
        }
    }
}
