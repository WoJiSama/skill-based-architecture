# Fix Bug Workflow

## Read First

1. `rules/project-rules.md`
2. `rules/coding-standards.md`
3. Task-relevant `rules/*.md`
4. Task-relevant `references/*.md` (especially `references/gotchas.md`)

## Steps

1. Restate the bug scope and affected behavior
2. Read the minimum necessary files — do not read files unrelated to the symptom
3. Identify the root cause — not the first plausible cause, the actual one
4. Implement the smallest correct fix — no "while we're here" cleanups
5. Validate behavior (tests pass, manual reproduction no longer triggers the bug)
6. **Run Task Closure Protocol** from `workflows/update-rules.md` — mandatory, not optional
7. If the recording threshold passes, update the appropriate `rules/`, `references/`, or `workflows/` file before ending the task
8. Records must pass the generalization check — write as reusable knowledge, not project-specific narratives
9. If the lesson is costly and task-relevant, also activate it in workflow/routing, not only store in `references/`

## Completion Checklist

- [ ] Root cause identified (not just a plausible-looking fix)
- [ ] Code fix verified (tests pass, manual repro clean)
- [ ] Task Closure Protocol was run (AAR scan completed before declaring task done)
- [ ] Recording threshold checked
- [ ] If threshold passed, record passes generalization check and docs updated
- [ ] If the lesson was costly and task-relevant, it was activated in workflow/routing, not only stored in `references/`

<!-- FILL: add project-specific validation steps here — e.g. specific test suites to run, linters, smoke tests. -->
