---
name: skill-based-architecture
description: >
  This skill should be used when the user asks to "organize the project rules",
  "clean up scattered documentation", "refactor project rules",
  "consolidate scattered rules", "create skill-based architecture",
  "restructure skill documentation", or "migrate rules to skills directory".
  Activate when a SKILL.md exceeds ~150 lines, rules are duplicated across
  multiple entry files (AGENTS.md, .cursor/rules/, CLAUDE.md, etc.),
  documentation feels hard to navigate or maintain, or the user requests
  rule consolidation or documentation cleanup.
primary: true
---

# skill-based-architecture (Cursor Registration Entry)

**This is the Cursor discovery entry.** Formal skill content lives at the repo root — read [SKILL.md](../../../SKILL.md) immediately, then follow its design principles and workflow routing.

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Migrate a downstream project's rules to skill-based architecture | `SKILL.md` + `WORKFLOW.md` | Follow `WORKFLOW.md` Quick Start + 9 phases |
| Edit or extend `templates/` | `SKILL.md` + `templates/README.md` + `templates/ANTI-TEMPLATES.md` | "结构可复用,内容禁止预制" |
| Add or revise a skill design principle in `SKILL.md` | `SKILL.md` + `references/layout.md` | ≤ 100 lines; every principle needs `✓ Check:` |
| Fix a bug in scripts or templates | `SKILL.md` + `templates/skill/scripts/smoke-test.sh` | Run smoke-test before and after |
| Other | `SKILL.md` | Scan `WORKFLOW.md` for closest phase |

## Why this file exists

Cursor's `agent_skill` mechanism only scans `.cursor/skills/`. Without this registration entry, the formal skill at repo root is invisible to Cursor.

The `description` above **must stay identical** to the root [SKILL.md](../../../SKILL.md) `description` field. Drift between the two = Cursor uses one activation rule while other harnesses use another. `templates/skill/scripts/smoke-test.sh` automatically verifies they match.
