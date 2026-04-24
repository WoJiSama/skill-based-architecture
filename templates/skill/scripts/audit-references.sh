#!/usr/bin/env bash
# audit-references.sh — Surface rules/ and references/ files with low/zero inbound links.
#
# Companion to workflows/update-rules.md § Activation Check (records require an
# activation path) and § Rule Deprecation (remove entries whose premise is gone).
# This script reveals the two failure modes those sections exist to prevent:
#
#   1. Orphans  — a file exists in rules/ or references/ but no workflow, rule, or
#                 SKILL.md links to it. Either the activation pointer was forgotten
#                 (add it) or the file is obsolete (delete it).
#   2. Stale   — a file with few inbound links and an old mtime; candidate for
#                 consolidation or deprecation when the surrounding rules rotate.
#
# Usage (run from the skill root — the directory containing workflows/, rules/,
# references/; for repos with self-hosting layout, run from the repo root):
#
#   bash audit-references.sh
#       Full report, sorted by inbound count (asc) then mtime (asc).
#
#   bash audit-references.sh --orphans
#       Only zero-inbound files. Useful as a CI/pre-commit trigger.
#
# Exit code:
#   0 — full report mode (always), or orphan mode with zero orphans
#   1 — orphan mode with one or more orphans found
#
# Heuristic only — "link" means the target path string appears in another file's
# text. Prose mentions of the concept without the path do not count. Use judgment
# before deleting anything the report flags.

set -euo pipefail

MODE="full"
if [[ "${1:-}" == "--orphans" ]]; then
  MODE="orphans"
fi

SKILL_ROOT="${PWD}"

# Directories scanned as potential referencers (places where activation pointers live).
SCAN_DIRS=("$SKILL_ROOT/workflows" "$SKILL_ROOT/rules" "$SKILL_ROOT/references")
SCAN_FILES=()

# Scan every top-level .md file at SKILL_ROOT. This captures SKILL.md, thin shells
# (AGENTS.md / CLAUDE.md / CODEX.md / GEMINI.md), and self-hosting variants
# (WORKFLOW.md / REFERENCE.md / TEMPLATES-GUIDE.md / EXAMPLES.md) in a single
# pass without enumerating names. Non-skill READMEs get scanned too — a valid
# inbound link from CONTRIBUTING.md still counts as activation.
for f in "$SKILL_ROOT"/*.md; do
  [[ -f "$f" ]] && SCAN_FILES+=("$f")
done

# If this skill sits under skills/<name>/, also scan the repo-root shells two
# levels up that may route into this skill from the outer harness.
if [[ -f "$SKILL_ROOT/../../AGENTS.md" || -f "$SKILL_ROOT/../../CLAUDE.md" ]]; then
  for s in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
    [[ -f "$SKILL_ROOT/../../$s" ]] && SCAN_FILES+=("$SKILL_ROOT/../../$s")
  done
fi

# Deduplicate (the same file could appear twice if SKILL_ROOT is also the repo root)
if [[ ${#SCAN_FILES[@]} -gt 0 ]]; then
  IFS=$'\n' SCAN_FILES=($(printf '%s\n' "${SCAN_FILES[@]}" | sort -u))
  unset IFS
fi

# ── Helpers ─────────────────────────────────────────────────────────────

mtime() {
  local f="$1"
  if [[ ! -f "$f" ]]; then echo "(missing)"; return; fi
  if stat -f "%Sm" -t "%Y-%m-%d" "$f" >/dev/null 2>&1; then
    stat -f "%Sm" -t "%Y-%m-%d" "$f"
  else
    stat -c "%y" "$f" 2>/dev/null | cut -d' ' -f1
  fi
}

# Strip fenced code blocks (``` … ```) from a file before matching. Paths that
# only appear inside code examples (e.g. `rm references/foo.md`) are noise, not
# real inbound links, and would otherwise inflate the count. Indented code
# blocks (4-space) are rare in our templates and intentionally not stripped —
# raise this later only if false positives recur.
strip_fences() {
  awk 'BEGIN{in_fence=0} /^```/ {in_fence = 1 - in_fence; next} !in_fence' "$1"
}

# Mention in $2 counts as an inbound link to $1 if target_rel appears outside
# fenced code blocks. Excludes the target's own file from its own count.
mentions_target() {
  local target_rel="$1"
  local scan_file="$2"
  strip_fences "$scan_file" | grep -qF "$target_rel"
}

# Count how many scanned files mention target_path (excluding the target itself).
count_inbound() {
  local target_rel="$1"           # e.g. "references/foo.md"
  local target_abs="$SKILL_ROOT/$target_rel"
  local count=0

  # Scan directories
  for dir in "${SCAN_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue
    for f in "$dir"/*.md; do
      [[ -f "$f" ]] || continue
      [[ "$f" == "$target_abs" ]] && continue
      if mentions_target "$target_rel" "$f" 2>/dev/null; then
        count=$((count+1))
      fi
    done
  done

  # Scan individual files (guard against empty array under set -u)
  for f in "${SCAN_FILES[@]:-}"; do
    [[ -n "$f" ]] || continue
    [[ -f "$f" ]] || continue
    [[ "$f" == "$target_abs" ]] && continue
    if mentions_target "$target_rel" "$f" 2>/dev/null; then
      count=$((count+1))
    fi
  done

  echo "$count"
}

# ── Collect audits ──────────────────────────────────────────────────────

declare -a AUDITS=()
for dir_name in references rules; do
  dir_abs="$SKILL_ROOT/$dir_name"
  [[ -d "$dir_abs" ]] || continue
  for f in "$dir_abs"/*.md; do
    [[ -f "$f" ]] || continue
    # Skip index / landing files — they're indexed by having content, not incoming links
    case "$(basename "$f")" in
      README.md|index.md) continue ;;
    esac
    rel="${f#$SKILL_ROOT/}"
    c="$(count_inbound "$rel")"
    m="$(mtime "$f")"
    AUDITS+=("$(printf '%d\t%s\t%s' "$c" "$m" "$rel")")
  done
done

if [[ ${#AUDITS[@]} -eq 0 ]]; then
  echo "audit-references.sh: no rules/*.md or references/*.md files found at $SKILL_ROOT." >&2
  echo "cd into the skill root (the directory containing rules/ or references/) first." >&2
  exit 0
fi

# ── Emit report ─────────────────────────────────────────────────────────

orphan_count=0

if [[ "$MODE" == "orphans" ]]; then
  echo "Orphan scan — files in rules/ or references/ with zero inbound links"
  echo "====================================================================="
  echo ""
  while IFS=$'\t' read -r c m path; do
    if [[ "$c" -eq 0 ]]; then
      printf '%-12s %s\n' "$m" "$path"
      orphan_count=$((orphan_count+1))
    fi
  done < <(printf '%s\n' "${AUDITS[@]}" | sort -t$'\t' -k1,1n -k2,2)

  echo ""
  if [[ "$orphan_count" -eq 0 ]]; then
    echo "No orphans. Every rules/ and references/ file has at least one inbound link."
    exit 0
  else
    echo "Found ${orphan_count} orphan(s). For each:"
    echo "  → Add an activation pointer from a workflow, rule, or SKILL.md route, OR"
    echo "  → Delete the file (see workflows/update-rules.md § Rule Deprecation)."
    exit 1
  fi
fi

# Full report
echo "Reference Audit — inbound link count per file"
echo "=============================================="
echo ""
printf '%-8s %-12s %s\n' "INBOUND" "MTIME" "FILE"
printf '%-8s %-12s %s\n' "-------" "----------" "----"

while IFS=$'\t' read -r c m path; do
  marker=""
  if [[ "$c" -eq 0 ]]; then
    marker="  ⚠ orphan — no workflow / rule / SKILL.md links here"
    orphan_count=$((orphan_count+1))
  elif [[ "$c" -eq 1 ]]; then
    marker="  · single referrer — verify it's a real activation path, not a stray mention"
  fi
  printf '%-8s %-12s %s%s\n' "$c" "$m" "$path" "$marker"
done < <(printf '%s\n' "${AUDITS[@]}" | sort -t$'\t' -k1,1n -k2,2)

echo ""
echo "Summary: ${#AUDITS[@]} file(s) audited, ${orphan_count} orphan(s)."
echo ""
echo "Scanned for inbound links in:"
for d in "${SCAN_DIRS[@]}"; do
  [[ -d "$d" ]] && echo "  - ${d#$SKILL_ROOT/}/ (*.md)"
done
for f in "${SCAN_FILES[@]:-}"; do
  [[ -n "$f" ]] || continue
  [[ -f "$f" ]] && echo "  - ${f#$SKILL_ROOT/}"
done
echo ""
echo "Notes:"
echo "  - 'inbound' counts files that contain the target path string. Prose mentions"
echo "    of the concept without the path do not count."
echo "  - Zero-inbound files are candidates for activation or deprecation — see"
echo "    workflows/update-rules.md § Activation Check and § Rule Deprecation."
echo "  - Heuristic only; always read the file before removing it."
