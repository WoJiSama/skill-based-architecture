#!/usr/bin/env bash
# Run the upstream repo's full maintenance check suite.

set -euo pipefail

MODE="worktree"
BASE="${UPSTREAM_CHANGES_BASE:-HEAD}"

usage() {
  cat <<'EOF'
Usage: scripts/check-all.sh [--base <git-ref>] [--staged]

Runs the self-hosting upstream maintenance checks used before commit/push:
  - upstream change-note guard
  - template routing manifest check
  - self-hosting routing/activation check
  - whitespace diff check
  - description routing check
  - growth health report
  - template and self-hosting route-path activation reports
  - self-hosting scenario checks
  - external-fact freshness check
  - self-hosting phase 7 smoke test
  - orphan reference audit
  - template content conformance (downstream contract)
  - self-hosting content conformance (upstream-canon)

Default mode checks the working tree. Use --staged from a pre-commit hook to
check the pending commit for UPSTREAM-CHANGES.md coverage and whitespace.
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

if [[ "$MODE" == "staged" ]]; then
  run "upstream change-note guard (staged)" bash scripts/check-upstream-changes.sh --base "$BASE" --staged
  run "whitespace diff check (staged)" git diff --cached --check
else
  run "upstream change-note guard" bash scripts/check-upstream-changes.sh --base "$BASE"
  run "whitespace diff check" git diff --check
fi

run "template routing manifest check" bash templates/skill/scripts/sync-routing.sh templates/skill --check
run "self-hosting routing and activation check" bash scripts/check-self-routing.sh
run "description routing check" bash templates/skill/scripts/check-description-routing.sh .
run "growth health report" bash templates/skill/scripts/check-growth-health.sh .
run "template route-path activation report" bash templates/skill/scripts/audit-route-paths.sh templates/skill
run "self-hosting route-path activation report" bash templates/skill/scripts/audit-route-paths.sh . --manifest references/self-hosting-routing.yaml
run "self-hosting scenario checks" bash scripts/check-self-scenarios.sh
run "external fact freshness check" bash templates/skill/scripts/check-external-facts.sh .
run "self-hosting phase 7 smoke test" bash templates/skill/scripts/smoke-test.sh skill-based-architecture --phase 7
run "reference orphan audit" bash templates/skill/scripts/audit-references.sh --orphans
run "template content conformance" bash templates/skill/scripts/check-version-conformance.sh templates/skill
run "self-hosting content conformance" bash templates/skill/scripts/check-version-conformance.sh . --conformance references/self-hosting-conformance.yaml

printf '\nAll upstream maintenance checks passed.\n'
