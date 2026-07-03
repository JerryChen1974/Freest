# Third-Party Notices

Freest bundles and/or depends on the following third-party components. Each is
distributed under its own license, reproduced or referenced below. Freest does
not relicense any of these; they remain under their original terms.

> This file is kept in sync with `Package.resolved` and updated whenever a
> dependency is added or its version changes. Freest pins KeyboardShortcuts to
> the 1.15.x line (`>=1.10.0, <1.16.0`) because 1.16.0+ uses the `#Preview`
> macro, whose `PreviewsMacros` plugin ships only with a full Xcode toolchain
> (not the Command Line Tools). KeyboardShortcuts has no third-party transitive
> dependencies of its own.

---

## WhisperKit

- **Purpose:** On-device automatic speech recognition (Whisper models via Core ML).
- **License:** Apache License 2.0
- **Project:** https://github.com/argmaxinc/WhisperKit

Licensed under the Apache License, Version 2.0. A copy of the Apache 2.0 license
text is included in this repository at [`LICENSE`](LICENSE).

### WhisperKit transitive dependencies

Resolved from `Package.resolved` (WhisperKit 0.18.0). Freest depends on none of
these directly; they are pulled in through WhisperKit. Each keeps its own
license.

| Component | Version | License | Project |
|---|---|---|---|
| swift-transformers | 1.1.9 | Apache-2.0 | https://github.com/huggingface/swift-transformers |
| swift-jinja | 2.3.6 | Apache-2.0 | https://github.com/huggingface/swift-jinja |
| swift-argument-parser | 1.8.2 | Apache-2.0 | https://github.com/apple/swift-argument-parser |
| swift-crypto | 4.5.0 | Apache-2.0 | https://github.com/apple/swift-crypto |
| swift-asn1 | 1.7.1 | Apache-2.0 | https://github.com/apple/swift-asn1 |
| swift-collections | 1.6.0 | Apache-2.0 | https://github.com/apple/swift-collections |
| yyjson | 0.12.0 | MIT | https://github.com/ibireme/yyjson |

---

## KeyboardShortcuts

- **Purpose:** User-recordable global keyboard shortcuts on macOS.
- **Version:** 1.15.0 (pinned `>=1.10.0, <1.16.0`; see note above)
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
