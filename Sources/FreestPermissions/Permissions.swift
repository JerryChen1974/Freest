// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import AVFoundation
import AppKit
import ApplicationServices
import FreestCore

/// The state of a single permission Freest needs.
public enum PermissionStatus: Sendable, Equatable {
    case granted
    case denied
    case notDetermined
}

/// Checks and requests the two OS permissions Freest needs: microphone access
/// (TCC, via `AVCaptureDevice`) and Accessibility trust (needed to paste at the
/// cursor). OS-gated, so covered by the manual smoke test.
public struct Permissions: Sendable {

    public init() {}

    // MARK: - Microphone

    /// The current microphone authorization status.
    public func microphoneStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return .granted
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    /// Prompt for microphone access if not yet determined; returns the outcome.
    @discardableResult
    public func requestMicrophone() async -> PermissionStatus {
        switch microphoneStatus() {
        case .granted: return .granted
        case .denied: return .denied
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            return granted ? .granted : .denied
        }
    }

    // MARK: - Accessibility (AX) trust

    /// Whether the app is trusted for Accessibility (required to send the
    /// synthetic ⌘V that pastes at the cursor).
    public func accessibilityStatus() -> PermissionStatus {
        AXIsProcessTrusted() ? .granted : .notDetermined
    }

    /// Show the system prompt that asks the user to grant Accessibility trust
    /// (opens the System Settings pane on first call). Returns the current
    /// trust state; the grant itself completes out-of-process.
    @discardableResult
    public func requestAccessibility() -> PermissionStatus {
        // The documented key string for the "prompt" option. Using the literal
        // avoids referencing the non-concurrency-safe global `var`
        // `kAXTrustedCheckOptionPrompt` under Swift 6 strict concurrency.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        return trusted ? .granted : .notDetermined
    }

    /// Open the Accessibility pane in System Settings, for a "fix this" button.
    public func openAccessibilitySettings() {
        if let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Open the Microphone pane in System Settings.
    public func openMicrophoneSettings() {
        if let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
}
