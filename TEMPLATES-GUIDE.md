# Meta-Workflow Templates (Guide)

> **Heads up — read this before copying code blocks below:**
> This file is a **guide** with annotated examples. The authoritative, byte-for-byte copyable files live in **[`templates/`](templates/)** (directory, lowercase). When the two drift, `templates/` wins.
>
> - Need a file to copy verbatim? → `templates/skill/…`, `templates/shells/…`, `templates/protocol-blocks/…`
> - Need to understand *why* a template looks the way it does? → keep reading here.
> - Not sure which to use? → always prefer `templates/` for copying, this doc for background.

Project-level workflow templates for rule maintenance and documentation health. Copy and customize for each project.

## Minimal Starter Template

Use this when a project has only one small skill and does **not** yet need the full `skills/<name>/rules|workflows|references` split.

```md
---
name: <project-name>
description: >
  This skill should be used when the user asks within this skill's domain, such as
  "<trigger phrase 1 in real user language>", "<trigger phrase 2>", or "<trigger phrase 3>".
  Activate when <condition 1> or <condition 2>.
---

# <Project Name>

One-line summary.

## Always Read
1. `<core-file-or-section>`

## Common Tasks
- Main task → read `<core-file-or-section>` and follow `<closest workflow or section>`
- Other → use the guidance above and keep edits minimal
```

Start here when:

- the skill is still short and self-contained
- rules are not duplicated across multiple entry files
- there is no strong need yet for separate `rules/`, `workflows/`, and `references/`

Upgrade to the full skill-based directory only when the single file starts to sprawl, duplicates appear, or knowledge needs active maintenance.

## update-rules.md Enhanced Template

Every project should have this workflow. It combines rule sync, active learning, deprecation, and health-check triggers, and it acts as the shared documentation exit path at task closure.

```md
# Rule Update Workflow

## Classification Guide

- Long-lived, must-follow constraints → `rules/`
- Task procedures with ordered steps → `workflows/`
- Architecture, routing, dependency explanations → `references/`
- External-facing material → `docs/`

## Sync Targets

| Change type | Files to update |
|---|---|
| New/renamed workflow or reference file | `routing.yaml`, then `scripts/sync-routing.sh` |
| UI convention / host compatibility / overlay layering / z-index / styling behavior issue that future agents would guess wrong without docs | Update the relevant `rules/*.md` or `references/*.md`, and update `SKILL.md` summary if the pitfall should surface earlier |
| (project-specific triggers) | (corresponding files) |

Threshold: if this change would cause someone to guess wrong on a similar task without reading the docs, update. Otherwise skip.

> **The trigger table itself is a living document:** when you discover a new change-to-update mapping, add it to this table.

## Task Closure Protocol

A task is NOT complete until all six gates are done:

1. **Main work + original-constraint check** — before final validation, restate the original request, chosen route, and forbidden shortcuts; if the task was long/interrupted and you cannot, run `protocol-blocks/reboot-check.md`, then verify/tests pass
2. **30-second AAR scan** — run the checklist below; all "no" = stop here
3. **Record if needed** — any "yes" → apply recording threshold → record if it passes
4. **Path integrity gate** — if this task touched any `.md` file, both checks must pass *before commit*. Run these from the project repo root unless noted:
   - `bash "skills/<skill-name>/scripts/smoke-test.sh" "<skill-name>" --phase 8` — verifies every relative `[text](path)` link resolves (Section 8: Broken Link Check) plus all earlier structural/routing/budget checks
   - `(cd "skills/<skill-name>" && bash scripts/audit-references.sh --orphans)` — verifies no `rules/` or `references/` file is unreachable from any inbound link
   - These together are the missing "compile-time" check for markdown links — partial path edits leave dangling references that rot silently otherwise
5. **Cross-reference content sync** — if this task changed the *meaning* of a `rules/` or `references/` file (not just paths), grep `workflows/` for files that reproduce the changed invariant and update them in the same commit
6. **External fact freshness** — if the edit adds or changes a claim about an external tool, framework, hosted service, API, model, CLI, or official behavior, verify against the primary source, add or refresh `<!-- external-fact: verified=YYYY-MM-DD source=https://official.example/docs -->`, then run `scripts/check-external-facts.sh`

No workflow may declare completion without step 2. Steps 3–6 fire conditionally (3 on AAR hits, 4 on any `.md` edit, 5 on rules/references meaning changes, 6 on external facts) and are mandatory when their trigger fires.

### Rationalizations to Reject

When the Agent feels the urge to skip steps 2–6, these are the common excuses and their rebuttals. Every row was captured from a real pressure-test failure (see [WORKFLOW.md § Phase 9](WORKFLOW.md#phase-9-pressure-test-the-skill)) — do not argue with them, just refuse.

| Rationalization | Reality |
|---|---|
| "This task was small — AAR is overkill" | Small tasks are where lessons hide. The AAR scan takes 30 seconds; skipping is slower than doing |
| "I'll run AAR at the end of the session" | You will forget. The scan must happen at task closure, not batched |
| "Nothing new happened, just a routine fix" | If nothing new happened, the scan returns "no" on all four questions in 30 seconds. Do it anyway |
| "The user is in a hurry" | The protocol exists *because* hurry produces the worst pitfalls. Pressure is a reason to run AAR, not skip it |
| "I already know this lesson, don't need to record" | Recording is for future agents, not past you. Current knowledge is not durable across context boundaries |
| "This is covered by the existing rules" | Then the scan returns "no" in 10 seconds. Faster to run it than argue about it |
| "I only renamed one file, links are probably fine" | Markdown links have zero compile-time verification — "probably fine" is exactly when drift accumulates. The check takes ~2 seconds; running it is faster than convincing yourself you don't need to |
| "I'll run smoke-test once at the end of the session" | Same failure mode as batched AAR: by the time you remember, you can no longer attribute breakage to a specific edit. Path integrity is per-commit, not per-session |
| "audit-references is just for orphans, my edit can't create orphans" | Wrong premise — deleting any inbound link can orphan a previously-linked file. The script runs in seconds; assumptions about what "can't" happen are how silent rot starts |
| "The official docs probably haven't changed" | Volatile external behavior is exactly where stale rules come from. Refresh the primary source and update the `external-fact` date |

### Red Flags — STOP

If the Agent catches itself thinking any of the following, stop and run the full protocol:

- "Just this once" — every skip erodes the protocol
- "I'll fix it in the next task" — the next task will have its own closure
- "Nobody will know I skipped" — the next pitfall will
- "The AAR is for big changes" — scope does not determine value; novelty does
- "This is overhead, not work" — Task Closure *is* the task; anything that ships without it is half-done

> Reusable versions of these blocks live in [`templates/protocol-blocks/`](templates/protocol-blocks/) — drop them into any project workflow that needs reinforcement.

## After-Action Review

The 30-second scan from step 2 of the Task Closure Protocol.

Skip only for: formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors.

Checklist:

- [ ] **New pattern** — Did this task use an undocumented pattern or convention?
- [ ] **New pitfall** — Did you hit a problem that wastes significant time if you don't know about it upfront?
- [ ] **Missing rule** — Did the absence of a rule cause you to take a wrong turn?
- [ ] **Outdated/obsolete rule** — Did you find an existing rule that is inaccurate or no longer applicable?
- [ ] **External fact** — Did this task rely on a vendor/tool/runtime fact that could have changed since it was written?

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
- Task routing changed → `routing.yaml`, then `scripts/sync-routing.sh`
- Entry routing or Always Read changed → `routing.yaml`, then regenerate thin-shell generated blocks (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`)

### Recording Destination (user-initiated recording)

When the user explicitly asks to "record this" or "remember this", decide the destination first:

- **Project-level knowledge** (would help a different agent on this project) → `skills/<name>/references/`, `rules/`, or `workflows/`
- **Personal preference** (only relevant to this specific user) → agent's own memory system (e.g. `~/.claude/.../memory/`)

Default to skill docs. Most explicit recording requests during development are project-scoped.

For UI / interaction / layering / host-compatibility issues:

- Long-lived team convention or preferred implementation pattern → `rules/`
- Compatibility pitfall, debugging lesson, layering trap, or non-obvious failure mode → `references/`

### Activation Check

If the lesson is both **costly** and **task-relevant**, don't stop at storing it in `references/`.

Ask:

1. Would a future agent naturally read this reference during the same task type?
2. If not, should this also change a workflow checklist, `routing.yaml`, or a concise rule summary?

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

Examples:

| Bad (project narrative) | Good (generalized knowledge) |
|---|---|
| In the product iteration module, we found pagination needs reset when switching tabs | When switching context (tabs, views, filters), reset pagination to page 1. Stale pagination causes empty results or out-of-range errors |
| Our UserService.createUser method needs a duplicate check first | Uniqueness validation must happen before entity creation — the DB constraint is the last line of defense, not the first |
| The OrderController date parameter uses yyyy-MM-dd format | API date parameters use ISO 8601 format (`yyyy-MM-dd` or `yyyy-MM-ddTHH:mm:ssZ`); validate format at the controller entry layer |
| admin-dashboard page loads slowly because of missing pagination | List endpoints must support pagination; unpaginated full-table queries become performance bottlenecks as data grows |
| Our auth context needs a Provider wrapper at the root | Authentication state must initialize at the app root; child components consume via context/provider pattern. Initializing auth deeper causes race conditions on protected routes |
| CI breaks because deploy.sh runs before build finishes | Deployment pipelines must include an explicit build step before deploy — never assume the artifact already exists. Missing build gates cause silent deploy of stale code |

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
3. **Partially obsolete** (e.g. migrating from jQuery to React, but old pages still use jQuery) → keep the rule but scope it: add a clear header like "Legacy only — applies to jQuery pages; new pages use React rules in `frontend-rules.md`". When the last legacy page is migrated, delete the scoped rule.
4. **If unsure** → annotate with `<!-- DEPRECATED: reason, date -->` and revisit later
5. **Update references** — if an entire file is deleted, update `routing.yaml`, run `scripts/sync-routing.sh`, and update the sync trigger table

## Inline Changelog (Optional)

When making meaningful rule changes, prepend a changelog comment to the affected file:

<!-- changelog: YYYY-MM-DD added filter registration pitfall -->
<!-- changelog: YYYY-MM-DD deprecated jQuery rules (migrated to React) -->

Benefits: agents can scan the first few lines to judge rule freshness without checking git history. Only log significant changes (new rules, major updates, deprecations) — skip formatting, typo fixes, and minor rewording.

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
```

## fix-bug.md Template

Use this workflow for bug fixes and debugging tasks. The key requirement is that a bug fix is not fully complete until the recording-threshold check has been performed.

```md
# Fix Bug Workflow

## Read First

1. `rules/project-rules.md`
2. `rules/coding-standards.md`
3. Task-relevant `rules/*.md`
4. Task-relevant `references/*.md`

## Steps

1. Restate the bug scope and affected behavior
2. Read the minimum necessary files
3. Identify the root cause
4. Implement the smallest correct fix
5. Run Fix Impact Analysis: direct callers/signatures, indirect data flow/shared state/events, data compatibility, and blast-radius validation
6. Validate behavior
7. Run Task Closure Protocol from `workflows/update-rules.md` — this is mandatory, not optional
8. If the recording threshold passes, update the appropriate `rules/`, `references/`, or `workflows/` file before ending the task
9. Records must pass the generalization check — write as reusable knowledge, not project-specific narratives (see Generalization Rule in `workflows/update-rules.md`)
10. If the lesson is costly and task-relevant, also activate it in workflow/routing, not only store in `references/`

## Completion Checklist

- [ ] Root cause identified
- [ ] Fix Impact Analysis completed against the actual diff
- [ ] Code fix verified
- [ ] Task Closure Protocol was run (AAR scan completed before declaring task done)
- [ ] Recording threshold checked
- [ ] If threshold passed, record passes generalization check and docs updated
- [ ] If the lesson was costly and task-relevant, it was activated in workflow/routing, not only stored in `references/`
```

## maintain-docs.md Template

File health maintenance workflow — prevents documentation degradation over time.

```md
# Documentation Health Maintenance

Keep the skills directory from degrading: files not too long, not too fragmented, no broken links, no duplicated content.

**Core principle: line counts are signals, not commands.** Exceeding a threshold triggers evaluation, not action. Only split when "over threshold + topics genuinely separable"; only merge when "fragmented + topics genuinely belong together".

## When to Run

- After completing the `update-rules.md` workflow, quickly check modified file line counts
- Proactive maintenance: when files feel "hard to navigate" or "too long to want to read"
- **Not required** after every small change

## Step 1: Size Scan

Check line counts for all files under `skills/<name>/` and flag those that may need attention:

| File type | Reference range | Triggers evaluation | Fragment signal |
|---|---|---|---|
| `SKILL.md` | ≤ 100 lines | > 100 lines | — |
| `rules/*.md` | 50–200 lines | > 200 lines | < 30 lines |
| `workflows/*.md` | 30–150 lines | > 150 lines | < 15 lines |
| `references/*.md` | 50–300 lines | > 300 lines | < 30 lines |
| Thin shells | Routing + compatibility notes only | Rule/workflow bodies or project-specific process detail | — |

Note: these numbers are **reference values**, not hard thresholds. A 250-line rules file with a single coherent topic is perfectly fine to keep.

## Step 1b: Gotchas Accumulation Check

If `references/gotchas.md` (or any domain-specific pitfall file) exceeds **30 entries**, evaluate:

1. **Can entries be grouped by domain?** (e.g., frontend pitfalls vs. backend pitfalls vs. deployment pitfalls) → Split into domain-specific files
2. **Have any gotchas been fixed?** (underlying framework bug patched, architecture changed) → Archive or delete resolved entries
3. **Are any entries redundant?** (same lesson captured from different angles) → Merge into one entry

A gotchas file that's too long to scan quickly defeats its purpose — the whole point is "brief, scannable list."

## Step 2: Evaluate — Should You Split?

When a file exceeds the reference range, answer these questions:

1. **Are the topics separable?** — Does the file contain 2+ independent topics where removing one doesn't affect understanding of the other?
2. **Is navigation difficult?** — Would someone looking for "Controller conventions" need to scroll through 300 lines to find it?
3. **Can each part stand alone?** — Would each resulting file have enough content (> 30 lines) to be independently useful?

**All three "yes" → splitting has value. Any "no" → don't split.**

Before executing, estimate the overhead: each new file adds ~5–10 lines of structural cost (file header, SKILL.md routing update). If total documentation after splitting would be more than ~10% larger than before, the navigation benefit may not outweigh the extra reading cost for agents. Prefer keeping the file intact or finding a more natural split boundary.

### When NOT to Split

- File is long but highly coherent (e.g. a complete API routing table)
- Splitting would create a sub-file too small (< 30 lines) to maintain independently
- Splitting would force readers to jump between two files to understand one concept
- File barely exceeds the reference value (e.g. 210-line rules file) with no actual navigation difficulty

### Executing a Split

Once you've confirmed splitting is worthwhile:

1. **Identify boundaries** — find independent topic blocks (usually separated by H2 headings)
2. **Name new files** — rules: `*-rules.md`, workflows: verb-noun, references: noun-based
3. **Migrate content** — move to new files, keep heading levels reasonable
4. **Update routing** — modify `routing.yaml`, then run `scripts/sync-routing.sh`
5. **Update referrers** — other rule files that cross-reference the split/merged files
6. **Verify** — no broken links, no duplicated content, nothing left behind

Common split dimensions:

| Original file | Possible split approach |
|---|---|
| `backend-rules.md` | By layer: controller-rules / service-rules / mapper-rules |
| `frontend-rules.md` | By concern: component-rules / state-rules / styling-rules |
| Large workflow | By phase or sub-task into separate workflows |
| Large reference | By topic: architecture / api-index / env-notes |

## Step 3: Evaluate — Should You Merge?

When fragment files are detected, answer these questions:

1. **Are the topics related?** — Do these small files belong to the same subject area?
2. **Is finding things easier after merging?** — Do readers frequently need to look at multiple files together?
3. **Will the merged file stay within limits?** — The merged file won't become another file that needs splitting?

**All three "yes" → merging has value. Otherwise keep as-is.**

### When NOT to Merge

- Small files are small but each has a clearly independent responsibility (e.g. `fix-bug.md` and `update-rules.md` are both short but cover different domains)
- Merging would exceed the type's reference limit
- Files belong to different subdirectories (don't merge across rules/workflows/references)

### Executing a Merge

Once you've confirmed merging is worthwhile:

1. **Merge** — combine content into one file, use H2 headings to separate original topics
2. **Check limits** — merged file should not exceed the type's reference limit
3. **Update references** — all locations that referenced the original files
4. **Clean up** — delete the original files

## Step 4: Reference Integrity Check

Run after any split, merge, rename, or deletion of files under `skills/<name>/`:

- [ ] All links in SKILL.md's Always Read and Common Tasks are valid
- [ ] All `workflows/*.md` "Read First" sections reference existing files
- [ ] Cross-references between rules/references files point to valid targets
- [ ] Thin shells still point to the current `skills/<name>/SKILL.md` or documented multi-skill router
- [ ] No orphaned files (file exists but no entry links to it)
- [ ] No duplicated content (each rule maintained in exactly one place)
- [ ] If a file was deleted, no other file still references it

## Completion Criteria

- Evaluated over-threshold files and made a **reasoned judgment** to keep or split
- If any file was split, merged, renamed, or deleted, reference integrity check passes
- SKILL.md navigation matches current file structure
```
