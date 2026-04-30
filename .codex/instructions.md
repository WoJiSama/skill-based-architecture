# Codex Instructions

This repo is the **skill-based-architecture** meta-skill. Formal docs live at the repo root (self-hosting layout). Read [SKILL.md](../SKILL.md) first.

<!-- SELF_ROUTING_BLOCK_START -->
## Quick Routing (survives context truncation)

Task routes live in `references/self-hosting-routing.yaml`.

For every new task:
1. Read `SKILL.md`.
2. Read `references/self-hosting-routing.yaml`.
3. Match by `labels`, `trigger_examples`, and task intent.
4. Read only that route's `required_reads`, then follow its `workflow`.
5. If no route matches, use the `other` route.
<!-- SELF_ROUTING_BLOCK_END -->

## Auto-Triggers

- **New task in same session** → re-read `SKILL.md`, re-match the route above, re-read all required files. "I already read it" is not valid — context compresses, routes differ.
- Before declaring any non-trivial task complete → run Task Closure Protocol (see `templates/skill/workflows/update-rules.md` § Task Closure Protocol + § Rationalizations to Reject)
- Skip only for: formatting-only, comment-only, dependency-version-only, behavior-preserving refactors
- When adding to `templates/` → apply the "would two real projects disagree?" admission test (`templates/ANTI-TEMPLATES.md`)

## Codex-specific notes

- When executing `WORKFLOW.md` phases, prefer sequential edits over bulk rewrites (Codex's `apply_patch` works best on focused diffs).
- When modifying `templates/`, run `bash templates/skill/scripts/smoke-test.sh <test-name>` against a sample target before declaring completion.
