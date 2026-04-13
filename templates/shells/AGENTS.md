# AGENTS.md

{{SUMMARY}}

Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| Multi-subtask / long run (≥ 3 independent subtasks) | `rules/project-rules.md` | `workflows/subagent-driven.md` |
| <!-- FILL: task --> | <!-- FILL: `rules/<x>.md` --> | <!-- FILL: `workflows/<y>.md` --> |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |

## Auto-Triggers

- **New task in same session** → re-read `skills/{{NAME}}/SKILL.md`, re-match Common Tasks route, re-read all required files for that route. "I already read it" is not valid — context compresses, routes differ.
- Before declaring any non-trivial task complete → run Task Closure Protocol (see `skills/{{NAME}}/workflows/update-rules.md`)
- Skip only for: formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors
- When user asks to "record/save/remember" something → project-level knowledge goes to `skills/{{NAME}}/` docs; personal preferences go to agent memory

## Red Flags — STOP

If you catch yourself thinking "just this once I'll skip the AAR", stop. See `skills/{{NAME}}/workflows/update-rules.md` § Rationalizations to Reject.
