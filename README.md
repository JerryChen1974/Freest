# Freest

A fully offline, on-device dictation app for the macOS menu bar. Press a global
hotkey, speak, and Freest transcribes your speech locally and pastes it at the
cursor — no accounts, no API keys, no cloud.

> **Status:** early development. This repository is being built in increments;
> the menu-bar app and its packaging land in a later increment. See
> [`plans/`](plans/) for the design and build sequence.

## Requirements

- macOS 14 or later.
- Apple Silicon is required for the optional **Apple Intelligence** refinement
  mode (macOS 26+); all other features run on any supported Mac.

## Build

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

Once the app target lands, a self-contained `Freest.app` bundle is assembled and
ad-hoc code-signed with:

```sh
scripts/build-app.sh
```

## First run

1. Grant **microphone** access when prompted.
2. Grant **Accessibility** access (needed to paste at the cursor in other apps).
3. Download the default speech model (**base**) — a one-time download; after
   that, transcription is fully offline.
4. Press the default hotkey **⌃⌥D**, speak, and your words are pasted at the
   cursor.

The hotkey, model, refinement mode, and input device are all configurable in
Settings.

## Refinement modes

- **Off** — paste the raw transcription.
- **Tidy** — local rule-based cleanup (trim, collapse spaces, sentence casing,
  terminal punctuation, drop leading filler words). Fully offline, no model.
- **Apple Intelligence** — on-device LLM cleanup via Apple's FoundationModels
  (macOS 26+, Apple Silicon). Falls back to **Tidy** where unavailable.

## Offline guarantee

The only time Freest uses the network is the one-time model download. Recording,
transcription, and refinement all run on-device; nothing you dictate leaves your
Mac.

## License

Apache License 2.0 — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
Third-party components and their licenses are listed in
[`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md). Provenance is documented in
[`docs/clean-room.md`](docs/clean-room.md).
