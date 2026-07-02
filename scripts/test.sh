#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Jerry Chen
#
# Run the Freest test suite.
#
# When a full Xcode toolchain is selected, `swift test` finds swift-testing on
# its own and this script just forwards to it. When only the Command Line Tools
# are installed, swift-testing ships as a framework that is NOT on SwiftPM's
# default search path, so we locate `Testing.framework` (and its interop dylib)
# and add the needed search paths + runtime rpaths. Extra args are forwarded to
# `swift test` (e.g. `scripts/test.sh --filter Pipeline`).
set -euo pipefail

cd "$(dirname "$0")/.."

# If a real Xcode is selected, plain `swift test` works.
dev_dir="$(xcode-select -p 2>/dev/null || true)"
if [[ "$dev_dir" == *"Xcode"* ]]; then
    exec swift test "$@"
fi

# Command Line Tools path: find the bundled swift-testing framework + interop lib.
fw_dir="$dev_dir/Library/Developer/Frameworks"
lib_dir="$dev_dir/Library/Developer/usr/lib"

if [[ ! -d "$fw_dir/Testing.framework" ]]; then
    echo "error: Testing.framework not found under $fw_dir" >&2
    echo "       Install a full Xcode or a Swift toolchain that bundles swift-testing." >&2
    exit 1
fi

exec swift test \
    -Xswiftc -F -Xswiftc "$fw_dir" \
    -Xlinker -rpath -Xlinker "$fw_dir" \
    -Xlinker -rpath -Xlinker "$lib_dir" \
    "$@"
