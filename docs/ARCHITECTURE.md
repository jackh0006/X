# Architecture

## Components

```
┌──────────────────────────────────────────────┐
│ Flutter UI (Dart, Material 3)                │
│  Send · Receive · Donate · About             │
│  Clipboard · file picker · Android share     │
└───────────────┬──────────────────────────────┘
                │ dart:ffi (C ABI, JSON results)
┌───────────────▼──────────────────────────────┐
│ x-core (Rust cdylib + rlib)                  │
│  format.rs   strict parser and serializer    │
│  crypto.rs   Argon2id + XChaCha20-Poly1305   │
│  limits.rs   size/KDF caps and profiles      │
│  passphrase.rs  7-word EFF generator         │
│  ffi.rs      four exported functions         │
└───────────────┬──────────────────────────────┘
                │ safe bindings (libsodium-rs)
┌───────────────▼──────────────────────────────┐
│ libsodium 1.0.22 (vendored, static)          │
│  crypto_pwhash (Argon2id v1.3)               │
│  crypto_aead_xchacha20poly1305_ietf_*         │
│  randombytes_buf                             │
└──────────────────────────────────────────────┘
```

## FFI contract

The boundary is deliberately small. Every function returns a heap-allocated
JSON C string and is freed with `x_free_string`:

| Function | Purpose |
|---|---|
| `x_encrypt(message, passphrase, profile)` | Encrypt UTF-8 bytes, return `X1.…` |
| `x_decrypt(payload, passphrase)` | Authenticate and return UTF-8 plaintext |
| `x_inspect(payload)` | Parse without a passphrase; return metadata |
| `x_generate_passphrase(words)` | CSPRNG Diceware passphrase |
| `x_core_version()` | Static version string |
| `x_free_string(ptr)` | Release a returned string |

Success: `{"ok":true,"value":"…"}`. Failure:
`{"ok":false,"code":"AUTHENTICATION_FAILED","message":"…"}`.

All pointer/length pairs are validated. Exported functions catch panics at the
boundary so unwinding never crosses into Dart. KDF and encryption run in a Dart
isolate so the UI stays responsive.

## Why a manual C ABI instead of a bridge generator

The surface is four functions with simple byte/string arguments. A manual C ABI
keeps the dependency graph and generated code out of the security boundary and
is easy to inspect. The trade-off is that the FFI layer is `unsafe` Rust; it is
small, explicitly documented, and covered by round-trip and error-shape tests.

## Platforms

### Android

- `flutter build apk --release --target-platform android-arm64`
- `cargo ndk -t arm64-v8a` produces `jniLibs/arm64-v8a/libx_core.so`
- `MainActivity.kt` provides two Android-only actions over a method channel:
  `ACTION_SEND` sharing and `ACTION_CREATE_DOCUMENT` saving via SAF.
- No `INTERNET` permission; `allowBackup=false`; `usesCleartextTraffic=false`.
- App id `com.jackh0006.x`, minSdk 24, target/compileSdk 36.

### Ubuntu

- Flutter GTK bundle installed under `/opt/x`, symlink `/usr/bin/x`.
- `libx_core.so` sits beside the bundle in `/opt/x/lib`; the Dart loader resolves
  it relative to the executable and the bundle uses an `$ORIGIN/lib` rpath.
- Desktop entry and hicolor icons installed by the DEB.
- The GTK header bar follows the in-app light/dark theme through a tiny method
  channel.

## Data flow

1. UI collects text and passphrase as Dart strings.
2. Dart encodes UTF-8 bytes and passes pointer/length pairs to `x_encrypt`.
3. Rust validates lengths, derives the key, builds the authenticated header and
   encrypts.
4. Dart receives only the `X1.…` string; it is never logged.
5. On receive, the same steps run in reverse; plaintext is returned only after
   authentication.

## Dependencies

- Rust: libsodium-rs, base64, serde/serde_json, zeroize. Dev-only: argon2,
  chacha20poly1305, proptest, hex.
- Flutter: ffi, file_selector, shared_preferences. Dev-only: flutter_test,
  integration_test, flutter_launcher_icons.
- No network, analytics, ads, crash reporting or account SDK.

## Build and release

`scripts/build-core.sh`, `scripts/build-linux.sh`, `scripts/build-android.sh`,
`scripts/build-deb.sh`, and `scripts/generate_sbom.py`. CI runs the test and
security gates; the release workflow builds and signs artifacts, generates
checksums/SBOM, attests provenance and publishes the GitHub release.
