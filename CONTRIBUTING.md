# Contributing

Thank you for improving X. The project is small; changes that keep it small,
auditable and offline are preferred.

## Ground rules

- Do not weaken cryptography, remove tests, or add a network dependency.
- Do not add accounts, telemetry, ads, analytics, or unnecessary permissions.
- Do not change the payload format without a version bump, a written
  compatibility plan, and new cross-platform fixtures.
- Never commit passphrases, keystores, signing passwords, wallet secrets, or
  real user messages.
- By contributing, you agree that your contribution is licensed under
  Apache-2.0.

## Workflow

1. Open an issue for non-trivial changes, especially anything touching
   `core/src/format.rs`, `core/src/crypto.rs`, limits or dependencies.
2. Fork and create a focused branch.
3. Add or update tests. Crypto/format changes need regression vectors.
4. Run the local gate in [`TESTING.md`](TESTING.md).
5. Open a pull request using the template. Describe security impact and test
   evidence.
6. CI must pass. A maintainer reviews; cryptography changes require an explicit
   second review when a second maintainer is available.

## Style

- Rust: `cargo fmt`, clippy clean, no new `unsafe` outside the FFI module.
- Dart: `flutter analyze` clean; keep widgets in `app/lib`.
- Documentation: plain, accurate, no marketing claims that are not backed by
  evidence.
- Commits: imperative subject, explain the why. Sign commits when possible.

## Reporting vulnerabilities

Follow [`SECURITY.md`](SECURITY.md), not the public issue tracker.

## Code of conduct

Participation is covered by [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
