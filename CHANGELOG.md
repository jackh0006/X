# Changelog

All notable changes are recorded here. The project follows semantic versioning.

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
- Rust, Flutter, native FFI, parser-fuzz and cross-platform test suites.
- CI, CodeQL for workflows, dependency review, Scorecard, gitleaks, SBOM,
  release provenance and pinned GitHub Actions.
- Complete security, privacy, threat-model, format, build and support docs.

### Known limitations

- No forward secrecy, sender identity, replay protection or metadata privacy.
- No independent security audit.
- Android runtime interoperability is exercised by CI, not a physical device in
  the build environment.
- System-wide `dpkg -i` installation requires the user's sudo password.
