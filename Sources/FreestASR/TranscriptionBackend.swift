// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen

import Foundation
import FreestCore

/// The narrow contract Freest needs from a speech-to-text backend. WhisperKit is
/// wrapped behind this so `WhisperKitASREngine` — the readiness/download/error
/// logic — is unit-testable against a fake, with no network or Core ML models.
public protocol TranscriptionBackend: Sendable {
    /// Load (and, if necessary, download) the given WhisperKit variant, storing
    /// it under `downloadBase`. Called before the first transcription.
    func loadModel(variant: String, downloadBase: URL) async throws

    /// Transcribe the audio file at `url`, returning the recognized text.
    func transcribe(audioAt url: URL) async throws -> String
}

/// Decides whether a model is present on disk, so Freest can show a "download"
/// state instead of attempting to transcribe with nothing. Injected as a
/// closure keeps `FreestASR` free of any concrete filesystem dependency.
public struct ModelReadiness: Sendable {
    /// Returns true when the model directory holds a usable (non-pointer)
    /// `*.mlmodelc`. Default implementation checks the real filesystem.
    public let isReady: @Sendable (_ directory: URL) -> Bool

    public init(isReady: @escaping @Sendable (_ directory: URL) -> Bool) {
        self.isReady = isReady
    }

    /// The real check: the directory exists and contains at least one
    /// `.mlmodelc` whose total size clears a small sanity threshold (guards
    /// against Git LFS pointer files or a half-finished download).
    public static let system = ModelReadiness { directory in
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
            return false
        }
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isDirectoryKey]
        ) else { return false }

        let minimumBytes = 1_000_000 // 1 MB — real weights dwarf this; pointers don't.
        for case let url as URL in enumerator where url.pathExtension == "mlmodelc" {
            let size = Self.directorySize(of: url)
            if size >= minimumBytes { return true }
        }
        return false
    }

    private static func directorySize(of url: URL) -> Int {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey]
        ) else { return 0 }
        var total = 0
        for case let file as URL in enumerator {
            let values = try? file.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
            total += values?.totalFileAllocatedSize ?? 0
        }
        return total
    }
}
