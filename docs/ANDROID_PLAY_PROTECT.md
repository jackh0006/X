# Android Play Protect and installation

## Why the warning appears

Android warns when an app is installed outside the Play Store and is signed by a
key Google has not seen. This is expected for a self-signed, open-source APK. It
does **not** mean the APK is corrupt or that X requests network access.

**This warning cannot be removed by application code.** Any developer can sign
an APK; Google decides whether to trust that signing identity. Options:

1. Tap **More details → Install anyway** after verifying the artifact.
2. Install through `adb` on a development device:
   ```bash
   adb install -r X-android-universal.apk
   ```
3. Publish through the Google Play Store (not currently configured).

## Verify before installing

```bash
sha256sum -c SHA256SUMS
apksigner verify --print-certs X-android-universal.apk
```

Expected certificate SHA-256:

```text
E8:16:9C:CC:4F:6A:77:B8:6A:44:B8:B6:89:38:F0:DD:7E:79:AA:0F:66:A6:34:3A:2F:3E:5B:88:01:C3:DC:F2
```

The release is signed with APK Signature Scheme v2 and v3.
The package is `com.jackh0006.x`, arm64-v8a, minSdk 24.

## If installation fails differently

If you see “There was a problem parsing the package,” “App not installed,” or a
signature mismatch, provide the exact text. Those are actionable build/signing
errors. A Play Protect “unknown app” warning is not.

## Permissions

The release requests no Internet, camera, storage, location, microphone, or
contacts permission. Saving uses the Android Storage Access Framework, which
does not require a storage permission.
