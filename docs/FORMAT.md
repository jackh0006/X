# Payload format v1

Full cryptographic rationale: [`../CRYPTOGRAPHY.md`](../CRYPTOGRAPHY.md).

## Envelope

```
X1.<base64url-no-padding(payload)>
```

## Payload bytes

| Offset | Size | Field |
|---:|---:|---|
| 0 | 4 | magic `XMSG` |
| 4 | 1 | format version = 1 |
| 5 | 1 | AEAD id = 1 (XChaCha20-Poly1305-IETF) |
| 6 | 1 | KDF id = 1 (Argon2id v1.3) |
| 7 | 4 | opslimit, big-endian u32 |
| 11 | 4 | memlimit bytes, big-endian u32 |
| 15 | 16 | salt |
| 31 | 24 | nonce |
| 55 | N | ciphertext |
| 55+N | 16 | Poly1305 tag |

**AAD:** bytes `0..55` (the entire header).

## Limits

- Plaintext: 0–65,536 bytes.
- Encoded body: ≤ 98,304 characters.
- Passphrase: 8–1,024 UTF-8 bytes.
- KDF: ops 2–10; memory 64–256 MiB. Values outside are rejected before
  allocation.

## Parser rules

1. Trim leading/trailing ASCII whitespace.
2. Require exact `X1.` prefix.
3. Require the canonical Base64URL alphabet, no padding, no internal space.
4. Re-encode and compare to reject non-canonical trailing bits.
5. Check magic, version, algorithm and KDF ids; reject unknown values.
6. Validate KDF bounds.
7. Require at least a 16-byte tag.
8. Authenticate before returning any plaintext.

## Test vector

This fixture is used by the cross-platform workflow. It was generated with the
fixed salt/nonce below and is **only** a test vector; the passphrase is public.

```text
passphrase: correct horse battery staple
profile:    Standard (opslimit 3, memlimit 134217728)
salt:       000102030405060708090a0b0c0d0e0f
nonce:      000102030405060708090a0b0c0d0e0f1011121314151617
plaintext:  Meet me at the old bridge at midnight. Bring the sealed envelope.
payload:    X1.WE1TRwEBAQAAAAMIAAAAAAECAwQFBgcICQoLDA0ODwABAgMEBQYHCAkKCwwNDg8QERITFBUWF_P7_ipwOXsGJqwFsblM9AasJnlcDGz9etRJ8g5mGduKzQAYbYoF6i3B9BqsnwBBW382bn3HHjXiLQDvzWIkR5UoTYk95CJutbzL4oF9nTxksg
```

Any implementation that claims compatibility should reproduce this payload and
recover the exact plaintext with the given passphrase and parameters.
