# Fix Bug Workflow

## Mandatory Pre-Step (cannot skip)

**Re-run `SKILL.md` § Session Discipline before starting.** Re-match this bug against Common Tasks, re-read all required files for that route. No exceptions — see SKILL.md for why.

## Read First

1. Re-open `SKILL.md` → match this bug to a Common Tasks route
2. Read **all** files listed for that route (not just the ones you remember)
3. Read task-relevant `references/*.md` (especially `references/gotchas.md`)

## Steps

1. Restate the bug scope and affected behavior
2. Read the minimum necessary files — do not read files unrelated to the symptom
3. Identify the root cause — not the first plausible cause, the actual one
4. Implement the smallest correct fix — no "while we're here" cleanups
5. Run Fix Impact Analysis — confirm the change did not silently break callers, data flow, or compatibility
6. Validate behavior (tests pass, manual reproduction no longer triggers the bug)
7. **Run Task Closure Protocol** from `workflows/update-rules.md` — mandatory, not optional
8. If the recording threshold passes, update the appropriate `rules/`, `references/`, or `workflows/` file before ending the task
9. Records must pass the generalization check — write as reusable knowledge, not project-specific narratives
10. If the lesson is costly and task-relevant, also activate it in workflow/routing, not only store in `references/`

## Fix Impact Analysis

Before final validation, inspect the actual diff and answer:

1. **Direct impact** — Which callers use the changed function/method/component? Did any parameter signature, return type, response shape, or error behavior change?
2. **Indirect impact** — Does the fix alter upstream/downstream data flow, shared state, global config, cache behavior, event timing, listeners, callbacks, or async ordering?
3. **Data compatibility** — If fields were added, removed, renamed, or changed type, do old data, persisted data, API consumers, and fallback/default paths still work?
4. **Blast-radius validation** — Which targeted tests, compile checks, type checks, or manual smoke paths cover the affected callers and compatibility assumptions?

If any answer is unknown, inspect the relevant callers or data contracts before declaring the fix safe.

## Completion Checklist

- [ ] Root cause identified (not just a plausible-looking fix)
- [ ] Fix Impact Analysis completed against the actual diff
- [ ] Direct callers and changed signatures/return shapes checked
- [ ] Indirect data flow, shared state, events, callbacks, and async timing considered
- [ ] Data compatibility checked for added/removed/renamed/type-changed fields
- [ ] Code fix verified (tests pass, manual repro clean)
- [ ] Task Closure Protocol was run (AAR scan completed before declaring task done)
- [ ] Recording threshold checked
- [ ] If threshold passed, record passes generalization check and docs updated
- [ ] If the lesson was costly and task-relevant, it was activated in workflow/routing, not only stored in `references/`

<!-- FILL: add project-specific validation steps here — e.g. specific test suites to run, linters, smoke tests. -->
