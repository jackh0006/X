//! Versioned, portable payload format.
//!
//! ```text
//! X1.<base64url(payload)>
//!
//! payload:
//!   magic           4   "XMSG"
//!   format version  1   0x01
//!   AEAD id         1   0x01  XChaCha20-Poly1305-IETF
//!   KDF id          1   0x01  Argon2id v1.3
//!   opslimit        4   u32 BE
//!   memlimit        4   u32 BE (bytes)
//!   salt           16
//!   nonce          24
//!   ciphertext      N
//!   tag            16
//! ```
//!
//! The first 55 bytes (everything before the ciphertext) are passed to the AEAD
//! as associated authenticated data.

use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine as _};

use crate::error::XError;
use crate::limits::{
    profile_hint, validate_kdf_params, Profile, MAX_ENCODED, MAX_PLAINTEXT, NONCE_LEN, SALT_LEN,
    TAG_LEN,
};

pub const MAGIC: [u8; 4] = *b"XMSG";
pub const VERSION: u8 = 1;
pub const AEAD_XCHACHA20_POLY1305: u8 = 1;
pub const KDF_ARGON2ID13: u8 = 1;
pub const HEADER_LEN: usize = 4 + 1 + 1 + 1 + 4 + 4 + SALT_LEN + NONCE_LEN;
pub const PREFIX: &str = "X1.";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Header {
    pub version: u8,
    pub aead: u8,
    pub kdf: u8,
    pub opslimit: u32,
    pub memlimit: u32,
    pub salt: [u8; SALT_LEN],
    pub nonce: [u8; NONCE_LEN],
}

impl Header {
    pub fn new(profile: Profile, salt: [u8; SALT_LEN], nonce: [u8; NONCE_LEN]) -> Self {
        Self {
            version: VERSION,
            aead: AEAD_XCHACHA20_POLY1305,
            kdf: KDF_ARGON2ID13,
            opslimit: profile.opslimit(),
            memlimit: profile.memlimit(),
            salt,
            nonce,
        }
    }

    pub fn to_bytes(&self) -> [u8; HEADER_LEN] {
        let mut out = [0u8; HEADER_LEN];
        out[0..4].copy_from_slice(&MAGIC);
        out[4] = self.version;
        out[5] = self.aead;
        out[6] = self.kdf;
        out[7..11].copy_from_slice(&self.opslimit.to_be_bytes());
        out[11..15].copy_from_slice(&self.memlimit.to_be_bytes());
        out[15..31].copy_from_slice(&self.salt);
        out[31..55].copy_from_slice(&self.nonce);
        out
    }

    pub fn parse(raw: &[u8]) -> Result<Self, XError> {
        if raw.len() != HEADER_LEN {
            return Err(XError::InvalidFormat("truncated header"));
        }
        if raw[0..4] != MAGIC {
            return Err(XError::InvalidFormat("bad magic"));
        }
        let version = raw[4];
        if version != VERSION {
            return Err(XError::UnsupportedVersion(version));
        }
        let aead = raw[5];
        if aead != AEAD_XCHACHA20_POLY1305 {
            return Err(XError::UnsupportedAlgorithm(aead));
        }
        let kdf = raw[6];
        if kdf != KDF_ARGON2ID13 {
            return Err(XError::UnsupportedKdf(kdf));
        }
        let opslimit = u32::from_be_bytes([raw[7], raw[8], raw[9], raw[10]]);
        let memlimit = u32::from_be_bytes([raw[11], raw[12], raw[13], raw[14]]);
        if !validate_kdf_params(opslimit, memlimit) {
            return Err(XError::InvalidKdfParameters);
        }
        let mut salt = [0u8; SALT_LEN];
        salt.copy_from_slice(&raw[15..31]);
        let mut nonce = [0u8; NONCE_LEN];
        nonce.copy_from_slice(&raw[31..55]);
        Ok(Self {
            version,
            aead,
            kdf,
            opslimit,
            memlimit,
            salt,
            nonce,
        })
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Decoded {
    pub header: Header,
    /// Exact authenticated header bytes (AAD).
    pub header_bytes: [u8; HEADER_LEN],
    /// Ciphertext followed by the 16-byte Poly1305 tag.
    pub ciphertext: Vec<u8>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PayloadInfo {
    pub version: u8,
    pub aead: u8,
    pub kdf: u8,
    pub opslimit: u32,
    pub memlimit: u32,
    pub ciphertext_len: usize,
    pub profile: Option<Profile>,
}

pub fn encode(header: &Header, ciphertext: &[u8]) -> String {
    let header_bytes = header.to_bytes();
    let mut raw = Vec::with_capacity(HEADER_LEN + ciphertext.len());
    raw.extend_from_slice(&header_bytes);
    raw.extend_from_slice(ciphertext);
    format!("{PREFIX}{}", URL_SAFE_NO_PAD.encode(raw))
}

pub fn decode(payload: &str) -> Result<Decoded, XError> {
    let trimmed = payload.trim_matches(|c: char| c.is_ascii_whitespace());
    let body = trimmed
        .strip_prefix(PREFIX)
        .ok_or(XError::InvalidFormat("missing X1 prefix"))?;

    if body.is_empty() {
        return Err(XError::InvalidFormat("empty payload"));
    }
    if body.len() > MAX_ENCODED {
        return Err(XError::PayloadTooLarge);
    }
    // Strict alphabet: Base64URL, no padding, no line breaks or interior spaces.
    if !body
        .bytes()
        .all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_')
    {
        return Err(XError::InvalidFormat("non-Base64URL character"));
    }

    let raw = URL_SAFE_NO_PAD
        .decode(body)
        .map_err(|_| XError::InvalidFormat("invalid Base64URL"))?;

    // Reject non-canonical encodings (non-zero trailing bits, alternate forms).
    if URL_SAFE_NO_PAD.encode(&raw) != body {
        return Err(XError::InvalidFormat("non-canonical Base64URL"));
    }

    if raw.len() < HEADER_LEN + TAG_LEN {
        return Err(XError::InvalidFormat("truncated payload"));
    }
    if raw.len() > HEADER_LEN + MAX_PLAINTEXT + TAG_LEN {
        return Err(XError::PayloadTooLarge);
    }

    let mut header_bytes = [0u8; HEADER_LEN];
    header_bytes.copy_from_slice(&raw[..HEADER_LEN]);
    let header = Header::parse(&header_bytes)?;

    let ciphertext = raw[HEADER_LEN..].to_vec();
    if ciphertext.len() < TAG_LEN {
        return Err(XError::InvalidFormat("missing authentication tag"));
    }

    Ok(Decoded {
        header,
        header_bytes,
        ciphertext,
    })
}

pub fn inspect(payload: &str) -> Result<PayloadInfo, XError> {
    let decoded = decode(payload)?;
    Ok(PayloadInfo {
        version: decoded.header.version,
        aead: decoded.header.aead,
        kdf: decoded.header.kdf,
        opslimit: decoded.header.opslimit,
        memlimit: decoded.header.memlimit,
        ciphertext_len: decoded.ciphertext.len(),
        profile: profile_hint(decoded.header.opslimit, decoded.header.memlimit),
    })
}
