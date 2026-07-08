#!/usr/bin/env bash
# upstream-status.sh — Report which upstream UPSTREAM-CHANGES.md entries are newer
# than this project's recorded sync point (.upstream-sync). Diagnosis only; porting
# stays manual via workflows/update-upstream.md.
#
# NOT the same as the upstream repo's check-upstream-changes.sh (that is an
# upstream-side guard that a change added a changelog entry). This is a DOWNSTREAM
# "am I behind upstream, and what changed" reporter.
#
# Usage:
#   bash scripts/upstream-status.sh [skill-name|skill-root] [--upstream <url-or-path>]
#
# Exit: 0 = up to date · 1 = behind (entries listed) · 2 = usage / cannot determine
set -uo pipefail

TARGET=""; UPSTREAM_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --upstream) UPSTREAM_OVERRIDE="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: bash upstream-status.sh [skill-name|skill-root] [--upstream <url-or-path>]"
      echo "Lists UPSTREAM-CHANGES entries newer than .upstream-sync synced_sha. Exit 1 if behind."
      exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

# Resolve the skill root (where SKILL.md + .upstream-sync live).
if [[ -n "$TARGET" && -f "$TARGET/SKILL.md" ]]; then SKILL_ROOT="$TARGET"
elif [[ -n "$TARGET" && -f "skills/$TARGET/SKILL.md" ]]; then SKILL_ROOT="skills/$TARGET"
elif [[ -f "SKILL.md" ]]; then SKILL_ROOT="."
else echo "Usage: bash upstream-status.sh [skill-name|skill-root] [--upstream <url-or-path>]" >&2; exit 2; fi

# Wrong-checkout guard: with multiple checkouts (git worktree), the live skill
# line exists in exactly one; porting into a stale sibling is the classic miss.
TOP="$(git rev-parse --show-toplevel 2>/dev/null || true)"
other_pointers() {
  [[ -z "$TOP" ]] && return 0
  local rel; rel="$(cd "$SKILL_ROOT" 2>/dev/null && pwd)"; rel="${rel#"$TOP"}"; rel="${rel#/}"
  git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | while read -r wt; do
    [[ "$wt" == "$TOP" ]] && continue
    [[ -f "$wt/${rel:+$rel/}.upstream-sync" ]] && echo "$wt/${rel:+$rel/}.upstream-sync"
  done
}

SYNC_FILE="$SKILL_ROOT/.upstream-sync"
MISSING_SYNC=0
if [[ ! -f "$SYNC_FILE" ]]; then
  OTHERS="$(other_pointers)"
  if [[ -n "$OTHERS" ]]; then
    echo "⚠ WRONG CHECKOUT? No sync pointer here, but sibling checkout(s) have one:"
    printf '%s\n' "$OTHERS" | sed 's/^/    /'
    echo "  The live skill line is probably there — do not port into this stale copy."
    exit 2
  fi
  MISSING_SYNC=1
fi

field() { grep -E "^$1:[[:space:]]*" "$SYNC_FILE" 2>/dev/null | head -1 | sed -E "s/^$1:[[:space:]]*//"; }
UPSTREAM="${UPSTREAM_OVERRIDE:-$(field upstream)}"
SYNCED_SHA="$(field synced_sha)"
NO_BASE=0

if [[ -z "$UPSTREAM" ]]; then
  echo "FAIL: no upstream URL found. Pass --upstream <repo-url-or-path> or set it in $SYNC_FILE." >&2
  exit 2
fi
if [[ "$MISSING_SYNC" -eq 1 || -z "$SYNCED_SHA" || "$SYNCED_SHA" == *"<"* ]]; then
  NO_BASE=1
fi

if [[ "$NO_BASE" -eq 0 ]]; then
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    osha="$(grep -E '^synced_sha:' "$p" 2>/dev/null | head -1 | sed -E 's/^synced_sha:[[:space:]]*//')"
    if [[ -n "$osha" && "$osha" != "$SYNCED_SHA" ]]; then
      echo "⚠ Sibling checkout has a different sync point: $p (${osha:0:7} vs here ${SYNCED_SHA:0:7})."
      echo "  Verify THIS checkout is the live skill-maintenance line before porting."
    fi
  done <<< "$(other_pointers)"
fi

# Get the upstream repo: reuse a local clone if given, else clone to a temp dir.
CLEAN=""; trap '[[ -n "$CLEAN" ]] && rm -rf "$CLEAN"' EXIT
if [[ -d "$UPSTREAM/.git" ]]; then
  REPO="$UPSTREAM"; git -C "$REPO" fetch -q 2>/dev/null || true
else
  CLEAN="$(mktemp -d)"; echo "Fetching upstream: $UPSTREAM"
  git clone -q "$UPSTREAM" "$CLEAN" 2>/dev/null || { echo "FAIL: cannot clone $UPSTREAM" >&2; exit 2; }
  REPO="$CLEAN"
fi

HEAD_SHA="$(git -C "$REPO" rev-parse HEAD 2>/dev/null || true)"
[[ -z "$HEAD_SHA" ]] && { echo "FAIL: no upstream HEAD found." >&2; exit 2; }

if [[ "$NO_BASE" -eq 1 ]]; then
  echo "⚠ No usable sync point in $SYNC_FILE."
  echo "  Showing the 8 most recent entries for a first refresh; update-upstream.md will set synced_sha after validation."
  git -C "$REPO" show "HEAD:UPSTREAM-CHANGES.md" 2>/dev/null | grep -E '^## [0-9]{4}-' | head -8 | sed 's/^/  /'
  exit 1
fi

if [[ "$SYNCED_SHA" == "$HEAD_SHA" ]]; then
  echo "✓ Up to date with upstream ($HEAD_SHA)."; exit 0
fi

if ! git -C "$REPO" cat-file -e "${SYNCED_SHA}^{commit}" 2>/dev/null; then
  echo "⚠ Recorded synced_sha ($SYNCED_SHA) not found upstream (rebased or shallow clone?)."
  echo "  Showing the 8 most recent entries instead — verify manually:"
  git -C "$REPO" show "HEAD:UPSTREAM-CHANGES.md" 2>/dev/null | grep -E '^## [0-9]{4}-' | head -8 | sed 's/^/  /'
  exit 1
fi

# New entries = dated '## ' headings added to the changelog since synced_sha.
NEW="$(git -C "$REPO" diff "$SYNCED_SHA..$HEAD_SHA" -- UPSTREAM-CHANGES.md 2>/dev/null \
        | grep -E '^\+## [0-9]{4}-' | sed -E 's/^\+//' || true)"

if [[ -z "$NEW" ]]; then
  echo "✓ No new UPSTREAM-CHANGES entries since your sync point."
  echo "  (Upstream HEAD moved $SYNCED_SHA → $HEAD_SHA, but nothing downstream-facing.)"
  exit 0
fi

COUNT="$(printf '%s\n' "$NEW" | grep -c '^##' || true)"
echo "▲ Behind by $COUNT UPSTREAM-CHANGES entr$([[ "$COUNT" == 1 ]] && echo y || echo ies)."
echo "  your sync point : $SYNCED_SHA"
echo "  upstream HEAD   : $HEAD_SHA"
echo ""
echo "New since your sync point (read these in upstream UPSTREAM-CHANGES.md for refresh guidance):"
printf '%s\n' "$NEW" | sed 's/^/  /'
echo ""
echo "→ Port via workflows/update-upstream.md, then set 'synced_sha: $HEAD_SHA' in $SYNC_FILE"
exit 1
