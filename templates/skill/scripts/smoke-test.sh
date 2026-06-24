#!/usr/bin/env bash
# smoke-test.sh — Fully automated post-migration verification
# Usage: bash smoke-test.sh <skill-name> [--phase N]
# Example: bash smoke-test.sh my-project
#          bash smoke-test.sh my-project --phase 4   # run only Phase 4 subset
#
# Zero manual input required. Checks routing.yaml-generated blocks plus SKILL.md Common Tasks.
# Supports both English and Chinese (中文) section names.
# Exit code: 0 = all pass, 1 = failures found.
#
# ═══════════════════════════════════════════════════════════════════════
# 9 CATEGORIES of checks (see corresponding section markers below):
#
#   1. Structural Checks          — SKILL.md, rules/, workflows/, gotchas,
#                                   Cursor registration entry, thin shells exist;
#                                   SessionStart re-injection hook wired (1d, WARN)
#   2. Line Count Budgets         — SKILL.md dual budget (description ≤ 25 + body ≤ 90), shells ≤ 60 lines,
#                                   gotchas/pitfall ≤ $GOTCHAS_MAX_LINES (default 400),
#                                   no duplicate ## headings in gotchas/pitfall files,
#                                   Common Tasks ≤ $COMMON_TASKS_MAX_ROWS rows
#                                   (default 10) — both env-overridable
#   3. Placeholder Residue        — no {{NAME}} / {{SUMMARY}} leftover;
#                                   no unreplaced <!-- FILL: --> markers
#   4. SKILL.md Content Quality   — description ≥ 20 words or enough CJK chars,
#                                   ≥ 2 quoted trigger phrases in real user
#                                   language(s), not keyword-stuffed (WARN if
#                                   > $DESCRIPTION_MAX_TRIGGERS quoted phrases),
#                                   Common Tasks + Known Gotchas sections exist
#   5. Routing Completeness       — routing.yaml generated summary/bootstraps match;
#                                   every file referenced in Common Tasks exists
#   6. Description Consistency    — SKILL.md and .cursor/skills/<name>/SKILL.md
#                                   descriptions match byte-for-byte
#   7. Shell Routing Consistency  — AGENTS / CLAUDE / CODEX / GEMINI shells
#                                   point at routing.yaml bootstrap
#   8. Broken Link Check          — every relative markdown link [text](path)
#                                   across all skill .md files resolves to an
#                                   existing file. Catches "path drift" after
#                                   partial renames or deletions.
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
#     GOTCHAS_MAX_LINES=600 COMMON_TASKS_MAX_ROWS=12 bash smoke-test.sh my-skill
GOTCHAS_MAX_LINES="${GOTCHAS_MAX_LINES:-400}"
COMMON_TASKS_MAX_ROWS="${COMMON_TASKS_MAX_ROWS:-10}"
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
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2 ;;
    --phase=*) PHASE="${1#--phase=}"; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$NAME" ]]; then
  echo "Usage: bash smoke-test.sh <skill-name> [--phase N]"
  echo "Example: bash smoke-test.sh my-project"
  exit 1
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

SKILL_DIR="skills/$NAME"
SKILL_MD="$SKILL_DIR/SKILL.md"
ROUTING_YAML="$SKILL_DIR/routing.yaml"
CURSOR_ENTRY=".cursor/skills/$NAME/SKILL.md"

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
  else
    fail "$ROUTING_YAML missing (routing source of truth)"
  fi
fi

# 1a-rules. constraint surface: rules/ OR architecture/ OR conventions/ (Phase 4+)
# A skill carries constraints in rules/ (folder-light) or, after the rate-of-change
# split, in architecture/ (stable) + conventions/ (volatile). Any non-empty one passes.
if sub_runs "1a-rules"; then
  CONSTRAINT_N=0
  for d in rules architecture conventions; do
    if [[ -d "$SKILL_DIR/$d" ]]; then
      n=$(find "$SKILL_DIR/$d" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
      CONSTRAINT_N=$((CONSTRAINT_N + n))
    fi
  done
  if [[ "$CONSTRAINT_N" -gt 0 ]]; then
    pass "constraint surface: $CONSTRAINT_N file(s) across rules/ architecture/ conventions/"
  else
    fail "no constraint surface — expected rules/, architecture/, or conventions/ with .md files"
  fi
fi

# 1a-workflows. workflows/*.md (Phase 5+)
if sub_runs "1a-workflows"; then
  if [[ -f "$SKILL_DIR/workflows/update-rules.md" ]]; then
    pass "$SKILL_DIR/workflows/update-rules.md exists"
  else
    fail "$SKILL_DIR/workflows/update-rules.md missing"
  fi

  if [[ -f "$ROUTING_YAML" ]]; then
    ROUTED_WORKFLOWS=()
    while IFS= read -r workflow; do
      [[ -n "$workflow" ]] || continue
      [[ "$workflow" == *"FILL:"* ]] && continue
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
    GOTCHA_FILE=$(find "$SKILL_DIR/references" -maxdepth 1 -type f \( -name '*pitfall*' -o -name '*gotcha*' \) 2>/dev/null | head -1)
    if [[ -n "$GOTCHA_FILE" ]]; then
      pass "gotchas/pitfalls reference found: $(basename "$GOTCHA_FILE")"
    else
      fail "no gotchas/ tier, $SKILL_DIR/references/gotchas.md, or equivalent pitfalls file"
    fi
  fi
fi

# 1b. Cursor registration entry (Phase 7+)
if sub_runs "1b"; then
  if [[ -f "$CURSOR_ENTRY" ]]; then
    pass "Cursor entry $CURSOR_ENTRY exists"
  else
    fail "Cursor entry $CURSOR_ENTRY missing (Cursor will never discover this skill)"
  fi
fi

# 1c. Thin shells + .cursor/rules (Phase 7+)
if sub_runs "1c"; then
  for shell in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
    if [[ ! -f "$shell" ]]; then
      fail "$shell missing"
    elif has_routing_bootstrap "$shell"; then
      pass "$shell exists with routing.yaml bootstrap"
    else
      fail "$shell exists but does not point at routing.yaml"
    fi
  done

  # .codex/instructions.md is an optional compatibility mirror. If a project
  # opts in, validate the routing bootstrap; otherwise stay silent.
  if [[ -f ".codex/instructions.md" ]]; then
    if has_routing_bootstrap ".codex/instructions.md"; then
      pass ".codex/instructions.md exists with routing.yaml bootstrap"
    else
      fail ".codex/instructions.md exists but does not point at routing.yaml"
    fi
  fi

  MDC_COUNT=$(find .cursor/rules -name '*.mdc' 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$MDC_COUNT" -gt 0 ]]; then
    pass ".cursor/rules/ has $MDC_COUNT .mdc file(s)"
  else
    fail ".cursor/rules/ has no .mdc files"
  fi

  # 1d. SessionStart re-injection hook (WARN-only — harness-dependent).
  # Pitfall #7: on /clear or /compact the harness summarizes context and the
  # SKILL.md routing table drops out. A SessionStart hook re-injects it. Never
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
      warn "no SessionStart hook in .claude/settings*.json — SKILL.md routing can silently drop after /clear or /compact (Pitfall #7); see templates/hooks/session-start"
    fi
  fi
fi

fi  # end section 1

# ── 2. Line Count Budgets ─────────────────────────────────────────────
if section 2 "Line Count Budgets"; then :

check_lines() {
  local file="$1" max="$2" label="$3"
  if [[ ! -f "$file" ]]; then return; fi
  local lines
  lines=$(wc -l < "$file" | tr -d ' ')
  if [[ "$lines" -le "$max" ]]; then
    pass "$label: $lines lines (≤ $max)"
  else
    fail "$label: $lines lines (exceeds $max limit)"
  fi
}

# SKILL.md uses dual budgets — description is the activation gate (frontmatter)
# and benefits from rich quoted trigger phrases; body is the navigation hub
# (Always Read / Common Tasks / boundaries) and must stay tight. Splitting the
# budgets prevents description quality from cannibalizing body clarity (and
# vice versa). Hard caps: description ≤ 25 lines, body ≤ 90 lines.
check_skill_md_budget() {
  local file="$1"
  [[ -f "$file" ]] || return
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
check_lines "$ROUTING_YAML" 140 "routing.yaml"  # tiered skills route to more files (architecture + gotchas/index + references) per task
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
  DUPLICATE_HEADINGS=$(grep "^## " "$gotcha_file" | sort | uniq -d)
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

# 2b. Common Tasks row count — per-task routing efficiency, not disk size.
# Each routing row imposes cognitive cost at task-match time. > $COMMON_TASKS_MAX_ROWS
# means the skill is doing too many things; candidate for fission (see
# references/layout.md § Multi-Skill Projects).
if [[ -f "$SKILL_MD" ]]; then
  CT_COUNTS=$(awk '
    /^## (Common Tasks|常见任务)/ { in_ct=1; next }
    in_ct && /^## / { exit }
    in_ct && /^\|/ { table++ }
    in_ct && /^[[:space:]]*[-*][[:space:]]+/ { bullet++ }
    END { print table+0, bullet+0 }
  ' "$SKILL_MD")
  read -r TABLE_LINES BULLET_ROWS <<< "$CT_COUNTS"
  # Prefer markdown table rows when present (subtract header + separator rows),
  # otherwise support the bullet-list format used by templates/skill/SKILL.md.template.
  if [[ "$TABLE_LINES" -gt 0 ]]; then
    CT_ROWS=$((TABLE_LINES > 2 ? TABLE_LINES - 2 : 0))
  else
    CT_ROWS="$BULLET_ROWS"
  fi
  if [[ "$CT_ROWS" -eq 0 ]]; then
    warn "Common Tasks routing appears empty or non-standard format"
  elif [[ "$CT_ROWS" -le "$COMMON_TASKS_MAX_ROWS" ]]; then
    pass "Common Tasks: $CT_ROWS routes (≤ $COMMON_TASKS_MAX_ROWS)"
  else
    fail "Common Tasks: $CT_ROWS routes (exceeds $COMMON_TASKS_MAX_ROWS — evaluate fission or route consolidation)"
  fi
fi

fi  # end section 2

# ── 3. Placeholder Residue ────────────────────────────────────────────
if section 3 "Placeholder Residue"; then :

# 3a. {{...}} placeholders should all be replaced
# Exclude JSX/code patterns like styles={{ }}, className={{ }}, etc.
PLACEHOLDER_HITS=$(grep -rn '{{' "$SKILL_DIR" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor 2>/dev/null \
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
FILL_HITS=$(grep -rn 'FILL:' "$SKILL_DIR" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor 2>/dev/null | grep -v 'node_modules' | grep -v '/scripts/' || true)
if [[ -z "$FILL_HITS" ]]; then
  pass "No <!-- FILL: --> markers remaining"
else
  fail "Unresolved FILL markers found ($(echo "$FILL_HITS" | wc -l | tr -d ' ') hits):"
  echo "$FILL_HITS" | head -20 | sed 's/^/       /'
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

  # 4c-stuffing. Too MANY quoted phrases = workflow-keyword stuffing (Pitfall #3 /
  # Principle #7). The description is a coarse activation gate, not a workflow
  # index; enumerating every task's keywords leaks which workflows exist and
  # competes with Common Tasks routing. WARN-only — judgment call.
  if [[ "$TRIGGER_COUNT" -gt "$DESCRIPTION_MAX_TRIGGERS" ]]; then
    warn "description has $TRIGGER_COUNT quoted phrases (> $DESCRIPTION_MAX_TRIGGERS) — likely workflow-keyword stuffing; keep it domain-level, move task keywords to Common Tasks (Pitfall #3)"
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
if section 5 "Routing Completeness (auto-parsed from Common Tasks)"; then :

if [[ -f "$SKILL_MD" ]]; then
  ROUTING_SYNC="$SKILL_DIR/scripts/sync-routing.sh"
  if [[ ! -f "$ROUTING_SYNC" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROUTING_SYNC="$SCRIPT_DIR/sync-routing.sh"
  fi
  if [[ -f "$ROUTING_YAML" && -f "$ROUTING_SYNC" ]]; then
    if ROUTING_OUTPUT=$(bash "$ROUTING_SYNC" "$NAME" --check 2>&1); then
      pass "routing.yaml generated blocks are in sync"
    else
      fail "routing.yaml generated blocks drifted"
      printf '%s\n' "$ROUTING_OUTPUT" | sed 's/^/       /' | head -50
    fi
  fi

  # Extract file references from Common Tasks / 常见任务 section
  IN_COMMON_TASKS=false
  REFERENCED_FILES=()
  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]+(Common[[:space:]]+Tasks|常见任务) ]]; then
      IN_COMMON_TASKS=true
      continue
    fi
    if $IN_COMMON_TASKS && [[ "$line" =~ ^## ]]; then
      break
    fi
    if $IN_COMMON_TASKS; then
      # Skip lines that are fully inside a multi-line HTML comment.
      # FILL comments often contain example paths as documentation — those
      # are not real references and should not trigger existence checks.
      if [[ "${IN_COMMENT:-false}" == "true" ]]; then
        if [[ "$line" == *"-->"* ]]; then
          IN_COMMENT=false
        fi
        continue
      fi

      # Strip single-line HTML comments (<!-- ... --> on one line)
      stripped_line=$(printf '%s' "$line" | sed -E 's/<!--([^-]|-[^-]|--[^>])*-->//g')

      # Detect start of multi-line comment (opens without close on this line)
      if [[ "$stripped_line" == *"<!--"* ]]; then
        IN_COMMENT=true
        stripped_line="${stripped_line%%<!--*}"
      fi

      # Extract backtick-quoted relative paths (rules/, workflows/, references/)
      while [[ "$stripped_line" =~ \`((rules|workflows|references)/[^\`]+)\` ]]; do
        ref="${BASH_REMATCH[1]}"
        REFERENCED_FILES+=("$ref")
        stripped_line="${stripped_line#*\`$ref\`}"
      done
    fi
  done < "$SKILL_MD"

  # Deduplicate (handle empty array gracefully)
  if [[ ${#REFERENCED_FILES[@]} -eq 0 ]]; then
    warn "No file references found in Common Tasks (section may be empty or use non-standard format)"
  else
    UNIQUE_FILES=($(printf '%s\n' "${REFERENCED_FILES[@]}" | sort -u))

    echo "  Found ${#UNIQUE_FILES[@]} unique file references in Common Tasks:"
    for ref in "${UNIQUE_FILES[@]}"; do
      full_path="$SKILL_DIR/$ref"
      # Skip wildcard patterns like rules/*.md
      if [[ "$ref" == *'*'* ]]; then
        pass "  $ref (wildcard pattern, skipping existence check)"
        continue
      fi
      # Skip angle-bracket placeholders like rules/<x>.md — treat as template residue
      if [[ "$ref" == *'<'* || "$ref" == *'>'* ]]; then
        warn "  $ref looks like an unfilled template placeholder — replace with a real path"
        continue
      fi
      if [[ -f "$full_path" ]]; then
        pass "  $ref exists"
      else
        fail "  $ref referenced in Common Tasks but file missing at $full_path"
      fi
    done
  fi

  # Also check Always Read / 必读 references
  echo ""
  echo "  Always Read / 必读 references:"
  IN_ALWAYS_READ=false
  FOUND_ALWAYS_READ=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]+(Always[[:space:]]+Read|必读) ]]; then
      IN_ALWAYS_READ=true
      continue
    fi
    if $IN_ALWAYS_READ && [[ "$line" =~ ^## ]]; then
      break
    fi
    if $IN_ALWAYS_READ; then
      while [[ "$line" =~ \`((rules|workflows|references)/[^\`]+)\` ]]; do
        ref="${BASH_REMATCH[1]}"
        FOUND_ALWAYS_READ=true
        full_path="$SKILL_DIR/$ref"
        if [[ -f "$full_path" ]]; then
          pass "  $ref exists"
        else
          fail "  $ref in Always Read but file missing at $full_path"
        fi
        line="${line#*\`$ref\`}"
      done
    fi
  done < "$SKILL_MD"
  if ! $FOUND_ALWAYS_READ; then
    warn "  No file references found in Always Read section"
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

# Check that all shells point at the routing manifest instead of carrying hand-maintained tables.
SHELL_FILES=(AGENTS.md CLAUDE.md CODEX.md GEMINI.md)
# Optional: include .codex/instructions.md only when the project opts into the compatibility mirror.
[[ -f ".codex/instructions.md" ]] && SHELL_FILES+=(".codex/instructions.md")
while IFS= read -r cursor_rule; do
  SHELL_FILES+=("$cursor_rule")
done < <(find .cursor/rules -maxdepth 1 -name '*.mdc' -type f 2>/dev/null | sort)
for shell in "${SHELL_FILES[@]}"; do
  if [[ ! -f "$shell" ]]; then continue; fi
  if grep -q 'routing.yaml' "$shell"; then
    pass "$shell points at routing.yaml"
  else
    fail "$shell does not point at routing.yaml"
  fi
done

fi  # end section 7

# ── 8. Broken Link Check ──────────────────────────────────────────────
# Catches "path drift": agent renames or deletes a file but only updates SOME
# of the references to it. Section 5 covers the generated Common Tasks summary only;
# this section scans every relative markdown link [text](path) across all skill
# .md files and verifies each target exists. Companion to audit-orphans.sh
# (which finds *orphan* files — files no one links to). Together they cover
# both directions of drift: broken outbound links here, dangling inbound links
# there.
if section 8 "Broken Link Check (all .md files)"; then :

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

# Strip fenced code blocks (```...```) before scanning. Paths inside code
# examples (e.g. `rm references/foo.md` shown as a sample command) are not
# real references and shouldn't trigger existence checks.
strip_fences() {
  awk '/^```/ { in_fence = !in_fence; next } !in_fence { print }' "$1"
}

LINK_BROKEN=0
LINK_CHECKED=0
LINK_BROKEN_LINES=()

for src in "${LINK_SCAN_FILES[@]}"; do
  src_dir=$(dirname "$src")
  content=$(strip_fences "$src")

  # Extract markdown link targets. Pattern matches `](X` where X has no
  # closing paren or whitespace — captures the URL portion before any
  # title attribute like [text](url "title").
  while IFS= read -r raw; do
    [[ -z "$raw" ]] && continue
    # Skip absolute URLs, mail, and anchor-only links — these are not file refs.
    [[ "$raw" =~ ^https?:// ]] && continue
    [[ "$raw" =~ ^mailto: ]] && continue
    [[ "$raw" =~ ^# ]] && continue
    # Strip anchor fragment (#section) and Claude Code line suffix (:42).
    target="${raw%%#*}"
    target="${target%%:[0-9]*}"
    [[ -z "$target" ]] && continue
    # Resolve relative to source file's directory (standard markdown semantics).
    if [[ "$target" = /* ]]; then
      resolved="$target"
    else
      resolved="$src_dir/$target"
    fi
    LINK_CHECKED=$((LINK_CHECKED + 1))
    if [[ ! -e "$resolved" ]]; then
      LINK_BROKEN=$((LINK_BROKEN + 1))
      LINK_BROKEN_LINES+=("$src → $raw")
    fi
  done < <(printf '%s\n' "$content" | grep -oE '\]\([^) ]+' | sed -E 's/^\]\(//' || true)
done

if [[ "$LINK_BROKEN" -eq 0 ]]; then
  pass "No broken markdown links ($LINK_CHECKED relative refs across ${#LINK_SCAN_FILES[@]} files)"
else
  fail "$LINK_BROKEN broken markdown link(s) found ($LINK_CHECKED relative refs checked):"
  printf '       %s\n' "${LINK_BROKEN_LINES[@]}" | head -25
  if [[ "$LINK_BROKEN" -gt 25 ]]; then
    echo "       ... and $((LINK_BROKEN - 25)) more (output truncated)"
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
  echo "  All checks passed! Skill '$NAME' is ready."
  exit 0
fi
