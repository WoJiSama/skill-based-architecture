#!/usr/bin/env bash
# check-external-facts.sh — Flag stale source-bound external facts.
#
# Mark facts with:
#   <!-- external-fact: verified=YYYY-MM-DD source=https://example.com/docs -->
#
# Usage:
#   bash scripts/check-external-facts.sh
#   EXTERNAL_FACT_MAX_DAYS=90 bash scripts/check-external-facts.sh
#   bash scripts/check-external-facts.sh /path/to/repo-or-skill-root

set -euo pipefail

ROOT="${1:-$PWD}"
MAX_DAYS="${EXTERNAL_FACT_MAX_DAYS:-180}"
TODAY="${EXTERNAL_FACT_TODAY:-$(date +%F)}"

python3 - "$ROOT" "$MAX_DAYS" "$TODAY" <<'PY'
from datetime import date
from pathlib import Path
import re
import sys

root = Path(sys.argv[1]).resolve()
max_days = int(sys.argv[2])
today = date.fromisoformat(sys.argv[3])
marker = re.compile(r"<!--\s*external-fact:\s*verified=(\d{4}-\d{2}-\d{2})\s+source=([^\s]+)\s*-->")
skip_dirs = {".git", "node_modules", ".venv", "venv", "dist", "build"}

if not root.exists():
    raise SystemExit(f"Missing scan root: {root}")

checked = 0
failures = []
for path in sorted(root.rglob("*.md")):
    if any(part in skip_dirs for part in path.parts):
        continue
    rel = path.relative_to(root)
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        lines = path.read_text(errors="replace").splitlines()
    for lineno, line in enumerate(lines, 1):
        stripped = line.strip()
        if "external-fact:" not in stripped:
            continue
        if not stripped.startswith("<!-- external-fact:"):
            continue
        match = marker.search(stripped)
        if not match:
            failures.append(f"{rel}:{lineno}: malformed external-fact marker")
            continue
        checked += 1
        try:
            verified = date.fromisoformat(match.group(1))
        except ValueError:
            failures.append(f"{rel}:{lineno}: invalid verified date: {match.group(1)}")
            continue
        source = match.group(2)
        age = (today - verified).days
        if age < 0:
            failures.append(f"{rel}:{lineno}: verified date is in the future: {verified}")
        if age > max_days:
            failures.append(f"{rel}:{lineno}: external fact is {age} days old (max {max_days}); refresh {source}")

print("External fact freshness check")
print("=============================")
print(f"Scan root: {root}")
print(f"Max age: {max_days} days")
print(f"Markers checked: {checked}")

if failures:
    print("")
    for failure in failures:
        print(f"❌ {failure}")
    raise SystemExit(1)

if checked == 0:
    print("No external-fact markers found.")
else:
    print("All external-fact markers are within the freshness window.")
PY
