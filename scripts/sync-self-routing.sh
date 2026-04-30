#!/usr/bin/env bash
# Sync the self-hosting routing bootstrap into all root thin shells.

set -euo pipefail

MODE="sync"
for arg in "$@"; do
  case "$arg" in
    --check) MODE="check" ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CANONICAL="$ROOT/references/self-hosting-routing.yaml"
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
  echo "Missing canonical routing manifest: $CANONICAL" >&2
  exit 1
fi

python3 - "$ROOT" "$CANONICAL" "$START" "$END" "$MODE" "${TARGETS[@]}" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
canonical = Path(sys.argv[2])
start = sys.argv[3]
end = sys.argv[4]
mode = sys.argv[5]
targets = sys.argv[6:]

def clean(value: str) -> str:
    value = value.strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1]
    return value

def parse_manifest():
    tasks = []
    current = None
    section = None
    for raw in canonical.read_text().splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        stripped = raw.strip()
        if stripped == "tasks:":
            continue
        if raw.startswith("  - id:"):
            current = {"id": clean(raw.split(":", 1)[1]), "required_reads": [], "trigger_examples": []}
            tasks.append(current)
            section = None
            continue
        if current is None:
            continue
        if raw.startswith("    required_reads:"):
            section = "required_reads"
            continue
        if raw.startswith("    trigger_examples:"):
            section = "trigger_examples"
            continue
        if section in {"required_reads", "trigger_examples"} and raw.startswith("      - "):
            current[section].append(clean(stripped[2:]))
            continue
        if raw.startswith("    ") and ":" in stripped:
            key, value = stripped.split(":", 1)
            current[key.strip()] = clean(value)
            section = None
    if not tasks:
        raise SystemExit("self-hosting-routing.yaml has no tasks")
    return tasks

def validate_paths(tasks):
    errors = []
    for task in tasks:
        refs = list(task.get("required_reads", []))
        workflow = task.get("workflow", "")
        if workflow:
            refs.append(workflow)
        for ref in refs:
            if "FILL:" in ref or ref.startswith("Check "):
                continue
            path = ref.split("#", 1)[0]
            if not path or not (".md" in path or ".sh" in path or "/" in path):
                continue
            if not (root / path).exists():
                errors.append(f"{task.get('id')}: missing route target: {ref}")
    return errors

tasks = parse_manifest()
ids = [task.get("id", "") for task in tasks]
if len(ids) != len(set(ids)):
    raise SystemExit("self-hosting-routing.yaml has duplicate task ids")
if "other" not in ids:
    raise SystemExit("self-hosting-routing.yaml is missing fallback task id: other")
errors = validate_paths(tasks)
if errors:
    for error in errors:
        print(f"FAIL: {error}")
    raise SystemExit(1)

block = """## Quick Routing (survives context truncation)

Task routes live in `references/self-hosting-routing.yaml`.

For every new task:
1. Read `SKILL.md`.
2. Read `references/self-hosting-routing.yaml`.
3. Match by `labels`, `trigger_examples`, and task intent.
4. Read only that route's `required_reads`, then follow its `workflow`.
5. If no route matches, use the `other` route."""

replacement = f"{start}\n{block}\n{end}"
failed = False

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
    if new_text == text:
        print(f"OK: {rel}")
    elif mode == "check":
        print(f"DRIFT: {rel}")
        failed = True
    else:
        path.write_text(new_text)
        print(f"synced {rel}")

if failed:
    print("\nRun: bash scripts/sync-self-routing.sh")
    raise SystemExit(1)
if mode == "check":
    print("\nAll self-hosting routing bootstraps match.")
PY
