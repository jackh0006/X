//! Thin, audited wrappers around libsodium. No primitive is implemented here.

use libsodium_rs::crypto_aead::xchacha20poly1305::{self as aead, Key, Nonce};
use libsodium_rs::{crypto_pwhash, random};
use zeroize::Zeroizing;

use crate::error::XError;
use crate::limits::{NONCE_LEN, SALT_LEN};

pub const KEY_LEN: usize = 32;

pub fn random_material() -> ([u8; SALT_LEN], [u8; NONCE_LEN]) {
    let mut salt = [0u8; SALT_LEN];
    let mut nonce = [0u8; NONCE_LEN];
    random::fill_bytes(&mut salt);
    random::fill_bytes(&mut nonce);
    (salt, nonce)
}

/// Derive a 32-byte key with Argon2id v1.3.
pub fn derive_key(
    passphrase: &[u8],
    salt: &[u8; SALT_LEN],
    opslimit: u32,
    memlimit: u32,
) -> Result<Key, XError> {
    if !crate::limits::validate_kdf_params(opslimit, memlimit) {
        return Err(XError::InvalidKdfParameters);
    }
    let key_bytes = Zeroizing::new(
        crypto_pwhash::pwhash(
            KEY_LEN,
            passphrase,
            salt,
            u64::from(opslimit),
            memlimit as usize,
            crypto_pwhash::ALG_ARGON2ID13,
        )
        .map_err(|_| XError::CryptoFailure)?,
    );
    Key::from_bytes(key_bytes.as_slice()).map_err(|_| XError::CryptoFailure)
}

pub fn seal(
    plaintext: &[u8],
    header_bytes: &[u8],
    nonce_bytes: &[u8; NONCE_LEN],
    key: &Key,
) -> Result<Vec<u8>, XError> {
    let nonce = Nonce::from_bytes(*nonce_bytes);
    aead::encrypt(plaintext, Some(header_bytes), &nonce, key).map_err(|_| XError::CryptoFailure)
}

pub fn open(
    ciphertext: &[u8],
    header_bytes: &[u8],
    nonce_bytes: &[u8; NONCE_LEN],
    key: &Key,
) -> Result<Zeroizing<Vec<u8>>, XError> {
    let nonce = Nonce::from_bytes(*nonce_bytes);
    // libsodium reports every authentication failure identically. We deliberately
    // collapse it into one public error so callers cannot use it as an oracle.
    aead::decrypt(ciphertext, Some(header_bytes), &nonce, key)
        .map(Zeroizing::new)
        .map_err(|_| XError::AuthenticationFailed)
}

/// Constant-shape helper used by tests to exercise the AEAD wrapper without KDF.
#[cfg(test)]
pub fn seal_with_key(
    plaintext: &[u8],
    aad: &[u8],
    nonce: &[u8; NONCE_LEN],
    key_bytes: &[u8; KEY_LEN],
) -> Vec<u8> {
    let key = Key::from_bytes(key_bytes).expect("key length");
    seal(plaintext, aad, nonce, &key).expect("seal")
}
