// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import SwiftUI
import FreestCore
import FreestASR
import KeyboardShortcuts

/// The Settings window: General, Transcription, Refinement, and Permissions
/// panes. Binds to `AppModel`; changes flow back through `updateSettings`.
public struct SettingsView: View {
    @Bindable var model: AppModel

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        TabView {
            GeneralPane(model: model)
                .tabItem { Label("General", systemImage: "gearshape") }
            TranscriptionPane(model: model)
                .tabItem { Label("Transcription", systemImage: "waveform") }
            RefinementPane(model: model)
                .tabItem { Label("Refinement", systemImage: "wand.and.stars") }
            PermissionsPane()
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
        }
        .frame(width: 460, height: 300)
        .padding()
    }
}

private struct GeneralPane: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            LabeledContent("Dictation hotkey") {
                // The KeyboardShortcuts recorder edits the shared named shortcut
                // directly; the app observes changes and re-registers.
                KeyboardShortcuts.Recorder(for: .init("freestToggleDictation"))
            }
            Toggle("Paste at cursor", isOn: Binding(
                get: { model.settings.pasteAtCursor },
                set: { value in model.updateSettings { $0.pasteAtCursor = value } }
            ))
            Toggle("Press Return after pasting", isOn: Binding(
                get: { model.settings.submitAfterPaste },
                set: { value in model.updateSettings { $0.submitAfterPaste = value } }
            ))
        }
        .formStyle(.grouped)
    }
}

private struct TranscriptionPane: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            Picker("Model", selection: Binding(
                get: { model.settings.selectedModelId },
                set: { value in model.updateSettings { $0.selectedModelId = value } }
            )) {
                ForEach(ModelCatalog.models) { m in
                    Text(m.displayName).tag(m.id)
                }
            }
            switch model.modelState {
            case .missing:
                Button("Download model") { model.downloadModel() }
            case .downloading(let fraction):
                ProgressView(value: fraction)
            case .failed(let message):
                Text("Download failed: \(message)").foregroundStyle(.red)
            case .ready:
                Label("Ready", systemImage: "checkmark.circle").foregroundStyle(.green)
            case .unknown:
                Text("Checking…")
            }
        }
        .formStyle(.grouped)
    }
}

private struct RefinementPane: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            Picker("Mode", selection: Binding(
                get: { model.settings.refinementMode },
                set: { value in model.updateSettings { $0.refinementMode = value } }
            )) {
                Text("Off").tag(RefinementMode.off)
                Text("Tidy (local rules)").tag(RefinementMode.tidy)
                Text(appleIntelligenceLabel).tag(RefinementMode.appleIntelligence)
            }
            if model.settings.refinementMode == .appleIntelligence, !model.appleIntelligenceEffective {
                Text("Apple Intelligence isn't available on this Mac; Freest will use local Tidy rules instead.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var appleIntelligenceLabel: String {
        model.appleIntelligenceEffective
            ? "Apple Intelligence"
            : "Apple Intelligence (unavailable — uses Tidy)"
    }
}

private struct PermissionsPane: View {
    var body: some View {
        Form {
            Text("Freest needs Microphone access to record and Accessibility access to paste at the cursor.")
                .font(.callout)
            Text("Grant both in System Settings → Privacy & Security. Freest prompts on first use.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}
