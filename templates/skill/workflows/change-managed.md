# Change-Managed Workflow

Use this for non-bug changes where partial edits can create drift: new features, refactors, optimizations, route changes, generated/copied files, shared configuration, or any change with multiple derived targets.

## Mandatory Pre-Step (cannot skip)

**Re-run `SKILL.md` § Session Discipline before starting.** Re-match the request against Common Tasks, re-read all required files for that route, and stop for clarification if the request is vague about scope or success criteria.

## Read First

1. Re-open `SKILL.md` → match this change to a Common Tasks route
2. Read `rules/project-rules.md` and task-relevant `rules/*.md`
3. Read task-relevant `references/*.md`, especially any source-of-truth or generated-file notes
4. If the change touches templates, scaffolds, copied shell blocks, generated files, or reusable project structure, switch to `workflows/edit-templates.md` or run its template-specific checks as a sub-step

## Steps

1. **Define scope** — name the exact files/modules owned by this change and the observable outcome that proves it worked.
2. **Find the source of truth** — identify whether the changed content is canonical or derived. If derived, edit the canonical source first and use the project's sync/generation command.
3. **Map fan-out targets** — list every file that must stay in sync before editing. Include thin shells, generated configs, docs indexes, tests, and registration files when relevant.
4. **Make the smallest coherent change** — avoid opportunistic cleanup outside the declared scope.
5. **Sync derived files** — run the project-specific generator, sync script, formatter, or manual copy step required by the source-of-truth mapping.
6. **Run drift checks** — run the project-specific drift/integrity checks. If none exist, compare the fan-out targets manually and consider recording the missing check via Task Closure Protocol.
7. **Validate behavior** — run the most targeted tests, smoke checks, or manual verification for the changed behavior.
8. **Run Task Closure Protocol** from `workflows/update-rules.md` — mandatory before declaring completion.

## Completion Checklist

- [ ] Scope and success criteria are explicit
- [ ] Canonical source vs derived files identified
- [ ] All fan-out targets updated or intentionally left unchanged with a reason
- [ ] Sync/generation step run when derived files exist
- [ ] Drift/integrity check run, or manual comparison completed
- [ ] Targeted validation completed
- [ ] Task Closure Protocol was run

<!-- FILL: project-specific sync/drift commands, for example `bash scripts/sync-*.sh`, `bash scripts/check-*.sh`, codegen, formatters, or schema validators. -->
