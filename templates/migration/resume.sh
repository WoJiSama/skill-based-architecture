#!/usr/bin/env bash
# resume.sh — Detect where a crashed migration left off and tell you what to do next.
#
# Usage:
#   NAME=<skill-name> bash resume.sh                 # detect and report
#   NAME=<skill-name> bash resume.sh --advance       # also re-run the last phase's
#                                                    # smoke-test to keep the checkpoint honest
#
# Exit codes:
#   0 — detection succeeded (even if phase=0, as long as we could read the state)
#   1 — usage error or detection failed

set -euo pipefail

NAME="${NAME:-}"
MODE="detect"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --advance) MODE="advance"; shift ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$NAME" ]]; then
  echo "Usage: NAME=<skill-name> bash resume.sh [--advance]" >&2
  exit 1
fi

SKILL_DIR="skills/$NAME"
SMOKE="$SKILL_DIR/scripts/smoke-test.sh"

routed_workflows_exist() {
  [[ -f "$SKILL_DIR/workflows/update-rules.md" ]] || return 1
  [[ -f "$SKILL_DIR/routing.yaml" ]] || return 0

  local workflow missing=0
  while IFS= read -r workflow; do
    [[ -n "$workflow" ]] || continue
    [[ "$workflow" == *"FILL:"* ]] && continue
    [[ "$workflow" == workflows/* ]] || continue
    [[ -f "$SKILL_DIR/${workflow%%#*}" ]] || missing=1
  done < <(awk '
    /^[[:space:]]+workflow:/ {
      sub(/^[[:space:]]+workflow:[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
    }
  ' "$SKILL_DIR/routing.yaml")

  [[ "$missing" -eq 0 ]]
}

# ── Phase detection ──────────────────────────────────────────────────
if [[ -f .migration-state ]]; then
  LAST=$(sed -n 's/^phase=//p' .migration-state | head -1)
  LAST="${LAST:-0}"
  echo "📍 .migration-state says: phase=$LAST (last checkpoint)"
  SOURCE="checkpoint file"
else
  # auto-detect by artifact signatures — each check is independent so a broken
  # phase in the middle is visible, not hidden behind a later-phase pass.
  LAST=0
  if [[ -f "$SKILL_DIR/SKILL.md" ]] && [[ -f "$SKILL_DIR/routing.yaml" ]] && [[ $(wc -l < "$SKILL_DIR/SKILL.md") -le 100 ]]; then
    LAST=3
  fi
  if [[ -f "$SKILL_DIR/rules/project-rules.md" ]] && [[ -f "$SKILL_DIR/rules/coding-standards.md" ]]; then
    LAST=4
  fi
  if routed_workflows_exist; then
    LAST=5
  fi
  if [[ -f "$SKILL_DIR/references/gotchas.md" ]] || \
     find "$SKILL_DIR/references" -maxdepth 1 -type f \( -name '*pitfall*' -o -name '*gotcha*' \) 2>/dev/null | grep -q .; then
    LAST=6
  fi
  if [[ -f ".cursor/skills/$NAME/SKILL.md" ]] && [[ -f AGENTS.md ]] && [[ -f CLAUDE.md ]] \
     && [[ -f CODEX.md ]] && [[ -f GEMINI.md ]]; then
    LAST=7
  fi
  if [[ -x "$SMOKE" ]] || [[ -f "$SMOKE" ]]; then
    if bash "$SMOKE" "$NAME" >/dev/null 2>&1; then LAST=8; fi
  fi
  echo "🔎 Auto-detected phase=$LAST (no .migration-state file)"
  SOURCE="artifact signatures"
fi

NEXT=$((LAST + 1))

echo ""
echo "─────────────────────────────────────────────"
echo "  Last completed phase: $LAST  (via $SOURCE)"
echo "  Next phase to run:    $NEXT"
echo "─────────────────────────────────────────────"

# ── Contamination check ─────────────────────────────────────────────
# Look for {{NAME}} / {{SUMMARY}} residue anywhere in the skill tree or shells.
# Presence implies a half-completed sed pass — that phase must be re-run.
RESIDUE=""
if [[ -d "$SKILL_DIR" ]]; then
  RESIDUE=$(find "$SKILL_DIR" -type f \( -name '*.md' -o -name '*.mdc' \) \
    -exec grep -l '{{NAME}}\|{{SUMMARY}}' {} + 2>/dev/null || true)
fi
for shell in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
  [[ -f "$shell" ]] && grep -l '{{NAME}}\|{{SUMMARY}}' "$shell" 2>/dev/null && RESIDUE="$RESIDUE $shell"
done

if [[ -n "$RESIDUE" ]]; then
  echo ""
  echo "⚠️  Placeholder residue detected — the sed pass did not finish:"
  echo "$RESIDUE" | tr ' ' '\n' | sed '/^$/d' | sed 's/^/    /'
  echo ""
  echo "  → Re-run the sed pass from WORKFLOW.md § Quick Start Step 1.4 before continuing."
fi

# ── Next-action hint ────────────────────────────────────────────────
echo ""
case "$NEXT" in
  1) echo "👉 Next: WORKFLOW.md Phase 1 — Audit existing rule sources." ;;
  2) echo "👉 Next: WORKFLOW.md Phase 2 — Design the skill directory structure." ;;
  3) echo "👉 Next: WORKFLOW.md Phase 3 — Write skills/$NAME/SKILL.md (≤ 100 lines) + routing.yaml." ;;
  4) echo "👉 Next: WORKFLOW.md Phase 4 — Extract rules/ files." ;;
  5) echo "👉 Next: WORKFLOW.md Phase 5 — Extract workflows/ files." ;;
  6) echo "👉 Next: WORKFLOW.md Phase 6 — Extract references/ and write gotchas.md." ;;
  7) echo "👉 Next: WORKFLOW.md Phase 7 — Create thin shells + .cursor/skills/$NAME/SKILL.md." ;;
  8) echo "👉 Next: WORKFLOW.md Phase 8 — Run full smoke-test: bash $SMOKE $NAME" ;;
  9) echo "👉 Next: WORKFLOW.md Phase 9 — Pressure-test with a fresh subagent." ;;
  10) echo "✅ All 9 phases complete. Migration done." ;;
esac

# ── Optional: re-validate checkpoint ────────────────────────────────
if [[ "$MODE" == "advance" ]]; then
  echo ""
  echo "── --advance: re-validating phase $LAST ──"
  if [[ "$LAST" -ge 3 ]] && [[ "$LAST" -le 8 ]] && [[ -f "$SMOKE" ]]; then
    if [[ "$LAST" == 8 ]]; then
      if bash "$SMOKE" "$NAME"; then
        echo "✅ phase $LAST re-validated. Checkpoint unchanged."
      else
        echo "❌ phase $LAST no longer passes. Fix before advancing." >&2
        exit 1
      fi
    else
      if bash "$SMOKE" "$NAME" --phase "$LAST"; then
        echo "✅ phase $LAST re-validated."
      else
        echo "❌ phase $LAST no longer passes. Fix before advancing." >&2
        exit 1
      fi
    fi
  else
    echo "(nothing to re-validate at phase=$LAST)"
  fi
fi
