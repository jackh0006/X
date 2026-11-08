# Support

X is a small open-source utility maintained by one developer.

## Before asking

- **The passphrase is not in the encrypted text.** X cannot recover it. If it is
  lost, the message cannot be decrypted by anyone, including the developer.
- **“Wrong passphrase or corrupted message”** means the passphrase is not an
  exact match (case, spaces, punctuation) or the payload changed. Try
  re-copying the whole `X1.…` text.
- **Invalid encrypted text** means the `X1.` envelope is missing or malformed.
  Check for line breaks or truncation.
- **Android install blocked** — the APK supports arm64-v8a only; enable
  installation from your file manager for this one package.
- **Ubuntu launch** — run `x` from a terminal to see an error; verify the DEB
  dependencies with `sudo apt-get install -f`.

## Reporting a bug

Use the GitHub bug template and include:

- version, platform and architecture;
- exact steps;
- whether the message was Unicode/large;
- error text (never include your real passphrase or plaintext).

## Security issues

Do **not** open a public issue. Email **jackh109867@gmail.com** as described in
[`SECURITY.md`](SECURITY.md).

## Scope of support

Best-effort community support. No SLA, no paid support, and no recovery service.
Donations do not purchase support.
