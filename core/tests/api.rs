use x_core::{decrypt, encrypt, generate_passphrase, inspect, Profile, XError};

const PASS: &[u8] = b"integration-passphrase-2026";

#[test]
fn public_api_roundtrip_and_inspect() {
    let payload = encrypt(
        "integration unicode 你好 🔐".as_bytes(),
        PASS,
        Profile::Standard,
    )
    .unwrap();
    let info = inspect(&payload).unwrap();
    assert_eq!(info.version, 1);
    assert_eq!(info.opslimit, 3);
    assert_eq!(info.memlimit, 128 * 1024 * 1024);
    assert_eq!(
        &decrypt(&payload, PASS).unwrap()[..],
        "integration unicode 你好 🔐".as_bytes()
    );
}

#[test]
fn public_api_rejects_wrong_phrase_without_plaintext() {
    let payload = encrypt(b"never released", PASS, Profile::Standard).unwrap();
    assert_eq!(
        decrypt(&payload, b"wrong phrase 2026"),
        Err(XError::AuthenticationFailed)
    );
}

#[test]
fn public_api_generates_distinct_phrases() {
    let a = generate_passphrase(7).unwrap();
    let b = generate_passphrase(7).unwrap();
    assert_eq!(a.split('-').count(), 7);
    assert_ne!(a, b);
}
