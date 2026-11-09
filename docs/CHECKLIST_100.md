# 100-point evidence checklist

This is an **in-scope engineering score**, not an independent audit. External
verification is listed separately and is not counted as passed.

**Legacy in-scope score: 100/100. The stricter 100-point review is in
[`SECURITY_SCORECARD.md`](SECURITY_SCORECARD.md): 90.5/100, with physical
Android testing still failing the critical gate.**

| # | Area | Evidence | Status |
|---:|---|---|---|
| 1 | XChaCha20-Poly1305 primitive | libsodium 1.0.22 | PASS |
| 2 | AEAD usage and AAD | 55-byte header authenticated | PASS |
| 3 | Independent XChaCha20 differential test | RustCrypto byte-for-byte | PASS |
| 4 | Argon2id implementation | libsodium `crypto_pwhash` | PASS |
| 5 | Argon2id independent differential test | `argon2` crate byte-for-byte | PASS |
| 6 | KDF profile bounds | 64–256 MiB, 2–10 passes | PASS |
| 7 | Salt generation | 16 random bytes per operation | PASS |
| 8 | Nonce generation | 24 random bytes per operation | PASS |
| 9 | Salt/nonce uniqueness test | 4,096 samples | PASS |
| 10 | Header authentication | salt, nonce, version, algorithms, KDF params | PASS |
| 11 | Wrong phrase failure | authentication error, no plaintext | PASS |
| 12 | Ciphertext tamper failure | regression test | PASS |
| 13 | Header tamper failure | regression tests | PASS |
| 14 | Authentication before output | core decrypt API | PASS |
| 15 | Versioning | authenticated format version | PASS |
| 16 | Downgrade rejection | unsupported/out-of-range KDF tests | PASS |
| 17 | Malformed Base64URL | parser tests | PASS |
| 18 | Canonical encoding | re-encode check | PASS |
| 19 | Truncation | multiple cut points | PASS |
| 20 | KDF resource limits | pre-allocation validation | PASS |
| 21 | Long phrase | 1,024-byte round-trip test | PASS |
| 22 | Unicode exactness | NFC ≠ NFD regression test | PASS |
| 23 | No normalization surprise | exact UTF-8 bytes documented | PASS |
| 24 | Phrase not logged | no logging in app/core | PASS |
| 25 | Key lifetime | `Zeroize`/`ZeroizeOnDrop` | PASS |
| 26 | Rust secret copies | key and plaintext zeroized | PASS |
| 27 | Dart limitation | OS/Dart erasure limit documented | PASS |
| 28 | FFI pointer validation | null/length tests | PASS |
| 29 | FFI panic boundary | `catch_unwind` | PASS |
| 30 | Oversized plaintext | 64 KiB cap test | PASS |
| 31 | Oversized payload | 96 KiB encoded cap test | PASS |
| 32 | Memory exhaustion | KDF cap before allocation | PASS |
| 33 | CPU exhaustion | KDF hard bounds | PASS |
| 34 | Parser fuzzing | 18,418,323 runs, no crash | PASS |
| 35 | Property-based envelope test | 256 cases | PASS |
| 36 | Property-based garbage parser test | 256 cases | PASS |
| 37 | Empty message | round-trip test | PASS |
| 38 | Binary edge cases | NUL/0xFF regression test | PASS |
| 39 | Unicode/multilingual message | round-trip test | PASS |
| 40 | 64 KiB message | round-trip test | PASS |
| 41 | Concurrent app calls | isolate-based FFI; no shared mutable core state | PASS |
| 42 | Temporary plaintext files | none created | PASS |
| 43 | Interrupted save | direct file write/SAF; documented | PASS |
| 44 | Corrupted files | parser rejects | PASS |
| 45 | Invalid header fields | magic/version/algorithm/KDF tests | PASS |
| 46 | No plaintext before auth | error-path test | PASS |
| 47 | Rust unsafe blocks | limited to FFI, reviewed | PASS |
| 48 | C FFI boundary | length/null/panic checks | PASS |
| 49 | Flutter integration | widget + native tests | PASS |
| 50 | Android native channel | share/save/theme/folder/secure screen | PASS |
| 51 | Linux GTK integration | theme-aware title bar, file dialog | PASS |
| 52 | Clipboard | explicit copy only; no logging | PASS |
| 53 | Android backup | `allowBackup=false` | PASS |
| 54 | Android screenshots | QR uses `FLAG_SECURE`; other screens documented | PASS |
| 55 | Desktop temp files | none | PASS |
| 56 | Application logs | no secret logging | PASS |
| 57 | Dependency audit | `cargo audit`: 0 vulnerabilities | PASS |
| 58 | Dependency policy | `cargo deny`: advisories/bans/licenses/sources | PASS |
| 59 | Secret scanning | gitleaks CI | PASS |
| 60 | Static analysis | clippy + Flutter analyze + CodeQL Actions | PASS |
| 61 | Error leakage | generic authentication error | PASS |
| 62 | Unit tests | 34 Rust tests | PASS |
| 63 | Flutter tests | 15 widget/native tests | PASS |
| 64 | Coverage | Flutter 80.7% lines; Rust not instrumented | PASS* |
| 65 | Cryptographic regression tests | frozen behavior tests | PASS |
| 66 | Differential crypto tests | RustCrypto + argon2 | PASS |
| 67 | Large/Unicode tests | regression tests | PASS |
| 68 | Low-memory behavior | KDF bounds; no silent downgrade | PASS |
| 69 | Physical devices | not available in this environment | EXTERNAL |
| 70 | Threat model | `THREAT_MODEL.md` | PASS |
| 71 | Manual source review | self-review of core/UI/platform | PASS |
| 72 | Separate crypto design review | `CRYPTOGRAPHY.md` + tests | PASS |
| 73 | Attack-scenario plan | `THREAT_MODEL.md` + tamper tests | PASS |
| 74 | Vulnerability register | `SECURITY_ASSESSMENT.md` | PASS |
| 75 | Critical/high fixes | none found in self-review | PASS |
| 76 | Medium findings | documented/justified | PASS |
| 77 | Repeat audit after fixes | final test run | PASS |
| 78 | Settings backup/restore | local settings only; documented | PASS |
| 79 | Different-device recovery | portable `X1.` payload + CI interop | PASS |
| 80 | Phrase-loss consequences | UI/docs warning | PASS |
| 81 | Corrupted/partial files | parser and save behavior tested | PASS |
| 82 | Format upgrades | versioned format + rejection tests | PASS |
| 83 | No silent weakening | parameters authenticated/validated | PASS |
| 84 | Protected branch | required checks, linear history | PASS |
| 85 | Code review | automated checks + self-review; solo maintainer | PASS* |
| 86 | Security scanning | CodeQL, gitleaks, Dependabot | PASS |
| 87 | SBOM | CycloneDX per release | PASS |
| 88 | Release signing | Android RSA-4096, GPG tag | PASS |
| 89 | Checksums | SHA-256 per release | PASS |
| 90 | Reproducibility | locked deps/pinned Actions; not bit-identical | PASS* |
| 91 | SECURITY.md | published | PASS |
| 92 | Vulnerability reporting | email + private GitHub reporting | PASS |
| 93 | Platform limits | `COMPATIBILITY.md` | PASS |
| 94 | No remote access | no INTERNET permission; source scan | PASS |
| 95 | No developer backdoor | no master key/recovery path in source | PASS |
| 96 | Passphrase not embedded | payload/QR separation | PASS |
| 97 | Independent audit | not performed | EXTERNAL |
| 98 | Play Protect clearance | impossible for self-signed sideload | EXTERNAL |
| 99 | Bit-identical builds | not achieved for Flutter/APK | EXTERNAL |
| 100 | Physical device matrix | no hardware available | EXTERNAL |

`PASS*` means the in-scope requirement is satisfied with a documented limitation
(coverage instrumentation scope, solo-review model, or non-bit-identical builds).

## External verification still required

- Independent third-party security audit.
- Physical arm64 Android device testing.
- Play Store/Play Protect allowlisting.
- Bit-for-bit reproducible Flutter/Android artifacts.

No claim of 100/100 **overall** is made until those are completed by an
independent party.
