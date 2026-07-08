# Change-Managed Workflow

> **Pervasive reverse-question — default habit**: Before each sub-step, ask "Is watching the whole process redundant for the main agent?" If yes (mechanical + time-consuming + only-need-result) → **directly** `spawn_agent` (global authorization assumed), main conversation only sees the result. See [`subagent-driven.md` § Mode 1: Direct Auxiliary Delegation](subagent-driven.md#mode-1-direct-auxiliary-delegation). **Not limited to specific list**; if planned as fanout refactor from start, go to [`refactor-fanout.md`](refactor-fanout.md) directly.

Use this for non-bug changes where partial edits can create drift: new features, refactors, optimizations, route changes, generated/copied files, shared configuration, or any change with multiple derived targets.

## Mandatory Pre-Step (cannot skip)

**Re-run `SKILL.md` § Session Discipline before starting.** Re-match the request against Common Tasks; re-read the route's files only if the route changed or context was compacted (see § Session Discipline); stop for clarification if the request is vague about scope or success criteria.

## Read First

1. Re-open `SKILL.md` → match this change to a Common Tasks route
2. Read `rules/project-rules.md` and task-relevant `rules/*.md`
3. Read task-relevant `references/*.md`, especially any source-of-truth or generated-file notes
4. If the change touches templates, scaffolds, copied shell blocks, generated files, or reusable project structure, switch to `workflows/edit-templates.md` or run its template-specific checks as a sub-step

## Steps

1. **Define scope** — name the exact files/modules owned by this change and the observable outcome that proves it worked. **Permission check (opt-in):** if the project uses a permission model, decide up front whether this is an *Ask-first* operation (crosses a contract, hard to reverse, blast radius beyond the task) → propose and stop for the user before editing; or *Never* → refuse. This is a **pre-execution authority** check — distinct from the **post-edit** blast-radius buckets in [`task-closure.md`](task-closure.md) (which gauge closure rigor, not permission). See [`../references/permission-model.md`](../references/permission-model.md).
2. **Find the source of truth** — identify whether the changed content is canonical or derived. If derived, edit the canonical source first and use the project's sync/generation command.
3. **Map fan-out targets** — list every file that must stay in sync before editing. Include thin shells, generated configs, docs indexes, tests, and registration files when relevant. **Before starting batch edits**, ask the reverse-question "主 agent 逐个文件改这堆同型编辑是多余的吗?" — if yes (typical when ≥ 5 files need the same-shape edit), see [`subagent-driven.md` § Mode 1: Direct Auxiliary Delegation](subagent-driven.md#mode-1-direct-auxiliary-delegation) signal #4 to optionally dispatch a refactor subagent. If the fan-out shape was planned from the start (not surfaced mid-task), go to [`refactor-fanout.md`](refactor-fanout.md) instead.
4. **Make the smallest coherent change** — avoid opportunistic cleanup outside the declared scope.
5. **Sync derived files** — run the project-specific generator, sync script, formatter, or manual copy step required by the source-of-truth mapping.
6. **Run drift checks** — run the project-specific drift/integrity checks. If none exist, compare the fan-out targets manually and consider recording the missing check via Task Closure Protocol.
7. **Validate behavior** — run the most targeted tests, smoke checks, or manual verification for the changed behavior.
8. **Run Task Closure Protocol** from `workflows/task-closure.md` — mandatory before declaring completion.

## Completion Checklist

- [ ] Scope and success criteria are explicit
- [ ] Canonical source vs derived files identified
- [ ] All fan-out targets updated or intentionally left unchanged with a reason
- [ ] Sync/generation step run when derived files exist
- [ ] Drift/integrity check run, or manual comparison completed
- [ ] Targeted validation completed
- [ ] Task Closure Protocol was run

<!-- OPTIONAL: project-specific sync/drift commands, for example `bash scripts/sync-*.sh`, `bash scripts/check-*.sh`, codegen, formatters, or schema validators. Also declare the cheapest-sufficient validation path (e.g. hot-reload dev server instead of a full production build) and the conditions that escalate to the expensive one (release evidence, cross-module contract change, build-chain edits). -->
