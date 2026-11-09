# Security scorecard — evidence-based

This is a self-assessment against the 100-point checklist. It is **not** an
independent audit. A critical-gate failure overrides the numerical score.

| Section | Points | Awarded | Status and gap |
|---|---:|---:|---|
| 1. Cryptographic implementation | 15 | 14.0 | libsodium, Argon2id, AEAD, differential tests; no official KAT source file |
| 2. Password and key security | 10 | 10.0 | CSPRNG phrases, no storage/logging, exact Unicode, zeroization |
| 3. Memory and secret protection | 10 | 9.0 | Rust/FFI zeroization; Dart/OS limits; allocation-failure tests not run |
| 4. Format and parser | 8 | 8.0 | Strict parser, limits, full-header tamper test, trailing-data test |
| 5. Rust core and FFI | 8 | 7.0 | Null/oversize/UTF-8/panic tests; sanitizer run unavailable |
| 6. Encryption/decryption correctness | 8 | 7.0 | Round-trips, profiles, cross-platform; physical-device test missing |
| 7. Testing and fuzzing | 10 | 7.5 | 34 Rust + 15 Flutter tests, fuzz; Rust coverage and ASAN missing |
| 8. Android security | 7 | 5.0 | No permissions, backup off, v2/v3, QR FLAG_SECURE; physical device missing |
| 9. Linux security | 4 | 4.0 | Actual DEB tested, paths, clipboard, save, no network |
| 10. Privacy and offline operation | 5 | 5.0 | No network/analytics/accounts; traced launch |
| 11. Transfer, recovery, reliability | 5 | 4.5 | Copy/save/backup/restart/reinstall; line-wrap edge not separately tested |
| 12. Dependencies and supply chain | 4 | 3.5 | Locks, audit, deny, SBOM; Dart/Kotlin advisory review not separately documented |
| 13. Build, release, repository | 3 | 3.0 | Protected branch, signed tag, checksums, provenance, exact release tested |
| 14. Documentation and threat model | 3 | 3.0 | Algorithms, format, limits, exchange, no sender auth/FS |
| **Total** | **100** | **90.5** | **Not ready for highly sensitive Android text** |

## Critical gate

| Gate | Status |
|---|---|
| Correct crypto/auth | PASS |
| KDF/randomness | PASS |
| No plaintext after auth failure | PASS |
| Safe parser/FFI | PASS |
| No critical/high open defects | PASS (self-review) |
| **Physical Android test** | **NOT TESTED — gate fails** |
| Real-world Linux | PASS |
| Cross-device transfer | PASS (emulator) |
| Recovery/backup | PASS |
| No unintended network | PASS |
| Final binary tested | PASS |
| Limitations documented | PASS |

Because physical Android testing is not complete, the **critical release gate
does not pass**, regardless of the 90.5 numerical score. X should not be
described as verified-ready for highly sensitive Android text until that is done.

## External items

- Independent third-party audit.
- Physical arm64 Android device matrix, install/upgrade/lock/share tests.
- Play Protect allowlisting for a self-signed sideload.
- Bit-for-bit reproducible Flutter/APK builds.
- Rust line/branch coverage and sanitizer runs.

## Latest tested release

`v1.1.1`; test evidence in `TEST_RESULTS.md`, `REAL_WORLD_TESTS.md`, and
`NO_REMOTE_ACCESS.md`.
