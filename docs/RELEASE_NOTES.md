# X 1.0.0

A lightweight, offline-first encrypted text utility for Ubuntu AMD64 and Android
ARM64.

## Highlights

- **SEND** encrypts text locally into portable `X1.…` ciphertext.
- **RECEIVE** authenticates and decrypts it locally.
- **No account, server, registration, telemetry or Internet permission.**
- XChaCha20-Poly1305-IETF + Argon2id via libsodium 1.0.22.
- Fresh 16-byte salt and 24-byte nonce for every encryption.
- Standard (128 MiB / 3) and High (256 MiB / 4) KDF profiles.
- Seven-word EFF passphrase generator.
- Beautiful light/dark interface; Android share and SAF save; Linux DEB.

## Artifacts

| File | Platform | Size |
|---|---|---:|
| `app-release.apk` | Android arm64-v8a, minSdk 24 | 19,887,708 bytes |
| `x_amd64.deb` | Ubuntu amd64 | 8,967,850 bytes |
| `SHA256SUMS` | Both | — |
| `x-1.0.0.cdx.json` | CycloneDX SBOM | — |
| `TEST_RESULTS.md` | Test report | — |
| `SECURITY_ASSESSMENT.md` | Self-assessment | — |

The authoritative checksums for the published artifacts are in
`SHA256SUMS` in this release. The sizes above describe the local verification
build; the CI-built release may differ slightly.


APK certificate SHA-256:
`E8:16:9C:CC:4F:6A:77:B8:6A:44:B8:B6:89:38:F0:DD:7E:79:AA:0F:66:A6:34:3A:2F:3E:5B:88:01:C3:DC:F2`

## Security notes

- The passphrase is **not** embedded. Share it separately.
- Wrong passphrase and tampered ciphertext both fail authentication.
- No forward secrecy, sender authentication, replay protection or metadata
  protection. No independent audit has been performed.
- This release has not been tested on a physical Android device in the build
  environment; see `docs/COMPATIBILITY.md`.

## Install

Android: install `app-release.apk` (arm64-v8a). Verify the checksum first.

Ubuntu:

```bash
sudo apt install ./x_amd64.deb
x
```

## License

Apache-2.0. Made by jackh0006, with AI assistance.
