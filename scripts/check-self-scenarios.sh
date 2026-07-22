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

required_reads_block() {
  local manifest="$1" id="$2"
  task_block "$manifest" "$id" | awk '
    /^[[:space:]]*required_reads:/ { in_reads=1; next }
    in_reads && /^    [a-z_]+:/ { exit }
    in_reads { print }
  '
}

assert_contains() {
  local block="$1" needle="$2" label="$3"
  if printf '%s\n' "$block" | grep -qF "$needle"; then
    pass "$label contains $needle"
  else
    fail "$label missing $needle"
  fi
}

assert_not_contains() {
  local block="$1" needle="$2" label="$3"
  if printf '%s\n' "$block" | grep -qF "$needle"; then
    fail "$label unexpectedly contains $needle"
  else
    pass "$label excludes $needle"
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
  "references/layout.md"

assert_contains \
  "$(task_block references/self-hosting-routing.yaml improve-activation-routing)" \
  "Load references/multi-skill-routing.md only when evidence shows multiple skills" \
  "improve activation routing conditional multi-skill read"
assert_not_contains \
  "$(required_reads_block references/self-hosting-routing.yaml improve-activation-routing)" \
  "references/multi-skill-routing.md" \
  "improve activation routing initial reads"

check_scenario \
  "draft plan without distillation preload" \
  "references/self-hosting-routing.yaml" \
  "制定一个 plan" \
  "plan-feature" \
  "templates/skill/workflows/plan-feature.md" \
  "SKILL.md" \
  "docs/plans/README.md"
assert_not_contains \
  "$(required_reads_block references/self-hosting-routing.yaml plan-feature)" \
  "templates/skill/workflows/update-rules.md" \
  "draft plan initial reads"

check_scenario \
  "distill plan conclusions" \
  "references/self-hosting-routing.yaml" \
  "把 plan 的结论沉淀下来" \
  "distill-plan-conclusions" \
  "templates/skill/workflows/update-rules.md" \
  "SKILL.md" \
  "docs/plans/README.md"

# update-upstream relies on always_read for rules (project-rules etc.); its
# required_reads is intentionally route-specific-only, so this proves the
# high-risk part: the trigger phrase reaches the update-upstream workflow.
check_scenario \
  "downstream upstream refresh" \
  "templates/skill/routing.yaml" \
  "上游项目更新了,帮我更新一下" \
  "update-upstream" \
  "workflows/update-upstream.md"

check_scenario \
  "classify record before evidence load" \
  "templates/skill/routing.yaml" \
  "把这次踩坑记下来" \
  "update-rules" \
  "workflows/update-rules.md"

assert_contains \
  "$(task_block templates/skill/routing.yaml update-rules)" \
  "never preload both evidence stores" \
  "update-rules conditional evidence selection"
assert_not_contains \
  "$(required_reads_block templates/skill/routing.yaml update-rules)" \
  "references/gotchas.md" \
  "update-rules initial gotcha read"
assert_not_contains \
  "$(required_reads_block templates/skill/routing.yaml update-rules)" \
  "references/behavior-failures.md" \
  "update-rules initial behavior-failure read"

echo ""
echo "==> task execution contracts"

task_execution="$(<templates/skill/workflows/task-execution.md)"
assert_contains "$task_execution" "Simple tasks skip this protocol" "task execution Simple no-ceremony boundary"
assert_contains "$task_execution" "After any needed alignment, proceed without waiting unless" "task execution auto-start default"
assert_contains "$task_execution" "harness's native Plan/Task surface" "task execution native plan preference"
assert_contains "$task_execution" "runtime state, not a fixed chat template" "task execution state-presentation boundary"
assert_contains "$task_execution" "natural-language alignment" "task execution default natural presentation"
assert_contains "$task_execution" "do not repeat its steps in chat" "task execution no native-plan duplication"
assert_contains "$task_execution" "## Presentation Gate" "task execution presentation selection gate"
assert_contains "$task_execution" "Evaluate **Structured Brief first**" "task execution structured-first precedence"
assert_contains "$task_execution" "Compact Alignment is allowed only when all Structured conditions are false" "task execution compact fallback boundary"
assert_contains "$task_execution" "first user-facing task-start message MUST begin with separate Goal" "task execution full brief escalation"
assert_contains "$task_execution" "Steps must be numbered" "task execution full brief numbered plan"
assert_contains "$task_execution" "do not collapse the brief into prose" "task execution full brief remains scannable"
assert_contains "$task_execution" "## Recitation Loop" "task execution recitation section"
assert_contains "$task_execution" "Before each main Plan step" "task execution per-step Anchor checkpoint"
assert_contains "$task_execution" "do not narrate it before every tool call" "task execution no per-tool narration"
assert_contains "$task_execution" "does not create durable planning files or recover task state across Sessions" "task execution session-only boundary"
assert_contains "$task_execution" "new independent outcome -> re-match the route and replace the old Anchor/Plan" "task execution new-task reset"
assert_contains "$task_execution" "cannot omit or reorder a mandatory gate" "task execution Workflow authority"
assert_not_contains "$task_execution" "task_plan.md" "task execution no fixed task-plan file"
assert_not_contains "$task_execution" "cross-tool state sync" "task execution no cross-tool state system"
assert_not_contains "$task_execution" "Plan: <concise task-specific steps" "task execution no fixed chat block"

agent_behavior="$(<templates/skill/rules/agent-behavior.md)"
assert_contains "$agent_behavior" "## 2. Semantic Completeness Before Minimality" "always-read semantic completeness precedence"
assert_contains "$agent_behavior" "Default to **Product Development**" "always-read development default"
assert_contains "$agent_behavior" "state ownership/provenance" "always-read ownership trace"
assert_contains "$agent_behavior" "full/incremental/read/write path" "always-read all-path trace"
assert_contains "$agent_behavior" "Dependency count is risk evidence, not a veto" "always-read dependency-count boundary"
assert_contains "$agent_behavior" "Enter **Operational Stabilization** only when" "always-read operational exception"
assert_contains "$agent_behavior" "One clear action with one direct check proceeds without planning ceremony" "always-read Simple direct path"
assert_contains "$agent_behavior" "task-execution.md" "always-read Task Execution activation"
assert_contains "$agent_behavior" "present only useful alignment" "always-read proportional Anchor presentation"
assert_contains "$agent_behavior" "without duplicating visible steps in chat" "always-read native Plan deduplication"
assert_contains "$agent_behavior" "Before every main Plan step" "always-read Anchor checkpoint activation"

task_closure="$(<templates/skill/workflows/task-closure.md)"
assert_contains "$task_closure" "### Entry Gate" "closure execution entry gate"
assert_contains "$task_closure" 'return to [`task-execution.md`](task-execution.md)' "closure cannot finish execution"
assert_contains "$task_closure" "final Anchor Checkpoint" "closure final Anchor checkpoint"

plan_feature="$(<templates/skill/workflows/plan-feature.md)"
assert_contains "$plan_feature" "it is not the runtime Native Plan" "design plan runtime boundary"
assert_contains "$plan_feature" "pass its chosen outcome, acceptance criteria, boundaries, and task breakdown" "design to execution transition"

subagent_driven="$(<templates/skill/workflows/subagent-driven.md)"
assert_contains "$subagent_driven" "Worker-local status never advances the Native Plan" "worker status main-plan boundary"

assert_contains "$(<AGENTS.md)" "Task Anchor" "self-hosting shell Task Anchor activation"
assert_contains "$(<templates/shells/AGENTS.md)" "Task Anchor" "downstream shell Task Anchor activation"
assert_contains "$(<AGENTS.md)" "Anchor Checkpoint" "self-hosting shell Recitation activation"
assert_contains "$(<templates/shells/AGENTS.md)" "Anchor Checkpoint" "downstream shell Recitation activation"
assert_contains "$(<AGENTS.md)" "without repeating visible steps in chat" "self-hosting shell Plan deduplication"
assert_contains "$(<templates/shells/AGENTS.md)" "without repeating visible steps in chat" "downstream shell Plan deduplication"

echo ""
echo "==> business-model and persistence contracts"

business_profile="$(<templates/skill/workflows/profile-business-model.md.example)"
assert_contains "$business_profile" "No model and the gap affects the task" "business model missing state"
assert_contains "$business_profile" "Existing model is locally unclear" "business model local calibration state"
assert_contains "$business_profile" "Existing model conflicts with code/tests/runtime" "business model conflict state"
assert_contains "$business_profile" '"Later" is session-only' "business model no-placeholder deferral"

fix_bug="$(<templates/skill/workflows/fix-bug.md)"
assert_contains "$fix_bug" "IMPLEMENTATION_BUG" "fix-bug implementation classification"
assert_contains "$fix_bug" "DESIGN_CHANGE" "fix-bug design-change classification"
assert_contains "$fix_bug" "INSUFFICIENT_BUSINESS_CONTEXT" "fix-bug insufficient-context classification"
assert_contains "$fix_bug" "changes a business type, flow direction, state machine, or core invariant" "fix-bug plan escalation red line"
assert_contains "$fix_bug" "Repair-depth gate" "fix-bug repair-depth gate"
assert_contains "$fix_bug" "invariant-owning boundary" "fix-bug owning-boundary repair"
assert_contains "$fix_bug" "smallest semantically complete repair" "fix-bug minimality tie-breaker"
assert_contains "$fix_bug" "full/incremental/read/write path" "fix-bug all-path inspection"

change_managed="$(<templates/skill/workflows/change-managed.md)"
assert_contains "$change_managed" "Map semantic fan-out" "change-managed invariant fan-out"
assert_contains "$change_managed" "full/incremental/read/write path" "change-managed all-path map"
assert_contains "$change_managed" "smallest semantically complete change" "change-managed minimality tie-breaker"

assert_contains "$plan_feature" "business-model impact: unchanged / proposed change / unknown" "plan business-model impact"
assert_contains "$plan_feature" "update the formal model only when code, tests, and behavior land" "plan current-baseline contract"

update_rules="$(<templates/skill/workflows/update-rules.md)"
for outcome in "No write" "Extend in place" "Correct in place" "Retire" "Add independently"; do
  assert_contains "$update_rules" "$outcome" "gotcha reconciliation outcome"
done
assert_contains "$update_rules" "can a fresh Agent, reading only the proposed record, reconstruct the same key judgment" "persistence fidelity reconstruction"

maintain_docs="$(<templates/skill/workflows/maintain-docs.md)"
assert_contains "$maintain_docs" "## Step 2: Independent Load-Reason Audit" "independent load-reason audit"
assert_contains "$maintain_docs" "## Step 5: Semantic Before/After Reconciliation" "semantic before-after audit"

plan_large="$(<templates/skill/workflows/plan-large.md)"
assert_contains "$plan_large" "Read this file only after" "large-plan conditional read"
assert_contains "$plan_large" "If an angle would be read only with every sibling" "large-plan independent angle reason"

echo ""
echo "Summary: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
