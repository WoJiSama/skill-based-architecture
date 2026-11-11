#!/usr/bin/env bash
# upstream-status.sh — Report which active or archived upstream entries are newer
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
    --upstream)
      [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || { echo "FAIL: --upstream requires a URL or path." >&2; exit 2; }
      UPSTREAM_OVERRIDE="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: bash upstream-status.sh [skill-name|skill-root] [--upstream <url-or-path>]"
      echo "Lists active and archived UPSTREAM-CHANGES entries newer than .upstream-sync synced_sha. Exit 1 if behind."
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

# Resolve one comparison revision. Fetching a clone does not advance its checkout;
# use the fetched tracking ref and never turn a failed fetch into a current claim.
CLEAN=""; trap '[[ -n "$CLEAN" ]] && rm -rf "$CLEAN"' EXIT
LOCAL_REPO=0
if [[ -d "$UPSTREAM" ]] && git -C "$UPSTREAM" rev-parse --git-dir >/dev/null 2>&1; then
  REPO="$UPSTREAM"; LOCAL_REPO=1
else
  CLEAN="$(mktemp -d)"; echo "Fetching upstream: $UPSTREAM"
  git clone -q "$UPSTREAM" "$CLEAN" 2>/dev/null || { echo "FAIL: cannot clone $UPSTREAM" >&2; exit 2; }
  REPO="$CLEAN"
fi

REMOTES="$(git -C "$REPO" remote)"
if [[ "$LOCAL_REPO" -eq 1 && -z "$REMOTES" ]]; then
  TARGET_REF="HEAD"
  TARGET_DESCRIPTION="local snapshot: $UPSTREAM HEAD; remote freshness not checked"
else
  BRANCH_REF="$(git -C "$REPO" symbolic-ref -q HEAD 2>/dev/null || true)"
  [[ -n "$BRANCH_REF" ]] || { echo "FAIL: detached upstream checkout; cannot determine a tracked remote target." >&2; exit 2; }
  BRANCH="${BRANCH_REF#refs/heads/}"
  REMOTE="$(git -C "$REPO" config --get-all "branch.$BRANCH.remote" || true)"
  MERGE_REF="$(git -C "$REPO" config --get-all "branch.$BRANCH.merge" || true)"
  TARGET_REF="$(git -C "$REPO" for-each-ref --format='%(upstream)' "$BRANCH_REF")"
  if [[ -z "$REMOTE" || "$REMOTE" == . || "$REMOTE" == *$'\n'* ||
        -z "$MERGE_REF" || "$MERGE_REF" == *$'\n'* || -z "$TARGET_REF" ]] ||
     ! printf '%s\n' "$REMOTES" | grep -Fx -- "$REMOTE" >/dev/null; then
    echo "FAIL: branch $BRANCH has no unambiguous remote tracking ref; cannot determine upstream freshness." >&2
    exit 2
  fi
  if ! git -C "$REPO" fetch -q -- "$REMOTE" "+$MERGE_REF:$TARGET_REF"; then
    echo "FAIL: cannot fetch $REMOTE $MERGE_REF; upstream freshness is unknown." >&2
    exit 2
  fi
  TARGET_DESCRIPTION="fetched $TARGET_REF from $REMOTE ($MERGE_REF)"
fi
TARGET_SHA="$(git -C "$REPO" rev-parse --verify "${TARGET_REF}^{commit}" 2>/dev/null || true)"
[[ -n "$TARGET_SHA" ]] || { echo "FAIL: no upstream comparison commit found." >&2; exit 2; }
echo "Comparison target: $TARGET_SHA ($TARGET_DESCRIPTION)."

# The identity is the dated heading, independent of its current source file.
# Compare the union at both revisions so archival neither loses nor invents notes.
notes_at() {
  local revision="$1" source
  for source in UPSTREAM-CHANGES.md UPSTREAM-CHANGES-archive.md; do
    git -C "$REPO" show "$revision:$source" 2>/dev/null |
      awk -v source="$source" '/^## [0-9][0-9][0-9][0-9]-/ { print $0 "\t" source }'
  done
}
recent_notes() {
  notes_at "$TARGET_SHA" | awk -F '\t' '!seen[$1]++ { print "  " $1 " [" $2 "]"; if (++count == 8) exit }'
}

if [[ "$NO_BASE" -eq 1 ]]; then
  echo "⚠ No usable sync point in $SYNC_FILE."
  echo "  Showing the 8 most recent entries for a first refresh; update-upstream.md will set synced_sha after validation."
  recent_notes
  exit 1
fi

if [[ "$SYNCED_SHA" == "$TARGET_SHA" ]]; then
  echo "✓ Up to date with comparison target ($TARGET_SHA)."; exit 0
fi

if ! git -C "$REPO" cat-file -e "${SYNCED_SHA}^{commit}" 2>/dev/null; then
  echo "⚠ Recorded synced_sha ($SYNCED_SHA) not found upstream (rebased or shallow clone?)."
  echo "  Showing the 8 most recent entries instead — verify manually:"
  recent_notes
  exit 1
fi

NEW="$(awk -F '\t' 'FILENAME == ARGV[1] { seen[$1]=1; next } !seen[$1]++ { print $1 " [" $2 "]" }' \
        <(notes_at "$SYNCED_SHA") <(notes_at "$TARGET_SHA"))"

if [[ -z "$NEW" ]]; then
  echo "✓ No new UPSTREAM-CHANGES entries since your sync point."
  echo "  (Compared $SYNCED_SHA → $TARGET_SHA; no newly added dated headings.)"
  exit 0
fi

COUNT="$(printf '%s\n' "$NEW" | grep -c '^##' || true)"
echo "▲ Behind by $COUNT UPSTREAM-CHANGES entr$([[ "$COUNT" == 1 ]] && echo y || echo ies)."
echo "  your sync point : $SYNCED_SHA"
echo "  upstream target : $TARGET_SHA"
echo ""
echo "New since your sync point (read each entry in its listed upstream source at $TARGET_SHA):"
printf '%s\n' "$NEW" | sed 's/^/  /'
echo ""
echo "→ Port via workflows/update-upstream.md, then set 'synced_sha: $TARGET_SHA' in $SYNC_FILE"
exit 1
