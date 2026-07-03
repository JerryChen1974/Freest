#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Jerry Chen
#
# Assemble a launchable, ad-hoc-signed Freest.app from the SwiftPM release
# build. `swift build` emits a bare Mach-O executable, not a macOS app bundle,
# so this script:
#   1. Builds the release binary.
#   2. Lays out Freest.app/Contents/{MacOS,Resources}.
#   3. Copies the executable and Info.plist.
#   4. Copies every SwiftPM resource bundle (*.bundle) next to the binary, so
#      dependencies that use Bundle.module (KeyboardShortcuts, WhisperKit's
#      transitive libs) don't fatalError at launch.
#   5. Ad-hoc code-signs with a stable identifier AND an explicit designated
#      requirement, so TCC microphone/accessibility grants persist across
#      rebuilds (a cdhash-based DR would go stale every build).
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

APP_NAME="Freest"
BUNDLE_ID="com.jerrychen.freest"
CONFIG="release"
BUILD_BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
APP="$ROOT/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RES_DIR="$CONTENTS/Resources"

echo "==> Building release binary"
swift build -c "$CONFIG" -Xswiftc -warnings-as-errors

echo "==> Assembling $APP_NAME.app"
rm -rf "$APP"
mkdir -p "$MACOS_DIR" "$RES_DIR"

# 1. Executable.
cp "$BUILD_BIN_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"

# 2. Info.plist.
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"

# 3. Resource bundles: copy every *.bundle SwiftPM produced next to the binary.
shopt -s nullglob
bundles=("$BUILD_BIN_DIR"/*.bundle)
if [ ${#bundles[@]} -eq 0 ]; then
    echo "    (no *.bundle resources found — continuing)"
else
    for bundle in "${bundles[@]}"; do
        echo "    copying $(basename "$bundle")"
        cp -R "$bundle" "$RES_DIR/"
    done
fi
shopt -u nullglob

echo "==> Ad-hoc code-signing with a designated requirement"
# The --requirements DR override (not --identifier alone) is what makes TCC
# grants survive rebuilds: it pins trust to the bundle identifier rather than
# the (per-build) cdhash.
codesign --force --sign - \
    --identifier "$BUNDLE_ID" \
    --requirements "=designated => identifier \"$BUNDLE_ID\"" \
    --entitlements "$ROOT/Resources/$APP_NAME.entitlements" \
    --timestamp=none \
    "$APP"

echo "==> Verifying signature"
codesign --verify --verbose=2 "$APP"

echo "==> Done: $APP"
