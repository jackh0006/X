//! X encryption core.
//!
//! Public API is byte-oriented so the wire format stays independent of the UI.
//! The Flutter layer only ever sees text; binary edge cases remain testable here.
//!
//! Security properties and documented limitations live in `CRYPTOGRAPHY.md`
//! and `THREAT_MODEL.md` at the repository root.

pub mod error;
pub mod ffi;
pub mod format;
pub mod limits;
pub mod passphrase;

mod crypto;
#[cfg(test)]
mod tests;

use zeroize::Zeroizing;

pub use error::XError;
pub use limits::{
    Profile, MAX_PASSPHRASE, MAX_PLAINTEXT, MIN_PASSPHRASE, NONCE_LEN, SALT_LEN, TAG_LEN,
};
pub use passphrase::{entropy_bits, DEFAULT_WORDS};

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
pub const FORMAT_VERSION: u8 = format::VERSION;

fn validate_passphrase(passphrase: &[u8]) -> Result<(), XError> {
    if passphrase.len() < MIN_PASSPHRASE {
        return Err(XError::PassphraseTooShort);
    }
    if passphrase.len() > MAX_PASSPHRASE {
        return Err(XError::PassphraseTooLong);
    }
    Ok(())
}

fn validate_plaintext(plaintext: &[u8]) -> Result<(), XError> {
    if plaintext.len() > MAX_PLAINTEXT {
        return Err(XError::MessageTooLarge);
    }
    Ok(())
}

fn seal_with_material(
    plaintext: &[u8],
    passphrase: &[u8],
    profile: Profile,
    salt: [u8; SALT_LEN],
    nonce: [u8; NONCE_LEN],
) -> Result<String, XError> {
    validate_plaintext(plaintext)?;
    validate_passphrase(passphrase)?;
    let header = format::Header::new(profile, salt, nonce);
    let header_bytes = header.to_bytes();
    let key = crypto::derive_key(passphrase, &salt, profile.opslimit(), profile.memlimit())?;
    let ciphertext = crypto::seal(plaintext, &header_bytes, &nonce, &key)?;
    Ok(format::encode(&header, &ciphertext))
}

/// Encrypt arbitrary bytes into a portable `X1.…` payload.
pub fn encrypt(plaintext: &[u8], passphrase: &[u8], profile: Profile) -> Result<String, XError> {
    let (salt, nonce) = crypto::random_material();
    seal_with_material(plaintext, passphrase, profile, salt, nonce)
}

/// Decrypt a portable payload. The returned buffer is zeroized on drop.
pub fn decrypt(payload: &str, passphrase: &[u8]) -> Result<Zeroizing<Vec<u8>>, XError> {
    validate_passphrase(passphrase)?;
    let decoded = format::decode(payload)?;
    if decoded.ciphertext.len() > MAX_PLAINTEXT + TAG_LEN {
        return Err(XError::MessageTooLarge);
    }
    let key = crypto::derive_key(
        passphrase,
        &decoded.header.salt,
        decoded.header.opslimit,
        decoded.header.memlimit,
    )?;
    let plaintext = crypto::open(
        &decoded.ciphertext,
        &decoded.header_bytes,
        &decoded.header.nonce,
        &key,
    )?;
    if plaintext.len() > MAX_PLAINTEXT {
        return Err(XError::MessageTooLarge);
    }
    Ok(plaintext)
}

/// Validate structure and read public metadata without a passphrase.
pub fn inspect(payload: &str) -> Result<format::PayloadInfo, XError> {
    format::inspect(payload)
}

/// Generate a strong passphrase. `words` must be between 4 and 12.
pub fn generate_passphrase(words: usize) -> Result<String, XError> {
    passphrase::generate(words)
}

/// Deterministic helper for checked-in interoperability fixtures.
///
/// Only compiled with `--features fixtures`; never part of release builds.
#[cfg(feature = "fixtures")]
#[doc(hidden)]
pub fn seal_fixture(
    plaintext: &[u8],
    passphrase: &[u8],
    profile: Profile,
    salt: [u8; SALT_LEN],
    nonce: [u8; NONCE_LEN],
) -> Result<String, XError> {
    seal_with_material(plaintext, passphrase, profile, salt, nonce)
}

/// Exposed for the fuzz target; parsing never allocates based on untrusted
/// lengths beyond the hard encoded-size cap.
pub fn validate_payload(payload: &str) -> bool {
    format::decode(payload).is_ok()
}
