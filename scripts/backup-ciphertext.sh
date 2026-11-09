#!/usr/bin/env bash
# Copy an X1 ciphertext file into a private backup folder with a checksum.
# The encryption phrase is never copied.
set -euo pipefail
if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 CIPHERTEXT_FILE [BACKUP_DIR]" >&2
  exit 2
fi
src="$1"
dest="${2:-$HOME/Backups/X}"
if [[ ! -f "$src" ]]; then
  echo "not a file: $src" >&2
  exit 1
fi
if [[ "$(head -c 3 "$src")" != "X1." ]]; then
  echo "refusing: file does not start with X1." >&2
  exit 1
fi
install -d -m 700 "$dest"
name="$(basename "$src")"
install -m 600 "$src" "$dest/$name"
(
  cd "$dest"
  sha256sum "$name" > SHA256SUMS
  chmod 600 SHA256SUMS
  sha256sum -c SHA256SUMS
)
printf 'backup: %s/%s\n' "$dest" "$name"
printf 'Store the encryption phrase separately. Test a restore before relying on it.\n'
