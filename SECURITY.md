# Security policy

## Reporting a vulnerability

Email **jackh109867@gmail.com** with:

- the affected version and platform,
- a description of the issue and its impact,
- reproduction steps or a proof of concept,
- whether you want public credit.

Please do not open a public issue for an unpatched vulnerability. I aim to
acknowledge reports within 7 days and to provide a remediation plan within 30
days. A 90-day coordinated disclosure window is the default; it can be shortened
when a fix is available.

There is no paid bug bounty. Good-faith research is welcome and will be
credited unless you prefer otherwise.

## Supported versions

| Version | Supported |
|---|---|
| 1.1.x | Yes |
| 1.0.x | Yes |
| < 1.0 | Not released |

Security fixes are shipped in a new semantic version; artifacts are never
silently replaced.

## Security posture

- libsodium 1.0.22 provides XChaCha20-Poly1305 and Argon2id.
- No custom cryptography, no network permission, no telemetry, no account.
- The encrypted format and threat model are public:
  [`CRYPTOGRAPHY.md`](CRYPTOGRAPHY.md), [`THREAT_MODEL.md`](THREAT_MODEL.md).
- Automated checks: Rust tests, independent algorithm cross-checks, Flutter
  tests, clippy, `cargo-audit`, `cargo-deny`, CodeQL for workflows, secret
  scanning, dependency review and fuzzing. See
  [`docs/TEST_RESULTS.md`](docs/TEST_RESULTS.md).

## What has not been done

**X has not been independently audited or formally verified.** No claim of
government approval, CIA certification, or mathematical proof is made. Passing
tests is evidence of tested behavior, not a guarantee.

## Release integrity

- APKs are signed with a dedicated 4096-bit RSA key (SHA-256 fingerprint
  published in `INSTALLATION.md`); the keystore is never committed.
- Releases include SHA-256 checksums, a CycloneDX SBOM and GitHub build
  provenance attestations.
- Release tags and subsequent commits are GPG-signed with key
  `CC819EF5E109A1518E840379D8C0CEC84BCCE06B`; the public key is
  [`docs/SIGNING_KEY.asc`](docs/SIGNING_KEY.asc).
- Verify artifacts before installing them. See [`INSTALLATION.md`](INSTALLATION.md)
  and [`docs/VERIFYING.md`](docs/VERIFYING.md).
