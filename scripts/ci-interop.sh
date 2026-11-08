#!/usr/bin/env bash
# Run the Android integration test, capture the device-generated payload, and
# decrypt it with the Linux core. Used by the cross-platform CI workflow.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE="${ANDROID_SERIAL:-emulator-5554}"

cd "$ROOT/app"
flutter test integration_test/interop_test.dart -d "$DEVICE" | tee /tmp/interop.log

PAYLOAD="$(grep -o 'X_INTEROP_CIPHERTEXT=.*' /tmp/interop.log | head -1 | cut -d= -f2-)"
if [[ -z "$PAYLOAD" ]]; then
  echo "Android integration test did not emit a payload." >&2
  exit 1
fi

cd "$ROOT/core"
printf '%s' "$PAYLOAD" | cargo run --release --features fixtures \
  --bin x-fixture -- open --pass 'correct horse battery staple' \
  | grep -q 'Android to Linux interoperability check'
echo "PASS: Android-generated payload decrypted by the Linux core."
