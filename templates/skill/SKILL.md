---
name: {{NAME}}
version: "1.0"
description: >
  <!-- FILL: Rewrite as a trigger condition, not a passive summary. -->
  <!-- FILL: Include ≥ 2 quoted trigger phrases the user would actually say. -->
  <!-- FILL: Include concrete activation conditions (not just category labels). -->
  This skill should be used when the user asks to "<trigger phrase 1>",
  "<trigger phrase 2>", or "<trigger phrase 3>".
  Activate when <condition 1> or <condition 2>.
primary: true
---

# {{NAME}}

{{SUMMARY}}

## Always Read

These files apply to every task. Read them first:
1. `rules/project-rules.md`
2. `rules/coding-standards.md`

<!-- FILL: keep to 2–3 files max. Domain-specific rules do NOT go here. -->

## Common Tasks

Each entry lists the exact files to read — don't read files not listed for your task:

<!-- FILL: replace these examples with 5–10 real recurring task types for this project. -->
- <task 1> → read `rules/<x>.md` + follow `workflows/<y>.md`
- <task 2> → read `rules/<x>.md` + follow `workflows/<y>.md`; ref: `references/<topic>.md`
- Fix bug → read task-relevant `rules/*.md` + follow `workflows/fix-bug.md`; ref: `references/gotchas.md`
- Multi-subtask / long autonomous run (≥ 3 independent subtasks) → follow `workflows/subagent-driven.md`; dispatch workers using `templates/protocol-blocks/subagent-contract.md`
- **Other / unlisted task** → read `rules/project-rules.md` + `rules/coding-standards.md`, then match by workflow filename (verb-noun: `add-page.md`, `fix-bug.md`, etc.). If no match, proceed with Always Read rules.

## Known Gotchas

<!-- FILL: brief, scannable list of the most costly pitfalls. Full details in `references/gotchas.md`. Start empty; grows via AAR. -->
- <!-- e.g. Controller X needs Y registered before Z — see `references/gotchas.md#x-registration` -->

## Rule Priority
1. `skills/{{NAME}}/SKILL.md`
2. `skills/{{NAME}}/rules/`
3. `skills/{{NAME}}/workflows/`
4. `skills/{{NAME}}/references/`
5. Root `README.md`
6. Thin shells (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`) — compatibility only

## Project Boundaries
<!-- FILL: 2–5 bullets describing what this project owns and does NOT own. -->
- <!-- Boundary 1 -->
- <!-- Boundary 2 -->
