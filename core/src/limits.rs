//! Hard limits and the two supported KDF profiles.
//!
//! The limits are part of the security boundary: they are validated before any
//! memory is allocated by the KDF, and they are repeated in the authenticated
//! header so a payload cannot silently request weaker parameters.

/// Maximum plaintext size in bytes (64 KiB).
pub const MAX_PLAINTEXT: usize = 64 * 1024;
/// Maximum accepted Base64URL body length in characters.
pub const MAX_ENCODED: usize = 96 * 1024;
/// Maximum passphrase length in bytes.
pub const MAX_PASSPHRASE: usize = 1024;
/// Minimum passphrase length in bytes.
///
/// This is a floor, not a strength guarantee. The UI warns below 12 characters
/// and offers a 7-word generator (~90 bits).
pub const MIN_PASSPHRASE: usize = 8;

pub const MIN_OPSLIMIT: u32 = 2;
pub const MAX_OPSLIMIT: u32 = 10;
pub const MIN_MEMLIMIT: u32 = 64 * 1024 * 1024; // 64 MiB
pub const MAX_MEMLIMIT: u32 = 256 * 1024 * 1024; // 256 MiB
pub const SALT_LEN: usize = 16;
pub const NONCE_LEN: usize = 24;
pub const TAG_LEN: usize = 16;

/// KDF performance/security profiles available in the interface.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Profile {
    /// 128 MiB, 3 passes. Default; chosen for desktop and mid-range phones.
    Standard,
    /// 256 MiB, 4 passes. Higher cost; may be slow on low-memory phones.
    High,
}

impl Profile {
    pub const fn opslimit(self) -> u32 {
        match self {
            Profile::Standard => 3,
            Profile::High => 4,
        }
    }

    pub const fn memlimit(self) -> u32 {
        match self {
            Profile::Standard => 128 * 1024 * 1024,
            Profile::High => 256 * 1024 * 1024,
        }
    }

    pub const fn id(self) -> u8 {
        match self {
            Profile::Standard => 1,
            Profile::High => 2,
        }
    }

    pub const fn from_id(id: u8) -> Option<Self> {
        match id {
            1 => Some(Profile::Standard),
            2 => Some(Profile::High),
            _ => None,
        }
    }

    pub const fn label(self) -> &'static str {
        match self {
            Profile::Standard => "Standard",
            Profile::High => "High",
        }
    }
}

/// Validate KDF parameters received from an untrusted payload.
pub fn validate_kdf_params(opslimit: u32, memlimit: u32) -> bool {
    (MIN_OPSLIMIT..=MAX_OPSLIMIT).contains(&opslimit)
        && (MIN_MEMLIMIT..=MAX_MEMLIMIT).contains(&memlimit)
}

/// A human-readable hint for the profile matching these exact parameters.
pub fn profile_hint(opslimit: u32, memlimit: u32) -> Option<Profile> {
    [Profile::Standard, Profile::High]
        .into_iter()
        .find(|p| p.opslimit() == opslimit && p.memlimit() == memlimit)
}
