//! Minimal C ABI for Flutter's `dart:ffi`.
//!
//! Ciphertext-producing and metadata functions return a JSON string that must
//! be released with `x_free_string`.
//!
//! Decryption **never** serializes plaintext. `x_decrypt` writes the
//! authenticated bytes into a caller-owned buffer and returns a numeric status.
//! The caller must overwrite that buffer before releasing it.

#[cfg(test)]
use std::ffi::CStr;
use std::ffi::{c_char, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::ptr;

use serde::Serialize;

use crate::format;
use crate::limits::{Profile, MAX_ENCODED, MAX_PASSPHRASE, MAX_PLAINTEXT};
use crate::{decrypt, encrypt, generate_passphrase, inspect, XError, VERSION};

const MAX_PAYLOAD_BYTES: usize = MAX_ENCODED + 16;

#[derive(Serialize)]
struct OkResponse<'a> {
    ok: bool,
    value: &'a str,
}

#[derive(Serialize)]
struct ErrResponse {
    ok: bool,
    code: &'static str,
    message: String,
}

fn reply(result: Result<String, XError>) -> *mut c_char {
    let json = match result {
        Ok(value) => serde_json::to_string(&OkResponse {
            ok: true,
            value: &value,
        }),
        Err(err) => serde_json::to_string(&ErrResponse {
            ok: false,
            code: err.code(),
            message: err.message(),
        }),
    };
    match json {
        Ok(json) => match CString::new(json) {
            Ok(c) => c.into_raw(),
            Err(_) => ptr::null_mut(),
        },
        Err(_) => ptr::null_mut(),
    }
}

fn internal_error() -> *mut c_char {
    reply(Err(XError::Internal))
}

/// Read a borrowed input slice with explicit length validation.
unsafe fn input<'a>(pointer: *const u8, length: usize, max: usize) -> Result<&'a [u8], XError> {
    if length > max {
        return Err(XError::PayloadTooLarge);
    }
    if length == 0 {
        return Ok(&[]);
    }
    if pointer.is_null() {
        return Err(XError::InvalidFormat("null input"));
    }
    Ok(std::slice::from_raw_parts(pointer, length))
}

fn payload_str<'a>(pointer: *const u8, length: usize) -> Result<&'a str, XError> {
    let bytes = unsafe { input(pointer, length, MAX_PAYLOAD_BYTES)? };
    std::str::from_utf8(bytes).map_err(|_| XError::InvalidFormat("payload is not UTF-8"))
}

fn profile_from_id(id: u32) -> Result<Profile, XError> {
    match id {
        1 => Ok(Profile::Standard),
        2 => Ok(Profile::High),
        _ => Err(XError::InvalidFormat("unknown performance profile")),
    }
}

/// Stable numeric error codes for the plaintext buffer API.
fn error_code(error: &XError) -> i32 {
    match error {
        XError::InvalidFormat(_) => 1,
        XError::UnsupportedVersion(_) => 2,
        XError::UnsupportedAlgorithm(_) => 3,
        XError::UnsupportedKdf(_) => 4,
        XError::InvalidKdfParameters => 5,
        XError::PayloadTooLarge => 6,
        XError::MessageTooLarge => 7,
        XError::PassphraseTooShort => 8,
        XError::PassphraseTooLong => 9,
        XError::AuthenticationFailed => 10,
        XError::NonUtf8 => 11,
        XError::CryptoFailure => 12,
        XError::Internal => 99,
    }
}

/// Encrypt UTF-8 bytes. Returns the `X1.…` payload.
///
/// # Safety
/// `plaintext` and `passphrase` must point to readable buffers of the given
/// lengths, or be null when the length is zero. The returned pointer must be
/// released with [`x_free_string`].
#[no_mangle]
pub unsafe extern "C" fn x_encrypt(
    plaintext: *const u8,
    plaintext_len: usize,
    passphrase: *const u8,
    passphrase_len: usize,
    profile_id: u32,
) -> *mut c_char {
    match catch_unwind(AssertUnwindSafe(|| {
        if plaintext_len > MAX_PLAINTEXT {
            return Err(XError::MessageTooLarge);
        }
        if passphrase_len > MAX_PASSPHRASE {
            return Err(XError::PassphraseTooLong);
        }
        let msg = unsafe { input(plaintext, plaintext_len, MAX_PLAINTEXT)? };
        let pass = unsafe { input(passphrase, passphrase_len, MAX_PASSPHRASE)? };
        let profile = profile_from_id(profile_id)?;
        encrypt(msg, pass, profile)
    })) {
        Ok(result) => reply(result),
        Err(_) => internal_error(),
    }
}

/// Decrypt a payload into a caller-owned buffer.
///
/// Returns `0` on success, otherwise one of the stable numeric error codes.
/// Plaintext is never placed in JSON or a C string.
///
/// # Safety
/// All pointers must be valid for the given lengths. `out` must point to at
/// least `out_capacity` writable bytes, and `out_len` must be writable. The
/// caller owns and must zeroize the output buffer.
#[no_mangle]
pub unsafe extern "C" fn x_decrypt(
    payload: *const u8,
    payload_len: usize,
    passphrase: *const u8,
    passphrase_len: usize,
    out: *mut u8,
    out_capacity: usize,
    out_len: *mut usize,
) -> i32 {
    match catch_unwind(AssertUnwindSafe(|| -> Result<usize, XError> {
        if out_len.is_null() {
            return Err(XError::InvalidFormat("null output length"));
        }
        if out.is_null() {
            return Err(XError::InvalidFormat("null output buffer"));
        }
        if passphrase_len > MAX_PASSPHRASE {
            return Err(XError::PassphraseTooLong);
        }
        let payload = payload_str(payload, payload_len)?;
        let pass = unsafe { input(passphrase, passphrase_len, MAX_PASSPHRASE)? };
        let plaintext = decrypt(payload, pass)?;
        if plaintext.len() > out_capacity {
            return Err(XError::MessageTooLarge);
        }
        unsafe {
            std::ptr::copy_nonoverlapping(plaintext.as_ptr(), out, plaintext.len());
            std::ptr::write(out_len, plaintext.len());
        }
        Ok(plaintext.len())
    })) {
        Ok(Ok(length)) => {
            let _ = length;
            0
        }
        Ok(Err(error)) => error_code(&error),
        Err(_) => 99,
    }
}

/// Validate format and return public metadata as a JSON string value.
///
/// # Safety
/// `payload` must point to a readable buffer of `payload_len` bytes. The
/// returned pointer must be released with [`x_free_string`].
#[no_mangle]
pub unsafe extern "C" fn x_inspect(payload: *const u8, payload_len: usize) -> *mut c_char {
    match catch_unwind(AssertUnwindSafe(|| {
        let payload = payload_str(payload, payload_len)?;
        let info = inspect(payload)?;
        let value = serde_json::json!({
            "version": info.version,
            "aead": info.aead,
            "kdf": info.kdf,
            "opslimit": info.opslimit,
            "memlimit": info.memlimit,
            "ciphertext_len": info.ciphertext_len,
            "profile": info.profile.map(|p| p.id()),
        });
        serde_json::to_string(&value).map_err(|_| XError::Internal)
    })) {
        Ok(result) => reply(result),
        Err(_) => internal_error(),
    }
}

/// Generate a passphrase with the bundled EFF wordlist.
#[no_mangle]
pub extern "C" fn x_generate_passphrase(words: u32) -> *mut c_char {
    match catch_unwind(AssertUnwindSafe(|| generate_passphrase(words as usize))) {
        Ok(result) => reply(result),
        Err(_) => internal_error(),
    }
}

/// Static version string. Do not free.
#[no_mangle]
pub extern "C" fn x_core_version() -> *const c_char {
    concat!(env!("CARGO_PKG_VERSION"), "\0").as_ptr() as *const c_char
}

/// Free a string returned by this module.
///
/// # Safety
/// `pointer` must be null or a pointer previously returned by this module and
/// not already freed.
#[no_mangle]
pub unsafe extern "C" fn x_free_string(pointer: *mut c_char) {
    if pointer.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(pointer));
    }
}

/// Convenience for tests: read a returned C string.
#[cfg(test)]
#[allow(clippy::not_unsafe_ptr_arg_deref)]
pub fn take_string(pointer: *mut c_char) -> String {
    assert!(!pointer.is_null());
    let value = unsafe { CStr::from_ptr(pointer) }
        .to_string_lossy()
        .into_owned();
    unsafe { x_free_string(pointer) };
    value
}

pub fn _version_is_exported() -> bool {
    VERSION == env!("CARGO_PKG_VERSION")
}

// Keep `format` referenced in documentation builds.
#[allow(dead_code)]
fn _format_version() -> u8 {
    format::VERSION
}
