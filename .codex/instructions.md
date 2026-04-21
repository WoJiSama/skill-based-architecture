# Codex Instructions

This repo is the **skill-based-architecture** meta-skill. Formal docs live at the repo root (self-hosting layout). Read [SKILL.md](../SKILL.md) first.

See [CODEX.md](../CODEX.md) for the shared thin-shell routing table and auto-triggers.

## Codex-specific notes

- When executing `WORKFLOW.md` phases, prefer sequential edits over bulk rewrites (Codex's `apply_patch` works best on focused diffs).
- When modifying `templates/`, run `bash templates/skill/scripts/smoke-test.sh <test-name>` against a sample target before declaring completion.
