# Comparison

X belongs to a different category from chat applications. Chat apps manage
identities, discovery, transport, delivery, history and metadata. X is a small
offline encryption utility: it makes portable ciphertext that you carry through
whatever channel you already use.

The table separates the categories rather than pretending they are equivalent.

## X compared with messaging platforms

| Property | X | Signal | WhatsApp | Telegram | Threema | SimpleX Chat |
|---|---|---|---|---|---|---|
| Primary category | Standalone text encryption | Messenger | Messenger | Messenger | Messenger | Messenger |
| Account required | **No** | Phone number | Phone number | Phone number | Threema ID | No user ID |
| Central service required to use | **No** | Yes | Yes | Yes | Yes | Relay servers |
| Fully offline encrypt/decrypt | **Yes** | No | No | No (cloud) | Partly | No |
| Portable ciphertext for any channel | **Yes** | No | No | No | No | No |
| End-to-end encrypted messaging | N/A | Yes | Yes | Secret chats only | Yes | Yes |
| Forward secrecy | **No** | Yes | Yes | Secret chats | Yes | Yes |
| Sender identity | **No** (passphrase possession only) | Yes | Yes | Yes | Yes | Yes |
| Metadata protection | **No** | Strong | Limited | Limited | Strong | Strong |
| Open source | **Yes** | Yes | No | Clients open; server closed | Apps open source; service proprietary | Yes |
| Client-side audit status | No independent audit | Extensively reviewed | Extensively reviewed | Mixed public analysis | Audited (vendor-commissioned) | Public analysis |

Notes:

- “Account required” means an identity registered with a service. X has no
  registration, directory, or server.
- Telegram cloud chats are not end-to-end encrypted; its Secret Chats are.
- Threema's apps are open source; its service is not a public federated protocol.
- These descriptions are feature-level and do not assert that any competitor is
  insecure.

## X compared with standalone encryption tools

| Property | X | OpenPGP tools (e.g. GnuPG) | age | Minisign/Signify |
|---|---|---|---|---|
| Authenticated encryption | XChaCha20-Poly1305 | Yes, depending on construction | XChaCha20-Poly1305 | Signature-only |
| Password-based mode | Argon2id | Yes, often S2K | Yes (scrypt) | No |
| Portable text payload | `X1.…` | ASCII armor | Text armor | Text signature |
| Key management burden | Passphrase | Keys, web of trust | Recipient keys | Keys |
| GUI for nontechnical users | Yes | Varies | CLI-first | CLI |
| No account/server | Yes | Yes | Yes | Yes |
| Forward secrecy | No | No | No | N/A |
| Sender identity | No | Yes, with keys | No (recipient key model) | Yes |
| Independent audit of this exact app | No | Tool-dependent | Tool-dependent | Tool-dependent |

## What X intentionally does not compete on

- Group chat, attachments, calls, presence, delivery receipts, contact
  discovery, multi-device sync, or message history.
- Forward secrecy and post-compromise security.
- Hiding who communicates with whom.
- Protecting a compromised endpoint.

## Where X is genuinely useful

- You already have a channel (SMS, email, a forum, a USB stick) and do not trust
  it with the plaintext.
- You want no account, registration, server, or provider.
- You need the same text to open on Ubuntu and Android.
- You want a simple, inspectable, offline tool rather than a messaging network.
