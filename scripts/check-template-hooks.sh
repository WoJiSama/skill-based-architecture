#!/usr/bin/env bash
# Verify hook templates keep their runtime contract without installing them.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/templates/hooks/session-start"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

make_skill() {
  local project="$1" name="$2" marker="$3"
  mkdir -p "$project/skills/$name"
  printf -- '---\nname: %s\n---\n\n# %s\n\n%s\n' \
    "$name" "$name" "$marker" > "$project/skills/$name/SKILL.md"
}

run_hook() {
  local project="$1" harness="$2"
  shift 2
  (cd "$project" && env CLAUDE_HARNESS="$harness" "$@" bash "$HOOK")
}

assert_payload() {
  local label="$1" output="$2" shape="$3" must="$4" absent="${5:-}"

  if ! OUT="$output" python3 - "$shape" "$must" "$absent" <<'PY'
import json
import os
import sys

shape, must, absent = sys.argv[1:]
payload = json.loads(os.environ["OUT"])
context = None

def reject(message):
    raise SystemExit(message)

if not isinstance(payload, dict):
    reject("payload is not an object")

if shape == "claude":
    hook_output = payload.get("hookSpecificOutput")
    if not isinstance(hook_output, dict):
        reject("missing hookSpecificOutput")
    if hook_output.get("hookEventName") != "SessionStart":
        reject("wrong hookEventName")
    if "additional_context" in payload or "additionalContext" in payload:
        reject("mixed top-level context keys")
    context = hook_output.get("additionalContext")
elif shape == "cursor":
    if "hookSpecificOutput" in payload or "additionalContext" in payload:
        reject("mixed non-cursor context keys")
    context = payload.get("additional_context")
elif shape == "generic":
    if "hookSpecificOutput" in payload or "additional_context" in payload:
        reject("mixed non-generic context keys")
    context = payload.get("additionalContext")
else:
    reject(f"unknown shape: {shape}")

if not isinstance(context, str) or not context:
    reject("missing context")
if must not in context:
    reject(f"missing marker: {must}")
if absent and absent in context:
    reject(f"contains excluded marker: {absent}")
PY
  then
    fail "$label"
  fi
  pass "$label"
}

assert_empty() {
  local label="$1" output="$2"
  [[ -z "$output" ]] || fail "$label emitted output unexpectedly"
  pass "$label"
}

echo "Template Hook Checks"
echo "===================="
[[ -f "$HOOK" ]] || fail "missing session-start template: $HOOK"
pass "session-start template exists"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SINGLE_MARKER="SBA_SESSION_START_SINGLE_SKILL_MARKER"
ROUTER_MARKER="SBA_SESSION_START_EXPLICIT_ROUTER_MARKER"
OTHER_MARKER="SBA_SESSION_START_OTHER_SKILL_MARKER"
CUSTOM_MARKER="SBA_SESSION_START_CUSTOM_ROUTER_MARKER"

single="$TMP/single"
mkdir -p "$single"
make_skill "$single" sample "$SINGLE_MARKER"
assert_payload "claude shape uses hookSpecificOutput.additionalContext" "$(run_hook "$single" claude)" claude "$SINGLE_MARKER"
assert_payload "cursor shape uses additional_context" "$(run_hook "$single" cursor)" cursor "$SINGLE_MARKER"
assert_payload "generic shape uses top-level additionalContext" "$(run_hook "$single" opencode)" generic "$SINGLE_MARKER"

with_router="$TMP/with-router"
mkdir -p "$with_router"
make_skill "$with_router" router "$ROUTER_MARKER"
make_skill "$with_router" sample "$OTHER_MARKER"
assert_payload "conventional router wins over sibling skills" "$(run_hook "$with_router" claude)" claude "$ROUTER_MARKER" "$OTHER_MARKER"

custom_router="$TMP/custom-router"
mkdir -p "$custom_router"
make_skill "$custom_router" sample "$OTHER_MARKER"
printf '# Custom router\n\n%s\n' "$CUSTOM_MARKER" > "$custom_router/custom-router.md"
assert_payload "SKILL_ROUTER_PATH wins over fallback" "$(run_hook "$custom_router" claude SKILL_ROUTER_PATH=custom-router.md)" claude "$CUSTOM_MARKER" "$OTHER_MARKER"

ambiguous="$TMP/ambiguous"
mkdir -p "$ambiguous"
make_skill "$ambiguous" alpha "$OTHER_MARKER"
make_skill "$ambiguous" beta "$SINGLE_MARKER"
assert_empty "ambiguous multi-skill project injects nothing" "$(run_hook "$ambiguous" claude)"

missing_explicit="$TMP/missing-explicit"
mkdir -p "$missing_explicit"
make_skill "$missing_explicit" sample "$SINGLE_MARKER"
assert_empty "missing explicit router does not fall back implicitly" "$(run_hook "$missing_explicit" claude SKILL_ROUTER_PATH=missing.md)"

echo
echo "All template hook checks passed."
