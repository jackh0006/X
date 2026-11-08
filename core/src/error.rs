use std::fmt;

/// Stable error type returned by the core. Codes are part of the FFI contract.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum XError {
    InvalidFormat(&'static str),
    UnsupportedVersion(u8),
    UnsupportedAlgorithm(u8),
    UnsupportedKdf(u8),
    InvalidKdfParameters,
    PayloadTooLarge,
    MessageTooLarge,
    PassphraseTooShort,
    PassphraseTooLong,
    AuthenticationFailed,
    NonUtf8,
    CryptoFailure,
    Internal,
}

impl XError {
    pub const fn code(&self) -> &'static str {
        match self {
            XError::InvalidFormat(_) => "INVALID_FORMAT",
            XError::UnsupportedVersion(_) => "UNSUPPORTED_VERSION",
            XError::UnsupportedAlgorithm(_) => "UNSUPPORTED_ALGORITHM",
            XError::UnsupportedKdf(_) => "UNSUPPORTED_KDF",
            XError::InvalidKdfParameters => "INVALID_KDF_PARAMETERS",
            XError::PayloadTooLarge => "PAYLOAD_TOO_LARGE",
            XError::MessageTooLarge => "MESSAGE_TOO_LARGE",
            XError::PassphraseTooShort => "PASSPHRASE_TOO_SHORT",
            XError::PassphraseTooLong => "PASSPHRASE_TOO_LONG",
            XError::AuthenticationFailed => "AUTHENTICATION_FAILED",
            XError::NonUtf8 => "NON_UTF8",
            XError::CryptoFailure => "CRYPTO_FAILURE",
            XError::Internal => "INTERNAL",
        }
    }

    pub fn message(&self) -> String {
        match self {
            XError::InvalidFormat(detail) => format!("Invalid encrypted text: {detail}."),
            XError::UnsupportedVersion(v) => {
                format!("Unsupported encrypted-text version ({v}). Update X and try again.")
            }
            XError::UnsupportedAlgorithm(a) => {
                format!("Unsupported encryption algorithm ({a}). Update X and try again.")
            }
            XError::UnsupportedKdf(k) => {
                format!("Unsupported key-derivation method ({k}). Update X and try again.")
            }
            XError::InvalidKdfParameters => {
                "The encrypted text contains unsafe or unsupported KDF parameters.".to_string()
            }
            XError::PayloadTooLarge => {
                "The encrypted text is too large (limit 96 KiB).".to_string()
            }
            XError::MessageTooLarge => "The message is too large (limit 64 KiB).".to_string(),
            XError::PassphraseTooShort => {
                "The passphrase must be at least 8 characters.".to_string()
            }
            XError::PassphraseTooLong => {
                "The passphrase must be at most 1024 characters.".to_string()
            }
            XError::AuthenticationFailed => {
                "Wrong passphrase, or the encrypted text was modified or corrupted.".to_string()
            }
            XError::NonUtf8 => "The decrypted data is not valid UTF-8 text.".to_string(),
            XError::CryptoFailure => "A cryptographic operation failed safely.".to_string(),
            XError::Internal => "An internal error occurred.".to_string(),
        }
    }
}

impl fmt::Display for XError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.message())
    }
}

impl std::error::Error for XError {}
