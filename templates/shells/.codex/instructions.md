Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

## Always Read (every task, in addition to route-specific reads)

<!-- ALWAYS_READ_START -->
- `skills/{{NAME}}/rules/project-rules.md`
- `skills/{{NAME}}/rules/coding-standards.md`
- `skills/{{NAME}}/rules/agent-behavior.md`
<!-- ALWAYS_READ_END -->

## Quick Routing (survives context truncation)

<!-- ROUTING_BOOTSTRAP_START -->
Task routes live in `skills/{{NAME}}/routing.yaml`.

For every new task:
1. Read `skills/{{NAME}}/routing.yaml`.
2. Match by `labels`, `trigger_examples`, and task intent.
3. Read only that route's `required_reads` plus Always Read files.
4. Follow that route's `workflow`.
5. If no route matches, use the `other` route.
<!-- ROUTING_BOOTSTRAP_END -->

**New task in same session** → re-read `skills/{{NAME}}/SKILL.md`, re-match Common Tasks route, re-read all required files. "I already read it" is not valid — context compresses, routes differ.

Conflicts between loaded project instructions → formal docs in `skills/{{NAME}}/` win. This does not override harness-native skill name precedence.
