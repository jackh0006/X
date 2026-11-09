# Real-world test report

Executed against the actual Linux release package on Ubuntu 24.04.5 (amd64),
plus the Android emulator interoperability workflow.

## Platform and integrity

- Installed the published v1.1.2 `X-linux-amd64.deb` into the user account.
- `dpkg-deb -I` reports version 1.1.x, amd64.
- `sha256sum -c` passes for the published artifacts.
- APK: arm64-v8a only, versionCode 5, no INTERNET/CAMERA permission, v2/v3
  signature verified.
- No outbound network connections during a traced Linux launch; only local
  `AF_UNIX` D-Bus/Wayland/accessibility sockets.

## Data handling

| Test | Result | Evidence |
|---|---|---|
| Copy ciphertext | PASS | Clipboard contained a 157-character `X1.` payload; no plaintext |
| Save ciphertext | PASS | `/tmp/x-test-export/X-test-message.txt`, 157 bytes, byte-identical to clipboard |
| Plaintext leakage in saved file | PASS | zero matches for the test plaintext |
| Save uses configured folder/name | PASS | no file dialog; wrote to the configured path |
| Transfer file | PASS | copied file to a backup folder and decrypted there |
| Ciphertext contains plaintext | PASS | no matches for message content |

## Recovery

| Test | Result | Evidence |
|---|---|---|
| Close/reopen app | PASS | saved ciphertext remains; Receive decrypts it |
| Reinstall DEB | PASS | user data and ciphertext persisted; decrypts after reinstall |
| Move to another device | PASS | CI Linux↔Android v1.1.0; v1.1.2 workflow is the release gate |
| Wrong encryption phrase | PASS | core CLI returned authentication failure with 0 output bytes |
| Corrupted/truncated payload | PASS | parser rejects; no plaintext |

## Real-world inputs

| Input | Result | Evidence |
|---|---|---|
| Special characters `!@#$%^&*()_+[]{};:,./<>?` | PASS | encrypted and decrypted in the app |
| Long message (65,534 bytes) | PASS | core CLI round-trip byte-for-byte |
| Unicode: 你好 · مرحبا · Привет · こんにちは · café · 🔐 | PASS | core CLI round-trip byte-for-byte |
| Empty message | PASS (core) / UI requires non-empty | core round-trip; widget test error path |
| Incorrect phrase | PASS | core + widget tests reject without output |
| 1,024-byte phrase | PASS | Rust regression test |
| NFC vs NFD phrase | PASS | Rust regression test; treated as different phrases |

The UI returns “Enter a message first” for an empty message. This is a product
choice; the core format supports a valid empty plaintext.

## Backup and restore

A test backup was created at:

```text
~/Documents/X-Backup-2026-11-09/
  message.x1.txt      (0600)
  SHA256SUMS          (0600)
  README.txt
```

`sha256sum -c` passed, and the ciphertext restored after reinstall. The
encryption phrase is deliberately **not** stored in that folder.

## Android

The v1.1.0 Linux↔Android emulator workflow passed both directions. The v1.1.2
release workflow reruns it. Physical-device testing remains external.

## Remaining external checks

- Physical arm64 Android device installation and runtime.
- Google Play Protect allowlisting for a sideloaded signing identity.
- Independent third-party audit.
