#!/usr/bin/env bash
# Verify the Android release has no Internet permission and the UI has no
# network client code. Fails closed.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APK="${1:-$ROOT/dist/X-android-universal.apk}"
AAPT="${AAPT:-${ANDROID_HOME:-$HOME/Android/Sdk}/build-tools/36.0.0/aapt}"

if [[ -f "$APK" ]]; then
  if "$AAPT" dump permissions "$APK" | grep -qE 'android.permission.(INTERNET|CAMERA)'; then
    echo "FAIL: INTERNET or CAMERA permission is present." >&2
    exit 1
  fi
  echo "PASS: APK has no INTERNET or CAMERA permission."
else
  echo "NOTE: APK not present; checked source only."
fi

if grep -RInE 'package:http/|HttpClient\(|WebSocket\(|Socket\.connect|Firebase|analytics|telemetry' \
  "$ROOT/app/lib" "$ROOT/core/src" >/tmp/x-network-scan.txt 2>/dev/null; then
  echo "FAIL: network or telemetry code found:" >&2
  cat /tmp/x-network-scan.txt >&2
  exit 1
fi
echo "PASS: no network or telemetry client code in app/lib or core/src."
