#!/usr/bin/env bash
# smoke-test.sh — Fully automated post-migration verification
# Usage: bash smoke-test.sh <skill-name> [--phase N] [--workspace-root <path>]
# Example: bash smoke-test.sh my-project
#          bash smoke-test.sh my-project --phase 4   # run only Phase 4 subset
#
# Zero manual input required. Checks every responsibility the target actually
# materialized; a Single-file Skill is valid without Full-only routing, shell,
# workflow, or maintenance surfaces.
# Supports both English and Chinese (中文) section names.
# Exit code: 0 = all pass, 1 = failures found.
#
# ═══════════════════════════════════════════════════════════════════════
# 9 CATEGORIES of checks (see corresponding section markers below):
#
#   1. Structural Checks          — SKILL.md always exists; separately materialized
#                                   rules/workflows/gotchas/routing/entry surfaces
#                                   are valid; SessionStart hook wired (1d, WARN)
#   2. Line Count Budgets         — SKILL.md dual budget (description ≤ 25 + body ≤ 90), routing task core ≤ 140,
#                                   optional domain manifest reported separately, shells ≤ 60 lines,
#                                   gotchas/pitfall ≤ $GOTCHAS_MAX_LINES (default 400),
#                                   no duplicate ## headings in gotchas/pitfall files,
#                                   task routes ≤ $TASK_ROUTES_MAX rows
#                                   (default 10) — both env-overridable
#   3. Placeholder Residue        — no {{NAME}} / {{SUMMARY}} leftover;
#                                   no unreplaced <!-- FILL: --> markers
#   4. SKILL.md Content Quality   — description ≥ 20 words or enough CJK chars,
#                                   ≥ 2 quoted trigger phrases in real user
#                                   language(s), not keyword-stuffed (WARN if
#                                   > $DESCRIPTION_MAX_TRIGGERS quoted phrases),
#                                   Common Tasks action hook + Known Gotchas sections exist
#   5. Routing Completeness       — routing.yaml structure/paths and generated blocks
#                                   match when routed; otherwise SKILL.md owns a
#                                   concrete direct Common Tasks boundary
#   6. Description Consistency    — SKILL.md and .cursor/skills/<name>/SKILL.md
#                                   descriptions match byte-for-byte
#   7. Shell Routing Consistency  — materialized harness entries point at the
#                                   actual routing owner (routing.yaml or SKILL.md)
#   8. Local Reference Integrity — relative markdown links, heading fragments,
#                                   and path-like inline code spans across Skill
#                                   docs resolve; two-root Skills also run
#                                   namespace-isolated orphan/reachability checks
#                                   when --workspace-root is supplied.
#   9. Content Conformance        — if a conformance.yaml manifest exists, every
#                                   section/phrase the upstream contract promises
#                                   is still PRESENT (catches content drift like a
#                                   renamed "Task Closure Protocol"). Skipped with
#                                   no manifest. Runs in full / --phase 8 only.
#
# Roughly 50 discrete checks across these 9 categories (count varies slightly
# based on how many rules/workflows/gotchas files the target project has).
# ═══════════════════════════════════════════════════════════════════════
#
# --phase N runs the subset of checks relevant to WORKFLOW.md Phase N. See
# `WORKFLOW.md § Resuming From a Failed Phase` for the phase→section mapping.
# Without --phase, all sections run (equivalent to Phase 8 full verify).
#
# ── Configurable thresholds ───────────────────────────────────────────
# Defaults are opinionated but adjustable per-project via env. Raise only with
# a principled reason; these caps exist to force fission/pruning rather than
# unbounded growth. Example override:
#     GOTCHAS_MAX_LINES=600 TASK_ROUTES_MAX=12 bash smoke-test.sh my-skill
GOTCHAS_MAX_LINES="${GOTCHAS_MAX_LINES:-400}"
TASK_ROUTES_MAX="${TASK_ROUTES_MAX:-${COMMON_TASKS_MAX_ROWS:-10}}"
DESCRIPTION_MIN_WORDS="${DESCRIPTION_MIN_WORDS:-20}"
DESCRIPTION_MIN_CJK_CHARS="${DESCRIPTION_MIN_CJK_CHARS:-40}"
# Description is a coarse activation gate, not a workflow index. More than this
# many quoted trigger phrases signals workflow-keyword stuffing (Pitfall #3). WARN-only.
DESCRIPTION_MAX_TRIGGERS="${DESCRIPTION_MAX_TRIGGERS:-12}"

# Maintenance note: this runs under `set -euo pipefail`. Any new `VAR=$(cmd | …)`
# capture MUST end with `|| true` — a non-zero anywhere in the pipe (grep no-match,
# or `find skills` when the self-hosting repo has no skills/ dir) otherwise aborts
# the whole run mid-section with no summary.
set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────
NAME="${1:-}"
PHASE=""
WORKSPACE_ROOT=""
SELF_HOSTING_ROOT=0
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2 ;;
    --phase=*) PHASE="${1#--phase=}"; shift ;;
    --workspace-root)
      [[ $# -ge 2 ]] || { echo "Missing value for --workspace-root" >&2; exit 1; }
      WORKSPACE_ROOT="$2"; shift 2 ;;
    --workspace-root=*) WORKSPACE_ROOT="${1#--workspace-root=}"; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$NAME" ]]; then
  echo "Usage: bash smoke-test.sh <skill-name> [--phase N] [--workspace-root <path>]"
  echo "Example: bash smoke-test.sh my-project"
  exit 1
fi

if [[ -n "$WORKSPACE_ROOT" ]]; then
  if [[ ! -d "$WORKSPACE_ROOT" ]]; then
    echo "Workspace root not found: $WORKSPACE_ROOT" >&2
    exit 1
  fi
  WORKSPACE_ROOT="$(cd "$WORKSPACE_ROOT" && pwd -P)"
fi

# Phase→section map. Each phase runs a subset of sections 1–9 below.
# Phase 3: SKILL.md written         → sections 4, 6
# Phase 4: rules extracted          → sections 1a, 2, 3
# Phase 5: workflows extracted      → sections 1a, 2, 3
# Phase 6: references extracted     → sections 1a, 3
# Phase 7: thin shells + routing    → sections 1b, 1c, 5, 6, 7, 8 (NOT 9)
# Phase 8: full verify              → all (incl. section 9 content conformance)
# (no flag)                         → all
# These --phase numbers map to WORKFLOW.md phases 3–8. WORKFLOW.md "Phase 9"
# is a separate MANUAL attestation (Rationalizations pressure test), not a
# smoke-test section; `--phase 9` here is just an alias that re-runs all.
phase_runs() {
  # $1 = section number (1..9). Returns 0 (run) or 1 (skip).
  [[ -z "$PHASE" ]] && return 0
  case "$PHASE" in
    3) [[ "$1" == "1" || "$1" == "2" || "$1" == "4" || "$1" == "6" ]] ;;
    4|5|6) [[ "$1" == "1" || "$1" == "2" || "$1" == "3" ]] ;;
    7) [[ "$1" == "1" || "$1" == "3" || "$1" == "5" || "$1" == "6" || "$1" == "7" || "$1" == "8" ]] ;;
    8|9) return 0 ;;
    *) return 0 ;;
  esac
}

sub_runs() {
  # $1 = sub-id (e.g. "1a-skill", "1a-rules", "1a-workflows", "1a-gotchas", "1b", "1c").
  # Sub-gates let a phase run only the part of a section that applies.
  # Returns 0 (run) or 1 (skip).
  [[ -z "$PHASE" ]] && return 0
  case "$PHASE" in
    3) [[ "$1" == "1a-skill" ]] ;;
    4) [[ "$1" == "1a-skill" || "$1" == "1a-rules" ]] ;;
    5) [[ "$1" == "1a-skill" || "$1" == "1a-rules" || "$1" == "1a-workflows" ]] ;;
    6) [[ "$1" == "1a-skill" || "$1" == "1a-rules" || "$1" == "1a-workflows" || "$1" == "1a-gotchas" ]] ;;
    7) [[ "$1" == "1b" || "$1" == "1c" ]] ;;
    8|9) return 0 ;;
    *) return 0 ;;
  esac
}

section() {
  # Print the banner and return 0 if this section should run; else print a skip notice and return 1.
  if phase_runs "$1"; then
    echo ""
    echo "═══ $1. $2 ═══"
    return 0
  else
    echo ""
    echo "─── (skipped section $1: $2 — not relevant for --phase $PHASE) ───"
    return 1
  fi
}

# Accept a skill name (standard skills/<name> layout), a skill directory path,
# or "." / cwd — meta-repo layouts like apps/<app>/skills/<name> and
# self-hosting roots are valid skill roots too. skills/$NAME stays the fallback.
if [[ -f "$NAME/SKILL.md" ]]; then
  SKILL_DIR="${NAME%/}"
  NAME="$(awk -F: '/^name:/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}' "$SKILL_DIR/SKILL.md")"
  NAME="${NAME:-$(basename "$SKILL_DIR")}"
elif [[ -f "$NAME/SKILL.md.template" ]]; then
  SKILL_DIR="${NAME%/}"
  NAME="$(basename "$SKILL_DIR")"
else
  ROOT_SKILL_NAME=""
  if [[ -f "SKILL.md" ]]; then
    ROOT_SKILL_NAME="$(awk -F: '/^name:/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}' SKILL.md)"
  fi
  if [[ -f "skills/$NAME/SKILL.md" ]]; then
    SKILL_DIR="skills/$NAME"
  elif [[ -n "$ROOT_SKILL_NAME" && "$ROOT_SKILL_NAME" == "$NAME" ]]; then
    SKILL_DIR="."
    NAME="$ROOT_SKILL_NAME"
  else
    SKILL_DIR="skills/$NAME"
  fi
fi
if [[ -f "$SKILL_DIR/references/self-hosting-routing.yaml" && ! -f "$SKILL_DIR/routing.yaml" ]]; then
  SELF_HOSTING_ROOT=1
fi
SKILL_MD="$SKILL_DIR/SKILL.md"
ROUTING_YAML="$SKILL_DIR/routing.yaml"
DOMAIN_ROUTING_YAML="$SKILL_DIR/domain-routing.yaml"
CURSOR_ENTRY=".cursor/skills/$NAME/SKILL.md"
CODE_ROOT_REL=""
CODE_ROOT_DIR=""
CODE_ROOT_RESOLUTION_ERROR=""

# Two-root layout (skeleton-flesh-split.md §7): when routing.yaml declares
# path_resolution, thin shells / Cursor entries may be rendered by an external
# assembler outside this repo — those absence checks downgrade to WARN.
# Single-root skills keep them as FAIL (a missing shell there is a real fault).
TWO_ROOT=0
if [[ -f "$ROUTING_YAML" ]] && grep -q '^path_resolution:' "$ROUTING_YAML"; then
  TWO_ROOT=1
fi

if [[ -f "$ROUTING_YAML" ]]; then
  CODE_ROOT_REL=$(awk '
    /^path_resolution:/ { in_paths=1; next }
    in_paths && /^[^[:space:]]/ { exit }
    in_paths && /^  code_root:/ { in_code=1; next }
    in_code && /^    root:/ {
      sub(/^    root:[[:space:]]*/, "")
      gsub(/^["'\'' ]+|["'\'' ]+$/, "")
      print
      exit
    }
    in_code && /^  [[:alnum:]_-]+:/ { exit }
  ' "$ROUTING_YAML")
fi

if [[ -n "$CODE_ROOT_REL" && -n "$WORKSPACE_ROOT" ]]; then
  if CODE_ROOT_DIR=$(python3 - "$WORKSPACE_ROOT" "$CODE_ROOT_REL" <<'PY'
from pathlib import Path
import sys

workspace = Path(sys.argv[1]).resolve()
candidate = (workspace / sys.argv[2]).resolve()
try:
    candidate.relative_to(workspace)
except ValueError:
    raise SystemExit(2)
print(candidate)
PY
  ); then
    :
  else
    CODE_ROOT_DIR=""
    CODE_ROOT_RESOLUTION_ERROR="code_root.root escapes --workspace-root: $CODE_ROOT_REL"
  fi
fi

PASS=0
FAIL=0
WARN=0

pass() { ((PASS++)); echo "  ✅ $1"; }
fail() { ((FAIL++)); echo "  ❌ $1"; }
warn() { ((WARN++)); echo "  ⚠️  $1"; }

# .maintenance-log.yaml helpers — schema + protocol: workflows/maintain-docs.md § Step 7.
read_ledger_last_tier2() {
  # $1=ledger, $2=relative file path. Echoes last_tier2 (YYYY-MM-DD) or empty.
  [[ -f "$1" ]] || return 0
  awk -v t="$2" '
    /^[[:space:]]*-[[:space:]]*path:/ { sub(/.*path:[[:space:]]*/,""); gsub(/["'\'']/,""); cur=$0; next }
    cur==t && /^[[:space:]]+last_tier2:/ { sub(/.*last_tier2:[[:space:]]*/,""); gsub(/["'\'']/,""); if ($0!="") { print; exit } }
  ' "$1"
}
days_since() {
  # $1=YYYY-MM-DD. Echoes integer days (-1 if empty/unparseable). BSD + GNU date compatible.
  [[ -z "$1" ]] && { echo -1; return; }
  local s
  s=$(date -j -f "%Y-%m-%d" "$1" "+%s" 2>/dev/null) || s=$(date -d "$1" "+%s" 2>/dev/null) || { echo -1; return; }
  echo $(( ($(date +%s) - s) / 86400 ))
}

# ── 1. Structural Checks ─────────────────────────────────────────────
has_routing_bootstrap() {
  local file="$1"
  grep -q 'routing.yaml' "$file" 2>/dev/null
}

has_skill_bootstrap() {
  local file="$1"
  grep -qE "skills/$NAME/SKILL\.md|(^|[^[:alnum:]_])SKILL\.md([^[:alnum:]_]|$)" "$file" 2>/dev/null
}

if section 1 "Structural Checks"; then :

# 1a-skill. SKILL.md exists (Phase 3+)
if sub_runs "1a-skill"; then
  if [[ -f "$SKILL_MD" ]]; then
    pass "$SKILL_MD exists"
  else
    fail "$SKILL_MD missing"
  fi
  if [[ -f "$ROUTING_YAML" ]]; then
    pass "$ROUTING_YAML exists"
  elif grep -qE '## (Common Tasks|常见任务)' "$SKILL_MD" 2>/dev/null; then
    pass "Single-file routing responsibility stays in SKILL.md"
  else
    fail "$ROUTING_YAML missing and SKILL.md has no direct Common Tasks owner"
  fi
fi

# 1a-rules. constraint surface: rules/ OR architecture/ OR conventions/ (Phase 4+)
# A skill carries constraints in rules/ (folder-light) or, after the rate-of-change
# split, in architecture/ (stable) + conventions/ (volatile). Any non-empty one passes.
if sub_runs "1a-rules"; then
  CONSTRAINT_N=0
  CONSTRAINT_DIR_N=0
  for d in rules architecture conventions; do
    if [[ -d "$SKILL_DIR/$d" ]]; then
      CONSTRAINT_DIR_N=$((CONSTRAINT_DIR_N + 1))
      n=$(find "$SKILL_DIR/$d" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
      CONSTRAINT_N=$((CONSTRAINT_N + n))
    fi
  done
  if [[ "$CONSTRAINT_N" -gt 0 ]]; then
    pass "constraint surface: $CONSTRAINT_N file(s) across rules/ architecture/ conventions/"
  elif [[ "$CONSTRAINT_DIR_N" -eq 0 ]]; then
    pass "no separate constraint surface materialized; SKILL.md owns the current rules"
  else
    fail "materialized constraint directories contain no .md files"
  fi
fi

# 1a-workflows. workflows/*.md (Phase 5+)
if sub_runs "1a-workflows"; then
  WORKFLOW_N=$(find "$SKILL_DIR/workflows" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ' || true)
  if [[ ! -d "$SKILL_DIR/workflows" ]]; then
    pass "no separate workflows materialized; SKILL.md owns the direct procedure"
  elif [[ "$WORKFLOW_N" -gt 0 ]]; then
    pass "workflow surface: $WORKFLOW_N file(s)"
  else
    fail "materialized workflows/ directory contains no .md files"
  fi

  if [[ -f "$ROUTING_YAML" ]]; then
    ROUTED_WORKFLOWS=()
    while IFS= read -r workflow; do
      [[ -n "$workflow" ]] || continue
      [[ "$workflow" == *"FILL:"* ]] && continue
      workflow="${workflow#skill:}"
      [[ "$workflow" == workflows/* ]] || continue
      ROUTED_WORKFLOWS+=("${workflow%%#*}")
    done < <(awk '
      /^[[:space:]]+workflow:/ {
        sub(/^[[:space:]]+workflow:[[:space:]]*/, "")
        gsub(/^"|"$/, "")
        print
      }
    ' "$ROUTING_YAML")

    if [[ ${#ROUTED_WORKFLOWS[@]} -eq 0 ]]; then
      warn "routing.yaml has no concrete workflows/*.md entries yet"
    else
      UNIQUE_ROUTED_WORKFLOWS=($(printf '%s\n' "${ROUTED_WORKFLOWS[@]}" | sort -u))
      for workflow in "${UNIQUE_ROUTED_WORKFLOWS[@]}"; do
        if [[ -f "$SKILL_DIR/$workflow" ]]; then
          pass "$SKILL_DIR/$workflow exists (from routing.yaml)"
        else
          fail "$SKILL_DIR/$workflow missing (referenced by routing.yaml)"
        fi
      done
    fi
  fi
fi

# 1a-gotchas. gotchas/ tier, or references/gotchas.md, or equivalent (Phase 6+)
if sub_runs "1a-gotchas"; then
  if [[ -d "$SKILL_DIR/gotchas" ]] && find "$SKILL_DIR/gotchas" -maxdepth 1 -name '*.md' 2>/dev/null | grep -q .; then
    GOTCHA_N=$(find "$SKILL_DIR/gotchas" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    pass "gotchas/ tier with $GOTCHA_N file(s)"
  elif [[ -f "$SKILL_DIR/references/gotchas.md" ]]; then
    pass "$SKILL_DIR/references/gotchas.md exists"
  else
    GOTCHA_FILE=$(find "$SKILL_DIR/references" -maxdepth 1 -type f \( -name '*pitfall*' -o -name '*gotcha*' \) 2>/dev/null | head -1 || true)
    if [[ -n "$GOTCHA_FILE" ]]; then
      pass "gotchas/pitfalls reference found: $(basename "$GOTCHA_FILE")"
    elif [[ ! -d "$SKILL_DIR/gotchas" && ! -d "$SKILL_DIR/references" ]]; then
      pass "no separate gotcha owner materialized"
    else
      pass "no gotcha owner materialized in the current content directories"
    fi
  fi
fi

# 1b. Cursor registration entry (Phase 7+)
if sub_runs "1b"; then
  if [[ -f "$CURSOR_ENTRY" ]]; then
    pass "Cursor entry $CURSOR_ENTRY exists"
  elif [[ "$TWO_ROOT" == "1" ]]; then
    warn "Cursor entry $CURSOR_ENTRY missing (two-root layout: entry may be rendered by an external assembler — verify there)"
  else
    pass "Cursor registration not materialized for this Skill"
  fi
fi

# 1c. Thin shells + .cursor/rules (Phase 7+)
if sub_runs "1c"; then
  SHELL_COUNT=0
  for shell in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
    [[ -f "$shell" ]] || continue
    SHELL_COUNT=$((SHELL_COUNT + 1))
    if [[ -f "$ROUTING_YAML" ]] && has_routing_bootstrap "$shell"; then
      pass "$shell exists with routing.yaml bootstrap"
    elif [[ ! -f "$ROUTING_YAML" ]] && has_skill_bootstrap "$shell"; then
      pass "$shell exists with direct SKILL.md bootstrap"
    elif [[ -f "$ROUTING_YAML" ]]; then
      fail "$shell exists but does not point at routing.yaml"
    else
      fail "$shell exists but does not point at the Single-file SKILL.md owner"
    fi
  done
  [[ "$SHELL_COUNT" -gt 0 ]] || pass "no root harness shells materialized"

  # .codex/instructions.md is an optional compatibility mirror. If a project
  # opts in, validate the routing bootstrap; otherwise stay silent.
  if [[ -f ".codex/instructions.md" ]]; then
    if [[ -f "$ROUTING_YAML" ]] && has_routing_bootstrap ".codex/instructions.md"; then
      pass ".codex/instructions.md exists with routing.yaml bootstrap"
    elif [[ ! -f "$ROUTING_YAML" ]] && has_skill_bootstrap ".codex/instructions.md"; then
      pass ".codex/instructions.md exists with direct SKILL.md bootstrap"
    elif [[ -f "$ROUTING_YAML" ]]; then
      fail ".codex/instructions.md exists but does not point at routing.yaml"
    else
      fail ".codex/instructions.md exists but does not point at the Single-file SKILL.md owner"
    fi
  fi

  MDC_COUNT=$(find .cursor/rules -name '*.mdc' 2>/dev/null | wc -l | tr -d ' ' || true)
  if [[ "$MDC_COUNT" -gt 0 ]]; then
    pass ".cursor/rules/ has $MDC_COUNT .mdc file(s)"
  elif [[ "$TWO_ROOT" == "1" ]]; then
    warn ".cursor/rules/ has no .mdc files (two-root layout: Cursor shell may be rendered by an external assembler)"
  else
    pass "no Cursor rule shell materialized"
  fi

  # 1d. SessionStart re-injection hook (WARN-only — harness-dependent).
  # Pitfall #7: on /clear or /compact the harness summarizes context and the
  # The SKILL.md action hook and routing bootstrap can drop out. A SessionStart hook re-injects them. Never
  # fails — not every harness supports hooks. Only checked when .claude/ exists.
  # Skill-aware: in a multi-skill repo, having *a* hook is not enough — it must
  # re-inject THIS skill's router (skills/$NAME/), else $NAME stays unprotected.
  if [[ -d ".claude" ]]; then
    if grep -qs 'SessionStart' .claude/settings.json .claude/settings.local.json 2>/dev/null; then
      SKILL_COUNT=$(find skills -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ' || true)
      if [[ "$SKILL_COUNT" -le 1 ]] || grep -qs "skills/$NAME/" .claude/settings.json .claude/settings.local.json 2>/dev/null; then
        pass "SessionStart re-injection hook wired for this skill (.claude/settings*.json)"
      else
        warn "a SessionStart hook exists but does not reference skills/$NAME/ — in this multi-skill repo this skill's router may not be re-injected after /clear or /compact (Pitfall #7)"
      fi
    else
      warn "no SessionStart hook in .claude/settings*.json — the routing bootstrap can silently drop after /clear or /compact (Pitfall #7); see templates/hooks/session-start"
    fi
  fi
fi

fi  # end section 1

# ── 2. Line Count Budgets ─────────────────────────────────────────────
if section 2 "Line Count Budgets"; then :

check_lines() {
  local file="$1" max="$2" label="$3"
  if [[ ! -f "$file" ]]; then return 0; fi
  local lines
  lines=$(wc -l < "$file" | tr -d ' ')
  if [[ "$lines" -le "$max" ]]; then
    pass "$label: $lines lines (≤ $max)"
  else
    fail "$label: $lines lines (exceeds $max limit)"
  fi
}

check_routing_budget() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  check_lines "$file" 140 "routing.yaml task routes"
  if grep -q '^domain_overlays:' "$file"; then
    fail "routing.yaml contains legacy domain_overlays (move them to domain-routing.yaml)"
  fi
}

check_domain_routing_budget() {
  [[ -f "$DOMAIN_ROUTING_YAML" ]] || return 0
  check_lines "$DOMAIN_ROUTING_YAML" 160 "domain-routing.yaml"
}

# SKILL.md uses dual budgets — description is the activation gate (frontmatter)
# and benefits from rich quoted trigger phrases; body is the navigation hub
# (Always Read / Common Tasks / boundaries) and must stay tight. Splitting the
# budgets prevents description quality from cannibalizing body clarity (and
# vice versa). Hard caps: description ≤ 25 lines, body ≤ 90 lines.
check_skill_md_budget() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  local desc_lines body_lines
  desc_lines=$(awk '
    /^---$/ { f++; next }
    f==1 && /^description:/ { in_desc=1; count++; next }
    f==1 && in_desc && /^[a-zA-Z_][a-zA-Z0-9_-]*:/ { in_desc=0 }
    f==1 && in_desc { count++ }
    END { print count+0 }
  ' "$file")
  body_lines=$(awk '
    /^---$/ { f++; next }
    f >= 2 { count++ }
    END { print count+0 }
  ' "$file")
  # If there is no frontmatter (single --- block or none), count whole file as body
  if [[ "$body_lines" -eq 0 ]]; then
    body_lines=$(wc -l < "$file" | tr -d ' ')
  fi
  if [[ "$desc_lines" -le 25 ]]; then
    pass "SKILL.md description: $desc_lines lines (≤ 25)"
  else
    fail "SKILL.md description: $desc_lines lines (exceeds 25 limit) — split intent clusters or shorten activate-when clause"
  fi
  if [[ "$body_lines" -le 90 ]]; then
    pass "SKILL.md body: $body_lines lines (≤ 90)"
  else
    fail "SKILL.md body: $body_lines lines (exceeds 90 limit) — move detail to architecture/ conventions/ gotchas/ workflows/ references/"
  fi
}

check_skill_md_budget "$SKILL_MD"
check_routing_budget "$ROUTING_YAML"
check_domain_routing_budget
for shell in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
  check_lines "$shell" 60 "$shell (thin shell)"
done
check_lines "$CURSOR_ENTRY" 60 "Cursor entry"

# 2a. gotchas / pitfall files: enforce $GOTCHAS_MAX_LINES cap, fail on exact-dup `## ` headings,
# and on dup also consult `.maintenance-log.yaml` to advise full Tier-2 reorg vs one-off dedup.
# Rationale + protocol: workflows/maintain-docs.md § Step 1b + Step 7, workflows/update-rules.md § Rule Deprecation.
LEDGER="$SKILL_DIR/.maintenance-log.yaml"
for gotcha_file in "$SKILL_DIR/references"/*gotcha*.md "$SKILL_DIR/references"/*pitfall*.md "$SKILL_DIR/gotchas"/*.md; do
  [[ -f "$gotcha_file" ]] || continue
  [[ "$(basename "$gotcha_file")" == "index.md" ]] && continue
  check_lines "$gotcha_file" "$GOTCHAS_MAX_LINES" "$(basename "$gotcha_file") (pitfall log)"
  DUPLICATE_HEADINGS=$(grep "^## " "$gotcha_file" | sort | uniq -d || true)
  if [[ -n "$DUPLICATE_HEADINGS" ]]; then
    fail "$(basename "$gotcha_file") has duplicate ## headings — same entry recorded twice"
    echo "$DUPLICATE_HEADINGS" | head -5 | sed 's/^/       duplicate: /'
    DUP_COUNT=$(echo "$DUPLICATE_HEADINGS" | wc -l | tr -d ' ')
    [[ "$DUP_COUNT" -gt 5 ]] && echo "       … and $((DUP_COUNT - 5)) more duplicate(s)"
    REL=${gotcha_file#$SKILL_DIR/}
    LT=$(read_ledger_last_tier2 "$LEDGER" "$REL")
    if [[ -z "$LT" ]]; then
      echo "       Tier-2 hint: no ledger entry for $REL — run baseline (maintain-docs.md § Step 7)"
    else
      AGE=$(days_since "$LT")
      if [[ "$AGE" -lt 0 ]]; then
        echo "       Tier-2 hint: ledger date '$LT' unparseable; check $LEDGER"
      elif [[ "$AGE" -gt 30 ]]; then
        echo "       Tier-2 hint: last reorg $AGE days ago ($LT) > 30d — run full Tier-2"
      else
        echo "       Tier-2 hint: last reorg $AGE days ago ($LT) ≤ 30d — dedup only, skip full Tier-2"
      fi
    fi
  else
    pass "$(basename "$gotcha_file"): no duplicate ## headings"
  fi
done

# 2b. Canonical task-route count — routing.yaml is the sole route-data owner.
if [[ -f "$ROUTING_YAML" ]]; then
  TASK_ROUTE_COUNT=$(awk '
    /^tasks:/ { in_tasks=1; next }
    in_tasks && /^[^[:space:]#]/ { exit }
    in_tasks && /^  - id:/ { count++ }
    END { print count+0 }
  ' "$ROUTING_YAML")
  if [[ "$TASK_ROUTE_COUNT" -eq 0 ]]; then
    fail "routing.yaml has no task routes"
  elif [[ "$TASK_ROUTE_COUNT" -le "$TASK_ROUTES_MAX" ]]; then
    pass "routing.yaml: $TASK_ROUTE_COUNT task routes (≤ $TASK_ROUTES_MAX)"
  else
    fail "routing.yaml: $TASK_ROUTE_COUNT task routes (exceeds $TASK_ROUTES_MAX — evaluate fission or route consolidation)"
  fi
fi

fi  # end section 2

# ── 3. Placeholder Residue ────────────────────────────────────────────
if section 3 "Placeholder Residue"; then :

# 3a. {{...}} placeholders should all be replaced
# Exclude JSX/code patterns like styles={{ }}, className={{ }}, etc.
RESIDUE_SCAN_TARGETS=("$SKILL_DIR" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor)
if [[ "$SELF_HOSTING_ROOT" == "1" ]]; then
  # The upstream authoring repo intentionally contains template placeholders
  # and prose that teaches downstream FILL handling. Its runtime entry surfaces
  # must still be fully materialized.
  RESIDUE_SCAN_TARGETS=("$SKILL_MD" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor)
fi
PLACEHOLDER_HITS=$(grep -rn '{{' "${RESIDUE_SCAN_TARGETS[@]}" 2>/dev/null \
  | grep -v 'node_modules' \
  | grep -v '/scripts/' \
  | grep -v '={{' \
  | grep -v '{{ *}}' \
  | grep -v 'styles={{' \
  | grep -v 'style={{' \
  | grep -v 'className={{' \
  || true)
if [[ -z "$PLACEHOLDER_HITS" ]]; then
  pass "No {{...}} placeholders remaining"
else
  fail "Unresolved {{...}} placeholders found:"
  echo "$PLACEHOLDER_HITS" | head -20 | sed 's/^/       /'
fi

# 3b. <!-- FILL: --> markers should all be replaced
FILL_HITS=$(grep -rn 'FILL:' "${RESIDUE_SCAN_TARGETS[@]}" 2>/dev/null | grep -v 'node_modules' | grep -v '/scripts/' || true)
if [[ -z "$FILL_HITS" ]]; then
  pass "No <!-- FILL: --> markers remaining"
else
  fail "Unresolved FILL markers found ($(echo "$FILL_HITS" | wc -l | tr -d ' ') hits):"
  echo "$FILL_HITS" | head -20 | sed 's/^/       /'
fi

# 3c. Renaming an unresolved marker is not migration. Reject the historical
# `FILL:` -> `FILLED:` laundering pattern explicitly.
RENAMED_FILL_HITS=$(grep -rnE '(^|[[:space:]#<])FILLED:' "${RESIDUE_SCAN_TARGETS[@]}" 2>/dev/null | grep -v 'node_modules' | grep -v '/scripts/' || true)
if [[ -z "$RENAMED_FILL_HITS" ]]; then
  pass "No renamed FILLED: markers"
else
  fail "Renamed FILLED: markers found; replace migration work with real project content:"
  echo "$RENAMED_FILL_HITS" | head -20 | sed 's/^/       /'
fi

fi  # end section 3

# ── 4. SKILL.md Content Quality ───────────────────────────────────────
if section 4 "SKILL.md Content Quality"; then :

if [[ -f "$SKILL_MD" ]]; then
  # 4a. Has frontmatter with name and description
  if head -5 "$SKILL_MD" | grep -q '^---'; then
    pass "SKILL.md has YAML frontmatter"
  else
    fail "SKILL.md missing YAML frontmatter"
  fi

  # 4b. description is long enough for reliable activation.
  # English-like text uses word count; Chinese/Japanese/Korean text may not
  # contain spaces, so accept a CJK character threshold as an alternative.
  # Extract YAML description: multi-line value (stops at next top-level key or ---)
  DESC=$(awk '
    /^description:/ { found=1; sub(/^description:[[:space:]]*>?[[:space:]]*/, ""); if ($0 != "") print; next }
    found && /^[a-z].*:/ { exit }
    found && /^---/ { exit }
    found { print }
  ' "$SKILL_MD" | tr -s ' \n' ' ')
  WORD_COUNT=$(echo "$DESC" | wc -w | tr -d ' ')
  CJK_COUNT=0
  if command -v perl &>/dev/null; then
    CJK_COUNT=$(printf '%s' "$DESC" | perl -CS -Mutf8 -ne '$n += (() = /\p{Han}|\p{Hiragana}|\p{Katakana}|\p{Hangul}/g); END { print $n || 0 }' 2>/dev/null || printf '0')
  fi
  if [[ "$WORD_COUNT" -ge "$DESCRIPTION_MIN_WORDS" || "$CJK_COUNT" -ge "$DESCRIPTION_MIN_CJK_CHARS" ]]; then
    pass "description length OK ($WORD_COUNT words, $CJK_COUNT CJK chars; need ≥ $DESCRIPTION_MIN_WORDS words or ≥ $DESCRIPTION_MIN_CJK_CHARS CJK chars)"
  else
    fail "description is too short ($WORD_COUNT words, $CJK_COUNT CJK chars; need ≥ $DESCRIPTION_MIN_WORDS words or ≥ $DESCRIPTION_MIN_CJK_CHARS CJK chars)"
  fi

  # 4c. description has quoted trigger phrases
  TRIGGER_COUNT=$(echo "$DESC" | grep -o '"[^"]*"' | wc -l | tr -d ' ' || true)
  if [[ "$TRIGGER_COUNT" -ge 2 ]]; then
    pass "description has $TRIGGER_COUNT quoted trigger phrases (≥ 2)"
  else
    fail "description has only $TRIGGER_COUNT quoted trigger phrases (need ≥ 2)"
  fi

  # 4c-stuffing. Too MANY quoted phrases = workflow-keyword stuffing. The
  # description is a coarse activation gate; exact task phrases live in routing.yaml.
  if [[ "$TRIGGER_COUNT" -gt "$DESCRIPTION_MAX_TRIGGERS" ]]; then
    warn "description has $TRIGGER_COUNT quoted phrases (> $DESCRIPTION_MAX_TRIGGERS) — likely workflow-keyword stuffing; keep it domain-level, move task keywords to routing.yaml"
  fi

  # 4d. Has Always Read section (English or Chinese)
  if grep -qE '## (Always Read|必读)' "$SKILL_MD"; then
    pass "SKILL.md has Always Read / 必读 section"
  else
    fail "SKILL.md missing Always Read / 必读 section"
  fi

  # 4e. Has Common Tasks section (English or Chinese)
  if grep -qE '## (Common Tasks|常见任务)' "$SKILL_MD"; then
    pass "SKILL.md has Common Tasks / 常见任务 section"
  else
    fail "SKILL.md missing Common Tasks / 常见任务 section"
  fi

  # 4f. Has Known Gotchas section (English or Chinese, flexible matching)
  if grep -qiE '## .*(Gotcha|Known|坑|Pitfall)' "$SKILL_MD"; then
    pass "SKILL.md has Known Gotchas / 坑点 section"
  else
    warn "SKILL.md missing Known Gotchas section (acceptable for fresh migration, should grow via AAR)"
  fi

  # 4g. Core Principles have ✓ Check: verification sentences
  if grep -qiE '## .*(Core Principles|核心原则|Principles)' "$SKILL_MD"; then
    principle_count=$(grep -cE '^\s*[0-9]+\.\s+\*\*' "$SKILL_MD" || true)
    check_count=$(grep -c '✓ Check:' "$SKILL_MD" || true)
    if [[ "$principle_count" -gt 0 ]]; then
      if [[ "$check_count" -ge "$principle_count" ]]; then
        pass "All $principle_count principles have ✓ Check: verification sentences"
      elif [[ "$check_count" -gt 0 ]]; then
        warn "SKILL.md has $principle_count principles but only $check_count ✓ Check: lines — some principles are declarative-only"
      else
        warn "SKILL.md has $principle_count principles but no ✓ Check: lines — all principles are declarative-only (add verification sentences)"
      fi
    fi
  fi

  # 4h. (removed 2026-05-19) Description scope + multi-skill overlap.
  #     The dedicated script `check-description-routing.sh` was deleted —
  #     it parsed 125 lines of YAML to surface things a human eyeballs in
  #     30 seconds when re-reading `description`. Manual re-read is the
  #     guidance now; if you genuinely cannot tell whether description is
  #     too narrow/broad, that is content judgment, not a tooling gap.
fi

fi  # end section 4

# ── 5. Routing Completeness ──────────────────────────────────────────
if section 5 "Routing Completeness (canonical routing.yaml)"; then :

if [[ "$SELF_HOSTING_ROOT" == "1" ]]; then
  SELF_ROUTING_YAML="$SKILL_DIR/references/self-hosting-routing.yaml"
  SELF_ROUTING_CHECK="$SKILL_DIR/scripts/check-self-shells.sh"
  if [[ ! -f "$SELF_ROUTING_YAML" ]]; then
    fail "self-hosting routing owner missing: $SELF_ROUTING_YAML"
  elif [[ ! -f "$SELF_ROUTING_CHECK" ]]; then
    fail "self-hosting routing check missing: $SELF_ROUTING_CHECK"
  elif (cd "$SKILL_DIR" && bash scripts/check-self-shells.sh >/dev/null); then
    pass "self-hosting routing manifest and generated shells are valid"
  else
    fail "self-hosting routing manifest or generated shell blocks drifted"
  fi
elif [[ -f "$SKILL_MD" ]]; then
  ROUTING_SYNC="$SKILL_DIR/scripts/sync-routing.sh"
  if [[ ! -f "$ROUTING_SYNC" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROUTING_SYNC="$SCRIPT_DIR/sync-routing.sh"
  fi
  if [[ -f "$ROUTING_YAML" && -f "$ROUTING_SYNC" ]]; then
    if ROUTING_OUTPUT=$(bash "$ROUTING_SYNC" "$SKILL_DIR" --check 2>&1); then
      pass "routing.yaml structure, paths, and generated blocks are valid"
    else
      fail "routing.yaml generated blocks drifted"
      printf '%s\n' "$ROUTING_OUTPUT" | sed 's/^/       /' | head -50
    fi
  elif [[ -f "$ROUTING_YAML" ]]; then
    fail "routing.yaml exists but no sync-routing.sh is available to verify its generated consumers"
  else
    if grep -q 'routing.yaml' "$SKILL_MD"; then
      fail "Single-file SKILL.md references routing.yaml even though no routing manifest exists"
    else
      DIRECT_TASK_COUNT=$(awk '
        /^## (Common Tasks|常见任务)/ { in_tasks=1; next }
        in_tasks && /^## / { exit }
        in_tasks && /^[[:space:]]*[-*][[:space:]]+/ && $0 !~ /<[^>]+>/ { count++ }
        END { print count+0 }
      ' "$SKILL_MD")
      if [[ "$DIRECT_TASK_COUNT" -gt 0 ]]; then
        pass "Single-file SKILL.md owns $DIRECT_TASK_COUNT concrete direct task entr$( [[ "$DIRECT_TASK_COUNT" -eq 1 ]] && printf 'y' || printf 'ies' )"
      else
        fail "Single-file SKILL.md has no concrete direct task entry"
      fi
    fi
  fi

fi

fi  # end section 5

# ── 6. Description Consistency ────────────────────────────────────────
if section 6 "Description Consistency"; then :

if [[ -f "$SKILL_MD" ]] && [[ -f "$CURSOR_ENTRY" ]]; then
  # Extract description from both files using awk for reliable YAML parsing
  extract_desc() {
    awk '
      /^description:/ { found=1; sub(/^description:[[:space:]]*>?[[:space:]]*/, ""); if ($0 != "") print; next }
      found && /^[a-z].*:/ { exit }
      found && /^---/ { exit }
      found { print }
    ' "$1" | tr -s ' \n' ' ' | sed 's/^ *//;s/ *$//'
  }
  DESC_FORMAL=$(extract_desc "$SKILL_MD")
  DESC_CURSOR=$(extract_desc "$CURSOR_ENTRY")

  BOTH_UNFILLED=false
  if [[ ( "$DESC_FORMAL" == *"FILL:"* || "$DESC_FORMAL" == *"<trigger phrase"* ) \
     && ( "$DESC_CURSOR" == *"FILL:"* || "$DESC_CURSOR" == *"<trigger phrase"* ) ]]; then
    BOTH_UNFILLED=true
  fi

  if $BOTH_UNFILLED; then
    warn "description in both SKILL.md and Cursor entry still contains FILL placeholders — fill them (identically) before shipping"
  elif [[ "$DESC_FORMAL" == "$DESC_CURSOR" ]]; then
    pass "description matches between SKILL.md and Cursor entry"
  else
    fail "description MISMATCH between SKILL.md and Cursor entry"
    echo "       Formal: ${DESC_FORMAL:0:80}..."
    echo "       Cursor: ${DESC_CURSOR:0:80}..."
  fi
fi

fi  # end section 6

# ── 7. Shell Routing Table Consistency ────────────────────────────────
if section 7 "Shell Routing Consistency"; then :

if [[ -f "scripts/check-self-shells.sh" && -f "references/self-hosting-routing.yaml" ]]; then
  if bash scripts/check-self-shells.sh >/dev/null; then
    pass "self-hosting shells match generated content"
  else
    fail "self-hosting shells drifted from generated content"
    echo "       Run: bash scripts/sync-self-shells.sh"
  fi
fi

# Check that every materialized shell points at the actual routing owner instead
# of carrying an unowned hand-maintained table.
SHELL_FILES=(AGENTS.md CLAUDE.md CODEX.md GEMINI.md)
# Optional: include .codex/instructions.md only when the project opts into the compatibility mirror.
[[ -f ".codex/instructions.md" ]] && SHELL_FILES+=(".codex/instructions.md")
while IFS= read -r cursor_rule; do
  SHELL_FILES+=("$cursor_rule")
done < <(find .cursor/rules -maxdepth 1 -name '*.mdc' -type f 2>/dev/null | sort)
for shell in "${SHELL_FILES[@]}"; do
  if [[ ! -f "$shell" ]]; then continue; fi
  if [[ -f "$ROUTING_YAML" ]] && grep -q 'routing.yaml' "$shell"; then
    pass "$shell points at routing.yaml"
  elif [[ ! -f "$ROUTING_YAML" ]] && has_skill_bootstrap "$shell"; then
    pass "$shell points at the Single-file SKILL.md owner"
  elif [[ -f "$ROUTING_YAML" ]]; then
    fail "$shell does not point at routing.yaml"
  else
    fail "$shell does not point at the Single-file SKILL.md owner"
  fi
done

fi  # end section 7

# ── 8. Local Reference Integrity ─────────────────────────────────────
# Catches path drift in Markdown links, local heading fragments, and path-like
# inline code spans. Fenced examples are excluded so sample commands do not
# become runtime dependencies. For a declared code_root.root, --workspace-root
# also turns this into the one-command, namespace-isolated two-root integrity gate.
if section 8 "Local Reference Integrity"; then :

# Layout detection: downstream uses skills/<name>/, self-hosting puts SKILL.md
# at repo root. Pick the right scan root.
if [[ -d "$SKILL_DIR" ]]; then
  LINK_SCAN_ROOT="$SKILL_DIR"
else
  LINK_SCAN_ROOT="."
fi

# Collect all .md files in scope. Exclude templates/ (intentional placeholder
# paths), node_modules/, .git/, and posts/ (drafts that may reference external
# example files). Also include harness shells and Cursor entry, which live
# outside SCAN_ROOT in the self-hosting case.
LINK_SCAN_FILES=()
while IFS= read -r f; do
  LINK_SCAN_FILES+=("$f")
done < <(find "$LINK_SCAN_ROOT" -type f -name '*.md' \
  -not -path '*/templates/*' \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/posts/*' \
  2>/dev/null)

if [[ -n "$CODE_ROOT_DIR" && -d "$CODE_ROOT_DIR" ]]; then
  while IFS= read -r f; do
    LINK_SCAN_FILES+=("$f")
  done < <(find "$CODE_ROOT_DIR" -type f \( -name '*.md' -o -name '*.mdc' \) \
    -not -path '*/node_modules/*' \
    -not -path '*/.git/*' \
    2>/dev/null)
fi

for shell in AGENTS.md CLAUDE.md CODEX.md GEMINI.md .codex/instructions.md "$CURSOR_ENTRY"; do
  # .codex/instructions.md is optional — only included when the project keeps it.
  [[ -f "$shell" ]] && LINK_SCAN_FILES+=("$shell")
done
while IFS= read -r mdc; do
  LINK_SCAN_FILES+=("$mdc")
done < <(find .cursor/rules -maxdepth 1 -name '*.mdc' -type f 2>/dev/null)

# Deduplicate
if [[ ${#LINK_SCAN_FILES[@]} -gt 0 ]]; then
  IFS=$'\n' LINK_SCAN_FILES=($(printf '%s\n' "${LINK_SCAN_FILES[@]}" | sort -u))
  unset IFS
fi

REFERENCE_OUTPUT=""
REFERENCE_REPORT="$(mktemp)"
REFERENCE_INPUT="$(mktemp)"
if [[ ${#LINK_SCAN_FILES[@]} -gt 0 ]]; then
  printf '%s\0' "${LINK_SCAN_FILES[@]}" > "$REFERENCE_INPUT"
fi
if python3 - "$SKILL_DIR" "${CODE_ROOT_DIR:-}" "$PWD" "${WORKSPACE_ROOT:-}" "$REFERENCE_INPUT" "$SELF_HOSTING_ROOT" >"$REFERENCE_REPORT" 2>&1 <<'PY'
from __future__ import annotations

import html
import os
import re
import sys
import unicodedata
from pathlib import Path
from urllib.parse import unquote

skill_root = Path(sys.argv[1]).resolve()
code_root = Path(sys.argv[2]).resolve() if sys.argv[2] else None
project_root = Path(sys.argv[3]).resolve()
workspace_root = Path(sys.argv[4]).resolve() if sys.argv[4] else project_root
file_list = Path(sys.argv[5])
self_hosting_root = sys.argv[6] == "1"
skill_registry_root = (
    skill_root.parent.parent
    if skill_root.parent.name == "skills"
    else project_root
)
files = sorted({
    Path(os.fsdecode(value)).resolve()
    for value in file_list.read_bytes().split(b"\0")
    if value and Path(os.fsdecode(value)).is_file()
})
code_project_root = None

external_re = re.compile(r"^(?:https?|mailto|data|javascript)://|^(?:mailto|data|javascript):", re.I)
markdown_link_re = re.compile(r"!?\[([^\]]*)\]\(\s*(?:<([^>]+)>|([^\s)]+))")
inline_code_re = re.compile(r"(?<!`)`([^`\n]+)`(?!`)")
reference_cue_re = re.compile(
    r"(?:\bread\b|\bsee\b|\bload\b|\bopen\b|\bfollow\b|\brun\b|"
    r"\bpoints?\s+to\b|\brefer(?:s|red)?\s+to\b|读取|参见|加载|打开|执行|指向|入口)",
    re.I,
)
optional_cue_re = re.compile(
    r"(?:\boptional\b|\bif\s+(?:it\s+)?(?:is\s+)?(?:present|available|admitted|materialized)\b|"
    r"\bwhen\s+(?:it\s+)?(?:is\s+)?(?:present|available|admitted|materialized)\b|"
    r"\bonly\s+if\b|\bif\s+(?:it\s+)?exists\b|\bwhen\s+(?:it\s+)?exists\b|"
    r"可选|按需|若存在|如存在|存在时)",
    re.I,
)
owner_prefixes = (
    "architecture/", "conventions/", "gotchas/", "protocol-blocks/",
    "references/", "rules/", "scripts/", "workflows/",
)
harness_prefixes = (
    ".agents/", ".claude/", ".codex/", ".cursor/", ".gemini/", "skills/",
)
root_files = {
    "AGENTS.md", "CLAUDE.md", "CODEX.md", "GEMINI.md", "SKILL.md",
    "conformance.yaml", "domain-routing.yaml", "hooks.yaml", "routing.yaml",
}
path_suffixes = (".md", ".mdc", ".yaml", ".yml", ".sh", ".tpl", ".template")
historical_inline_parts = {"docs", "examples", "posts"}
historical_inline_names = {
    "UPSTREAM-CHANGES.md", "findings.md", "progress.md", "task_plan.md",
}


def under(path: Path, root: Path | None) -> bool:
    if root is None:
        return False
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


if code_root is not None and under(code_root, workspace_root):
    relative_code_root = code_root.relative_to(workspace_root)
    if relative_code_root.parts:
        code_project_root = workspace_root / relative_code_root.parts[0]


def without_fences(text: str) -> str:
    output: list[str] = []
    marker: str | None = None
    for line in text.splitlines():
        match = re.match(r"^[ \t]*(```+|~~~+)", line)
        if match:
            token = match.group(1)[0]
            if marker is None:
                marker = token
            elif marker == token:
                marker = None
            continue
        if marker is None:
            output.append(line)
    return re.sub(r"<!--.*?-->", "", "\n".join(output), flags=re.S)


def slugify_heading(value: str) -> str:
    value = html.unescape(value)
    value = re.sub(r"!??\[([^\]]*)\]\([^)]*\)", r"\1", value)
    value = re.sub(r"<[^>]+>", "", value)
    value = value.replace("`", "").replace("*", "").replace("~", "")
    kept: list[str] = []
    for char in value.strip().lower():
        category = unicodedata.category(char)
        if char.isspace():
            kept.append("-")
        elif category.startswith(("L", "N")) or char in "-_":
            kept.append(char)
    return "".join(kept)


anchor_cache: dict[Path, set[str]] = {}


def anchors(path: Path) -> set[str]:
    if path in anchor_cache:
        return anchor_cache[path]
    found: set[str] = set()
    seen: dict[str, int] = {}
    content = without_fences(path.read_text(encoding="utf-8", errors="replace"))
    for line in content.splitlines():
        match = re.match(r"^[ \t]{0,3}#{1,6}[ \t]+(.+?)[ \t]*#*[ \t]*$", line)
        if not match:
            continue
        base = slugify_heading(match.group(1))
        if not base:
            continue
        count = seen.get(base, 0)
        seen[base] = count + 1
        found.add(base if count == 0 else f"{base}-{count}")
    for match in re.finditer(r"<(?:a\s+[^>]*?(?:name|id)|[A-Za-z][^>]*?\sid)=[\"']([^\"']+)[\"']", content, re.I):
        found.add(unquote(match.group(1)).lower())
    anchor_cache[path] = found
    return found


def split_reference(raw: str) -> tuple[str, str, str]:
    value = html.unescape(raw.strip()).strip("<>")
    prefix = ""
    for candidate in ("skill:", "code:"):
        if value.startswith(candidate):
            prefix = candidate[:-1]
            value = value[len(candidate):]
            break
    path_text, separator, fragment = value.partition("#")
    path_text = unquote(path_text.split("?", 1)[0])
    path_text = re.sub(r":\d+$", "", path_text)
    return prefix, path_text, unquote(fragment) if separator else ""


def source_project_root(src: Path) -> Path:
    if under(src, code_root) and code_project_root is not None:
        return code_project_root
    return workspace_root


def is_harness_source(src: Path) -> bool:
    if src.name in {"AGENTS.md", "CLAUDE.md", "CODEX.md", "GEMINI.md"}:
        return True
    value = src.as_posix()
    return any(marker in value for marker in ("/.agents/", "/.claude/", "/.codex/", "/.cursor/", "/.gemini/"))


def owner_candidates(src: Path, path_text: str) -> list[Path]:
    root = owner_root(src)
    candidate = (root / path_text).resolve()
    return [candidate] if under(candidate, root) else []


def bare_candidates(src: Path, path_text: str) -> list[Path]:
    candidates = [src.parent / path_text]
    for root in (owner_root(src), skill_root, code_root):
        if root is not None:
            candidates.extend(root / directory / path_text for directory in owner_prefixes)
    return sorted({candidate.resolve() for candidate in candidates if candidate.exists()})


def path_like_inline(src: Path, raw: str, context_before: str) -> bool:
    if any(char.isspace() for char in raw):
        return False
    if external_re.match(raw):
        return False
    if any(token in raw for token in ("{{", "}}", "<", ">", "{", "}", "*", "?", "[", "]", "$", "|", ";", "...")):
        return False
    prefix, path_text, _ = split_reference(raw)
    if not path_text or path_text.startswith("-"):
        return False
    plain = path_text.lstrip("./")
    if ":" in plain and not prefix:
        return False
    if "/" not in path_text and plain not in root_files:
        return False
    if plain.startswith(harness_prefixes) and not is_harness_source(src):
        return False
    structurally_path_like = (
        bool(prefix)
        or path_text.startswith(("./", "../"))
        or (path_text.startswith("/") and path_text.endswith(path_suffixes))
        or plain in root_files
        or plain.startswith(owner_prefixes)
        or plain.startswith(harness_prefixes)
        or ("/" in path_text and path_text.endswith(path_suffixes))
    )
    if not structurally_path_like:
        return False
    if optional_cue_re.search(context_before):
        return False
    return bool(prefix) or path_text.startswith(("./", "../", "/")) or is_harness_source(src) or bool(reference_cue_re.search(context_before))


def owner_root(src: Path) -> Path:
    return code_root if under(src, code_root) else skill_root


def resolve(src: Path, raw: str, markdown_link: bool) -> tuple[Path | None, str, str]:
    prefix, path_text, fragment = split_reference(raw)
    boundary: Path | None = None
    if prefix == "skill":
        base = skill_root
        boundary = skill_root
    elif prefix == "code":
        if code_root is None:
            return None, fragment, "code root unavailable"
        base = code_root
        boundary = code_root
    elif not path_text:
        return src, fragment, ""
    elif Path(path_text).is_absolute():
        return Path(path_text), fragment, ""
    elif markdown_link or path_text.startswith(("./", "../")):
        base = src.parent
    else:
        plain = path_text.lstrip("./")
        if plain.startswith("skills/") and under(src, skill_root):
            base = skill_registry_root
            boundary = skill_registry_root
        elif plain.startswith(harness_prefixes):
            base = workspace_root
            boundary = workspace_root
        elif plain in root_files:
            if plain == "SKILL.md":
                base = owner_root(src)
                boundary = base
            else:
                candidates = owner_candidates(src, path_text)
                existing = [candidate for candidate in candidates if candidate.exists()]
                base = existing[0].parent if existing else owner_root(src)
                boundary = owner_root(src)
                path_text = existing[0].name if existing else path_text
        elif plain.startswith(owner_prefixes):
            candidates = owner_candidates(src, path_text)
            existing = [candidate for candidate in candidates if candidate.exists()]
            if existing:
                return existing[0], fragment, ""
            base = owner_root(src)
            boundary = base
        elif "/" not in path_text:
            candidates = bare_candidates(src, path_text)
            if len(candidates) != 1:
                return None, fragment, "bare path is not uniquely resolvable"
            return candidates[0], fragment, ""
        elif code_project_root is not None and path_text.startswith(
            f"{code_project_root.name}/"
        ):
            base = workspace_root
            boundary = workspace_root
        else:
            base = source_project_root(src)
    target = (base / path_text).resolve()
    if boundary is not None and not under(target, boundary):
        return None, fragment, f"path escapes {boundary}"
    return target, fragment, ""


def should_check_inline(src: Path) -> bool:
    if self_hosting_root:
        return src == (skill_root / "SKILL.md").resolve() or is_harness_source(src)
    if src.name in historical_inline_names:
        return False
    if under(src, skill_root):
        rel = src.relative_to(skill_root)
        return not any(part in historical_inline_parts for part in rel.parts[:-1])
    return True


issues: list[str] = []
links_checked = 0
codes_checked = 0
anchors_checked = 0
skipped_code_root = 0

for src in files:
    content = without_fences(src.read_text(encoding="utf-8", errors="replace"))
    references: list[tuple[str, str]] = []
    markdown_links = list(markdown_link_re.finditer(content))
    for match in markdown_links:
        references.append(("markdown link", match.group(2) or match.group(3)))
    if should_check_inline(src):
        for line in content.splitlines():
            markdown_label_ranges = [
                (match.start(1), match.end(1))
                for match in markdown_link_re.finditer(line)
            ]
            for match in inline_code_re.finditer(line):
                if any(start <= match.start() and match.end() <= end for start, end in markdown_label_ranges):
                    continue
                raw = match.group(1)
                context_before = line[max(0, match.start() - 80):match.start()]
                if path_like_inline(src, raw, context_before):
                    references.append(("inline path", raw))

    for kind, raw in references:
        if external_re.match(raw):
            continue
        target, fragment, reason = resolve(src, raw, kind == "markdown link")
        if target is None:
            if reason == "code root unavailable":
                skipped_code_root += 1
                continue
            issues.append(f"{src} -> {raw} ({reason})")
            continue
        if kind == "markdown link":
            links_checked += 1
        else:
            codes_checked += 1
        if not target.exists():
            issues.append(f"{kind}: {src} -> {raw} (missing {target})")
            continue
        if fragment and target.is_file() and target.suffix.lower() in (".md", ".mdc"):
            if re.fullmatch(r"(?:l|line-?)\d+(?:-l?\d+)?", fragment, re.I):
                continue
            anchors_checked += 1
            normalized = fragment.strip().lower().replace(" ", "-")
            if normalized not in anchors(target):
                issues.append(f"heading fragment: {src} -> {raw} (missing #{normalized} in {target})")

print(
    f"STATS files={len(files)} links={links_checked} inline_paths={codes_checked} "
    f"fragments={anchors_checked} skipped_code_root={skipped_code_root}"
)
for issue in issues:
    print(issue)
raise SystemExit(1 if issues else 0)
PY
then
  REFERENCE_OUTPUT="$(<"$REFERENCE_REPORT")"
  pass "Local links, inline paths, and heading fragments resolve (${REFERENCE_OUTPUT#STATS })"
else
  REFERENCE_OUTPUT="$(<"$REFERENCE_REPORT")"
  fail "Broken local reference(s) found:"
  printf '%s\n' "$REFERENCE_OUTPUT" | sed 's/^/       /' | head -30 || true
fi
rm -f "$REFERENCE_REPORT" "$REFERENCE_INPUT"

if [[ -n "$CODE_ROOT_RESOLUTION_ERROR" ]]; then
  fail "$CODE_ROOT_RESOLUTION_ERROR"
elif [[ -n "$CODE_ROOT_REL" && -z "$WORKSPACE_ROOT" ]]; then
  warn "routing.yaml declares code_root.root=$CODE_ROOT_REL; rerun with --workspace-root to verify both roots"
elif [[ -n "$CODE_ROOT_REL" && ! -d "$CODE_ROOT_DIR" ]]; then
  fail "declared code root missing: $CODE_ROOT_DIR"
elif [[ -n "$CODE_ROOT_REL" ]]; then
  ROUTING_ABS="$(cd "$(dirname "$ROUTING_YAML")" && pwd -P)/$(basename "$ROUTING_YAML")"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  ORPHAN_SH="$SCRIPT_DIR/audit-orphans.sh"
  REACHABILITY_SH="$SCRIPT_DIR/route-reachability.sh"
  [[ -f "$ORPHAN_SH" ]] || ORPHAN_SH="$SKILL_DIR/scripts/audit-orphans.sh"
  [[ -f "$REACHABILITY_SH" ]] || REACHABILITY_SH="$SKILL_DIR/scripts/route-reachability.sh"
  ORPHAN_SH="$(cd "$(dirname "$ORPHAN_SH")" && pwd -P)/$(basename "$ORPHAN_SH")"
  REACHABILITY_SH="$(cd "$(dirname "$REACHABILITY_SH")" && pwd -P)/$(basename "$REACHABILITY_SH")"

  if SKILL_ORPHAN_OUT=$(cd "$SKILL_DIR" && bash "$ORPHAN_SH" --namespace skill --routing "$ROUTING_ABS" 2>&1); then
    pass "skill-root orphan audit passed"
  else
    fail "skill-root orphan audit failed"
    printf '%s\n' "$SKILL_ORPHAN_OUT" | sed 's/^/       /' | head -20 || true
  fi
  if SKILL_REACH_OUT=$(cd "$SKILL_DIR" && bash "$REACHABILITY_SH" --namespace skill --routing "$ROUTING_ABS" 2>&1); then
    pass "skill-root route reachability passed"
  else
    fail "skill-root route reachability failed"
    printf '%s\n' "$SKILL_REACH_OUT" | sed 's/^/       /' | head -20 || true
  fi
  if CODE_ORPHAN_OUT=$(cd "$CODE_ROOT_DIR" && bash "$ORPHAN_SH" --namespace code --routing "$ROUTING_ABS" 2>&1); then
    pass "code-root orphan audit passed"
  else
    fail "code-root orphan audit failed"
    printf '%s\n' "$CODE_ORPHAN_OUT" | sed 's/^/       /' | head -20 || true
  fi
  if CODE_REACH_OUT=$(cd "$CODE_ROOT_DIR" && bash "$REACHABILITY_SH" --namespace code --routing "$ROUTING_ABS" 2>&1); then
    pass "code-root route reachability passed"
  else
    fail "code-root route reachability failed"
    printf '%s\n' "$CODE_REACH_OUT" | sed 's/^/       /' | head -20 || true
  fi
fi

fi  # end section 8

# ── 9. Content Conformance (manifest-gated) ──────────────────────────
# Sections 1–8 verify files EXIST and links resolve; none verifies a file still
# CONTAINS the sections the upstream contract promises. That content drift is how
# a well-meaning edit (e.g. renaming "Task Closure Protocol" → "Trigger Policy")
# silently breaks the contract and goes unnoticed until update-upstream. Folding
# conformance into the one check people run after every change closes that gap.
# Skipped silently when the skill carries no conformance.yaml.
if section 9 "Content Conformance (manifest-gated)"; then :

CONF_YAML="$SKILL_DIR/conformance.yaml"
CONF_SH="$SKILL_DIR/scripts/check-version-conformance.sh"
if [[ ! -f "$CONF_SH" ]]; then
  CONF_SH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check-version-conformance.sh"
fi
if [[ -f "$CONF_YAML" && -f "$CONF_SH" ]]; then
  if CONF_OUT=$(bash "$CONF_SH" "$SKILL_DIR" 2>&1); then
    pass "content conformance: skill carries every section its conformance.yaml requires"
  else
    fail "content conformance drifted — a required section/phrase is missing:"
    printf '%s\n' "$CONF_OUT" | grep -iE 'FAIL|MISSING' | head -20 | sed 's/^/       /' || true
  fi
elif [[ -f "$CONF_YAML" && ! -f "$CONF_SH" ]]; then
  warn "conformance.yaml present but check-version-conformance.sh missing (vendored dir + fallback) — content conformance NOT verified; re-vendor the conformance checker alongside smoke-test.sh"
else
  echo "  (no conformance.yaml — content-conformance check skipped)"
fi

if [[ -n "$CODE_ROOT_REL" && -n "$WORKSPACE_ROOT" && -d "$CODE_ROOT_DIR" ]]; then
  CODE_CONF_YAML="$CODE_ROOT_DIR/conformance.yaml"
  if [[ -f "$CODE_CONF_YAML" && -f "$CONF_SH" ]]; then
    if CODE_CONF_OUT=$(bash "$CONF_SH" "$CODE_ROOT_DIR" --conformance "$CODE_CONF_YAML" 2>&1); then
      pass "code-root content conformance passed"
    else
      fail "code-root content conformance drifted:"
      printf '%s\n' "$CODE_CONF_OUT" | grep -iE 'FAIL|MISSING|schema error' | head -20 | sed 's/^/       /' || true
    fi
  elif [[ -f "$CODE_CONF_YAML" ]]; then
    fail "code-root conformance.yaml exists but no check-version-conformance.sh is available"
  else
    echo "  (no code-root conformance.yaml — code-root content check skipped)"
  fi
fi

fi  # end section 9

# ── Summary ───────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
echo "  Results: ✅ $PASS passed  ❌ $FAIL failed  ⚠️  $WARN warnings"
echo "═══════════════════════════════════════"

if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "  Fix the ❌ items above, then re-run: bash smoke-test.sh $NAME"
  exit 1
else
  echo ""
  echo "  All applicable structural checks passed for Skill '$NAME'."
  echo "  This does not prove semantic migration or live Agent behavior."
  exit 0
fi
