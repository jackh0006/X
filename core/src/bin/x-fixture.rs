//! Deterministic fixture generator/decryptor for cross-platform interoperability
//! tests. Built only with `--features fixtures`.

use std::io::{self, Read, Write};

use x_core::{decrypt, limits::Profile, seal_fixture};

fn usage() -> ! {
    eprintln!(
        "usage:\n  x-fixture seal --pass PASSPHRASE --profile standard|high --salt HEX --nonce HEX < plaintext\n  x-fixture open --pass PASSPHRASE < payload"
    );
    std::process::exit(2);
}

fn arg(args: &[String], name: &str) -> String {
    args.iter()
        .position(|a| a == name)
        .and_then(|i| args.get(i + 1))
        .unwrap_or_else(|| usage())
        .clone()
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        usage();
    }
    let mut input = Vec::new();
    io::stdin().read_to_end(&mut input).expect("stdin");
    let pass = arg(&args, "--pass");

    match args[1].as_str() {
        "seal" => {
            let profile = match arg(&args, "--profile").as_str() {
                "standard" => Profile::Standard,
                "high" => Profile::High,
                _ => usage(),
            };
            let salt_hex = arg(&args, "--salt");
            let nonce_hex = arg(&args, "--nonce");
            let salt_vec = hex::decode(&salt_hex).unwrap_or_else(|_| usage());
            let nonce_vec = hex::decode(&nonce_hex).unwrap_or_else(|_| usage());
            let salt: [u8; 16] = salt_vec.try_into().unwrap_or_else(|_| usage());
            let nonce: [u8; 24] = nonce_vec.try_into().unwrap_or_else(|_| usage());
            let payload =
                seal_fixture(&input, pass.as_bytes(), profile, salt, nonce).expect("seal fixture");
            println!("{payload}");
        }
        "open" => {
            let payload = String::from_utf8(input).expect("payload utf8");
            let payload = payload.trim();
            let plaintext = decrypt(payload, pass.as_bytes()).expect("decrypt fixture");
            io::stdout().write_all(&plaintext).expect("stdout");
        }
        _ => usage(),
    }
}
