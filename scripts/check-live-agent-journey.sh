#!/usr/bin/env bash
# Opt-in black-box journeys using a real Codex CLI in fresh temporary projects.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_BIN="${SBA_CODEX_BIN:-codex}"
LIVE_TIMEOUT_SECONDS="${SBA_LIVE_AGENT_TIMEOUT_SECONDS:-180}"
MODE="single-file"

usage() {
  cat <<'EOF'
Usage: scripts/check-live-agent-journey.sh [--mode single-file|migration]

Modes:
  single-file  Run the existing direct-Skill version-update journey (default).
  migration    Run the ordinary code-first SBA rule-migration journey.

Exit 3 means live transport/authentication/model evidence was unavailable and
therefore produced no behavior verdict. It is neither a pass nor a failure.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      [[ $# -ge 2 ]] || { echo "Missing value for --mode" >&2; exit 2; }
      MODE="$2"
      shift 2
      ;;
    --mode=*)
      MODE="${1#--mode=}"
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

case "$MODE" in
  single-file|migration) ;;
  *)
    echo "Unknown live journey mode: $MODE" >&2
    usage >&2
    exit 2
    ;;
esac

command -v "$CODEX_BIN" >/dev/null 2>&1 || {
  echo "Codex CLI not found: $CODEX_BIN" >&2
  exit 2
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
project="$tmp/project"
mkdir -p "$project"

PROMPT=""
AGENTS_BEFORE=""
SKILL_BEFORE=""
CHECK_BEFORE=""
MIGRATION_NAME="lantern-orders"
MIGRATION_RULE="Orders totaling CNY 7300 or more require two finance approvals before fulfillment."
MIGRATION_SOURCES_BEFORE=""

setup_single_file_fixture() {
  mkdir -p "$project/skills/release-helper" "$project/scripts"

  cat > "$project/AGENTS.md" <<'MARKDOWN'
# Project Instructions

For every task, read `skills/release-helper/SKILL.md` before acting.
MARKDOWN

  cat > "$project/skills/release-helper/SKILL.md" <<'MARKDOWN'
---
name: release-helper
description: >
  This skill should be used when the user asks to "update the project version",
  "prepare a release", or "更新版本号". Activate for release metadata changes
  in this small repository where one direct workflow covers every admitted task.
---

# Release Helper

## Always Read

1. Read `VERSION` before changing release metadata.

## Common Tasks

- Version update: change only `VERSION`, then run `bash scripts/check-version.sh 1.2.4`.
- Other release request: inspect `VERSION`, make the smallest relevant change, and run the same check.

Do not create `routing.yaml`, workflow directories, extra harness entries, or maintenance files for this task.
MARKDOWN

  cat > "$project/scripts/check-version.sh" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
expected="${1:?expected version required}"
actual="$(tr -d '\r\n' < VERSION)"
[[ "$actual" == "$expected" ]] || {
  echo "expected VERSION=$expected, got $actual" >&2
  exit 1
}
BASH
  chmod +x "$project/scripts/check-version.sh"
  printf '1.2.3\n' > "$project/VERSION"

  AGENTS_BEFORE="$(cksum "$project/AGENTS.md")"
  SKILL_BEFORE="$(cksum "$project/skills/release-helper/SKILL.md")"
  CHECK_BEFORE="$(cksum "$project/scripts/check-version.sh")"
  PROMPT='把版本号更新到 1.2.4'
}

setup_migration_fixture() {
  mkdir -p "$project/config" "$project/docs" "$project/scripts" \
    "$project/src" "$project/tests"

  {
    printf '# Project Instructions\n\n'
    printf 'For a request to organize this project with SBA, use the current SBA checkout as a read-only tool source.\n'
    printf 'Read %s/SKILL.md first, then %s/references/self-hosting-routing.yaml, match exactly one route, and follow that workflow.\n' "$ROOT" "$ROOT"
    printf 'Treat this temporary repository as the migration target. The request authorizes project-local instruction and Skill edits only; it does not authorize writes to the SBA checkout or any external system.\n'
  } > "$project/AGENTS.md"

  cat > "$project/README.md" <<'MARKDOWN'
# Lantern Orders

`lantern-orders` is a small TypeScript order-policy service. Its canonical
business wording is in `docs/business-rules.md`; current implementation values
are in `config/order-policy.yaml` and `src/order-policy.ts`.

## Fix policy defects

Trace the failing policy path, preserve the documented business rule, and run
`bash scripts/check-project.sh`.

## Change fulfillment behavior

Update the documented rule, configuration, implementation, and tests together,
then run `bash scripts/check-project.sh`.

## Review release readiness

Compare the business rule with configuration, implementation, and tests before
reporting whether a release is ready.
MARKDOWN

  cat > "$project/package.json" <<'JSON'
{
  "name": "lantern-orders",
  "private": true,
  "scripts": {
    "check": "bash scripts/check-project.sh"
  }
}
JSON

  cat > "$project/docs/business-rules.md" <<EOF
# Business Rules

This file is the canonical project rule source for the current service.

## Finance approval

$MIGRATION_RULE

Preserve the sentence above verbatim when project rules are reorganized.
EOF

  cat > "$project/config/order-policy.yaml" <<'YAML'
finance_approval_threshold_cny: 7300
required_finance_approvals: 2
YAML

  cat > "$project/src/order-policy.ts" <<'TYPESCRIPT'
export const FINANCE_APPROVAL_THRESHOLD_CNY = 7300;
export const REQUIRED_FINANCE_APPROVALS = 2;

export function requiresFinanceApproval(totalCny: number): boolean {
  return totalCny >= FINANCE_APPROVAL_THRESHOLD_CNY;
}
TYPESCRIPT

  cat > "$project/tests/order-policy.test.ts" <<'TYPESCRIPT'
import {
  FINANCE_APPROVAL_THRESHOLD_CNY,
  REQUIRED_FINANCE_APPROVALS,
  requiresFinanceApproval,
} from "../src/order-policy";

if (FINANCE_APPROVAL_THRESHOLD_CNY !== 7300) throw new Error("threshold drift");
if (REQUIRED_FINANCE_APPROVALS !== 2) throw new Error("approval-count drift");
if (!requiresFinanceApproval(7300)) throw new Error("boundary drift");
TYPESCRIPT

  cat > "$project/scripts/check-project.sh" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
grep -qF 'finance_approval_threshold_cny: 7300' config/order-policy.yaml
grep -qF 'required_finance_approvals: 2' config/order-policy.yaml
grep -qF 'FINANCE_APPROVAL_THRESHOLD_CNY = 7300' src/order-policy.ts
grep -qF 'REQUIRED_FINANCE_APPROVALS = 2' src/order-policy.ts
grep -qF 'Orders totaling CNY 7300 or more require two finance approvals before fulfillment.' docs/business-rules.md
BASH
  chmod +x "$project/scripts/check-project.sh"

  MIGRATION_SOURCES_BEFORE="$(
    cd "$project"
    cksum README.md package.json docs/business-rules.md \
      config/order-policy.yaml src/order-policy.ts tests/order-policy.test.ts \
      scripts/check-project.sh
  )"
  PROMPT='用 SBA 整理这个项目的规则'
}

run_codex() {
  local codex_status
  set +e
  perl -e 'alarm shift; exec @ARGV' "$LIVE_TIMEOUT_SECONDS" \
    "$CODEX_BIN" exec \
      --cd "$project" \
      --sandbox workspace-write \
      --skip-git-repo-check \
      --ephemeral \
      --ignore-user-config \
      --disable plugins \
      --disable remote_plugin \
      --disable plugin_sharing \
      --disable apps \
      --disable browser_use \
      --disable browser_use_external \
      --disable computer_use \
      --disable in_app_browser \
      --disable image_generation \
      --disable memories \
      --disable multi_agent \
      --color never \
      "$PROMPT" \
      </dev/null \
      >"$tmp/codex-output.log" 2>&1
  codex_status=$?
  set -e
  if [[ "$codex_status" -ne 0 ]]; then
    echo "Live Codex $MODE journey exited with status $codex_status" >&2
    sed -n '1,160p' "$tmp/codex-output.log" >&2
    if [[ "$codex_status" -eq 142 ]] || grep -qiE 'stream disconnected|request timed out|authentication required|unauthorized|rate limit|model.*unavailable' "$tmp/codex-output.log"; then
      echo "NO VERDICT: live Agent transport, authentication, or model access was unavailable for the $MODE journey." >&2
      exit 3
    fi
    exit "$codex_status"
  fi
}

verify_single_file_journey() {
  (
    cd "$project"
    bash scripts/check-version.sh 1.2.4
  )
  [[ "$(cksum "$project/AGENTS.md")" == "$AGENTS_BEFORE" ]] || {
    echo "Live Agent changed AGENTS.md outside the requested task" >&2
    exit 1
  }
  [[ "$(cksum "$project/skills/release-helper/SKILL.md")" == "$SKILL_BEFORE" ]] || {
    echo "Live Agent changed the Single-file Skill outside the requested task" >&2
    exit 1
  }
  [[ "$(cksum "$project/scripts/check-version.sh")" == "$CHECK_BEFORE" ]] || {
    echo "Live Agent changed the validation script outside the requested task" >&2
    exit 1
  }
  [[ ! -e "$project/skills/release-helper/routing.yaml" ]] || {
    echo "Live Agent created an unneeded routing.yaml" >&2
    exit 1
  }
  [[ ! -d "$project/skills/release-helper/workflows" ]] || {
    echo "Live Agent created an unneeded workflows directory" >&2
    exit 1
  }

  printf 'PASS: fresh-project natural-language journey updated VERSION through a Single-file Skill\n'
  printf 'NOTE: this proves one live Codex journey, not every harness, prompt, migration, or interruption path.\n'
}

verify_migration_journey() {
  local migration_sources_after
  (
    cd "$project"
    bash scripts/check-project.sh
  )
  migration_sources_after="$(
    cd "$project"
    cksum README.md package.json docs/business-rules.md \
      config/order-policy.yaml src/order-policy.ts tests/order-policy.test.ts \
      scripts/check-project.sh
  )"
  [[ "$migration_sources_after" == "$MIGRATION_SOURCES_BEFORE" ]] || {
    echo "Live Agent changed target source evidence during rule migration" >&2
    exit 1
  }
  [[ -f "$project/skills/$MIGRATION_NAME/SKILL.md" ]] || {
    echo "Live Agent did not materialize skills/$MIGRATION_NAME/SKILL.md" >&2
    exit 1
  }
  grep -R -Fq "$MIGRATION_RULE" "$project/skills/$MIGRATION_NAME" || {
    echo "Live Agent did not migrate the canonical finance-approval rule" >&2
    exit 1
  }
  grep -Fq "skills/$MIGRATION_NAME/SKILL.md" "$project/AGENTS.md" || {
    echo "Live Agent did not integrate the materialized Skill into AGENTS.md" >&2
    exit 1
  }
  [[ -f "$project/skills/$MIGRATION_NAME/scripts/smoke-test.sh" ]] || {
    echo "Live Agent did not materialize the fitted smoke-test owner" >&2
    exit 1
  }
  grep -Fq "skills/$MIGRATION_NAME/scripts/smoke-test.sh" "$tmp/codex-output.log" || {
    echo "Live Agent output does not show the fitted smoke-test invocation" >&2
    exit 1
  }
  grep -Fq -- '--workspace-root' "$tmp/codex-output.log" || {
    echo "Live Agent did not run fitted smoke with --workspace-root" >&2
    exit 1
  }
  (
    cd "$project"
    bash "skills/$MIGRATION_NAME/scripts/smoke-test.sh" "$MIGRATION_NAME" \
      --workspace-root "$project"
  )

  printf 'PASS: ordinary SBA migration inspected target evidence, materialized and activated a Skill, preserved source files, migrated the canonical rule, and ran fitted smoke with --workspace-root\n'
  printf 'NOTE: this proves only the named Codex migration prompt, fixture, workspace, and terminal checks; it does not prove every harness or project migration.\n'
}

case "$MODE" in
  single-file)
    setup_single_file_fixture
    run_codex
    verify_single_file_journey
    ;;
  migration)
    setup_migration_fixture
    run_codex
    verify_migration_journey
    ;;
esac
