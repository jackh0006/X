# Security assessment (self-assessment)

**This is an internal, evidence-based self-assessment. It is not an independent
security audit, penetration test, or formal verification.**

## Scope

Reviewed: Rust core (`core/src`), FFI boundary, Flutter UI and Android/Linux
platform glue, build scripts, dependency locks, and release configuration.
Version 1.0.0, 2026-11-08.

## Method

- Manual review of format parsing, KDF parameter validation, AEAD use and FFI
  pointer/length handling.
- `cargo clippy -D warnings`, `cargo fmt --check`, `cargo test --release`.
- Independent algorithm cross-checks (RustCrypto XChaCha20-Poly1305 and the
  `argon2` crate).
- `cargo audit` and `cargo deny`.
- Parser fuzzing (18.4 million executions, no crash).
- APK signature/badging/native-library inspection; DEB metadata, extraction,
  `ldd` and launch.
- Flutter static analysis and widget/native tests.

## Findings

| ID | Severity | Finding | Status |
|---|---|---|---|
| X-01 | Informational | No third-party audit or formal verification exists. | Disclosed; not claimed |
| X-02 | Medium (design) | A static passphrase provides no forward secrecy; one compromise exposes all messages encrypted with it. | Inherent to scope; documented |
| X-03 | Medium (design) | No sender identity/authentication beyond possession of the passphrase. | Documented |
| X-04 | Medium (design) | Passphrase exchange is outside X; users can defeat the system by sending it over the same channel. | UI/docs warning |
| X-05 | Medium (environment) | Dart/OS cannot guarantee erasure of plaintext copies; clipboard and swap risks remain. | Documented |
| X-06 | Medium (evidence) | Android runtime was validated on an x86_64 API 35 emulator; physical arm64 device was not tested locally. | Emulator PASS (CI run 42512453104); physical pending |
| X-07 | Low (evidence) | Fuzzing could not run with AddressSanitizer because the vendored libsodium C build fails ASAN link; it ran without ASAN. | Documented |
| X-08 | Low (build) | `dpkg -i` could not be tested without sudo; extraction and execution passed. | Documented |
| X-09 | Low (supply chain) | Vendored libsodium and crates add supply-chain surface; locks, audits, SBOM and provenance reduce but do not eliminate it. | Mitigated/documented |
| X-10 | Low | CodeQL currently analyzes GitHub Actions; Rust is covered by clippy/audit/fuzz, Kotlin by compilation. | Documented; CodeQL Actions PASS |

No critical or high-severity implementation vulnerability was found in the
reviewed code. This statement is limited by the absence of an independent audit.

## Controls that are present

- Established primitives only; no custom cryptography.
- Fresh 16-byte salt and 24-byte nonce per encryption; OS CSPRNG.
- Authenticated header (AAD) covering version, algorithms, KDF parameters, salt
  and nonce.
- Strict parser, canonical Base64URL, checked offsets, hard size caps.
- KDF memory/ops bounds checked before allocation (DoS cap).
- Wrong passphrase and tampering collapse to one error.
- No network permission or telemetry in the Android release.
- No passphrase or plaintext logging; no passphrase persistence.
- Release APK signed with a dedicated RSA-4096 key; keystore never committed.
- Checksums, SBOM and build provenance on releases.

## Engineering scorecard

Scores are relative and evidence-based, not a guarantee. 10/10 would mean
"best practical within scope and independently verified", which X does not
claim.

| Category | Score | Justification |
|---|---:|---|
| Cryptographic implementation | 8.5/10 | libsodium 1.0.22, XChaCha20-Poly1305, Argon2id, independent cross-checks; no audit |
| Key management | 6.0/10 | Simple passphrase model; no forward secrecy, sender identity or key rotation |
| Authentication & integrity | 9.0/10 | AEAD over ciphertext and full header; strict parser and tamper tests |
| Privacy | 9.5/10 | No account, network, telemetry or ads; Android backup disabled |
| Reliability | 8.0/10 | Deterministic error handling, limits, tests; Android runtime pending |
| Performance | 7.5/10 | ~0.47 s Standard / ~1.24 s High on old dual-core; 180 MiB RSS |
| Portability | 8.0/10 | Shared payload and core; Ubuntu and arm64 Android built; runtime evidence pending |
| Accessibility | 8.0/10 | Large targets, semantics, contrast, 1.8× text-scale test; no formal WCAG audit |
| Maintainability | 8.0/10 | Small modules, documented format, pinned deps, CI; manual FFI is unsafe code |
| Test coverage | 7.5/10 | 25 Rust + 14 Flutter/native tests, fuzz; no ASAN and no device tests |
| Reproducibility | 6.5/10 | Locked deps, pinned Actions, deterministic DEB timestamps; Flutter/APK builds not bit-identical |

## Recommendation

Suitable for careful, low-volume transmission of sensitive text when the
passphrase is strong and exchanged out of band. Not suitable for high-assurance
threat models requiring forward secrecy, sender authentication, metadata
protection, or an audited product. Commission an independent audit before
making those claims.
