#!/usr/bin/env bash
# Build X-linux-amd64.deb from an already-built Flutter Linux bundle.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(grep -m1 '^version:' "$ROOT/app/pubspec.yaml" | sed 's/version: //; s/+.*//')"
BUNDLE="$ROOT/app/build/linux/x64/release/bundle"
STAGE="$ROOT/build/deb/x_${VERSION}_amd64"

if [[ ! -x "$BUNDLE/x" ]]; then
  echo "Linux bundle not found; run scripts/build-linux.sh first." >&2
  exit 1
fi
if [[ ! -f "$BUNDLE/lib/libx_core.so" ]]; then
  echo "libx_core.so missing from bundle; run scripts/build-linux.sh." >&2
  exit 1
fi

rm -rf "$STAGE"
install -d "$STAGE/opt/x" "$STAGE/usr/bin" "$STAGE/usr/share/applications" \
  "$STAGE/usr/share/icons/hicolor/128x128/apps" \
  "$STAGE/usr/share/icons/hicolor/256x256/apps" \
  "$STAGE/usr/share/icons/hicolor/512x512/apps" \
  "$STAGE/usr/share/doc/x" "$STAGE/DEBIAN" "$STAGE/debian"

cp -a "$BUNDLE/." "$STAGE/opt/x/"
find "$STAGE/opt/x" -type d -exec chmod 755 {} +
find "$STAGE/opt/x" -type f -exec chmod 644 {} +
chmod 755 "$STAGE/opt/x/x"
ln -s /opt/x/x "$STAGE/usr/bin/x"

install -m 644 "$ROOT/packaging/linux/x.desktop" \
  "$STAGE/usr/share/applications/x.desktop"
install -m 644 "$ROOT/app/assets/icon/icon_128.png" \
  "$STAGE/usr/share/icons/hicolor/128x128/apps/x.png"
install -m 644 "$ROOT/app/assets/icon/icon_256.png" \
  "$STAGE/usr/share/icons/hicolor/256x256/apps/x.png"
install -m 644 "$ROOT/app/assets/icon/icon_512.png" \
  "$STAGE/usr/share/icons/hicolor/512x512/apps/x.png"
install -m 644 "$ROOT/LICENSE" "$STAGE/usr/share/doc/x/copyright"

cat > "$STAGE/usr/share/doc/x/changelog.Debian" <<EOF
x (${VERSION}) unstable; urgency=medium

  * Initial release.
  * Offline XChaCha20-Poly1305 and Argon2id text encryption.
  * Android arm64-v8a and Ubuntu amd64 share one payload format.

 -- jackh0006 <jackh109867@gmail.com>  Sun, 08 Nov 2026 00:00:00 +0000
EOF
gzip -9n "$STAGE/usr/share/doc/x/changelog.Debian"

cat > "$STAGE/debian/control" <<'EOF'
Source: x
Section: utils
Priority: optional
Maintainer: jackh0006 <jackh109867@gmail.com>
Standards-Version: 4.6.2

Package: x
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}
Description: offline encrypted text utility
 X encrypts text locally with XChaCha20-Poly1305 and Argon2id and produces
 portable X1 text that can be sent through any messenger. No account, no
 server, no telemetry.
EOF

DEPS="$(cd "$STAGE" && dpkg-shlibdeps -O -e"$STAGE/opt/x/x" 2>/dev/null \
  | sed -n 's/^shlibs:Depends=//p')"
# Ubuntu 24.04 renamed several runtime packages with a t64 suffix; each t64
# package Provides the historical name, which also exists on older releases.
DEPS="$(printf '%s' "$DEPS" | sed -E 's/\b(lib[a-z0-9.+-]+)-0t64/\1-0/g')"
if [[ -z "$DEPS" ]]; then
  echo "Could not compute package dependencies." >&2
  exit 1
fi

INSTALLED_SIZE="$(du -sk "$STAGE/opt/x" | awk '{print $1}')"
cat > "$STAGE/DEBIAN/control" <<EOF
Package: x
Version: ${VERSION}
Architecture: amd64
Maintainer: jackh0006 <jackh109867@gmail.com>
Installed-Size: ${INSTALLED_SIZE}
Depends: ${DEPS}
Section: utils
Priority: optional
Homepage: https://github.com/jackh0006/X
Description: offline encrypted text utility
 X encrypts text locally with XChaCha20-Poly1305 authenticated encryption
 and Argon2id key derivation, producing portable X1 text that can be sent
 through any messenger, email, or file transfer. The passphrase is never
 embedded in the payload. No account, no server, and no telemetry.
EOF

rm -rf "$STAGE/debian"
(
  cd "$STAGE"
  find opt usr -type f -print0 | sort -z | xargs -0 md5sum > DEBIAN/md5sums
)

mkdir -p "$ROOT/dist"
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1791504000}"
dpkg-deb --build --root-owner-group --uniform-compression \
  "$STAGE" "$ROOT/dist/X-linux-amd64.deb" >/dev/null
echo "deb: $ROOT/dist/X-linux-amd64.deb"
