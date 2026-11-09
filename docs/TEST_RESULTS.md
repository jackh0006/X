# Test results

Environment: Ubuntu 24.04.5 LTS, Intel Pentium G2030 (2 cores), 3.8 GiB RAM,
Rust 1.98.1, Flutter 3.47.6 / Dart 3.13.5. Date: 2026-11-09.
Release: **v1.1.2**.

Legend: **PASS** = executed and passed; **FAIL** = executed and failed;
**NOT TESTED** = not executed; **N/A** = outside X's scope or not applicable.

## Cryptographic core

| Test | Result | Evidence |
|---|---|---|
| Round-trip, Unicode/multilingual | PASS | `cargo test --release`: 34/34 |
| Empty message | PASS | `cargo test --release` |
| Binary edge cases (NUL, 0xFF) | PASS | `cargo test --release` |
| Maximum 64 KiB message | PASS | `cargo test --release` |
| Wrong passphrase rejection | PASS | `cargo test --release` |
| Ciphertext modification rejected | PASS | `cargo test --release` |
| Authenticated header modification rejected (salt/nonce/ops/mem) | PASS | `cargo test --release` |
| Unsupported version/algorithm/KDF | PASS | `cargo test --release` |
| Malformed Base64URL / padding / interior whitespace | PASS | `cargo test --release` |
| Truncated payloads (multiple cut points) | PASS | `cargo test --release` |
| Oversized encoded payload | PASS | `cargo test --release` |
| KDF parameter bounds / downgrade rejection | PASS | `cargo test --release` |
| Salt and nonce uniqueness (4,096 samples) | PASS | `cargo test --release` |
| XChaCha20-Poly1305 cross-check vs RustCrypto | PASS | byte-for-byte test |
| Argon2id cross-check vs independent `argon2` crate | PASS | byte-for-byte test |
| Property test: envelope encode/decode (256 cases) | PASS | `cargo test --release` |
| Property test: parser never panics on garbage | PASS | `cargo test --release` |
| Every header byte mutation rejected | PASS | exhaustive 0..55 regression test |
| Appended trailing data rejected | PASS | regression test |
| Identical plaintext produces different payloads | PASS | fresh salt/nonce test |
| Public API integration tests | PASS | 3 integration tests |
| libFuzzer parser campaign | PASS (with limitation) | 18,418,323 executions, 31 s, no crash |
| AddressSanitizer fuzzing | NOT TESTED | vendored libsodium C objects fail ASAN linking; fuzz ran with `-s none` |

## Application

| Test | Result | Evidence |
|---|---|---|
| Exactly four sections; navigation | PASS | Flutter widget tests 11/11 |
| SEND encrypt + result + copy | PASS | widget test with clipboard spy |
| Passphrase generation | PASS | widget + native tests |
| Short/empty input validation | PASS | widget test |
| RECEIVE success and wrong-passphrase error | PASS | widget test |
| Malformed payload error | PASS | widget test |
| DONATE addresses + copy | PASS | widget test |
| Light/dark theme switching | PASS | widget test + real screenshots |
| About disclosures | PASS | widget test |
| Mobile layout / large text scaling | PASS | widget test, 1.8× scale |
| Native FFI round-trip, wrong pass, inspect | PASS | 3 native tests on host |
| Flutter static analysis | PASS | `flutter analyze`: no issues |
| Real-world copy/save/transfer | **PASS** | `docs/REAL_WORLD_TESTS.md`; 157-byte ciphertext, no plaintext |
| Restart/reinstall recovery | **PASS** | saved ciphertext decrypted after reinstall |
| Backup/restore | **PASS** | private backup + SHA-256 + restore |
| QR phrase display + warning + close | PASS | widget test |
| Local data card + paths | PASS | widget test |
| Exact NFC/NFD phrase behavior | PASS | Rust regression test |
| 1,024-byte phrase | PASS | Rust regression test |
| FFI null/oversize rejection | PASS | Rust regression test |
| Flutter line coverage | **80.7%** (1002/1242) | `flutter test --coverage` |
| Rust line coverage | NOT INSTRUMENTED | all core modules covered by targeted tests; no llvm-cov run |
| Full CI gate | **PASS** | GitHub Actions run 42613337772 (all five jobs) |
| Android emulator runtime + Linux and Android interoperability | **PASS** | GitHub Actions run [42613468188](https://github.com/jackh0006/X/actions/runs/42613468188): Linux fixture decrypted on x86_64 API 35 emulator; Android payload decrypted by Linux core |

## Security and supply chain

| Check | Result | Evidence |
|---|---|---|
| `cargo fmt --check` | PASS | local run |
| `cargo clippy -D warnings` | PASS | local run |
| `cargo audit` | PASS | 0 vulnerabilities in 132 locked crates |
| `cargo deny check` | PASS | advisories, bans, licenses, sources ok |
| Secret scan | **PASS** | gitleaks in CI; allowlist only for published key/cert fingerprints |
| CodeQL | **PASS** (Actions) | CodeQL workflow analyzes GitHub Actions; Rust covered by clippy/audit/fuzz |
| Dependency review | **PASS** (PR) | GitHub dependency-review workflow |
| SBOM generation | PASS | `dist/x-1.1.0.cdx.json` generated from lockfiles |

## Builds and packages

| Test | Result | Evidence |
|---|---|---|
| Rust release build | PASS | `cargo build --release` |
| Flutter Linux release build | PASS | `build/linux/x64/release/bundle/x` |
| Linux launch from built bundle | PASS | real app + screenshots |
| DEB structure and metadata | PASS | `dpkg-deb -I`, `-c` (local v1.1.2: 8,705,560 B) |
| DEB extraction + executable launch | PASS | extracted `/opt/x/x` ran |
| DEB fake-root `dpkg` unpack/configure | PASS | `dpkg --root=/tmp/xroot --force-not-root`; status `install ok installed` |
| DEB system install with `dpkg -i` | NOT TESTED | requires sudo unavailable in build environment |
| Android arm64-v8a cross-compile | PASS | `libx_core.so` in `jniLibs/arm64-v8a` |
| Android release APK build | PASS | 18,598,755 B; versionCode 5; arm64-v8a; v2/v3 signed |
| APK signature | PASS | `apksigner verify`; RSA-4096 v2/v3, cert `e8169ccc…dcf2` |
| APK package/arch | PASS | `com.jackh0006.x`; `native-code` exactly `arm64-v8a`; no INTERNET/CAMERA |
| APK install on physical Android device | NOT TESTED | no device available |
| APK install on emulator | NOT TESTED | local host has no `/dev/kvm`; CI workflow defined |

## Performance

See [`PERFORMANCE_BENCHMARKS.md`](PERFORMANCE_BENCHMARKS.md). KDF is the dominant
cost: Standard ≈ 470 ms, High ≈ 1.24 s per operation on the test machine.

## Screenshots

All screenshots in [`screenshots/`](screenshots/) were captured from the real
packaged Linux build, including a real encryption and a real decryption. No
mockups.

## Non-claims

No independent security audit, formal verification, government certification,
or universal device compatibility is claimed.
