# Roadmap

This is a direction, not a promise. Security and honesty take priority over
feature count.

## 1.0.x — maintenance

- Keep dependencies patched and rerun the release gate.
- Fix accessibility and platform bugs found by users.
- Expand device and Ubuntu-version compatibility evidence.
- Improve the Android runtime test matrix.

## 1.1 — polish, no format break

- Add an optional passphrase-strength explanation with entropy estimates.
- Improve large-message editor ergonomics without raising the 64 KiB limit.
- Add more automated screenshot/golden coverage.
- Add reproducible-build documentation for the Android artifact.

## Under consideration

- A v2 format with an explicit key-derivation profile id (not just parameters)
  and a documented migration path.
- Optional local file encryption workflow.
- A desktop keyboard-shortcut help sheet.

## Explicit non-goals

- Accounts, servers, cloud sync, contact discovery, group chat, calls.
- Telemetry, analytics, ads, or a proprietary backend.
- Forward secrecy without a real key-exchange and ratchet design.
- Claiming an audit, certification, or “100% secure” score.
