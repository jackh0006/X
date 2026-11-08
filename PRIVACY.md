# Privacy

X is designed to need no personal data.

## What X collects

**Nothing.** X has no account system, no analytics, no telemetry, no crash
reporting, no advertising SDK, and no network client. The Android release
manifest contains no `INTERNET` permission. The Linux build makes no network
requests.

## What stays on the device

- Text you type is held in memory only while you use the screen.
- Encrypted output exists only where you copy, share, or save it.
- The theme preference is stored locally (Android SharedPreferences or the
  Linux XDG data directory). It contains no message or passphrase.
- Passphrases are not stored. They are never written to disk or logs.
- Android backups are disabled (`allowBackup=false`).

## Clipboard and sharing

Copying places the selected text on the system clipboard, where other
applications may read it. On Android, sharing opens the system share sheet with
the ciphertext only; X does not upload it. Review the target app's privacy
practices before sharing.

## Files

Saving uses the platform document picker. X writes only the encrypted text, at
the location you choose. It creates no temporary plaintext files.

## Donations

The Donate screen contains public receiving addresses published by the
developer. Viewing them sends no data. A wallet or exchange may collect
information when you send a transaction; that is outside X.

## Children

X is a general-purpose utility and is not directed at children. It collects no
data from anyone.

## Changes

Privacy-relevant changes are recorded in [`CHANGELOG.md`](CHANGELOG.md). Because
X has no server, there is no server-side privacy policy to update.
