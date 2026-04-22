---
name: {{NAME}}
description: >
  <!-- FILL: Rewrite as a trigger condition, not a passive summary. -->
  <!-- FILL: Include ≥ 2 quoted trigger phrases the user would actually say. -->
  <!-- FILL: Include concrete activation conditions (not just category labels). -->
  <!-- FILL: After filling, copy the whole description block into .cursor/skills/{{NAME}}/SKILL.md — smoke-test enforces byte-equality. -->
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
3. `rules/agent-behavior.md`

<!-- FILL: keep to 2–3 files max. Domain-specific rules do NOT go here. agent-behavior.md is pre-filled universal defaults (Karpathy) — remove it only if your project explicitly overrides those defaults. -->

## Session Discipline

**Every new task — even the second or third in the same session — must re-read this SKILL.md, re-match the route below, and re-read all files listed for that route.**

- "I already read it earlier" is not valid. Context compresses silently; the new task may match a different route; partial memory is worse than no memory.
- Re-read costs seconds. Skipping costs hours of wrong-direction work.
- This applies to ALL task types, not just bug fixes.

## Common Tasks

Each entry lists the exact files to read — don't read files not listed for your task:

<!-- FILL: add 3–8 real recurring task types for this project, in the format below.
     Format example (DO NOT keep this comment — replace with real tasks):
       Add page → read `rules/frontend-rules.md` + follow `workflows/add-page.md`
       Add API endpoint → read `rules/backend-rules.md` + follow `workflows/add-endpoint.md`; ref: `references/gotchas.md`
     Rule: use real file paths the project will actually have.
     Do NOT use angle-bracket placeholders like `rules/<x>.md` — they fool the smoke-test. -->
- Fix bug → read task-relevant `rules/*.md` + follow `workflows/fix-bug.md`; ref: `references/gotchas.md`
- Multi-subtask / long autonomous run (≥ 3 independent subtasks) → follow `workflows/subagent-driven.md`
- **Other / unlisted task** → read `rules/project-rules.md` + `rules/coding-standards.md`, then match by workflow filename (verb-noun: `add-page.md`, `fix-bug.md`, etc.). If no match, proceed with Always Read rules.

## Known Gotchas

<!-- FILL: brief, scannable list of the most costly pitfalls. Full details in `references/gotchas.md`. Start empty; grows via AAR. -->
- <!-- e.g. Controller X needs Y registered before Z — see `references/gotchas.md#x-registration` -->

## Core Principles

<!-- FILL: List 3–7 principles specific to this project.
     Each principle MUST end with a ✓ Check: sentence — a concrete question the Agent
     can ask itself AFTER execution to verify compliance. Declarative-only principles
     are weaker: they get "remembered" before acting but have no hook to trigger
     post-execution verification.

     The examples below are REALISTIC SHAPES (not your actual principles) —
     replace every one of them with a project-specific rule. Keep the
     "rule + ✓ Check" format; delete these exact lines before shipping. -->

1. **Every change ships with a test** — bug fixes and features both require an automated test that fails before the change and passes after.
   ✓ Check: can you name the new test file or test name added in this commit? If not, the change isn't done.

2. **No cross-layer imports** — UI code never reaches into data-access code directly; all access goes through the service layer.
   ✓ Check: `grep -rn "from '.*\/db" src/components/` returns 0 results.

3. **User-facing error messages are typed, not strings** — every user-visible error comes from an enum or typed error class so translations and telemetry can match on it.
   ✓ Check: does every `throw` / `return error` in this change reference a named error type, not a raw string?

<!-- Delete the three examples above and write your own. Aim for 3–7 principles.
     Patterns that work well: cross-cutting invariants, architectural rules,
     style constraints agents keep violating, project-specific security/perf guards. -->


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
