#!/usr/bin/env python3
"""Validate every donation address published in the X repository.

This is a format/checksum check, not proof of ownership. It exists so a typo
can never reach the Donate screen or README. XRP uses the XRPL base58 alphabet
and TON uses the CRC16/XMODEM checksum of the 34-byte user-friendly address.
"""
from __future__ import annotations

import base64
import hashlib
import re

BTC = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
XRP = "rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz"
BECH32 = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

ADDRESSES = {
    "BTC": "bc1q8t0fn2yrsy4lh3m0pz34uj27t8vxjeavkjym83",
    "ETH/BNB/USDT-EVM": "0xdad428900a4359be8f76b3062df34211582e09eb",
    "TRX/USDT-TRC20": "TMpb6RNTuGNM1eTakm9kjds1mRTPYYJesf",
    "SOL/USDT-SPL/USDC-SPL": "BDCCrRez1yD1RpkAtiqKKDk3BfxPD8P7nkL26jCYrzgL",
    "DOGE": "D6ZdMQ7mHGGmuH9prpZ2zjpnG5Q3WVRDtC",
    "XRP": "rNUAhaATFLvosdu9m9M95bupRBtZ8eqpj9",
    "TON": "UQCu6-3yGyQ5dzvcCxr2gobuvx5ddbS9EC690qtey92P5_wX",
    "LTC": "ltc1q2gs89cfy3mumr7gu9w0zl9rllf80q67m5rmma8",
}


def b58decode(value: str, alphabet: str, zero_char: str) -> bytes:
    number = 0
    for char in value:
        number = number * 58 + alphabet.index(char)
    raw = number.to_bytes((number.bit_length() + 7) // 8, "big") if number else b""
    return b"\0" * (len(value) - len(value.lstrip(zero_char))) + raw


def b58check(value: str, alphabet: str = BTC, zero_char: str = "1") -> bytes:
    raw = b58decode(value, alphabet, zero_char)
    expected = hashlib.sha256(hashlib.sha256(raw[:-4]).digest()).digest()[:4]
    if len(raw) != 25 or expected != raw[-4:]:
        raise ValueError("bad base58check")
    return raw


def bech32_polymod(values: list[int]) -> int:
    generators = [0x3B6A57B2, 0x26508E6D, 0x1EA119FA, 0x3D4233DD, 0x2A1462B3]
    checksum = 1
    for value in values:
        top = checksum >> 25
        checksum = ((checksum & 0x1FFFFFF) << 5) ^ value
        for index in range(5):
            checksum ^= generators[index] if ((top >> index) & 1) else 0
    return checksum


def bech32_ok(value: str) -> bool:
    position = value.rfind("1")
    hrp, body = value[:position], value[position + 1 :]
    data = [BECH32.index(char) for char in body]
    expanded = [ord(c) >> 5 for c in hrp] + [0] + [ord(c) & 31 for c in hrp]
    return bech32_polymod(expanded + data) == 1


def ton_ok(value: str) -> bool:
    raw = base64.urlsafe_b64decode(value + "=" * ((4 - len(value) % 4) % 4))
    if len(raw) != 36:
        return False
    crc = 0
    for byte in raw[:34]:
        crc ^= byte << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF if crc & 0x8000 else (crc << 1) & 0xFFFF
    return crc == int.from_bytes(raw[34:], "big")


def validate(network: str, address: str) -> bool:
    checks = {
        "BTC": lambda: bech32_ok(address) and address.startswith("bc1"),
        "LTC": lambda: bech32_ok(address) and address.startswith("ltc1"),
        "ETH/BNB/USDT-EVM": lambda: bool(re.fullmatch(r"0x[0-9a-fA-F]{40}", address)),
        "TRX/USDT-TRC20": lambda: b58check(address)[0] == 0x41,
        "DOGE": lambda: b58check(address)[0] == 0x1E,
        "XRP": lambda: b58check(address, XRP, "r")[0] == 0x00,
        "SOL/USDT-SPL/USDC-SPL": lambda: len(b58decode(address, BTC, "1")) == 32,
        "TON": lambda: ton_ok(address),
    }
    return checks[network]()


def main() -> int:
    failed = False
    for network, address in ADDRESSES.items():
        try:
            ok = validate(network, address)
        except Exception:
            ok = False
        print(f"{network:24} {'VALID' if ok else 'INVALID'}  {address}")
        failed |= not ok
    if failed:
        print("One or more donation addresses failed validation.", flush=True)
        return 1
    print("All donation addresses are format-valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
