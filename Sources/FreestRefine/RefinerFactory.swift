// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import FreestCore

/// Builds the `Refiner` for a given `RefinementMode`. When `.appleIntelligence`
/// is selected but unavailable, the returned `AppleIntelligenceRefiner`
/// transparently falls back to `TextTidier` at refine time (reporting `.tidy`),
/// so mode selection never fails.
public struct RefinerFactory: Sendable {
    private let availability: RefinementAvailability

    public init(availability: RefinementAvailability = .system) {
        self.availability = availability
    }

    /// The refiner for `mode`.
    public func makeRefiner(for mode: RefinementMode) -> any Refiner {
        switch mode {
        case .off:
            return PassthroughRefiner()
        case .tidy:
            return TidyRefiner()
        case .appleIntelligence:
            return AppleIntelligenceRefiner(availability: availability)
        }
    }

    /// Whether the Apple Intelligence option should be offered as *effective*
    /// (vs. shown but falling back). The UI uses this to label the choice.
    public var isAppleIntelligenceEffective: Bool {
        availability.isAppleIntelligenceAvailable()
    }
}
