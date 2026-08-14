#!/usr/bin/env bash
# Upstream regression checks for responsibility-aware downstream validation.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() {
  PASS=$((PASS + 1))
  printf 'PASS: %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  printf 'FAIL: %s\n' "$1" >&2
}

materialize_complete_fixture() {
  local target="$1" name="$2"

  mkdir -p "$target/skills/$name" \
    "$target/.cursor/skills/$name" \
    "$target/.cursor/rules"
  cp -R "$ROOT/templates/skill/." "$target/skills/$name/"
  # Conditional materializer sources are upstream author inputs, not emitted
  # Full downstream owners. Keep only the canonical complete Skill template.
  find "$target/skills/$name" -maxdepth 1 -type f \
    -name 'SKILL.*.md.template' ! -name 'SKILL.md.template' -delete
  mv "$target/skills/$name/SKILL.md.template" "$target/skills/$name/SKILL.md"
  # The same rule applies to conditional workflow/reference template sources
  # nested under the author tree: a complete downstream contains concrete
  # owners, never an unfilled *.md.template/*.yaml.template source.
  find "$target/skills/$name" -type f \( -name '*.md.template' -o -name '*.yaml.template' \) -delete
  cp "$ROOT/templates/shells/.cursor/skills/{{NAME}}/SKILL.md.template" \
    "$target/.cursor/skills/$name/SKILL.md"
  cp "$ROOT/templates/shells/.cursor/rules/workflow.mdc" \
    "$target/.cursor/rules/workflow.mdc"
  for shell in AGENTS.md CLAUDE.md CODEX.md GEMINI.md; do
    cp "$ROOT/templates/shells/$shell" "$target/$shell"
  done
}

replace_complete_fixture_identity() {
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
  )
}

fill_complete_fixture() {
  local target="$1" name="$2"
  (
    cd "$target"
    find "skills/$name" .cursor \
      -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.yaml' \) \
      -exec perl -0pi -e 's/<!-- FILL:.*?-->//sg' {} +
    perl -0pi -e 's/^# FILL:.*?(?=^tasks:)/# This fixture intentionally exercises the complete routed scaffold.\n/ms' \
      "skills/$name/routing.yaml"
    perl -0pi -e 's/- <!-- Boundary 1 -->/- Owns the sample application and its repository-local validation rules./; s/- <!-- Boundary 2 -->/- Does not own deployment credentials or external release approval./' \
      "skills/$name/SKILL.md"
    perl -0pi -e 's#`\./\.maintenance-log\.yaml`#`../.maintenance-log.yaml`#g' \
      "skills/$name/workflows/maintain-docs.md"

    mkdir -p "skills/$name/references/business"
    cat > "skills/$name/domain-routing.yaml" <<'YAML'
domain_overlays:
  - id: order-policy
    labels: { en: Order policy domain, zh: 订单策略领域 }
    required_reads:
      - references/business/order-policy.md
    trigger_examples:
      - order policy rule
      - 订单策略规则
YAML
    cat > "skills/$name/references/business/order-policy.md" <<'MARKDOWN'
# Order Policy

The complete fixture owns one explicit business domain so its optional domain
routing references resolve to a real, activated owner.
MARKDOWN
    cat > "skills/$name/.maintenance-log.yaml" <<'YAML'
files:
  - path: references/gotchas.md
    last_tier2: 2026-08-11
YAML
    cat >> "skills/$name/references/gotchas.md" <<'MARKDOWN'

## X Registration

Register the fixture dependency before the controller uses it.
MARKDOWN

    cat > "skills/$name/rules/project-rules.md" <<'MARKDOWN'
# Project Rules

- Changes to the sample application must preserve its command-line contract.
- Release-affecting work requires the repository validation workflow before delivery.
- External credentials, deployment, and publication remain outside this project Skill.
- Project-rule changes require explicit user intent and the routed update-rules workflow.
- Task scope does not automatically grant external write authority for databases, deployments, configuration, or shared systems; obtain explicit authorization before performing such writes.
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

declared_complete_surfaces() {
  local name="$1"
  printf '%s\n' \
    "skills/$name/SKILL.md" \
    "skills/$name/routing.yaml" \
    "skills/$name/domain-routing.yaml" \
    "skills/$name/.maintenance-log.yaml" \
    "skills/$name/conformance.yaml" \
    "skills/$name/references/business/order-policy.md" \
    "skills/$name/workflows/task-execution.md" \
    "skills/$name/workflows/task-closure.md" \
    "skills/$name/workflows/update-upstream.md" \
    "skills/$name/protocol-blocks/external-delivery-verification.md" \
    "skills/$name/scripts/smoke-test.sh" \
    "skills/$name/scripts/sync-routing.sh" \
    "skills/$name/scripts/check-version-conformance.sh" \
    "skills/$name/scripts/audit-orphans.sh" \
    "skills/$name/scripts/route-reachability.sh" \
    "skills/$name/scripts/route-health.sh" \
    "skills/$name/scripts/sync-vendor.sh" \
    "skills/$name/scripts/upstream-status.sh" \
    "skills/$name/sync-manifest.yaml" \
    ".cursor/skills/$name/SKILL.md" \
    ".cursor/rules/workflow.mdc" \
    "AGENTS.md" \
    "CLAUDE.md" \
    "CODEX.md" \
    "GEMINI.md"
}

write_declared_complete_manifest() {
  local target="$1" name="$2" manifest="$3" path prefix
  prefix="skills/$name/"
  printf 'required_files:\n' > "$manifest"
  while IFS= read -r path; do
    # Conformance owns the Skill root; root-level harness/registration entries
    # are checked separately by assert_declared_complete_surfaces.
    [[ "$path" == "$prefix"* ]] || continue
    printf '  - path: %s\n' "${path#"$prefix"}" >> "$manifest"
  done < <(declared_complete_surfaces "$name")
}

assert_declared_complete_surfaces() {
  local target="$1" name="$2" path
  while IFS= read -r path; do
    [[ -e "$target/$path" ]] || {
      printf 'declared complete fixture surface is missing: %s\n' "$path" >&2
      return 1
    }
  done < <(declared_complete_surfaces "$name")
}

# Evidence input: one SKILL.md with one direct Common Tasks procedure and no
# independently owned routing, workflow, maintenance, or harness surfaces.
# Expected: smoke-test accepts the result and does not infer Full obligations.
check_single_file_skill() (
  set -euo pipefail
  local tmp skill output
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/release-helper"
  output="$tmp/smoke.out"
  mkdir -p "$skill"

  cat > "$skill/SKILL.md" <<'MARKDOWN'
---
name: release-helper
description: >
  This skill should be used when the user asks to "update the project version",
  "prepare a release", or "更新版本号". Activate for release metadata changes
  in this small repository where one direct workflow covers every admitted task.
---

# Release Helper

Keep release metadata consistent without introducing additional project machinery.

## Always Read

1. Read `VERSION` before changing release metadata.

## Common Tasks

- Version update: edit `VERSION`, then run `bash scripts/check-version.sh`.
- Other release request: inspect `VERSION`, make the smallest relevant change, and run the same check.
MARKDOWN

  [[ ! -e "$skill/routing.yaml" ]]
  [[ ! -e "$skill/workflows" ]]
  [[ ! -e "$skill/scripts" ]]
  if ! (
    cd "$tmp"
    bash "$ROOT/templates/skill/scripts/smoke-test.sh" release-helper
  ) >"$output" 2>&1; then
    cat "$output" >&2
    return 1
  fi
)

# Evidence input: two Folder-light projects. The first keeps one recurring
# procedure in rules/ + workflows/ while SKILL.md owns routing directly. The
# second has two independently selectable procedures, so routing.yaml and its
# sync owner are admitted, but Full author/harness machinery remains absent.
# Expected: both fitted shapes pass; deleting a routed workflow fails exactly at
# the declared route target.
check_folder_light_fitted_shapes() (
  set -euo pipefail
  local tmp direct_root direct_skill routed_root routed_skill output
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  direct_root="$tmp/direct"
  direct_skill="$direct_root/skills/release-helper"
  mkdir -p "$direct_skill/rules" "$direct_skill/workflows"
  cat > "$direct_skill/SKILL.md" <<'MARKDOWN'
---
name: release-helper
description: >
  This skill should be used when the user asks to "update the project version",
  "prepare a release", or "更新版本号". Activate for release metadata changes
  whose one admitted procedure reads one repository-specific rules file.
---

# Release Helper

## Always Read

1. Read [`release-rules.md`](rules/release-rules.md) before changing version metadata.

## Common Tasks

- Release change: follow [`change-release.md`](workflows/change-release.md), including its direct verification and completion check.

## Known Gotchas

- Never infer a release approval from a successful local build.
MARKDOWN
  cat > "$direct_skill/rules/release-rules.md" <<'MARKDOWN'
# Release Rules

Keep the release approval rule.
MARKDOWN
  cat > "$direct_skill/workflows/change-release.md" <<'MARKDOWN'
# Change Release

Read [`release-rules.md`](../rules/release-rules.md), update the version, run the repository check, and report only that requested result as complete.
MARKDOWN
  cat > "$direct_skill/conformance.yaml" <<'YAML'
required_sections:
  - file: rules/release-rules.md
    must_contain:
      - "Keep the release approval rule."
  - file: workflows/change-release.md
    must_contain:
      - "report only that requested result as complete"
required_files:
  - path: SKILL.md
  - path: rules/release-rules.md
  - path: workflows/change-release.md
YAML

  [[ ! -e "$direct_skill/routing.yaml" ]]
  [[ ! -e "$direct_skill/scripts/sync-routing.sh" ]]
  output="$direct_root/smoke.out"
  if ! (
    cd "$direct_root"
    bash "$ROOT/templates/skill/scripts/smoke-test.sh" release-helper
  ) >"$output" 2>&1; then
    cat "$output" >&2
    return 1
  fi

  routed_root="$tmp/routed"
  routed_skill="$routed_root/skills/release-helper"
  mkdir -p "$routed_skill/rules" "$routed_skill/workflows" "$routed_skill/scripts"
  cat > "$routed_skill/SKILL.md" <<'MARKDOWN'
---
name: release-helper
description: >
  This skill should be used when the user asks to "update the project version",
  "inspect release readiness", or "检查发布准备情况". Activate for release work
  where two independently selectable procedures now require conditional routing.
---

# Release Helper

## Always Read

<!-- ALWAYS_READ_START -->
<!-- ALWAYS_READ_END -->

## Common Tasks

<!-- ROUTING_SUMMARY_START -->
<!-- ROUTING_SUMMARY_END -->

## Known Gotchas

- Never infer a release approval from a successful local build.
MARKDOWN
  cat > "$routed_skill/routing.yaml" <<'YAML'
always_read:
  - rules/release-rules.md
tasks:
  - id: change-release
    labels: { en: Change release, zh: 修改发布 }
    workflow: workflows/change-release.md
    trigger_examples: [update the project version, 更新版本号]
  - id: other
    labels: { en: Other release task, zh: 其他发布任务 }
    workflow: workflows/inspect-release.md
    trigger_examples: [inspect release readiness, 检查发布准备情况]
YAML
  cat > "$routed_skill/rules/release-rules.md" <<'MARKDOWN'
# Release Rules

Keep the release approval rule.
MARKDOWN
  cat > "$routed_skill/workflows/change-release.md" <<'MARKDOWN'
# Change Release

Read [`release-rules.md`](../rules/release-rules.md), update the version, and run the repository check.
MARKDOWN
  cat > "$routed_skill/workflows/inspect-release.md" <<'MARKDOWN'
# Inspect Release

Read [`release-rules.md`](../rules/release-rules.md) and report release readiness without changing repository state.
MARKDOWN
  cp "$ROOT/templates/skill/scripts/sync-routing.sh" "$routed_skill/scripts/sync-routing.sh"
  cat > "$routed_skill/conformance.yaml" <<'YAML'
required_sections:
  - file: routing.yaml
    must_contain:
      - "id: change-release"
      - "id: other"
  - file: workflows/change-release.md
    must_contain:
      - "run the repository check"
  - file: workflows/inspect-release.md
    must_contain:
      - "without changing repository state"
required_files:
  - path: SKILL.md
  - path: routing.yaml
  - path: scripts/sync-routing.sh
YAML

  [[ ! -e "$routed_root/AGENTS.md" ]]
  [[ ! -e "$routed_root/.cursor/skills/release-helper/SKILL.md" ]]
  (
    cd "$routed_root"
    bash "skills/release-helper/scripts/sync-routing.sh" release-helper >/dev/null
  )
  output="$routed_root/smoke.out"
  if ! (
    cd "$routed_root"
    bash "$ROOT/templates/skill/scripts/smoke-test.sh" release-helper
  ) >"$output" 2>&1; then
    cat "$output" >&2
    return 1
  fi

  mv "$routed_skill/workflows/change-release.md" \
    "$routed_skill/workflows/change-release.md.validation-missing"
  if (
    cd "$routed_root"
    bash "$ROOT/templates/skill/scripts/smoke-test.sh" release-helper
  ) >"$output" 2>&1; then
    echo "conditional routing accepted a missing declared workflow" >&2
    return 1
  fi
  grep -q 'workflows/change-release.md missing' "$output" || {
    cat "$output" >&2
    echo "conditional routing failed for an unrelated reason" >&2
    return 1
  }
)

# Evidence input: a deliberately complete copy of the canonical emitted
# templates/skill owners (conditional *.template author sources are excluded)
# plus every emitted shell/registration surface. The fixture itself declares
# these paths in a fitted required_files manifest.
# Expected: the complete result passes, and removing any representative routing,
# execution, Closure, maintenance, Cursor, or harness owner is a hard failure.
check_complete_declared_surfaces() (
  set -euo pipefail
  local tmp name summary skill manifest output path backup status
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  name="complete-skill"
  summary="Complete routed fixture for declared downstream responsibilities"
  skill="$tmp/skills/$name"
  manifest="$tmp/declared-complete-surfaces.yaml"
  output="$tmp/check.out"

  materialize_complete_fixture "$tmp" "$name"
  replace_complete_fixture_identity "$tmp" "$name" "$summary"
  fill_complete_fixture "$tmp" "$name"
  assert_declared_complete_surfaces "$tmp" "$name"
  write_declared_complete_manifest "$tmp" "$name" "$manifest"

  (
    cd "$tmp"
    bash "skills/$name/scripts/sync-routing.sh" "$name" --check >/dev/null
    bash "skills/$name/scripts/smoke-test.sh" "$name" --phase 8
  ) >"$output" 2>&1 || {
    cat "$output" >&2
    return 1
  }
  bash "$ROOT/templates/skill/scripts/check-version-conformance.sh" \
    "$skill" --conformance "$manifest" >"$output" 2>&1 || {
    cat "$output" >&2
    return 1
  }

  for path in \
    "routing.yaml" \
    "workflows/task-execution.md" \
    "workflows/task-closure.md" \
    "scripts/upstream-status.sh"; do
    backup="$skill/$path.validation-missing"
    mv "$skill/$path" "$backup"
    set +e
    bash "$ROOT/templates/skill/scripts/check-version-conformance.sh" \
      "$skill" --conformance "$manifest" >"$output" 2>&1
    status=$?
    set -e
    mv "$backup" "$skill/$path"
    if [[ "$status" -ne 1 ]] || ! grep -qF "$path <- MISSING" "$output"; then
      cat "$output" >&2
      echo "declared complete surface was not enforced: $path" >&2
      return 1
    fi
  done

  for path in ".cursor/skills/$name/SKILL.md" "AGENTS.md"; do
    backup="$tmp/$path.validation-missing"
    mv "$tmp/$path" "$backup"
    if assert_declared_complete_surfaces "$tmp" "$name" >"$output" 2>&1; then
      mv "$backup" "$tmp/$path"
      echo "declared external surface was not enforced: $path" >&2
      return 1
    fi
    mv "$backup" "$tmp/$path"
  done

  mv "$skill/workflows/task-closure.md" \
    "$skill/workflows/task-closure.md.validation-missing"
  if (
    cd "$tmp"
    bash "skills/$name/scripts/smoke-test.sh" "$name" --phase 8
  ) >"$output" 2>&1; then
    echo "complete smoke validation accepted a missing Task Closure owner" >&2
    return 1
  fi
  grep -q 'task-closure.md' "$output" || {
    cat "$output" >&2
    echo "complete smoke validation failed for an unrelated reason" >&2
    return 1
  }
)

# Evidence input: the same complete fixture first retains upstream FILL markers,
# then mechanically renames them to FILLED:. Expected: each fails for the marker
# contract itself, not merely because an unrelated route or link happens to drift.
check_unresolved_and_laundered_fill_are_rejected() (
  set -euo pipefail
  local tmp name summary output
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  name="laundered-skill"
  summary="Fixture that must not pass by renaming unresolved migration work"
  output="$tmp/smoke.out"

  materialize_complete_fixture "$tmp" "$name"
  replace_complete_fixture_identity "$tmp" "$name" "$summary"

  if (
    cd "$tmp"
    bash "skills/$name/scripts/smoke-test.sh" "$name" --phase 8
  ) >"$output" 2>&1; then
    echo "unresolved FILL markers passed validation" >&2
    return 1
  fi
  grep -q 'Unresolved FILL markers found' "$output" || {
    cat "$output" >&2
    echo "unresolved FILL fixture failed for an unrelated reason" >&2
    return 1
  }

  (
    cd "$tmp"
    find "skills/$name" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor \
      -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.yaml' \) \
      -exec sed -i.bak -e 's/FILL:/FILLED:/g' {} +
    find . -name '*.bak' -type f -delete
    bash "skills/$name/scripts/sync-routing.sh" "$name" >/dev/null
  )

  if (
    cd "$tmp"
    bash "skills/$name/scripts/smoke-test.sh" "$name" --phase 8
  ) >"$output" 2>&1; then
    echo "renamed FILLED markers passed validation" >&2
    return 1
  fi
  grep -q 'Renamed FILLED: markers found' "$output" || {
    cat "$output" >&2
    echo "renamed FILLED fixture failed for an unrelated reason" >&2
    return 1
  }
)

# Evidence input: an inventory with a verbatim clause, a reviewed rewrite, and an
# explicit exclusion, plus deliberately malformed variants. Expected: every
# decision-changing source clause has exactly one disposition and activation
# proof; rewrites pass only with explicit review evidence.
check_migration_evidence_contract() (
  set -euo pipefail
  local tmp root manifest checker output status
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  root="$tmp/project"
  manifest="$tmp/evidence.json"
  checker="$ROOT/scripts/check-migration-evidence.sh"
  mkdir -p "$root/source" "$root/skills/release-helper/workflows" "$root/skills/release-helper/rules"

  cat > "$root/source/AGENTS.md" <<'MARKDOWN'
# Existing Rules

Keep the release approval rule.
Run the repository formatter before review.
Remove the obsolete local-only note during migration.
MARKDOWN
  cat > "$root/skills/release-helper/SKILL.md" <<'MARKDOWN'
# Release Helper

Read [`routing.yaml`](routing.yaml) for every task.
MARKDOWN
  cat > "$root/skills/release-helper/routing.yaml" <<'YAML'
tasks:
  - id: change-release
    workflow: workflows/change-release.md
YAML
  cat > "$root/skills/release-helper/workflows/change-release.md" <<'MARKDOWN'
# Change Release

Before changing release state, read [`project-rules.md`](../rules/project-rules.md).
MARKDOWN
  cat > "$root/skills/release-helper/rules/project-rules.md" <<'MARKDOWN'
# Project Rules

Keep the release approval rule.
Use the repository formatter before requesting review.
MARKDOWN

  expect_manifest_failure() {
    local expected="$1" label="$2"
    set +e
    output="$(bash "$checker" --root "$root" --manifest "$manifest" 2>&1)"
    status=$?
    set -e
    if [[ "$status" -ne 1 || "$output" != *"$expected"* ]]; then
      printf '%s\n' "$output" >&2
      printf 'migration evidence fixture did not reject %s with the expected contract failure\n' "$label" >&2
      return 1
    fi
  }

  cat > "$manifest" <<'JSON'
{
  "version": 1,
  "inventory": [
    {"id": "release-approval", "source": "source/AGENTS.md", "text": "Keep the release approval rule."},
    {"id": "formatter-before-review", "source": "source/AGENTS.md", "text": "Run the repository formatter before review."},
    {"id": "obsolete-note", "source": "source/AGENTS.md", "text": "Remove the obsolete local-only note during migration."}
  ],
  "mappings": [
    {
      "inventory_id": "release-approval",
      "destination": "skills/release-helper/rules/project-rules.md",
      "mode": "verbatim",
      "activation_chain": [
        "skills/release-helper/SKILL.md",
        "skills/release-helper/routing.yaml",
        "skills/release-helper/workflows/change-release.md",
        "skills/release-helper/rules/project-rules.md"
      ]
    }
  ],
  "exclusions": [
    {"inventory_id": "obsolete-note", "reason": "The instruction explicitly says this local-only note is obsolete."}
  ]
}
JSON
  expect_manifest_failure \
    "inventory formatter-before-review has no mapped or excluded disposition" \
    "a missing disposition"

  cat > "$manifest" <<'JSON'
{
  "version": 1,
  "inventory": [
    {"id": "release-approval", "source": "source/AGENTS.md", "text": "Keep the release approval rule."},
    {"id": "formatter-before-review", "source": "source/AGENTS.md", "text": "Run the repository formatter before review."},
    {"id": "obsolete-note", "source": "source/AGENTS.md", "text": "Remove the obsolete local-only note during migration."}
  ],
  "mappings": [
    {
      "inventory_id": "release-approval",
      "destination": "skills/release-helper/rules/project-rules.md",
      "mode": "verbatim",
      "activation_chain": [
        "skills/release-helper/SKILL.md",
        "skills/release-helper/workflows/change-release.md",
        "skills/release-helper/rules/project-rules.md"
      ]
    }
  ],
  "exclusions": [
    {"inventory_id": "formatter-before-review", "reason": "Temporary fixture disposition."},
    {"inventory_id": "obsolete-note", "reason": "The instruction explicitly says this local-only note is obsolete."}
  ]
}
JSON
  expect_manifest_failure \
    "activation chain for release-approval has no reference" \
    "a broken activation chain"

  cat > "$manifest" <<'JSON'
{
  "version": 1,
  "inventory": [
    {"id": "release-approval", "source": "source/AGENTS.md", "text": "Keep the release approval rule."},
    {"id": "formatter-before-review", "source": "source/AGENTS.md", "text": "Run the repository formatter before review."},
    {"id": "obsolete-note", "source": "source/AGENTS.md", "text": "Remove the obsolete local-only note during migration."}
  ],
  "mappings": [
    {
      "inventory_id": "release-approval",
      "destination": "skills/release-helper/rules/project-rules.md",
      "mode": "verbatim",
      "activation_chain": [
        "skills/release-helper/SKILL.md",
        "skills/release-helper/routing.yaml",
        "skills/release-helper/workflows/change-release.md",
        "skills/release-helper/rules/project-rules.md"
      ]
    }
  ],
  "exclusions": [
    {"inventory_id": "release-approval", "reason": "Duplicate disposition fixture."},
    {"inventory_id": "formatter-before-review", "reason": "Temporary fixture disposition."},
    {"inventory_id": "obsolete-note", "reason": "The instruction explicitly says this local-only note is obsolete."}
  ]
}
JSON
  expect_manifest_failure \
    "inventory release-approval has 2 dispositions; exactly one is required" \
    "duplicate dispositions"

  cat > "$manifest" <<'JSON'
{
  "version": 1,
  "inventory": [
    {"id": "release-approval", "source": "source/AGENTS.md", "text": "Keep the release approval rule."},
    {"id": "formatter-before-review", "source": "source/AGENTS.md", "text": "Run the repository formatter before review."},
    {"id": "obsolete-note", "source": "source/AGENTS.md", "text": "Remove the obsolete local-only note during migration."}
  ],
  "mappings": [
    {
      "inventory_id": "formatter-before-review",
      "destination": "skills/release-helper/rules/project-rules.md",
      "destination_text": "Use the repository formatter before requesting review.",
      "mode": "rewrite",
      "activation_chain": [
        "skills/release-helper/SKILL.md",
        "skills/release-helper/routing.yaml",
        "skills/release-helper/workflows/change-release.md",
        "skills/release-helper/rules/project-rules.md"
      ]
    }
  ],
  "exclusions": [
    {"inventory_id": "release-approval", "reason": "Temporary fixture disposition."},
    {"inventory_id": "obsolete-note", "reason": "The instruction explicitly says this local-only note is obsolete."}
  ]
}
JSON
  expect_manifest_failure \
    "mapping formatter-before-review review must be non-empty text" \
    "an unreviewed faithful rewrite"

  cat > "$manifest" <<'JSON'
{
  "version": 1,
  "inventory": [
    {"id": "release-approval", "source": "source/AGENTS.md", "text": "Keep the release approval rule."},
    {"id": "formatter-before-review", "source": "source/AGENTS.md", "text": "Run the repository formatter before review."},
    {"id": "obsolete-note", "source": "source/AGENTS.md", "text": "Remove the obsolete local-only note during migration."}
  ],
  "mappings": [
    {
      "inventory_id": "release-approval",
      "destination": "skills/release-helper/rules/project-rules.md",
      "mode": "verbatim",
      "activation_chain": [
        "skills/release-helper/SKILL.md",
        "skills/release-helper/routing.yaml",
        "skills/release-helper/workflows/change-release.md",
        "skills/release-helper/rules/project-rules.md"
      ]
    },
    {
      "inventory_id": "formatter-before-review",
      "destination": "skills/release-helper/rules/project-rules.md",
      "destination_text": "Use the repository formatter before requesting review.",
      "mode": "rewrite",
      "review": "Reviewed by the migration owner against the original formatter-before-review requirement.",
      "activation_chain": [
        "skills/release-helper/SKILL.md",
        "skills/release-helper/routing.yaml",
        "skills/release-helper/workflows/change-release.md",
        "skills/release-helper/rules/project-rules.md"
      ]
    }
  ],
  "exclusions": [
    {"inventory_id": "obsolete-note", "reason": "The instruction explicitly says this local-only note is obsolete."}
  ]
}
JSON
  output="$(bash "$checker" --root "$root" --manifest "$manifest")"
  [[ "$output" == *"REVIEW: mapping formatter-before-review records rewrite review"* ]]
  [[ "$output" == *"semantic equivalence is review evidence, not a script claim"* ]]
  [[ "$output" == *"0 failed"* ]]
)

# Evidence input: a malformed fitted manifest uses scalar required_files items.
# Expected: the conformance parser rejects the schema with exit 2 instead of
# silently producing zero file-existence rules.
check_scalar_required_files_are_rejected() (
  set -euo pipefail
  local tmp skill manifest checker output status
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/scalar-contract"
  manifest="$skill/conformance.yaml"
  checker="$ROOT/templates/skill/scripts/check-version-conformance.sh"
  mkdir -p "$skill"
  printf '# Scalar contract\n' > "$skill/SKILL.md"
  cat > "$manifest" <<'YAML'
required_files:
  - SKILL.md
YAML

  set +e
  output="$(bash "$checker" "$skill" --conformance "$manifest" 2>&1)"
  status=$?
  set -e
  [[ "$status" -eq 2 ]] || {
    printf '%s\n' "$output" >&2
    echo "scalar required_files returned status $status instead of schema status 2" >&2
    return 1
  }
  [[ "$output" == *"conformance schema error"* ]]
  [[ "$output" == *"required_files items must be mappings"* ]]
)

# A stable runtime precondition is behavioral only when its activation,
# selection, and effective-runtime readback all precede the protected command.
# Presence-only assertions would accept the same prose after the red-test step.
check_ordered_precondition_contract() (
  set -euo pipefail
  local tmp skill manifest checker owner output status base_owner mutation schema_case
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/precondition-contract"
  manifest="$skill/conformance.yaml"
  checker="$ROOT/templates/skill/scripts/check-version-conformance.sh"
  owner="$skill/workflows/test.md"
  base_owner="$tmp/test.base.md"
  mkdir -p "$skill/workflows"

  cat > "$base_owner" <<'MARKDOWN'
# Test Workflow

## Runtime Preflight

Read the project toolchain owner before constructing a test command.
Select the required runtime.
Read back the effective runtime used by the build tool.

## Red Test

Run the first protected test command.
MARKDOWN
  cp "$base_owner" "$owner"
  cat > "$manifest" <<'YAML'
required_sections:
  - file: workflows/test.md
    must_contain_in_order:
      - "## Runtime Preflight"
      - "Read the project toolchain owner"
      - "Select the required runtime"
      - "Read back the effective runtime"
      - "## Red Test"
      - "Run the first protected test command"
YAML

  output="$(bash "$checker" "$skill" --conformance "$manifest")"
  [[ "$output" == *"0 failed"* ]]

  for mutation in activation selection readback; do
    cp "$base_owner" "$owner"
    case "$mutation" in
      activation)
        sed -i.bak '/Read the project toolchain owner/d' "$owner"
        ;;
      selection)
        sed -i.bak '/Select the required runtime/d' "$owner"
        ;;
      readback)
        sed -i.bak '/Read back the effective runtime/d' "$owner"
        ;;
    esac
    rm -f "$owner.bak"
    set +e
    output="$(bash "$checker" "$skill" --conformance "$manifest" 2>&1)"
    status=$?
    set -e
    [[ "$status" -eq 1 && "$output" == *"MISSING ordered phrase"* ]] || {
      printf '%s\n' "$output" >&2
      echo "ordered precondition accepted missing $mutation" >&2
      return 1
    }
  done

  cat > "$owner" <<'MARKDOWN'
# Test Workflow

## Red Test

Run the first protected test command.

## Runtime Preflight

Read the project toolchain owner before constructing a test command.
Select the required runtime.
Read back the effective runtime used by the build tool.
MARKDOWN
  set +e
  output="$(bash "$checker" "$skill" --conformance "$manifest" 2>&1)"
  status=$?
  set -e
  [[ "$status" -eq 1 && "$output" == *"OUT OF ORDER"* ]] || {
    printf '%s\n' "$output" >&2
    echo "ordered precondition accepted a preflight after the protected command" >&2
    return 1
  }

  cat > "$owner" <<'MARKDOWN'
# Quoted Scalar Contract

Say "hello": # now
Bob's runtime
MARKDOWN
  cat > "$manifest" <<'YAML'
required_sections:
  - must_contain_in_order:
      - "Say \"hello\": # now"
      - 'Bob''s runtime'
    file: workflows/test.md
YAML
  output="$(bash "$checker" "$skill" --conformance "$manifest")"
  [[ "$output" == *"2"*"passed, 0 failed"* ]] || {
    printf '%s\n' "$output" >&2
    echo "ordered manifest did not decode quoted YAML scalars or honor a later file key" >&2
    return 1
  }

  for schema_case in empty empty_flow inline_flow; do
    case "$schema_case" in
      empty)
        cat > "$manifest" <<'YAML'
required_sections:
  - file: workflows/test.md
    must_contain_in_order:
YAML
        ;;
      empty_flow)
        cat > "$manifest" <<'YAML'
required_sections:
  - file: workflows/test.md
    must_contain_in_order: []
YAML
        ;;
      inline_flow)
        cat > "$manifest" <<'YAML'
required_sections:
  - file: workflows/test.md
    must_contain_in_order: ["DOES NOT EXIST", "Bob's runtime"]
YAML
        ;;
    esac
    set +e
    output="$(bash "$checker" "$skill" --conformance "$manifest" 2>&1)"
    status=$?
    set -e
    [[ "$status" -eq 2 && "$output" == *"conformance schema error"* \
      && "$output" == *"must be a non-empty block sequence"* ]] || {
      printf '%s\n' "$output" >&2
      echo "ordered manifest accepted $schema_case without an ordered assertion" >&2
      return 1
    }
  done

  printf '\377\376\000' > "$owner"
  cat > "$manifest" <<'YAML'
required_sections:
  - file: workflows/test.md
    must_contain_in_order:
      - "runtime"
YAML
  set +e
  output="$(bash "$checker" "$skill" --conformance "$manifest" 2>&1)"
  status=$?
  set -e
  [[ "$status" -eq 1 && "$output" == *"ordered check error"* \
    && "$output" == *"UnicodeDecodeError"* && "$output" == *"Results:"* \
    && "$output" == *"Conformance check failed."* \
    && "$output" != *"Traceback"* ]] || {
    printf '%s\n' "$output" >&2
    echo "ordered scan error did not reach a stable failure summary" >&2
    return 1
  }
)

# Stored prevention and first-occurrence learning close different failure
# boundaries. Each class, plus the non-substitution rule between their proof,
# must remain independently mutation-protected.
check_independent_verified_failure_classes() (
  set -euo pipefail
  local tmp skill manifest checker owner base_owner output status mutation
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/failure-classes"
  manifest="$skill/conformance.yaml"
  checker="$ROOT/templates/skill/scripts/check-version-conformance.sh"
  owner="$skill/workflows/rule-update/verified-failure.md"
  base_owner="$tmp/verified-failure.base.md"
  mkdir -p "$skill/workflows/rule-update"
  cp "$ROOT/templates/skill/workflows/rule-update/verified-failure.md" "$base_owner"
  cp "$base_owner" "$owner"

  cat > "$manifest" <<'YAML'
required_sections:
  - file: workflows/rule-update/verified-failure.md
    must_contain:
      - "**Activation failure** - applicable prevention already exists"
      - "**Learning-closure failure** - the first occurrence has already proved a stable prevention"
      - "Their evidence is not interchangeable"
      - "Evaluate and close both classes separately whenever both are present"
YAML

  output="$(bash "$checker" "$skill" --conformance "$manifest")"
  [[ "$output" == *"4"*"passed, 0 failed"* ]] || {
    printf '%s\n' "$output" >&2
    echo "verified failure class baseline did not satisfy all independent assertions" >&2
    return 1
  }

  for mutation in activation learning_closure proof_boundary; do
    cp "$base_owner" "$owner"
    case "$mutation" in
      activation)
        sed -i.bak '/\*\*Activation failure\*\*/d' "$owner"
        ;;
      learning_closure)
        sed -i.bak '/\*\*Learning-closure failure\*\*/d' "$owner"
        ;;
      proof_boundary)
        sed -i.bak '/Their evidence is not interchangeable/d' "$owner"
        ;;
    esac
    rm -f "$owner.bak"
    set +e
    output="$(bash "$checker" "$skill" --conformance "$manifest" 2>&1)"
    status=$?
    set -e
    [[ "$status" -eq 1 && "$output" == *"MISSING"* ]] || {
      printf '%s\n' "$output" >&2
      echo "verified failure class mutation accepted missing $mutation" >&2
      return 1
    }
  done
)

# Requirement Definition, Implementation Planning, and deterministic downshift
# protect separate decisions. A broad presence check can stay green after a
# responsibility moves back into Plan Feature or one phase is reordered, so
# delete every load-bearing clause and inject the dangerous ownership/order
# regressions independently.
check_requirement_plan_separation_and_bounded_execution_contract() (
  set -euo pipefail
  local tmp skill manifest checker requirement_owner plan_owner task_owner
  local contract_owner change_owner executable_owner composite_owner delivery_owner output check_status
  local mutation owner needle replacement
  local base_requirement base_plan base_task base_contract base_change base_executable
  local base_composite base_delivery
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/requirement-execution-contract"
  manifest="$skill/conformance.yaml"
  checker="$ROOT/templates/skill/scripts/check-version-conformance.sh"
  requirement_owner="$skill/workflows/define-requirement.md"
  plan_owner="$skill/workflows/plan-feature.md"
  task_owner="$skill/workflows/task-execution.md"
  contract_owner="$skill/protocol-blocks/change-contract.md"
  change_owner="$skill/workflows/change-managed.md"
  executable_owner="$skill/references/executable-skill-architecture.md"
  composite_owner="$skill/protocol-blocks/composite-plan-execution.md"
  delivery_owner="$skill/protocol-blocks/external-delivery-verification.md"
  base_requirement="$tmp/define-requirement.base.md"
  base_plan="$tmp/plan-feature.base.md"
  base_task="$tmp/task-execution.base.md"
  base_contract="$tmp/change-contract.base.md"
  base_change="$tmp/change-managed.base.md"
  base_executable="$tmp/executable-skill-architecture.base.md"
  base_composite="$tmp/composite-plan-execution.base.md"
  base_delivery="$tmp/external-delivery-verification.base.md"
  mkdir -p "$skill/workflows" "$skill/protocol-blocks" "$skill/references"
  cp "$ROOT/templates/skill/workflows/define-requirement.md" "$base_requirement"
  cp "$ROOT/templates/skill/workflows/plan-feature.md" "$base_plan"
  cp "$ROOT/templates/skill/workflows/task-execution.md" "$base_task"
  cp "$ROOT/templates/skill/protocol-blocks/change-contract.md" "$base_contract"
  cp "$ROOT/templates/skill/workflows/change-managed.md" "$base_change"
  cp "$ROOT/references/executable-skill-architecture.md" "$base_executable"
  cp "$ROOT/templates/skill/protocol-blocks/composite-plan-execution.md" "$base_composite"
  cp "$ROOT/templates/skill/protocol-blocks/external-delivery-verification.md" "$base_delivery"
  cp "$base_requirement" "$requirement_owner"
  cp "$base_plan" "$plan_owner"
  cp "$base_task" "$task_owner"
  cp "$base_contract" "$contract_owner"
  cp "$base_change" "$change_owner"
  cp "$base_executable" "$executable_owner"
  cp "$base_composite" "$composite_owner"
  cp "$base_delivery" "$delivery_owner"

  cat > "$manifest" <<'YAML'
required_files:
  - path: workflows/define-requirement.md
    reason: Requirement Definition interaction owner.
  - path: workflows/plan-feature.md
    reason: Implementation Plan owner.
  - path: workflows/task-execution.md
    reason: Task Anchor and Native Plan runtime owner.
  - path: protocol-blocks/change-contract.md
    reason: Requirement Contract and Implementation Binding state owner.
  - path: workflows/change-managed.md
    reason: Feature implementation consumer.
  - path: references/executable-skill-architecture.md
    reason: Bounded deterministic execution owner.
  - path: protocol-blocks/composite-plan-execution.md
    reason: Requirement-governed technical composition owner.
  - path: protocol-blocks/external-delivery-verification.md
    reason: Requirement-bound requested artifact verification owner.
required_sections:
  - file: workflows/define-requirement.md
    must_contain:
      - "produces `requirement-ready` and, only under its own"
      - "ask the minimum normative question needed to choose among those meanings"
      - "Code may constrain or falsify a premise; it cannot choose desired"
      - "Keep the Requirement Contract in the current Session by default"
      - "update the smallest Governing Requirement only when the user explicitly asks"
      - "Exclude Current -> Target implementation design"
      - "Requirement does not enter Plan Feature or authorize mutation"
      - "Plan Feature cannot copy, narrow, resolve, or update the Governing"
      - "Requirement Definition does not derive implementation steps"
    must_not_contain:
      - "## Question Gate"
      - "## Decision Mainline"
      - "Do not create a Requirement file, Task Anchor, or Plan here"
      - "Requirement-only PRD uses Plan Feature's Artifact Pressure Gate"
  - file: workflows/plan-feature.md
    must_contain:
      - "It is not the Requirement Definition owner"
      - "If later evidence changes desired meaning, return to Requirement Definition"
      - "The proof implementation is subordinate to acceptance"
      - "Requirement Definition and never borrows this Gate"
      - "return to Requirement Definition to materialize that owner first"
      - "use separate dossier carriers"
      - "`prd.md` owns the Requirement and `design.md` owns the Implementation Plan"
      - "`design.md` declares `requirement: prd.md`"
      - "A Requirement-only dossier may stop at `prd.md`"
      - "A new implementation Plan never uses `prd.md` as its technical or lifecycle owner"
      - "Requirement-only artifact delivery never enters this workflow"
      - "Then let Task Execution derive the Native Plan"
    must_contain_in_order:
      - "Consume the Requirement"
      - "Project the Task Anchor"
      - "Prove implementation facts"
      - "Reach `implementation-ready`"
      - "derive technical design, Task Interfaces, proof implementation"
    must_not_contain:
      - "## Question Gate"
      - "## Decision Mainline"
      - "Requirement-only PRD uses Plan Feature's Artifact Pressure Gate"
      - "a new implementation Plan uses `prd.md` as its technical or lifecycle owner"
  - file: workflows/task-execution.md
    must_contain:
      - "Apparent code locality never makes requirement-bearing work Simple"
      - "reclassify before more mutation"
      - "After `requirement-ready` and before implementation-binding discovery"
      - "After source localization makes the Change Contract `implementation-ready`"
      - "Technical evidence that changes only Current facts"
      - "without editing the Anchor"
      - "updated and reaches `requirement-ready` again"
    must_not_contain:
      - "Re-anchor only when the user or evidence changes the Requirement frame"
      - "If evidence changes the premise, scope, ordering, or Done When, update the Anchor"
  - file: protocol-blocks/change-contract.md
    must_contain:
      - "desired goal and observable user/business outcome"
      - "scope, non-goals, preserved behavior, and permission boundary"
      - "decision-bearing actor/trigger, model/object relationship, concrete flow"
      - "rules, defaults, constraints, failure meaning, and compatibility behavior"
      - "observable, falsifiable acceptance that can reject a wrong result"
      - "Bind Current -> Target without changing the Requirement"
      - "creates the Task Anchor after `requirement-ready`, but creates the Native Plan"
      - "only after `implementation-ready`; the Plan consumes rather than defines the"
    must_contain_in_order:
      - "requirement-incomplete -> requirement-ready"
      - "localization-required/owner-proven"
      - "binding-incomplete -> implementation-ready"
  - file: workflows/change-managed.md
    must_contain_in_order:
      - "complete Requirement Definition"
      - "project its Task Anchor"
      - "after `implementation-ready` derive the Native Plan"
      - "before mutation"
  - file: references/executable-skill-architecture.md
    must_contain:
      - "1. **Low freedom:**"
      - "2. **Real pressure:**"
      - "The Agent owns the goal, desired meaning, semantic parameters, target selection"
      - "A one-off, low-risk action with a direct cheap check stays on"
      - "1. **Execution identity:**"
      - "2. **Authority and provenance:**"
      - "3. **Freshness:**"
      - "4. **Completeness and semantic validity:**"
      - "5. **Requested terminal state:**"
      - "the user's outcome, not only accepted, queued"
  - file: protocol-blocks/composite-plan-execution.md
    must_contain:
      - "common governing Requirement projection"
      - "Task Execution alone projects that Requirement into one Integrating Task Anchor"
      - "read its governing Requirement or Requirement projection for Goal, meaning, invariant, boundary, and acceptance"
      - "Read its Component Plan only for technical decisions"
      - "conflict returns to Requirement Definition and the affected Requirement owner"
      - "this protocol neither creates that Anchor nor defines the common outcome or integrated acceptance"
    must_not_contain:
      - "multiple independently authoritative Plans"
      - "Component meaning, invariant, boundary, accepted interface, or local acceptance returns to that Component's Design owner"
      - "one Integrating Task Anchor and one Native Plan cover the common outcome and integrated acceptance"
  - file: protocol-blocks/external-delivery-verification.md
    must_contain:
      - "current explicit user request and the Governing Requirement, as projected into the active Task Anchor"
      - "Plans may attach only an already-bound item's technical identity"
      - "Plan cannot add, omit, narrow, or modify an artifact or requested terminal state"
    must_not_contain:
      - "active Task Anchor, and every governing Plan"
YAML

  output="$(bash "$checker" "$skill" --conformance "$manifest")"
  [[ "$output" == *"0 failed"* ]] || {
    printf '%s\n' "$output" >&2
    echo "requirement/Plan separation and bounded-execution baseline did not pass" >&2
    return 1
  }

  for mutation in \
    requirement_goal \
    requirement_scope \
    requirement_model_flow \
    requirement_rules \
    requirement_acceptance \
    incomplete_no_guess \
    requirement_session_default \
    requirement_explicit_artifact_pressure \
    requirement_artifact_excludes_implementation \
    requirement_one_way_plan_consumer \
    plan_separate_dossier_carriers \
    plan_design_requirement_link \
    plan_prd_not_plan_owner \
    old_absolute_no_requirement_file \
    plan_borrowed_requirement_persistence \
    plan_prd_technical_owner \
    technical_evidence_edits_anchor \
    current_vs_desired \
    anchor_projection \
    implementation_ready_ordering \
    plan_return \
    test_subordinate \
    requirement_no_mutation \
    plan_question_gate \
    plan_decision_mainline \
    plan_order_reversal \
    feature_not_simple \
    in_place_reclassification \
    low_freedom \
    real_pressure \
    agent_judgment \
    one_off_direct \
    readback_identity \
    readback_authority \
    readback_freshness \
    readback_completeness \
    readback_terminal \
    intermediate_not_terminal \
    delivery_plan_authority \
    composite_plan_authority \
    composite_design_owner_return \
    composite_creates_anchor; do
    cp "$base_requirement" "$requirement_owner"
    cp "$base_plan" "$plan_owner"
    cp "$base_task" "$task_owner"
    cp "$base_contract" "$contract_owner"
    cp "$base_change" "$change_owner"
    cp "$base_executable" "$executable_owner"
    cp "$base_composite" "$composite_owner"
    cp "$base_delivery" "$delivery_owner"
    replacement=""
    case "$mutation" in
      requirement_goal)
        owner="$contract_owner"
        needle="desired goal and observable user/business outcome"
        ;;
      requirement_scope)
        owner="$contract_owner"
        needle="scope, non-goals, preserved behavior, and permission boundary"
        ;;
      requirement_model_flow)
        owner="$contract_owner"
        needle="decision-bearing actor/trigger, model/object relationship, concrete flow"
        ;;
      requirement_rules)
        owner="$contract_owner"
        needle="rules, defaults, constraints, failure meaning, and compatibility behavior"
        ;;
      requirement_acceptance)
        owner="$contract_owner"
        needle="observable, falsifiable acceptance that can reject a wrong result"
        ;;
      incomplete_no_guess)
        owner="$requirement_owner"
        needle="ask the minimum normative question needed to choose among those meanings"
        ;;
      requirement_session_default)
        owner="$requirement_owner"
        needle="Keep the Requirement Contract in the current Session by default"
        ;;
      requirement_explicit_artifact_pressure)
        owner="$requirement_owner"
        needle="update the smallest Governing Requirement only when the user explicitly asks"
        ;;
      requirement_artifact_excludes_implementation)
        owner="$requirement_owner"
        needle="Exclude Current -> Target implementation design"
        ;;
      requirement_one_way_plan_consumer)
        owner="$requirement_owner"
        needle="Plan Feature cannot copy, narrow, resolve, or update the Governing"
        ;;
      plan_separate_dossier_carriers)
        owner="$plan_owner"
        needle="use separate dossier carriers"
        ;;
      plan_design_requirement_link)
        owner="$plan_owner"
        needle='`design.md` declares `requirement: prd.md`'
        ;;
      plan_prd_not_plan_owner)
        owner="$plan_owner"
        needle='A new implementation Plan never uses `prd.md` as its technical or lifecycle owner'
        ;;
      old_absolute_no_requirement_file)
        owner="$requirement_owner"
        needle="Do not create a Requirement file, Task Anchor, or Plan here"
        replacement=$'\nDo not create a Requirement file, Task Anchor, or Plan here.\n'
        ;;
      plan_borrowed_requirement_persistence)
        owner="$plan_owner"
        needle="Requirement-only PRD uses Plan Feature's Artifact Pressure Gate"
        replacement=$'\nRequirement-only PRD uses Plan Feature\x27s Artifact Pressure Gate.\n'
        ;;
      plan_prd_technical_owner)
        owner="$plan_owner"
        needle='a new implementation Plan uses `prd.md` as its technical or lifecycle owner'
        replacement=$'\na new implementation Plan uses `prd.md` as its technical or lifecycle owner.\n'
        ;;
      technical_evidence_edits_anchor)
        owner="$task_owner"
        needle="If evidence changes the premise, scope, ordering, or Done When, update the Anchor"
        replacement=$'\nIf evidence changes the premise, scope, ordering, or Done When, update the Anchor and remaining Plan before more mutation.\n'
        ;;
      current_vs_desired)
        owner="$contract_owner"
        needle="Bind Current -> Target without changing the Requirement"
        ;;
      anchor_projection)
        owner="$task_owner"
        needle='After `requirement-ready` and before implementation-binding discovery'
        ;;
      implementation_ready_ordering)
        owner="$contract_owner"
        needle='only after `implementation-ready`; the Plan consumes rather than defines the'
        ;;
      plan_return)
        owner="$plan_owner"
        needle="If later evidence changes desired meaning, return to Requirement Definition"
        ;;
      test_subordinate)
        owner="$plan_owner"
        needle="The proof implementation is subordinate to acceptance"
        ;;
      requirement_no_mutation)
        owner="$requirement_owner"
        needle="Requirement does not enter Plan Feature or authorize mutation"
        ;;
      plan_question_gate)
        owner="$plan_owner"
        needle="## Question Gate"
        replacement=$'\n## Question Gate\n\nPlan Feature asks and resolves normative questions.\n'
        ;;
      plan_decision_mainline)
        owner="$plan_owner"
        needle="## Decision Mainline"
        replacement=$'\n## Decision Mainline\n\nPlan Feature records user-owned desired meaning.\n'
        ;;
      plan_order_reversal)
        owner="$plan_owner"
        needle="Consume the Requirement"
        replacement="__ORDER_REVERSAL__"
        ;;
      feature_not_simple)
        owner="$task_owner"
        needle="Apparent code locality never makes requirement-bearing work Simple"
        ;;
      readiness_before_native_plan)
        owner="$plan_owner"
        needle='Task Breakdown, task interfaces, and mutation stay absent until `requirement-ready`'
        ;;
      native_plan_vs_durable)
        owner="$plan_owner"
        needle="durable materialization still requires Artifact Pressure"
        ;;
      in_place_reclassification)
        owner="$task_owner"
        needle="reclassify before more mutation"
        ;;
      low_freedom)
        owner="$executable_owner"
        needle="1. **Low freedom:**"
        ;;
      real_pressure)
        owner="$executable_owner"
        needle="2. **Real pressure:**"
        ;;
      agent_judgment)
        owner="$executable_owner"
        needle="The Agent owns the goal, desired meaning, semantic parameters, target selection"
        ;;
      one_off_direct)
        owner="$executable_owner"
        needle="A one-off, low-risk action with a direct cheap check stays on"
        ;;
      readback_identity)
        owner="$executable_owner"
        needle="1. **Execution identity:**"
        ;;
      readback_authority)
        owner="$executable_owner"
        needle="2. **Authority and provenance:**"
        ;;
      readback_freshness)
        owner="$executable_owner"
        needle="3. **Freshness:**"
        ;;
      readback_completeness)
        owner="$executable_owner"
        needle="4. **Completeness and semantic validity:**"
        ;;
      readback_terminal)
        owner="$executable_owner"
        needle="5. **Requested terminal state:**"
        ;;
      intermediate_not_terminal)
        owner="$executable_owner"
        needle="the user's outcome, not only accepted, queued"
        ;;
      delivery_plan_authority)
        owner="$delivery_owner"
        needle="active Task Anchor, and every governing Plan"
        replacement=$'\nDerive the set only from the current explicit user request, active Task Anchor, and every governing Plan.\n'
        ;;
      composite_plan_authority)
        owner="$composite_owner"
        needle="multiple independently authoritative Plans"
        replacement=$'\nLoad this protocol only when one outcome consumes multiple independently authoritative Plans.\n'
        ;;
      composite_design_owner_return)
        owner="$composite_owner"
        needle="Component meaning, invariant, boundary, accepted interface, or local acceptance returns to that Component's Design owner"
        replacement=$'\nComponent meaning, invariant, boundary, accepted interface, or local acceptance returns to that Component\x27s Design owner.\n'
        ;;
      composite_creates_anchor)
        owner="$composite_owner"
        needle="one Integrating Task Anchor and one Native Plan cover the common outcome and integrated acceptance"
        replacement=$'\n- `ready`: one Integrating Task Anchor and one Native Plan cover the common outcome and integrated acceptance.\n'
        ;;
    esac
    if [[ "$mutation" == "plan_question_gate" || "$mutation" == "plan_decision_mainline" || \
          "$mutation" == "old_absolute_no_requirement_file" || \
          "$mutation" == "plan_borrowed_requirement_persistence" || \
          "$mutation" == "plan_prd_technical_owner" || \
          "$mutation" == "technical_evidence_edits_anchor" || \
          "$mutation" == "delivery_plan_authority" || \
          "$mutation" == "composite_plan_authority" || \
          "$mutation" == "composite_design_owner_return" || \
          "$mutation" == "composite_creates_anchor" ]]; then
      printf '%s' "$replacement" >> "$owner"
    elif [[ "$mutation" == "plan_order_reversal" ]]; then
      MUTATION_NEEDLE="$needle" MUTATION_REPLACEMENT="$replacement" perl -0pi -e \
        's/\Q$ENV{MUTATION_NEEDLE}\E/$ENV{MUTATION_REPLACEMENT}/' "$owner"
      perl -0pi -e \
        's/Reach `implementation-ready`/__ORDER_READY__/; s/__ORDER_REVERSAL__/Reach `implementation-ready`/; s/__ORDER_READY__/Consume the Requirement/' \
        "$owner"
    else
      MUTATION_NEEDLE="$needle" perl -0pi -e 's/\Q$ENV{MUTATION_NEEDLE}\E//' "$owner"
      if grep -qF -- "$needle" "$owner"; then
        echo "mutation setup failed to remove $mutation" >&2
        return 1
      fi
    fi
    set +e
    output="$(bash "$checker" "$skill" --conformance "$manifest" 2>&1)"
    check_status=$?
    set -e
    [[ "$check_status" -eq 1 ]] || {
      printf '%s\n' "$output" >&2
      echo "requirement/Plan/execution mutation accepted $mutation" >&2
      return 1
    }
  done
)

# The canonical materializer must preserve the phase split without exporting the
# complete author scaffold. Exercise every fitted carrier and verify both local
# reference integrity and route-specific mutation/Plan prohibitions.
check_requirement_materialization_matrix() (
  set -euo pipefail
  local tmp scaffold smoke checker output status
  local direct_root folder_root routed_root plan_root broad_root control_root
  local direct_skill folder_skill routed_skill plan_skill broad_skill control_skill
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  scaffold="$ROOT/scripts/scaffold-downstream.sh"
  smoke="$ROOT/templates/skill/scripts/smoke-test.sh"
  checker="$ROOT/templates/skill/scripts/check-version-conformance.sh"

  assert_in_order() {
    local file="$1" content phrase
    shift
    content="$(<"$file")"
    for phrase in "$@"; do
      [[ "$content" == *"$phrase"* ]] || {
        echo "$file missing ordered phase: $phrase" >&2
        return 1
      }
      content="${content#*"$phrase"}"
    done
  }

  assert_path_contract() {
    local root="$1" name="$2" result
    result="$(cd "$root" && bash "$smoke" "$name" --phase 7 --workspace-root "$root")"
    [[ "$result" == *"Local links, inline paths, and heading fragments resolve"* ]] || {
      printf '%s\n' "$result" >&2
      echo "$name materialization has a broken local reference" >&2
      return 1
    }
  }

  direct_root="$tmp/direct"
  folder_root="$tmp/folder"
  routed_root="$tmp/routed"
  plan_root="$tmp/plan"
  broad_root="$tmp/broad"
  control_root="$tmp/broad-control"
  mkdir -p "$direct_root" "$folder_root" "$routed_root" "$plan_root" "$broad_root" "$control_root"

  bash "$scaffold" --target "$direct_root" --name direct-requirement \
    --summary "Direct requirement carrier" --apply >/dev/null
  direct_skill="$direct_root/skills/direct-requirement"
  [[ -f "$direct_skill/SKILL.md" && ! -e "$direct_skill/routing.yaml" && ! -d "$direct_skill/workflows" ]]
  assert_in_order "$direct_skill/SKILL.md" \
    'requirement-ready' 'Task Anchor' 'implementation-ready' 'implementation Plan' 'mutate'
  assert_path_contract "$direct_root" direct-requirement

  cat > "$tmp/folder.json" <<'JSON'
{"version":1,"tasks":[{"id":"change-managed","labels":{"en":"Change behavior","zh":"修改行为"},"trigger_examples":["change behavior","修改行为"]}]}
JSON
  bash "$scaffold" --target "$folder_root" --name folder-requirement \
    --summary "Folder-light direct requirement carrier" --evidence "$tmp/folder.json" --apply >/dev/null
  folder_skill="$folder_root/skills/folder-requirement"
  [[ -f "$folder_skill/workflows/project-task.md" && ! -e "$folder_skill/routing.yaml" && ! -e "$folder_skill/workflows/define-requirement.md" ]]
  assert_in_order "$folder_skill/workflows/project-task.md" \
    'requirement-ready' 'Task Anchor' 'implementation-ready' 'implementation Plan' 'make one risk-sized change'
  assert_path_contract "$folder_root" folder-requirement

  cat > "$tmp/routed.json" <<'JSON'
{"version":1,"tasks":[{"id":"define-requirement","labels":{"en":"Define requirement","zh":"明确需求"},"trigger_examples":["define requirement","明确需求"]},{"id":"change-managed","labels":{"en":"Change behavior","zh":"修改行为"},"trigger_examples":["change behavior","修改行为"],"managed":true}]}
JSON
  bash "$scaffold" --target "$routed_root" --name routed-requirement \
    --summary "Folder-light routed requirement carrier" --evidence "$tmp/routed.json" --apply >/dev/null
  routed_skill="$routed_root/skills/routed-requirement"
  grep -qF -- 'id: define-requirement' "$routed_skill/routing.yaml"
  grep -qF -- 'id: change-managed' "$routed_skill/routing.yaml"
  grep -qF -- 'does not produce an implementation Plan, Task Breakdown, code mutation, or proof command' \
    "$routed_skill/workflows/define-requirement.md"
  ! grep -qF -- 'Make one risk-sized change' "$routed_skill/workflows/define-requirement.md"
  assert_in_order "$routed_skill/workflows/change-managed.md" \
    'requirement-ready' 'Task Anchor' 'implementation-ready' 'implementation Plan' 'make one risk-sized change'
  [[ ! -e "$routed_skill/workflows/task-execution.md" ]]
  ! rg -q 'task-execution\.md|task-closure\.md' "$routed_skill/SKILL.md" "$routed_root/AGENTS.md"
  assert_path_contract "$routed_root" routed-requirement

  cat > "$tmp/plan.json" <<'JSON'
{"version":1,"tasks":[{"id":"define-requirement","labels":{"en":"Define requirement","zh":"明确需求"},"trigger_examples":["define requirement","明确需求"]},{"id":"plan-feature","labels":{"en":"Plan implementation","zh":"规划实现"},"trigger_examples":["plan implementation","规划实现"]}]}
JSON
  bash "$scaffold" --target "$plan_root" --name plan-requirement \
    --summary "Folder-light implementation Plan carrier" --evidence "$tmp/plan.json" --apply >/dev/null
  plan_skill="$plan_root/skills/plan-requirement"
  assert_in_order "$plan_skill/workflows/plan-feature.md" \
    'requirement-ready' 'Task Anchor' 'implementation-ready' 'implementation Plan'
  grep -qF -- 'does not execute mutation' "$plan_skill/workflows/plan-feature.md"
  grep -qF -- 'Any durable implementation Plan is a separate one-way consumer' "$plan_skill/workflows/plan-feature.md"
  grep -qF -- 'never stores technical Plan content or lifecycle state in' "$plan_skill/workflows/plan-feature.md"
  ! grep -qF -- 'Make one risk-sized change' "$plan_skill/workflows/plan-feature.md"
  assert_path_contract "$plan_root" plan-requirement

  cat > "$tmp/broad.json" <<'JSON'
{"version":1,"tasks":[{"id":"define-requirement","labels":{"en":"Define requirement","zh":"明确需求"},"trigger_examples":["define requirement","明确需求"]},{"id":"change-managed","labels":{"en":"Change behavior","zh":"修改行为"},"trigger_examples":["change behavior","修改行为"],"managed":true},{"id":"plan-feature","labels":{"en":"Plan implementation","zh":"规划实现"},"trigger_examples":["plan implementation","规划实现"]}],"maintenance_pressure":{"validation":true}}
JSON
  bash "$scaffold" --target "$broad_root" --name broad-requirement \
    --summary "Broad admitted requirement carrier" --evidence "$tmp/broad.json" --apply >/dev/null
  broad_skill="$broad_root/skills/broad-requirement"
  [[ -f "$broad_skill/workflows/define-requirement.md" && -f "$broad_skill/conformance.yaml" ]]
  output="$(bash "$checker" "$broad_skill" --conformance "$broad_skill/conformance.yaml")"
  [[ "$output" == *"0 failed"* ]]
  mv "$broad_skill/workflows/define-requirement.md" "$tmp/define-requirement.missing"
  set +e
  output="$(bash "$checker" "$broad_skill" --conformance "$broad_skill/conformance.yaml" 2>&1)"
  status=$?
  set -e
  mv "$tmp/define-requirement.missing" "$broad_skill/workflows/define-requirement.md"
  [[ "$status" -eq 1 && "$output" == *"workflows/define-requirement.md <- MISSING"* ]]
  assert_path_contract "$broad_root" broad-requirement

  cat > "$tmp/control.json" <<'JSON'
{"version":1,"tasks":[{"id":"change-managed","labels":{"en":"Change behavior","zh":"修改行为"},"trigger_examples":["change behavior","修改行为"],"managed":true},{"id":"plan-feature","labels":{"en":"Plan implementation","zh":"规划实现"},"trigger_examples":["plan implementation","规划实现"]},{"id":"receiving-review","labels":{"en":"Receive review","zh":"处理评审"},"trigger_examples":["receive review","处理评审"]}],"maintenance_pressure":{"validation":true}}
JSON
  bash "$scaffold" --target "$control_root" --name broad-control \
    --summary "Broad control without requirement route" --evidence "$tmp/control.json" --apply >/dev/null
  control_skill="$control_root/skills/broad-control"
  [[ ! -e "$control_skill/workflows/define-requirement.md" ]]
  ! grep -qF -- 'id: define-requirement' "$control_skill/routing.yaml"
  ! grep -qF -- 'workflows/define-requirement.md' "$control_skill/conformance.yaml"
  assert_path_contract "$control_root" broad-control
)

# Evidence input: valid local Markdown references include one path-like inline
# code span, a Markdown link whose label contains a backticked path, one heading
# fragment, fenced example paths, and placeholder/glob examples. Expected: the
# valid fixture passes; deleting the standalone inline target and renaming the
# heading each fail for the exact affected reference.
check_inline_paths_and_heading_fragments() (
  set -euo pipefail
  local tmp skill smoke output status
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/path-contract"
  smoke="$ROOT/templates/skill/scripts/smoke-test.sh"
  mkdir -p "$skill/references" "$skill/workflows/rule-update"

  cat > "$skill/SKILL.md" <<'MARKDOWN'
---
name: path-contract
description: >
  This skill should be used when the user asks to "inspect reference integrity",
  "validate local skill documentation", or "检查技能引用". Activate for project
  documentation whose local paths and section anchors must stay executable.
---

# Path Contract

## Common Tasks

- Reference check: read [inline paths](references/code-owner.md) and
  [heading anchors](references/anchor-owner.md), then run the fitted smoke check.
- Other: inspect the same two owners and report unresolved local references.

## Known Gotchas

- Fenced examples and placeholder/glob notation are examples, not dependencies.
MARKDOWN
  cat > "$skill/references/code-owner.md" <<'MARKDOWN'
# Inline Path Owner

Read `references/details.md` before applying the local procedure.

Follow [`rule-update/business-truth.md` § Requirement Decision Source](../workflows/rule-update/business-truth.md#requirement-decision-source).

`missing-catalog/entry.md` is a non-binding inventory example; a reference cue
on the preceding line must not turn it into a dependency.

Do not treat `path with spaces.md`, `references/<name>/missing.md`, or
`references/*.md` as concrete dependencies.

```text
`missing-fenced-example.md`
```
MARKDOWN
  cat > "$skill/references/anchor-owner.md" <<'MARKDOWN'
# Anchor Owner

Follow the [Completion Gate](sections.md#completion-gate).
MARKDOWN
  cat > "$skill/references/details.md" <<'MARKDOWN'
# Details

The concrete inline-code target exists.
MARKDOWN
  cat > "$skill/references/sections.md" <<'MARKDOWN'
# Sections

## Completion Gate

The referenced completion section exists.
MARKDOWN
  cat > "$skill/workflows/rule-update/business-truth.md" <<'MARKDOWN'
# Business Truth

## Requirement Decision Source

The Markdown link target resolves relative to its source file; the backticked
path in the link label is presentation text, not a second inline dependency.
MARKDOWN

  output="$(cd "$tmp" && bash "$smoke" path-contract --phase 7 --workspace-root "$tmp")"
  [[ "$output" == *"inline_paths="* ]]
  [[ "$output" == *"fragments="* ]]

  mv "$skill/references/details.md" "$skill/references/details.md.validation-missing"
  set +e
  output="$(cd "$tmp" && bash "$smoke" path-contract --phase 7 --workspace-root "$tmp" 2>&1)"
  status=$?
  set -e
  mv "$skill/references/details.md.validation-missing" "$skill/references/details.md"
  [[ "$status" -eq 1 && "$output" == *"inline path:"* && "$output" == *"details.md"* ]] || {
    printf '%s\n' "$output" >&2
    echo "missing inline-code target did not fail for details.md" >&2
    return 1
  }

  cp "$skill/references/sections.md" "$tmp/sections.base.md"
  perl -0pi -e 's/## Completion Gate/## Completion Boundary/' "$skill/references/sections.md"
  set +e
  output="$(cd "$tmp" && bash "$smoke" path-contract --phase 7 --workspace-root "$tmp" 2>&1)"
  status=$?
  set -e
  cp "$tmp/sections.base.md" "$skill/references/sections.md"
  [[ "$status" -eq 1 && "$output" == *"heading fragment:"* && "$output" == *"sections.md#completion-gate"* ]] || {
    printf '%s\n' "$output" >&2
    echo "renamed heading did not fail for the completion-gate fragment" >&2
    return 1
  }
)

# Evidence input: a real broad materializer result with validation and
# database/deploy/config/shared-system pressure. Expected: the emitted manifest
# uses mapping-shaped required_files, deleting an emitted owner fails, and the
# no-implied-authority rule is both emitted and mutation-protected.
check_materialized_required_files_and_permission_anchor() (
  set -euo pipefail
  local tmp target name summary skill manifest checker output status permission_anchor
  local control_target control_name control_summary control_skill control_manifest control_apply
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  target="$tmp/project"
  name="permission-project"
  summary="Project with validation and external write authority pressure"
  skill="$target/skills/$name"
  manifest="$skill/conformance.yaml"
  checker="$ROOT/templates/skill/scripts/check-version-conformance.sh"
  permission_anchor='Task scope does not automatically grant external write authority for databases, deployments, configuration, or shared systems; obtain explicit authorization before performing such writes.'
  mkdir -p "$target/.github/workflows" "$target/scripts"
  cat > "$target/AGENTS.md" <<'MARKDOWN'
# Project Instructions

## Fix Bug Workflow

Reproduce database failures and run the repository validation script.

## Add Feature Workflow

Implement configuration changes without deploying them to a shared system.

## Review Release Workflow

Review the change and keep deployment approval explicit.

## Known Gotcha

Never infer database, deployment, configuration, or shared-system write authority from local task scope.
MARKDOWN
  printf 'name: verify\n' > "$target/.github/workflows/verify.yml"
  printf '#!/usr/bin/env bash\nset -euo pipefail\n' > "$target/scripts/check-project.sh"
  chmod +x "$target/scripts/check-project.sh"

  bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$target" --name "$name" --summary "$summary" --apply >/dev/null

  [[ -f "$manifest" ]]
  grep -qF -- '- path: workflows/task-closure.md' "$manifest"
  grep -qF -- "$permission_anchor" "$skill/rules/project-rules.md"
  grep -qF -- 'file: rules/project-rules.md' "$manifest"
  grep -qF -- "$permission_anchor" "$manifest"
  [[ ! -e "$skill/references/permission-model.md" ]]
  bash "$checker" "$skill" --conformance "$manifest" >/dev/null

  mv "$skill/workflows/task-closure.md" \
    "$skill/workflows/task-closure.md.validation-missing"
  set +e
  output="$(bash "$checker" "$skill" --conformance "$manifest" 2>&1)"
  status=$?
  set -e
  mv "$skill/workflows/task-closure.md.validation-missing" \
    "$skill/workflows/task-closure.md"
  [[ "$status" -eq 1 && "$output" == *"workflows/task-closure.md <- MISSING"* ]] || {
    printf '%s\n' "$output" >&2
    echo "deleting an actually emitted required file did not fail conformance" >&2
    return 1
  }

  cp "$skill/rules/project-rules.md" "$tmp/project-rules.base.md"
  perl -0pi -e 's/Task scope does not automatically grant external write authority for databases, deployments, configuration, or shared systems; obtain explicit authorization before performing such writes\.//g' \
    "$skill/rules/project-rules.md"
  set +e
  output="$(bash "$checker" "$skill" --conformance "$manifest" 2>&1)"
  status=$?
  set -e
  cp "$tmp/project-rules.base.md" "$skill/rules/project-rules.md"
  [[ "$status" -eq 1 && "$output" == *"rules/project-rules.md <- MISSING: $permission_anchor"* ]] || {
    printf '%s\n' "$output" >&2
    echo "removing the permission anchor did not fail for its fitted rule" >&2
    return 1
  }

  # Control: one recurring local procedure justifies Folder-light owners but
  # carries no evidence of an external side effect. Permission responsibility
  # must therefore stay absent rather than becoming a universal doctrine.
  control_target="$tmp/local-procedure-project"
  control_name="local-procedure"
  control_summary="Project with one recurring formatter procedure"
  control_skill="$control_target/skills/$control_name"
  control_manifest="$control_skill/conformance.yaml"
  mkdir -p "$control_target"
  cat > "$control_target/AGENTS.md" <<'MARKDOWN'
# Project Instructions

## Formatter Procedure

Run the repository formatter before review and keep public output stable.
MARKDOWN

  control_apply="$(bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$control_target" --name "$control_name" \
    --summary "$control_summary" --apply)"
  [[ "$control_apply" == *"APPLIED RESPONSIBILITIES: materialization=folder routed=0"* ]] || {
    printf '%s\n' "$control_apply" >&2
    echo "no-external-write control did not materialize as Folder-light" >&2
    return 1
  }
  [[ -f "$control_skill/rules/project-rules.md" ]]
  if grep -qF -- "$permission_anchor" "$control_skill/rules/project-rules.md"; then
    echo "Folder-light control received permission doctrine without external-write evidence" >&2
    return 1
  fi
  if [[ -f "$control_manifest" ]] && grep -qF -- "$permission_anchor" "$control_manifest"; then
    echo "Folder-light fitted manifest protected permission doctrine without external-write evidence" >&2
    return 1
  fi
)

# Evidence input: five existing harness Skill registries, with four matching
# formal owners and one orphaned Claude registration. Expected: every registry
# is inventoried/preserved, and the orphan produces explicit review work without
# being deleted or silently treated as a complete migration.
check_existing_skill_registries_are_preserved() (
  set -euo pipefail
  local tmp target before name summary preview apply path owner
  local registrations=(
    ".cursor/skills/cursor-helper/SKILL.md"
    ".claude/skills/orphan/SKILL.md"
    ".codex/skills/codex-helper/SKILL.md"
    ".agents/skills/agents-helper/SKILL.md"
    ".gemini/skills/gemini-helper/SKILL.md"
  )
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  target="$tmp/project"
  before="$tmp/before"
  name="registry-project"
  summary="Project with existing harness Skill registrations"
  mkdir -p "$target" "$before"

  for path in "${registrations[@]}"; do
    mkdir -p "$target/$(dirname "$path")"
    cat > "$target/$path" <<MARKDOWN
---
name: $(basename "$(dirname "$path")")
description: Existing harness registration fixture.
---

# Existing Registration

Preserve this harness-local registration during SBA migration.
MARKDOWN
  done
  for owner in cursor-helper codex-helper agents-helper gemini-helper; do
    mkdir -p "$target/skills/$owner"
    printf '# %s formal owner\n' "$owner" > "$target/skills/$owner/SKILL.md"
  done
  cp -R "$target/." "$before/"

  preview="$(bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$target" --name "$name" --summary "$summary")"
  diff -r "$before" "$target"
  for path in "${registrations[@]}"; do
    [[ "$preview" == *"PRESERVE: $path (Agent must migrate its meaning and keep the local shell hook)"* ]] || {
      printf '%s\n' "$preview" >&2
      echo "registry was omitted from the evidence inventory: $path" >&2
      return 1
    }
  done
  [[ "$preview" == *"REVIEW: .claude/skills/orphan/SKILL.md (formal owner missing: skills/orphan/SKILL.md; preserve registration until ownership is resolved)"* ]] || {
    printf '%s\n' "$preview" >&2
    echo "missing formal owner did not create explicit registry review work" >&2
    return 1
  }

  apply="$(bash "$ROOT/scripts/scaffold-downstream.sh" \
    --target "$target" --name "$name" --summary "$summary" --apply)"
  [[ "$apply" == *"REVIEW: .claude/skills/orphan/SKILL.md"* ]]
  for path in "${registrations[@]}"; do
    cmp "$before/$path" "$target/$path"
  done
  for owner in cursor-helper codex-helper agents-helper gemini-helper; do
    cmp "$before/skills/$owner/SKILL.md" "$target/skills/$owner/SKILL.md"
  done
)

# Evidence input: a routed Skill and Cursor registration begin with identical
# descriptions, then only the formal SKILL.md activation text changes. Expected:
# --check reports drift, normal sync repairs Cursor frontmatter, and registration-
# specific body content remains intact.
check_cursor_description_sync_contract() (
  set -euo pipefail
  local tmp skill cursor sync output status
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/description-skill"
  cursor="$tmp/.cursor/skills/description-skill/SKILL.md"
  sync="$ROOT/templates/skill/scripts/sync-routing.sh"
  mkdir -p "$skill/workflows" "$(dirname "$cursor")"
  cat > "$skill/SKILL.md" <<'MARKDOWN'
---
name: description-skill
description: >
  This skill should be used when the user asks to "inspect the old activation",
  "maintain description routing", or "检查旧触发描述". Activate for the routed
  description synchronization fixture.
---

# Description Skill

## Always Read

<!-- ALWAYS_READ_START -->
<!-- ALWAYS_READ_END -->

## Common Tasks

<!-- ROUTING_SUMMARY_START -->
<!-- ROUTING_SUMMARY_END -->

## Known Gotchas

- Keep the formal and Cursor descriptions identical.
MARKDOWN
  cat > "$skill/routing.yaml" <<'YAML'
always_read: []
tasks:
  - id: inspect
    labels: { en: Inspect, zh: 检查 }
    workflow: workflows/inspect.md
    trigger_examples: [inspect activation, 检查触发]
  - id: other
    labels: { en: Other, zh: 其他 }
    workflow: workflows/inspect.md
    trigger_examples: [other task, 其他任务]
YAML
  printf '# Inspect\n\nInspect the routed activation.\n' > "$skill/workflows/inspect.md"
  cat > "$cursor" <<'MARKDOWN'
---
name: description-skill
description: >
  This skill should be used when the user asks to "inspect the old activation",
  "maintain description routing", or "检查旧触发描述". Activate for the routed
  description synchronization fixture.
---

# Cursor Registration

CURSOR-SPECIFIC-SENTINEL: preserve this registration body.

<!-- ROUTING_BOOTSTRAP_START -->
<!-- ROUTING_BOOTSTRAP_END -->
MARKDOWN

  bash "$sync" "$skill" >/dev/null
  perl -0pi -e 's/inspect the old activation/inspect the new canonical activation/' \
    "$skill/SKILL.md"
  set +e
  output="$(bash "$sync" "$skill" --check 2>&1)"
  status=$?
  set -e
  [[ "$status" -eq 1 && "$output" == *"DRIFT:"* && "$output" == *".cursor/skills/description-skill/SKILL.md"* ]] || {
    printf '%s\n' "$output" >&2
    echo "Cursor description drift was not reported in check mode" >&2
    return 1
  }

  bash "$sync" "$skill" >/dev/null
  grep -qF 'inspect the new canonical activation' "$cursor"
  grep -qF 'CURSOR-SPECIFIC-SENTINEL: preserve this registration body.' "$cursor"
  bash "$sync" "$skill" --check >/dev/null
)

# App Skills are installed beneath a harness-owned `skills/` registry. A
# reference from one formal Skill to another is relative to that harness root,
# even when --workspace-root points at the surrounding iteration directory.
check_harness_relative_skill_paths_resolve() (
  set -euo pipefail
  local tmp harness primary secondary smoke output
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  harness="$tmp/.codex"
  primary="$harness/skills/primary"
  secondary="$harness/skills/secondary"
  smoke="$ROOT/templates/skill/scripts/smoke-test.sh"
  mkdir -p "$primary/workflows" "$secondary"
  cat > "$primary/SKILL.md" <<'MARKDOWN'
---
name: primary
description: >
  This skill should be used when the user asks to "inspect installed skills",
  "follow a sibling skill owner", or "检查已安装 Skill". Activate for harness
  registries whose formal owners live below the current skills directory.
---

# Primary

## Common Tasks

- Sibling owner: read `workflows/run.md`.
- Other: use the same harness-relative owner rule.

## Known Gotchas

- The workspace root and harness registry root are distinct boundaries.
MARKDOWN
  cat > "$primary/workflows/run.md" <<'MARKDOWN'
# Run

Read `skills/secondary/SKILL.md` before reporting the sibling owner.
MARKDOWN
  cat > "$secondary/SKILL.md" <<'MARKDOWN'
---
name: secondary
description: >
  This skill should be used when the user asks to "read the secondary owner",
  "inspect sibling registration", or "读取相邻 Skill". Activate for the
  secondary installed owner used by the harness-relative fixture.
---

# Secondary

## Common Tasks

- Owner check: report this file.
- Other: report this file.

## Known Gotchas

- This owner is intentionally outside the primary Skill directory.
MARKDOWN

  output="$(cd "$harness" && bash "$smoke" primary --phase 7 --workspace-root "$tmp")"
  [[ "$output" == *"Local links, inline paths, and heading fragments resolve"* ]]
  output="$(cd "$primary" && bash "$smoke" . --phase 7 --workspace-root "$tmp")"
  [[ "$output" == *"Local links, inline paths, and heading fragments resolve"* ]]
)

# A self-hosting Skill may keep its formal owner at the project root. Invoking
# smoke by the Skill's frontmatter name must not fall through to skills/<name>.
check_self_hosting_skill_root_resolves_by_name() (
  set -euo pipefail
  local tmp smoke output
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  smoke="$ROOT/templates/skill/scripts/smoke-test.sh"
  mkdir -p "$tmp/references" "$tmp/workflows" "$tmp/scripts" "$tmp/.cursor/rules"
  cat > "$tmp/SKILL.md" <<'MARKDOWN'
---
name: self-hosting-contract
description: >
  This skill should be used when the user asks to "inspect a self-hosting Skill",
  "validate root-owned formal docs", or "检查自托管 Skill". Activate when the
  formal Skill owner intentionally lives at the repository root.
---

# Self-Hosting Contract

## Common Tasks

- Root owner check: read [the fitted workflow](workflows/full-migration.md).
- Other: use the same root-owned formal documentation.

## Known Gotchas

- The project root, not `skills/self-hosting-contract`, owns this Skill.
MARKDOWN
  cat > "$tmp/references/self-hosting-routing.yaml" <<'YAML'
tasks:
  - id: migrate
    workflow: workflows/full-migration.md
YAML
  cat > "$tmp/references/protocols.md" <<'MARKDOWN'
# Protocols

Use the fitted completion proof.
MARKDOWN
  cat > "$tmp/workflows/full-migration.md" <<'MARKDOWN'
# Full Migration

Read `references/protocols.md` before completion.
MARKDOWN
  cat > "$tmp/AGENTS.md" <<'MARKDOWN'
# Agent Instructions

Formal docs live at repo root. Read `SKILL.md` first, then read
`references/self-hosting-routing.yaml`; the migration route owns
`workflows/full-migration.md` and completion uses `references/protocols.md`.
MARKDOWN
  cat > "$tmp/.cursor/rules/workflow.mdc" <<'MARKDOWN'
# Cursor Workflow

Read `SKILL.md` and `references/self-hosting-routing.yaml` before routing.
MARKDOWN
  cat > "$tmp/scripts/check-self-shells.sh" <<'SHELL'
#!/usr/bin/env bash
set -euo pipefail
test -f references/self-hosting-routing.yaml
SHELL
  chmod +x "$tmp/scripts/check-self-shells.sh"

  output="$(cd "$tmp" && bash "$smoke" self-hosting-contract --phase 7 --workspace-root "$tmp")"
  [[ "$output" == *"Local links, inline paths, and heading fragments resolve"* ]]
  [[ "$output" != *"(missing $tmp/skills/self-hosting-contract"* ]]
)

# Optional-owner guidance and examples in HTML comments are authoring context,
# not live downstream dependencies. Missing paths inside those comments must not
# fail the fitted local-reference scan.
check_html_comments_are_not_live_references() (
  set -euo pipefail
  local tmp skill smoke output
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/comment-contract"
  smoke="$ROOT/templates/skill/scripts/smoke-test.sh"
  mkdir -p "$skill"
  cat > "$skill/SKILL.md" <<'MARKDOWN'
---
name: comment-contract
description: >
  This skill should be used when the user asks to "validate optional examples",
  "inspect commented owners", or "检查注释示例". Activate for downstream
  documentation whose author-only HTML comments must not become live paths.
---

# Comment Contract

## Common Tasks

- Comment check: run the fitted reference scan and preserve author examples as comments.
- Other: inspect only materialized owners.

## Known Gotchas

<!-- OPTIONAL: Read `references/not-materialized.md` only after a real owner is admitted. -->
<!-- e.g. See [Example owner](references/example-owner.md#example-section). -->
MARKDOWN

  output="$(cd "$tmp" && bash "$smoke" comment-contract --phase 7 --workspace-root "$tmp")"
  [[ "$output" == *"Local links, inline paths, and heading fragments resolve"* ]]
)

# Namespaced references are rooted capabilities, not permission to traverse out
# of either owner. Existing files outside the roots must not launder ../ escapes.
check_namespaced_path_escapes_are_rejected() (
  set -euo pipefail
  local tmp workspace skill code_root smoke sync reach output smoke_status skill_status code_status
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  workspace="$tmp/workspace"
  skill="$workspace/skills/escape-contract"
  code_root="$workspace/code/skills/escape-contract"
  smoke="$ROOT/templates/skill/scripts/smoke-test.sh"
  sync="$ROOT/templates/skill/scripts/sync-routing.sh"
  reach="$ROOT/templates/skill/scripts/route-reachability.sh"
  mkdir -p "$skill/workflows" "$code_root" "$workspace/skills" "$workspace/code/skills"
  printf '# Outside skill root\n' > "$workspace/skills/outside.md"
  printf '# Outside code root\n' > "$workspace/code/skills/outside.md"
  cat > "$skill/SKILL.md" <<'MARKDOWN'
---
name: escape-contract
description: >
  This skill should be used when the user asks to "validate owner boundaries",
  "inspect namespaced paths", or "检查路径越界". Activate for two-root routing
  whose skill and code references must remain inside their declared owners.
---

# Escape Contract

## Always Read

<!-- ALWAYS_READ_START -->
<!-- ALWAYS_READ_END -->

## Common Tasks

<!-- ROUTING_SUMMARY_START -->
<!-- ROUTING_SUMMARY_END -->

## Known Gotchas

- Never accept an existing file outside a declared owner root.

## Escape Probe

Read `skill:../outside.md` and `code:../outside.md` before the probe.
MARKDOWN
  cat > "$skill/routing.yaml" <<'YAML'
path_resolution:
  skill_root: { owns: [SKILL.md, routing.yaml, workflows/**] }
  code_root:
    root: code/skills/escape-contract
    owns: [references/**]
always_read: []
tasks:
  - id: probe
    labels: { en: Probe paths, zh: 检查路径 }
    workflow: workflows/run.md
    trigger_examples: [probe paths, 检查路径]
  - id: other
    labels: { en: Other, zh: 其他 }
    workflow: workflows/run.md
    trigger_examples: [other task, 其他任务]
YAML
  printf '# Run\n\nRun the owner-boundary probe.\n' > "$skill/workflows/run.md"
  bash "$sync" "$skill" --workspace-root "$workspace" >/dev/null

  set +e
  output="$(cd "$workspace" && bash "$smoke" escape-contract --phase 7 --workspace-root "$workspace" 2>&1)"
  smoke_status=$?
  set -e
  [[ "$smoke_status" -eq 1 && "$output" == *"skill:../outside.md"* && "$output" == *"code:../outside.md"* ]] || {
    printf '%s\n' "$output" >&2
    echo "smoke accepted a namespaced path escape" >&2
    return 1
  }

  perl -0pi -e 's/always_read: \[\]/always_read:\n  - skill:workflows\/\.\.\/\.\.\/outside.md\n  - code:references\/\.\.\/\.\.\/outside.md/' \
    "$skill/routing.yaml"
  perl -0pi -e 's/workflow: workflows\/run\.md/workflow: skill:workflows\/run.md/g' \
    "$skill/routing.yaml"
  set +e
  output="$(cd "$skill" && bash "$reach" --namespace skill --routing "$skill/routing.yaml" 2>&1)"
  skill_status=$?
  set -e
  [[ "$skill_status" -eq 1 && "$output" == *"INVALID"* && "$output" == *"../outside.md"* ]] || {
    printf '%s\n' "$output" >&2
    echo "skill reachability accepted a ../ escape" >&2
    return 1
  }
  set +e
  output="$(cd "$code_root" && bash "$reach" --namespace code --routing "$skill/routing.yaml" 2>&1)"
  code_status=$?
  set -e
  [[ "$code_status" -eq 1 && "$output" == *"INVALID"* && "$output" == *"../outside.md"* ]] || {
    printf '%s\n' "$output" >&2
    echo "code reachability accepted a ../ escape" >&2
    return 1
  }
)

# A missing owner in one formal Skill cannot be satisfied by a same-relative
# path that happens to exist under another harness registration Skill.
check_registration_owners_do_not_cross_resolve() (
  set -euo pipefail
  local tmp skill smoke output status
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/primary-skill"
  smoke="$ROOT/templates/skill/scripts/smoke-test.sh"
  mkdir -p "$skill" "$tmp/.cursor/skills/unrelated-skill/references"
  cat > "$skill/SKILL.md" <<'MARKDOWN'
---
name: primary-skill
description: >
  This skill should be used when the user asks to "validate owner isolation",
  "inspect registration references", or "检查注册隔离". Activate when local
  references must resolve only inside the selected formal Skill owner.
---

# Primary Skill

## Common Tasks

- Owner check: read [the primary owner](references/shared.md).
- Other: report the missing primary owner without searching another Skill.

## Known Gotchas

- Same-relative paths in another registration are not substitutes.
MARKDOWN
  printf '# Unrelated registration owner\n' \
    > "$tmp/.cursor/skills/unrelated-skill/references/shared.md"

  set +e
  output="$(cd "$tmp" && bash "$smoke" primary-skill --phase 7 --workspace-root "$tmp" 2>&1)"
  status=$?
  set -e
  [[ "$status" -eq 1 && "$output" == *"references/shared.md"* && "$output" == *"missing"* ]] || {
    printf '%s\n' "$output" >&2
    echo "smoke resolved a missing owner through another registration Skill" >&2
    return 1
  }
)

# required_files paths are owned by the selected Skill root. A reason cannot
# make parent traversal valid even when the escaped target exists.
check_required_files_path_escape_is_rejected() (
  set -euo pipefail
  local tmp skill manifest checker output status
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/path-escape"
  manifest="$skill/conformance.yaml"
  checker="$ROOT/templates/skill/scripts/check-version-conformance.sh"
  mkdir -p "$skill"
  printf '# Path Escape\n' > "$skill/SKILL.md"
  printf '# Outside\n' > "$tmp/skills/outside.md"
  cat > "$manifest" <<'YAML'
required_files:
  - path: ../outside.md
    reason: Existing outside file must not satisfy a Skill-root contract.
YAML

  set +e
  output="$(bash "$checker" "$skill" --conformance "$manifest" 2>&1)"
  status=$?
  set -e
  [[ "$status" -eq 2 && "$output" == *"conformance schema error"* ]] || {
    printf '%s\n' "$output" >&2
    echo "required_files accepted a path escaping the Skill root" >&2
    return 1
  }
)

# Commented YAML examples are not routing edges. An otherwise-unreferenced file
# named only in a routing comment must remain unreachable.
check_routing_comments_do_not_seed_reachability() (
  set -euo pipefail
  local tmp skill reach output status
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skill"
  reach="$ROOT/templates/skill/scripts/route-reachability.sh"
  mkdir -p "$skill/workflows" "$skill/references"
  printf '# Run\n' > "$skill/workflows/run.md"
  printf '# Hidden owner\n' > "$skill/references/hidden.md"
  cat > "$skill/routing.yaml" <<'YAML'
# Example only: references/hidden.md
tasks:
  - id: run
    workflow: workflows/run.md
YAML

  set +e
  output="$(cd "$skill" && bash "$reach" 2>&1)"
  status=$?
  set -e
  [[ "$status" -eq 1 && "$output" == *"UNREACHED  references/hidden.md"* ]] || {
    printf '%s\n' "$output" >&2
    echo "routing.yaml comment text became a reachability seed" >&2
    return 1
  }
)

# GitHub preserves every separator hyphen produced by spaces and punctuation;
# `A - B` therefore resolves to #a---b, not a collapsed #a-b slug.
check_github_slug_preserves_consecutive_hyphens() (
  set -euo pipefail
  local tmp skill smoke output
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/slug-contract"
  smoke="$ROOT/templates/skill/scripts/smoke-test.sh"
  mkdir -p "$skill/references"
  cat > "$skill/SKILL.md" <<'MARKDOWN'
---
name: slug-contract
description: >
  This skill should be used when the user asks to "validate heading anchors",
  "inspect GitHub slugs", or "检查标题锚点". Activate for Markdown references
  whose punctuation must follow GitHub heading-fragment behavior exactly.
---

# Slug Contract

## Common Tasks

- Fragment check: read [A - B](references/sections.md#a---b).
- Other: run the same fitted reference scan.

## Known Gotchas

- Consecutive separator hyphens are significant.
MARKDOWN
  cat > "$skill/references/sections.md" <<'MARKDOWN'
# Sections

## A - B

The GitHub-compatible fragment contains three consecutive hyphens.
MARKDOWN

  output="$(cd "$tmp" && bash "$smoke" slug-contract --phase 7 --workspace-root "$tmp")"
  [[ "$output" == *"fragments=1"* ]]
)

# required_files is a mapping contract, not a key-order contract. A useful
# reason may appear before path without suppressing the existence assertion.
check_reason_first_required_files_mapping() (
  set -euo pipefail
  local tmp skill manifest checker output
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/reason-first"
  manifest="$skill/conformance.yaml"
  checker="$ROOT/templates/skill/scripts/check-version-conformance.sh"
  mkdir -p "$skill"
  printf '# Reason First\n' > "$skill/SKILL.md"
  cat > "$manifest" <<'YAML'
required_files:
  - reason: Primary formal owner for this fitted result.
    path: SKILL.md
YAML

  output="$(bash "$checker" "$skill" --conformance "$manifest")"
  [[ "$output" == *"SKILL.md <- exists"* && "$output" == *"0 failed"* ]]
)

# The smoke scanner must stream or batch discovered files. Passing every path in
# argv makes a large but valid Markdown tree fail before Python can inspect it.
check_many_markdown_files_do_not_hit_arg_max() (
  set -euo pipefail
  local tmp skill smoke output arg_max approximate_path_bytes file_count index long_name
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  skill="$tmp/skills/arg-max-contract"
  smoke="$ROOT/templates/skill/scripts/smoke-test.sh"
  mkdir -p "$skill/references/bulk"
  cat > "$skill/SKILL.md" <<'MARKDOWN'
---
name: arg-max-contract
description: >
  This skill should be used when the user asks to "scan a large documentation tree",
  "validate many Markdown owners", or "检查大量文档". Activate when fitted
  reference integrity must remain independent of operating-system argv limits.
---

# Arg Max Contract

## Common Tasks

- Large scan: run fitted local-reference integrity across every Markdown owner.
- Other: use the same streamed file inventory.

## Known Gotchas

- File discovery volume must not become one process argument list.
MARKDOWN
  arg_max="$(getconf ARG_MAX 2>/dev/null || printf '1048576')"
  approximate_path_bytes=190
  file_count=$((arg_max / approximate_path_bytes + 512))
  [[ "$file_count" -le 14000 ]] || file_count=14000
  long_name="$(printf '%0120d' 0 | tr '0' 'x')"
  for ((index = 0; index < file_count; index++)); do
    printf '# Bulk owner %s\n' "$index" \
      > "$skill/references/bulk/$long_name-$index.md"
  done

  output="$(cd "$tmp" && bash "$smoke" arg-max-contract --phase 7 --workspace-root "$tmp")"
  [[ "$output" == *"Local links, inline paths, and heading fragments resolve"* ]]
)

if check_single_file_skill; then
  pass "valid Single-file Skill passes without Full-only files"
else
  fail "valid Single-file Skill was rejected by Full-shape assumptions"
fi

if check_folder_light_fitted_shapes; then
  pass "Folder-light direct and conditionally routed shapes use fitted validation"
else
  fail "Folder-light validation still assumes absent Full or routing surfaces"
fi

if check_complete_declared_surfaces; then
  pass "complete fixture keeps every declared Full responsibility strict"
else
  fail "adaptive validation weakened a declared Full responsibility"
fi

if check_unresolved_and_laundered_fill_are_rejected; then
  pass "FILL residue and renamed FILLED markers are rejected for their actual reason"
else
  fail "unresolved migration markers can still be laundered or fail only incidentally"
fi

if check_migration_evidence_contract; then
  pass "source clauses require one disposition, activation, and explicit rewrite review"
else
  fail "migration evidence did not distinguish stored text from activated or reviewed migration"
fi

if check_scalar_required_files_are_rejected; then
  pass "scalar required_files manifests are rejected as schema errors"
else
  fail "scalar required_files can still bypass file-existence checks"
fi

if check_ordered_precondition_contract; then
  pass "runtime preconditions must activate, select, and read back before the protected command"
else
  fail "presence-only conformance can still accept a late or incomplete runtime precondition"
fi

if check_independent_verified_failure_classes; then
  pass "activation and learning-closure failures retain independent proof and completion boundaries"
else
  fail "one JDK failure class can still mask or substitute for the other"
fi

if check_requirement_plan_separation_and_bounded_execution_contract; then
  pass "Requirement Definition, Implementation Plan separation, bounded downshift, and terminal readback are independently mutation-protected"
else
  fail "requirement/Plan ownership, ordering, or deterministic-execution clauses can regress without a fitted contract failure"
fi

if check_requirement_materialization_matrix; then
  pass "direct, Folder-light, routed, Plan, and broad carriers preserve fitted requirement/Plan separation without broken references"
else
  fail "a fitted downstream carrier can over-materialize, mutate during requirement discussion, reorder Plan phases, or emit broken references"
fi

if check_inline_paths_and_heading_fragments; then
  pass "inline paths and heading fragments fail on the exact missing target"
else
  fail "local-reference validation still ignores code spans, anchors, or example boundaries"
fi

if check_materialized_required_files_and_permission_anchor; then
  pass "actual emitted required files and permission semantics are mutation-protected"
else
  fail "materialized conformance does not protect emitted owners and external-write authority"
fi

if check_existing_skill_registries_are_preserved; then
  pass "existing harness Skill registries are inventoried, preserved, and reviewed when orphaned"
else
  fail "existing harness Skill registrations can be omitted or silently lose ownership"
fi

if check_cursor_description_sync_contract; then
  pass "routing sync detects and repairs Cursor description drift without replacing registration content"
else
  fail "Cursor activation description remains a drifting hand-maintained copy"
fi

if check_harness_relative_skill_paths_resolve; then
  pass "installed skills/... references resolve from the active harness registry root"
else
  fail "installed sibling Skill references are incorrectly resolved from the workspace root"
fi

if check_self_hosting_skill_root_resolves_by_name; then
  pass "self-hosting Skills invoked by name resolve their root formal owner"
else
  fail "self-hosting root owners fall through to a nonexistent skills/<name> directory"
fi

if check_html_comments_are_not_live_references; then
  pass "optional-owner and HTML-comment examples do not become live references"
else
  fail "commented author examples are still treated as materialized owners"
fi

if check_namespaced_path_escapes_are_rejected; then
  pass "smoke and reachability reject skill:/code: paths that escape their owner roots"
else
  fail "namespaced ../ paths can escape a declared owner root"
fi

if check_registration_owners_do_not_cross_resolve; then
  pass "smoke does not satisfy a missing owner from another registration Skill"
else
  fail "registration globbing can cross-resolve an unrelated Skill owner"
fi

if check_required_files_path_escape_is_rejected; then
  pass "conformance rejects required_files paths that escape the Skill root"
else
  fail "required_files can validate an owner outside the fitted Skill root"
fi

if check_routing_comments_do_not_seed_reachability; then
  pass "routing.yaml comments do not create reachability seeds"
else
  fail "comment-only routing paths can make dead owners look reachable"
fi

if check_github_slug_preserves_consecutive_hyphens; then
  pass "heading fragments follow GitHub consecutive-hyphen slug behavior"
else
  fail "heading slug normalization collapses significant consecutive hyphens"
fi

if check_reason_first_required_files_mapping; then
  pass "reason-first required_files mappings retain their path assertion"
else
  fail "required_files mapping validity still depends on key order"
fi

if check_many_markdown_files_do_not_hit_arg_max; then
  pass "large Markdown inventories are scanned without an argv-sized file list"
else
  fail "large Markdown inventories can still fail at the operating-system ARG_MAX boundary"
fi

printf '\nValidation contract results: %s passed, %s failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
