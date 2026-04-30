# GEMINI.md

Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

Conflicts between loaded project instructions → formal docs in `skills/{{NAME}}/` win. This does not override harness-native skill name precedence.

<!-- The <always-applicable> and <task-routing> XML tags below are load-bearing.
     Rationale: LLMs parse XML-tag blocks as discrete hard-constraint sections
     more reliably than plain markdown headings, especially after context
     compression. See skill's references/thin-shells.md § XML-Tag Injection. -->

<always-applicable>

**Always Read (every task, in addition to route-specific reads)**

<!-- ALWAYS_READ_START -->
- `skills/{{NAME}}/rules/project-rules.md`
- `skills/{{NAME}}/rules/coding-standards.md`
- `skills/{{NAME}}/rules/agent-behavior.md`
<!-- ALWAYS_READ_END -->

**Route-before-routing check**: if the request contains vague improvement verbs ("refactor / clean up / optimize / make it better / 整理 / 重构 / 优化") **without** a concrete module/file or verifiable outcome → stop and ask for scope. Do not offer partial plans; see `skills/{{NAME}}/protocol-blocks/ambiguous-request-gate.md` if present.

</always-applicable>

Route metadata lives in `skills/{{NAME}}/routing.yaml`; the bootstrap below tells agents how to match it.

<task-routing>

**Quick Routing (survives context truncation)**

<!-- ROUTING_BOOTSTRAP_START -->
Task routes live in `skills/{{NAME}}/routing.yaml`.

For every new task:
1. Read `skills/{{NAME}}/routing.yaml`.
2. Match by `labels`, `trigger_examples`, and task intent.
3. Read only that route's `required_reads` plus Always Read files.
4. Follow that route's `workflow`.
5. If no route matches, use the `other` route.
<!-- ROUTING_BOOTSTRAP_END -->

</task-routing>

## Auto-Triggers

- **New task in same session** → re-read `skills/{{NAME}}/SKILL.md`, re-match Common Tasks route, re-read all required files for that route. "I already read it" is not valid — context compresses, routes differ.
- Before declaring any non-trivial task complete → run Task Closure Protocol (see `skills/{{NAME}}/workflows/update-rules.md`)
- Skip only for: formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors
- When user asks to "record/save/remember" something → project-level knowledge goes to `skills/{{NAME}}/` docs; personal preferences go to agent memory

## Red Flags — STOP

"Just this once I'll skip the AAR" → stop. See `skills/{{NAME}}/workflows/update-rules.md` § Rationalizations to Reject.
