#!/usr/bin/env python3
"""Generate a CycloneDX 1.5 SBOM from the two lockfiles.

This is deliberately a lockfile-derived inventory, not a claim of complete
transitive license analysis. It is regenerated for every release.
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def cargo_components() -> list[dict]:
    text = (ROOT / "core" / "Cargo.lock").read_text()
    components = []
    for block in text.split("[[package]]")[1:]:
        name = re.search(r'^name = "([^"]+)"', block, re.M)
        version = re.search(r'^version = "([^"]+)"', block, re.M)
        if not name or not version:
            continue
        components.append(
            {
                "type": "library",
                "name": name.group(1),
                "version": version.group(1),
                "purl": f"pkg:cargo/{name.group(1)}@{version.group(1)}",
                "scope": "required",
            }
        )
    return components


def pub_components() -> list[dict]:
    text = (ROOT / "app" / "pubspec.lock").read_text()
    components = []
    current = None
    for line in text.splitlines():
        if re.match(r"^  [A-Za-z0-9_]+:\s*$", line) and not line.startswith("    "):
            if current:
                components.append(current)
            current = {"type": "library", "name": line.strip().rstrip(":")}
        elif current and line.startswith("    version:"):
            version = line.split(":", 1)[1].strip().strip('"')
            current["version"] = version
            current["purl"] = f"pkg:pub/{current['name']}@{version}"
            current["scope"] = "required"
        elif current and line.startswith("    dependency:"):
            kind = line.split(":", 1)[1].strip()
            if kind == "direct main":
                current["scope"] = "required"
    if current:
        components.append(current)
    return [c for c in components if "version" in c]


def main() -> int:
    version = re.search(
        r"^version:\s*([^\s+]+)", (ROOT / "app" / "pubspec.yaml").read_text(), re.M
    )
    if not version:
        print("cannot read app version", file=sys.stderr)
        return 1
    components = sorted(
        cargo_components() + pub_components(),
        key=lambda c: (c["name"].lower(), c["version"]),
    )
    bom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "version": 1,
        "metadata": {
            "timestamp": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
            "tools": [{"vendor": "X", "name": "generate_sbom.py", "version": "1.0.0"}],
            "component": {
                "type": "application",
                "name": "X",
                "version": version.group(1),
                "purl": f"pkg:github/jackh0006/X@{version.group(1)}",
            },
        },
        "components": components,
    }
    out = ROOT / "dist" / f"x-{version.group(1)}.cdx.json"
    out.parent.mkdir(exist_ok=True)
    out.write_text(json.dumps(bom, indent=2) + "\n")
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
