#!/usr/bin/env bash
# test-trigger.sh — Test skill description trigger rate
# Usage: bash test-trigger.sh <skill-name|skill-root> [--include-body]
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
#   2. Also scans SKILL.md body for *candidate* trigger phrases (quoted
#      strings inside Tier-2 / positive_signals / intent-table sections that
#      live INSIDE SKILL.md rather than in description or routing.yaml).
#      These are reported as "promotion candidates" — they cannot activate
#      the skill from where they currently live, only after they are lifted
#      into description.
#   3. Generates natural-language prompts a real user might say
#   4. Sends each prompt to `claude -p` and checks if the response
#      references the skill or its files
#   5. Reports trigger rate (X/Y prompts activated the skill)
#
# Flags:
#   --include-body   Also use body candidate phrases as test prompts (as if
#                    they had already been promoted to description). Useful
#                    for measuring "potential trigger rate after promotion".

set -euo pipefail

TARGET=""
INCLUDE_BODY=0
for arg in "$@"; do
  case "$arg" in
    --include-body) INCLUDE_BODY=1 ;;
    -h|--help)
      TARGET=""
      break
      ;;
    *) [[ -z "$TARGET" ]] && TARGET="$arg" || { echo "Unknown arg: $arg" >&2; exit 2; } ;;
  esac
done
if [[ -z "$TARGET" ]]; then
  echo "Usage: bash test-trigger.sh <skill-name|skill-root> [--include-body]"
  echo ""
  echo "This script tests whether your skill's description triggers correctly"
  echo "when a user gives task-related prompts."
  echo ""
  echo "What it does:"
  echo "  1. Reads quoted trigger phrases from description"
  echo "  2. Samples routing.yaml trigger_examples as extra smoke prompts"
  echo "  3. Scans SKILL.md body for *candidate* phrases (Tier-2 routes,"
  echo "     positive_signals, intent tables) — reports them as promotion"
  echo "     candidates that should move to description"
  echo "  4. Uses 'claude -p' to check if the agent finds and uses your skill"
  echo "  5. Reports a trigger rate score"
  echo ""
  echo "Flags:"
  echo "  --include-body  Also feed body candidates into the trigger test"
  echo "                  (measures potential rate after promotion)"
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

# Scan SKILL.md body (after frontmatter, outside code blocks) for quoted
# *candidate* trigger phrases that should be lifted into description.
#
# Recognises any "..." quoted phrase under a body heading, with light filters
# to drop obvious non-trigger strings (paths, snake_case identifiers, all-caps
# constants, single chars, frontmatter separators). Labels each candidate with
# the nearest preceding ## / ### heading so the user can see which Tier-2
# route / intent table / section they came from.
#
# Output: one record per line, TAB-separated: <heading>\t<phrase>
# Empty output means no body candidates found.
extract_body_candidates() {
  python3 - "$1" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
lines = path.read_text().splitlines()

start = 0
if lines and lines[0].strip() == "---":
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            start = i + 1
            break

heading = "(top)"
in_code = False
seen = set()
PHRASE_RE = re.compile(r'"([^"]{2,})"')

for i in range(start, len(lines)):
    line = lines[i]
    if line.lstrip().startswith("```"):
        in_code = not in_code
        continue
    if in_code:
        continue
    if line.startswith("#"):
        heading = line.lstrip("#").strip() or heading
        continue
    for phrase in PHRASE_RE.findall(line):
        # filter obvious non-triggers
        p = phrase.strip()
        if not p or p in {"---", "..."}:
            continue
        if "/" in p[:6] or p.startswith("http"):
            continue
        if re.match(r'^[A-Z][A-Z0-9_]+$', p):  # all-caps constants
            continue
        if re.match(r'^[a-z][a-z0-9_]*$', p) and "_" in p:  # snake_case ids
            continue
        if re.match(r'^[a-zA-Z][a-zA-Z0-9_.-]*\.(md|sh|py|yaml|yml|json)$', p):  # file paths
            continue
        key = (heading, p)
        if key in seen:
            continue
        seen.add(key)
        print(f"{heading}\t{p}")
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
  echo ""

  # Body candidates — phrases living inside SKILL.md body that should be
  # promoted to description for Agent to see at routing time.
  BODY_TMP="$(mktemp)"
  trap 'rm -f "$BODY_TMP"' RETURN
  extract_body_candidates "$SKILL_MD" > "$BODY_TMP"
  BODY_COUNT=$(wc -l < "$BODY_TMP" | tr -d ' ')
  if [[ "$BODY_COUNT" -gt 0 ]]; then
    DESC_TRIG_COUNT=$(echo "$DESC" | grep -o '"[^"]*"' | wc -l | tr -d ' ')
    echo "Body candidate trigger phrases (found inside SKILL.md, not in description):"
    awk -F '\t' '{ printf "  [%s] %s\n", $1, $2 }' "$BODY_TMP" | head -40
    if [[ "$BODY_COUNT" -gt 40 ]]; then
      echo "  … and $((BODY_COUNT - 40)) more (total: $BODY_COUNT)"
    fi
    echo ""
    if [[ "$DESC_TRIG_COUNT" -eq 0 ]]; then
      echo "⚠️  description has 0 quoted trigger phrases but body has $BODY_COUNT candidates."
      echo "    Agent does NOT see body content at routing time. Promote the most"
      echo "    representative ${BODY_COUNT}+ phrases into the frontmatter description."
    else
      echo "ℹ️  description has $DESC_TRIG_COUNT phrases; body has $BODY_COUNT additional candidates."
      echo "    If trigger rate is still low, consider promoting more body candidates."
    fi
  fi
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

# Body candidates: phrases living inside SKILL.md body. Always extracted so
# we can report them; only added to PROMPTS when --include-body is passed.
BODY_TMP="$(mktemp)"
trap 'rm -f "$BODY_TMP"' EXIT
extract_body_candidates "$SKILL_MD" > "$BODY_TMP"
BODY_COUNT=$(wc -l < "$BODY_TMP" | tr -d ' ')

if [[ "$INCLUDE_BODY" -eq 1 && "$BODY_COUNT" -gt 0 ]]; then
  while IFS=$'\t' read -r heading phrase; do
    [[ -n "$phrase" ]] || continue
    PROMPTS+=("$phrase")
    TASK_NAMES+=("[body candidate / $heading] $phrase")
  done < "$BODY_TMP"
fi

if [[ ${#PROMPTS[@]} -eq 0 ]]; then
  echo "❌ No test prompts could be generated from description / routing.yaml / Common Tasks."
  echo ""
  if [[ "$BODY_COUNT" -gt 0 ]]; then
    echo "However, $BODY_COUNT candidate trigger phrases were found inside SKILL.md body:"
    awk -F '\t' '{ printf "  [%s] %s\n", $1, $2 }' "$BODY_TMP" | head -30
    if [[ "$BODY_COUNT" -gt 30 ]]; then
      echo "  … and $((BODY_COUNT - 30)) more (total: $BODY_COUNT)"
    fi
    echo ""
    echo "Agent does NOT see body content at routing time — these phrases are"
    echo "currently invisible to activation. Two ways forward:"
    echo "  (a) Promote the representative phrases into the frontmatter description"
    echo "      and re-run this script."
    echo "  (b) Re-run with --include-body to test these phrases as if they had"
    echo "      already been promoted (measures potential trigger rate)."
  else
    echo "No trigger phrases found anywhere — description, routing.yaml, Common Tasks,"
    echo "and SKILL.md body are all empty of \"…\" quoted user-language phrases."
    echo "Add trigger phrases to the frontmatter description first; see"
    echo "references/layout.md § Description as Trigger Condition."
  fi
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
