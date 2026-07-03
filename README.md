# Freest

A free, fully offline, on-device dictation app for the macOS menu bar. Press a
global hotkey, speak, and Freest transcribes your speech locally and pastes it
at the cursor — no accounts, no API keys, no cloud.

### 🌐 Website & easy setup

**→ [jerrychen1974.github.io/Freest](https://jerrychen1974.github.io/Freest/)** — the
landing page with one-glance setup, the dictation hotkey, and a copy-paste prompt
for AI agents.

- **Humans:** follow [`docs/SETUP.md`](docs/SETUP.md).
- **AI agents:** point your coding agent at
  [`docs/llms.txt`](docs/llms.txt) — it's a machine-readable guide the agent can
  execute end to end. Or paste this to your agent:

  > Set up Freest (offline macOS voice dictation) on my Mac. Read
  > https://jerrychen1974.github.io/Freest/llms.txt and follow it: clone this
  > repo, build with `scripts/build-app.sh`, help me grant Microphone +
  > Accessibility permissions, download the default speech model, and confirm
  > the ⌃⌥D dictation hotkey works.

## Quick start

```sh
git clone https://github.com/JerryChen1974/Freest.git
cd Freest
scripts/build-app.sh     # builds & ad-hoc-signs Freest.app
open Freest.app
```

Then, on first launch:

1. Grant **Microphone** (to hear you) and **Accessibility** (to paste at the cursor).
2. Download the default **base** speech model from the menu bar (one time).
3. Hold **⌃⌥D**, speak, release — your words are pasted at the cursor. That's it.

## Requirements

- macOS 14 or later.
- Apple Silicon is required only for the optional **Apple Intelligence** refinement
  mode (macOS 26+); all other features run on any supported Mac.

## Build & test

```sh
swift build          # compile
swift test           # run the unit tests (with a full Xcode toolchain)
scripts/test.sh      # run the unit tests (also works with Command Line Tools only)
```

> `scripts/test.sh` forwards to `swift test` under a full Xcode, and otherwise
> points SwiftPM at the swift-testing framework bundled with the Command Line
> Tools (which isn't on the default search path). Extra args are forwarded,
> e.g. `scripts/test.sh --filter Pipeline`.

## Package the app

A self-contained `Freest.app` bundle is assembled and ad-hoc code-signed with:

```sh
scripts/build-app.sh
```

## Refinement modes

- **Off** — paste the raw transcription.
- **Tidy** — local rule-based cleanup (trim, collapse spaces, sentence casing,
  terminal punctuation, drop leading filler words). Fully offline, no model.
- **Apple Intelligence** — on-device LLM cleanup via Apple's FoundationModels
  (macOS 26+, Apple Silicon). Falls back to **Tidy** where unavailable.

The hotkey, model, refinement mode, and input device are all configurable in
Settings.

## Offline guarantee

The only time Freest uses the network is the one-time model download. Recording,
transcription, and refinement all run on-device; nothing you dictate leaves your
Mac.

## License

Apache License 2.0 — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
Third-party components and their licenses are listed in
[`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md). Provenance is documented in
[`docs/clean-room.md`](docs/clean-room.md).
