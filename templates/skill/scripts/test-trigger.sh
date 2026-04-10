#!/usr/bin/env bash
# test-trigger.sh — Test skill description trigger rate
# Usage: bash test-trigger.sh <skill-name> [--cursor-only]
#
# Automatically generates test prompts from SKILL.md Common Tasks,
# then uses `claude -p` to check if the skill activates.
#
# Prerequisites:
#   - Claude Code CLI installed (`claude` command available)
#   - .cursor/skills/<name>/SKILL.md exists (for Cursor trigger testing)
#
# How it works:
#   1. Parses Common Tasks from SKILL.md to extract task descriptions
#   2. Generates natural-language prompts a real user might say
#   3. Sends each prompt to `claude -p` and checks if the response
#      references the skill or its files
#   4. Reports trigger rate (X/Y prompts activated the skill)

set -euo pipefail

NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  echo "Usage: bash test-trigger.sh <skill-name>"
  echo ""
  echo "This script tests whether your skill's description triggers correctly"
  echo "when a user gives task-related prompts."
  echo ""
  echo "What it does:"
  echo "  1. Reads your SKILL.md Common Tasks to understand what the skill handles"
  echo "  2. Generates realistic user prompts for each task type"
  echo "  3. Uses 'claude -p' to check if the agent finds and uses your skill"
  echo "  4. Reports a trigger rate score"
  exit 1
fi

SKILL_DIR="skills/$NAME"
SKILL_MD="$SKILL_DIR/SKILL.md"

if [[ ! -f "$SKILL_MD" ]]; then
  echo "Error: $SKILL_MD not found. Run smoke-test.sh first."
  exit 1
fi

# Check if claude CLI is available
if ! command -v claude &>/dev/null; then
  echo "Error: 'claude' CLI not found."
  echo ""
  echo "This script needs Claude Code CLI to test trigger rates."
  echo "Install it from: https://docs.anthropic.com/en/docs/claude-code"
  echo ""
  echo "Alternative: manually verify trigger phrases by checking that your"
  echo "SKILL.md description includes quoted phrases matching Common Tasks."
  echo ""
  echo "Running static analysis instead..."
  echo ""

  # Fallback: static description analysis
  echo "═══ Static Description Analysis ═══"
  echo ""

  # Extract description
  DESC=$(sed -n '/^description:/,/^[a-z]*:/{ /^description:/d; /^[a-z]*:/d; p; }' "$SKILL_MD" | tr -s ' \n' ' ')
  echo "Description ($( echo "$DESC" | wc -w | tr -d ' ') words):"
  echo "  $DESC"
  echo ""

  # Extract trigger phrases
  TRIGGERS=$(echo "$DESC" | grep -o '"[^"]*"' || true)
  if [[ -n "$TRIGGERS" ]]; then
    echo "Trigger phrases found:"
    echo "$TRIGGERS" | sed 's/^/  /'
  else
    echo "⚠️  No quoted trigger phrases found in description!"
  fi
  echo ""

  # Extract Common Tasks
  echo "Common Tasks found:"
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
      # Check if any trigger phrase covers this task
      TASK_LOWER=$(echo "$TASK" | tr '[:upper:]' '[:lower:]')
      DESC_LOWER=$(echo "$DESC" | tr '[:upper:]' '[:lower:]')
      if echo "$DESC_LOWER" | grep -qi "$TASK_LOWER" 2>/dev/null; then
        echo "    ✅ Covered by description"
      else
        echo "    ⚠️  Not obviously covered by description (may still trigger via semantic matching)"
      fi
    fi
  done < "$SKILL_MD"

  exit 0
fi

# ── Generate test prompts from Common Tasks ───────────────────────────
echo "═══ Trigger Rate Test ═══"
echo ""
echo "Generating test prompts from $SKILL_MD Common Tasks..."
echo ""

PROMPTS=()
TASK_NAMES=()

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
    # Generate a natural prompt
    PROMPTS+=("I need to $TASK")
  fi
done < "$SKILL_MD"

# Also add trigger phrases from description as test prompts
DESC=$(sed -n '/^description:/,/^[a-z]*:/{ /^description:/d; /^[a-z]*:/d; p; }' "$SKILL_MD" | tr -s ' \n' ' ')
while IFS= read -r phrase; do
  if [[ -n "$phrase" ]]; then
    CLEAN=$(echo "$phrase" | tr -d '"')
    PROMPTS+=("$CLEAN")
    TASK_NAMES+=("[trigger phrase] $CLEAN")
  fi
done < <(echo "$DESC" | grep -o '"[^"]*"')

if [[ ${#PROMPTS[@]} -eq 0 ]]; then
  echo "No test prompts could be generated. Check that SKILL.md has a Common Tasks section."
  exit 1
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
  META_PROMPT="You are testing skill activation. A user says: \"$prompt\"

Look at the available skills in this project (check .cursor/skills/ and skills/ directories).
Which skill(s) would you activate for this request? Just list the skill name(s) and the file path(s) you would read. If no skill matches, say 'NO_SKILL_MATCH'.

Important: only answer with skill names and paths, nothing else. Be brief."

  RESPONSE=$(claude -p "$META_PROMPT" --max-turns 1 2>/dev/null || echo "ERROR_RUNNING_CLAUDE")

  if echo "$RESPONSE" | grep -qi "$NAME\|skills/$NAME\|\.cursor/skills/$NAME" 2>/dev/null; then
    echo "  ✅ Triggered (found reference to $NAME)"
    ((TRIGGERED++))
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
echo "  1. Add more quoted trigger phrases to SKILL.md description"
echo "  2. Include concrete task verbs users would actually say"
echo "  3. Match phrases to Common Tasks entries"
echo "  4. Ensure .cursor/skills/$NAME/SKILL.md description matches exactly"
echo "═══════════════════════════════════════"

exit 0
