#!/usr/bin/env bash
# Run the upstream repo's full maintenance check suite.

set -euo pipefail

MODE="worktree"
BASE="${UPSTREAM_CHANGES_BASE:-HEAD}"
RUN_LIVE_AGENT=0

usage() {
  cat <<'EOF'
Usage: scripts/check-all.sh [--base <git-ref>] [--staged] [--live-agent]

Runs the self-hosting upstream maintenance checks used before commit/push:
  - upstream change-note guard
  - upstream supersedes refs check
  - template routing manifest check
  - template SessionStart hook runtime contract
  - responsibility-aware downstream validation contracts
  - empty-target Single-file materializer journey
  - one-procedure Folder-light materializer journey
  - declared Full downstream scaffold structural contract
  - existing-project first-migration journey
  - self-hosting shells + activation check
  - whitespace diff check
  - single-root + two-root integrity contracts
  - self-hosting manifest route proofs
  - self-hosting shell/bootstrap/link smoke subset
  - self-hosting orphan audit
  - Full template content conformance
  - self-hosting content conformance (upstream-canon)

Default mode checks the working tree. Use --staged from a pre-commit hook to
check the pending commit for UPSTREAM-CHANGES.md coverage and whitespace.
Use --live-agent to add the real Codex Single-file task and ordinary SBA
migration journeys in fresh temporary projects; without it, green means
deterministic structure and contract checks only.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      [[ $# -ge 2 ]] || { echo "Missing value for --base" >&2; exit 2; }
      BASE="$2"
      shift 2
      ;;
    --staged)
      MODE="staged"
      shift
      ;;
    --live-agent)
      RUN_LIVE_AGENT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

run() {
  local label="$1"
  shift
  printf '\n==> %s\n' "$label"
  "$@"
}

LIVE_AGENT_NO_VERDICT_MODES=""

run_live_agent_mode() {
  local label="$1" live_mode="$2" live_exit_code
  printf '\n==> %s\n' "$label"
  set +e
  bash scripts/check-live-agent-journey.sh --mode "$live_mode"
  live_exit_code=$?
  set -e
  case "$live_exit_code" in
    0) return 0 ;;
    3)
      if [[ -n "$LIVE_AGENT_NO_VERDICT_MODES" ]]; then
        LIVE_AGENT_NO_VERDICT_MODES="$LIVE_AGENT_NO_VERDICT_MODES, $live_mode"
      else
        LIVE_AGENT_NO_VERDICT_MODES="$live_mode"
      fi
      return 0
      ;;
    *) return "$live_exit_code" ;;
  esac
}

fill_sample_scaffold() {
  local target="$1" name="$2" summary="$3"
  (
    cd "$target"
    find "skills/$name" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor \
      -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.yaml' \) \
      -exec sed -i.bak \
        -e "s/{{NAME}}/$name/g" \
        -e "s/{{SUMMARY}}/$summary/g" \
        -e "s/<trigger phrase 1>/fix sample bug/g" \
        -e "s/<trigger phrase 2>/plan sample feature/g" \
        -e "s/<trigger phrase 3 \\/ 中文触发短语>/更新示例技能/g" \
        -e "s/<condition 1>/working on the sample project/g" \
        -e "s/<condition 2>/maintaining sample project rules/g" \
        {} +
    find . -name '*.bak' -type f -delete

    find "skills/$name" .cursor \
      -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.yaml' \) \
      -exec perl -0pi -e 's/<!-- FILL:.*?-->//sg' {} +
    perl -0pi -e 's/^# FILL:.*?(?=^tasks:)/# This fixture intentionally exercises the complete routed scaffold.\n/ms' \
      "skills/$name/routing.yaml"
    perl -0pi -e 's/- <!-- Boundary 1 -->/- Owns the sample application and its repository-local validation rules./; s/- <!-- Boundary 2 -->/- Does not own deployment credentials or external release approval./' \
      "skills/$name/SKILL.md"

    cat > "skills/$name/rules/project-rules.md" <<'MARKDOWN'
# Project Rules

- Changes to the sample application must preserve its command-line contract.
- Release-affecting work requires the repository validation workflow before delivery.
- External credentials, deployment, and publication remain outside this project Skill.
- Project-rule changes require explicit user intent and the routed update-rules workflow.
MARKDOWN

    cat > "skills/$name/rules/coding-standards.md" <<'MARKDOWN'
# Coding Standards

- Use kebab-case file names and descriptive shell function names.
- Comment only non-obvious ownership, failure, or recovery boundaries.
- Keep shell scripts compatible with Bash 3.2 unless a checked runtime contract says otherwise.
- Run the repository-owned formatter or syntax check before reporting implementation complete.
- Keep imports and helper ownership local to the smallest responsible module.
MARKDOWN
  )
}

assert_full_scaffold_surfaces() {
  local target="$1" name="$2" path
  local required=(
    "skills/$name/routing.yaml"
    "skills/$name/workflows/task-execution.md"
    "skills/$name/workflows/task-closure.md"
    "skills/$name/scripts/smoke-test.sh"
    "skills/$name/scripts/sync-routing.sh"
    ".cursor/skills/$name/SKILL.md"
    ".cursor/rules/workflow.mdc"
    "AGENTS.md"
    "CLAUDE.md"
    "CODEX.md"
    "GEMINI.md"
  )

  for path in "${required[@]}"; do
    [[ -e "$target/$path" ]] || {
      echo "Full scaffold fixture missing declared surface: $path" >&2
      return 1
    }
  done
}

validate_downstream_scaffold() {
  local target="$1" name="$2"
  (
    cd "$target"
    bash "skills/$name/scripts/sync-routing.sh" "$name" --check
    bash "skills/$name/scripts/smoke-test.sh" "$name" --phase 8
    (
      cd "skills/$name"
      bash scripts/audit-orphans.sh
      bash scripts/route-reachability.sh
    )
  )
}

# Exercise the actual no-evidence Quick Start path.  The assertions are about
# the fitted boundary (the two owners and the absence of independently owned
# surfaces), not a copied Full scaffold inventory.
check_single_file_materializer_journey() (
  set -euo pipefail
  local tmp before name summary preview apply file_count
  tmp="$(mktemp -d)"
  before="$(mktemp -d)"
  trap 'rm -rf "$tmp" "$before"' EXIT
  name="single-project"
  summary="Small project with one direct procedure"

  preview="$(bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$tmp" --name "$name" --summary "$summary")"
  [[ "$preview" == *"DRY-RUN: target unchanged; the evidence plan is session-scoped and was not written to the target"* ]]
  diff -r "$before" "$tmp"

  apply="$(bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$tmp" --name "$name" --summary "$summary" --apply)"
  [[ "$apply" == *"APPLIED: evidence-selected Skill created; generated owners passed marker/path staging checks"* ]]
  [[ "$apply" == *"APPLIED RESPONSIBILITIES: materialization=direct routed=0"* ]]

  [[ -f "$tmp/AGENTS.md" ]]
  [[ -f "$tmp/skills/$name/SKILL.md" ]]
  file_count="$(find "$tmp" -type f -print | wc -l | tr -d '[:space:]')"
  [[ "$file_count" -eq 2 ]]
  for path in \
    "skills/$name/routing.yaml" \
    "skills/$name/workflows" \
    "skills/$name/scripts" \
    "CLAUDE.md" "CODEX.md" "GEMINI.md" \
    ".cursor" ".claude" ".codex" ".gemini"; do
    [[ ! -e "$tmp/$path" ]] || {
      echo "Single-file journey materialized an unadmitted surface: $path" >&2
      return 1
    }
  done
  grep -qF "skills/$name/SKILL.md" "$tmp/AGENTS.md"
  ! grep -qE 'routing\.yaml|workflows/|scripts/' "$tmp/skills/$name/SKILL.md"

  (
    cd "$tmp"
    bash "$ROOT/templates/skill/scripts/smoke-test.sh" "$name" --phase 8 >/dev/null
  )
  printf 'PASS: empty target materializes only the fitted Single-file owners\n'
)

# Exercise a single recurring workflow signal.  This must produce the
# Folder-light direct shape: rule owners plus one project procedure, while
# routing, Full execution/Closure owners, maintenance scripts, and extra
# harness registrations remain absent.
check_folder_direct_materializer_journey() (
  set -euo pipefail
  local tmp before name summary preview apply file_count
  tmp="$(mktemp -d)"
  before="$(mktemp -d)"
  trap 'rm -rf "$tmp" "$before"' EXIT
  name="folder-project"
  summary="Project with one recurring release procedure"
  cat > "$tmp/README.md" <<'MARKDOWN'
# Release Helper

## Release Workflow

Follow this workflow to change release metadata and verify a release.

1. Read VERSION.
2. Run the repository release check.
MARKDOWN
  cp -R "$tmp/." "$before/"

  preview="$(bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$tmp" --name "$name" --summary "$summary")"
  [[ "$preview" == *"recurring_signals=1"* ]]
  [[ "$preview" == *"workflow_pressure=1"* ]]
  [[ "$preview" == *"CREATE: skills/$name/rules/project-rules.md"* ]]
  [[ "$preview" == *"CREATE: skills/$name/rules/coding-standards.md"* ]]
  [[ "$preview" == *"CREATE: skills/$name/workflows/project-task.md"* ]]
  [[ "$preview" != *"CREATE: skills/$name/routing.yaml"* ]]
  [[ "$preview" != *"CREATE: skills/$name/scripts/"* ]]
  [[ "$preview" != *"CREATE: skills/$name/workflows/task-execution.md"* ]]
  [[ "$preview" != *"CREATE: skills/$name/workflows/task-closure.md"* ]]
  [[ "$preview" == *"DRY-RUN: target unchanged; the evidence plan is session-scoped and was not written to the target"* ]]
  diff -r "$before" "$tmp"

  apply="$(bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$tmp" --name "$name" --summary "$summary" --apply)"
  [[ "$apply" == *"APPLIED: evidence-selected Skill created; generated owners passed marker/path staging checks"* ]]
  [[ "$apply" == *"APPLIED RESPONSIBILITIES: materialization=folder routed=0"* ]]
  cmp "$before/README.md" "$tmp/README.md"

  for path in \
    "skills/$name/SKILL.md" \
    "skills/$name/rules/project-rules.md" \
    "skills/$name/rules/coding-standards.md" \
    "skills/$name/workflows/project-task.md"; do
    [[ -f "$tmp/$path" ]] || {
      echo "Folder-light direct journey is missing fitted owner: $path" >&2
      return 1
    }
  done
  file_count="$(find "$tmp" -type f -print | wc -l | tr -d '[:space:]')"
  [[ "$file_count" -eq 6 ]]
  for path in \
    "skills/$name/routing.yaml" \
    "skills/$name/scripts" \
    "skills/$name/workflows/task-execution.md" \
    "skills/$name/workflows/task-closure.md" \
    "skills/$name/conformance.yaml" \
    "skills/$name/sync-manifest.yaml" \
    "skills/$name/.upstream-sync" \
    "skills/$name/references" \
    "CLAUDE.md" "CODEX.md" "GEMINI.md" \
    ".cursor" ".claude" ".codex" ".gemini"; do
    [[ ! -e "$tmp/$path" ]] || {
      echo "Folder-light direct journey materialized an unadmitted surface: $path" >&2
      return 1
    }
  done
  grep -qF "rules/project-rules.md" "$tmp/skills/$name/SKILL.md"
  grep -qF "workflows/project-task.md" "$tmp/skills/$name/SKILL.md"
  grep -qF "repository-owned fitted" \
    "$tmp/skills/$name/workflows/project-task.md"
  grep -qF "validation command." \
    "$tmp/skills/$name/workflows/project-task.md"

  (
    cd "$tmp"
    bash "$ROOT/templates/skill/scripts/smoke-test.sh" "$name" --phase 8 >/dev/null
  )
  printf 'PASS: one recurring procedure materializes fitted Folder-light direct owners\n'
)

check_downstream_scaffold() (
  set -euo pipefail
  local tmp name summary
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  name="sample-skill"
  summary="Sample downstream scaffold for upstream regression checks"

  # This is an explicitly evidenced broad project, not the default path. The
  # blank-target/default journey is covered separately by the responsibility
  # contract fixture; keeping this evidence here preserves a real Full-like
  # regression without teaching Quick Start to copy it unconditionally.
  mkdir -p "$tmp/.cursor" "$tmp/.claude" "$tmp/.codex" "$tmp/.gemini" \
    "$tmp/.github/workflows" "$tmp/scripts"
  printf '# Sample project instructions\n\n## Fix bug\nReproduce the bug and run the check.\n\n## Add feature\nPreserve the public contract.\n\n## Refactor\nUpdate all callers and review the result.\n' > "$tmp/AGENTS.md"
  printf '# Upstream tracking evidence\nRefresh upstream vendor files only with the repository check.\n' > "$tmp/UPSTREAM-CHANGES.md"

  bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$tmp" --name "$name" --summary "$summary" --apply
  # Simulate the Agent's semantic merge of the preserved source entry before
  # running fitted structural checks; the scaffold itself must not overwrite it.
  for shell in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
    cp "$ROOT/templates/shells/$shell" "$tmp/$shell"
  done
  cp "$ROOT/templates/shells/.cursor/rules/workflow.mdc" "$tmp/.cursor/rules/workflow.mdc"
  fill_sample_scaffold "$tmp" "$name" "$summary"
  # Semantic merge changes canonical route inputs and generated shell bodies.
  # Model the real Agent path: regenerate from routing.yaml, then let the
  # validator below prove check mode is clean rather than accepting drift.
  (
    cd "$tmp"
    bash "skills/$name/scripts/sync-routing.sh" "$name" >/dev/null
  )
  assert_full_scaffold_surfaces "$tmp" "$name"
  validate_downstream_scaffold "$tmp" "$name"
)

check_existing_project_scaffold_journey() (
  set -euo pipefail
  local tmp before after_apply name summary preview conflict_output conflict_status evidence
  tmp="$(mktemp -d)"
  before="$(mktemp -d)"
  after_apply="$(mktemp -d)"
  trap 'rm -rf "$tmp" "$before" "$after_apply"' EXIT
  name="existing-project"
  summary="Existing project migration journey"

  mkdir -p "$tmp/.cursor/rules" "$tmp/.codex" "$tmp/.gemini"
  printf '# Existing Agent Rules\n\nKeep the release approval rule.\n' > "$tmp/AGENTS.md"
  printf '# Existing Claude Rules\n\n## Fix bug\nReproduce the failing case.\n\n## Change feature\nPreserve the public behavior.\n' > "$tmp/CLAUDE.md"
  printf '# Existing Cursor Rule\n\nRun the repository formatter before review.\n' > "$tmp/.cursor/rules/workflow.mdc"
  cp -R "$tmp/." "$before/"

  preview="$(bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$tmp" --name "$name" --summary "$summary")"
  [[ "$preview" == *"PRESERVE: AGENTS.md"* ]]
  [[ "$preview" == *"PRESERVE: .cursor/rules/workflow.mdc"* ]]
  diff -r "$before" "$tmp"

  bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$tmp" --name "$name" --summary "$summary" --apply
  cmp "$before/AGENTS.md" "$tmp/AGENTS.md"
  cmp "$before/.cursor/rules/workflow.mdc" "$tmp/.cursor/rules/workflow.mdc"

  cp -R "$tmp/." "$after_apply/"
  set +e
  conflict_output="$(bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$tmp" --name "$name" --summary "$summary" 2>&1)"
  conflict_status=$?
  set -e
  [[ $conflict_status -eq 2 ]]
  [[ "$conflict_output" == *"CONFLICT: skills/$name already exists"* ]]
  diff -r "$after_apply" "$tmp"

  cp "$before/AGENTS.md" "$tmp/skills/$name/rules/project-rules.md"
  cp "$before/.cursor/rules/workflow.mdc" "$tmp/skills/$name/rules/coding-standards.md"
  cp "$ROOT/templates/shells/AGENTS.md" "$tmp/AGENTS.md"
  # The existing Claude entry is also a preserved source.  The original remains
  # available under `before`/`.migration-source` for semantic evidence; the
  # target root entry is switched to the canonical thin shell so the generated
  # marker contract can be checked after the merge below.
  cp "$ROOT/templates/shells/CLAUDE.md" "$tmp/CLAUDE.md"
  cp "$ROOT/templates/shells/.cursor/rules/workflow.mdc" "$tmp/.cursor/rules/workflow.mdc"
  fill_sample_scaffold "$tmp" "$name" "$summary"
  cp "$before/AGENTS.md" "$tmp/skills/$name/rules/project-rules.md"
  cp "$before/.cursor/rules/workflow.mdc" "$tmp/skills/$name/rules/coding-standards.md"
  cat >> "$tmp/skills/$name/rules/project-rules.md" <<'MARKDOWN'

## Migrated Claude rules

- Reproduce the failing case.
- Preserve the public behavior.
MARKDOWN

  grep -qF 'Keep the release approval rule.' "$tmp/skills/$name/rules/project-rules.md"
  grep -qF 'Run the repository formatter before review.' "$tmp/skills/$name/rules/coding-standards.md"
  mkdir -p "$tmp/.migration-source/.cursor/rules"
  cp "$before/AGENTS.md" "$tmp/.migration-source/AGENTS.md"
  cp "$before/CLAUDE.md" "$tmp/.migration-source/CLAUDE.md"
  cp "$before/.cursor/rules/workflow.mdc" "$tmp/.migration-source/.cursor/rules/workflow.mdc"
  evidence="$tmp/migration-evidence.json"
  cat > "$evidence" <<JSON
{
  "version": 1,
  "inventory": [
    {
      "id": "release-approval",
      "source": ".migration-source/AGENTS.md",
      "text": "Keep the release approval rule."
    },
    {
      "id": "formatter-before-review",
      "source": ".migration-source/.cursor/rules/workflow.mdc",
      "text": "Run the repository formatter before review."
    },
    {
      "id": "claude-reproduce-failing-case",
      "source": ".migration-source/CLAUDE.md",
      "text": "Reproduce the failing case."
    },
    {
      "id": "claude-preserve-public-behavior",
      "source": ".migration-source/CLAUDE.md",
      "text": "Preserve the public behavior."
    }
  ],
  "mappings": [
    {
      "inventory_id": "release-approval",
      "destination": "skills/$name/rules/project-rules.md",
      "mode": "verbatim",
      "activation_chain": [
        "skills/$name/SKILL.md",
        "skills/$name/routing.yaml",
        "skills/$name/workflows/change-managed.md",
        "skills/$name/rules/change-discipline.md",
        "skills/$name/rules/project-rules.md"
      ]
    },
    {
      "inventory_id": "formatter-before-review",
      "destination": "skills/$name/rules/coding-standards.md",
      "mode": "verbatim",
      "activation_chain": [
        "skills/$name/SKILL.md",
        "skills/$name/routing.yaml",
        "skills/$name/workflows/change-managed.md",
        "skills/$name/rules/change-discipline.md",
        "skills/$name/rules/coding-standards.md"
      ]
    },
    {
      "inventory_id": "claude-reproduce-failing-case",
      "destination": "skills/$name/rules/project-rules.md",
      "mode": "verbatim",
      "activation_chain": [
        "skills/$name/SKILL.md",
        "skills/$name/routing.yaml",
        "skills/$name/workflows/fix-bug.md",
        "skills/$name/rules/change-discipline.md",
        "skills/$name/rules/project-rules.md"
      ]
    },
    {
      "inventory_id": "claude-preserve-public-behavior",
      "destination": "skills/$name/rules/project-rules.md",
      "mode": "verbatim",
      "activation_chain": [
        "skills/$name/SKILL.md",
        "skills/$name/routing.yaml",
        "skills/$name/workflows/change-managed.md",
        "skills/$name/rules/change-discipline.md",
        "skills/$name/rules/project-rules.md"
      ]
    }
  ],
  "exclusions": []
}
JSON
  bash "$ROOT/scripts/check-migration-evidence.sh" --root "$tmp" --manifest "$evidence"
  # The migrated rules and preserved shell replacements above are the Agent's
  # semantic merge. Regenerate their derived routing blocks before strict
  # check mode, matching the same lifecycle as the declared-Full journey.
  (
    cd "$tmp"
    bash "skills/$name/scripts/sync-routing.sh" "$name" >/dev/null
  )
  assert_full_scaffold_surfaces "$tmp" "$name"
  validate_downstream_scaffold "$tmp" "$name"
)

check_two_root_integrity() {
  local tmp skill_root code_root routing
  tmp="$(mktemp -d)"
  skill_root="$tmp/skill"
  code_root="$tmp/code"
  routing="$skill_root/routing.yaml"
  mkdir -p "$skill_root/rules" "$skill_root/workflows" "$skill_root/gotchas" "$code_root/gotchas"

  printf '# Base\n' > "$skill_root/rules/base.md"
  printf '# Run\n' > "$skill_root/workflows/run.md"
  printf '# Code shared\n' > "$code_root/gotchas/shared.md"
  printf '# Skill collision\n' > "$skill_root/gotchas/shared.md"
  cat > "$routing" <<'YAML'
path_resolution:
  skill_root: {owns: [rules/**, workflows/**, gotchas/**]}
  code_root: {owns: [gotchas/**]}
always_read:
  - skill:rules/base.md
  - code:gotchas/shared.md
tasks:
  - id: fixture
    workflow: skill:workflows/run.md
YAML

  if (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh" --namespace skill --routing "$routing") >/dev/null 2>&1; then
    echo "two-root audit failed to isolate a same-path skill:/code: collision" >&2
    rm -rf "$tmp"
    return 1
  fi
  if (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh" --namespace skill --routing "$routing") >/dev/null 2>&1; then
    echo "two-root route check failed to isolate a same-path skill:/code: collision" >&2
    rm -rf "$tmp"
    return 1
  fi

  rm "$skill_root/gotchas/shared.md"
  (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh" --namespace skill --routing "$routing")
  (cd "$skill_root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh" --namespace skill --routing "$routing")
  (cd "$code_root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh" --namespace code --routing "$routing")
  (cd "$code_root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh" --namespace code --routing "$routing")
  rm -rf "$tmp"
}

check_conformance_option_like_phrases() {
  local tmp script
  tmp="$(mktemp -d)"
  script="$ROOT/templates/skill/scripts/check-version-conformance.sh"
  printf '%s\n' '# Fixture' '--present' > "$tmp/fixture.md"

  cat > "$tmp/pass.yaml" <<'YAML'
required_sections:
  - file: fixture.md
    must_contain:
      - "--present"
YAML
  bash "$script" "$tmp" --conformance "$tmp/pass.yaml" >/dev/null

  cat > "$tmp/fail.yaml" <<'YAML'
required_sections:
  - file: fixture.md
    must_not_contain:
      - "--present"
YAML
  if bash "$script" "$tmp" --conformance "$tmp/fail.yaml" >/dev/null 2>&1; then
    echo "conformance must_not_contain accepted an option-like phrase that exists" >&2
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"
}

check_vendor_sync_guards() (
  set -euo pipefail
  local tmp up skill outside script manifest sha output status
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  up="$tmp/upstream"; skill="$tmp/skill"; outside="$tmp/outside"
  script="$ROOT/templates/skill/scripts/sync-vendor.sh"
  manifest="$up/templates/skill/sync-manifest.yaml"

  mkdir -p "$up/templates/skill/scripts" "$up/templates/skill/rules" "$skill" "$outside"
  printf '# fixture\n' > "$up/templates/skill/scripts/payload.sh"
  printf '# project-owned\n' > "$up/templates/skill/rules/project.md"
  printf '# fixture skill\n' > "$skill/SKILL.md"
  printf 'vendor:\n  - scripts/payload.sh\nproject_owned:\n  - rules/project.md\n' > "$manifest"
  git -C "$up" init -q
  git -C "$up" config user.email fixture@example.invalid
  git -C "$up" config user.name Fixture
  git -C "$up" add .
  git -C "$up" commit -qm fixture
  sha="$(git -C "$up" rev-parse HEAD)"
  printf 'upstream: fixture\nsynced_sha: %s\nsynced_date: 2026-07-22\n' "$sha" > "$skill/.upstream-sync"

  bash "$script" "$skill" --upstream "$up" --apply >/dev/null
  [[ -f "$skill/scripts/payload.sh" ]] || { echo "vendor block entry was not copied" >&2; return 1; }
  [[ ! -e "$skill/rules/project.md" ]] || { echo "parser consumed a non-vendor owner block" >&2; return 1; }

  expect_vendor_reject() {
    local label="$1"
    if output="$(bash "$script" "$skill" --upstream "$up" --apply 2>&1)"; then
      echo "vendor guard accepted $label" >&2
      return 1
    else
      status=$?
    fi
    [[ $status -eq 2 && "$output" == *"FAIL:"* ]] || {
      echo "vendor guard returned unexpected result for $label: status=$status" >&2
      printf '%s\n' "$output" >&2
      return 1
    }
  }

  printf 'vendor:\n  - rules/project.md\n' > "$manifest"
  expect_vendor_reject "project-owned path"
  [[ ! -e "$skill/rules/project.md" ]] || { echo "project-owned path was written" >&2; return 1; }

  printf 'vendor:\n  - /tmp/vendor-sync-absolute-escape\n' > "$manifest"
  expect_vendor_reject "absolute path"

  printf 'vendor:\n  - scripts/../escape.sh\n' > "$manifest"
  expect_vendor_reject "traversal path"
  [[ ! -e "$skill/escape.sh" ]] || { echo "traversal path escaped the owner directory" >&2; return 1; }

  rm -rf "$skill/scripts"
  ln -s "$outside" "$skill/scripts"
  printf 'vendor:\n  - scripts/payload.sh\n' > "$manifest"
  expect_vendor_reject "symlink target"
  [[ ! -e "$outside/payload.sh" ]] || { echo "symlink target escaped the skill root" >&2; return 1; }
)

check_vendor_selection_and_io_contract() (
  set +e
  set -uo pipefail
  local script="$ROOT/templates/skill/scripts/sync-vendor.sh"
script="$(cd "$(dirname "$script")" && pwd)/$(basename "$script")"
tmp="$(mktemp -d)"; trap "$(printf 'rm -rf -- %q' "$tmp")" EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0
up="$tmp/up"; skill="$tmp/skill"; pass=0; fail=0
ok() { echo "PASS $1"; pass=$((pass+1)); }
no() { echo "FAIL $1"; printf '%s\n' "$output"; fail=$((fail+1)); }
run() { output="$(bash "$script" "$skill" --upstream "$up" --apply 2>&1)"; status=$?; }
reset_skill() {
  rm -rf "$skill"; mkdir -p "$skill/scripts"
  printf '# fixture\n' > "$skill/SKILL.md"
  printf 'synced_sha: %s\n' "$sha" > "$skill/.upstream-sync"
  printf 'vendor:\n  - sync-manifest.yaml\n  - scripts/payload.sh\n' > "$skill/sync-manifest.yaml"
  printf '# base\n' > "$skill/scripts/payload.sh"
}
mkdir -p "$up/templates/skill/scripts" "$up/templates/skill/protocol-blocks"
printf '# base\n' > "$up/templates/skill/scripts/payload.sh"
printf '# extra\n' > "$up/templates/skill/scripts/extra.sh"
printf '# extra\n' > "$up/templates/skill/protocol-blocks/extra.md"
printf 'vendor:\n  - sync-manifest.yaml\n  - scripts/payload.sh\n  - scripts/extra.sh\n  - protocol-blocks/extra.md\n' > "$up/templates/skill/sync-manifest.yaml"
git -C "$up" init -q && git -C "$up" config user.name Fixture && git -C "$up" config user.email fixture@example.invalid && git -C "$up" add . && git -C "$up" commit -qm base || exit 2
sha="$(git -C "$up" rev-parse HEAD)"; reset_skill
cp "$skill/sync-manifest.yaml" "$tmp/selection"
run
if [[ $status -eq 0 && ! -e "$skill/scripts/extra.sh" && ! -e "$skill/protocol-blocks" && "$output" != *LOCAL-EDIT* ]] && cmp -s "$skill/sync-manifest.yaml" "$tmp/selection"; then ok fitted-selection; else no fitted-selection; fi
reset_skill
printf '# update\n' > "$up/templates/skill/scripts/payload.sh"
run
if [[ $status -eq 0 ]] && cmp -s "$skill/scripts/payload.sh" "$up/templates/skill/scripts/payload.sh"; then ok unmodified-update; else no unmodified-update; fi
printf '# local\n' > "$skill/scripts/payload.sh"
run
if [[ $status -eq 1 && "$output" == *'LOCAL-EDIT scripts/payload.sh'* && "$(cat "$skill/scripts/payload.sh")" == '# local' ]]; then ok local-edit; else no local-edit; fi
reset_skill
cp "$up/templates/skill/sync-manifest.yaml" "$tmp/catalog"
printf 'vendor:\n  - sync-manifest.yaml\n  - scripts/extra.sh\n' > "$up/templates/skill/sync-manifest.yaml"
run
if [[ $status -eq 1 && "$output" == *'DROPPED    scripts/payload.sh'* ]]; then ok removed-catalog; else no removed-catalog; fi
cp "$tmp/catalog" "$up/templates/skill/sync-manifest.yaml"
reset_skill
printf '  - scripts/later.sh\n' >> "$skill/sync-manifest.yaml"
printf '  - scripts/later.sh\n' >> "$up/templates/skill/sync-manifest.yaml"
printf '# later\n' > "$up/templates/skill/scripts/later.sh"
mkdir "$skill/scripts/later.sh"
run
if [[ $status -eq 2 && "$(cat "$skill/scripts/payload.sh")" == '# base' && "$output" == *FAIL:* ]]; then ok preflight-collision; else no preflight-collision; fi
reset_skill
mkdir -p "$tmp/outside"; rm -rf "$skill/scripts"; ln -s "$tmp/outside" "$skill/scripts"
run
if [[ $status -eq 2 && ! -e "$tmp/outside/payload.sh" ]]; then ok target-symlink; else no target-symlink; fi
reset_skill
mv "$up/templates/skill/scripts/payload.sh" "$tmp/payload"; ln -s "$tmp/payload" "$up/templates/skill/scripts/payload.sh"
run
if [[ $status -eq 2 && "$(cat "$skill/scripts/payload.sh")" == '# base' ]]; then ok source-symlink; else no source-symlink; fi
rm "$up/templates/skill/scripts/payload.sh"; mv "$tmp/payload" "$up/templates/skill/scripts/payload.sh"
reset_skill
printf '  - scripts/../escape\n' >> "$skill/sync-manifest.yaml"
run
if [[ $status -eq 2 && ! -e "$skill/escape" && "$(cat "$skill/scripts/payload.sh")" == '# base' ]]; then ok unsafe-selection; else no unsafe-selection; fi
reset_skill
mkdir "$tmp/bin"
cat > "$tmp/bin/cp" <<'MOCK'
#!/usr/bin/env bash
echo 'fixture: write denied' >&2
exit 1
MOCK
chmod +x "$tmp/bin/cp"
output="$(PATH="$tmp/bin:$PATH" bash "$script" "$skill" --upstream "$up" --apply 2>&1)"; status=$?
if [[ $status -eq 2 && "$output" == *FAIL:* && "$output" != *'vendor sync (applied)'* && "$(cat "$skill/scripts/payload.sh")" == '# base' ]]; then ok failed-write; else no failed-write; fi
cat > "$tmp/bin/cp" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
output="$(PATH="$tmp/bin:$PATH" bash "$script" "$skill" --upstream "$up" --apply 2>&1)"; status=$?
if [[ $status -eq 2 && "$output" == *FAIL:* && "$output" != *'vendor sync (applied)'* ]]; then ok failed-readback; else no failed-readback; fi
rm "$tmp/bin/cp"
cat > "$tmp/bin/mkdir" <<'MOCK'
#!/usr/bin/env bash
echo 'fixture: mkdir denied' >&2
exit 1
MOCK
chmod +x "$tmp/bin/mkdir"
rm "$skill/scripts/payload.sh"
output="$(PATH="$tmp/bin:$PATH" bash "$script" "$skill" --upstream "$up" --apply 2>&1)"; status=$?
if [[ $status -eq 2 && "$output" == *FAIL:* && "$output" != *'vendor sync (applied)'* ]]; then ok failed-mkdir; else no failed-mkdir; fi
rm "$tmp/bin/mkdir"
reset_skill
rm "$skill/sync-manifest.yaml" "$skill/scripts/payload.sh"
run
if [[ $status -eq 0 && -f "$skill/scripts/extra.sh" && -f "$skill/protocol-blocks/extra.md" && -f "$skill/sync-manifest.yaml" ]]; then ok legacy-bootstrap; else no legacy-bootstrap; fi
reset_skill
git -C "$up" worktree add --detach -q "$tmp/worktree" HEAD || exit 2
up="$tmp/worktree"; run
if [[ $status -eq 0 && "$output" != *LOCAL-EDIT* ]]; then ok linked-worktree; else no linked-worktree; fi
printf 'vendor regression: %s passed, %s failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]

)

check_fitted_upgrade_lifecycle() (
  set -euo pipefail
  local tmp up project skill manifest candidate checker output
  tmp="$(mktemp -d)"
  trap "$(printf 'rm -rf -- %q' "$tmp")" EXIT
  export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0
  up="$tmp/upstream"; project="$tmp/project"; skill="$project/skills/fixture"
  candidate="$tmp/current-fitted.yaml"
  checker="$ROOT/templates/skill/scripts/check-version-conformance.sh"
  mkdir -p "$up/scripts" "$project"
  cp -R "$ROOT/templates" "$up/templates"
  cp "$ROOT/scripts/scaffold-downstream.sh" "$ROOT/scripts/render-fitted-conformance.sh" "$up/scripts/"
  git -C "$up" init -q
  git -C "$up" config user.name Fixture
  git -C "$up" config user.email fixture@example.invalid
  git -C "$up" add .
  git -C "$up" commit -qm baseline
  cat > "$tmp/evidence.json" <<'JSON'
{"version":1,"tasks":[{"id":"fix-bug","trigger_examples":["fix a fixture bug"]},{"id":"change-managed","trigger_examples":["change fixture behavior"]},{"id":"update-upstream","trigger_examples":["refresh fixture rules"]}],"maintenance_pressure":{"upstream":true,"validation":true}}
JSON
  bash "$up/scripts/scaffold-downstream.sh" --target "$project" --name fixture \
    --summary 'Upgrade lifecycle fixture' --evidence "$tmp/evidence.json" --apply >/dev/null
  manifest="$skill/conformance.yaml"
  cmp "$skill/workflows/update-upstream.md" "$up/templates/skill/workflows/update-upstream.md"
  bash "$checker" "$skill" >/dev/null
  bash "$up/scripts/render-fitted-conformance.sh" "$manifest" > "$candidate"
  cmp "$manifest" "$candidate"
  bash "$checker" "$skill" --conformance "$candidate" >/dev/null
  # The complete scaffold is deliberately not this project's adopted contract.
  if bash "$checker" "$skill" --conformance "$up/templates/skill/conformance.yaml" >"$tmp/full.log" 2>&1; then
    echo "lifecycle fixture unexpectedly adopted the complete scaffold" >&2; return 1
  fi
  git -C "$project" init -q
  git -C "$project" config user.name Fixture
  git -C "$project" config user.email fixture@example.invalid
  git -C "$project" add .
  git -C "$project" commit -qm generated
  output="$(bash "$up/templates/skill/scripts/sync-vendor.sh" "$skill" --upstream "$up" --apply)"
  [[ -z "$(git -C "$project" status --porcelain)" && "$output" != *LOCAL-EDIT* ]] || {
    echo "same-version fitted upgrade changed the generated result" >&2; printf '%s\n' "$output" >&2; return 1;
  }
  cp "$skill/sync-manifest.yaml" "$tmp/selection.before"
  printf '\n# Preserve project-owned knowledge\n' >> "$skill/rules/project-rules.md"
  cp "$skill/rules/project-rules.md" "$tmp/project-rules.before"
  printf '\n# Upstream fixture update\n' >> "$up/templates/skill/scripts/route-health.sh"
  printf '# Not selected\n' > "$up/templates/skill/scripts/not-selected.sh"
  printf '  - scripts/not-selected.sh\n' >> "$up/templates/skill/sync-manifest.yaml"
  # Change the actual upstream check owner; a stale local contract must not
  # make this new applicable requirement disappear during refresh.
  python3 - "$up/scripts/render-fitted-conformance.sh" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = 'section("SKILL.md", must_contain=["## Common Tasks", "routing.yaml"])'
assert old in s
p.write_text(s.replace(old, 'section("SKILL.md", must_contain=["## Common Tasks", "routing.yaml", "fixture-upstream-requirement"])'))
PY
  git -C "$up" add .
  git -C "$up" commit -qm upgrade
  bash "$up/templates/skill/scripts/sync-vendor.sh" "$skill" --upstream "$up" --apply >/dev/null
  cmp "$skill/scripts/route-health.sh" "$up/templates/skill/scripts/route-health.sh"
  cmp "$skill/sync-manifest.yaml" "$tmp/selection.before"
  cmp "$skill/rules/project-rules.md" "$tmp/project-rules.before"
  [[ ! -e "$skill/scripts/not-selected.sh" && ! -d "$skill/protocol-blocks" ]]
  bash "$up/scripts/render-fitted-conformance.sh" "$manifest" > "$candidate"
  bash "$checker" "$skill" --conformance "$manifest" >/dev/null
  if bash "$checker" "$skill" --conformance "$candidate" >"$tmp/new-check.log" 2>&1; then
    echo "fresh fitted check failed to require the upstream update" >&2; return 1
  fi
  grep -qF 'fixture-upstream-requirement' "$tmp/new-check.log"
  printf '\nfixture-upstream-requirement\n' >> "$skill/SKILL.md"
  bash "$checker" "$skill" --conformance "$candidate" >/dev/null
  # Regeneration cannot silently drop a deleted declared owner.
  rm "$skill/workflows/change-managed.md"
  bash "$up/scripts/render-fitted-conformance.sh" "$manifest" > "$candidate"
  if bash "$checker" "$skill" --conformance "$candidate" >"$tmp/missing.log" 2>&1; then
    echo "refresh hid a missing declared workflow" >&2; return 1
  fi
  grep -qF 'workflows/change-managed.md' "$tmp/missing.log"
  # A project-specific assertion must not accidentally adopt external-write policy.
  cp "$manifest" "$tmp/custom.yaml"
  printf '\n  - file: rules/project-rules.md\n    must_contain:\n      - "Keep project knowledge"\n' >> "$tmp/custom.yaml"
  bash "$up/scripts/render-fitted-conformance.sh" "$tmp/custom.yaml" > "$tmp/custom-current.yaml"
  if grep -qF 'Task scope does not automatically grant external write authority' "$tmp/custom-current.yaml"; then
    echo "custom project-rule assertion expanded the adopted responsibilities" >&2; return 1
  fi
  # Unsafe/custom declaration shapes are rejected rather than silently fitted.
  cp "$manifest" "$tmp/unsafe.yaml"
  printf '\nrequired_files:\n  - path: ../escape\n' >> "$tmp/unsafe.yaml"
  if bash "$up/scripts/render-fitted-conformance.sh" "$tmp/unsafe.yaml" >"$tmp/unsafe.out" 2>/dev/null; then
    echo "renderer accepted ambiguous declared owners" >&2; return 1
  fi
  [[ ! -s "$tmp/unsafe.out" ]]
  echo "OK: fitted generation, same-version sync, selective upgrade, and current checks"
)

check_upstream_status_contract() (
  set +e
  set -uo pipefail
  local script="$ROOT/templates/skill/scripts/upstream-status.sh"
script="$(cd "$(dirname "$script")" && pwd)/$(basename "$script")"
tmp="$(mktemp -d)"
trap "$(printf 'rm -rf -- %q' "$tmp")" EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0
passed=0; failed=0
ok() { printf 'PASS %s\n' "$1"; passed=$((passed+1)); }
fail() { printf 'FAIL %s\n%s\n' "$1" "${output:-}"; failed=$((failed+1)); }
init_repo() {
  git init -q "$1" && git -C "$1" checkout -qb main &&
  git -C "$1" config user.name 'SBA fixture' && git -C "$1" config user.email fixture@example.invalid
}
commit() { git -C "$1" add . && git -C "$1" commit -qm "$2"; }
point() { printf 'upstream: fixture\nsynced_sha: %s\n' "$1" > "$tmp/skill/.upstream-sync"; }
run_status() {
  output="$(cd "$tmp/skill" && bash "$script" "$tmp/skill" --upstream "$1" 2>&1)"; result=$?
}
mkdir -p "$tmp/skill"
printf '# Fixture\n' > "$tmp/skill/SKILL.md"
init_repo "$tmp/source" || exit 1
printf '# Updates\n\n## 2026-01-01 - baseline\n- Guidance: baseline\n' > "$tmp/source/UPSTREAM-CHANGES.md"
commit "$tmp/source" base || exit 1
base="$(git -C "$tmp/source" rev-parse HEAD)"
point "$base"
printf '\n## 2026-01-02 - added then archived\n- Guidance: apply new mechanism\n' >> "$tmp/source/UPSTREAM-CHANGES.md"
commit "$tmp/source" added || exit 1
printf '# Archive\n\n## 2026-01-02 - added then archived\n- Guidance: apply new mechanism\n' > "$tmp/source/UPSTREAM-CHANGES-archive.md"
printf '# Updates\n\n## 2026-01-01 - baseline\n- Guidance: baseline\n' > "$tmp/source/UPSTREAM-CHANGES.md"
commit "$tmp/source" archived || exit 1
run_status "$tmp/source"
if [[ "$result" == 1 && "$output" == *'2026-01-02 - added then archived'* && "$output" == *'UPSTREAM-CHANGES-archive.md'* ]]; then ok 'new note remains visible after archival'; else fail 'new note remains visible after archival'; fi
archive_sha="$(git -C "$tmp/source" rev-parse HEAD)"
point "$archive_sha"
printf '\n## 2026-01-01 - baseline\n- Guidance: baseline\n' >> "$tmp/source/UPSTREAM-CHANGES-archive.md"
printf '# Updates\n' > "$tmp/source/UPSTREAM-CHANGES.md"
commit "$tmp/source" move-baseline || exit 1
run_status "$tmp/source"
if [[ "$result" == 0 && "$output" == *'No new UPSTREAM-CHANGES entries'* ]]; then ok 'moving existing headings is not a new note'; else fail 'moving existing headings is not a new note'; fi
point "$(git -C "$tmp/source" rev-parse HEAD)"
run_status "$tmp/source"
if [[ "$result" == 0 && "$output" == *'local snapshot'* ]]; then ok 'no-remote checkout is explicitly a local snapshot'; else fail 'no-remote checkout is explicitly a local snapshot'; fi
git clone -q --bare "$tmp/source" "$tmp/origin.git" || exit 1
git clone -q "$tmp/origin.git" "$tmp/stale" || exit 1
stale_sha="$(git -C "$tmp/stale" rev-parse HEAD)"
point "$stale_sha"
printf '# Updates\n\n## 2026-01-03 - remote advancement\n- Guidance: new target\n' > "$tmp/source/UPSTREAM-CHANGES.md"
commit "$tmp/source" remote-update || exit 1
git -C "$tmp/source" push -q "$tmp/origin.git" main || exit 1
latest="$(git -C "$tmp/source" rev-parse HEAD)"
run_status "$tmp/stale"
if [[ "$result" == 1 && "$output" == *'2026-01-03 - remote advancement'* && "$output" == *"$latest"* && "$(git -C "$tmp/stale" rev-parse HEAD)" == "$stale_sha" ]]; then ok 'fetch compares tracked target while preserving stale checkout'; else fail 'fetch compares tracked target while preserving stale checkout'; fi
point "$latest"
run_status "$tmp/stale"
if [[ "$result" == 0 && "$output" == *"$latest"* && "$output" == *'refs/remotes/origin/main'* ]]; then ok 'current status identifies fetched comparison revision'; else fail 'current status identifies fetched comparison revision'; fi
run_status "file://$tmp/origin.git"
if [[ "$result" == 0 && "$output" == *"$latest"* && "$output" == *'refs/remotes/origin/main'* ]]; then ok 'temporary clone resolves its fetched tracking revision'; else fail 'temporary clone resolves its fetched tracking revision'; fi
point '<set on first refresh>'
run_status "$tmp/source"
if [[ "$result" == 1 && "$output" == *'2026-01-03 - remote advancement'* && "$output" == *'2026-01-02 - added then archived'* ]]; then ok 'first refresh lists active and archived notes'; else fail 'first refresh lists active and archived notes'; fi
point 0000000000000000000000000000000000000001
run_status "$tmp/source"
if [[ "$result" == 1 && "$output" == *'not found upstream'* && "$output" == *'2026-01-02 - added then archived'* ]]; then ok 'missing baseline reports attention with archive fallback'; else fail 'missing baseline reports attention with archive fallback'; fi
point "$latest"
git -C "$tmp/stale" remote set-url origin "$tmp/missing-origin.git"
run_status "$tmp/stale"
if [[ "$result" == 2 && "$output" != *'Up to date'* && "$output" != *'No new UPSTREAM-CHANGES entries'* ]]; then ok 'fetch failure cannot claim current'; else fail 'fetch failure cannot claim current'; fi
git -C "$tmp/stale" remote set-url origin "$tmp/origin.git"
git -C "$tmp/stale" checkout -q --detach
run_status "$tmp/stale"
if [[ "$result" == 2 ]]; then ok 'detached remote checkout cannot choose latest'; else fail 'detached remote checkout cannot choose latest'; fi
git -C "$tmp/stale" checkout -q main
git -C "$tmp/stale" branch --unset-upstream
run_status "$tmp/stale"
if [[ "$result" == 2 ]]; then ok 'untracked remote checkout cannot choose latest'; else fail 'untracked remote checkout cannot choose latest'; fi
git -C "$tmp/stale" branch --set-upstream-to=origin/main main >/dev/null
git -C "$tmp/stale" worktree add -q -b worktree-check "$tmp/worktree" main || exit 1
git -C "$tmp/worktree" branch --set-upstream-to=origin/main worktree-check >/dev/null
point "$stale_sha"
run_status "$tmp/worktree"
if [[ "$result" == 1 && "$output" == *"$latest"* && "$output" == *'2026-01-03 - remote advancement'* ]]; then ok 'worktree git file uses configured tracked target'; else fail 'worktree git file uses configured tracked target'; fi
# Bound the historical failed-shift loop in the process running the script.
output="$(cd "$tmp/skill" && perl -e 'alarm shift; exec @ARGV' 3 bash "$script" "$tmp/skill" --upstream 2>&1)"; result=$?
if [[ "$result" == 2 ]]; then ok 'missing upstream option value exits 2'; else fail 'missing upstream option value exits 2'; fi
printf 'Result: %s passed; %s failed\n' "$passed" "$failed"
[[ "$failed" == 0 ]]

)

check_live_agent_harness_contract() (
  set -euo pipefail
  local tmp script stub output status run_dir
  tmp="$(mktemp -d)"
  trap "$(printf 'rm -rf -- %q' "$tmp")" EXIT
  script="$ROOT/scripts/check-live-agent-journey.sh"
  stub="$tmp/codex-stub"
  mkdir -p "$tmp/unrelated"
  printf '9.9.9\n' > "$tmp/unrelated/VERSION"
  cat > "$stub" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
project=""
[[ "${1:-}" == exec ]] || exit 2
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cd)
      [[ $# -ge 2 ]] || exit 2
      project="$2"
      shift 2
      ;;
    *) shift ;;
  esac
done
[[ -n "$project" && -f "$project/VERSION" ]] || exit 2
case "${SBA_LIVE_STUB_CASE:-correct}" in
  correct) printf '1.2.4\n' > "$project/VERSION" ;;
  wrong-version) printf '1.2.5\n' > "$project/VERSION" ;;
  changed-instructions)
    printf '1.2.4\n' > "$project/VERSION"
    printf '\nUnexpected instruction change\n' >> "$project/AGENTS.md"
    ;;
  *) exit 2 ;;
esac
STUB
  chmod +x "$stub"

  for run_dir in "$tmp/unrelated" "$ROOT"; do
    if ! output="$(cd "$run_dir" && SBA_CODEX_BIN="$stub" SBA_LIVE_STUB_CASE=correct bash "$script" --mode single-file 2>&1)"; then
      printf 'live harness rejected the correct fixture VERSION from %s:\n%s\n' "$run_dir" "$output" >&2
      return 1
    fi
    [[ "$output" == *'PASS: fresh-project natural-language journey updated VERSION'* ]] || {
      echo "live harness did not report the expected successful terminal check" >&2
      return 1
    }
  done

  if output="$(cd "$tmp/unrelated" && SBA_CODEX_BIN="$stub" SBA_LIVE_STUB_CASE=wrong-version bash "$script" --mode single-file 2>&1)"; then
    echo "live harness accepted an incorrect fixture VERSION" >&2
    return 1
  else
    status=$?
  fi
  [[ "$status" -eq 1 && "$output" == *'expected VERSION=1.2.4, got 1.2.5'* ]] || {
    printf 'live harness rejected an incorrect VERSION for the wrong reason (status=%s):\n%s\n' "$status" "$output" >&2
    return 1
  }

  if output="$(cd "$tmp/unrelated" && SBA_CODEX_BIN="$stub" SBA_LIVE_STUB_CASE=changed-instructions bash "$script" --mode single-file 2>&1)"; then
    echo "live harness accepted an unrelated instruction change" >&2
    return 1
  else
    status=$?
  fi
  [[ "$status" -eq 1 && "$output" == *'Live Agent changed AGENTS.md outside the requested task'* ]] || {
    printf 'live harness rejected an unrelated instruction change for the wrong reason (status=%s):\n%s\n' "$status" "$output" >&2
    return 1
  }
)


check_overlay_owner_contract() (
  set -euo pipefail
  local tmp root skill script output
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  root="$tmp/workspace"
  skill="$root/skills/sample"
  script="$ROOT/templates/skill/scripts/sync-routing.sh"
  mkdir -p "$skill/rules" "$skill/workflows" "$skill/references/business" \
    "$root/services/billing/skills/billing/references/business"
  printf '# Base\n' > "$skill/rules/base.md"
  printf '# Run\n' > "$skill/workflows/run.md"
  printf '# Local billing consumer\n' > "$skill/references/business/billing-consumer.md"
  printf '# Billing owner\n' > "$root/services/billing/skills/billing/references/business/billing.md"
  cat > "$skill/SKILL.md" <<'MARKDOWN'
---
name: sample
description: sample overlay fixture
---
# Sample
<!-- ALWAYS_READ_START -->
<!-- ALWAYS_READ_END -->
<!-- ROUTING_SUMMARY_START -->
<!-- ROUTING_SUMMARY_END -->
MARKDOWN
  cat > "$skill/routing.yaml" <<'YAML'
always_read:
  - rules/base.md
tasks:
  - id: run
    labels: { en: Run, zh: 执行 }
    workflow: workflows/run.md
    trigger_examples: [执行任务, run task]
  - id: other
    labels: { en: Other, zh: 其他 }
    workflow: workflows/run.md
    trigger_examples: [其他任务]
YAML

  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "domain validation accepted a business owner without domain-routing.yaml" >&2
    return 1
  fi

  printf 'domain_overlays: []\n' > "$skill/domain-routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "domain validation accepted an empty domain-routing.yaml" >&2
    return 1
  fi

  cat > "$skill/domain-routing.yaml" <<'YAML'
owner_roots:
  billing: services/billing
domain_overlays:
  - id: billing
    labels: { en: Billing, zh: 计费 }
    required_reads:
      - references/business/billing-consumer.md
      - owner:billing:skills/billing/references/business/billing.md
    trigger_examples: [账单, billing policy]
YAML

  (cd "$root" && bash "$script" "$skill" --workspace-root "$root") >/dev/null
  grep -qF 'For each new task, read `routing.yaml`, match exactly one route' "$skill/SKILL.md"
  if grep -qF 'Run / 执行 (`run`) -> workflow `workflows/run.md`' "$skill/SKILL.md"; then
    echo "generated SKILL.md duplicated canonical task-route rows" >&2
    return 1
  fi
  if grep -q 'billing-consumer\|domain_overlay_ids\|merged_required_reads' "$skill/SKILL.md"; then
    echo "generated task summary eagerly exposed domain-routing content" >&2
    return 1
  fi
  (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null
  output="$(cd "$root" && bash "$script" "$skill" --check)"
  [[ "$output" == *"cross-owner target verification remains open"* ]] || {
    echo "owner check without workspace root did not report unverified target existence" >&2
    return 1
  }
  output="$(bash "$ROOT/templates/skill/scripts/route-health.sh" "$skill")"
  [[ "$output" == *"1 task routes + 1 domain overlays"* ]] || {
    echo "route-health did not separate task routes from domain overlays" >&2
    return 1
  }

  cp "$skill/domain-routing.yaml" "$tmp/domain-routing.base"
  perl -0pi -e 's#      - references/business/billing-consumer.md\n      - owner:billing:skills/billing/references/business/billing.md#      - task-relevant requirement billing:docs/requirements/billing.md#' "$skill/domain-routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "domain validation accepted a Plan requirement without a business owner" >&2
    return 1
  fi
  cp "$tmp/domain-routing.base" "$skill/domain-routing.yaml"

  printf '# Unregistered domain\n' > "$skill/references/business/unregistered.md"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "domain validation accepted an unregistered business leaf" >&2
    return 1
  fi
  rm "$skill/references/business/unregistered.md"

  cp "$skill/routing.yaml" "$tmp/routing.base"
  perl -0pi -e 's/(    labels: \{ en: Run[^\n]*\n)/$1    required_reads: []\n/' "$skill/routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "task route validation accepted required_reads" >&2
    return 1
  fi
  cp "$tmp/routing.base" "$skill/routing.yaml"

  perl -0pi -e 's/(    labels: \{ en: Run[^\n]*\n)/$1    route: inspect everything\n/' "$skill/routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "task route validation accepted executable route instructions" >&2
    return 1
  fi
  cp "$tmp/routing.base" "$skill/routing.yaml"

  printf '# Navigation only\n' > "$skill/references/navigation.md"
  perl -0pi -e 's#workflow: workflows/run.md#workflow: references/navigation.md#' "$skill/routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "task route validation accepted a navigation-only workflow target" >&2
    return 1
  fi
  cp "$tmp/routing.base" "$skill/routing.yaml"
  rm "$skill/references/navigation.md"

  cat >> "$skill/routing.yaml" <<'YAML'
domain_overlays:
  - id: legacy
    labels: { en: Legacy, zh: 旧领域 }
    required_reads: [references/business/billing-consumer.md]
    trigger_examples: [legacy]
YAML
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "task routing accepted legacy inline domain overlays" >&2
    return 1
  fi
  cp "$tmp/routing.base" "$skill/routing.yaml"

  rm "$root/services/billing/skills/billing/references/business/billing.md"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "owner target validation accepted a missing cross-owner file" >&2
    return 1
  fi
  printf '# Billing owner\n' > "$root/services/billing/skills/billing/references/business/billing.md"

  perl -0pi -e 's#billing: services/billing#billing: ../billing#' "$skill/domain-routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "owner root validation accepted parent traversal" >&2
    return 1
  fi
  perl -0pi -e 's#billing: ../billing#billing: services/billing#' "$skill/domain-routing.yaml"

  perl -0pi -e 's#owner:billing:#owner:undeclared:#' "$skill/domain-routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "owner reference validation accepted an undeclared owner" >&2
    return 1
  fi
  perl -0pi -e 's#owner:undeclared:#owner:billing:#' "$skill/domain-routing.yaml"

  perl -0pi -e 's/(    labels: \{ en: Billing[^\n]*\n)/$1    workflow: workflows\/run.md\n/' "$skill/domain-routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "domain overlay validation accepted a workflow override" >&2
    return 1
  fi
)

check_code_root_domain_contract() (
  set -euo pipefail
  local tmp root skill code_root script
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  root="$tmp/workspace"
  skill="$root/skills/sample"
  code_root="$root/code/skills/sample"
  script="$ROOT/templates/skill/scripts/sync-routing.sh"
  mkdir -p "$skill/workflows" "$code_root/references/business/orders"
  printf '# Run\n' > "$skill/workflows/run.md"
  printf '# Business catalog\n' > "$code_root/references/business/index.md"
  printf '# Orders selector\n\nSee [refunds](refunds.md).\n' > "$code_root/references/business/orders/index.md"
  printf '# Refund rules\n' > "$code_root/references/business/orders/refunds.md"
  cat > "$skill/SKILL.md" <<'MARKDOWN'
---
name: sample
description: sample code-root domain fixture
---
# Sample
<!-- ALWAYS_READ_START -->
<!-- ALWAYS_READ_END -->
<!-- ROUTING_SUMMARY_START -->
<!-- ROUTING_SUMMARY_END -->
MARKDOWN
  cat > "$skill/routing.yaml" <<'YAML'
path_resolution:
  skill_root:
    owns: [SKILL.md, routing.yaml, domain-routing.yaml, workflows/**]
  code_root:
    root: code/skills/sample
    owns: [references/**]
always_read: []
tasks:
  - id: run
    labels: { en: Run, zh: 执行 }
    workflow: workflows/run.md
    trigger_examples: [run]
  - id: other
    labels: { en: Other, zh: 其他 }
    workflow: workflows/run.md
    trigger_examples: [other]
YAML

  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "code-root domain validation accepted business content without domain-routing.yaml" >&2
    return 1
  fi

  cat > "$skill/domain-routing.yaml" <<'YAML'
domain_overlays:
  - id: orders
    labels: { en: Orders, zh: 订单 }
    required_reads: [code:references/business/orders/index.md]
    trigger_examples: [refund, 退款]
YAML
  (cd "$root" && bash "$script" "$skill" --workspace-root "$root") >/dev/null
  (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null
  output="$(cd "$root" && bash "$script" "$skill" --check)"
  [[ "$output" == *"code-root target verification remains open"* ]] || {
    echo "code-root check without workspace root did not report open target verification" >&2
    return 1
  }

  cp "$skill/domain-routing.yaml" "$tmp/code-domain-routing.base"
  perl -0pi -e 's#required_reads: \[code:references/business/orders/index.md\]#required_reads: [code:references/business/orders/index.md, code:references/business/missing.md]#' "$skill/domain-routing.yaml"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "code-root target validation accepted a missing code owner" >&2
    return 1
  fi
  cp "$tmp/code-domain-routing.base" "$skill/domain-routing.yaml"

  mv "$code_root/references/business/orders/index.md" "$tmp/orders-index.md"
  if (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null 2>&1; then
    echo "code-root domain validation accepted nested leaves without a selecting index" >&2
    return 1
  fi
  mv "$tmp/orders-index.md" "$code_root/references/business/orders/index.md"
  (cd "$root" && bash "$script" "$skill" --check --workspace-root "$root") >/dev/null
)

check_recursive_knowledge_integrity() (
  set -euo pipefail
  local tmp root routing domain_routing
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  root="$tmp/skill"
  routing="$root/routing.yaml"
  domain_routing="$root/domain-routing.yaml"
  mkdir -p "$root/rules" "$root/workflows" "$root/references/business/deep"
  printf '# Base\n' > "$root/rules/base.md"
  printf '# Run\n' > "$root/workflows/run.md"
  printf '# Known\n' > "$root/references/business/known.md"
  printf '# Nested orphan\n' > "$root/references/business/deep/orphan.md"
  cat > "$routing" <<'YAML'
always_read:
  - rules/base.md
tasks:
  - id: run
    workflow: workflows/run.md
  - id: other
    workflow: workflows/run.md
YAML
  cat > "$domain_routing" <<'YAML'
domain_overlays:
  - id: known
    labels: { en: Known, zh: 已知 }
    required_reads:
      - references/business/known.md
    trigger_examples: [known]
YAML

  if (cd "$root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh") >/dev/null 2>&1; then
    echo "recursive orphan audit missed a nested business reference" >&2
    return 1
  fi
  if (cd "$root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh") >/dev/null 2>&1; then
    echo "recursive route reachability missed an unactivated nested business reference" >&2
    return 1
  fi

  printf '\nSee references/business/deep/orphan.md.\n' >> "$root/references/business/known.md"
  (cd "$root" && bash "$ROOT/templates/skill/scripts/audit-orphans.sh") >/dev/null
  (cd "$root" && bash "$ROOT/templates/skill/scripts/route-reachability.sh") >/dev/null
)

if [[ "$MODE" == "staged" ]]; then
  run "upstream change-note guard (staged)" bash scripts/check-upstream-changes.sh --base "$BASE" --staged
  run "whitespace diff check (staged)" git diff --cached --check
else
  run "upstream change-note guard" bash scripts/check-upstream-changes.sh --base "$BASE"
  run "whitespace diff check" git diff --check
fi

run "upstream supersedes refs check" bash scripts/check-upstream-supersedes.sh

run "template routing manifest check" bash templates/skill/scripts/sync-routing.sh templates/skill --check
run "template SessionStart hook runtime contract" bash scripts/check-template-hooks.sh
run "responsibility-aware downstream validation contracts" bash scripts/check-validation-contract.sh
run "empty-target Single-file materializer journey" check_single_file_materializer_journey
run "one-procedure Folder-light materializer journey" check_folder_direct_materializer_journey
run "declared Full downstream scaffold structural contract" check_downstream_scaffold
run "existing-project first-migration journey" check_existing_project_scaffold_journey
run "single-root + two-root integrity contracts" check_two_root_integrity
run "conformance option-like phrase contract" check_conformance_option_like_phrases
run "vendor owner + path guards" check_vendor_sync_guards
run "vendor selection and write-failure contract" check_vendor_selection_and_io_contract
run "fitted generation and upstream upgrade lifecycle" check_fitted_upgrade_lifecycle
run "upstream revision and archived-note status" check_upstream_status_contract
run "live harness terminal-check isolation (stub)" check_live_agent_harness_contract
run "task route + domain overlay and cross-owner guards" check_overlay_owner_contract
run "code-root domain materialization + nested-owner guards" check_code_root_domain_contract
run "recursive business-reference integrity" check_recursive_knowledge_integrity
run "self-hosting shells + activation check" bash scripts/check-self-shells.sh
run "self-hosting manifest route proofs" bash scripts/check-self-scenarios.sh
# The self-hosting root intentionally stores unfilled template sources. This
# Phase 7 slice checks only its root shell/bootstrap/link surfaces; the valid
# Single-file and declared Full fixtures above own downstream Skill structure.
run "self-hosting shell/bootstrap/link smoke subset" bash templates/skill/scripts/smoke-test.sh skill-based-architecture --phase 7
run "self-hosting orphan audit" bash templates/skill/scripts/audit-orphans.sh
run "Full template content conformance" bash templates/skill/scripts/check-version-conformance.sh templates/skill
run "self-hosting content conformance" bash templates/skill/scripts/check-version-conformance.sh . --conformance references/self-hosting-conformance.yaml

printf '\nAll deterministic upstream structure and contract checks passed.\n'
if [[ "$RUN_LIVE_AGENT" -eq 1 ]]; then
  run_live_agent_mode "live Codex Single-file user journey" single-file
  run_live_agent_mode "live Codex ordinary SBA migration journey" migration
  if [[ -n "$LIVE_AGENT_NO_VERDICT_MODES" ]]; then
    printf '\nNO VERDICT: live Agent evidence was unavailable for mode(s): %s.\n' "$LIVE_AGENT_NO_VERDICT_MODES" >&2
    printf 'Deterministic checks passed, but this run proves no live behavior for those mode(s).\n' >&2
    exit 3
  fi
  printf '\nBoth requested live Codex journeys passed their named terminal checks.\n'
else
  printf 'Live Agent behavior was not run; this green result does not prove real Agent behavior.\n'
  printf 'Run `bash scripts/check-all.sh --base %q --live-agent` for the opt-in Single-file and migration journeys.\n' "$BASE"
fi
