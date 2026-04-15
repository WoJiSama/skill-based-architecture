#!/usr/bin/env bash
# migrate.sh — Atomic "run one phase + validate + checkpoint" helper.
#
# This is the bridge between WORKFLOW.md's human-driven 9-phase process and
# a full state machine. Phases 1, 2, 9 are *not* machine-executable (they
# require human judgment) — for those, `migrate.sh N` just records the
# checkpoint after you confirm the phase is done.
#
# Phases 3–8 are wired to `smoke-test.sh --phase N` so the checkpoint only
# lands if the per-phase validator passes.
#
# Usage:
#   NAME=my-project bash migrate.sh <phase>
#
# Examples:
#   NAME=my-project bash migrate.sh 4       # validate phase 4, write phase=4
#   NAME=my-project bash migrate.sh 1       # human-only phase; confirms and writes phase=1
#   NAME=my-project bash migrate.sh status  # show current state (equivalent to resume.sh)
#
# Exit codes:
#   0 — phase validated (or human-confirmed) and checkpoint written
#   1 — validation failed; checkpoint NOT written
#   2 — usage error

set -euo pipefail

NAME="${NAME:-}"
PHASE="${1:-}"

if [[ -z "$NAME" ]] || [[ -z "$PHASE" ]]; then
  sed -n '2,22p' "$0" >&2
  exit 2
fi

SKILL_DIR="skills/$NAME"
SMOKE="$SKILL_DIR/scripts/smoke-test.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── status → delegate to resume.sh ──────────────────────────────────
if [[ "$PHASE" == "status" ]]; then
  exec bash "$SCRIPT_DIR/resume.sh"
fi

# ── validate phase number ───────────────────────────────────────────
if ! [[ "$PHASE" =~ ^[1-9]$ ]]; then
  echo "Error: phase must be 1..9 (got '$PHASE')" >&2
  exit 2
fi

# ── human-only phases (1, 2, 9) ─────────────────────────────────────
HUMAN_ONLY=0
case "$PHASE" in
  1|2|9) HUMAN_ONLY=1 ;;
esac

if [[ "$HUMAN_ONLY" == "1" ]]; then
  case "$PHASE" in
    1) DESC="Audit existing rule sources" ;;
    2) DESC="Design skill directory structure" ;;
    9) DESC="Pressure-test with fresh subagent (RED/GREEN/REFACTOR)" ;;
  esac
  echo "Phase $PHASE ($DESC) is human-only — no machine validator."
  printf "Have you completed Phase %s per WORKFLOW.md? [y/N] " "$PHASE"
  read -r ANSWER
  if [[ "$ANSWER" != "y" ]] && [[ "$ANSWER" != "Y" ]]; then
    echo "Aborted. Checkpoint not written."
    exit 1
  fi
  echo "phase=$PHASE" > .migration-state
  echo "✅ Checkpoint written: phase=$PHASE"
  exit 0
fi

# ── machine-validated phases (3–8) ──────────────────────────────────
if [[ ! -f "$SMOKE" ]]; then
  echo "Error: $SMOKE not found. Have you scaffolded skills/$NAME/?" >&2
  exit 1
fi

echo "── Validating phase $PHASE via smoke-test.sh ──"
if [[ "$PHASE" == "8" ]]; then
  # Phase 8 runs the full sweep (no --phase flag)
  if ! bash "$SMOKE" "$NAME"; then
    echo ""
    echo "❌ Phase 8 full validation failed. Checkpoint NOT written."
    echo "   Fix the ❌ items above, then re-run: bash migrate.sh 8"
    exit 1
  fi
else
  if ! bash "$SMOKE" "$NAME" --phase "$PHASE"; then
    echo ""
    echo "❌ Phase $PHASE validation failed. Checkpoint NOT written."
    echo "   Fix the ❌ items above, then re-run: bash migrate.sh $PHASE"
    exit 1
  fi
fi

echo "phase=$PHASE" > .migration-state
echo ""
echo "✅ Phase $PHASE validated + checkpoint written (phase=$PHASE)."
NEXT=$((PHASE + 1))
if [[ "$NEXT" -le 9 ]]; then
  echo "   Next: bash migrate.sh $NEXT"
else
  echo "   Migration complete."
fi
