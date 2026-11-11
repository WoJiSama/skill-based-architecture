#!/usr/bin/env bash
# sync-vendor.sh — Sync the project's selected vendor payloads from upstream.
# The local sync-manifest.yaml owns selection; upstream's manifest is the
# allowed catalog. A missing local manifest bootstraps from that catalog.
#
# Safety model (upstream git history is the base):
#   local == upstream@synced_sha → UPDATE; local differs → LOCAL-EDIT
#   no local file → NEW; selection absent from catalog/source → DROPPED
# Existing selection metadata is preserved, never compared as vendor payload.
# All paths are validated before writing. Writes are checked, not transactional.
#
# Usage: bash sync-vendor.sh [skill-name|skill-root] --upstream <clone> [--apply]
# Default is dry-run. Exit: 0 = clean; 1 = attention; 2 = invalid input/I/O failure.
set -uo pipefail

TARGET=""; UP=""; APPLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --upstream)
      [[ $# -ge 2 && -n "$2" ]] || { echo "FAIL: --upstream requires a path." >&2; exit 2; }
      UP="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    -h|--help)
      echo "Usage: bash sync-vendor.sh [skill-name|skill-root] --upstream <path-to-clone> [--apply]"
      echo "Syncs the local manifest's selected vendor files; dry-run unless --apply."
      exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [[ -n "$TARGET" && -f "$TARGET/SKILL.md" ]]; then SKILL_ROOT="$TARGET"
elif [[ -n "$TARGET" && -f "skills/$TARGET/SKILL.md" ]]; then SKILL_ROOT="skills/$TARGET"
elif [[ -f "SKILL.md" ]]; then SKILL_ROOT="."
else echo "Usage: bash sync-vendor.sh [skill-name|skill-root] --upstream <path-to-clone> [--apply]" >&2; exit 2; fi

if [[ -z "$UP" || ! -d "$UP" ]] \
   || [[ "$(git -C "$UP" rev-parse --is-inside-work-tree 2>/dev/null)" != true ]]; then
  echo "FAIL: --upstream must be a git working tree (need history for the base check)." >&2
  exit 2
fi

validate_vendor_path() {
  local f="$1"
  case "$f" in
    ""|/*|.|..|./*|../*|*/.|*/..|*/./*|*/../*|*//*|*/)
      echo "FAIL: unsafe vendor path: $f" >&2; return 1 ;;
  esac
  case "$f" in
    sync-manifest.yaml|protocol-blocks/*|scripts/*) ;;
    *) echo "FAIL: vendor path is outside allowed owners: $f" >&2; return 1 ;;
  esac
}

# Reject symlinks, non-directory parents, and non-file leaves even when a later
# entry would only be reported as dropped. Never let cp reinterpret a directory.
validate_file_path() {
  local root="$1" f="$2" label="$3" probe part i
  local -a parts
  if [[ -L "$root" || ! -d "$root" ]]; then
    echo "FAIL: $label root is not a plain directory: $root" >&2; return 1
  fi
  IFS='/' read -r -a parts <<< "$f"
  probe="$root"
  for ((i=0; i<${#parts[@]}; i++)); do
    part="${parts[$i]}"; probe="$probe/$part"
    if [[ -L "$probe" ]]; then
      echo "FAIL: $label contains a symlink component: $f" >&2; return 1
    fi
    if [[ -e "$probe" ]]; then
      if [[ $i -lt $((${#parts[@]}-1)) && ! -d "$probe" ]]; then
        echo "FAIL: $label parent is not a directory: $f" >&2; return 1
      elif [[ $i -eq $((${#parts[@]}-1)) && ! -f "$probe" ]]; then
        echo "FAIL: $label is not a regular file: $f" >&2; return 1
      fi
    fi
  done
}

MANIFEST="$UP/templates/skill/sync-manifest.yaml"
LOCAL_MANIFEST="$SKILL_ROOT/sync-manifest.yaml"
validate_file_path "$UP" templates/skill/sync-manifest.yaml "upstream manifest" || exit 2
validate_file_path "$SKILL_ROOT" sync-manifest.yaml "local manifest" || exit 2
if [[ ! -f "$MANIFEST" ]]; then
  echo "FAIL: upstream clone has no templates/skill/sync-manifest.yaml (pre-manifest upstream? fall back to manual steps)." >&2
  exit 2
fi

TMP_DIR="$(mktemp -d)" || { echo "FAIL: cannot create sync temporary directory." >&2; exit 2; }
trap 'rm -rf "$TMP_DIR"' EXIT
CATALOG_LIST="$TMP_DIR/catalog"; VENDOR_LIST="$TMP_DIR/selected"; BASE_TMP="$TMP_DIR/base"
parse_manifest() {
  awk '
    BEGIN { inside=0; found=0; count=0; bad=0 }
    function fail(msg) { print "FAIL: " FILENAME ": " msg > "/dev/stderr"; bad=1 }
    {
      line=$0
      if (line ~ /^vendor:[[:space:]]*(#.*)?$/) {
        if (found) fail("duplicate vendor block")
        inside=1; found=1; next
      }
      if (!inside) next
      if (line ~ /^[^[:space:]#]/) { inside=0; next }
      if (line ~ /^[[:space:]]*($|#)/) next
      if (line ~ /^  -[[:space:]]+/) {
        sub(/^  -[[:space:]]+/, "", line); sub(/[[:space:]]+$/, "", line)
        if (line == "") fail("empty vendor path")
        else if (seen[line]++) fail("duplicate vendor path: " line)
        else { print line; count++ }
        next
      }
      fail("invalid vendor manifest line: " line)
    }
    END {
      if (!found) fail("sync-manifest.yaml has no vendor block")
      else if (count == 0) fail("sync-manifest.yaml vendor block is empty")
      if (bad) exit 1
    }
  ' "$1" > "$2"
}
parse_manifest "$MANIFEST" "$CATALOG_LIST" || { echo "FAIL: cannot read upstream vendor catalog." >&2; exit 2; }
HAS_LOCAL_MANIFEST=0
if [[ -f "$LOCAL_MANIFEST" ]]; then
  HAS_LOCAL_MANIFEST=1
  parse_manifest "$LOCAL_MANIFEST" "$VENDOR_LIST" || { echo "FAIL: cannot read local vendor selection." >&2; exit 2; }
else
  VENDOR_LIST="$CATALOG_LIST"
fi

# Complete preflight before any write, including entries after a valid update.
while IFS= read -r F; do
  validate_vendor_path "$F" || exit 2
done < "$CATALOG_LIST"
while IFS= read -r F; do
  validate_vendor_path "$F" || exit 2
  validate_file_path "$SKILL_ROOT" "$F" "vendor target" || exit 2
  validate_file_path "$UP" "templates/skill/$F" "vendor source" || exit 2
done < "$VENDOR_LIST"

SYNC_FILE="$SKILL_ROOT/.upstream-sync"
SYNCED_SHA="$(grep -E '^synced_sha:' "$SYNC_FILE" 2>/dev/null | head -1 | sed -E 's/^synced_sha:[[:space:]]*//')"
BASE_OK=1
if [[ -z "$SYNCED_SHA" || "$SYNCED_SHA" == *"<"* ]] \
   || ! git -C "$UP" cat-file -e "${SYNCED_SHA}^{commit}" 2>/dev/null; then
  BASE_OK=0
  echo "⚠ No usable synced_sha (missing/placeholder pointer, or sha not in upstream history)."
  echo "  Without a base, differing local files report as LOCAL-EDIT."
  echo "  Do one manual pass (update-upstream.md) and set the pointer."
  echo ""
fi

copy_verified() {
  local source="$1" destination="$2"
  if ! mkdir -p "$(dirname "$destination")"; then
    echo "FAIL: cannot create vendor target directory: $destination" >&2; return 1
  fi
  if ! cp -p "$source" "$destination"; then
    echo "FAIL: cannot copy vendor file: $destination" >&2; return 1
  fi
  if ! cmp -s "$source" "$destination"; then
    echo "FAIL: vendor copy readback failed: $destination" >&2; return 1
  fi
}

new=0; upd=0; ok=0; conflict=0; dropped=0
while IFS= read -r F; do
  # Fitted selection metadata is not a byte-equality payload.
  [[ "$F" == sync-manifest.yaml && $HAS_LOCAL_MANIFEST -eq 1 ]] && continue
  upnew="$UP/templates/skill/$F"; loc="$SKILL_ROOT/$F"
  if ! grep -Fxq -- "$F" "$CATALOG_LIST" || [[ ! -f "$upnew" ]]; then
    echo "DROPPED    $F  (absent from upstream catalog/source — review upstream changes; reconcile selection/deletion manually)"
    dropped=$((dropped+1)); continue
  fi
  if [[ ! -f "$loc" ]]; then
    if [[ $APPLY -eq 1 ]]; then copy_verified "$upnew" "$loc" || exit 2; fi
    echo "NEW        $F"
    new=$((new+1)); continue
  fi
  if cmp -s "$loc" "$upnew"; then ok=$((ok+1)); continue
  else compare_status=$?; fi
  if [[ $compare_status -gt 1 ]]; then
    echo "FAIL: cannot compare vendor file: $F" >&2; exit 2
  fi
  matches_base=0
  if [[ $BASE_OK -eq 1 ]] && git -C "$UP" cat-file -e "$SYNCED_SHA:templates/skill/$F" 2>/dev/null; then
    if ! git -C "$UP" show "$SYNCED_SHA:templates/skill/$F" > "$BASE_TMP"; then
      echo "FAIL: cannot read vendor base: $F" >&2; exit 2
    fi
    if cmp -s "$loc" "$BASE_TMP"; then matches_base=1
    else
      compare_status=$?
      if [[ $compare_status -gt 1 ]]; then echo "FAIL: cannot compare vendor base: $F" >&2; exit 2; fi
    fi
  fi
  if [[ $matches_base -eq 1 ]]; then
    if [[ $APPLY -eq 1 ]]; then copy_verified "$upnew" "$loc" || exit 2; fi
    echo "UPDATE     $F  (local == base @ ${SYNCED_SHA:0:7} → taking upstream HEAD)"
    upd=$((upd+1))
  else
    echo "LOCAL-EDIT $F  (differs from base — reconcile by hand: port your edit upstream, or keep the fork and record why)"
    conflict=$((conflict+1))
  fi
done < "$VENDOR_LIST"

echo ""
mode="dry-run"; [[ $APPLY -eq 1 ]] && mode="applied"
echo "vendor sync ($mode): $ok current · $new new · $upd updated · $conflict local-edit · $dropped dropped"
if [[ $APPLY -eq 0 && $((new + upd)) -gt 0 ]]; then
  echo "→ re-run with --apply to write the NEW/UPDATE files."
fi
[[ $((conflict + dropped)) -gt 0 ]] && exit 1
exit 0
