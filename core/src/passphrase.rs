//! Offline Diceware-style passphrase generation using libsodium's CSPRNG.

use libsodium_rs::random;

use crate::error::XError;

const WORDS: &str = include_str!("../assets/eff_large_wordlist.txt");
pub const WORD_COUNT: usize = 7776;
pub const DEFAULT_WORDS: usize = 7;
pub const MIN_WORDS: usize = 4;
pub const MAX_WORDS: usize = 12;

fn wordlist() -> Vec<&'static str> {
    WORDS
        .lines()
        .map(str::trim)
        .filter(|w| !w.is_empty())
        .collect()
}

/// Uniform random index in `0..WORD_COUNT` without modulo bias.
fn uniform_index() -> usize {
    let mut buf = [0u8; 4];
    loop {
        random::fill_bytes(&mut buf);
        let value = u32::from_le_bytes(buf) as u64;
        let limit = (u64::from(u32::MAX) + 1) / WORD_COUNT as u64 * WORD_COUNT as u64;
        if value < limit {
            return (value % WORD_COUNT as u64) as usize;
        }
    }
}

pub fn generate(words: usize) -> Result<String, XError> {
    if !(MIN_WORDS..=MAX_WORDS).contains(&words) {
        return Err(XError::InvalidFormat("unsupported passphrase word count"));
    }
    let list = wordlist();
    if list.len() != WORD_COUNT {
        return Err(XError::Internal);
    }
    let mut chosen = Vec::with_capacity(words);
    for _ in 0..words {
        chosen.push(list[uniform_index()]);
    }
    Ok(chosen.join("-"))
}

/// Entropy of a generated passphrase, rounded down to whole bits.
pub const fn entropy_bits(words: usize) -> u32 {
    // log2(7776) = 12.9248...
    (words as u32 * 1292) / 100
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generated_passphrases_have_expected_shape() {
        for words in [4, 7, 12] {
            let p = generate(words).unwrap();
            assert_eq!(p.split('-').count(), words);
            assert!(p.len() >= words * 2);
        }
    }

    #[test]
    fn generated_passphrases_are_unique() {
        let mut seen = std::collections::HashSet::new();
        for _ in 0..64 {
            assert!(seen.insert(generate(DEFAULT_WORDS).unwrap()));
        }
    }

    #[test]
    fn rejects_unsupported_word_counts() {
        assert!(generate(3).is_err());
        assert!(generate(13).is_err());
    }

    #[test]
    fn entropy_is_about_90_bits_for_seven_words() {
        assert_eq!(entropy_bits(7), 90);
    }
}
