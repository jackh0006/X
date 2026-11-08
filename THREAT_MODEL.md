# Threat model

## Scope

X is an offline encryption/decryption utility. It turns text into portable
`X1.…` ciphertext and back. It is **not** a messaging platform, transport,
account system, or key-exchange protocol.

## Assets

1. Message plaintext.
2. The passphrase used to derive the encryption key.
3. Decrypted plaintext displayed or copied after a successful open.
4. The integrity of the encrypted payload.

## Adversaries considered

| Adversary | Capability | X's response |
|---|---|---|
| Channel observer | Reads the ciphertext in transit | XChaCha20-Poly1305 confidentiality; no plaintext is sent by X |
| Active tamperer | Modifies, truncates, reorders or injects bytes | Authenticated header + ciphertext; any modification is rejected |
| Offline guesser | Obtains a payload and tries passphrases | Argon2id with a fresh salt and 128/256 MiB cost |
| Malicious payload author | Crafts headers to exhaust memory or confuse the parser | Strict parser, hard size/KDF caps before allocation, unknown versions rejected |
| Casual local observer | Picks up an unlocked device | No account, no persistence by default, passphrase fields obscured; OS lock is still required |
| Supply-chain attacker | Compromises a dependency or build | Locked dependencies, pinned Actions, audits, SBOM, checksums, build provenance; not eliminated |

## Out of scope

- A compromised operating system, root malware, keylogger, screen recorder or
  clipboard monitor.
- Physical access to an unlocked device or memory extraction.
- A malicious recipient who shares the plaintext or passphrase.
- Weak user-chosen passphrases (the UI warns and offers a strong generator).
- Coercion, traffic analysis, or the metadata of the channel used to carry the
  ciphertext.
- Side-channel attacks on libsodium, the CPU, or the Flutter engine.
- Loss of the passphrase. There is no recovery key, backdoor, or master
  password.

## Guarantees within scope

- If the recipient enters the exact passphrase and the payload has not changed,
  authentication succeeds and the original bytes are returned.
- If the passphrase is wrong, or any authenticated byte changed, no plaintext
  is returned.
- Passphrases are never embedded in payloads.
- The same payload is accepted by the Ubuntu and Android builds of the same
  version.
- The app makes no network requests and requests no Internet permission.

## Residual risks

1. **Passphrase exchange.** X cannot protect a passphrase sent through the same
   compromised channel. Users are told to share it separately or in person.
2. **No forward secrecy.** Compromise of one passphrase exposes every message
   encrypted with it.
3. **No sender identity.** A valid tag proves possession of the passphrase, not
   who created the message.
4. **Replay.** An old ciphertext can be re-sent and will still decrypt.
5. **Length leakage.** Ciphertext length reveals approximate plaintext length.
6. **Clipboard.** Copied text is visible to other apps on many platforms.
7. **Memory.** Dart/Flutter cannot guarantee erasure; swap and crash dumps may
   retain copies.
8. **No audit.** The implementation has automated tests and self-review, not an
   independent security audit.

## Trust boundaries

```
User input (trusted intent, untrusted content)
        │
   Flutter UI (no crypto)
        │  C ABI, explicit lengths, JSON results
   Rust core (small unsafe FFI surface)
        │
   libsodium (audited primitives; vendored static build)
        │
   OS CSPRNG / filesystem / clipboard
```

The parser and KDF parameter validator are treated as hostile-input code.
Parsing never allocates based on an untrusted size before checking the hard
limits.
