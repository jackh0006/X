#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$HOME/Android/Sdk/ndk/28.2.13676358}"
JNI="$ROOT/app/android/app/src/main/jniLibs"

cd "$ROOT/core"
cargo ndk -t armeabi-v7a -t arm64-v8a -t x86_64 -o "$JNI" build --release --locked
if [[ "${WITH_X86_64:-0}" == "1" ]]; then
  cargo ndk -t x86_64 -o "$JNI" build --release --locked
fi

cd "$ROOT/app"
flutter build apk --release --target-platform android-arm,android-arm64,android-x64
mkdir -p "$ROOT/dist"
cp build/app/outputs/flutter-apk/app-release.apk "$ROOT/dist/X-android-universal.apk"
printf 'apk: %s\n' "$ROOT/dist/X-android-universal.apk"
