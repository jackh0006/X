# AI/remote access: what is and is not possible

## Installed application

The installed X application has **no code path that sends user data to
DeepSeek, OpenAI, or any other service**:

- The Android release has **no `INTERNET` permission**.
- The Linux app has no HTTP client, socket client, analytics, telemetry, crash
  reporting, account, or remote endpoint.
- No API key, model endpoint, or vendor SDK is present in the source.
- `scripts/no_network_check.sh` passes for the release APK and source tree.
- A Linux `strace -f -e trace=network` launch shows only local `AF_UNIX`
  connections (D-Bus, Wayland, accessibility); no `AF_INET`/`AF_INET6` and no
  Internet `connect()`.
- Passphrases and plaintext are never logged.

## The AI development environment

The **agent harness** used to build this repository can read files in the
workspace, including files you place there. That is a property of this coding
environment, not of the installed X application. No such channel exists in X's
code or permissions.

## What cannot be proven

No software author can prove that a *future* signed update will never contain
malicious code. The verifiable controls are:

- public source at the tagged revision,
- signed tag and release artifacts,
- SHA-256 checksums,
- GitHub build provenance,
- APK signature verification,
- reproducible build instructions.

Verify those for every release. Do not install an artifact whose checksum or
signature does not match.

## Commands

```bash
./scripts/no_network_check.sh dist/X-android-arm64.apk
aapt dump permissions X-android-arm64.apk
strace -f -e trace=network -o /tmp/x-net.log ./x
git verify-tag v1.1.3
sha256sum -c SHA256SUMS
```
