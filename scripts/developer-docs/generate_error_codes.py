"""Generate docs/developer-docs/error-codes.md from the official ONDC error codes list.

Source: ONDC-Official/developer-docs -> protocol-network-extension/error-codes.md

Usage:
    python3 scripts/developer-docs/generate_error_codes.py [--source <local error-codes.md>]

Without --source the official file is downloaded from GitHub.
"""
import argparse
import os
import re
import sys
import urllib.request

SOURCE_URL = (
    "https://raw.githubusercontent.com/ONDC-Official/developer-docs/main/"
    "protocol-network-extension/error-codes.md"
)
OUTPUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "..", "docs", "developer-docs", "error-codes.md"
)

# Section order and headings, keyed by the "Type" column of the official list
SENDERS = [
    ("Gateway", "Gateway", "Returned by the ONDC Gateway."),
    ("BNP", "Buyer App (BNP)", "Returned by a Buyer Network Participant (buyer app)."),
    ("SNP", "Seller App (SNP)", "Returned by a Seller Network Participant (seller app)."),
    ("LBNP", "Logistics Buyer (LBNP)", "Returned by a Logistics Buyer Network Participant."),
    ("LSP", "Logistics Provider (LSP)", "Returned by a Logistics Service Provider."),
]

ROW = re.compile(r"^\s*\|\s*(\d{5})\s*\|")


def load_source(path):
    if path:
        with open(path, encoding="utf-8") as f:
            return f.read()
    with urllib.request.urlopen(SOURCE_URL, timeout=30) as r:
        return r.read().decode("utf-8")


def parse(text):
    rows = []
    for line in text.splitlines():
        if not ROW.match(line):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) != 4:
            sys.exit(f"Unexpected row format: {line!r}")
        code, sender, message, description = cells
        rows.append({"code": code, "sender": sender, "message": message, "description": description})
    return rows


def slug(text):
    return re.sub(r"[^a-z0-9 -]", "", text.lower()).replace(" ", "-")


def render(rows):
    by_sender = {key: sorted((r for r in rows if r["sender"] == key), key=lambda r: int(r["code"])) for key, _, _ in SENDERS}
    unknown = sorted({r["sender"] for r in rows} - set(by_sender))
    if unknown:
        sys.exit(f"Unknown sender type(s) in source: {unknown}")

    out = []
    w = out.append
    w("# Core Error Codes")
    w("")
    w("> The core ONDC error codes that a Gateway, buyer app, seller app or logistics participant returns when a request cannot be processed.")
    w("")
    w("---")
    w("")
    w("## Overview")
    w("")
    w("When a request fails, the receiver returns a **NACK** with an `error` object carrying one of the codes below. See [ACK / NACK](/developer-guide/docs/about-ondc#44-ack--nack--the-synchronous-handshake) in About ONDC for the response format.")
    w("")
    w("```json")
    w("{")
    w('    "message": { "ack": { "status": "NACK" } },')
    w('    "error": {')
    w('        "code": "10001",')
    w('        "message": "Invalid Signature"')
    w("    }")
    w("}")
    w("```")
    w("")
    w("Codes are grouped by the participant that returns them:")
    w("")
    w("| Returned by | Codes | Range |")
    w("| ----------- | ----- | ----- |")
    for key, title, _ in SENDERS:
        codes = [int(r["code"]) for r in by_sender[key]]
        w(f"| [{title}](#{slug(title)}) | {len(codes)} | {min(codes)}–{max(codes)} |")
    w("")
    w("Some domains (for example Financial Services, Mobility and Network Services) define **additional domain-specific codes**. Those are listed in the **Error Codes** tab of each use case under Explore by Domain.")
    w("")
    for key, title, intro in SENDERS:
        w("---")
        w("")
        w(f"## {title}")
        w("")
        w(intro)
        w("")
        w("| Code | Message | Description |")
        w("| ---- | ------- | ----------- |")
        for r in by_sender[key]:
            w(f"| `{r['code']}` | {r['message']} | {r['description']} |")
        w("")
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source", help="local copy of the official error-codes.md")
    args = parser.parse_args()

    rows = parse(load_source(args.source))
    if not rows:
        sys.exit("No error code rows found in source")
    with open(OUTPUT, "w", encoding="utf-8") as f:
        f.write(render(rows))
    print(f"Wrote {len(rows)} error codes to {os.path.normpath(OUTPUT)}")


if __name__ == "__main__":
    main()
