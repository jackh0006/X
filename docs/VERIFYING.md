# Verifying a release

## Checksums

```bash
sha256sum -c SHA256SUMS
```

The checksum file must be downloaded from the same GitHub release as the
artifacts. A checksum is only useful if you trust the release page.

## Android signature

```bash
apksigner verify --print-certs app-release.apk
```

Expected certificate SHA-256:

```text
E8:16:9C:CC:4F:6A:77:B8:6A:44:B8:B6:89:38:F0:DD:7E:79:AA:0F:66:A6:34:3A:2F:3E:5B:88:01:C3:DC:F2
```

## Signed tag and commit

The release tag is GPG-signed. The public key is in
[`SIGNING_KEY.asc`](SIGNING_KEY.asc).

```bash
gpg --import SIGNING_KEY.asc
git fetch --tags
git verify-tag v1.0.1
git log --show-signature -1 v1.0.1
```

Key fingerprint: `CC819EF5E109A1518E840379D8C0CEC84BCCE06B`.

## Build provenance

For a release with GitHub attestations:

```bash
gh attestation verify app-release.apk --repo jackh0006/X
gh attestation verify x_amd64.deb --repo jackh0006/X
```

## DEB

```bash
dpkg-deb -I x_amd64.deb
dpkg-deb -c x_amd64.deb
```

Do not install an artifact whose checksum or signature does not match.
