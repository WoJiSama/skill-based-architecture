# GEMINI.md

Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

<!-- The <always-applicable> and <task-routing> XML tags below are load-bearing.
     Rationale: LLMs parse XML-tag blocks as discrete hard-constraint sections
     more reliably than plain markdown headings, especially after context
     compression. See skill's references/thin-shells.md § XML-Tag Injection. -->

<always-applicable>

**Always Read (every task, in addition to route-specific reads)**

- `skills/{{NAME}}/rules/project-rules.md`
- `skills/{{NAME}}/rules/coding-standards.md`
- `skills/{{NAME}}/rules/agent-behavior.md` — universal behavior defaults (Think / Simplicity / Surgical / Goal-Driven / Three-Strike)

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

## Auto-Triggers

- **New task in same session** → re-read `skills/{{NAME}}/SKILL.md`, re-match Common Tasks route, re-read all required files for that route. "I already read it" is not valid — context compresses, routes differ.
- Before declaring any non-trivial task complete → run Task Closure Protocol (see `skills/{{NAME}}/workflows/update-rules.md`)
- Skip only for: formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors
- When user asks to "record/save/remember" something → project-level knowledge goes to `skills/{{NAME}}/` docs; personal preferences go to agent memory

## Red Flags — STOP

"Just this once I'll skip the AAR" → stop. See `skills/{{NAME}}/workflows/update-rules.md` § Rationalizations to Reject.
