#!/usr/bin/env bash
# Minimal self-hosting scenario checks for high-risk routes.
#
# These are transcript-shaped route proofs, not a general scenario harness:
# user phrase -> routing manifest row -> required reads + workflow.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

pass() { PASS=$((PASS+1)); echo "PASS: $1"; }
fail() { FAIL=$((FAIL+1)); echo "FAIL: $1"; }

task_block() {
  local manifest="$1" id="$2"
  awk -v id="$id" '
    /^[[:space:]]*-[[:space:]]id:/ {
      current=$0
      sub(/^[[:space:]]*-[[:space:]]id:[[:space:]]*/, "", current)
      in_task=(current==id)
    }
    in_task { print }
  ' "$manifest"
}

assert_contains() {
  local block="$1" needle="$2" label="$3"
  if printf '%s\n' "$block" | grep -qF "$needle"; then
    pass "$label contains $needle"
  else
    fail "$label missing $needle"
  fi
}

check_scenario() {
  local name="$1" manifest="$2" prompt="$3" route="$4" workflow="$5"
  shift 5
  local block
  block="$(task_block "$manifest" "$route")"

  echo ""
  echo "==> $name"
  if [[ -z "$block" ]]; then
    fail "$name route $route missing"
    return
  fi

  assert_contains "$block" "$prompt" "$name trigger_examples"
  assert_contains "$block" "workflow: $workflow" "$name workflow"

  local read_path
  for read_path in "$@"; do
    assert_contains "$block" "$read_path" "$name required_reads"
  done
}

echo "Self-hosting Scenario Checks"
echo "============================"

check_scenario \
  "edit templates" \
  "references/self-hosting-routing.yaml" \
  "修改 templates" \
  "edit-templates" \
  "templates/skill/workflows/edit-templates.md" \
  "SKILL.md" \
  "templates/README.md" \
  "templates/ANTI-TEMPLATES.md"

check_scenario \
  "improve activation routing" \
  "references/self-hosting-routing.yaml" \
  "优化 routing.yaml" \
  "improve-activation-routing" \
  "references/layout.md#description-as-trigger-condition" \
  "SKILL.md" \
  "references/layout.md" \
  "references/multi-skill-routing.md"

# update-upstream relies on always_read for rules (project-rules etc.); its
# required_reads is intentionally route-specific-only, so this proves the
# high-risk part: the trigger phrase reaches the update-upstream workflow.
check_scenario \
  "downstream upstream refresh" \
  "templates/skill/routing.yaml" \
  "上游项目更新了,帮我更新一下" \
  "update-upstream" \
  "workflows/update-upstream.md"

echo ""
echo "Summary: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
