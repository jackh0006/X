use std::collections::HashSet;
use std::sync::{Mutex, MutexGuard};

use base64::Engine as _;
use proptest::prelude::*;

use crate::crypto;
use crate::format::{self, Header};
use crate::limits::*;
use crate::*;

const TEST_PASS: &[u8] = b"correct horse battery staple";

/// Serialize KDF-heavy tests so parallel test threads do not multiply memory.
static KDF_LOCK: Mutex<()> = Mutex::new(());

fn kdf_guard() -> MutexGuard<'static, ()> {
    KDF_LOCK.lock().unwrap_or_else(|e| e.into_inner())
}

fn synthetic(header: &Header) -> String {
    format::encode(header, &[0u8; TAG_LEN])
}

#[test]
fn aead_matches_rustcrypto_xchacha20poly1305() {
    use chacha20poly1305::aead::{Aead, Payload};
    use chacha20poly1305::{KeyInit, XChaCha20Poly1305, XNonce};

    let key = [0x42u8; 32];
    let nonce = [0x24u8; NONCE_LEN];
    let aad = b"XMSG authenticated header";
    let plaintext = b"The quick brown fox jumps over the lazy dog.";

    let ours = crypto::seal_with_key(plaintext, aad, &nonce, &key);

    let cipher = XChaCha20Poly1305::new(chacha20poly1305::Key::from_slice(&key));
    let theirs = cipher
        .encrypt(
            XNonce::from_slice(&nonce),
            Payload {
                msg: plaintext,
                aad,
            },
        )
        .unwrap();

    assert_eq!(ours, theirs, "libsodium and RustCrypto must agree");
}

#[test]
fn kdf_matches_independent_argon2id_implementation() {
    use argon2::{Algorithm, Argon2, Params, Version};

    let _guard = kdf_guard();
    let salt = [0x11u8; SALT_LEN];
    let ops = 2u32;
    let mem = 64u32 * 1024 * 1024;

    let key = crypto::derive_key(TEST_PASS, &salt, ops, mem).unwrap();

    let params = Params::new(mem / 1024, ops, 1, Some(32)).unwrap();
    let argon = Argon2::new(Algorithm::Argon2id, Version::V0x13, params);
    let mut expected = [0u8; 32];
    argon
        .hash_password_into(TEST_PASS, &salt, &mut expected)
        .unwrap();

    assert_eq!(key.as_bytes(), expected);
}

#[test]
fn roundtrip_unicode_and_multilingual() {
    let _guard = kdf_guard();
    let message = "Hello — 你好 — مرحبا — Привет — こんにちは — 🔐🟠";
    let payload = encrypt(message.as_bytes(), TEST_PASS, Profile::Standard).unwrap();
    assert!(payload.starts_with("X1."));
    let out = decrypt(&payload, TEST_PASS).unwrap();
    assert_eq!(&out[..], message.as_bytes());
}

#[test]
fn roundtrip_empty_message() {
    let _guard = kdf_guard();
    let payload = encrypt(b"", TEST_PASS, Profile::Standard).unwrap();
    let out = decrypt(&payload, TEST_PASS).unwrap();
    assert!(out.is_empty());
}

#[test]
fn roundtrip_binary_edge_cases() {
    let _guard = kdf_guard();
    let message: Vec<u8> = (0u16..=255)
        .map(|v| v as u8)
        .chain([0, 255, 0, 128])
        .collect();
    let payload = encrypt(&message, TEST_PASS, Profile::Standard).unwrap();
    let out = decrypt(&payload, TEST_PASS).unwrap();
    assert_eq!(&out[..], message.as_slice());
}

#[test]
fn roundtrip_maximum_message_size() {
    let _guard = kdf_guard();
    let message = vec![b'x'; MAX_PLAINTEXT];
    let payload = encrypt(&message, TEST_PASS, Profile::Standard).unwrap();
    let out = decrypt(&payload, TEST_PASS).unwrap();
    assert_eq!(out.len(), MAX_PLAINTEXT);
    assert_eq!(&out[..], message.as_slice());
}

#[test]
fn rejects_oversized_message_before_kdf() {
    let message = vec![0u8; MAX_PLAINTEXT + 1];
    assert_eq!(
        encrypt(&message, TEST_PASS, Profile::Standard),
        Err(XError::MessageTooLarge)
    );
}

#[test]
fn wrong_passphrase_is_rejected() {
    let _guard = kdf_guard();
    let payload = encrypt(b"secret text", TEST_PASS, Profile::Standard).unwrap();
    assert_eq!(
        decrypt(&payload, b"wrong passphrase"),
        Err(XError::AuthenticationFailed)
    );
}

#[test]
fn modified_ciphertext_is_rejected() {
    let _guard = kdf_guard();
    let payload = encrypt(b"secret text", TEST_PASS, Profile::Standard).unwrap();
    let mut decoded = format::decode(&payload).unwrap();
    decoded.ciphertext[0] ^= 1;
    let tampered = format::encode(&decoded.header, &decoded.ciphertext);
    assert_eq!(
        decrypt(&tampered, TEST_PASS),
        Err(XError::AuthenticationFailed)
    );
}

#[test]
fn modified_authenticated_header_is_rejected() {
    let _guard = kdf_guard();
    let payload = encrypt(b"secret text", TEST_PASS, Profile::Standard).unwrap();
    let decoded = format::decode(&payload).unwrap();

    // Salt, nonce, opslimit and memlimit all parse successfully but must fail
    // authentication because they are covered by the AAD.
    for index in [15usize, 31, 10, 14] {
        let mut header_bytes = decoded.header_bytes;
        header_bytes[index] ^= 1;
        // These positions stay within the accepted KDF bounds, so they must be
        // stopped by authentication rather than by the parameter validator.
        let header = Header::parse(&header_bytes).expect("header remains structurally valid");
        let tampered = format::encode(&header, &decoded.ciphertext);
        assert_eq!(
            decrypt(&tampered, TEST_PASS),
            Err(XError::AuthenticationFailed),
            "header byte {index} was not authenticated"
        );
    }
}

#[test]
fn unsupported_header_fields_are_rejected() {
    let header = Header::new(Profile::Standard, [1u8; SALT_LEN], [2u8; NONCE_LEN]);

    let mut h = header.to_bytes();
    h[4] = 99;
    let mut bytes = h.to_vec();
    bytes.extend_from_slice(&[0u8; 16]);
    let b64 = base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(bytes);
    assert_eq!(
        format::decode(&format!("X1.{b64}")),
        Err(XError::UnsupportedVersion(99))
    );

    let mut h = header.to_bytes();
    h[5] = 99;
    // Header::parse rejects before encode, so test decode path directly.
    let raw = format::encode(&header, &[0u8; 16]);
    let mut decoded = format::decode(&raw).unwrap();
    decoded.header_bytes = h;
    let mut bytes = decoded.header_bytes.to_vec();
    bytes.extend_from_slice(&[0u8; 16]);
    let b64 = base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(bytes);
    assert_eq!(
        format::decode(&format!("X1.{b64}")),
        Err(XError::UnsupportedAlgorithm(99))
    );

    let mut h = header.to_bytes();
    h[6] = 99;
    let mut bytes = h.to_vec();
    bytes.extend_from_slice(&[0u8; 16]);
    let b64 = base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(bytes);
    assert_eq!(
        format::decode(&format!("X1.{b64}")),
        Err(XError::UnsupportedKdf(99))
    );
}

#[test]
fn invalid_format_variants_are_rejected() {
    let header = Header::new(Profile::Standard, [3u8; SALT_LEN], [4u8; NONCE_LEN]);
    let good = synthetic(&header);

    assert!(format::decode("").is_err());
    assert!(format::decode("X1.").is_err());
    assert!(format::decode("X2.abc").is_err());
    assert!(format::decode(&good.replace("X1.", "x1.")).is_err());
    assert!(format::decode(&format!("{}=", good)).is_err());
    assert!(format::decode(&format!("{} ", good)).is_ok()); // outer whitespace is tolerated

    let decoded = format::decode(&good).unwrap();
    let mut body = decoded.header_bytes.to_vec();
    body.extend_from_slice(&decoded.ciphertext);
    for cut in [0usize, 4, format::HEADER_LEN, format::HEADER_LEN + 8] {
        let b64 = base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(&body[..cut]);
        assert!(format::decode(&format!("X1.{b64}")).is_err(), "cut {cut}");
    }

    let mut interior = good.clone();
    interior.insert(10, '\n');
    assert!(format::decode(&interior).is_err());
}

#[test]
fn invalid_kdf_bounds_are_rejected() {
    let header = Header::new(Profile::Standard, [0u8; SALT_LEN], [0u8; NONCE_LEN]);
    for (ops, mem) in [
        (1u32, header.memlimit),
        (MAX_OPSLIMIT + 1, header.memlimit),
        (header.opslimit, MIN_MEMLIMIT - 1),
        (header.opslimit, MAX_MEMLIMIT + 1),
    ] {
        let mut h = header.to_bytes();
        h[7..11].copy_from_slice(&ops.to_be_bytes());
        h[11..15].copy_from_slice(&mem.to_be_bytes());
        let mut bytes = h.to_vec();
        bytes.extend_from_slice(&[0u8; 16]);
        let b64 = base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(bytes);
        assert_eq!(
            format::decode(&format!("X1.{b64}")),
            Err(XError::InvalidKdfParameters),
            "ops={ops} mem={mem}"
        );
    }
}

#[test]
fn oversized_encoded_payload_is_rejected() {
    let payload = format!("X1.{}", "A".repeat(MAX_ENCODED + 1));
    assert_eq!(format::decode(&payload), Err(XError::PayloadTooLarge));
}

#[test]
fn metadata_is_reported_without_passphrase() {
    let header = Header::new(Profile::High, [9u8; SALT_LEN], [8u8; NONCE_LEN]);
    let payload = synthetic(&header);
    let info = inspect(&payload).unwrap();
    assert_eq!(info.version, 1);
    assert_eq!(info.aead, 1);
    assert_eq!(info.kdf, 1);
    assert_eq!(info.opslimit, Profile::High.opslimit());
    assert_eq!(info.memlimit, Profile::High.memlimit());
    assert_eq!(info.profile, Some(Profile::High));
    assert_eq!(info.ciphertext_len, TAG_LEN);
}

#[test]
fn salt_and_nonce_are_unique() {
    let mut salts = HashSet::new();
    let mut nonces = HashSet::new();
    for _ in 0..4096 {
        let (salt, nonce) = crypto::random_material();
        assert!(salts.insert(salt));
        assert!(nonces.insert(nonce));
    }
}

#[test]
fn unicode_normalization_is_exact() {
    let _guard = kdf_guard();
    // NFC and NFD render similarly but are different byte sequences. X does
    // not silently normalize because a changed phrase must never be accepted.
    let nfc = "café-au-lait-passphrase";
    let nfd = "cafe\u{301}-au-lait-passphrase";
    assert_ne!(nfc.as_bytes(), nfd.as_bytes());
    let payload = encrypt(b"normalization test", nfc.as_bytes(), Profile::Standard).unwrap();
    assert_eq!(
        decrypt(&payload, nfd.as_bytes()),
        Err(XError::AuthenticationFailed)
    );
    assert_eq!(
        &decrypt(&payload, nfc.as_bytes()).unwrap()[..],
        b"normalization test"
    );
}

#[test]
fn maximum_passphrase_length_roundtrip() {
    let _guard = kdf_guard();
    let passphrase = vec![b'Z'; MAX_PASSPHRASE];
    let payload = encrypt(b"long phrase", &passphrase, Profile::Standard).unwrap();
    assert_eq!(&decrypt(&payload, &passphrase).unwrap()[..], b"long phrase");
}

#[test]
fn ffi_rejects_null_and_oversized_inputs_without_leaking() {
    let message = b"never leak this plaintext";
    let pass = b"correct horse battery staple";
    let result = unsafe {
        ffi::x_encrypt(
            message.as_ptr(),
            MAX_PLAINTEXT + 1,
            pass.as_ptr(),
            pass.len(),
            1,
        )
    };
    let value: serde_json::Value = serde_json::from_str(&ffi::take_string(result)).unwrap();
    assert_eq!(value["code"], "MESSAGE_TOO_LARGE");

    let result = unsafe { ffi::x_decrypt(std::ptr::null(), 1, pass.as_ptr(), pass.len()) };
    let json = ffi::take_string(result);
    let value: serde_json::Value = serde_json::from_str(&json).unwrap();
    assert_eq!(value["code"], "INVALID_FORMAT");
    assert!(!json.contains("never leak this plaintext"));
    assert!(!json.contains("correct horse"));

    unsafe { ffi::x_free_string(std::ptr::null_mut()) };
}

#[test]
fn passphrase_length_limits() {
    assert_eq!(
        encrypt(b"x", b"short", Profile::Standard),
        Err(XError::PassphraseTooShort)
    );
    let long = vec![b'a'; MAX_PASSPHRASE + 1];
    assert_eq!(
        encrypt(b"x", &long, Profile::Standard),
        Err(XError::PassphraseTooLong)
    );
}

#[test]
fn passphrase_generation_is_strong_and_offline() {
    let p = generate_passphrase(7).unwrap();
    assert_eq!(p.split('-').count(), 7);
    assert!(p.len() > 20);
    assert!(entropy_bits(7) >= 90);
}

#[test]
fn ffi_roundtrip_and_error_shape() {
    let _guard = kdf_guard();
    let message = "ffi 你好 🔐";
    let pass = b"ffi test passphrase";
    let ptr = unsafe {
        ffi::x_encrypt(
            message.as_ptr(),
            message.len(),
            pass.as_ptr(),
            pass.len(),
            1,
        )
    };
    let json = ffi::take_string(ptr);
    let value: serde_json::Value = serde_json::from_str(&json).unwrap();
    assert_eq!(value["ok"], true);
    let payload = value["value"].as_str().unwrap().to_string();

    let ptr = unsafe { ffi::x_decrypt(payload.as_ptr(), payload.len(), pass.as_ptr(), pass.len()) };
    let json = ffi::take_string(ptr);
    let value: serde_json::Value = serde_json::from_str(&json).unwrap();
    assert_eq!(value["ok"], true);
    assert_eq!(value["value"], message);

    let bad = "not a payload";
    let ptr = unsafe { ffi::x_decrypt(bad.as_ptr(), bad.len(), pass.as_ptr(), pass.len()) };
    let json = ffi::take_string(ptr);
    let value: serde_json::Value = serde_json::from_str(&json).unwrap();
    assert_eq!(value["ok"], false);
    assert_eq!(value["code"], "INVALID_FORMAT");
    assert!(!value.to_string().contains(message));

    assert!(ffi::_version_is_exported());
}

proptest! {
    #![proptest_config(ProptestConfig::with_cases(256))]

    #[test]
    fn format_encode_decode_roundtrip(
        salt in proptest::array::uniform16(any::<u8>()),
        nonce in proptest::array::uniform24(any::<u8>()),
        ciphertext in proptest::collection::vec(any::<u8>(), 16..2048),
    ) {
        let header = Header::new(Profile::Standard, salt, nonce);
        let payload = format::encode(&header, &ciphertext);
        let decoded = format::decode(&payload).unwrap();
        prop_assert_eq!(decoded.header, header);
        prop_assert_eq!(decoded.ciphertext, ciphertext);
    }

    #[test]
    fn parser_never_panics_on_garbage(text in ".{0,300}") {
        let _ = inspect(&text);
    }
}
