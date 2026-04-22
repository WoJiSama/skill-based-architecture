#!/usr/bin/env bash
# agent-behavior-gate — PreToolUse guard for rules/agent-behavior.md
#
# Fires before every Write/Edit. For edits that would GROW the file beyond a
# typo-tolerance, enforces two checks:
#   1. Projected line count ≤ HARD_CAP (default 100)
#   2. references/behavior-failures.md contains at least one non-FILL '## ' row
#
# Designed to minimize false positives. Allows without evidence checks when:
#   - Edit shrinks the file (negative line delta) — refactor/deletion path
#   - Edit keeps line count constant AND char delta ≤ TYPO_TOLERANCE (default 20)
#
# Escape hatch:  AGENT_BEHAVIOR_GATE_OVERRIDE=1
#   Bypasses all checks and logs the override to stderr. Intended for
#   legitimate maintainer edits. Audit via shell history / commit hooks.
#
# Warning-only mode:  AGENT_BEHAVIOR_GATE_WARN=1
#   Prints would-block reasons to stderr but still exits 0. Useful when
#   rolling the hook out on a repo that's currently over cap.
#
# Exit codes: 2 = block (Claude Code PreToolUse convention); 0 = allow.
# Requires: jq (macOS/Linux standard; git-bash on Windows may need install).

set -uo pipefail

# ── Config ────────────────────────────────────────────────────────────
HARD_CAP="${AGENT_BEHAVIOR_GATE_HARD_CAP:-100}"
TYPO_TOLERANCE="${AGENT_BEHAVIOR_GATE_TYPO_TOLERANCE:-20}"
GATED_FILE="${AGENT_BEHAVIOR_GATE_PATH:-templates/skill/rules/agent-behavior.md}"
EVIDENCE_FILE="${AGENT_BEHAVIOR_GATE_EVIDENCE:-templates/skill/references/behavior-failures.md}"

# ── Read tool call (Claude Code PreToolUse passes JSON on stdin) ──────
TOOL_INPUT=$(cat)
TOOL_NAME=$(echo "$TOOL_INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

# ── Scope: only Write/Edit on the gated file ──────────────────────────
[[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]] && exit 0
[[ "$FILE_PATH" != *"$GATED_FILE" ]] && exit 0

# ── Escape hatch ──────────────────────────────────────────────────────
if [[ "${AGENT_BEHAVIOR_GATE_OVERRIDE:-}" == "1" ]]; then
  echo "[agent-behavior-gate] OVERRIDE acknowledged (AGENT_BEHAVIOR_GATE_OVERRIDE=1)" >&2
  exit 0
fi

# ── Compute deltas ────────────────────────────────────────────────────
count_lines() {
  # Count newline-separated lines. Empty string → 0.
  if [[ -z "${1:-}" ]]; then
    echo 0
  else
    printf '%s' "$1" | awk 'END {print NR}'
  fi
}

if [[ "$TOOL_NAME" == "Edit" ]]; then
  OLD_STRING=$(echo "$TOOL_INPUT" | jq -r '.tool_input.old_string // empty')
  NEW_STRING=$(echo "$TOOL_INPUT" | jq -r '.tool_input.new_string // empty')
  OLD_LINES=$(count_lines "$OLD_STRING")
  NEW_LINES=$(count_lines "$NEW_STRING")
  LINE_DELTA=$((NEW_LINES - OLD_LINES))
  CHAR_DELTA=$((${#NEW_STRING} - ${#OLD_STRING}))
else
  # Write: replaces entire file. Compare new content to current file.
  NEW_CONTENT=$(echo "$TOOL_INPUT" | jq -r '.tool_input.content // empty')
  NEW_LINES=$(count_lines "$NEW_CONTENT")
  if [[ -f "$FILE_PATH" ]]; then
    OLD_LINES=$(wc -l < "$FILE_PATH")
  else
    OLD_LINES=0
  fi
  LINE_DELTA=$((NEW_LINES - OLD_LINES))
  # For Write we don't have a clean char-delta against old content;
  # use line-delta as the proxy for "grew or not".
  CHAR_DELTA=$((LINE_DELTA * 40))  # rough: ~40 chars per line average
fi

# ── Path A: shrinking → always allow ──────────────────────────────────
if [[ $LINE_DELTA -lt 0 ]]; then
  echo "[agent-behavior-gate] shrinking edit allowed (Δlines=$LINE_DELTA)" >&2
  exit 0
fi

# ── Path B: same line count + small char delta → typo/style → allow ──
ABS_CHAR_DELTA=${CHAR_DELTA#-}
if [[ $LINE_DELTA -eq 0 && $ABS_CHAR_DELTA -le $TYPO_TOLERANCE ]]; then
  echo "[agent-behavior-gate] minor edit allowed (Δchars=$CHAR_DELTA, within tolerance $TYPO_TOLERANCE)" >&2
  exit 0
fi

# ── Path C: edit grows content. Enforce gate. ─────────────────────────
BLOCK_REASONS=()

# Check 1: projected line count ≤ cap
if [[ -f "$FILE_PATH" ]]; then
  CURRENT_LINES=$(wc -l < "$FILE_PATH")
  PROJECTED=$((CURRENT_LINES + LINE_DELTA))
  if [[ $PROJECTED -gt $HARD_CAP ]]; then
    BLOCK_REASONS+=("cap-exceeded: projected $PROJECTED / $HARD_CAP lines")
  fi
fi

# Check 2: evidence file has at least one real AAR row
EVIDENCE_COUNT=0
if [[ -f "$EVIDENCE_FILE" ]]; then
  EVIDENCE_COUNT=$(grep -cE '^## ' "$EVIDENCE_FILE" 2>/dev/null || echo 0)
fi
if [[ $EVIDENCE_COUNT -eq 0 ]]; then
  BLOCK_REASONS+=("no-evidence: $EVIDENCE_FILE has 0 '## ' rows")
fi

# ── Decide ────────────────────────────────────────────────────────────
if [[ ${#BLOCK_REASONS[@]} -eq 0 ]]; then
  exit 0
fi

# Block (or warn).
{
  echo "BLOCKED: edit to $GATED_FILE rejected by admission gate."
  echo "  Δlines=$LINE_DELTA  Δchars=$CHAR_DELTA  projected-lines=${PROJECTED:-n/a}"
  for reason in "${BLOCK_REASONS[@]}"; do
    echo "  - $reason"
  done
  echo ""
  echo "Paths to unblock:"
  echo "  (a) shrink existing principles to make room (any reducing edit is allowed)"
  echo "  (b) route the new content to templates/protocol-blocks/ or templates/skill/references/"
  echo "  (c) write a concrete AAR row in $EVIDENCE_FILE (what was asked / what failed / cost / why existing principles missed it), then retry"
  echo "  (d) emergency override: run with AGENT_BEHAVIOR_GATE_OVERRIDE=1"
  echo ""
  echo "Full gate rationale: templates/ANTI-TEMPLATES.md § Admission Threshold for Behavioral Principles"
} >&2

if [[ "${AGENT_BEHAVIOR_GATE_WARN:-}" == "1" ]]; then
  echo "[agent-behavior-gate] WARN-ONLY mode (AGENT_BEHAVIOR_GATE_WARN=1): allowing despite block reasons above" >&2
  exit 0
fi

exit 2
