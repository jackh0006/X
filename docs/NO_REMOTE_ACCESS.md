# No remote access: evidence

X is designed so the installed app has no path to a developer server.

## Android

- Release manifest has **no `INTERNET` permission**. Verify:
  ```bash
  aapt dump permissions X-android-universal.apk | grep INTERNET
  # no output
  ```
- No account, login, upload, analytics, crash-reporting, Firebase, or telemetry
  SDK is present.
- The only network-capable component would require the Android permission,
  which is absent; the OS blocks network sockets for the app.

## Linux

- The app contains no HTTP client or telemetry endpoint.
- Source scan:
  ```bash
  ./scripts/no_network_check.sh
  ```
- Runtime trace during a local launch:
  ```bash
  strace -f -e trace=network -o /tmp/x-net.log ./x
  ```
  The 2026-11-09 trace showed only local `AF_UNIX` connections to the session
  bus, Wayland, and the accessibility bus. There were **no `AF_INET` or
  `AF_INET6` sockets and no Internet `connect()` calls**.

## Source

- No master password, recovery key, developer decryption key, or hidden
  network path exists in `core/`, `app/lib/`, or the platform glue.
- The passphrase is never embedded in the ciphertext.
- The QR feature displays the phrase only after an explicit action and sets
  Android `FLAG_SECURE` while the QR is visible.

## Limits of this proof

This proves the **published source and artifact** contain no remote access. It
does not prove that a future release signed by the developer can never be
malicious. Users should verify source, signed tags, checksums, and provenance
for every release.

## Reproduce

```bash
./scripts/no_network_check.sh dist/X-android-universal.apk
aapt dump permissions X-android-universal.apk
git verify-tag v1.1.0
sha256sum -c SHA256SUMS
```
