<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Jerry Chen -->

# Setting up Freest

Freest is a free, fully offline voice-dictation app for the macOS menu bar.
Hold **⌃⌥D** (Control-Option-D), speak, release — your words are typed at the
cursor. No accounts, no cloud, no API keys.

> **Using an AI agent?** Point it at
> [`llms.txt`](./llms.txt) — it's the same steps in a machine-readable form, and
> most coding agents can run the whole setup for you. Or paste this to your agent:
>
> > Set up Freest (offline macOS voice dictation) on my Mac. Read
> > https://jerrychen1974.github.io/Freest/llms.txt and follow it: clone
> > https://github.com/JerryChen1974/Freest, build with `scripts/build-app.sh`,
> > help me grant Microphone + Accessibility permissions, download the default
> > speech model, and confirm the ⌃⌥D hotkey works.

## Requirements

- **macOS 14** (Sonoma) or later.
- The **Xcode Command Line Tools** (for the Swift compiler). Install with
  `xcode-select --install` if `swift --version` fails. A full Xcode is *not*
  required to build or run the app.
- **Apple Silicon** only if you want the optional Apple Intelligence refinement
  mode (macOS 26+). Everything else runs on any supported Mac.

## 1. Build the app

```sh
git clone https://github.com/JerryChen1974/Freest.git
cd Freest
scripts/build-app.sh
open Freest.app
```

`build-app.sh` compiles a release build, assembles `Freest.app`, and ad-hoc
signs it. Freest then appears as a small waveform icon in your menu bar (no Dock
icon, no window).

## 2. Grant permissions (first launch)

On first use, macOS will prompt for two permissions — approve both:

| Permission | Why | Where |
|---|---|---|
| **Microphone** | so Freest can hear you | System Settings ▸ Privacy & Security ▸ Microphone |
| **Accessibility** | so Freest can paste at the cursor | System Settings ▸ Privacy & Security ▸ Accessibility |

## 3. Download the speech model (one time)

From the menu-bar dropdown, click **Download model (base)**. This is the only
step that uses the network. When it says **Model ready: base**, you're fully
offline from here on.

## 4. Dictate

1. Click into any text field.
2. Hold **⌃⌥D**.
3. Speak.
4. Release — your words are pasted at the cursor.

## Settings

Open **Settings** from the menu bar to change:

- **Hotkey** — default ⌃⌥D.
- **Model** — tiny / base / small / medium / large-v3 (larger = more accurate,
  slower, bigger download).
- **Refinement** — Off (raw), Tidy (local cleanup), or Apple Intelligence
  (on-device; falls back to Tidy where unavailable).
- Input device, paste-at-cursor, press-Return-after-paste.

## Troubleshooting

- **Hotkey does nothing** → confirm Accessibility is granted and the model shows
  "ready".
- **"Model not ready"** → finish step 3 first.
- **It heard me but nothing pasted** → check Accessibility trust.
- **`swift test` can't find `Testing`** → that only affects the optional test
  suite, not the app; use `scripts/test.sh` or skip it.

## License

Apache-2.0. See [`LICENSE`](https://github.com/JerryChen1974/Freest/blob/main/LICENSE).
