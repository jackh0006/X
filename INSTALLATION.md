# Installation

## Android (arm64-v8a)

Requirements: Android 7.0 (API 24) or newer, **arm64-v8a** device.

1. Download `X-android-arm64.apk` from
   [Releases](https://github.com/jackh0006/X/releases/latest).
2. Verify the SHA-256 checksum from the same release:
   ```bash
   sha256sum X-android-arm64.apk
   ```
   Compare with `SHA256SUMS`.
3. Allow your browser/file manager to install unknown apps, then open the APK.
4. The package id is `com.jackh0006.x`; the label is **X**.

The release is signed with a dedicated RSA-4096 key. Verify it with Android's
`apksigner` if you build or audit locally:

```text
Certificate SHA-256:
E8:16:9C:CC:4F:6A:77:B8:6A:44:B8:B6:89:38:F0:DD:7E:79:AA:0F:66:A6:34:3A:2F:3E:5B:88:01:C3:DC:F2
```

X requests no Internet permission and disables Android backup.

## Ubuntu (amd64)

Tested on **Ubuntu 24.04.5 LTS**. Other releases are not claimed as tested.

```bash
sudo apt install ./X-linux-amd64.deb
x
```

Or:

```bash
sudo dpkg -i X-linux-amd64.deb
sudo apt-get install -f   # only if dependencies are missing
```

The package installs:

- `/opt/x/` — application bundle and `libx_core.so`
- `/usr/bin/x` — launcher symlink
- `/usr/share/applications/x.desktop`
- hicolor icons under `/usr/share/icons/`

Uninstall:

```bash
sudo apt remove x
```

User preferences under the XDG data directory are not removed by package
removal; delete them manually if desired. The package creates no system
service, no root daemon, and no background process.

Verify the DEB before installing:

```bash
sha256sum X-linux-amd64.deb
dpkg-deb -I X-linux-amd64.deb
```

## Build from source

See [`BUILDING.md`](BUILDING.md).

## Supported formats

- Android: APK, arm64-v8a only.
- Ubuntu: DEB, amd64 only.
- No web build, no iOS build, no 32-bit build is published.

## Payload compatibility

Ubuntu and Android use the same Rust core and the same `X1.` format. You can
encrypt on one and decrypt on the other. The passphrase must be shared
separately.
