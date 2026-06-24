#!/usr/bin/env bash
# route-reachability.sh — every active-tier file must be ROUTE-reachable.
#
# Complements audit-orphans.sh. audit-orphans checks LINK-reachability: the
# file's path is mentioned *somewhere* (incl. the SKILL.md manifest), so the
# file is not dead. That is necessary but NOT sufficient. This script checks
# ROUTE-reachability: starting from routing.yaml (always_read + every task's
# required_reads + route text) and following hub-navigation edges (a reachable
# file that lists another file's skill-root-relative path), can the agent
# actually arrive at the file while doing a task?
#
# A file that is link-reachable (e.g. listed only in the SKILL.md manifest) but
# on no route is "stored, not activated" — you split it out for cohesion, but
# the task that needs it never reads it. That is pure waste, and the failure
# this check exists to catch.
#
# Active tiers (MUST be route-reachable): architecture/ conventions/ gotchas/
# rules/. Lookup tiers (references/, docs/) are read on demand and exempt;
# workflows/ are routed by each task's `workflow:` field + covered by
# check-cross-references.sh.
#
# The fix for a fine-grained tier is a routed index.md hub: route the hub, list
# each file in it as a skill-root-relative inline-code path; the agent
# navigates from there. One hub keeps a whole tier reachable without enumerating
# every file in every route.
#
# Usage (run from the skill root, the dir holding the tier directories):
#   bash route-reachability.sh
#
# Exit code: 0 = all active-tier files route-reachable, 1 = one or more not.

set -uo pipefail

ROOT="$PWD"
ROUTING="$ROOT/routing.yaml"

# Tiers that MUST be route-reachable.
ACTIVE_DIRS=(architecture conventions gotchas rules)
# Path shape used both for seeding and for hub-navigation edges (all tiers, so
# the graph can traverse through references/ and workflows/ to reach an active file).
PATH_RE='(architecture|conventions|gotchas|rules|references|workflows)/[A-Za-z0-9._/-]+\.md'

if [[ ! -f "$ROUTING" ]]; then
  echo "route-reachability: no routing.yaml at $ROOT — nothing to check"
  exit 0
fi

strip_fences() { awk 'BEGIN{f=0} /^```/ {f=1-f; next} !f' "$1"; }
extract_paths() { grep -oE "$PATH_RE" | sort -u; }

# Seed: content paths the routing.yaml actually routes to (comments excluded so a
# path mentioned only in a comment does not falsely count as routed).
reachable="$(grep -vE '^[[:space:]]*#' "$ROUTING" | extract_paths)"

# Fixpoint: expand through reachable files — hub lists its spokes, a routed file
# points at another. strip_fences so example paths inside code blocks don't leak in.
while :; do
  add=""
  while IFS= read -r rel; do
    [[ -n "$rel" && -f "$ROOT/$rel" ]] || continue
    add+="$(strip_fences "$ROOT/$rel" | extract_paths)"$'\n'
  done <<< "$reachable"
  next="$(printf '%s\n%s\n' "$reachable" "$add" | grep -vE '^[[:space:]]*$' | sort -u)"
  [[ "$next" == "$reachable" ]] && break
  reachable="$next"
done

UNREACHED=0
TOTAL=0
echo "Route-reachability — active-tier files reachable from routing.yaml + hubs"
echo "==================================================================="
for d in "${ACTIVE_DIRS[@]}"; do
  [[ -d "$ROOT/$d" ]] || continue
  for f in "$ROOT/$d"/*.md; do
    [[ -f "$f" ]] || continue
    case "$(basename "$f")" in README.md) continue ;; esac
    TOTAL=$((TOTAL+1))
    rel="${f#$ROOT/}"
    if ! grep -qxF "$rel" <<< "$reachable"; then
      echo "UNREACHED  $rel"
      UNREACHED=$((UNREACHED+1))
    fi
  done
done

echo ""
echo "Summary: $UNREACHED unreachable / $TOTAL active-tier file(s)"
if [[ "$UNREACHED" -gt 0 ]]; then
  echo "For each: add it to a task's required_reads, OR list it (skill-root-relative inline-code path) in a routed index.md hub. See references/rate-of-change-split.md § 4."
  exit 1
fi
exit 0
