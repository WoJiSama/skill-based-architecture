#!/usr/bin/env bash
# Sync the self-hosting Quick Routing block into all root thin shells.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CANONICAL="$ROOT/references/self-hosting-routing.md"
START='<!-- SELF_ROUTING_BLOCK_START -->'
END='<!-- SELF_ROUTING_BLOCK_END -->'
TARGETS=(
  "AGENTS.md"
  "CLAUDE.md"
  "CODEX.md"
  "GEMINI.md"
  ".codex/instructions.md"
  ".cursor/rules/workflow.mdc"
  ".cursor/skills/skill-based-architecture/SKILL.md"
)

if [[ ! -f "$CANONICAL" ]]; then
  echo "Missing canonical routing file: $CANONICAL" >&2
  exit 1
fi

python3 - "$ROOT" "$CANONICAL" "$START" "$END" "${TARGETS[@]}" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
canonical = Path(sys.argv[2])
start = sys.argv[3]
end = sys.argv[4]
targets = sys.argv[5:]

source = canonical.read_text()
try:
    block = source.split(start, 1)[1].split(end, 1)[0].strip("\n")
except IndexError:
    raise SystemExit(f"Canonical block markers missing in {canonical}")

replacement = f"{start}\n{block}\n{end}"

for rel in targets:
    path = root / rel
    text = path.read_text()
    if start in text and end in text:
        before = text.split(start, 1)[0]
        after = text.split(end, 1)[1]
        new_text = before + replacement + after
    else:
        marker = "## Quick Routing (survives context truncation)"
        if marker not in text:
            raise SystemExit(f"No routing block or heading found in {rel}")
        before, rest = text.split(marker, 1)
        next_section = rest.find("\n## ")
        if next_section == -1:
            after = "\n"
        else:
            after = rest[next_section + 1:]
        new_text = before.rstrip() + "\n\n" + replacement + "\n\n" + after.lstrip()
    path.write_text(new_text)
    print(f"synced {rel}")
PY
