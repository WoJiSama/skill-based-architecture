# CODEX.md

Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

<!-- The <always-applicable> and <task-routing> XML tags below are load-bearing.
     Rationale: LLMs parse XML-tag blocks as discrete hard-constraint sections
     more reliably than plain markdown headings, especially after context
     compression. See skill's references/thin-shells.md § XML-Tag Injection. -->

<always-applicable>

**Always Read (every task, in addition to route-specific reads)**

- `skills/{{NAME}}/rules/project-rules.md`
- `skills/{{NAME}}/rules/coding-standards.md`
- `skills/{{NAME}}/rules/agent-behavior.md` — universal behavior defaults (Think / Simplicity / Surgical / Goal-Driven / Three-Strike / Response)

**Route-before-routing check**: if the request contains vague improvement verbs ("refactor / clean up / optimize / make it better / 整理 / 重构 / 优化") **without** a concrete module/file or verifiable outcome → stop and ask for scope. Do not offer partial plans; see `skills/{{NAME}}/protocol-blocks/ambiguous-request-gate.md` if present.

</always-applicable>

The table below lists **additional** reads per task type.

<task-routing>

**Quick Routing (survives context truncation)**

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| Multi-subtask / long run (≥ 3 independent subtasks) | `rules/project-rules.md` | `workflows/subagent-driven.md` |
| <!-- FILL: task --> | <!-- FILL: `rules/<x>.md` --> | <!-- FILL: `workflows/<y>.md` --> |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |

</task-routing>

**New task in same session** → re-read `skills/{{NAME}}/SKILL.md`, re-match Common Tasks route, re-read all required files. "I already read it" is not valid — context compresses, routes differ.

Conflicts → formal docs in `skills/{{NAME}}/` win.
