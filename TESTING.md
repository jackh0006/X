# Testing

## Quick local gate

```bash
cd core
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --release
cargo audit
cargo deny check

cd ../app
flutter analyze
flutter test

cd ..
./scripts/build-linux.sh
./scripts/build-deb.sh
```

Android:

```bash
export ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk/28.2.13676358"
./scripts/build-android.sh
$ANDROID_HOME/build-tools/36.0.0/apksigner verify --print-certs dist/app-release.apk
```

## Module → test map

| Source | Tests |
|---|---|
| `core/src/format.rs` | parser/encoder unit, proptest, fuzz target |
| `core/src/crypto.rs` | Argon2id and XChaCha20-Poly1305 cross-checks, tamper tests |
| `core/src/limits.rs` | KDF bounds, size limits, profile metadata |
| `core/src/passphrase.rs` | word count, uniqueness, entropy |
| `core/src/ffi.rs` | FFI round-trip, error shape, UTF-8 |
| `app/lib/screens/*` | widget tests: navigation, send, receive, donate, about |
| `app/lib/theme/*` | light/dark switching, screenshots |
| `app/integration_test/*` | Linux and Android fixture interoperability |
| `packaging/linux/*` | DEB inspection, extraction, launch |

## Test impact strategy

- **Core crypto/format change:** run all Rust tests, fuzz the parser, rebuild
  both artifacts, rerun cross-platform interoperability, and re-review the
  format document. This is an expanded gate.
- **UI-only change:** `flutter analyze`, widget tests, rebuild Linux screenshots
  if visuals changed.
- **Dependency change:** lockfile review, `cargo audit`, `cargo deny`, full
  tests, rebuild both packages.
- **Docs/CI-only change:** lint YAML, run the affected workflow, no crypto
  re-review.

Previously validated modules do not need a full re-review for unrelated
changes, but every release still runs the mandatory gate below.

## Mandatory release gate

1. Rust unit/integration tests, clippy, fmt, audit, deny.
2. Full cryptographic regression suite.
3. Flutter analyze + all widget/native tests.
4. Cross-platform interoperability workflow.
5. APK build, signature, package id, arm64 core presence.
6. DEB build, metadata, extraction, launch.
7. Secret scan, dependency review, SBOM.
8. Checksums and artifact integrity.
9. Screenshots from the actual package when UI changed.

## Fuzzing

```bash
cd core
cargo +nightly fuzz run -s none parse -- -max_total_time=60
```

AddressSanitizer is currently blocked by the vendored libsodium C build; the
parser campaign runs with coverage instrumentation but without ASAN. This is
recorded honestly in [`docs/TEST_RESULTS.md`](docs/TEST_RESULTS.md).

## Automated vs independent

Automated tests and self-review are not a formal audit. Do not describe a green
CI run as proof of security.
