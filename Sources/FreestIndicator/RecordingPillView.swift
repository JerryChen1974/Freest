// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import SwiftUI
import FreestCore

/// The small floating pill shown while dictation is active. Reflects the
/// current `DictationState` with a label and a subtle animation.
public struct RecordingPillView: View {
    public let phase: Phase

    /// The visual phases the pill can show (a UI-facing reduction of
    /// `DictationState`).
    public enum Phase: Sendable, Equatable {
        case recording
        case working   // transcribing / refining / outputting
        case error(String)

        /// Map a Core `DictationState` to a pill phase, or nil when the pill
        /// should be hidden (idle).
        public init?(_ state: DictationState) {
            switch state {
            case .idle: return nil
            case .recording: self = .recording
            case .transcribing, .refining, .outputting: self = .working
            case .error(let error): self = .error(error.errorDescription ?? "Error")
            }
        }
    }

    public init(phase: Phase) {
        self.phase = phase
    }

    public var body: some View {
        HStack(spacing: 8) {
            icon
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(.black.opacity(0.8))
        )
        .fixedSize()
    }

    @ViewBuilder
    private var icon: some View {
        switch phase {
        case .recording:
            Circle().fill(.red).frame(width: 10, height: 10)
        case .working:
            ProgressView().controlSize(.small).tint(.white)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
        }
    }

    private var label: String {
        switch phase {
        case .recording: return "Listening…"
        case .working: return "Transcribing…"
        case .error(let message): return message
        }
    }
}
