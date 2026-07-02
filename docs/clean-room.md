# Clean-room provenance

Freest is original, independently authored software. This document records the
method by which it was written and attests that no proprietary reference source
was copied into it.

## Method

Freest was written from the *ideas* of a general dictation-app architecture —
global hotkey → record microphone → local speech-to-text → optional local
text cleanup → paste at the cursor — combined with the **public documentation**
of each library and OS framework it integrates. It was **not** produced by
copying, translating, or adapting the source code of any proprietary reference
application.

## Structural isolation rule (strict)

During implementation the author and any assisting agent **do not read, search,
open, or otherwise consult the source of any proprietary reference application.**
No file under a proprietary reference tree is opened during the build of Freest.
Any behavioral knowledge that informed the design was reduced to plain-English
notes in the project's planning documents *before* implementation began, and the
reference source is off-limits from that point forward. This is a hard rule, not
a preference.

Naming follows from this rule:

- Generic pattern names that any Swift engineer would independently reach for are
  used freely (`Pipeline`, `Sink`, `Clock`, `AudioCapturing`, `ASREngine`,
  `Refiner`, `AudioFile`).
- Names for domain-specific concepts are **independently derived** and do not
  echo any reference application's specific coinages. See the naming choices in
  the design plan.
- Module names are plain functional nouns: Core, Audio, ASR, Refine, Storage,
  Output, Permissions, Hotkey, Indicator, UI, App.

## Public documentation — source of truth per area

Every integration is written against the underlying library / OS public docs:

| Area | Public source of truth |
|---|---|
| Speech-to-text | WhisperKit README and public API (github.com/argmaxinc/WhisperKit) |
| Microphone capture | Apple AVFoundation documentation |
| Paste at cursor / synthetic key events | Apple AppKit `NSPasteboard`, Core Graphics events, Accessibility (AX) documentation |
| Global hotkey | KeyboardShortcuts README (github.com/sindresorhus/KeyboardShortcuts) |
| On-device text refinement | Apple FoundationModels documentation (macOS 26+, Apple Silicon) |
| Menu-bar UI, floating indicator | Apple SwiftUI and AppKit (`MenuBarExtra`, `NSPanel`, `NSHostingView`) documentation |
| Permissions (mic, accessibility) | Apple AVFoundation `AVCaptureDevice` authorization; `AXIsProcessTrusted` |

## Per-file provenance

Every source file carries an SPDX identifier header:

```
// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Jerry Chen
```

## Attestation

No proprietary reference source code was copied, translated, or adapted into
Freest. Freest's expression is original work authored under the isolation rule
above and is licensed by its author, Jerry Chen, under the Apache License 2.0.
