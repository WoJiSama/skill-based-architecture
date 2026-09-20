#!/usr/bin/env bash
# Verify root thin shells match generated content + activation metadata stays
# identical across SKILL.md, .cursor/skills/.../SKILL.md, and skill.yaml.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT/scripts/sync-self-shells.sh" --check

# SKILL.md dual budget (SKILL.md principle 1): description ≤ 25 lines,
# body ≤ 90 lines. Budgets are overridable for legitimate experiments.
DESC_MAX="${SKILL_DESC_MAX_LINES:-25}"
BODY_MAX="${SKILL_BODY_MAX_LINES:-90}"
read -r desc_lines body_lines <<< "$(awk '/^---$/{n++; next} n==1{d++} n>=2{b++} END{print d+0, b+0}' "$ROOT/SKILL.md")"
if (( desc_lines > DESC_MAX || body_lines > BODY_MAX )); then
  echo "FAIL: SKILL.md exceeds dual budget (description ${desc_lines}/${DESC_MAX} lines, body ${body_lines}/${BODY_MAX} lines)."
  echo "Split intent clusters or move detail to references/ — see SKILL.md principle 1."
  exit 1
fi
echo "OK: SKILL.md within dual budget (description ${desc_lines}/${DESC_MAX}, body ${body_lines}/${BODY_MAX} lines)."

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
sources = [
    ("SKILL.md", root / "SKILL.md"),
    (".cursor/skills/skill-based-architecture/SKILL.md", root / ".cursor/skills/skill-based-architecture/SKILL.md"),
    ("skill.yaml", root / "skill.yaml"),
]

def clean(value: str) -> str:
    value = value.strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1]
    return value

def read_description(path: Path) -> str:
    lines = path.read_text().splitlines()
    for idx, raw in enumerate(lines):
        if not raw.startswith("description:"):
            continue
        value = raw.split(":", 1)[1].strip()
        if value and value not in {">", "|", ">-", "|-"}:
            return clean(value)
        block = []
        for line in lines[idx + 1:]:
            stripped = line.strip()
            if not stripped:
                continue
            if line.startswith("---") or (line[:1].strip() and ":" in stripped):
                break
            block.append(stripped)
        return " ".join(block)
    raise SystemExit(f"FAIL: missing description in {path.relative_to(root)}")

descriptions = []
for label, path in sources:
    if not path.exists():
        raise SystemExit(f"FAIL: missing activation metadata source: {label}")
    descriptions.append((label, read_description(path)))

baseline = descriptions[0][1]
failed = False
for label, description in descriptions[1:]:
    if description != baseline:
        failed = True
        print(f"FAIL: description drift between SKILL.md and {label}")

if failed:
    print("\nKeep SKILL.md, Cursor registration, and skill.yaml descriptions identical.")
    raise SystemExit(1)

print("\nAll self-hosting activation descriptions match.")
PY
