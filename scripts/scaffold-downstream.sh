#!/usr/bin/env bash
# Evidence-driven first-use materializer for a downstream project.
#
# The command deliberately has one public action: inspect, preview, then apply.
# It does not expose a tier/profile/capability switch.  The physical result is
# derived from target evidence and is complete only for the responsibilities
# that evidence admits.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$(pwd)"
NAME=""
SUMMARY=""
MODE="dry-run"
EVIDENCE_PATH="${SBA_MATERIALIZATION_EVIDENCE:-}"

usage() {
  cat <<'EOF'
Usage: bash scripts/scaffold-downstream.sh --name <skill-name> --summary <text> [--target <dir>] [--apply]

Defaults to a read-only evidence inventory and preview.  Existing project
instruction entries are preserved and reported for Agent-led semantic merge.
Existing skill or Cursor registration directories are hard conflicts because
rerunning over them is unsafe.  The command chooses only the owners and
harness surfaces supported by target evidence; it never asks for a shape.

Agent-only session evidence may be supplied with `--evidence <temporary-json>`
or `SBA_MATERIALIZATION_EVIDENCE`. It is read before staging and is never
copied into the downstream project; ordinary users do not choose a tier.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      [[ $# -ge 2 ]] || { echo "Missing value for --name" >&2; exit 2; }
      NAME="$2"
      shift 2
      ;;
    --summary)
      [[ $# -ge 2 ]] || { echo "Missing value for --summary" >&2; exit 2; }
      SUMMARY="$2"
      shift 2
      ;;
    --target)
      [[ $# -ge 2 ]] || { echo "Missing value for --target" >&2; exit 2; }
      TARGET="$2"
      shift 2
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    --dry-run)
      MODE="dry-run"
      shift
      ;;
    --evidence)
      [[ $# -ge 2 ]] || { echo "Missing value for --evidence" >&2; exit 2; }
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "$NAME" ]] || { echo "Missing required --name" >&2; exit 2; }
[[ -n "$SUMMARY" ]] || { echo "Missing required --summary" >&2; exit 2; }
[[ "$NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
  echo "Skill name must be kebab-case: $NAME" >&2
  exit 2
}
[[ "$SUMMARY" != *$'\n'* ]] || { echo "Summary must be one line" >&2; exit 2; }
[[ -d "$TARGET" ]] || { echo "Target directory does not exist: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd -P)"

has_path() {
  [[ -e "$TARGET/$1" || -L "$TARGET/$1" ]]
}

file_lines() {
  wc -l < "$1" | tr -d ' '
}

yaml_quote() {
  # Quote only YAML double-quoted scalar metacharacters.  The previous
  # bracket expressions also matched the backslash introduced by the first
  # substitution, turning one source backslash into a pair of escaped quotes
  # in the generated manifest.
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

append_unique() {
  # Usage: append_unique ARRAY_NAME VALUE.  Bash 3.2 has no nameref, so the
  # supported arrays are explicit below.
  local array_name="$1" value="$2" item
  shift 2
  case "$array_name" in
    INSTRUCTION_FILES)
      if [[ ${#INSTRUCTION_FILES[@]} -gt 0 ]]; then
        for item in "${INSTRUCTION_FILES[@]}"; do [[ "$item" == "$value" ]] && return; done
      fi
      INSTRUCTION_FILES+=("$value")
      ;;
    PRESERVE_FILES)
      if [[ ${#PRESERVE_FILES[@]} -gt 0 ]]; then
        for item in "${PRESERVE_FILES[@]}"; do [[ "$item" == "$value" ]] && return; done
      fi
      PRESERVE_FILES+=("$value")
      ;;
    REGISTRATION_FILES)
      if [[ ${#REGISTRATION_FILES[@]} -gt 0 ]]; then
        for item in "${REGISTRATION_FILES[@]}"; do [[ "$item" == "$value" ]] && return; done
      fi
      REGISTRATION_FILES+=("$value")
      ;;
    REVIEW_REGISTRATIONS)
      if [[ ${#REVIEW_REGISTRATIONS[@]} -gt 0 ]]; then
        for item in "${REVIEW_REGISTRATIONS[@]}"; do [[ "$item" == "$value" ]] && return; done
      fi
      REVIEW_REGISTRATIONS+=("$value")
      ;;
    ROUTE_IDS)
      if [[ ${#ROUTE_IDS[@]} -gt 0 ]]; then
        for item in "${ROUTE_IDS[@]}"; do [[ "$item" == "$value" ]] && return; done
      fi
      ROUTE_IDS+=("$value")
      ;;
    *)
      echo "internal error: unknown array $array_name" >&2
      exit 70
      ;;
  esac
}

# ── 1. Read-only target evidence inventory ───────────────────────────

INSTRUCTION_FILES=()
PRESERVE_FILES=()
REGISTRATION_FILES=()
REVIEW_REGISTRATIONS=()
ROUTE_IDS=()
EVIDENCE_TASK_IDS=()
EVIDENCE_TASK_LABEL_EN=()
EVIDENCE_TASK_LABEL_ZH=()
EVIDENCE_TASK_TRIGGER_EN=()
EVIDENCE_TASK_TRIGGER_ZH=()
EVIDENCE_TASK_MANAGED=()
EVIDENCE_TASK_CLOSURE=()
EVIDENCE_TASK_GOTCHA=()
EVIDENCE_TASK_UPSTREAM=()
EVIDENCE_HARNESSES=()
EVIDENCE_PRESENT=0
EVIDENCE_MANAGED_PRESSURE=0
EVIDENCE_CLOSURE_PRESSURE=0
EVIDENCE_VALIDATION_PRESSURE=0
EVIDENCE_UPSTREAM_PRESSURE=0
EVIDENCE_GOTCHA_PRESSURE=0
EVIDENCE_SHARED_ROUTING=0
EVIDENCE_BROAD_PRESSURE=0
EVIDENCE_EXTERNAL_WRITE_PRESSURE=0

INSTRUCTION_COUNT=0
ENTRY_COUNT=0
INSTRUCTION_LINES=0
TASK_SIGNAL_COUNT=0
WORKFLOW_PRESSURE=0
HARNESS_COUNT=0
VALIDATION_PRESSURE=0
UPSTREAM_PRESSURE=0
MANAGED_PRESSURE=0
CLOSURE_PRESSURE=0
SHARED_ROUTING_DECLARED=0
TEAM_HARNESS_DECLARED=0
EXPLICIT_BROAD_PRESSURE=0
EXTERNAL_WRITE_PRESSURE=0
GOTCHA_PRESSURE=0
MULTI_PROCEDURE_EVIDENCE=0

TASK_BUG=0
TASK_CHANGE=0
TASK_REFACTOR=0
TASK_PLAN=0
TASK_REVIEW=0
TASK_RULE=0
TASK_UPSTREAM=0

NEED_AGENTS=1                    # AGENTS.md is the cross-harness no-evidence floor.
NEED_CLAUDE=0
NEED_CODEX=0
NEED_GEMINI=0
NEED_CURSOR=0

append_evidence_task() {
  EVIDENCE_TASK_IDS+=("$1")
  EVIDENCE_TASK_LABEL_EN+=("$2")
  EVIDENCE_TASK_LABEL_ZH+=("$3")
  EVIDENCE_TASK_TRIGGER_EN+=("$4")
  EVIDENCE_TASK_TRIGGER_ZH+=("$5")
  EVIDENCE_TASK_MANAGED+=("$6")
  EVIDENCE_TASK_CLOSURE+=("$7")
  EVIDENCE_TASK_GOTCHA+=("$8")
  EVIDENCE_TASK_UPSTREAM+=("$9")
}

load_session_evidence() {
  [[ -n "$EVIDENCE_PATH" ]] || return 0
  [[ -f "$EVIDENCE_PATH" ]] || {
    echo "Evidence manifest not found: $EVIDENCE_PATH" >&2
    exit 2
  }
  command -v python3 >/dev/null 2>&1 || {
    echo "Python 3 is required to read --evidence manifests" >&2
    exit 2
  }
  local evidence_lines line kind a b c d e f g h i
  evidence_lines="$(python3 - "$EVIDENCE_PATH" <<'PY'
import json, re, sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as exc:
    raise SystemExit(f"invalid evidence manifest: {exc}")
if not isinstance(data, dict) or data.get("version") != 1:
    raise SystemExit("evidence manifest version must be 1")

def text(value, label):
    if not isinstance(value, str) or not value.strip() or "\t" in value or "\n" in value:
        raise SystemExit(f"{label} must be one-line text")
    return value.strip()

tasks = data.get("tasks", [])
if not isinstance(tasks, list):
    raise SystemExit("evidence tasks must be a list")
seen = set()
for index, task in enumerate(tasks):
    if not isinstance(task, dict):
        raise SystemExit(f"tasks[{index}] must be an object")
    task_id = text(task.get("id"), f"tasks[{index}].id")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", task_id):
        raise SystemExit(f"tasks[{index}].id must be kebab-case")
    if task_id in seen:
        raise SystemExit(f"duplicate evidence task id: {task_id}")
    seen.add(task_id)
    labels = task.get("labels", {})
    if not isinstance(labels, dict):
        raise SystemExit(f"tasks[{index}].labels must be an object")
    label_en = text(labels.get("en", task_id.replace("-", " ").title()), f"tasks[{index}].labels.en")
    label_zh = text(labels.get("zh", "项目任务"), f"tasks[{index}].labels.zh")
    triggers = task.get("trigger_examples", [])
    if not isinstance(triggers, list) or not triggers:
        raise SystemExit(f"tasks[{index}].trigger_examples must be non-empty")
    trigger_en = text(triggers[0], f"tasks[{index}].trigger_examples[0]")
    trigger_zh = text(triggers[1] if len(triggers) > 1 else "处理项目任务", f"tasks[{index}].trigger_examples[1]")
    flags = ["managed", "closure", "gotcha", "upstream"]
    values = []
    for flag in flags:
        value = task.get(flag, False)
        if not isinstance(value, bool):
            raise SystemExit(f"tasks[{index}].{flag} must be boolean")
        values.append("1" if value else "0")
    print("TASK\t" + "\t".join([task_id, label_en, label_zh, trigger_en, trigger_zh] + values))

harnesses = data.get("harnesses", [])
if not isinstance(harnesses, list):
    raise SystemExit("evidence harnesses must be a list")
for index, harness in enumerate(harnesses):
    value = text(harness, f"harnesses[{index}]").lower()
    if value not in {"agents", "claude", "codex", "gemini", "cursor"}:
        raise SystemExit(f"unsupported evidence harness: {value}")
    print("HARNESS\t" + value)

maintenance = data.get("maintenance_pressure", {})
if maintenance is None:
    maintenance = {}
if not isinstance(maintenance, dict):
    raise SystemExit("maintenance_pressure must be an object")
for key in ("managed_execution", "closure", "validation", "upstream", "gotchas", "shared_routing", "broad", "external_writes"):
    value = maintenance.get(key, False)
    if not isinstance(value, bool):
        raise SystemExit(f"maintenance_pressure.{key} must be boolean")
    if value:
        print("PRESSURE\t" + key)
PY
)" || exit 2
  EVIDENCE_PRESENT=1
  while IFS=$'\t' read -r kind a b c d e f g h i; do
    [[ -n "$kind" ]] || continue
    case "$kind" in
      TASK) append_evidence_task "$a" "$b" "$c" "$d" "$e" "$f" "$g" "$h" "${i:-0}" ;;
      HARNESS) EVIDENCE_HARNESSES+=("$a") ;;
      PRESSURE)
        case "$a" in
          managed_execution) EVIDENCE_MANAGED_PRESSURE=1 ;;
          closure) EVIDENCE_CLOSURE_PRESSURE=1 ;;
          validation) EVIDENCE_VALIDATION_PRESSURE=1 ;;
          upstream) EVIDENCE_UPSTREAM_PRESSURE=1 ;;
          gotchas) EVIDENCE_GOTCHA_PRESSURE=1 ;;
          shared_routing) EVIDENCE_SHARED_ROUTING=1 ;;
          broad) EVIDENCE_BROAD_PRESSURE=1 ;;
          external_writes) EVIDENCE_EXTERNAL_WRITE_PRESSURE=1 ;;
        esac
        ;;
      *) echo "invalid evidence output" >&2; exit 2 ;;
    esac
  done <<< "$evidence_lines"
}

collect_file() {
  local rel="$1"
  [[ -f "$TARGET/$rel" ]] || return 0
  append_unique INSTRUCTION_FILES "$rel"
}

collect_glob_files() {
  local dir="$1" pattern="$2" rel
  [[ -d "$TARGET/$dir" ]] || return 0
  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    collect_file "${rel#$TARGET/}"
  done < <(find "$TARGET/$dir" -maxdepth 2 -type f -name "$pattern" -print 2>/dev/null | sort)
}

instruction_files_contain() {
  local pattern="$1" file
  [[ ${#INSTRUCTION_FILES[@]} -gt 0 ]] || return 1
  for file in "${INSTRUCTION_FILES[@]}"; do
    [[ -f "$TARGET/$file" ]] || continue
    if grep -Eiq "$pattern" "$TARGET/$file" 2>/dev/null; then return 0; fi
  done
  return 1
}

inventory_entries() {
  local path registry registration_name formal_owner
  for path in AGENTS.md CLAUDE.md CODEX.md GEMINI.md \
    .codex/instructions.md .clinerules .windsurfrules \
    .github/copilot-instructions.md .cursor/rules/workflow.mdc; do
    collect_file "$path"
  done
  collect_glob_files .cursor/rules '*.mdc'
  collect_glob_files .windsurf/rules '*.md'
  collect_glob_files .claude '*.md'
  collect_glob_files .gemini '*.md'

  for registry in .cursor .claude .codex .agents .gemini; do
    [[ -d "$TARGET/$registry/skills" ]] || continue
    while IFS= read -r path; do
      [[ -n "$path" ]] || continue
      path="${path#$TARGET/}"
      append_unique REGISTRATION_FILES "$path"
      collect_file "$path"
      registration_name="${path#"$registry/skills/"}"
      registration_name="${registration_name%/SKILL.md}"
      formal_owner="skills/$registration_name/SKILL.md"
      if [[ ! -f "$TARGET/$formal_owner" ]]; then
        append_unique REVIEW_REGISTRATIONS "$path"
      fi
    done < <(find "$TARGET/$registry/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md -print 2>/dev/null | sort)
  done

  if [[ ${#INSTRUCTION_FILES[@]} -gt 0 ]]; then
    for path in "${INSTRUCTION_FILES[@]}"; do
      append_unique PRESERVE_FILES "$path"
    done
  fi
  ENTRY_COUNT=${#PRESERVE_FILES[@]}

  # Existing skill/routing surfaces are evidence, not destinations to merge.
  if [[ -d "$TARGET/skills" ]]; then
    while IFS= read -r path; do
      [[ -n "$path" ]] || continue
      if [[ "$path" != "$TARGET/skills/$NAME"* ]]; then
        EXPLICIT_BROAD_PRESSURE=1
        SHARED_ROUTING_DECLARED=1
      fi
    done < <(find "$TARGET/skills" -mindepth 2 -maxdepth 3 -type f \( -name routing.yaml -o -name SKILL.md \) -print 2>/dev/null)
  fi
}

inventory_harnesses() {
  if has_path CLAUDE.md || has_path .claude || has_path .claude/settings.json ||
     instruction_files_contain 'claude[[:space:]]*(code|harness)|claude\.md'; then
    NEED_CLAUDE=1
    HARNESS_COUNT=$((HARNESS_COUNT + 1))
  fi
  if has_path CODEX.md || has_path .codex || has_path .codex/instructions.md ||
     [[ "${SBA_HARNESS:-}" == "codex" ]] || [[ "${SESSION_HARNESS:-}" == "codex" ]]; then
    NEED_CODEX=1
    HARNESS_COUNT=$((HARNESS_COUNT + 1))
  fi
  if has_path GEMINI.md || has_path .gemini || has_path .gemini/settings.json ||
     instruction_files_contain 'gemini[[:space:]]*(cli|harness)|gemini\.md'; then
    NEED_GEMINI=1
    HARNESS_COUNT=$((HARNESS_COUNT + 1))
  fi
  if has_path .cursor || has_path .cursor/rules || has_path .cursor/skills ||
     instruction_files_contain 'cursor[[:space:]]*(rule|harness)|\.cursor/'; then
    NEED_CURSOR=1
    HARNESS_COUNT=$((HARNESS_COUNT + 1))
  fi

  # A root entry that already exists is always preserved even if its harness is
  # not currently active.  It is migration evidence, never a reason to delete.
  has_path CLAUDE.md && NEED_CLAUDE=1
  has_path CODEX.md && NEED_CODEX=1
  has_path GEMINI.md && NEED_GEMINI=1
  find "$TARGET/.cursor/rules" -maxdepth 1 -type f -name '*.mdc' -print 2>/dev/null | grep -q . && NEED_CURSOR=1 || true
}

inventory_content_pressure() {
  local file text
  for file in ${INSTRUCTION_FILES[@]+"${INSTRUCTION_FILES[@]}"} README.md CONTRIBUTING.md DEVELOPMENT.md \
    package.json pyproject.toml Cargo.toml go.mod pom.xml Makefile; do
    [[ -f "$TARGET/$file" ]] || continue
    append_unique INSTRUCTION_FILES "$file"
  done

  if [[ ${#INSTRUCTION_FILES[@]} -gt 0 ]]; then
    for file in "${INSTRUCTION_FILES[@]}"; do
      [[ -f "$TARGET/$file" ]] || continue
      INSTRUCTION_LINES=$((INSTRUCTION_LINES + $(file_lines "$TARGET/$file")))
    if grep -Eiq 'bug|error|failing|exception|incident|报错|异常|故障|测试挂' "$TARGET/$file"; then TASK_BUG=1; fi
    if grep -Eiq 'feature|add|implement|change|optimi[sz]|新增|功能|优化|改动' "$TARGET/$file"; then TASK_CHANGE=1; fi
    if grep -Eiq 'refactor|rename|migrat|extract|重构|改名|迁移' "$TARGET/$file"; then TASK_REFACTOR=1; fi
    if grep -Eiq 'plan|design|architecture|规划|设计|方案' "$TARGET/$file"; then TASK_PLAN=1; fi
    if grep -Eiq 'review|reviewer|评审|审查' "$TARGET/$file"; then TASK_REVIEW=1; fi
    if grep -Eiq 'rule|lesson|gotcha|pitfall|规范|规则|踩坑|经验' "$TARGET/$file"; then TASK_RULE=1; fi
    if grep -Eiq 'lesson|gotcha|pitfall|踩坑|重复故障|经验' "$TARGET/$file"; then GOTCHA_PRESSURE=1; fi
    if grep -Eiq 'upstream|vendor|上游|同步模板' "$TARGET/$file"; then TASK_UPSTREAM=1; fi
    if grep -Eiq 'task[[:space:]_-]*(execution|anchor|plan)|pause|resume|replan|decision drift|中断|恢复|锚点' "$TARGET/$file"; then MANAGED_PRESSURE=1; fi
    if grep -Eiq 'closure|definition of done|AAR|complete|delivery|deliver|commit|push|merge|完成|交付|验收' "$TARGET/$file"; then CLOSURE_PRESSURE=1; fi
    if grep -Eiq 'database|postgres|mysql|sql[[:space:]_-]*migration|schema[[:space:]_-]*migration|deploy|deployment|publish[[:space:]_-]*(config|configuration)|config(uration)?([[:space:]_-]*(file|value|setting|change|write|publish|update|management|center|service))?|nacos|consul|shared[[:space:]_-]*(system|service|environment)|production[[:space:]_-]*(system|environment)|数据库|部署|配置|发布配置|配置中心|共享系统|生产环境' "$TARGET/$file"; then EXTERNAL_WRITE_PRESSURE=1; fi
      if grep -Eiq 'harness|tooling|route|routing|workflow|procedure|步骤|流程' "$TARGET/$file"; then WORKFLOW_PRESSURE=1; fi
      if grep -Eiq 'claude|cursor|codex|gemini|windsurf|copilot' "$TARGET/$file"; then TEAM_HARNESS_DECLARED=1; fi
      procedure_headings=$(grep -Eic '^#{2,4}[[:space:]].*(workflow|flow|bug|feature|review|plan|release|procedure|流程|修复|规划|评审|发布)' "$TARGET/$file" 2>/dev/null || true)
      if [[ "$procedure_headings" -ge 2 ]]; then MULTI_PROCEDURE_EVIDENCE=1; fi
    done
  fi

  TASK_SIGNAL_COUNT=$((TASK_BUG + TASK_CHANGE + TASK_REFACTOR + TASK_PLAN + TASK_REVIEW + TASK_RULE))
  if [[ "$ENTRY_COUNT" -le 1 && "$MULTI_PROCEDURE_EVIDENCE" -eq 0 && "$TASK_SIGNAL_COUNT" -gt 1 ]]; then
    TASK_SIGNAL_COUNT=1
    # A lone document can own several verbs without proving independently
    # loaded managed/closure phases. Keep those responsibilities inline until
    # another consumer or an explicit evidence declaration appears.
    MANAGED_PRESSURE=0
    CLOSURE_PRESSURE=0
  fi

  if [[ -d "$TARGET/.github/workflows" ]] || [[ -d "$TARGET/.buildkite" ]] ||
     [[ -d "$TARGET/.circleci" ]] || [[ -d "$TARGET/scripts" ]] ||
     [[ -f "$TARGET/Makefile" ]] || [[ -f "$TARGET/package.json" ]]; then
    VALIDATION_PRESSURE=1
  fi
  if [[ -f "$TARGET/UPSTREAM-CHANGES.md" || -f "$TARGET/.upstream-sync" ||
        -f "$TARGET/skills/$NAME/.upstream-sync" || -f "$TARGET/skills/$NAME/sync-manifest.yaml" ||
        "$TASK_UPSTREAM" -eq 1 ]]; then
    UPSTREAM_PRESSURE=1
  fi
  if [[ -f "$TARGET/.sba/evidence.yaml" || -f "$TARGET/.sba/materialization.yaml" ||
        -f "$TARGET/sba-evidence.yaml" || -f "$TARGET/SBA-EVIDENCE.md" ]]; then
    local evidence
    for evidence in .sba/evidence.yaml .sba/materialization.yaml sba-evidence.yaml SBA-EVIDENCE.md; do
      [[ -f "$TARGET/$evidence" ]] || continue
      grep -Eiq 'shared[_ -]?routing|multiple[_ -]?routes|routing[[:space:]_-]*source' "$TARGET/$evidence" && SHARED_ROUTING_DECLARED=1 || true
      grep -Eiq 'managed[_ -]?execution|task[_ -]?anchor|pause[_ -]?resume|decision[_ -]?drift' "$TARGET/$evidence" && MANAGED_PRESSURE=1 || true
      grep -Eiq 'closure|AAR|external[_ -]?delivery|completion' "$TARGET/$evidence" && CLOSURE_PRESSURE=1 || true
      grep -Eiq 'upstream|vendor|sync[_ -]?manifest' "$TARGET/$evidence" && UPSTREAM_PRESSURE=1 || true
      grep -Eiq 'team[_ -]?harness|multi[_ -]?harness|claude|cursor|codex|gemini' "$TARGET/$evidence" && TEAM_HARNESS_DECLARED=1 || true
      grep -Eiq 'full[_ -]?runtime|broad[_ -]?maintenance|author[_ -]?maintenance' "$TARGET/$evidence" && EXPLICIT_BROAD_PRESSURE=1 || true
      grep -Eiq 'external[_ -]?write|database|deploy|publish[_ -]?config|configuration[_ -]?center|shared[_ -]?(system|service|environment)' "$TARGET/$evidence" && EXTERNAL_WRITE_PRESSURE=1 || true
    done
  fi

  if [[ "$TASK_SIGNAL_COUNT" -ge 2 || "$HARNESS_COUNT" -ge 2 || "$TEAM_HARNESS_DECLARED" -eq 1 ]]; then
    WORKFLOW_PRESSURE=1
  fi

  # Independent pressures, rather than a fixed file count, decide the physical
  # carrier.  Line count is only a supporting signal for a growing single file;
  # it is never sufficient to claim semantic completeness.
  if [[ "$TASK_SIGNAL_COUNT" -ge 3 ||
        ("$HARNESS_COUNT" -ge 3 && "$WORKFLOW_PRESSURE" -eq 1) ||
        ("$MANAGED_PRESSURE" -eq 1 && "$CLOSURE_PRESSURE" -eq 1) ||
        ("$UPSTREAM_PRESSURE" -eq 1 && "$VALIDATION_PRESSURE" -eq 1) ||
        "$EXPLICIT_BROAD_PRESSURE" -eq 1 ]]; then
    MATERIALIZATION="broad"
  elif [[ "$EXTERNAL_WRITE_PRESSURE" -eq 1 || "$WORKFLOW_PRESSURE" -eq 1 || "$INSTRUCTION_LINES" -ge 60 ||
          "$TASK_SIGNAL_COUNT" -ge 1 ]]; then
    MATERIALIZATION="folder"
  else
    MATERIALIZATION="direct"
  fi

  if [[ "$MATERIALIZATION" != "direct" &&
        ("$TASK_SIGNAL_COUNT" -ge 2 || ("$HARNESS_COUNT" -ge 2 && "$TASK_SIGNAL_COUNT" -ge 1) || "$SHARED_ROUTING_DECLARED" -eq 1) ]]; then
    ROUTED=1
  else
    ROUTED=0
  fi
  if [[ "$MATERIALIZATION" == "broad" ]]; then
    ROUTED=1
    if [[ "$TASK_SIGNAL_COUNT" -ge 3 ]]; then
      MANAGED_PRESSURE=1
      CLOSURE_PRESSURE=1
    fi
  fi
}

inventory_target() {
  inventory_entries
  inventory_content_pressure
  inventory_harnesses
  INSTRUCTION_COUNT=${#INSTRUCTION_FILES[@]}
}

apply_session_evidence() {
  [[ "$EVIDENCE_PRESENT" -eq 1 ]] || return 0

  # A supplied session manifest is the Agent's evidence-backed decision input;
  # do not let broad keyword matches from a README silently widen it.
  TASK_BUG=0
  TASK_CHANGE=0
  TASK_REFACTOR=0
  TASK_PLAN=0
  TASK_REVIEW=0
  TASK_RULE=0
  TASK_UPSTREAM=0
  TASK_SIGNAL_COUNT=${#EVIDENCE_TASK_IDS[@]}
  WORKFLOW_PRESSURE=0
  HARNESS_COUNT=0
  MANAGED_PRESSURE=0
  CLOSURE_PRESSURE=0
  GOTCHA_PRESSURE=0
  UPSTREAM_PRESSURE=0
  VALIDATION_PRESSURE=0
  SHARED_ROUTING_DECLARED=0
  EXPLICIT_BROAD_PRESSURE=0
  EXTERNAL_WRITE_PRESSURE=0

  MANAGED_PRESSURE="$EVIDENCE_MANAGED_PRESSURE"
  CLOSURE_PRESSURE="$EVIDENCE_CLOSURE_PRESSURE"
  VALIDATION_PRESSURE="$EVIDENCE_VALIDATION_PRESSURE"
  UPSTREAM_PRESSURE="$EVIDENCE_UPSTREAM_PRESSURE"
  GOTCHA_PRESSURE="$EVIDENCE_GOTCHA_PRESSURE"
  SHARED_ROUTING_DECLARED="$EVIDENCE_SHARED_ROUTING"
  EXPLICIT_BROAD_PRESSURE="$EVIDENCE_BROAD_PRESSURE"
  EXTERNAL_WRITE_PRESSURE="$EVIDENCE_EXTERNAL_WRITE_PRESSURE"

  NEED_AGENTS=1
  NEED_CLAUDE=0
  NEED_CODEX=0
  NEED_GEMINI=0
  NEED_CURSOR=0

  local index id harness
  for index in ${!EVIDENCE_TASK_IDS[@]}; do
    id="${EVIDENCE_TASK_IDS[$index]}"
    case "$id" in
      fix-bug) TASK_BUG=1 ;;
      change-managed) TASK_CHANGE=1 ;;
      refactor-fanout) TASK_REFACTOR=1 ;;
      plan-feature) TASK_PLAN=1 ;;
      receiving-review) TASK_REVIEW=1 ;;
      update-rules) TASK_RULE=1 ;;
      update-upstream) TASK_UPSTREAM=1 ;;
    esac
    [[ "${EVIDENCE_TASK_MANAGED[$index]}" == "1" ]] && MANAGED_PRESSURE=1
    [[ "${EVIDENCE_TASK_CLOSURE[$index]}" == "1" ]] && CLOSURE_PRESSURE=1
    [[ "${EVIDENCE_TASK_GOTCHA[$index]}" == "1" ]] && GOTCHA_PRESSURE=1
    [[ "${EVIDENCE_TASK_UPSTREAM[$index]}" == "1" ]] && UPSTREAM_PRESSURE=1
  done
  for harness in ${EVIDENCE_HARNESSES[@]+"${EVIDENCE_HARNESSES[@]}"}; do
    case "$harness" in
      agents) NEED_AGENTS=1 ;;
      claude) NEED_CLAUDE=1 ;;
      codex) NEED_CODEX=1 ;;
      gemini) NEED_GEMINI=1 ;;
      cursor) NEED_CURSOR=1 ;;
    esac
    HARNESS_COUNT=$((HARNESS_COUNT + 1))
  done
  [[ "$TASK_SIGNAL_COUNT" -ge 2 ]] && WORKFLOW_PRESSURE=1
  [[ "$TASK_SIGNAL_COUNT" -ge 2 || "$SHARED_ROUTING_DECLARED" -eq 1 ]] && ROUTED=1 || ROUTED=0
  if [[ "$TASK_SIGNAL_COUNT" -ge 3 || ("$MANAGED_PRESSURE" -eq 1 && "$CLOSURE_PRESSURE" -eq 1) || "$EXPLICIT_BROAD_PRESSURE" -eq 1 ]]; then
    MATERIALIZATION="broad"
  elif [[ "$EXTERNAL_WRITE_PRESSURE" -eq 1 || "$TASK_SIGNAL_COUNT" -ge 1 || "$WORKFLOW_PRESSURE" -eq 1 ]]; then
    MATERIALIZATION="folder"
  else
    MATERIALIZATION="direct"
  fi
  # Keep the function's return status successful for the common fitted
  # Folder-light case.  Under `set -e`, leaving a false `[[ ... ]] && ...`
  # as the final command makes the caller treat a valid evidence plan as a
  # materializer failure.
  if [[ "$MATERIALIZATION" == "broad" ]]; then
    ROUTED=1
  fi
}

# ── 2. Derive owners and path plan ───────────────────────────────────

ROUTED=0
MATERIALIZATION="direct"
PLAN_PATHS=()

add_plan_path() {
  local path="$1" item
  if [[ ${#PLAN_PATHS[@]} -gt 0 ]]; then
    for item in "${PLAN_PATHS[@]}"; do [[ "$item" == "$path" ]] && return; done
  fi
  PLAN_PATHS+=("$path")
}

planned_path() {
  local wanted="$1" item
  if [[ ${#PLAN_PATHS[@]} -gt 0 ]]; then
    for item in "${PLAN_PATHS[@]}"; do
      [[ "$item" == "$wanted" ]] && return 0
    done
  fi
  return 1
}

route_for_signal() {
  local id="$1"
  append_unique ROUTE_IDS "$id"
}

derive_routes() {
  ROUTE_IDS=()
  if [[ "$MATERIALIZATION" == "direct" ]]; then return; fi
  if [[ "$EVIDENCE_PRESENT" -eq 1 ]]; then
    local evidence_id
    for evidence_id in ${EVIDENCE_TASK_IDS[@]+"${EVIDENCE_TASK_IDS[@]}"}; do
      route_for_signal "$evidence_id"
    done
    [[ ${#ROUTE_IDS[@]} -gt 0 ]] || route_for_signal change-managed
    return
  fi
  [[ "$TASK_BUG" -eq 1 ]] && route_for_signal fix-bug
  [[ "$TASK_CHANGE" -eq 1 ]] && route_for_signal change-managed
  [[ "$TASK_REFACTOR" -eq 1 ]] && route_for_signal refactor-fanout
  [[ "$TASK_PLAN" -eq 1 ]] && route_for_signal plan-feature
  [[ "$TASK_REVIEW" -eq 1 ]] && route_for_signal receiving-review
  [[ "$TASK_RULE" -eq 1 ]] && route_for_signal update-rules
  [[ "$TASK_UPSTREAM" -eq 1 ]] && route_for_signal update-upstream
  if [[ ${#ROUTE_IDS[@]} -eq 0 ]]; then route_for_signal change-managed; fi
}

derive_plan() {
  PLAN_PATHS=()
  add_plan_path "skills/$NAME/SKILL.md"

  # AGENTS is the only no-evidence floor. Other shells/registrations are
  # admitted only when an existing reader, config, current harness, or team
  # declaration makes them useful.
  [[ "$NEED_AGENTS" -eq 1 ]] && add_plan_path AGENTS.md
  [[ "$NEED_CLAUDE" -eq 1 ]] && add_plan_path CLAUDE.md
  [[ "$NEED_CODEX" -eq 1 ]] && add_plan_path CODEX.md
  [[ "$NEED_GEMINI" -eq 1 ]] && add_plan_path GEMINI.md
  if [[ "$NEED_CURSOR" -eq 1 ]]; then
    add_plan_path ".cursor/skills/$NAME/SKILL.md"
    [[ "$ROUTED" -eq 1 ]] && add_plan_path .cursor/rules/workflow.mdc
  fi

  if [[ "$MATERIALIZATION" == "direct" ]]; then
    return
  fi

  if [[ "$MATERIALIZATION" == "folder" ]]; then
    add_plan_path "skills/$NAME/rules/project-rules.md"
    add_plan_path "skills/$NAME/rules/coding-standards.md"
    if [[ ("$WORKFLOW_PRESSURE" -eq 1 || "$TASK_SIGNAL_COUNT" -ge 1) && "$ROUTED" -eq 0 ]]; then
      add_plan_path "skills/$NAME/workflows/project-task.md"
    fi
    if [[ "$ROUTED" -eq 1 ]]; then
      add_plan_path "skills/$NAME/routing.yaml"
      add_plan_path "skills/$NAME/scripts/sync-routing.sh"
      local route_id
      for route_id in ${ROUTE_IDS[@]+"${ROUTE_IDS[@]}"}; do
        add_plan_path "skills/$NAME/workflows/$route_id.md"
      done
      add_plan_path "skills/$NAME/workflows/other.md"
    fi
    return
  fi

  # Broad runtime pressure starts from the canonical full SKILL carrier but
  # still admits task owners by evidence; it does not blindly copy every route.
  add_plan_path "skills/$NAME/routing.yaml"
  add_plan_path "skills/$NAME/rules/project-rules.md"
  add_plan_path "skills/$NAME/rules/coding-standards.md"
  add_plan_path "skills/$NAME/rules/change-discipline.md"
  add_plan_path "skills/$NAME/scripts/sync-routing.sh"
  add_plan_path "skills/$NAME/scripts/smoke-test.sh"
  add_plan_path "skills/$NAME/scripts/audit-orphans.sh"
  add_plan_path "skills/$NAME/scripts/route-reachability.sh"
  add_plan_path "skills/$NAME/scripts/route-health.sh"
  local broad_route
  for broad_route in ${ROUTE_IDS[@]+"${ROUTE_IDS[@]}"}; do
    add_plan_path "skills/$NAME/workflows/$broad_route.md"
  done
  add_plan_path "skills/$NAME/workflows/other.md"
  [[ "$MANAGED_PRESSURE" -eq 1 ]] && add_plan_path "skills/$NAME/workflows/task-execution.md"
  [[ "$CLOSURE_PRESSURE" -eq 1 ]] && add_plan_path "skills/$NAME/workflows/task-closure.md"
  if [[ "$VALIDATION_PRESSURE" -eq 1 ]]; then
    add_plan_path "skills/$NAME/conformance.yaml"
    add_plan_path "skills/$NAME/scripts/check-version-conformance.sh"
  fi
  if [[ "$UPSTREAM_PRESSURE" -eq 1 ]]; then
    add_plan_path "skills/$NAME/scripts/sync-vendor.sh"
    add_plan_path "skills/$NAME/scripts/upstream-status.sh"
    add_plan_path "skills/$NAME/sync-manifest.yaml"
    add_plan_path "skills/$NAME/.upstream-sync"
  fi
  if [[ "$TASK_SIGNAL_COUNT" -ge 1 ]]; then
    add_plan_path "skills/$NAME/references/gotchas.md"
  fi
}

# ── 3. Stage selected owners ─────────────────────────────────────────

stage_copy() {
  local source_rel="$1" destination_rel="$2"
  local source="$ROOT/templates/skill/$source_rel"
  [[ -f "$source" ]] || { echo "FAIL: canonical template missing: $source_rel" >&2; return 1; }
  mkdir -p "$(dirname "$stage/skills/$NAME/$destination_rel")"
  cp "$source" "$stage/skills/$NAME/$destination_rel"
}

stage_copy_root_template() {
  local source_rel="$1" destination_rel="$2"
  local source="$ROOT/templates/$source_rel"
  [[ -f "$source" ]] || { echo "FAIL: canonical shell template missing: $source_rel" >&2; return 1; }
  mkdir -p "$(dirname "$stage/$destination_rel")"
  cp "$source" "$stage/$destination_rel"
}

render_shells() {
  local shell_path harness source
  for shell_path in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
    case "$shell_path" in
      AGENTS.md) [[ "$NEED_AGENTS" -eq 1 ]] || continue; harness="AGENTS.md" ;;
      CLAUDE.md) [[ "$NEED_CLAUDE" -eq 1 ]] || continue; harness="CLAUDE.md" ;;
      CODEX.md) [[ "$NEED_CODEX" -eq 1 ]] || continue; harness="CODEX.md" ;;
      GEMINI.md) [[ "$NEED_GEMINI" -eq 1 ]] || continue; harness="GEMINI.md" ;;
    esac
    if [[ "$ROUTED" -eq 1 ]]; then
      stage_copy_root_template "shells/$harness" "$shell_path"
    else
      stage_copy_root_template "shells/single-entry.md.template" "$shell_path"
      perl -0pi -e "s/\\{\\{HARNESS\\}\\}/$harness/g" "$stage/$shell_path"
    fi
  done

  [[ "$NEED_CURSOR" -eq 1 ]] || return 0
  render_cursor_registration "$stage/.cursor/skills/$NAME/SKILL.md"
  if [[ "$ROUTED" -eq 1 ]]; then
    stage_copy_root_template "shells/.cursor/rules/workflow.mdc" ".cursor/rules/workflow.mdc"
  fi
}

render_cursor_registration() {
  local destination="$1" description_block
  mkdir -p "$(dirname "$destination")"
  description_block="$(awk '
    BEGIN { frontmatter = 0; capture = 0 }
    /^---[[:space:]]*$/ {
      if (frontmatter == 0) { frontmatter = 1; next }
      if (capture == 1) exit
    }
    frontmatter == 1 && /^description:[[:space:]]*/ { capture = 1; print; next }
    capture == 1 {
      if ($0 ~ /^[[:space:]]+/ || $0 == "") { print; next }
      exit
    }
  ' "$stage/skills/$NAME/SKILL.md")"
  [[ -n "$description_block" ]] || {
    echo "FAIL: formal SKILL.md is missing a description field" >&2
    return 1
  }
  cat > "$destination" <<EOF
---
name: $NAME
$description_block
---

# $NAME (Cursor Entry)

Formal project rules live at \`skills/$NAME/SKILL.md\`. Read that file before
acting; it is the sole semantic owner. This registration contains no duplicate
route or rule body.
EOF
  if [[ "$ROUTED" -eq 1 ]]; then
    cat >> "$destination" <<EOF

## Quick Routing

<!-- ROUTING_BOOTSTRAP_START -->
Task routes live in \`skills/$NAME/routing.yaml\`.

For every new task:
1. Read \`skills/$NAME/routing.yaml\`.
2. Match exactly one task route by labels, trigger examples, and task intent;
   if none matches, use \`other\`.
3. Follow only that route's workflow; the task route does not preload knowledge.
4. Let the workflow inspect the smallest evidence that can decide the next action.
<!-- ROUTING_BOOTSTRAP_END -->
EOF
  else
    cat >> "$destination" <<EOF

Follow the direct Common Tasks procedure in \`skills/$NAME/SKILL.md\`; this
small project has no independent routing manifest.
EOF
  fi
}

render_skill_direct() {
  local destination="$stage/skills/$NAME/SKILL.md"
  mkdir -p "$(dirname "$destination")"
  cat > "$destination" <<EOF
---
name: $NAME
description: >
  This skill should be used when the user asks to "work on $NAME",
  "maintain $NAME", or "处理 $NAME 任务". Activate when the request concerns
  $SUMMARY.
primary: true
---

# $NAME

$SUMMARY

## Always Read

Read the smallest project evidence that can decide the next action. No
separate knowledge file is universal for this Single-file project.
$(if [[ ${#PRESERVE_FILES[@]} -gt 0 ]]; then for preserved in "${PRESERVE_FILES[@]}"; do printf '%s\n' "- Existing migration source: $preserved remains preserved until its meaning has a mapped or excluded disposition."; done; fi)

## Common Tasks

- Project task: inspect the relevant evidence, make one risk-sized change or
  check, and run the repository-owned verification before reporting the result.
- Requirement-bearing change: first reach \`requirement-ready\`; if desired
  meaning is incomplete, state the current understanding and real conflict and
  ask only the minimum normative question. Project Goal, Done When, and material
  Boundaries into a Task Anchor, prove the current owner and Current -> Target
  until \`implementation-ready\`, and only then derive an implementation Plan,
  mutate, and prove the Requirement's observable acceptance.
- Other: identify the nearest project rule, keep the change minimal, and state
  any unresolved evidence instead of guessing.

## Completion

Report the requested result only after its fitted check and terminal state are
verified. A successful command, commit, push, or readiness state is not a
substitute for the requested outcome.

## Recovery

After interruption or compaction, recover the current request and the last
verified boundary before acting. A later independent request is re-evaluated;
it does not silently chain another workflow.

## Project Boundaries

- Owns the project-scoped rules and the direct task procedure admitted here.
- Does not own unrelated repositories, historical tasks, credentials, or
  implicit follow-up delivery.
EOF
}

render_skill_folder_direct() {
  local destination="$stage/skills/$NAME/SKILL.md"
  mkdir -p "$(dirname "$destination")"
  cat > "$destination" <<EOF
---
name: $NAME
description: >
  This skill should be used when the user asks to "work on $NAME",
  "maintain $NAME", or "处理 $NAME 任务". Activate when the request concerns
  $SUMMARY.
primary: true
---

# $NAME

$SUMMARY

## Always Read

- Read [project rules](rules/project-rules.md) before a change when they can
  affect the next action.
$(if [[ ${#PRESERVE_FILES[@]} -gt 0 ]]; then for preserved in "${PRESERVE_FILES[@]}"; do printf '%s\n' "- Existing migration source: $preserved remains preserved until its meaning has a mapped or excluded disposition."; done; fi)

## Common Tasks

- Project task: follow [the project procedure](workflows/project-task.md), run
  its fitted check, and report only the requested terminal result.
- Other: inspect the smallest relevant evidence, then use the same procedure
  or stop with the unresolved decision clearly stated.

## Known Gotchas

No recurring gotcha owner has been admitted yet; add one only after a real,
repeatable failure and an activation path exist.

## Project Boundaries

- Owns the project-scoped rules and one recurring procedure admitted here.
- Does not own unrelated repositories, historical tasks, credentials, or
  implicit follow-up delivery.
EOF
}

render_skill_routed() {
  local destination="$stage/skills/$NAME/SKILL.md"
  mkdir -p "$(dirname "$destination")"
  cat > "$destination" <<EOF
---
name: $NAME
description: >
  This skill should be used when the user asks to "work on $NAME",
  "maintain $NAME", or "处理 $NAME 任务". Activate when the request concerns
  $SUMMARY.
primary: true
---

# $NAME

$SUMMARY

<always-applicable>

## Always Read

<!-- ALWAYS_READ_START -->
None by default; workflows load knowledge at evidence and phase boundaries.
<!-- ALWAYS_READ_END -->
$(if [[ ${#PRESERVE_FILES[@]} -gt 0 ]]; then for preserved in "${PRESERVE_FILES[@]}"; do printf '%s\n' "- Existing migration source: $preserved remains preserved until its meaning has a mapped or excluded disposition."; done; fi)

## Session Discipline

For every new task, read [routing.yaml](routing.yaml), match exactly one route,
and follow only its workflow. After interruption or compaction, recover the
current workflow and decision-relevant evidence before acting.

Requirement-bearing routes preserve this order: \`requirement-ready\` -> Task
Anchor -> proven Current -> Target and \`implementation-ready\` -> Native Plan ->
mutation/proof. A clear Requirement needs no ceremonial confirmation; an
incomplete one stops with current understanding, real risk/conflict, and the
minimum normative question.

</always-applicable>

<task-routing>

## Common Tasks

<!-- ROUTING_SUMMARY_START -->
- Read [routing.yaml](routing.yaml), match one project route by intent, and
  fall back to \`other\` when no route matches.
<!-- ROUTING_SUMMARY_END -->

</task-routing>

## Known Gotchas

No recurring gotcha owner is loaded unless the current evidence selects one.

## Project Boundaries

- Owns the admitted project routes, procedures, rules, and fitted checks.
- Does not own unrelated repositories, historical tasks, credentials, or
  implicit follow-up delivery.
EOF
  if planned_path "skills/$NAME/workflows/task-execution.md"; then
    cat >> "$destination" <<'EOF'

For dependent, interrupted, or decision-drift work, read the [Managed Task
Execution owner](workflows/task-execution.md) before the next main step.
EOF
  fi
  if planned_path "skills/$NAME/workflows/task-closure.md"; then
    cat >> "$destination" <<'EOF'

When a changing task reaches its completion boundary, read the [Task Closure
owner](workflows/task-closure.md) and verify its terminal result.
EOF
  fi
}

render_project_rules() {
  local destination="$stage/skills/$NAME/rules/project-rules.md"
  mkdir -p "$(dirname "$destination")"
  cat > "$destination" <<EOF
# Project Rules

These rules govern the project scope summarized in \`skills/$NAME/SKILL.md\`.

- Preserve existing project instruction meaning until each source clause has
  an evidence-backed destination or explicit exclusion.
- Make the smallest change that satisfies the selected task and verify it at
  the repository-owned boundary.
- Do not expand completion to historical tasks, adjacent repositories, or
  implicit follow-up delivery.
EOF
  if [[ "$EXTERNAL_WRITE_PRESSURE" -eq 1 ]]; then
    cat >> "$destination" <<'EOF'
- Task scope does not automatically grant external write authority for databases, deployments, configuration, or shared systems; obtain explicit authorization before performing such writes.
EOF
  fi
}

render_coding_standards() {
  local destination="$stage/skills/$NAME/rules/coding-standards.md"
  mkdir -p "$(dirname "$destination")"
  cat > "$destination" <<'EOF'
# Coding Standards

- Keep changes local to the smallest owner that can preserve the invariant.
- Use the repository's existing formatter, linter, and test commands when
  evidence identifies them; do not invent a framework or threshold.
- Comment non-obvious ownership, failure, and recovery boundaries only.
EOF
}

render_gotchas() {
  [[ "$GOTCHA_PRESSURE" -eq 1 ]] || return 0
  local destination="$stage/skills/$NAME/references/gotchas.md"
  mkdir -p "$(dirname "$destination")"
  cat > "$destination" <<EOF
# Observed Gotchas

The source inventory contains a recurring pitfall signal. Before adding a
project-specific entry, reproduce the symptom and record its cause, boundary,
and fitted verification here; do not fill this file with generic advice.
EOF
}

render_light_workflow() {
  local destination="$1" title="$2"
  mkdir -p "$(dirname "$stage/skills/$NAME/$destination")"
  cat > "$stage/skills/$NAME/$destination" <<EOF
# $title

## Use When

Use this procedure when the selected route or the project's existing evidence
matches this task. Keep the route-specific facts in the owning project files.

## Procedure

1. Read the smallest project evidence that can decide the next action.
2. For a request that changes desired behavior, first reach
   \`requirement-ready\`. Clear wording needs no additional confirmation; when a
   normative choice remains, state the current understanding and real
   risk/conflict, ask only the minimum question, and stop before planning or
   mutation.
3. Project Goal, Done When, and material Boundaries into a Task Anchor. Prove
   the current owner, Current -> Target, affected path, and material risks until
   \`implementation-ready\`.
4. Only then derive the implementation Plan, make one risk-sized change or
   check, and run the repository-owned fitted validation command.
5. If evidence contradicts desired meaning, return to Requirement Definition;
   if it changes technical ownership, re-localize instead of widening scope.

## Completion

Verify the requested terminal result itself, report the exact check and any
remaining uncertainty, and stop. A successful command, commit, push, or
readiness state is not the requested result unless explicitly asked for it.
EOF
  if [[ "$MATERIALIZATION" == "broad" ]]; then
    cat >> "$stage/skills/$NAME/$destination" <<'EOF'

## Shared Owners

Read [Change Discipline](../rules/change-discipline.md) immediately before the
first mutation.
EOF
    if planned_path "skills/$NAME/workflows/task-execution.md"; then
      cat >> "$stage/skills/$NAME/$destination" <<'EOF'
Read [Managed Task Execution](task-execution.md) only for dependent,
interrupted, or decision-drift work.
EOF
    fi
    if planned_path "skills/$NAME/workflows/task-closure.md"; then
      cat >> "$stage/skills/$NAME/$destination" <<'EOF'
Read [Task Closure](task-closure.md) only when a changing task reaches its
completion boundary.
EOF
    fi
    if [[ "$GOTCHA_PRESSURE" -eq 1 ]]; then
      echo 'When evidence matches the observed pitfall, read `../references/gotchas.md`.' >> "$stage/skills/$NAME/$destination"
    fi
  fi
}

render_requirement_workflow() {
  local destination="$1" title="$2"
  mkdir -p "$(dirname "$stage/skills/$NAME/$destination")"
  cat > "$stage/skills/$NAME/$destination" <<EOF
# $title

## Use When

Use this procedure when the requested result is to discuss, brainstorm,
clarify, correct, or confirm desired behavior before implementation planning.

## Requirement Definition

1. Preserve clear user wording and its authority. Evaluate only dimensions that
   can change this result: goal; scope, non-goals, and preservation;
   decision-bearing model/flow/state/order/interaction; rules and constraints;
   and observable, falsifiable acceptance. This is not a fixed questionnaire.
2. Inspect only the smallest project evidence that can resolve the current
   uncertainty. Discover Current owners, paths, behavior, feasibility, cost,
   and risk from the project instead of asking the user for technical facts.
3. Separate confirmed desired meaning, Current facts, assumptions, real
   risks/conflicts, and remaining normative choices. Code may falsify a premise
   but cannot choose desired product meaning.
4. If every activated user-owned choice is closed, return
   \`requirement-ready\` without another confirmation turn. Otherwise present the
   current understanding, name the real risk/conflict, ask the minimum normative
   question, and stop.
5. Discuss one load-bearing normative topic at a time. When it is unresolved,
   include current understanding, decisive evidence/constraints, material
   risk/trade-off, the Agent recommendation, and at most one minimum question;
   when it is clear, ask none.

## Boundary

Acceptance belongs to the Requirement; tests, browser/runtime checks, and human
review are later proof choices. This procedure does not produce an
implementation Plan, Task Breakdown, code mutation, or proof command. Keep the
Requirement Session-only by default. Create or update the smallest Governing
Requirement only when the user explicitly requests a Requirement/PRD artifact,
or an independent reader, review, recovery, validator, lifecycle, or handoff
needs it; first prove the real project code root and local archive contract.
Complexity and activity alone are not pressure. A later Plan links this owner
one way and cannot copy, narrow, resolve, or update it.
EOF
}

render_plan_workflow() {
  local destination="$1" title="$2"
  mkdir -p "$(dirname "$stage/skills/$NAME/$destination")"
  cat > "$stage/skills/$NAME/$destination" <<EOF
# $title

## Use When

Use this procedure to derive an implementation Plan from an already confirmed
Requirement. Desired-behavior discussion returns to Requirement Definition.

## Planning Sequence

1. Consume a named \`requirement-ready\` source without rewriting its goal,
   scope, flow/model, rules/constraints, preservation, or acceptance.
2. Project Goal, Done When, and material Boundaries into a Task Anchor.
3. Prove the canonical owner, Current behavior, Current -> Target, affected
   path, and material technical risks from project evidence.
4. Reach \`implementation-ready\` before deriving technical options, Task
   Interfaces, implementation order, or proof commands.
5. Map Requirement acceptance to the cheapest truthful proof, then return the
   implementation Plan. If a test needs an unstated expected result, return that
   question to Requirement Definition.

## Boundary

The Plan is a revisable implementation means and does not execute mutation.
Ordinary planning creates no persistent artifact unless explicit handoff,
review, recovery, conflict, or lifecycle pressure requires one.
Requirement-only artifact delivery stays in Requirement Definition.
Any durable implementation Plan is a separate one-way consumer under the local archive contract.
It never stores technical Plan content or lifecycle state in the Governing Requirement file.
EOF
}

route_metadata() {
  local id="$1" index
  ROUTE_LABEL_EN="Project task"
  ROUTE_LABEL_ZH="项目任务"
  ROUTE_TRIGGER_EN="work on $NAME"
  ROUTE_TRIGGER_ZH="处理 $NAME 任务"
  case "$id" in
    fix-bug) ROUTE_LABEL_EN="Fix project bugs"; ROUTE_LABEL_ZH="修复项目问题"; ROUTE_TRIGGER_EN="fix a bug in $NAME"; ROUTE_TRIGGER_ZH="修复 $NAME 的问题" ;;
    change-managed) ROUTE_LABEL_EN="Change project behavior"; ROUTE_LABEL_ZH="修改项目行为"; ROUTE_TRIGGER_EN="change $NAME behavior"; ROUTE_TRIGGER_ZH="修改 $NAME 的功能" ;;
    define-requirement) ROUTE_LABEL_EN="Define project requirements"; ROUTE_LABEL_ZH="定义或澄清项目需求"; ROUTE_TRIGGER_EN="clarify the desired $NAME behavior"; ROUTE_TRIGGER_ZH="先讨论 $NAME 的需求" ;;
    refactor-fanout) ROUTE_LABEL_EN="Refactor project usage"; ROUTE_LABEL_ZH="重构项目用法"; ROUTE_TRIGGER_EN="refactor $NAME usage"; ROUTE_TRIGGER_ZH="重构 $NAME 的调用" ;;
    plan-feature) ROUTE_LABEL_EN="Plan confirmed requirement implementation"; ROUTE_LABEL_ZH="规划已确认需求的实现"; ROUTE_TRIGGER_EN="plan the confirmed $NAME requirement"; ROUTE_TRIGGER_ZH="基于已确认需求规划 $NAME 实现" ;;
    receiving-review) ROUTE_LABEL_EN="Handle project review"; ROUTE_LABEL_ZH="处理项目评审"; ROUTE_TRIGGER_EN="review the $NAME change"; ROUTE_TRIGGER_ZH="处理 $NAME 的评审意见" ;;
    update-rules) ROUTE_LABEL_EN="Update project rules"; ROUTE_LABEL_ZH="更新项目规则"; ROUTE_TRIGGER_EN="update $NAME rules"; ROUTE_TRIGGER_ZH="更新 $NAME 规则" ;;
    update-upstream) ROUTE_LABEL_EN="Refresh project from upstream"; ROUTE_LABEL_ZH="同步项目上游"; ROUTE_TRIGGER_EN="refresh $NAME from upstream"; ROUTE_TRIGGER_ZH="同步 $NAME 上游" ;;
  esac
  if [[ "$EVIDENCE_PRESENT" -eq 1 && ${#EVIDENCE_TASK_IDS[@]} -gt 0 ]]; then
    for index in "${!EVIDENCE_TASK_IDS[@]}"; do
      if [[ "${EVIDENCE_TASK_IDS[$index]}" == "$id" ]]; then
        ROUTE_LABEL_EN="${EVIDENCE_TASK_LABEL_EN[$index]}"
        ROUTE_LABEL_ZH="${EVIDENCE_TASK_LABEL_ZH[$index]}"
        ROUTE_TRIGGER_EN="${EVIDENCE_TASK_TRIGGER_EN[$index]}"
        ROUTE_TRIGGER_ZH="${EVIDENCE_TASK_TRIGGER_ZH[$index]}"
        break
      fi
    done
  fi
}

render_routing() {
  [[ "$ROUTED" -eq 1 ]] || return 0
  mkdir -p "$stage/skills/$NAME"
  {
    echo "# Evidence-selected route owner. This session's admitted task evidence owns the rows below."
    echo "always_read: []"
    echo "tasks:"
    local id workflow
    for id in ${ROUTE_IDS[@]+"${ROUTE_IDS[@]}"}; do
      route_metadata "$id"
      workflow="workflows/$id.md"
      echo "  - id: $id"
      echo "    labels: { en: \"$(yaml_quote "$ROUTE_LABEL_EN")\", zh: \"$(yaml_quote "$ROUTE_LABEL_ZH")\" }"
      echo "    workflow: $workflow"
      echo "    trigger_examples:"
      echo "      - \"$(yaml_quote "$ROUTE_TRIGGER_EN")\""
      echo "      - \"$(yaml_quote "$ROUTE_TRIGGER_ZH")\""
    done
    local fallback_workflow="workflows/other.md"
    echo "  - id: other"
    echo "    labels: { en: \"Other / unlisted task\", zh: \"其他 / 未列出的任务\" }"
    echo "    workflow: $fallback_workflow"
    echo "    trigger_examples:"
    echo "      - \"other project task\""
  } > "$stage/skills/$NAME/routing.yaml"
}

stage_selected_owners() {
  if [[ "$MATERIALIZATION" == "direct" ]]; then
    render_skill_direct
    return
  fi

  if [[ "$MATERIALIZATION" == "folder" ]]; then
    if [[ "$ROUTED" -eq 1 ]]; then
      render_skill_routed
    else
      render_skill_folder_direct
    fi
    render_project_rules
    render_coding_standards
    if [[ ("$WORKFLOW_PRESSURE" -eq 1 || "$TASK_SIGNAL_COUNT" -ge 1) && "$ROUTED" -eq 0 ]]; then
      render_light_workflow "workflows/project-task.md" "Project task procedure"
    fi
    if [[ "$ROUTED" -eq 1 ]]; then
      stage_copy "scripts/sync-routing.sh" "scripts/sync-routing.sh"
    fi
    return
  fi

  render_skill_routed
  render_project_rules
  render_coding_standards
  stage_copy "rules/change-discipline.md" "rules/change-discipline.md"
  stage_copy "scripts/sync-routing.sh" "scripts/sync-routing.sh"
  if [[ "$MANAGED_PRESSURE" -eq 1 ]]; then
    stage_copy "workflows/task-execution.materialized.md.template" "workflows/task-execution.md"
  fi
  if [[ "$CLOSURE_PRESSURE" -eq 1 ]]; then
    stage_copy "workflows/task-closure.materialized.md.template" "workflows/task-closure.md"
  fi
  render_gotchas
  stage_copy "scripts/smoke-test.sh" "scripts/smoke-test.sh"
  stage_copy "scripts/audit-orphans.sh" "scripts/audit-orphans.sh"
  stage_copy "scripts/route-reachability.sh" "scripts/route-reachability.sh"
  stage_copy "scripts/route-health.sh" "scripts/route-health.sh"
  if [[ "$VALIDATION_PRESSURE" -eq 1 ]]; then
    stage_copy "scripts/check-version-conformance.sh" "scripts/check-version-conformance.sh"
  fi
  if [[ "$UPSTREAM_PRESSURE" -eq 1 ]]; then
    stage_copy "scripts/sync-vendor.sh" "scripts/sync-vendor.sh"
    stage_copy "scripts/upstream-status.sh" "scripts/upstream-status.sh"
  fi

}

render_fitted_conformance() {
  [[ "$MATERIALIZATION" == "broad" && "$VALIDATION_PRESSURE" -eq 1 ]] || return 0
  local conformance="$stage/skills/$NAME/conformance.yaml"
  {
    echo "# Fitted content contract: only owners admitted by this evidence plan."
    if [[ "$EXTERNAL_WRITE_PRESSURE" -eq 1 ]]; then
      echo "# Fitted external-write responsibility: adopted"
    fi
    echo "required_files:"
    echo "  - path: SKILL.md"
    echo "    reason: Primary routed skill owner."
    echo "  - path: routing.yaml"
    echo "    reason: Evidence-selected route owner."
    local id
    for id in ${ROUTE_IDS[@]+"${ROUTE_IDS[@]}"}; do
      echo "  - path: workflows/$id.md"
      echo "    reason: Admitted task workflow."
    done
    echo "  - path: workflows/other.md"
    echo "    reason: Required fallback workflow."
    if [[ "$MANAGED_PRESSURE" -eq 1 ]]; then
      echo "  - path: workflows/task-execution.md"
      echo "    reason: Admitted managed-execution owner."
    fi
    if [[ "$CLOSURE_PRESSURE" -eq 1 ]]; then
      echo "  - path: workflows/task-closure.md"
      echo "    reason: Admitted completion owner."
    fi
  } > "$conformance"
  # Initial materialization and later upgrades use the same current checks.
  bash "$ROOT/scripts/render-fitted-conformance.sh" "$conformance" > "$conformance.refreshed"
  mv "$conformance.refreshed" "$conformance"
}

render_fitted_sync_manifest() {
  [[ "$MATERIALIZATION" == "broad" && "$UPSTREAM_PRESSURE" -eq 1 ]] || return 0
  local manifest="$stage/skills/$NAME/sync-manifest.yaml"
  {
    echo "# Project-owned vendor selection for upstream refresh; preserve this subset."
    echo "vendor:"
    echo "  - sync-manifest.yaml"
    echo "  - scripts/sync-vendor.sh"
    echo "  - scripts/upstream-status.sh"
    echo "  - scripts/smoke-test.sh"
    echo "  - scripts/sync-routing.sh"
    echo "  - scripts/audit-orphans.sh"
    echo "  - scripts/route-reachability.sh"
    echo "  - scripts/route-health.sh"
    if [[ "$VALIDATION_PRESSURE" -eq 1 ]]; then
      echo "  - scripts/check-version-conformance.sh"
    fi
  } > "$manifest"
}

render_direct_skill_links() {
  local skill="$stage/skills/$NAME/SKILL.md"
  [[ -f "$skill" ]] || return 0
  if [[ "$MATERIALIZATION" == "folder" ]]; then
    perl -0pi -e 's#- Main task:.*?(?=- Other:)#- Main task: follow [the project procedure](workflows/project-task.md), then run its fitted check.\n#s' "$skill"
  fi
}

replace_placeholders() {
  local escaped_name escaped_summary
  escaped_name="$(printf '%s' "$NAME" | sed 's/[\\&|]/\\&/g')"
  escaped_summary="$(printf '%s' "$SUMMARY" | sed 's/[\\&|]/\\&/g')"
  find "$stage" -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.yaml' -o -name '*.template' \) \
    -exec sed -i.bak \
      -e "s|{{NAME}}|$escaped_name|g" \
      -e "s|{{SUMMARY}}|$escaped_summary|g" \
      -e 's|{{HARNESS}}|Project harness|g' \
      {} +
  find "$stage" -name '*.bak' -type f -delete
  find "$stage" -type f -name '*.template' -exec sh -c 'for f do mv "$f" "${f%.template}"; done' sh {} +
}

assert_materialized_stage() {
  local hits templates
  templates="$(find "$stage" -type f \( -name '*.template' -o -name '*.md.template' -o -name '*.yaml.template' \) -print 2>/dev/null || true)"
  if [[ -n "$templates" ]]; then
    echo "FAIL: author-only template files remain in the materialized stage:" >&2
    echo "$templates" | sed 's/^/  /' >&2
    return 1
  fi
  hits="$(find "$stage" -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.yaml' \) ! -path '*/scripts/*' -exec grep -nHE 'FILL:|FILLED:|\{\{[^}]+\}\}|<trigger phrase|<condition [0-9]|<project-specific|<中文标签>|<中文触发' {} + 2>/dev/null || true)"
  if [[ -n "$hits" ]]; then
    echo "FAIL: unresolved materialization markers remain:" >&2
    echo "$hits" | sed 's/^/  /' >&2
    return 1
  fi
}

render_light_routes() {
  [[ "$ROUTED" -eq 1 ]] || return 0
  local id title destination
  for id in ${ROUTE_IDS[@]+"${ROUTE_IDS[@]}"}; do
    route_metadata "$id"
    title="$ROUTE_LABEL_EN"
    destination="workflows/$id.md"
    case "$id" in
      define-requirement) render_requirement_workflow "$destination" "$title" ;;
      plan-feature) render_plan_workflow "$destination" "$title" ;;
      update-upstream) stage_copy "workflows/update-upstream.md" "$destination" ;;
      *) render_light_workflow "$destination" "$title" ;;
    esac
  done
  render_light_workflow "workflows/other.md" "Other project task"
}

# ── 4. Preview / apply safety ─────────────────────────────────────────

hard_conflict=0
for path in "skills/$NAME" ".cursor/skills/$NAME"; do
  if has_path "$path"; then
    if [[ "$path" == ".cursor/skills/$NAME" && -f "$TARGET/.cursor/skills/$NAME/SKILL.md" && ! -f "$TARGET/skills/$NAME/SKILL.md" ]]; then
      echo "REVIEW: .cursor/skills/$NAME/SKILL.md (formal owner missing: skills/$NAME/SKILL.md; preserve registration until ownership is resolved)"
    fi
    echo "CONFLICT: $path already exists; inspect the current migration instead of rerunning"
    hard_conflict=1
  fi
done
for parent in skills .cursor .cursor/skills .cursor/rules; do
  if [[ -L "$TARGET/$parent" ]]; then
    echo "CONFLICT: $parent is a symlink; refusing to materialize through an unresolved parent" >&2
    hard_conflict=1
  fi
done
[[ "$hard_conflict" -eq 0 ]] || exit 2

load_session_evidence
inventory_target
apply_session_evidence
derive_routes
derive_plan

echo "EVIDENCE INVENTORY:"
echo "  evidence_files=$INSTRUCTION_COUNT preserved_entries=$ENTRY_COUNT source_lines=$INSTRUCTION_LINES recurring_signals=$TASK_SIGNAL_COUNT harness_signals=$HARNESS_COUNT"
echo "  workflow_pressure=$WORKFLOW_PRESSURE managed_execution_pressure=$MANAGED_PRESSURE closure_pressure=$CLOSURE_PRESSURE validation_pressure=$VALIDATION_PRESSURE upstream_pressure=$UPSTREAM_PRESSURE"
echo "  external_write_pressure=$EXTERNAL_WRITE_PRESSURE"
echo "DERIVED RESPONSIBILITIES: direct_route=$([[ "$ROUTED" -eq 0 ]] && echo yes || echo no) shared_routing=$([[ "$ROUTED" -eq 1 ]] && echo yes || echo no)"
echo "  managed_execution=$([[ "$MANAGED_PRESSURE" -eq 1 ]] && echo admitted || echo deferred) closure_owner=$([[ "$CLOSURE_PRESSURE" -eq 1 ]] && echo admitted || echo deferred)"

if [[ ${#PRESERVE_FILES[@]} -gt 0 ]]; then
  for path in "${PRESERVE_FILES[@]}"; do
    echo "PRESERVE: $path (Agent must migrate its meaning and keep the local shell hook)"
  done
fi
if [[ ${#REVIEW_REGISTRATIONS[@]} -gt 0 ]]; then
  for path in "${REVIEW_REGISTRATIONS[@]}"; do
    registry_root="${path%%/skills/*}"
    registration_name="${path#"$registry_root/skills/"}"
    registration_name="${registration_name%/SKILL.md}"
    echo "REVIEW: $path (formal owner missing: skills/$registration_name/SKILL.md; preserve registration until ownership is resolved)"
  done
fi

for path in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
  local_need=0
  case "$path" in
    AGENTS.md) local_need="$NEED_AGENTS" ;;
    CLAUDE.md) local_need="$NEED_CLAUDE" ;;
    CODEX.md) local_need="$NEED_CODEX" ;;
    GEMINI.md) local_need="$NEED_GEMINI" ;;
  esac
  if [[ "$local_need" -eq 1 ]] && ! has_path "$path"; then echo "CREATE: $path"; fi
done
if [[ "$NEED_CURSOR" -eq 1 ]]; then
  ! has_path ".cursor/skills/$NAME/SKILL.md" && echo "CREATE: .cursor/skills/$NAME/SKILL.md"
  if [[ "$ROUTED" -eq 1 ]] && ! has_path .cursor/rules/workflow.mdc; then
    echo "CREATE: .cursor/rules/workflow.mdc"
  fi
fi
for path in "${PLAN_PATHS[@]}"; do
  case "$path" in
    AGENTS.md|CLAUDE.md|CODEX.md|GEMINI.md|.cursor/*) continue ;;
  esac
  echo "CREATE: $path"
done

if [[ "$MODE" == "dry-run" ]]; then
  echo "DRY-RUN: target unchanged; the evidence plan is session-scoped and was not written to the target"
  exit 0
fi

stage="$(mktemp -d)"
created_paths=()
cleanup() { rm -rf "$stage"; }
rollback() {
  local status=$?
  if [[ "$status" -ne 0 ]]; then
    local path
    if [[ ${#created_paths[@]} -gt 0 ]]; then
      for path in "${created_paths[@]}"; do rm -rf "$TARGET/$path"; done
    fi
    echo "FAIL: scaffold apply rolled back newly created paths" >&2
  fi
  cleanup
  exit "$status"
}
trap rollback EXIT

mkdir -p "$stage/skills/$NAME"
stage_selected_owners
render_light_routes
render_routing
render_fitted_conformance
render_fitted_sync_manifest
render_direct_skill_links
render_shells
replace_placeholders
assert_materialized_stage

# The fitted route generator is the canonical owner for generated blocks. Run
# it only when a route manifest was actually admitted; Single-file output has
# no empty manifest and therefore no sync machinery.
if [[ "$ROUTED" -eq 1 && -f "$stage/skills/$NAME/scripts/sync-routing.sh" ]]; then
  (
    cd "$stage"
    bash "skills/$NAME/scripts/sync-routing.sh" "$NAME" >/dev/null
  )
fi

upstream_ref="$(git -C "$ROOT" config --get remote.origin.url 2>/dev/null || printf '%s' "$ROOT")"
upstream_sha="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || true)"
if [[ "$UPSTREAM_PRESSURE" -eq 1 && -n "$upstream_sha" ]]; then
  printf 'upstream: %s\nsynced_sha: %s\nsynced_date: %s\n' \
    "$upstream_ref" "$upstream_sha" "$(date +%F)" > "$stage/skills/$NAME/.upstream-sync"
fi

mkdir -p "$TARGET/skills"
created_paths+=("skills/$NAME")
cp -R "$stage/skills/$NAME" "$TARGET/skills/"

if [[ "$NEED_CURSOR" -eq 1 ]]; then
  mkdir -p "$TARGET/.cursor/skills"
  created_paths+=(".cursor/skills/$NAME")
  cp -R "$stage/.cursor/skills/$NAME" "$TARGET/.cursor/skills/"
  if [[ -f "$stage/.cursor/rules/workflow.mdc" ]]; then
    mkdir -p "$TARGET/.cursor/rules"
    if [[ ! -e "$TARGET/.cursor/rules/workflow.mdc" && ! -L "$TARGET/.cursor/rules/workflow.mdc" ]]; then
      created_paths+=(".cursor/rules/workflow.mdc")
      cp "$stage/.cursor/rules/workflow.mdc" "$TARGET/.cursor/rules/workflow.mdc"
    fi
  fi
fi

for path in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
  local_need=0
  case "$path" in
    AGENTS.md) local_need="$NEED_AGENTS" ;;
    CLAUDE.md) local_need="$NEED_CLAUDE" ;;
    CODEX.md) local_need="$NEED_CODEX" ;;
    GEMINI.md) local_need="$NEED_GEMINI" ;;
  esac
  if [[ "$local_need" -eq 1 && ! -e "$TARGET/$path" && ! -L "$TARGET/$path" ]]; then
    created_paths+=("$path")
    cp "$stage/$path" "$TARGET/$path"
  fi
done

trap - EXIT
cleanup
if [[ ${#PRESERVE_FILES[@]} -gt 0 ]]; then
  echo "READY FOR SEMANTIC MERGE: evidence-selected Skill staged; preserved entries still require Agent-led merge and migration-evidence verification"
else
  echo "APPLIED: evidence-selected Skill created; generated owners passed marker/path staging checks"
fi
echo "APPLIED RESPONSIBILITIES: materialization=$MATERIALIZATION routed=$ROUTED"
