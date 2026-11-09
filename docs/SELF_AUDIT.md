# Self-audit evidence

Environment: Ubuntu 24.04.5, Rust 1.98.1, Flutter 3.47.6, Huawei P10 not
enumerating over USB, no system-wide sudo session available to the agent.

| Check | Command | Result |
|---|---|---|
| Rust format | `cargo fmt --all -- --check` | PASS |
| Rust clippy | `cargo clippy --all-targets --all-features -- -D warnings` | PASS |
| Rust tests | `cargo test --release` | **34 PASS** |
| Flutter analyze | `flutter analyze` | PASS |
| Flutter tests | `flutter test` | **17 PASS** |
| Coverage | `flutter test --coverage` | 81.2% lines (measured before final timeout test; recheck on release) |
| Parser fuzz | `cargo +nightly fuzz run -s none parse` | 18.4M+ executions, no crash |
| Header tampering | exhaustive 0..55 test | PASS |
| Trailing data | regression test | PASS |
| Wrong phrase | core + FFI + widget tests | PASS, no plaintext |
| Long/Unicode/empty | core + CLI + widget tests | PASS |
| Copy/save/transfer | actual Linux app | PASS |
| Restart/reinstall/backup | actual Linux app + checksum restore | PASS |
| No network | `strace -f -e trace=network` | only local `AF_UNIX` |
| APK permissions | `aapt dump permissions` | no Internet/Camera |
| APK signature | `apksigner verify` | v2/v3 |
| APK ABI | `aapt dump badging` | arm64-v8a |
| DEB package | `dpkg-deb -I`, user-local launch | PASS |
| System-wide DEB install | `sudo apt install` | **NOT RUN** |
| Physical Android | `adb devices -l` | **NOT RUN — no device enumerated** |
| ASAN/UBSAN | attempted with vendored libsodium | **NOT RUN — PIC/ASAN link failure** |
| Rust line coverage | cargo-llvm-cov | **NOT RUN — tool unavailable** |
| Secret scan | gitleaks CI | PASS |
| Dependency audit | `cargo audit` | 0 vulnerabilities |
| License policy | `cargo deny check` | PASS |
| SBOM/provenance | release workflow | PASS |
| DeepSeek/network code | source grep + permission + strace | none found |

## Final decision rule

A failed or unexecuted Critical gate blocks READY. F-08 and F-09 therefore keep
the release at **NOT READY** for the “most important texts” claim, regardless of
the numerical score.

## Remaining limitations

No forward secrecy, no sender authentication, Dart/OS memory copies, best-effort
clipboard clearing, compromised-device exposure, no independent audit, Play
Protect warning, and no physical Android verification.
