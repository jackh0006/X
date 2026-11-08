//! Reproducible local benchmark for the X core. Prints a Markdown table.
//!
//! Usage: cargo run --release --bin x-bench

use std::time::Instant;

use x_core::{decrypt, encrypt, generate_passphrase, Profile};

fn median(values: &mut [f64]) -> f64 {
    values.sort_by(|a, b| a.partial_cmp(b).unwrap());
    values[values.len() / 2]
}

fn one(profile: Profile, size: usize, repeat: usize) -> (f64, f64) {
    let message = vec![b'a'; size];
    let pass = b"benchmark-passphrase-2026";
    let mut enc = Vec::with_capacity(repeat);
    let mut dec = Vec::with_capacity(repeat);
    for _ in 0..repeat {
        let start = Instant::now();
        let payload = encrypt(&message, pass, profile).expect("encrypt");
        enc.push(start.elapsed().as_secs_f64() * 1000.0);
        let start = Instant::now();
        let out = decrypt(&payload, pass).expect("decrypt");
        assert_eq!(out.len(), size);
        dec.push(start.elapsed().as_secs_f64() * 1000.0);
    }
    (median(&mut enc), median(&mut dec))
}

fn main() {
    println!("| Profile | Message | Encrypt (ms) | Decrypt (ms) |");
    println!("|---|---:|---:|---:|");
    for profile in [Profile::Standard, Profile::High] {
        for (label, size) in [
            ("empty", 0usize),
            ("1 KiB", 1024),
            ("16 KiB", 16 * 1024),
            ("64 KiB", 64 * 1024),
        ] {
            let (enc, dec) = one(profile, size, 5);
            println!(
                "| {} | {} | {:.1} | {:.1} |",
                profile.label(),
                label,
                enc,
                dec
            );
        }
    }

    let start = Instant::now();
    for _ in 0..32 {
        let p = generate_passphrase(7).expect("generate");
        assert_eq!(p.split('-').count(), 7);
    }
    println!(
        "\nPassphrase generation (7 words): {:.3} ms/op",
        start.elapsed().as_secs_f64() * 1000.0 / 32.0
    );
}
