# Building

## Prerequisites

- Ubuntu 24.04 (tested), amd64
- Rust 1.88+ (tested 1.98.1) with `rustup`
- Flutter 3.47.6 stable / Dart 3.13.5
- Linux: `clang cmake ninja-build pkg-config libgtk-3-dev libblkid-dev
  liblzma-dev libsecret-1-dev`
- Android: JDK 21, Android SDK 36, NDK 28.2.13676358, `cargo-ndk`
- `dpkg-deb`, `fakeroot` (only for the DEB)

libsodium is vendored and statically built by `libsodium-sys-stable`; no system
libsodium development package is required.

## Core

```bash
cd core
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --release
cargo build --release
```

Output: `core/target/release/libx_core.so` and the `x-bench` binary.

## Linux application

```bash
./scripts/build-linux.sh
```

This builds the core, builds the Flutter Linux release bundle, and ensures
`build/linux/x64/release/bundle/lib/libx_core.so` is present.

Run:

```bash
./app/build/linux/x64/release/bundle/x
```

## Ubuntu DEB

```bash
./scripts/build-deb.sh
```

Output: `dist/X-linux-amd64.deb`. The script:

- stages `/opt/x`, `/usr/bin/x`, desktop entry and icons;
- computes runtime dependencies with `dpkg-shlibdeps`;
- adds Debian changelog/copyright and md5sums;
- builds with `--root-owner-group` and a fixed `SOURCE_DATE_EPOCH`.

## Android APK

```bash
export ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk/28.2.13676358"
cargo install cargo-ndk --locked
./scripts/build-android.sh
```

Output: `dist/X-android-universal.apk`, arm64-v8a, signed if
`app/android/key.properties` exists.

### Creating your own release key

Never commit a keystore. The repository ignores `*.jks`, `*.keystore` and
`key.properties`.

```bash
mkdir -p ~/.x-release && chmod 700 ~/.x-release
keytool -genkeypair -v \
  -keystore ~/.x-release/x-release.jks \
  -alias x -keyalg RSA -keysize 4096 -validity 10950 \
  -dname "CN=jackh0006, OU=X, O=jackh0006, C=US"
```

Create `app/android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=x
storeFile=/absolute/path/to/x-release.jks
```

Back up the keystore and passwords offline. Losing them prevents shipping
updates under the same Android identity. For CI, store the keystore as base64
in the `ANDROID_KEYSTORE_BASE64` secret and the passwords in
`ANDROID_STORE_PASSWORD` / `ANDROID_KEY_PASSWORD`; `release.yml` recreates it
temporarily.

## Reproducibility

- `Cargo.lock` and `pubspec.lock` are committed and builds use locked
  dependencies.
- GitHub Actions are pinned to commit SHAs.
- The DEB uses `SOURCE_DATE_EPOCH` and uniform compression.
- Flutter/APK builds are not bit-for-bit reproducible across machines; verify
  checksums and provenance rather than assuming identical bytes.

## Release gate

Every release must pass the gates in [`TESTING.md`](TESTING.md) before a tag is
pushed. The `Release` workflow refuses to publish without the Android signing
secret.
