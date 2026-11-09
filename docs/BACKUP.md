# Backup and recovery

X ciphertext is portable text. A backup only needs the `X1.…` file; the
encryption phrase must be retained separately.

## Recommended backup

1. Save the ciphertext from SEND using **Save**.
2. Copy it to at least two trusted locations (for example, an encrypted external
   drive and an offline backup).
3. Record a SHA-256 checksum.
4. Store the encryption phrase in a password manager or a separate offline
   location — **not in the same folder as the ciphertext**.
5. Restore a copy before relying on the backup: open it in RECEIVE on another
   device/install and verify the plaintext.

Helper:

```bash
./scripts/backup-ciphertext.sh /path/to/X-encrypted-message.txt ~/Backups/X
```

The script copies the file with mode `0600`, writes `SHA256SUMS`, and refuses to
copy a file that does not start with `X1.`.

## Recovery limits

- Without the correct phrase, the ciphertext is unrecoverable.
- X has no recovery key, master password, or developer backdoor.
- Preserve the exact phrase, including case, spaces, punctuation and Unicode
  normalization form. X does not normalize phrases.
- Losing both the ciphertext and the phrase loses the message. Losing only the
  app install does not.
- Test a restore after every device or storage change.
