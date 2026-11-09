# Performance benchmarks

## Environment

| Item | Value |
|---|---|
| CPU | Intel Pentium G2030, 2 cores, 3.0 GHz |
| RAM | 3.8 GiB |
| OS | Ubuntu 24.04.5 LTS, kernel 7.0.0-42-generic |
| Rust | 1.98.1, release profile |
| Flutter | 3.47.6, release build |
| libsodium | 1.0.22, vendored static |
| Display | X11/XWayland, 1232×919 window |

These are modest, older desktop numbers. Newer hardware and phones will be
faster; low-end phones can be slower than this desktop. Measure on your own
device before choosing the High profile.

## KDF + encryption end-to-end

Median of 5 runs per cell, measured by `cargo run --release --bin x-bench`.
Each operation includes Argon2id and the AEAD.

| Profile | Message | Encrypt (ms) | Decrypt (ms) |
|---|---:|---:|---:|
| Standard (128 MiB, 3) | empty | 456.8 | 467.1 |
| Standard | 1 KiB | 479.6 | 460.4 |
| Standard | 16 KiB | 478.1 | 467.9 |
| Standard | 64 KiB | 465.3 | 483.8 |
| High (256 MiB, 4) | empty | 1219.5 | 1275.1 |
| High | 1 KiB | 1220.9 | 1224.8 |
| High | 16 KiB | 1247.1 | 1220.7 |
| High | 64 KiB | 1254.7 | 1321.9 |

Passphrase generation: **0.315 ms/op** (7 words).

The KDF dominates. A 64 KiB message costs only a few milliseconds beyond the
empty-message case, so the 64 KiB limit does not encourage smaller messages for
performance reasons.

## Application

| Metric | Result | Method |
|---|---|---|
| Linux startup to window | **1.36 s** | launch → first X window, 50 ms polling |
| Linux max RSS | **~180 MiB** | `/usr/bin/time -v`, 8 s run |
| APK size | 52,099,218 bytes (49.7 MiB) | `stat` |
| DEB size | 8,708,994 bytes (8.3 MiB) | `stat` |
| Installed Linux bundle | 26 MiB | `du -sh` |
| DEB installed size (control) | 25,980 KiB | `dpkg-deb -I` |

Android startup/RAM and KDF timing on arm64-v8a hardware are **NOT TESTED** locally;
the cross-platform workflow records emulator results when run. Emulator numbers
are not a substitute for a physical phone.

## Reproduce

```bash
cd core
cargo run --release --bin x-bench

cd ../app
./../scripts/build-linux.sh
/usr/bin/time -v timeout 8 ./build/linux/x64/release/bundle/x
```

Startup time depends on the desktop compositor, font cache and storage. Report
your own hardware when comparing.
