# Rule Update Workflow

## Classification Guide

- Long-lived, must-follow constraints → `rules/`
- Task procedures with ordered steps → `workflows/`
- Architecture, routing, dependency explanations → `references/`
- External-facing material → `docs/`

## Sync Targets

| Change type | Files to update |
|---|---|
| New/renamed workflow or reference file | `SKILL.md` Common Tasks routing |
| UI convention / host compatibility / overlay layering / z-index / styling behavior issue that future agents would guess wrong without docs | Update the relevant `rules/*.md` or `references/*.md`, and update `SKILL.md` summary if the pitfall should surface earlier |
| <!-- FILL: project-specific trigger → target file --> | <!-- FILL --> |

Threshold: if this change would cause someone to guess wrong on a similar task without reading the docs, update. Otherwise skip.

> **The trigger table itself is a living document:** when you discover a new change-to-update mapping, add it to this table.

## Task Closure Protocol

A task is NOT complete until all three steps are done:

1. **Main work** — implementation done, verified, tests pass
2. **30-second AAR scan** — run the 4-question checklist below; all "no" = stop here
3. **Record if needed** — any "yes" → apply recording threshold → record if it passes

No workflow may declare completion without step 2. This is mandatory, not an optional add-on.

### Rationalizations to Reject

When the Agent feels the urge to skip the AAR, these are the common excuses and their rebuttals. Every row was captured from a real pressure-test failure — do not argue with them, just refuse.

| Rationalization | Reality |
|---|---|
| "This task was small — AAR is overkill" | Small tasks are where lessons hide. The 4-question scan takes 30 seconds; skipping it is slower than doing it |
| "I'll run AAR at the end of the session" | You will forget. The scan must happen at task closure, not batched |
| "Nothing new happened, just a routine fix" | If nothing new happened, the scan returns "no" on all four questions in 30 seconds. Do it anyway |
| "The user is in a hurry" | The protocol exists *because* hurry produces the worst pitfalls. Pressure is a reason to run AAR, not skip it |
| "I already know this lesson, don't need to record" | Recording is for future agents, not past you. Current knowledge is not durable |
| "This is covered by the existing rules" | Then the scan returns "no" in 10 seconds. Faster to run it than argue about it |

### Red Flags — STOP if you catch yourself thinking any of these

- "Just this once" — every skip erodes the protocol
- "I'll fix it in the next task" — the next task will have its own closure
- "Nobody will know I skipped" — the next pitfall will
- "The AAR is for big changes" — scope does not determine value; novelty does
- "This is overhead, not work" — Task Closure *is* the task; anything that ships without it is half-done

## After-Action Review

The 30-second scan from step 2 of the Task Closure Protocol.

Skip only for: formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors.

Checklist:

- [ ] **New pattern** — Did this task use an undocumented pattern or convention?
- [ ] **New pitfall** — Did you hit a problem that wastes significant time if you don't know about it upfront?
- [ ] **Missing rule** — Did the absence of a rule cause you to take a wrong turn?
- [ ] **Outdated/obsolete rule** — Did you find an existing rule that is inaccurate or no longer applicable?

If any answer is "yes", apply the recording threshold before writing anything down. If all answers are "no", stop here. The review should stay lightweight, but it is still part of task closure.

### Recording Threshold

Before recording a potential new piece of knowledge, ask:

1. **Will it recur?** — Is this likely to come up again in future tasks, or is it a one-off?
2. **Is the cost high?** — How much time would someone waste not knowing this? A few minutes of trial-and-error isn't worth a rule; 30+ minutes of debugging is.
3. **Is it obvious from the code?** — Can someone read the code and immediately understand this? If yes, don't document it separately.

**At least 2 of 3 must be "yes / high / no" → worth recording. Otherwise skip.**

### Where To Record

- Stable constraint or convention → `rules/`
- Pitfall, architecture note, lifecycle gotcha, source index → `references/`
- Ordered task step or completion check → `workflows/`
- Task routing changed → `SKILL.md`
- Entry routing changed → thin shells (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`)

### Recording Destination (user-initiated recording)

When the user explicitly asks to "record this" or "remember this", decide the destination first:

- **Project-level knowledge** (would help a different agent on this project) → `skills/{{NAME}}/references/`, `rules/`, or `workflows/`
- **Personal preference** (only relevant to this specific user) → agent's own memory system (e.g. `~/.claude/.../memory/`)

Default to skill docs. Most explicit recording requests during development are project-scoped.

For UI / interaction / layering / host-compatibility issues:

- Long-lived team convention or preferred implementation pattern → `rules/`
- Compatibility pitfall, debugging lesson, layering trap, or non-obvious failure mode → `references/`

### Activation Check

If the lesson is both **costly** and **task-relevant**, don't stop at storing it in `references/`.

Ask:

1. Would a future agent naturally read this reference during the same task type?
2. If not, should this also change a workflow checklist, `SKILL.md` Common Tasks routing, or a concise rule summary?

High-cost pitfalls are only considered fully captured when they are both:

- **stored** in the right formal doc, and
- **activated** in the task path that should prevent the mistake next time

### When NOT to Record

- One-off workarounds (only relevant to this specific bug, won't recur)
- Things immediately obvious from reading the code (e.g. "this function takes two parameters")
- Minor personal preferences (e.g. "I think this variable name is bad")
- Content already clearly documented in official framework docs (don't copy official docs into rules)

### Recording Format

Not everything worth recording needs a full section. Choose the lightest format:

| Content size | Format |
|---|---|
| One sentence | Append a bullet point to an existing section |
| 3–5 lines of explanation | Append a short paragraph to an existing file |
| 10+ lines with distinct steps | Consider whether a new file is warranted (usually not) |

**Prefer appending to existing files over creating new ones.**

### Generalization Rule

Records must be reusable knowledge, not project-specific narratives. A record should make sense even if moved to a different project of the same type.

**Check:** if the record mentions a specific module name, business term, or variable name without an abstract explanation, rewrite it.

**Pattern:** `specific finding → abstract as general pattern → state the consequence of not following it`

## Learn from Mistakes

When an error occurs during a task and is corrected:

1. **Search first** — before concluding a rule is missing, search existing rule files (`rules/`, `workflows/`, `references/`) to confirm the rule doesn't already exist. If it exists but was missed, the root cause is "rule not followed" or "rule not prominent enough", not "missing rule".
2. Identify root cause: missing rule / outdated rule / obsolete rule / rule exists but wasn't followed?
3. **Missing rule** → apply recording threshold (will it recur? high cost?); if it passes, add to the appropriate file
4. **Outdated rule** → update the rule content directly (an outdated rule is more harmful than a missing one — no threshold needed)
5. **Obsolete rule** → follow the Rule Deprecation process below
6. **Rule not followed** → check if the rule is prominent enough; consider moving it to Always Read or bolding key constraints

## Rule Deprecation

Rules that only grow and never shrink lead to bloated documentation. Remove or mark as deprecated when:

- The related technology or dependency has been removed from the project
- The project architecture has changed and the rule's premise no longer holds
- The pitfall described has been fixed in a newer version of the framework or tool

Deprecation steps:

1. **Confirm the premise has changed** — not "I don't think we need this" but "the technology/pattern this rule depends on is gone"
2. **Fully obsolete** → delete the entry or file
3. **Partially obsolete** → keep the rule but scope it with a clear header indicating the legacy surface; delete when the last legacy usage is migrated
4. **If unsure** → annotate with `<!-- DEPRECATED: reason, date -->` and revisit later
5. **Update references** — if an entire file is deleted, update SKILL.md and the sync trigger table

## Post-Update Health Check

After completing rule updates, check the line count of modified files. If any exceed the healthy range, evaluate whether splitting is needed using the `maintain-docs.md` judgment process — **exceeding the threshold does not mean you must split**; a long file with a single coherent topic can stay as-is.

## Completion Criteria

- Formal rules maintained in exactly one place
- Entry files contain only navigation and summaries
- Sync trigger table includes any newly discovered mappings
- Obsolete rules have been removed or marked
- Recording threshold was checked for every substantive task that triggered this workflow
- If the threshold passed, the appropriate file was updated before task closure
- If the lesson was costly and task-relevant, it was also surfaced in workflow/routing instead of living only in `references/`
