# X v1.1.0

An offline-first encrypted text utility for Ubuntu amd64 and Android arm64-v8a.

## Added

- **Encryption phrase QR:** show the phrase as an offline QR code from SEND.
  The QR contains the phrase only, never the message or ciphertext. Android sets
  `FLAG_SECURE` while the QR is visible; the dialog includes a clear warning.
- **Local Data panel:** see the app data, cache and preferences paths; copy or
  open them; delete local app data; choose a default export folder; change the
  default export filename. X stores no messages or plaintext.
- **One icon:** Linux now uses the Android icon artwork as its single source.
- APK Signature Scheme v2 and v3.
- A 100-point evidence checklist, no-remote-access evidence, and a test-impact
  policy for faster feature updates.

## Security and reliability

- Exact NFC/NFD encryption-phrase behavior is tested and documented; X does not
  silently normalize a phrase.
- 1,024-byte phrases, FFI null/oversize inputs, authentication failures, and
  header integrity are regression-tested.
- Android release has no `INTERNET` permission and no network client code.
- No master password, recovery key, or developer decryption path exists.

## Artifacts

| File | Platform |
|---|---|
| `X-android-arm64.apk` | Android arm64-v8a, minSdk 24, versionCode 3 |
| `X-linux-amd64.deb` | Ubuntu amd64, version 1.1.0 |
| `SHA256SUMS` | Both artifacts |
| `x-1.1.0.cdx.json` | CycloneDX SBOM |
| `TEST_RESULTS.md` | Test report |
| `SECURITY_ASSESSMENT.md` | Self-assessment |

The authoritative checksums are in `SHA256SUMS`.

## Android installation

The APK is signed with the project's dedicated RSA-4096 release key. Google Play
Protect may display an “unknown app” warning for any sideloaded, self-signed APK.
That warning cannot be removed by application code; only Play Store distribution
or the user's “Install anyway” choice removes it. Verify the checksum and the
certificate fingerprint before installing:

```text
E8:16:9C:CC:4F:6A:77:B8:6A:44:B8:B6:89:38:F0:DD:7E:79:AA:0F:66:A6:34:3A:2F:3E:5B:88:01:C3:DC:F2
```

## Ubuntu installation

```bash
sha256sum -c SHA256SUMS
sudo apt install ./X-linux-amd64.deb
x
```

## Limitations

- No forward secrecy, sender identity, replay protection, or metadata protection.
- No independent security audit has been performed.
- Physical arm64 Android device testing is still external.
- App-internal Android data paths are fixed by the OS sandbox; the Local Data
  panel lets you change the **export** folder instead.

Apache-2.0. Made by jackh0006, with AI assistance.
