#!/usr/bin/env bash
# Verify root thin-shell routing blocks match references/self-hosting-routing.md.

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

python3 - "$ROOT" "$CANONICAL" "$START" "$END" "${TARGETS[@]}" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
canonical = Path(sys.argv[2])
start = sys.argv[3]
end = sys.argv[4]
targets = sys.argv[5:]

def extract(path: Path) -> str:
    text = path.read_text()
    if start not in text or end not in text:
        raise ValueError(f"missing routing markers")
    return text.split(start, 1)[1].split(end, 1)[0].strip("\n")

expected = extract(canonical)
failed = False
for rel in targets:
    path = root / rel
    try:
        actual = extract(path)
    except Exception as exc:
        print(f"❌ {rel}: {exc}")
        failed = True
        continue
    if actual != expected:
        print(f"❌ {rel}: routing block drifted from references/self-hosting-routing.md")
        failed = True
    else:
        print(f"✅ {rel}: routing block matches")

if failed:
    print("\nRun: bash scripts/sync-self-routing.sh")
    raise SystemExit(1)
print("\nAll self-hosting routing blocks match.")
PY
