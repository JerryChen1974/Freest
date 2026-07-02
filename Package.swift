// swift-tools-version: 6.0
// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import PackageDescription

// Freest is built up incrementally. Only targets whose sources exist are
// declared here, so `swift build` always compiles. Increment 1 declares just
// the pure domain core (`FreestCore`) and its tests; the audio, ASR, refine,
// storage, and app targets are added in later increments.
let package = Package(
    name: "Freest",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "FreestCore", targets: ["FreestCore"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FreestCore",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "FreestCoreTests",
            dependencies: ["FreestCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
