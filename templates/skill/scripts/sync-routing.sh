#!/usr/bin/env bash
# sync-routing.sh — Generate Always Read, Common Tasks, and shell bootstraps from routing.yaml.
# Usage:
#   bash scripts/sync-routing.sh [skill-name|skill-root] [--check]
#   bash skills/<name>/scripts/sync-routing.sh <name> [--check]

set -euo pipefail

MODE="sync"
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --check) MODE="check" ;;
    *) TARGET="$arg" ;;
  esac
done

if [[ -n "$TARGET" && -f "$TARGET/SKILL.md" ]]; then
  SKILL_ROOT="$TARGET"
elif [[ -n "$TARGET" && -f "$TARGET/SKILL.md.template" ]]; then
  SKILL_ROOT="$TARGET"
elif [[ -n "$TARGET" && -f "skills/$TARGET/SKILL.md" ]]; then
  SKILL_ROOT="skills/$TARGET"
elif [[ -f "SKILL.md" && -f "routing.yaml" ]]; then
  SKILL_ROOT="."
elif [[ -f "SKILL.md.template" && -f "routing.yaml" ]]; then
  SKILL_ROOT="."
else
  echo "Usage: bash sync-routing.sh [skill-name|skill-root] [--check]" >&2
  exit 1
fi

python3 - "$SKILL_ROOT" "$MODE" <<'PY'
from pathlib import Path
import sys

skill_root = Path(sys.argv[1]).resolve()
mode = sys.argv[2]
manifest = skill_root / "routing.yaml"
summary_start = "<!-- ROUTING_SUMMARY_START -->"
summary_end = "<!-- ROUTING_SUMMARY_END -->"
bootstrap_start = "<!-- ROUTING_BOOTSTRAP_START -->"
bootstrap_end = "<!-- ROUTING_BOOTSTRAP_END -->"
always_start = "<!-- ALWAYS_READ_START -->"
always_end = "<!-- ALWAYS_READ_END -->"

if not manifest.exists():
    raise SystemExit(f"Missing routing manifest: {manifest}")

template_mode = skill_root.name == "skill" and skill_root.parent.name == "templates"
skill_file = skill_root / ("SKILL.md.template" if template_mode else "SKILL.md")

if template_mode:
    repo_root = skill_root.parent / "shells"
elif skill_root.parent.name == "skills":
    repo_root = skill_root.parent.parent
else:
    repo_root = Path.cwd().resolve()

def skill_name() -> str:
    for line in skill_file.read_text().splitlines():
        if line.startswith("name:"):
            return line.split(":", 1)[1].strip()
    return skill_root.name

name = skill_name()

def clean(value: str) -> str:
    value = value.strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1]
    return value

def parse_manifest():
    always_read = []
    tasks = []
    current = None
    section = None
    top_section = None
    for raw in manifest.read_text().splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        stripped = raw.strip()
        if stripped == "always_read:":
            top_section = "always_read"
            current = None
            section = None
            continue
        if stripped == "tasks:":
            top_section = "tasks"
            section = None
            continue
        if top_section == "always_read" and raw.startswith("  - "):
            always_read.append(clean(stripped[2:]))
            continue
        if raw.startswith("  - id:"):
            current = {"id": clean(raw.split(":", 1)[1]), "labels": {}, "required_reads": [], "trigger_examples": []}
            tasks.append(current)
            section = None
            continue
        if current is None:
            continue
        if raw.startswith("    labels:"):
            section = "labels"
            continue
        if raw.startswith("    required_reads:"):
            section = "required_reads"
            continue
        if raw.startswith("    trigger_examples:"):
            section = "trigger_examples"
            continue
        if section == "labels" and raw.startswith("      ") and ":" in stripped:
            key, value = stripped.split(":", 1)
            current["labels"][key.strip()] = clean(value)
            continue
        if section in {"required_reads", "trigger_examples"} and raw.startswith("      - "):
            current[section].append(clean(stripped[2:]))
            continue
        if raw.startswith("    ") and ":" in stripped:
            key, value = stripped.split(":", 1)
            current[key.strip()] = clean(value)
            section = None
    if not tasks:
        raise SystemExit("routing.yaml has no tasks")
    return always_read, tasks

always_read, tasks = parse_manifest()

def validate_schema(always_read, tasks):
    errors = []
    ids = [task.get("id", "") for task in tasks]
    duplicates = sorted({task_id for task_id in ids if ids.count(task_id) > 1})
    for task_id in duplicates:
        errors.append(f"duplicate task id: {task_id}")
    if "other" not in ids:
        errors.append("missing fallback task id: other")
    for task in tasks:
        task_id = task.get("id", "")
        if not task_id:
            errors.append("task missing id")
        if not task.get("labels"):
            errors.append(f"{task_id}: missing labels")
        if not task.get("workflow"):
            errors.append(f"{task_id}: missing workflow")
    for item in always_read:
        if not item or "FILL:" in item:
            continue
        if not any(item.startswith(prefix) for prefix in ("rules/", "workflows/", "references/")):
            errors.append(f"always_read path should be skill-relative rules/, workflows/, or references/: {item}")
    return errors

schema_errors = validate_schema(always_read, tasks)
if schema_errors:
    for err in schema_errors:
        print(f"FAIL: {err}")
    raise SystemExit(1)

def label_for(task):
    labels = task.get("labels", {})
    en = labels.get("en", "").strip()
    zh = labels.get("zh", "").strip()
    task_id = task.get("id", "").strip()
    if en and zh and en != zh:
        return f"{en} / {zh} (`{task_id}`)"
    if en or zh:
        return f"{en or zh} (`{task_id}`)"
    return task_id

def format_reads(reads):
    if not reads:
        return "none"
    return ", ".join(f"`{item}`" if "/" in item and "<!--" not in item else item for item in reads)

def format_always_skill(reads):
    if not reads:
        return "<!-- FILL: add 2-3 always-read files in routing.yaml -->"
    return "\n".join(f"{idx}. `{item}`" for idx, item in enumerate(reads, 1))

def format_always_shell(reads):
    if not reads:
        return "- <!-- FILL: add 2-3 always-read files in skills/{{NAME}}/routing.yaml -->"
    return "\n".join(f"- `skills/{name}/{item}`" for item in reads)

def format_triggers(examples):
    real = [ex for ex in examples if ex and "FILL:" not in ex]
    if not real:
        return ""
    return "; triggers: " + ", ".join(f'"{ex}"' for ex in real[:3])

def format_workflow(value):
    if not value:
        return "none"
    if value.startswith("workflows/"):
        return f"`{value}`"
    return value

summary_block = "\n".join(
    f"- {label_for(task)} -> reads {format_reads(task.get('required_reads', []))}; "
    f"workflow {format_workflow(task.get('workflow', ''))}; {task.get('route', '').strip()}{format_triggers(task.get('trigger_examples', []))}"
    for task in tasks
)
always_skill_block = format_always_skill(always_read)
always_shell_block = format_always_shell(always_read)

bootstrap_block = f"""Task routes live in `skills/{name}/routing.yaml`.

For every new task:
1. Read `skills/{name}/routing.yaml`.
2. Match by `labels`, `trigger_examples`, and task intent.
3. Read only that route's `required_reads` plus Always Read files.
4. Follow that route's `workflow`.
5. If no route matches, use the `other` route."""

def validate_paths():
    errors = []
    for item in always_read:
        if "*" in item or "FILL:" in item:
            continue
        target = skill_root / item.split("#", 1)[0]
        if not target.exists():
            errors.append(f"always_read missing: {item}")
    for task in tasks:
        if "FILL:" in str(task):
            continue
        workflow = task.get("workflow", "")
        if workflow.startswith("workflows/"):
            target = skill_root / workflow.split("#", 1)[0]
            if not target.exists():
                errors.append(f"{task.get('id')}: workflow missing: {workflow}")
        for item in task.get("required_reads", []):
            if "*" in item or "FILL:" in item or item.startswith("task-relevant "):
                continue
            if "/" in item:
                target = skill_root / item.split("#", 1)[0]
                if not target.exists():
                    errors.append(f"{task.get('id')}: required_read missing: {item}")
    return errors

path_errors = validate_paths()
if path_errors:
    for err in path_errors:
        print(f"FAIL: {err}")
    raise SystemExit(1)

def label(path: Path) -> str:
    for base in (repo_root, skill_root.parent.parent if template_mode else repo_root):
        try:
            return str(path.relative_to(base))
        except ValueError:
            pass
    return str(path)

targets = [
    (skill_file, always_start, always_end, always_skill_block),
    (skill_file, summary_start, summary_end, summary_block),
]
for rel in ["AGENTS.md", "CLAUDE.md", "CODEX.md", "GEMINI.md", ".codex/instructions.md"]:
    path = repo_root / rel
    targets.append((path, always_start, always_end, always_shell_block))
    targets.append((path, bootstrap_start, bootstrap_end, bootstrap_block))
rules_dir = repo_root / ".cursor" / "rules"
if rules_dir.exists():
    for path in sorted(rules_dir.glob("*.mdc")):
        targets.append((path, always_start, always_end, always_shell_block))
        targets.append((path, bootstrap_start, bootstrap_end, bootstrap_block))
cursor_entry = repo_root / ".cursor" / "skills" / name / ("SKILL.md.template" if template_mode else "SKILL.md")
targets.append((cursor_entry, bootstrap_start, bootstrap_end, bootstrap_block))

failed = False
changed = False
for path, start, end, block in targets:
    if not path.exists():
        continue
    text = path.read_text()
    if start not in text or end not in text:
        print(f"FAIL: {label(path)} missing generated block markers: {start} / {end}")
        failed = True
        continue
    expected = f"{start}\n{block}\n{end}"
    actual = start + text.split(start, 1)[1].split(end, 1)[0] + end
    if actual == expected:
        print(f"OK: {label(path)}")
        continue
    if mode == "check":
        print(f"DRIFT: {label(path)}")
        failed = True
        continue
    before = text.split(start, 1)[0]
    after = text.split(end, 1)[1]
    path.write_text(before + expected + after)
    changed = True
    print(f"synced {label(path)}")

if failed:
    print("\nRun: bash skills/<name>/scripts/sync-routing.sh <name>")
    raise SystemExit(1)
if mode == "check":
    print("Routing manifest check passed.")
elif not changed:
    print("Routing summary and bootstraps already up to date.")
PY
