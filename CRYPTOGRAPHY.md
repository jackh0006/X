# Cryptography

X uses libsodium for every cryptographic operation. No primitive is implemented
by this project. The same Rust core and the same payload format are used by the
Ubuntu and Android builds.

- libsodium: **1.0.22** (vendored and statically linked via
  `libsodium-sys-stable` 1.24.5, through `libsodium-rs` 0.3.1)
- AEAD: **XChaCha20-Poly1305-IETF**
- KDF: **Argon2id v1.3** (`crypto_pwhash`, 32-byte output)
- Randomness: libsodium `randombytes_buf` (operating-system CSPRNG)
- Encoding: canonical Base64URL without padding
- Passphrase generator: 7 words from the bundled EFF large wordlist
  (12.92 bits per word, about 90 bits total)

## Payload format v1

```text
X1.<base64url(payload)>

payload:
  offset  size  field
  0       4     magic "XMSG"
  4       1     format version (1)
  5       1     AEAD id (1 = XChaCha20-Poly1305-IETF)
  6       1     KDF id  (1 = Argon2id v1.3)
  7       4     opslimit, unsigned big-endian
  11      4     memlimit in bytes, unsigned big-endian
  15      16    salt
  31      24    nonce
  55      N     ciphertext
  55+N    16    Poly1305 authentication tag
```

The first **55 bytes** are passed to the AEAD as associated authenticated data
(AAD). Changing any header byte — including the salt, nonce, version, algorithm
ids or KDF parameters — causes authentication to fail. The textual `X1.` prefix
is not secret; it selects the parser and must match the authenticated version.

### Encoding rules

- The body must be canonical Base64URL (`A-Z`, `a-z`, `0-9`, `-`, `_`), with no
  padding, no interior whitespace and no line breaks.
- Leading and trailing ASCII whitespace is ignored, so a copied payload that
  gained a final newline still opens.
- The decoder re-encodes the bytes and requires an exact match. This rejects
  non-canonical encodings with non-zero trailing bits.
- Maximum encoded body: 96 KiB. Maximum plaintext: 64 KiB. Maximum passphrase:
  1024 UTF-8 bytes.
- Any failure is reported before the plaintext is returned. Authentication
  failure is always reported as “wrong passphrase, or the encrypted text was
  modified or corrupted”; X does not expose a decryption oracle that separates
  those two causes.

## Key derivation

```
key = Argon2id(
    password = UTF-8 passphrase bytes,
    salt     = 16 random bytes,
    opslimit = profile passes,
    memlimit = profile memory in bytes,
    output   = 32 bytes,
    version  = 0x13,
    lanes    = 1
)
```

Passphrases are **not** Unicode-normalized. The exact UTF-8 byte sequence is
used. A composed and a decomposed spelling of the same visible text are
different passphrases; the interface states that passphrases are
case-sensitive and must match exactly.

### Profiles

| Profile | Argon2id memory | Passes | Intended use |
|---|---:|---:|---|
| Standard (default) | 128 MiB | 3 | Desktop and mid-range phones |
| High | 256 MiB | 4 | Higher-cost option; slower on older phones |

Accepted range when decrypting: **64 MiB–256 MiB** and **2–10 passes**. A
payload that requests parameters outside this range is rejected **before** the
KDF allocates memory. This bounds attacker-controlled memory use. X never
silently substitutes weaker parameters: the parameters that were used are
authenticated in the header.

Measured on the test machine (Pentium G2030, 2 cores, 3.8 GiB RAM, Ubuntu
24.04): Standard end-to-end encryption/decryption ≈ 470 ms; High ≈ 1.24 s.
The KDF dominates; a 64 KiB message adds only a few milliseconds. See
[`docs/PERFORMANCE_BENCHMARKS.md`](docs/PERFORMANCE_BENCHMARKS.md).

## Encryption

1. Validate passphrase length (8–1024 bytes) and plaintext length (≤ 64 KiB).
2. Generate a fresh 16-byte salt and 24-byte nonce with the OS CSPRNG.
3. Derive the 32-byte key with Argon2id.
4. Build the 55-byte header and authenticate it as AAD.
5. Encrypt with XChaCha20-Poly1305; libsodium appends the 16-byte tag.
6. Serialize header + ciphertext + tag and encode as `X1.<base64url>`.

Salt and nonce are generated per encryption. They are never reused by X; there
is no counter or deterministic nonce derivation.

## Decryption

1. Parse and strictly validate the envelope.
2. Validate KDF bounds **before** allocating.
3. Derive the key from the header's salt and parameters.
4. Verify and decrypt with the 55-byte header as AAD.
5. Return the plaintext only after successful authentication.

The plaintext is returned in a `Zeroizing<Vec<u8>>`; the derived key uses
`zeroize`/`ZeroizeOnDrop`. The FFI copies plaintext into Dart strings, which
cannot be reliably erased by the Dart runtime. This limitation is documented
rather than overstated.

## Independent checks in the test suite

- **XChaCha20-Poly1305** output is compared byte-for-byte with the independent
  RustCrypto `chacha20poly1305` implementation.
- **Argon2id** output is compared byte-for-byte with the independent `argon2`
  crate using matching parameters.
- Parser tests cover invalid Base64URL, non-canonical encodings, truncation,
  unsupported versions/algorithms/KDFs, KDF bounds and oversized inputs.
- Tamper tests modify ciphertext and authenticated header fields.
- Proptest round-trips the envelope and throws garbage at the parser.
- A libFuzzer target ran 18.4 million executions without a crash (without
  AddressSanitizer; see the testing limitations in `docs/TEST_RESULTS.md`).

## What this design does not provide

- **No forward secrecy.** One static passphrase protects every message
  encrypted with it.
- **No sender authentication.** Anyone who knows the passphrase can create a
  valid payload. The tag proves knowledge of the passphrase, not identity.
- **No metadata protection.** The format and approximate message length are
  visible; the transport still sees who sent what and when.
- **No protection against replay.** A valid old payload remains valid.
- **No protection on a compromised device.** Malware, keyloggers, screen
  capture, clipboard readers and a compromised OS are outside the boundary.
- **No guarantee of memory erasure** across Dart, the Flutter engine, the OS,
  swap, or crash dumps.
- **No independent audit.** The code and tests are public, but no third-party
  security audit has been completed.

## Versioning

`format version` is authenticated. A future version may add new AEAD or KDF
ids while keeping the parser able to read v1. X rejects unknown versions and
algorithms rather than guessing. Backward compatibility is a release
requirement for every future version that claims to read v1.
