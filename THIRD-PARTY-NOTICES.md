# Third-Party Notices

Freest bundles and/or depends on the following third-party components. Each is
distributed under its own license, reproduced or referenced below. Freest does
not relicense any of these; they remain under their original terms.

> Note: The full dependency set (including transitive dependencies) is finalized
> in later increments as the ASR and hotkey modules are added. This file is kept
> in sync with `Package.resolved` and updated whenever a dependency is added or
> its version changes.

---

## WhisperKit

- **Purpose:** On-device automatic speech recognition (Whisper models via Core ML).
- **License:** Apache License 2.0
- **Project:** https://github.com/argmaxinc/WhisperKit

Licensed under the Apache License, Version 2.0. A copy of the Apache 2.0 license
text is included in this repository at [`LICENSE`](LICENSE).

### WhisperKit transitive dependencies

- **swift-transformers** — Apache License 2.0 — https://github.com/huggingface/swift-transformers
- **swift-argument-parser** — Apache License 2.0 — https://github.com/apple/swift-argument-parser
  (pulled in transitively; Freest itself does not use it directly)

> These transitive components are enumerated precisely from `Package.resolved`
> once WhisperKit is wired in (Increment 2). Any additional transitive licenses
> will be added here at that time.

---

## KeyboardShortcuts

- **Purpose:** User-recordable global keyboard shortcuts on macOS.
- **License:** MIT License
- **Project:** https://github.com/sindresorhus/KeyboardShortcuts

```
MIT License

Copyright (c) Sindre Sorhus <sindresorhus@gmail.com> (https://sindresorhus.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
