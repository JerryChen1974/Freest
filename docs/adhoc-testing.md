# Ad-hoc testing — Freest.app manual smoke test

`swift test` covers the pure logic (core state machine, storage, ASR policy,
refinement rules). The OS-gated parts — real microphone capture, global hotkey,
synthetic paste, permission prompts, the floating indicator, and the actual
Apple Intelligence / WhisperKit runtime behavior — can only be verified by
running the assembled app. This file is the checklist and the evidence log.

## Build the app

```sh
scripts/build-app.sh          # produces ./Freest.app (release, ad-hoc signed)
open Freest.app
```

## Automated pre-checks (run by the build/gate, recorded here)

These were verified mechanically and do not need a human:

- [x] `swift build -c release -Xswiftc -warnings-as-errors` — clean.
- [x] `scripts/build-app.sh` — assembles `Freest.app`, copies resource bundles
      (`KeyboardShortcuts_KeyboardShortcuts.bundle`, `swift-crypto_Crypto.bundle`,
      `swift-transformers_Hub.bundle`), ad-hoc signs.
- [x] `codesign --verify` — "valid on disk" and "satisfies its Designated
      Requirement"; DR is `identifier "com.jerrychen.freest"` (identifier-based,
      so TCC grants persist across rebuilds).
- [x] `plutil -p Contents/Info.plist` — `LSUIElement = true`,
      `CFBundleIdentifier = com.jerrychen.freest`, `NSMicrophoneUsageDescription`
      present.
- [x] Cold launch — process stays up, runs as a menu-bar accessory (no Dock
      icon), no `Bundle.module` fatalError in the process log.

## Manual smoke checklist (requires a human at the keyboard)

Perform in order. Record pass/fail and notes in the evidence block below.

1. **Fresh launch, no model.** With `~/Library/Application Support/Freest/models/`
   absent, launch the app. The menu-bar dropdown shows a "Download model (base)"
   affordance (not a transcription attempt).
2. **Download the base model.** Click download; a progress indicator runs; on
   completion the menu shows "Model ready: base". (Network is used only here.)
3. **Grant permissions.** On the first record attempt, macOS prompts for
   Microphone and Accessibility. Grant both. Denial must show a clear state in
   the Permissions pane, not a crash.
4. **Dictate into TextEdit.** Focus a TextEdit document, press and hold **⌃⌥D**,
   say *"testing one two three"*, release. Confirm that exact text is pasted at
   the cursor and the previous clipboard contents are restored afterward.
5. **Refinement modes.** In Settings → Refinement, try Off / Tidy /
   Apple Intelligence. Confirm Off pastes raw, Tidy cleans up casing/punctuation,
   and Apple Intelligence either refines (macOS 26+/Apple-Silicon with the model
   enabled) or is labeled "unavailable — uses Tidy" and falls back.
6. **Persist settings.** Change the model and the hotkey in Settings, quit, and
   relaunch. Confirm both survived (settings persisted to
   `~/.config/freest/config.json`).
7. **Negatives.** (a) Deny microphone → clear error, no crash. (b) Trigger
   dictation with the model missing → clear "model not ready" state, no crash.

## Offline check

With the model already downloaded, turn Wi-Fi **off** and repeat step 4.
Expected: transcription still succeeds and no outbound connection is made
(corroborate with `lsof -i -a -p <pid>` or `nettop -p <pid>`).

## Evidence log

> Fill in when the manual pass is run.

- Date:
- macOS version:
- Hardware (chip):
- Model id used:
- Steps 1–7 result:
- Offline check result:
- Screenshot of pasted text: (attach)
- Notes / anomalies:
