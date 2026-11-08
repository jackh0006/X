## What changed

<!-- A short description and the motivation. -->

## Security impact

- [ ] No cryptography, format, parser or dependency change
- [ ] Cryptography / format / parser / dependency change (describe below)

<!-- If checked, include test vectors, compatibility notes and updated docs. -->

## Tests

<!-- Commands run and their results. Link CI runs when available. -->

- [ ] `cargo fmt --check`
- [ ] `cargo clippy -D warnings`
- [ ] `cargo test --release`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Linux/Android build or package check (if affected)

## Checklist

- [ ] No secrets, keystores, passphrases, or private wallet material
- [ ] Docs updated (README / CRYPTOGRAPHY / CHANGELOG as needed)
- [ ] No new network dependency or unnecessary permission
- [ ] Accessibility and light/dark themes considered
