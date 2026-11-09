# X v1.0.1

A lightweight, offline-first encrypted text utility for Ubuntu amd64 and Android
arm64-v8a. This patch makes the Android release strictly arm64-v8a and removes an
unnecessary preferences plugin.

## Highlights

- **SEND** encrypts text locally into portable `X1.…` ciphertext.
- **RECEIVE** authenticates and decrypts it locally.
- **No account, server, registration, telemetry, or Internet permission.**
- XChaCha20-Poly1305-IETF + Argon2id via libsodium 1.0.22.
- Fresh 16-byte salt and 24-byte nonce for every encryption.
- Standard (128 MiB / 3) and High (256 MiB / 4) KDF profiles.
- Seven-word EFF passphrase generator.
- Light/dark interface; Android share and SAF save; Linux DEB.

## Fixed in 1.0.1

- The APK now advertises and contains only `arm64-v8a`. The previous
  `shared_preferences` dependency added x86/x86_64 JNI stubs, which could make
  Android offer the app to unsupported devices.
- Theme persistence uses a small Android native preference or a Linux XDG file,
  removing several transitive packages and reducing APK size.

## Artifacts

| File | Platform |
|---|---|
| `X-android-arm64.apk` | Android arm64-v8a, minSdk 24, versionCode 2 |
| `X-linux-amd64.deb` | Ubuntu amd64, version 1.0.1 |
| `SHA256SUMS` | Both artifacts |
| `x-1.0.1.cdx.json` | CycloneDX SBOM |
| `TEST_RESULTS.md` | Test report |
| `SECURITY_ASSESSMENT.md` | Self-assessment |

The authoritative checksums are in `SHA256SUMS` in this release.

APK certificate SHA-256:
`E8:16:9C:CC:4F:6A:77:B8:6A:44:B8:B6:89:38:F0:DD:7E:79:AA:0F:66:A6:34:3A:2F:3E:5B:88:01:C3:DC:F2`

## Security notes

- The passphrase is **not** embedded. Share it separately.
- Wrong passphrase and tampered ciphertext both fail authentication.
- No forward secrecy, sender authentication, replay protection, or metadata
  protection. No independent audit has been performed.
- Linux and Android interoperability passed in CI on an x86_64 API 35 emulator.
- A physical arm64 Android device was not available in the build environment;
  see `docs/COMPATIBILITY.md`.

## Install

Android: install `X-android-arm64.apk` (arm64-v8a). Verify the checksum first.

Ubuntu:

```bash
sudo apt install ./X-linux-amd64.deb
x
```

## License

Apache-2.0. Made by jackh0006, with AI assistance.
