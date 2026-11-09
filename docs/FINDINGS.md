# Finding register

Version: v1.1.3. Self-assessment only; not an independent audit.

| ID | Severity | Location | Impact | Fix | Proof | Status |
|---|---|---|---|---|---|---|
| F-01 | High | `core/src/ffi.rs` `x_decrypt` | Plaintext crossed FFI through JSON, `String`, `CString` copies | Caller-owned native buffer; no plaintext JSON | FFI tests + native Flutter tests | **FIXED** |
| F-02 | Medium | `app/lib/core/native_x_service.dart` | Passphrase/plaintext byte buffers freed without overwrite | `fillRange(0)` before free | code review + tests | **FIXED** |
| F-03 | Medium | `send_screen.dart` `_save` | Interrupted write could damage an existing export | temp file + flush + atomic rename; Android deletes partial SAF document | code review + save test | **FIXED** |
| F-04 | Medium | SEND/RECEIVE | Sensitive fields could remain indefinitely | tab/background reset + 2-minute inactivity timer | widget test | **FIXED** |
| F-05 | Medium | SEND success/failure | Phrase/plaintext retained after use | clear controllers after success/failure | widget tests | **FIXED** |
| F-06 | Medium | Clipboard | Sensitive text could remain visible to other apps | explicit copy only; best-effort 60s clear if unchanged | code + widget test | **FIXED (best effort)** |
| F-07 | Medium | Android window | Recents/screenshot exposure | app-wide `FLAG_SECURE` | source review | **FIXED (physical test pending)** |
| F-08 | Critical | Android physical | Emulator is not sufficient for the release gate | physical device matrix | `adb` device not enumerating | **BLOCKED** |
| F-09 | Critical | Linux system install | User-local extraction is not a full package installation | `sudo apt install` test | not executed | **BLOCKED** |
| F-10 | Medium | Test tooling | Rust coverage and sanitizers unavailable/not run | cargo-llvm-cov, PIC/ASAN attempt | not executed | **OPEN** |
| F-11 | Low | Crypto tests | No official KAT vector; differential checks only | add authoritative vectors | not executed | **OPEN** |
| F-12 | Low | Design | No forward secrecy or sender authentication | architectural limitation | documented | **ACCEPTED** |
| F-13 | Low | Android sideload | Play Protect warning | Play Store distribution or user bypass | documented | **EXTERNAL** |
| F-14 | Low | QR | Phrase visible as QR | app-wide `FLAG_SECURE`, warning, explicit action | code review | **MITIGATED** |
| F-15 | Low | Dart runtime | Immutable strings/OS copies cannot be erased | minimize lifetime | documented | **ACCEPTED** |

## Critical/high status

- F-01 fixed.
- F-08 and F-09 block a READY declaration.
- No other known Critical/High implementation finding remains in the self-review.
