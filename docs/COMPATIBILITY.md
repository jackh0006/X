# Compatibility

## Tested

| Platform | Version / ABI | Status | Evidence |
|---|---|---|---|
| Ubuntu | 24.04.5 LTS, amd64 | PASS | Built, packaged, extracted, launched |
| Android | arm64-v8a, minSdk 24, targetSdk 36 | Build PASS | Signed APK verified; emulator CI |
| Android emulator | x86_64, API 35 | **PASS** | CI run 42630568802, Linux and Android both directions |
| Ubuntu 22.04 / 25.04 | amd64 | NOT TESTED | dependency names are compatible; binary built on 24.04 |
| Physical Android phone | arm64-v8a | NOT TESTED | no device available |

## Android

- Application ID: `com.jackh0006.x`
- Version: 1.1.3 (versionCode 6)
- minSdk 24, targetSdk 36, compileSdk 36
- Native core: `lib/arm64-v8a/libx_core.so`
- Signing: RSA-4096, APK Signature Scheme v2, certificate SHA-256
  `E8:16:9C:CC:4F:6A:77:B8:6A:44:B8:B6:89:38:F0:DD:7E:79:AA:0F:66:A6:34:3A:2F:3E:5B:88:01:C3:DC:F2`
- Permissions: no `INTERNET`; only the AndroidX-generated
  `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`
- Backup disabled (`allowBackup=false`)
- Share and save use Android system intents (no storage permission)

The APK's `native-code` list is exactly `arm64-v8a`; no 32-bit or x86 stubs
are packaged. The supported and tested target is **arm64-v8a**.

## Ubuntu

- Package: `X-linux-amd64.deb`, architecture amd64
- Install root: `/opt/x`, launcher `/usr/bin/x`
- Desktop entry: `/usr/share/applications/x.desktop`
- Icons: hicolor 128/256/512
- Runtime dependencies are generated with `dpkg-shlibdeps` (GTK 3, GLib, Pango,
  Cairo, ATK, gdk-pixbuf, zlib, libc, libstdc++, libgcc)
- Tested on Ubuntu 24.04.5 with the distribution GTK theme, both light and dark

## Payload compatibility

The format is platform-independent text. A payload produced on Ubuntu is
accepted by Android and vice versa; the implementation is the same Rust crate.
The automated interoperability workflow decrypts a Linux-generated fixture on an
Android emulator and decrypts an Android-generated payload with the Linux core
(see `docs/TEST_RESULTS.md` for the latest result).

## Not claimed

Universal compatibility with every Android device, every Ubuntu release, every
desktop environment, or every keyboard layout. Test on your target before
relying on it.
