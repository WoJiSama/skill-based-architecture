#!/usr/bin/env bash
# smoke-test.sh — Fully automated post-migration verification
# Usage: bash smoke-test.sh <skill-name> [--phase N]
# Example: bash smoke-test.sh my-project
#          bash smoke-test.sh my-project --phase 4   # run only Phase 4 subset
#
# Zero manual input required. Parses SKILL.md Common Tasks as the source of truth.
# Supports both English and Chinese (中文) section names.
# Exit code: 0 = all pass, 1 = failures found.
#
# ═══════════════════════════════════════════════════════════════════════
# 8 CATEGORIES of checks (see corresponding section markers below):
#
#   1. Structural Checks          — SKILL.md, rules/, workflows/, gotchas,
#                                   Cursor registration entry, thin shells exist
#   2. Line Count Budgets         — SKILL.md ≤ 100 lines, shells ≤ 60 lines,
#                                   gotchas/pitfall ≤ $GOTCHAS_MAX_LINES (default 400),
#                                   Common Tasks ≤ $COMMON_TASKS_MAX_ROWS rows
#                                   (default 10) — both env-overridable
#   3. Placeholder Residue        — no {{NAME}} / {{SUMMARY}} leftover;
#                                   no unreplaced <!-- FILL: --> markers
#   4. SKILL.md Content Quality   — description ≥ 20 words, ≥ 2 quoted trigger
#                                   phrases, Common Tasks has Other fallback,
#                                   Known Gotchas section exists
#   5. Routing Completeness       — every file referenced in Common Tasks
#                                   actually exists on disk
#   6. Description Consistency    — SKILL.md and .cursor/skills/<name>/SKILL.md
#                                   descriptions match byte-for-byte
#   7. Shell Routing Consistency  — AGENTS / CLAUDE / CODEX / GEMINI shells
#                                   share the same Quick Routing task set
#   8. Broken Link Check          — every relative markdown link [text](path)
#                                   across all skill .md files resolves to an
#                                   existing file. Catches "path drift" after
#                                   partial renames or deletions.
#
# Roughly 50 discrete checks across these 8 categories (count varies slightly
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

# Phase→section map. Each phase runs a subset of sections 1–8 below.
# Phase 3: SKILL.md written         → sections 4, 6
# Phase 4: rules extracted          → sections 1a, 2, 3
# Phase 5: workflows extracted      → sections 1a, 2, 3
# Phase 6: references extracted     → sections 1a, 3
# Phase 7: thin shells + routing    → sections 1b, 1c, 5, 6, 7, 8
# Phase 8: full verify              → all
# (no flag)                         → all
phase_runs() {
  # $1 = section number (1..8). Returns 0 (run) or 1 (skip).
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
CURSOR_ENTRY=".cursor/skills/$NAME/SKILL.md"

PASS=0
FAIL=0
WARN=0

pass() { ((PASS++)); echo "  ✅ $1"; }
fail() { ((FAIL++)); echo "  ❌ $1"; }
warn() { ((WARN++)); echo "  ⚠️  $1"; }

# ── 1. Structural Checks ─────────────────────────────────────────────
has_routing_table() {
  local file="$1"
  grep -q '^|' "$file" 2>/dev/null
}

if section 1 "Structural Checks"; then :

# 1a-skill. SKILL.md exists (Phase 3+)
if sub_runs "1a-skill"; then
  if [[ -f "$SKILL_MD" ]]; then
    pass "$SKILL_MD exists"
  else
    fail "$SKILL_MD missing"
  fi
fi

# 1a-rules. rules/*.md (Phase 4+)
if sub_runs "1a-rules"; then
  for f in "$SKILL_DIR/rules/project-rules.md" \
           "$SKILL_DIR/rules/coding-standards.md"; do
    if [[ -f "$f" ]]; then
      pass "$f exists"
    else
      fail "$f missing"
    fi
  done
fi

# 1a-workflows. workflows/*.md (Phase 5+)
if sub_runs "1a-workflows"; then
  for f in "$SKILL_DIR/workflows/update-rules.md" \
           "$SKILL_DIR/workflows/fix-bug.md" \
           "$SKILL_DIR/workflows/change-managed.md" \
           "$SKILL_DIR/workflows/edit-templates.md" \
           "$SKILL_DIR/workflows/maintain-docs.md"; do
    if [[ -f "$f" ]]; then
      pass "$f exists"
    else
      fail "$f missing"
    fi
  done
fi

# 1a-gotchas. references/gotchas.md or equivalent (Phase 6+)
if sub_runs "1a-gotchas"; then
  if [[ -f "$SKILL_DIR/references/gotchas.md" ]]; then
    pass "$SKILL_DIR/references/gotchas.md exists"
  else
    GOTCHA_FILE=$(find "$SKILL_DIR/references" -maxdepth 1 -type f \( -name '*pitfall*' -o -name '*gotcha*' \) 2>/dev/null | head -1)
    if [[ -n "$GOTCHA_FILE" ]]; then
      pass "gotchas/pitfalls reference found: $(basename "$GOTCHA_FILE")"
    else
      fail "$SKILL_DIR/references/gotchas.md (or equivalent pitfalls file) missing"
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

# 1c. Thin shells + .codex + .cursor/rules (Phase 7+)
if sub_runs "1c"; then
  for shell in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
    if [[ ! -f "$shell" ]]; then
      fail "$shell missing"
    elif has_routing_table "$shell"; then
      pass "$shell exists with routing table"
    else
      fail "$shell exists but has no routing table (no '|' table rows found)"
    fi
  done

  if [[ -f ".codex/instructions.md" ]]; then
    if has_routing_table ".codex/instructions.md"; then
      pass ".codex/instructions.md exists with routing table"
    else
      fail ".codex/instructions.md exists but no routing table"
    fi
  else
    fail ".codex/instructions.md missing"
  fi

  MDC_COUNT=$(find .cursor/rules -name '*.mdc' 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$MDC_COUNT" -gt 0 ]]; then
    pass ".cursor/rules/ has $MDC_COUNT .mdc file(s)"
  else
    fail ".cursor/rules/ has no .mdc files"
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

check_lines "$SKILL_MD" 100 "SKILL.md"
for shell in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
  check_lines "$shell" 60 "$shell (thin shell)"
done
check_lines "$CURSOR_ENTRY" 60 "Cursor entry"

# 2a. gotchas / pitfall files — runaway growth is the #1 disk-size failure mode.
# Default threshold $GOTCHAS_MAX_LINES = "split into topic-specific pitfall files
# or deprecate stale entries". A fresh migration has a near-empty gotchas.md
# (well under the cap); this fails only after accumulation without pruning. See
# workflows/update-rules.md § Rule Deprecation and scripts/audit-references.sh.
for gotcha_file in "$SKILL_DIR/references"/*gotcha*.md "$SKILL_DIR/references"/*pitfall*.md; do
  [[ -f "$gotcha_file" ]] || continue
  check_lines "$gotcha_file" "$GOTCHAS_MAX_LINES" "$(basename "$gotcha_file") (pitfall log)"
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
  # otherwise support the bullet-list format used by templates/skill/SKILL.md.
  if [[ "$TABLE_LINES" -gt 0 ]]; then
    CT_ROWS=$((TABLE_LINES > 2 ? TABLE_LINES - 2 : 0))
  else
    CT_ROWS="$BULLET_ROWS"
  fi
  if [[ "$CT_ROWS" -eq 0 ]]; then
    warn "Common Tasks routing appears empty or non-standard format"
  elif [[ "$CT_ROWS" -le "$COMMON_TASKS_MAX_ROWS" ]]; then
    pass "Common Tasks: $CT_ROWS routing rows (≤ $COMMON_TASKS_MAX_ROWS)"
  else
    fail "Common Tasks: $CT_ROWS routing rows (exceeds $COMMON_TASKS_MAX_ROWS — evaluate fission or row consolidation)"
  fi
fi

fi  # end section 2

# ── 3. Placeholder Residue ────────────────────────────────────────────
if section 3 "Placeholder Residue"; then :

# 3a. {{...}} placeholders should all be replaced
# Exclude JSX/code patterns like styles={{ }}, className={{ }}, etc.
PLACEHOLDER_HITS=$(grep -rn '{{' "$SKILL_DIR" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .codex .cursor 2>/dev/null \
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
FILL_HITS=$(grep -rn 'FILL:' "$SKILL_DIR" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .codex .cursor 2>/dev/null | grep -v 'node_modules' | grep -v '/scripts/' || true)
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

  # 4b. description is ≥ 20 words
  # Extract YAML description: multi-line value (stops at next top-level key or ---)
  DESC=$(awk '
    /^description:/ { found=1; sub(/^description:[[:space:]]*>?[[:space:]]*/, ""); if ($0 != "") print; next }
    found && /^[a-z].*:/ { exit }
    found && /^---/ { exit }
    found { print }
  ' "$SKILL_MD" | tr -s ' \n' ' ')
  WORD_COUNT=$(echo "$DESC" | wc -w | tr -d ' ')
  if [[ "$WORD_COUNT" -ge 20 ]]; then
    pass "description is $WORD_COUNT words (≥ 20)"
  else
    fail "description is only $WORD_COUNT words (need ≥ 20 for reliable activation)"
  fi

  # 4c. description has quoted trigger phrases
  TRIGGER_COUNT=$(echo "$DESC" | grep -o '"[^"]*"' | wc -l | tr -d ' ')
  if [[ "$TRIGGER_COUNT" -ge 2 ]]; then
    pass "description has $TRIGGER_COUNT quoted trigger phrases (≥ 2)"
  else
    fail "description has only $TRIGGER_COUNT quoted trigger phrases (need ≥ 2)"
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
fi

fi  # end section 4

# ── 5. Routing Completeness ──────────────────────────────────────────
if section 5 "Routing Completeness (auto-parsed from Common Tasks)"; then :

if [[ -f "$SKILL_MD" ]]; then
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

if [[ -f "scripts/check-self-routing.sh" && -f "references/self-hosting-routing.md" ]]; then
  if bash scripts/check-self-routing.sh >/dev/null; then
    pass "self-hosting routing blocks match canonical source"
  else
    fail "self-hosting routing blocks drifted from references/self-hosting-routing.md"
    echo "       Run: bash scripts/sync-self-routing.sh"
  fi
fi

# Check that all shells reference the same set of tasks
SHELL_FILES=(AGENTS.md CLAUDE.md CODEX.md GEMINI.md)
[[ -f ".codex/instructions.md" ]] && SHELL_FILES+=(".codex/instructions.md")
while IFS= read -r cursor_rule; do
  SHELL_FILES+=("$cursor_rule")
done < <(find .cursor/rules -maxdepth 1 -name '*.mdc' -type f 2>/dev/null | sort)
PREV_TASKS=""
PREV_SHELL=""
for shell in "${SHELL_FILES[@]}"; do
  if [[ ! -f "$shell" ]]; then continue; fi
  # Extract task column from routing table (first column after | )
  # Skip header rows (containing "Task" or "任务" or "---")
  TASKS=$(grep '^|' "$shell" | grep -v '^| Task' | grep -v '任务类型' | grep -v '^|---' | awk -F'|' '{print $2}' | tr -d ' ' | sort)
  if [[ -z "$PREV_TASKS" ]]; then
    PREV_TASKS="$TASKS"
    PREV_SHELL="$shell"
    continue
  fi
  if [[ "$TASKS" == "$PREV_TASKS" ]]; then
    pass "$shell routing table matches $PREV_SHELL"
  else
    warn "$shell routing table differs from $PREV_SHELL (may be intentional)"
  fi
done

fi  # end section 7

# ── 8. Broken Link Check ──────────────────────────────────────────────
# Catches "path drift": agent renames or deletes a file but only updates SOME
# of the references to it. Section 5 covers the Common Tasks routing table only;
# this section scans every relative markdown link [text](path) across all skill
# .md files and verifies each target exists. Companion to audit-references.sh
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
