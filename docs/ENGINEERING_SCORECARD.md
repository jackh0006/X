# Engineering scorecard

Scores are evidence-based and deliberately not 100/100. See
[`SECURITY_ASSESSMENT.md`](SECURITY_ASSESSMENT.md) for the full rationale.

| Category | Score | Evidence |
|---|---:|---|
| Cryptographic implementation | 8.5 | libsodium 1.0.22; XChaCha20-Poly1305; Argon2id; independent byte-for-byte cross-checks |
| Key management | 6.0 | Passphrase-only; no forward secrecy, identity, or rotation |
| Authentication & integrity | 9.0 | Full-header AAD; strict parser; tamper and truncation tests |
| Privacy | 9.5 | No network permission, account, telemetry, ads or plaintext logging |
| Reliability | 8.0 | Bounded inputs, deterministic errors, tests; Android runtime pending |
| Performance | 7.5 | 0.47 s / 1.24 s KDF-dominated; 1.36 s startup; ~180 MiB RSS |
| Portability | 8.0 | One Rust core and format for Ubuntu/Android; runtime interoperability pending CI |
| Accessibility | 8.0 | Semantics, large targets, contrast, 1.8× scale test; no WCAG audit |
| Maintainability | 8.0 | Small modules, docs, CI, pinned dependencies; unsafe FFI surface |
| Test coverage | 7.5 | 34 Rust + 15 Flutter/native tests; 18.4M fuzz runs; no ASAN/device tests |
| Reproducibility | 6.5 | Locked deps, pinned Actions, deterministic DEB timestamps; APK not bit-reproducible |

**Overall: 7.8/10 (weighted toward security and evidence).**

This is not a certification, audit result, or mathematical proof. It is an
honest engineering snapshot that can improve when independent testing exists.
