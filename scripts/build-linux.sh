#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT/scripts/build-core.sh"
cd "$ROOT/app"
flutter build linux --release
BUNDLE="$ROOT/app/build/linux/x64/release/bundle"
mkdir -p "$BUNDLE/lib"
cp "$ROOT/core/target/release/libx_core.so" "$BUNDLE/lib/"
printf 'linux bundle: %s\n' "$BUNDLE"
