#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/core"
cargo build --release --locked
printf 'core: %s\n' "$ROOT/core/target/release/libx_core.so"
