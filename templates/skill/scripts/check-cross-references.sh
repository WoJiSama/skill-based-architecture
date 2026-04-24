#!/usr/bin/env bash
# check-cross-references.sh — List cross-references from workflows/*.md
# into rules/*.md and references/*.md, as a staleness-detection aid.
#
# Companion to the Task Closure Protocol's step 4 (Cross-Reference Sync Check).
# Informational only: this script never fails the build. It prints a report;
# the human or agent decides whether any flagged workflow needs an update.
#
# Usage:
#   bash check-cross-references.sh
#       Full report. For each workflows/*.md, list the rules/references files it
#       links to, with mtimes. A ⚠ marker flags cases where the referenced file
#       was modified after the workflow — the workflow may describe stale behavior.
#
#   bash check-cross-references.sh <changed-file>
#       Reverse lookup. List every workflows/*.md that links to <changed-file>.
#       Use this right after editing a rule or reference to find dependent workflows.
#       Accepts paths like "rules/foo.md", "references/bar.md", or just "foo.md".
#
# Run from: the skill directory (the one containing workflows/, rules/,
# references/). If you have multiple skills in skills/<name>/, cd into each.
#
# Exit code: 0 always — informational only, not a validation gate.

set -euo pipefail

SKILL_ROOT="${PWD}"
WORKFLOWS_DIR="${SKILL_ROOT}/workflows"

if [[ ! -d "$WORKFLOWS_DIR" ]]; then
  echo "check-cross-references.sh: no workflows/ directory found at ${SKILL_ROOT}." >&2
  echo "cd into the skill root (the directory containing workflows/, rules/, references/) first." >&2
  exit 1
fi

# ── Helpers ─────────────────────────────────────────────────────────────

# Print YYYY-MM-DD mtime of a file, or "(missing)" if absent.
# Handles both BSD (macOS) and GNU (Linux) stat.
mtime() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    echo "(missing)"
    return
  fi
  if stat -f "%Sm" -t "%Y-%m-%d" "$f" >/dev/null 2>&1; then
    stat -f "%Sm" -t "%Y-%m-%d" "$f"
  else
    stat -c "%y" "$f" 2>/dev/null | cut -d' ' -f1
  fi
}

# Extract unique rules/*.md and references/*.md paths from a markdown file.
# Strips URL fragments (#section). Safe on files with no matches.
extract_refs() {
  local file="$1"
  grep -oE '(rules|references)/[A-Za-z0-9_./-]+\.md' "$file" 2>/dev/null \
    | sed 's/#.*$//' \
    | sort -u \
    || true
}

# ── Reverse lookup mode ─────────────────────────────────────────────────

if [[ $# -gt 0 ]]; then
  target="${1#./}"
  target_basename="$(basename "$target")"

  echo "Workflows referencing ${target}:"
  found=0
  for wf in "$WORKFLOWS_DIR"/*.md; do
    [[ -f "$wf" ]] || continue
    # Match the target by basename inside a rules/ or references/ path.
    if grep -qE "(rules|references)/[^[:space:]\\\`\"')]*${target_basename}" "$wf" 2>/dev/null; then
      printf '  %s  (mtime: %s)\n' "${wf#$SKILL_ROOT/}" "$(mtime "$wf")"
      found=1
    fi
  done
  if [[ $found -eq 0 ]]; then
    echo "  (none found)"
    echo ""
    echo "If the change is material, the workflows may simply not have caught up yet."
    echo "Consider adding a pointer from the nearest workflow to the new rule/reference."
  fi

  # Resolve target to an absolute path for mtime lookup.
  if [[ -f "$SKILL_ROOT/$target" ]]; then
    echo ""
    echo "Target mtime: $(mtime "$SKILL_ROOT/$target")"
  elif [[ -f "$target" ]]; then
    echo ""
    echo "Target mtime: $(mtime "$target")"
  fi
  echo ""
  echo "Workflows older than the target may describe stale behavior. Review each."
  exit 0
fi

# ── Full report mode ────────────────────────────────────────────────────

echo "Cross-reference report — workflows/*.md → rules/*.md + references/*.md"
echo "========================================================================"
echo ""

stale_count=0
total_workflows=0

for wf in "$WORKFLOWS_DIR"/*.md; do
  [[ -f "$wf" ]] || continue
  total_workflows=$((total_workflows + 1))
  wf_rel="${wf#$SKILL_ROOT/}"
  wf_mtime="$(mtime "$wf")"
  refs="$(extract_refs "$wf")"

  if [[ -z "$refs" ]]; then
    printf '%s (mtime: %s)\n  (no cross-references to rules/ or references/)\n\n' \
      "$wf_rel" "$wf_mtime"
    continue
  fi

  printf '%s (mtime: %s)\n' "$wf_rel" "$wf_mtime"
  while IFS= read -r ref; do
    [[ -n "$ref" ]] || continue
    ref_path="$SKILL_ROOT/$ref"
    ref_mtime="$(mtime "$ref_path")"
    marker=""
    if [[ -f "$ref_path" && "$ref_path" -nt "$wf" ]]; then
      marker="  ⚠ referenced file newer than workflow"
      stale_count=$((stale_count + 1))
    elif [[ ! -f "$ref_path" ]]; then
      marker="  ⚠ referenced file missing"
    fi
    printf '  → %s (mtime: %s)%s\n' "$ref" "$ref_mtime" "$marker"
  done <<< "$refs"
  echo ""
done

echo "------------------------------------------------------------------------"
echo "Scanned ${total_workflows} workflow(s)."
if [[ $stale_count -gt 0 ]]; then
  echo "Found ${stale_count} link(s) where the referenced file was modified after the workflow."
  echo "Review each ⚠ flagged workflow; update its checklist if the rule/reference now contradicts it."
else
  echo "No stale references detected."
fi
echo ""
echo "Note: this is a heuristic. mtime is not proof of content drift — a workflow"
echo "may still be accurate after an unrelated edit to the referenced file. Use"
echo "judgment. The value of this script is prompting the human review, not enforcing it."
