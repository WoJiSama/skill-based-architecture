#!/usr/bin/env bash
# test-trigger.sh — Test skill description trigger rate
# Usage: bash test-trigger.sh <skill-name|skill-root>
#
# Tests whether SKILL.md description activates for domain-level user language.
# routing.yaml trigger_examples are sampled as smoke prompts, but description
# should not become a keyword dump of every workflow; SKILL.md routes tasks
# after activation.
#
# Prerequisites:
#   - Claude Code CLI installed (`claude` command available)
#   - .cursor/skills/<name>/SKILL.md exists (for Cursor trigger testing)
#
# How it works:
#   1. Parses quoted trigger phrases from description + routing.yaml examples
#   2. Generates natural-language prompts a real user might say
#   3. Sends each prompt to `claude -p` and checks if the response
#      references the skill or its files
#   4. Reports trigger rate (X/Y prompts activated the skill)

set -euo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  echo "Usage: bash test-trigger.sh <skill-name|skill-root>"
  echo ""
  echo "This script tests whether your skill's description triggers correctly"
  echo "when a user gives task-related prompts."
  echo ""
  echo "What it does:"
  echo "  1. Reads quoted trigger phrases from description"
  echo "  2. Samples routing.yaml trigger_examples as extra smoke prompts"
  echo "  3. Uses 'claude -p' to check if the agent finds and uses your skill"
  echo "  4. Reports a trigger rate score"
  exit 1
fi

if [[ -f "$TARGET/SKILL.md" ]]; then
  SKILL_DIR="${TARGET%/}"
elif [[ -f "skills/$TARGET/SKILL.md" ]]; then
  SKILL_DIR="skills/$TARGET"
else
  SKILL_DIR="skills/$TARGET"
fi

SKILL_MD="$SKILL_DIR/SKILL.md"

if [[ ! -f "$SKILL_MD" ]]; then
  echo "Error: $SKILL_MD not found. Run smoke-test.sh first."
  exit 1
fi

NAME="$(awk '/^name:/ { sub(/^name:[[:space:]]*/, ""); gsub(/^["'\'']|["'\'']$/, ""); print; exit }' "$SKILL_MD")"
NAME="${NAME:-$(basename "$SKILL_DIR")}"
CURSOR_ENTRY=".cursor/skills/$NAME/SKILL.md"

if [[ -f "$SKILL_DIR/routing.yaml" ]]; then
  ROUTING_YAML="$SKILL_DIR/routing.yaml"
elif [[ "$SKILL_DIR" == "." && -f "references/self-hosting-routing.yaml" ]]; then
  ROUTING_YAML="references/self-hosting-routing.yaml"
else
  ROUTING_YAML=""
fi

extract_description() {
  python3 - "$1" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
lines = path.read_text().splitlines()
in_frontmatter = bool(lines and lines[0].strip() == "---")
start = 1 if in_frontmatter else 0

for idx in range(start, len(lines)):
    raw = lines[idx]
    if in_frontmatter and idx > start and raw.strip() == "---":
        break
    if not raw.startswith("description:"):
        continue
    value = raw.split(":", 1)[1].strip()
    if value and value not in {">", "|", ">-", "|-"}:
        print(value.strip("\"'"))
        raise SystemExit(0)
    block = []
    for line in lines[idx + 1:]:
        stripped = line.strip()
        if not stripped:
            continue
        if in_frontmatter and stripped == "---":
            break
        if line[:1].strip() and ":" in stripped:
            break
        block.append(stripped)
    print(" ".join(block))
    raise SystemExit(0)
PY
}

run_static_analysis() {
  echo "═══ Static Description Analysis ═══"
  echo ""

  DESC=$(extract_description "$SKILL_MD")
  echo "Description ($( echo "$DESC" | wc -w | tr -d ' ') words):"
  echo "  $DESC"
  echo ""

  TRIGGERS=$(echo "$DESC" | grep -o '"[^"]*"' || true)
  if [[ -n "$TRIGGERS" ]]; then
    echo "Trigger phrases found:"
    echo "$TRIGGERS" | sed 's/^/  /'
  else
    echo "⚠️  No quoted trigger phrases found in description!"
  fi
  echo ""

  if [[ -n "$ROUTING_YAML" && -f "$ROUTING_YAML" ]]; then
    echo "routing.yaml trigger examples found:"
    python3 - "$ROUTING_YAML" <<'PY' | sed 's/^/  /'
from pathlib import Path
import sys

path = Path(sys.argv[1])
current = None
in_examples = False
for raw in path.read_text().splitlines():
    stripped = raw.strip()
    if raw.startswith("  - id:"):
        current = stripped.split(":", 1)[1].strip().strip('"')
        in_examples = False
    elif raw.startswith("    trigger_examples:"):
        in_examples = True
    elif in_examples and raw.startswith("      - "):
        value = stripped[2:].strip().strip('"')
        if "FILL:" not in value:
            print(f"{current}: {value}")
    elif raw.startswith("    ") and ":" in stripped:
        in_examples = False
PY
    echo ""
  fi

  echo "Common Tasks found (task-level routing after activation):"
  IN_CT=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]+Common[[:space:]]+Tasks ]]; then
      IN_CT=true
      continue
    fi
    if $IN_CT && [[ "$line" =~ ^## ]]; then
      break
    fi
    if $IN_CT && [[ "$line" =~ ^-[[:space:]] ]]; then
      TASK=$(echo "$line" | sed 's/^- //' | sed 's/ →.*//')
      echo "  - $TASK"
    fi
  done < "$SKILL_MD"
  echo ""
  echo "Note: Common Tasks do not need exact phrase coverage in description."
  echo "Description should activate the skill domain; Common Tasks routes workflow choice."
}

# Check if claude CLI is available and usable.
if ! command -v claude &>/dev/null; then
  echo "Error: 'claude' CLI not found."
  echo ""
  echo "This script needs Claude Code CLI to test trigger rates."
  echo "Install it from: https://docs.anthropic.com/en/docs/claude-code"
  echo ""
  echo "Alternative: manually verify trigger phrases by checking that your"
  echo "SKILL.md description includes domain-level trigger phrases in the"
  echo "language users actually use. Common Tasks handles detailed routing."
  echo ""
  echo "Running static analysis instead..."
  echo ""

  run_static_analysis
  exit 0
fi

CLAUDE_PREFLIGHT=$(claude -p "Reply with OK only." --max-turns 1 2>&1) || {
  echo "Warning: 'claude' CLI is installed but cannot run trigger prompts."
  echo "First error line: $(echo "$CLAUDE_PREFLIGHT" | head -n 1)"
  echo ""
  echo "Running static analysis instead..."
  echo ""

  run_static_analysis
  exit 0
}

# ── Generate test prompts from description + sampled Common Tasks ─────
echo "═══ Trigger Rate Test ═══"
echo ""
echo "Generating test prompts from $SKILL_MD description and routing examples..."
echo ""

PROMPTS=()
TASK_NAMES=()

if [[ -n "$ROUTING_YAML" && -f "$ROUTING_YAML" ]]; then
  while IFS=$'\t' read -r task prompt; do
    [[ -n "$prompt" ]] || continue
    PROMPTS+=("$prompt")
    TASK_NAMES+=("[routing.yaml] $task")
  done < <(python3 - "$ROUTING_YAML" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
current = None
in_examples = False
for raw in path.read_text().splitlines():
    stripped = raw.strip()
    if raw.startswith("  - id:"):
        current = stripped.split(":", 1)[1].strip().strip('"')
        in_examples = False
    elif raw.startswith("    trigger_examples:"):
        in_examples = True
    elif in_examples and raw.startswith("      - "):
        value = stripped[2:].strip().strip('"')
        if "FILL:" not in value:
            print(f"{current}\t{value}")
    elif raw.startswith("    ") and ":" in stripped:
        in_examples = False
PY
  )
fi

IN_CT=false
while IFS= read -r line; do
  if [[ "$line" =~ ^##[[:space:]]+Common[[:space:]]+Tasks ]]; then
    IN_CT=true
    continue
  fi
  if $IN_CT && [[ "$line" =~ ^## ]]; then
    break
  fi
  if $IN_CT && [[ "$line" =~ ^-[[:space:]] ]]; then
    # Extract the task name (before →)
    TASK=$(echo "$line" | sed 's/^- //' | sed 's/ →.*//' | sed 's/\*\*//g')
    # Skip generic "Other" entries
    if echo "$TASK" | grep -qi "^other\|^unlisted"; then
      continue
    fi
    TASK_NAMES+=("$TASK")
    # Generate a natural prompt. This is a smoke sample, not a requirement that
    # the description literally list every workflow label.
    PROMPTS+=("I need help in this project: $TASK")
  fi
done < "$SKILL_MD"

# Also add trigger phrases from description as test prompts
DESC=$(extract_description "$SKILL_MD")
while IFS= read -r phrase; do
  if [[ -n "$phrase" ]]; then
    CLEAN=$(echo "$phrase" | tr -d '"')
    PROMPTS+=("$CLEAN")
    TASK_NAMES+=("[trigger phrase] $CLEAN")
  fi
done < <(echo "$DESC" | grep -o '"[^"]*"')

if [[ ${#PROMPTS[@]} -eq 0 ]]; then
  echo "No test prompts could be generated. Check routing.yaml trigger_examples and SKILL.md Common Tasks."
  exit 1
fi

CANDIDATE_PATHS="$SKILL_MD"
if [[ -f "$CURSOR_ENTRY" ]]; then
  CANDIDATE_PATHS="$CANDIDATE_PATHS, $CURSOR_ENTRY"
fi

echo "Generated ${#PROMPTS[@]} test prompts:"
for i in "${!TASK_NAMES[@]}"; do
  echo "  $((i+1)). ${TASK_NAMES[$i]}"
done
echo ""

# ── Run each prompt through claude -p ─────────────────────────────────
TRIGGERED=0
TOTAL=${#PROMPTS[@]}
RESULTS=()

for i in "${!PROMPTS[@]}"; do
  prompt="${PROMPTS[$i]}"
  task="${TASK_NAMES[$i]}"
  echo "Testing [$((i+1))/$TOTAL]: $task"

  # Use claude -p with a meta-prompt that asks which skill would activate
  META_PROMPT="You are testing skill activation from metadata. A user says: \"$prompt\"

Candidate skill:
- name: $NAME
- description: $DESC
- paths: $CANDIDATE_PATHS

Would this candidate skill activate for this request? Use the description as the coarse activation rule. If it matches the domain boundary, list the skill name and path(s). If it does not match, say 'NO_SKILL_MATCH'.

Important: only answer with skill names and paths, nothing else. Be brief."

  RESPONSE=$(claude -p "$META_PROMPT" --max-turns 1 2>/dev/null || echo "ERROR_RUNNING_CLAUDE")

  if echo "$RESPONSE" | grep -qi "$NAME\|$SKILL_MD\|skills/$NAME\|$CURSOR_ENTRY" 2>/dev/null; then
    echo "  ✅ Triggered (found reference to $NAME)"
    ((TRIGGERED+=1))
    RESULTS+=("✅")
  elif echo "$RESPONSE" | grep -qi "NO_SKILL_MATCH\|ERROR_RUNNING" 2>/dev/null; then
    echo "  ❌ NOT triggered"
    RESULTS+=("❌")
  else
    echo "  ⚠️  Unclear (response didn't explicitly mention $NAME)"
    echo "     Response: ${RESPONSE:0:120}..."
    RESULTS+=("⚠️")
  fi
done

# ── Summary ───────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
RATE=$((TRIGGERED * 100 / TOTAL))
echo "  Trigger Rate: $TRIGGERED/$TOTAL ($RATE%)"
echo ""

if [[ $RATE -ge 80 ]]; then
  echo "  ✅ Good trigger rate (≥ 80%)"
elif [[ $RATE -ge 50 ]]; then
  echo "  ⚠️  Moderate trigger rate (50-79%) — consider improving description"
else
  echo "  ❌ Low trigger rate (< 50%) — description needs significant improvement"
fi

echo ""
echo "  To improve trigger rate:"
echo "  1. Add domain-level quoted trigger phrases users actually say"
echo "  2. Add route-specific examples to routing.yaml trigger_examples"
echo "  3. Cover intent clusters (broken behavior, feature change, docs/rules), not every workflow keyword"
echo "  4. Ensure $CURSOR_ENTRY description matches exactly when that registration entry exists"
echo "═══════════════════════════════════════"

exit 0
