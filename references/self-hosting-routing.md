# Self-Hosting Routing Block

This file is the canonical source for the root thin-shell routing block in this self-hosting repository. Edit this file first, then run `bash scripts/sync-self-routing.sh`.

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

## Sync Targets

- `AGENTS.md`
- `CLAUDE.md`
- `CODEX.md`
- `GEMINI.md`
- `.codex/instructions.md`
- `.cursor/rules/workflow.mdc`
- `.cursor/skills/skill-based-architecture/SKILL.md`

## Update Protocol

1. Edit the block between `SELF_ROUTING_BLOCK_START` and `SELF_ROUTING_BLOCK_END` above.
2. Run `bash scripts/sync-self-routing.sh`.
3. Run `bash scripts/check-self-routing.sh`.
4. Run the relevant smoke or syntax checks before closing the task.

Do not hand-edit copied Quick Routing tables in target files. Local text before or after the generated block may remain harness-specific.
