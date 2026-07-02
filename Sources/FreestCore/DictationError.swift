// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// The single error type surfaced by a dictation run. Infrastructure modules
/// map their own low-level failures onto one of these cases so the core state
/// machine and the UI have a small, stable vocabulary to reason about.
public enum DictationError: Error, Sendable, Equatable {
    /// Microphone permission has not been granted.
    case microphonePermissionDenied
    /// Accessibility (AX) trust has not been granted, so pasting can't proceed.
    case accessibilityPermissionDenied
    /// The selected speech model is not present on disk (needs downloading).
    case modelNotReady(modelId: String)
    /// The speech model failed to download.
    case modelDownloadFailed(reason: String)
    /// Audio capture failed (no input device, recorder error, empty recording).
    case audioCaptureFailed(reason: String)
    /// Transcription failed inside the ASR engine.
    case transcriptionFailed(reason: String)
    /// Refinement failed. Callers generally treat this as recoverable by
    /// falling back to the raw transcript rather than surfacing it.
    case refinementFailed(reason: String)
    /// Delivering the text to the target app failed.
    case outputFailed(reason: String)
    /// The run was cancelled by the user.
    case cancelled
}

extension DictationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is not granted."
        case .accessibilityPermissionDenied:
            return "Accessibility access is not granted, so Freest can't paste at the cursor."
        case .modelNotReady(let modelId):
            return "The speech model \"\(modelId)\" isn't downloaded yet."
        case .modelDownloadFailed(let reason):
            return "Downloading the speech model failed: \(reason)"
        case .audioCaptureFailed(let reason):
            return "Recording failed: \(reason)"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        case .refinementFailed(let reason):
            return "Text refinement failed: \(reason)"
        case .outputFailed(let reason):
            return "Delivering the text failed: \(reason)"
        case .cancelled:
            return "Dictation was cancelled."
        }
    }
}
