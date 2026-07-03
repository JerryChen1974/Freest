// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation

/// Reports whether on-device Apple Intelligence refinement is usable right now.
/// Injected as a value so both the AI-selected and the fallback-to-tidy paths
/// are unit-testable on any CI OS, regardless of the host's real capabilities.
public struct RefinementAvailability: Sendable {
    /// True when Apple's on-device language model is available for refinement.
    public let isAppleIntelligenceAvailable: @Sendable () -> Bool

    public init(isAppleIntelligenceAvailable: @escaping @Sendable () -> Bool) {
        self.isAppleIntelligenceAvailable = isAppleIntelligenceAvailable
    }

    /// The real check: compiles against FoundationModels only where available
    /// (macOS 26+), and reports the system model's actual availability. On any
    /// OS/toolchain without FoundationModels this is a compile-time `false`.
    public static let system = RefinementAvailability {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return AppleIntelligenceProbe.isModelAvailable()
        } else {
            return false
        }
        #else
        return false
        #endif
    }

    /// Test seams.
    public static let alwaysAvailable = RefinementAvailability { true }
    public static let neverAvailable = RefinementAvailability { false }
}
