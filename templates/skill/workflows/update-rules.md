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
A task is NOT complete until all six gates are done:

1. **Main work** — implementation done, verified, tests pass
2. **30-second AAR scan** — run the checklist below; all "no" = stop here
3. **Record if needed** — any "yes" → apply recording threshold → record if it passes
4. **Path integrity gate** — if this task touched any `.md` file in skill structure, both checks below must pass *before commit*. Run these from the project repo root unless noted. Markdown links have no compile-time verification — agents partially update path references all the time, leaving dangling links that silently rot. These two scripts are the missing "type checker":
   - `bash "skills/<skill-name>/scripts/smoke-test.sh" "<skill-name>" --phase 8` — verifies every relative markdown file link in every skill `.md` resolves to an existing file (Section 8: Broken Link Check), plus all earlier structural/routing/budget checks
   - `(cd "skills/<skill-name>" && bash scripts/audit-references.sh --orphans)` — verifies no file in `rules/` or `references/` is unreachable from any inbound link (orphans = stored but never activated)
   - Together they cover both directions of drift: broken outbound links (Section 8) and dangling inbound links (orphans)
   - Fix every failure in the same commit as the edit that caused it, not "next task"
5. **Cross-reference content sync** — if this task changed the *meaning* of a `rules/` or `references/` file (not just paths), grep `workflows/` for files that reproduce the changed invariant and update them in the same commit. Rule meaning drifts silently otherwise; a workflow that repeats a now-wrong invariant actively misleads.
6. **External fact freshness** — if the edit adds or changes a claim about an external tool, framework, hosted service, API, model, CLI, or official behavior, verify against the primary source, add/refresh `<!-- external-fact: verified=YYYY-MM-DD source=https://official.example/docs -->`, then run `bash "skills/<skill-name>/scripts/check-external-facts.sh" .`. Project-internal facts do not need this marker.

No workflow may declare completion without step 2. Steps 3–6 fire conditionally (3 on AAR hits, 4 on any `.md` edit, 5 on rules/references *meaning* changes, 6 on external facts) and are mandatory when their trigger fires.

### Rationalizations to Reject

When the Agent feels the urge to skip the AAR, these are the common excuses and their rebuttals. Every row was captured from a real pressure-test failure — do not argue with them, just refuse.

| Rationalization | Reality |
|---|---|
| "This task was small — AAR is overkill" | Small tasks are where lessons hide. The AAR scan takes 30 seconds; skipping it is slower than doing it |
| "I'll run AAR at the end of the session" | You will forget. The scan must happen at task closure, not batched |
| "Nothing new happened, just a routine fix" | If nothing new happened, the scan returns "no" on all four questions in 30 seconds. Do it anyway |
| "The user is in a hurry" | The protocol exists *because* hurry produces the worst pitfalls. Pressure is a reason to run AAR, not skip it |
| "I already know this lesson, don't need to record" | Recording is for future agents, not past you. Current knowledge is not durable |
| "This is covered by the existing rules" | Then the scan returns "no" in 10 seconds. Faster to run it than argue about it |
| "I already read SKILL.md for the previous task" | The new task may match a different route. Context compresses silently. Re-read costs seconds; skipping costs hours of wrong-direction work |
| "User said 'record this' — I'll also archive the full session as YYYY-MM-DD-session-notes.md in `references/`" | "Record" means extract a **generalized, reusable lesson** into `rules/` or `references/<topic>.md`. Dated session narratives belong in `git log` / `CHANGELOG`, never in `references/`. `references/` rejects date-named narrative files — they violate the generalization rule (project-specific story, not reusable knowledge) and the activation rule (no routing path will ever read them) |
| "I changed `rules/<x>.md` — workflows can be checked next task" | Cross-reference drift compounds silently. A workflow that repeats a now-wrong invariant is worse than one missing the new invariant; it actively misleads. The check takes seconds when the edit is fresh; next task, you'll forget what you changed |
| "I'll add the activation pointer to the workflow in a follow-up commit" | Same excuse family as "workflows can be checked next task". The moment you know where the new entry belongs is *now*; after the commit lands, the routing decision evaporates. Either declare the activation path in the same commit, or skip recording entirely |
| "The entry is so obviously useful someone will find it" | "Obvious" is survivor bias — you already know the lesson. Future agents arriving cold see only the routing table; unindexed references are invisible. Activation is navigation, not advertising |
| "I only renamed one file, links are probably fine" | Markdown links have zero compile-time verification — "probably fine" is exactly when drift accumulates. The check takes ~2 seconds; running it is faster than convincing yourself you don't need to |
| "I'll run smoke-test once at the end of the session" | Same failure mode as batched AAR: by the time you remember, you can no longer attribute breakage to a specific edit. Path integrity is per-commit, not per-session |
| "audit-references is just for orphans, my edit can't create orphans" | Wrong premise — deleting any inbound link can orphan a previously-linked file. The script runs in seconds; assumptions about what "can't" happen are how silent rot starts |
| "The official docs probably haven't changed" | Volatile external behavior is exactly where stale rules come from. If the rule depends on a tool/vendor/runtime, refresh the primary source and update the `external-fact` date |

### Red Flags — STOP if you catch yourself thinking any of these

- "Just this once" — every skip erodes the protocol
- "I'll fix it in the next task" — the next task will have its own closure
- "Nobody will know I skipped" — the next pitfall will
- "The AAR is for big changes" — scope does not determine value; novelty does
- "This is overhead, not work" — Task Closure *is* the task; anything that ships without it is half-done

## After-Action Review

The 30-second scan from step 2 of the Task Closure Protocol. Skip only for: formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors.

Checklist:

- [ ] **New pattern** — Did this task use an undocumented pattern or convention?
- [ ] **New pitfall** — Did you hit a problem that wastes significant time if you don't know about it upfront?
- [ ] **Missing rule** — Did the absence of a rule cause you to take a wrong turn?
- [ ] **Outdated/obsolete rule** — Did you find an existing rule that is inaccurate or no longer applicable?
- [ ] **External fact** — Did this task rely on a vendor/tool/runtime fact that could have changed since it was written?

If any answer is "yes", apply the relevant gate before writing anything down: recording threshold for new lessons, direct update for outdated rules, external-fact freshness for volatile external claims. If all answers are "no", stop here. The review should stay lightweight, but it is still part of task closure.

### Recording Threshold

Before recording a potential new piece of knowledge, ask:

1. **Will it recur?** — Is this likely to come up again in future tasks, or is it a one-off?
2. **Is the cost high?** — How much time would someone waste not knowing this? A few minutes of trial-and-error isn't worth a rule; 30+ minutes of debugging is.
3. **Is it obvious from the code?** — Can someone read the code and immediately understand this? If yes, don't document it separately.

**At least 2 of 3 must be "yes / high / no" → worth recording. Otherwise skip.**

### Search Before Record (mandatory)

Before writing anything new, search existing docs for the same or similar lesson:

```bash
grep -ri "<key concept>" skills/<name>/rules/ skills/<name>/references/ skills/<name>/workflows/
```

- **Exact match found** → stop. The lesson already exists. If the existing entry is incomplete, **update it in place** rather than adding a new one.
- **Similar but different angle found** → **merge into the existing entry**, adding the new angle. Do not create a parallel entry with different wording for the same lesson.
- **No match found** → proceed to "Where To Record" below.

This step prevents the most common form of knowledge rot: the same lesson recorded 3 times in 3 different wordings across 3 files.

### Where To Record

- Stable constraint or convention → `rules/`
- Pitfall, architecture note, lifecycle gotcha, source index → `references/`
- Ordered task step or completion check → `workflows/`
- Task routing changed → `SKILL.md`
- Entry routing changed → thin shells (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`)
- **Session history / debug trace / chronological notes → do NOT record in the skill** — use git commit messages, `CHANGELOG.md`, or a `docs/` note outside the skill. `references/` is for reusable knowledge, not timestamped logs. Every `YYYY-MM-DD-session-notes.md` under `references/` is a sign this rule was violated.

### Recording Destination (user-initiated recording)

When the user explicitly asks to "record this" or "remember this", decide the destination first:

- **Project-level knowledge** (would help a different agent on this project) → `skills/{{NAME}}/references/`, `rules/`, or `workflows/`
- **Personal preference** (only relevant to this specific user) → agent's own memory system (e.g. `~/.claude/.../memory/`)

Default to skill docs. Most explicit recording requests during development are project-scoped.

For UI / interaction / layering / host-compatibility issues:

- Long-lived team convention or preferred implementation pattern → `rules/`
- Compatibility pitfall, debugging lesson, layering trap, or non-obvious failure mode → `references/`

### Activation Check (mandatory gate)

**Rule: no new `references/` entry ships without a declared activation path.**

Before recording any new entry in `references/`, answer both:

1. **Where will the next agent hit this?** Name the specific trigger — a workflow checklist line, a `SKILL.md` Common Tasks route, a thin-shell routing-table cell, or a concise rule summary. "In `references/` under the right topic" is not an answer; that is storage, not activation.
2. **Is that trigger guaranteed to fire for the task this entry prevents?** If the task path never reads the referencing file, the entry is inert — reject recording.

If no activation path exists, do one of these and re-check:

- Add the pointer to the nearest workflow / route / rule in the **same commit** that adds the reference entry
- Promote the entry to a `rules/` line or `workflows/` checklist item if short enough to live there directly
- Skip recording; the lesson isn't costly enough to justify a reference file no task will read

This gate applies to **every** record, not just high-cost ones. Unactivated `references/` entries inflate disk and token budget without ever being consulted — indistinguishable from not recording at all. The writer's burden is proving the entry is reachable, not arguing it is valuable.

**Tier exception (Progressive Rigor):** At Folder-light tier the activation path can target a `SKILL.md` routing row or a bullet in `rules/*.md` — `workflows/` need not exist. At Single-file tier with no `rules/` either, skip recording: the lesson has not earned the upgrade pressure. The gate never forces tier escalation; it forces honesty about whether the current tier has a reachable path.

**Write the "why" out loud:** in the commit body (or PR description), one sentence on why the chosen activation point is the right one ("this pitfall triggers during the auth-setup workflow, so the pointer goes in workflows/auth-setup.md § Step 3"). Not machine-verifiable — the point is that ceremonial pointers feel wrong when you have to defend them in prose. Backstop: [`scripts/audit-references.sh`](../scripts/audit-references.sh) catches orphans the gate missed.

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

### Entry Tagging

Every recorded entry — bullet point, gotcha, or rule — must carry lightweight inline tags for future machine-assisted dedup and staleness scanning.

**Format:** `**[topic]**` at the start of every entry. Example: `- **[lifecycle]** Filter must register before app init; registering after causes silent drop`. For gotchas, the topic goes in the H2 heading: `## **[lifecycle]** Short title`.

**Rules:**

1. `[topic]` is a short reusable noun, not a sentence. Reuse existing topics — check `grep -oP '\*\*\[([^\]]+)\]' references/ rules/` before inventing a new one.
2. When multiple entries share the same `[topic]` in one file, verify they are not duplicates — merge if yes.

### Structural Placement (not "append at bottom")

New entries must be placed **under the most relevant existing H2/H3 section** in the target file, not appended at the file bottom.

1. Scan the target file's headings — find the section whose topic matches the new entry.
2. **Match found** → append under that heading, in logical order with existing entries.
3. **No match found** → create a new H2/H3 section with a descriptive name, then add the entry. Place the new section in the most logical position among existing sections, not at the very end.

**Why this matters:** entries appended at the bottom of a file without section anchoring become an unsorted pile. After 10 such entries, no one (human or Agent) will scan through them. Structurally placed entries stay discoverable because they sit next to related content.

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
7. **External fact changed** → update the rule/reference and refresh its `external-fact` marker in the same commit

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

### Surfacing Deprecation Candidates

Proactive scan — do not wait for "I noticed this feels stale":

```bash
(cd "skills/<skill-name>" && bash scripts/audit-references.sh)              # full inbound-link report
(cd "skills/<skill-name>" && bash scripts/audit-references.sh --orphans)    # only zero-inbound files, exits 1 if any
```

An orphan (zero inbound links from workflows, rules, SKILL.md, or shells) is either a forgotten activation pointer or a candidate for deletion. Single-referrer files are weak links — read the referring file to confirm it's a real activation path, not a leftover mention.

Run this at every major refactor or when `smoke-test.sh` flags gotchas/pitfall line bloat (default cap 400 lines; tune via `GOTCHAS_MAX_LINES` env var if the project has a principled reason). For routine tasks, the `§ Activation Check` gate should prevent orphans in the first place; this audit is the backstop for when the gate was skipped.

## Post-Update Health Check

After completing rule updates, check the line count of modified files. If any exceed the healthy range, evaluate whether splitting is needed using the `maintain-docs.md` judgment process — **exceeding the threshold does not mean you must split**; a long file with a single coherent topic can stay as-is.

## Completion Criteria

- Formal rules maintained in exactly one place
- Entry files contain only navigation and summaries
- Sync trigger table includes any newly discovered mappings
- Obsolete rules have been removed or marked
- Recording threshold checked on every substantive task; when it passed, the appropriate file was updated before closure
- Every new `references/` entry has a declared activation path (workflow line / `SKILL.md` route / rule summary) added in the **same commit** — no orphan shipped
