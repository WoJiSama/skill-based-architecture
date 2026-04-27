# GEMINI.md

This repo is the **skill-based-architecture** meta-skill itself. Formal docs live at the repo root (self-hosting layout). Read [SKILL.md](SKILL.md) first — it is the router.

<!-- SELF_ROUTING_BLOCK_START -->
## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Migrate a downstream project's rules to skill-based architecture | `SKILL.md` + `WORKFLOW.md` | Follow `WORKFLOW.md` Quick Start + 9 phases |
| Edit or extend `templates/` (shells / hooks / protocol-blocks / skill) | `SKILL.md` + `templates/README.md` + `templates/ANTI-TEMPLATES.md` | Follow "结构可复用,内容禁止预制" rule |
| Add or revise a skill design principle in `SKILL.md` | `SKILL.md` + `references/layout.md` | Keep ≤ 100 lines; every principle needs a `✓ Check:` sentence |
| Add or revise a reference doc | `SKILL.md` + `references/README.md` | Keep topic-focused, link from SKILL.md |
| Add an example (before/after, scenario, behavior failure) | `examples/README.md` | Place in correct sub-file (migration / project-types / self-evolution / behavior-failures) |
| Fix a bug in scripts or templates | `SKILL.md` + `templates/skill/scripts/smoke-test.sh` | Run smoke-test before and after |
| Multi-subtask / long autonomous run (≥ 3 independent subtasks) | `SKILL.md` | Dispatch via `templates/protocol-blocks/subagent-contract.md` |
| Other | `SKILL.md` | Scan `WORKFLOW.md` for closest phase |
<!-- SELF_ROUTING_BLOCK_END -->

## Auto-Triggers

- **New task in same session** → re-read `SKILL.md`, re-match the route above, re-read all required files.
- Before declaring any non-trivial task complete → run Task Closure Protocol (see `templates/skill/workflows/update-rules.md` § Task Closure Protocol + § Rationalizations to Reject)
- Skip only for: formatting-only, comment-only, dependency-version-only, behavior-preserving refactors
- When adding to `templates/` → apply the "would two real projects disagree?" admission test (`templates/ANTI-TEMPLATES.md`)

## Red Flags — STOP

- "Just this once I'll skip the AAR" → stop.
- "I'll inline this in SKILL.md instead of linking a reference" → stop. SKILL.md stays ≤ 100 lines; content goes to `references/` or `templates/`.
- "Let me pre-fill a gotchas example so the template feels complete" → stop. `templates/ANTI-TEMPLATES.md` forbids project-specific content in templates.
