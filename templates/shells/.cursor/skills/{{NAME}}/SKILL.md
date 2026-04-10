---
name: {{NAME}}
version: "1.0"
description: >
  <!-- FILL: MUST MATCH the description in skills/{{NAME}}/SKILL.md exactly. -->
  This skill should be used when the user asks to "<trigger phrase 1>",
  "<trigger phrase 2>", or "<trigger phrase 3>".
  Activate when <condition 1> or <condition 2>.
---

# {{NAME}} (Cursor Entry)

Formal skill content lives at `skills/{{NAME}}/SKILL.md`.
**Read that file immediately, then follow its Always Read list and Common Tasks routing.**

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| Multi-subtask / long run (≥ 3 independent subtasks) | `rules/project-rules.md` | `workflows/subagent-driven.md` |
| <!-- FILL: task --> | <!-- FILL: `rules/<x>.md` --> | <!-- FILL: `workflows/<y>.md` --> |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |
