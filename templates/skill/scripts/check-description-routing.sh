#!/usr/bin/env bash
# check-description-routing.sh — Guard description scope and multi-skill routing.
# Usage:
#   bash scripts/check-description-routing.sh [skill-name|skill-root]
# Run from repo root after migration, or from a skill root with no argument.

set -euo pipefail

TARGET="${1:-}"
ROOT="$PWD"

if [[ -n "$TARGET" && -f "$TARGET/SKILL.md" ]]; then
  SKILL_ROOT="${TARGET%/}"
elif [[ -n "$TARGET" && -f "skills/$TARGET/SKILL.md" ]]; then
  SKILL_ROOT="skills/$TARGET"
elif [[ -f "SKILL.md" ]]; then
  SKILL_ROOT="."
else
  echo "Usage: bash check-description-routing.sh [skill-name|skill-root]" >&2
  exit 1
fi

if [[ "$SKILL_ROOT" == skills/* ]]; then
  REPO_ROOT="."
elif [[ "$SKILL_ROOT" == */skills/* ]]; then
  REPO_ROOT="${SKILL_ROOT%%/skills/*}"
else
  REPO_ROOT="$ROOT"
fi

SKILL_MD="$SKILL_ROOT/SKILL.md"
FAIL=0
WARN=0
PASS=0

pass() { PASS=$((PASS+1)); echo "PASS: $1"; }
warn() { WARN=$((WARN+1)); echo "WARN: $1"; }
fail() { FAIL=$((FAIL+1)); echo "FAIL: $1"; }

extract_desc() {
  awk '
    /^description:/ { found=1; sub(/^description:[[:space:]]*>?[[:space:]]*/, ""); if ($0 != "") print; next }
    found && /^[a-zA-Z_][A-Za-z0-9_-]*:/ { exit }
    found && /^---/ { exit }
    found { print }
  ' "$1" | tr -s ' \n' ' ' | sed 's/^ *//;s/ *$//'
}

DESC="$(extract_desc "$SKILL_MD")"
DESC_LOWER="$(printf '%s' "$DESC" | tr '[:upper:]' '[:lower:]')"

GENERIC_HITS=0
for phrase in \
  "helps with development" "all tasks" "any task" "anything" "everything" \
  "general coding" "coding tasks" "software development" "development work"; do
  if printf '%s' "$DESC_LOWER" | grep -Fq "$phrase"; then
    GENERIC_HITS=$((GENERIC_HITS+1))
  fi
done
if [[ "$GENERIC_HITS" -gt 0 ]]; then
  fail "description contains broad generic activation phrase(s); write a domain boundary instead"
else
  pass "description avoids obvious over-broad activation phrases"
fi

WORKFLOW_HITS=0
if [[ -d "$SKILL_ROOT/workflows" ]]; then
  while IFS= read -r wf; do
    base="$(basename "$wf" .md)"
    phrase="${base//-/ }"
    if printf '%s' "$DESC_LOWER" | grep -Eiq "(^|[^a-z0-9_-])(${base}|${phrase})([^a-z0-9_-]|$)"; then
      WORKFLOW_HITS=$((WORKFLOW_HITS+1))
    fi
  done < <(find "$SKILL_ROOT/workflows" -maxdepth 1 -type f -name '*.md' | sort)
fi
if [[ "$WORKFLOW_HITS" -ge 4 ]]; then
  fail "description mentions $WORKFLOW_HITS workflow names; route workflows in Common Tasks instead"
elif [[ "$WORKFLOW_HITS" -ge 2 ]]; then
  warn "description mentions $WORKFLOW_HITS workflow names; verify this is domain language, not routing"
else
  pass "description is not overloaded with workflow names"
fi

if [[ -d "$REPO_ROOT/skills" ]]; then
  SKILL_FILES=()
  while IFS= read -r f; do SKILL_FILES+=("$f"); done < <(find "$REPO_ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | sort)
  COUNT="${#SKILL_FILES[@]}"
  if [[ "$COUNT" -gt 1 ]]; then
    PRIMARY_COUNT="$({ grep -hE '^primary:[[:space:]]*true[[:space:]]*$' "${SKILL_FILES[@]}" 2>/dev/null || true; } | wc -l | tr -d ' ')"
    if [[ "$PRIMARY_COUNT" -gt 1 ]]; then
      fail "multiple skills declare primary: true"
    elif [[ "$PRIMARY_COUNT" -eq 0 ]]; then
      warn "multiple skills found but none declares primary: true"
    else
      pass "multi-skill repo has exactly one primary skill"
    fi

    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT
    for f in "${SKILL_FILES[@]}"; do
      skill="$(basename "$(dirname "$f")")"
      while IFS= read -r q; do
        [[ -n "$q" ]] && printf '%s\t%s\n' "$(printf '%s' "$q" | tr '[:upper:]' '[:lower:]')" "$skill" >> "$TMP"
      done < <(extract_desc "$f" | grep -o '"[^"]*"' | sed 's/^"//;s/"$//' || true)
      case "$skill" in
        fix-bug|add-feature|review|update-docs|maintain-docs|refactor)
          warn "skill '$skill' looks workflow-level; prefer workflows/*.md unless rules and triggers diverge"
          ;;
      esac
    done
    DUPES="$(sort -u "$TMP" | awk -F '\t' 'prev==$1 && owner!=$2 { print $1; dup=1 } { prev=$1; owner=$2 } END { exit dup ? 0 : 1 }' || true)"
    if [[ -n "$DUPES" ]]; then
      fail "duplicate quoted trigger phrase(s) across skills: $(printf '%s' "$DUPES" | tr '\n' ',' | sed 's/,$//')"
    else
      pass "no duplicate quoted trigger phrases across skills"
    fi
  else
    pass "single-skill layout; multi-skill overlap check not needed"
  fi
else
  pass "no skills/ directory; multi-skill overlap check not needed"
fi

echo "Summary: $PASS passed, $WARN warnings, $FAIL failures"
[[ "$FAIL" -eq 0 ]]
