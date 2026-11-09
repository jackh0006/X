# Changelog

All notable changes are recorded here. The project follows semantic versioning.

## [1.1.1] - 2026-11-09

### Fixed

- SEND message, phrase and result now survive tab switches; screens are kept
  alive instead of being rebuilt.
- Save now uses the configured export folder and filename without opening an
  unexpected file picker.

### Verified

- Copy/save ciphertext with no plaintext leakage.
- Close/reopen, reinstall, transfer, backup/restore, long text, Unicode,
  special characters, empty input, and wrong phrase tests.
- Physical-device testing remains external.

## [1.1.0] - 2026-11-09

### Added

- Offline QR display for sharing the encryption phrase, with an explicit
  warning and Android `FLAG_SECURE` while visible.
- Local Data panel: app/cache/preferences paths, copy and open controls,
  confirmed deletion, default export folder and filename.
- Single-source icon artwork for Android and Linux.
- APK Signature Scheme v2 and v3.
- A 100-point evidence checklist, no-remote-access evidence, and an incremental
  test-impact policy.

### Changed

- Version 1.1.0 (Android versionCode 3); release assets remain
  `X-android-arm64.apk` and `X-linux-amd64.deb`.
- Expanded tests: exact NFC/NFD phrase behavior, 1,024-byte phrase, FFI
  null/oversize handling, QR, storage.

## [1.0.1] - 2026-11-08

### Fixed

- Release APK now advertises and contains only the arm64-v8a ABI. Removing the
  `shared_preferences` plugin eliminated x86/x86_64 `libdartjni` stubs that
  could make Android offer the app to unsupported devices.
- Theme persistence now uses a small native Android preference or a Linux XDG
  file, reducing dependencies and APK size.

## [1.0.0] - 2026-11-08

Initial public release.

### Added

- Offline SEND and RECEIVE screens for authenticated text encryption.
- XChaCha20-Poly1305-IETF with Argon2id v1.3 via vendored libsodium 1.0.22.
- Versioned `X1.` portable payload format with authenticated header, 16-byte
  salt and 24-byte nonce per encryption.
- Standard (128 MiB / 3) and High (256 MiB / 4) KDF profiles with strict
  downgrade and resource-exhaustion bounds.
- Seven-word EFF Diceware passphrase generator (~90 bits).
- Strict parser with 64 KiB plaintext and 96 KiB encoded limits.
- Four-section Material 3 interface: SEND, RECEIVE, DONATE, ABOUT.
- Light, dark and system themes with a theme-aware Linux title bar.
- Android SAF save and native share; Linux file save; clipboard copy.
- Android arm64-v8a release APK and Ubuntu amd64 DEB.
- Rust, Flutter, native FFI, parser-fuzz, and cross-platform test suites.
- CI, CodeQL for workflows, dependency review, Scorecard, gitleaks, SBOM,
  release provenance, and pinned GitHub Actions.
- Complete security, privacy, threat-model, format, build and support docs.

### Known limitations

- No forward secrecy, sender identity, replay protection, or metadata privacy.
- No independent security audit.
- Android runtime interoperability is exercised by CI, not a physical device in
  the build environment.
- System-wide `dpkg -i` installation requires the user's sudo password.
