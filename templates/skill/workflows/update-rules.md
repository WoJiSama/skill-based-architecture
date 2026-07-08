# Rule Update Workflow

## Classification Guide
- Long-lived, must-follow constraints → `rules/`
- Task procedures with ordered steps → `workflows/`
- Architecture, routing, dependency explanations → `references/`
- Anti-patterns, footguns, "we tried X, here is why X is wrong" → `references/gotchas.md` (or domain-specific `references/*pitfall*.md`); promote to SKILL.md § Common Pitfalls when the lesson must surface on every task
- Frozen plan snapshots (audit trail only, not active knowledge) → `docs/plans/`; load-bearing content from the plan goes into the rows above, not stored only in the plan
- External-facing material → `docs/`

## Sync Targets

| Change type | Files to update |
|---|---|
| New/renamed workflow or reference file | `routing.yaml`, then run `scripts/sync-routing.sh` |
| UI convention / host compatibility / overlay layering / z-index / styling behavior issue that future agents would guess wrong without docs | Update the relevant `rules/*.md` or `references/*.md`, and update `SKILL.md` summary if the pitfall should surface earlier |
| Plan landed (`status: done`) with a load-bearing conclusion | Lift the conclusion: "must / must not do X" → `rules/<topic>.md`; "tried Y, Y is wrong" → `references/gotchas.md` or SKILL.md § Common Pitfalls. Set the plan's `distilled_to:` frontmatter to the files that received content. Pure-provenance conclusions stay in the plan archive only |
| <!-- OPTIONAL: project-specific trigger → target file --> | <!-- OPTIONAL --> |

Threshold: if this change would cause someone to guess wrong on a similar task without reading the docs, update. Otherwise skip.

> **The trigger table itself is a living document:** when you discover a new change-to-update mapping, add it to this table.

## Task Closure

The cross-cutting **Task Closure Protocol** (Trigger Policy, the six closure steps, the 30-second AAR scan, Rationalizations to Reject, Red Flags) is the gate **every behavior-changing task** runs at its close. It is the canonical home for the closure gate and lives in [`task-closure.md`](task-closure.md) — invoked by `fix-bug.md`, `change-managed.md`, `refactor-fanout.md`, `edit-templates.md`, and any other workflow at their closure step.

This file holds the **recording mechanics** that the gate's "record if needed" step ([`task-closure.md`](task-closure.md) § Task Closure Protocol, step 3) calls into. Closure decides *whether* to record; the sections below decide *how*. Do not restate the Trigger Policy, closure steps, Rationalizations, or Red Flags here — that content is allowed to exist only in `task-closure.md`; a second copy is how the two drift apart.

## Recording Lessons

> **Cross-axis prompt (opt-in — permission-model projects):** a lesson on one governance axis often implies a rung on the other — a code gotcha ↔ an operation tier (🟡/🔴), an operation incident ↔ a design convention. When recording on one axis, check whether the paired axis needs a rung. See [`../references/permission-model.md`](../references/permission-model.md) § two axes.

### Recording Threshold

Before recording a potential new piece of knowledge, ask:

1. **Will it recur?** — Is this likely to come up again in future tasks, or is it a one-off?
2. **Is the cost high?** — How much time would someone waste not knowing this? A few minutes of trial-and-error isn't worth a rule; 30+ minutes of debugging is.
3. **Is it obvious from the code?** — Can someone read the code and immediately understand this? If yes, don't document it separately.

**At least 2 of 3 must be "yes / high / no" → worth recording. Otherwise skip.**

### Baseline Check (discipline rules only)

Applies only to a rule whose whole job is to change behavior under pressure — a red flag, a rationalization-table row, an "always/never" constraint. Descriptive / reference content is exempt (no behavior to fail). This is **not** a per-edit gate; it almost always costs nothing:

- **You watched it fail this session, or it's a known recurring pain** → the baseline is organic and free. Record the verbatim failure and write the rule.
- **No observed failure, only a hunch** → this is the imagined-pain fork (SKILL.md Common Pitfalls #10). Either run a baseline to prove it fails (see `references/scenario-testing.md` § Baseline-First for Discipline Content), or drop the rule. Two minutes of proof, or no permanent rule.

Never run a baseline for routine recording where the failure already happened in front of you.

### Search Before Record (mandatory)

Before writing anything new, search existing docs for the same or similar lesson. This is Tier 1 of the maintenance trigger discipline (see `maintain-docs.md § Step 1b` for the full tier table). It is cheap because the agent already has the new entry's content and context in hand — a targeted scan of 3–5 candidate entries is far cheaper than reading the whole file.

**General search** (any docs):

```bash
grep -ri "<key concept>" skills/<name>/rules/ skills/<name>/references/ skills/<name>/workflows/
```

**Gotchas/pitfall-specific scan** (when about to append to `references/gotchas.md` or `references/*pitfall*.md`):

```bash
# 1. List existing topic tags — promote/reuse rather than invent
grep -oP '\*\*\[([^\]]+)\]' <file> | sort | uniq -c | sort -rn | head -10

# 2. List existing ## / ### headings — surface near-duplicate titles
grep -E '^#{2,3} ' <file>

# 3. For each likely-matching heading, read the surrounding 10–20 lines
#    DO NOT read the whole file just for a similarity check.
```

Decision tree:

- **Exact match found** → stop. The lesson already exists. If the existing entry is incomplete, **update it in place** rather than adding a new one.
- **Similar but different angle found** → **merge into the existing entry**, adding the new angle as another paragraph or bullet. Do not create a parallel entry with different wording for the same lesson.
- **No match found** → proceed to "Where To Record" below.

This step prevents the most common form of knowledge rot: the same lesson recorded 3 times in 3 different wordings across 3 files. Smoke-test (`§ 2a`) catches the lazy case (verbatim duplicate `## ` heading); this Search step catches the harder case (near-duplicate phrased differently) at the cheapest moment to catch it.

### Where To Record

- Stable constraint or convention → `rules/`
- Pitfall, architecture note, lifecycle gotcha, source index → `references/`
- Ordered task step or completion check → `workflows/`
- Task routing changed → `routing.yaml`, then `scripts/sync-routing.sh`
- Entry routing or Always Read changed → `routing.yaml`, then regenerate thin-shell generated blocks (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`)
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

**Rule: no new `references/` entry ships without a declared activation path — one that is both *reached* and *acted on*.**

Before recording any new entry in `references/`, answer all three:

1. **Where will the next agent hit this?** Name the specific trigger — a workflow checklist line, a `routing.yaml` route or `always_read` entry that generates `SKILL.md` / thin-shell content, or a concise rule summary. "In `references/` under the right topic" is not an answer; that is storage, not activation.
2. **Is that trigger guaranteed to fire for the task this entry prevents?** If the task path never reads the referencing file, the entry is inert — reject recording.
3. **When the agent reads it, does it change the next action?** A correct-but-inert entry — read, understood, then the agent proceeds exactly as it would have — is reached but not activated. Phrase the entry as the action it should trigger (the file to open, the check to run, the step to skip), not as a background fact. Reachable ≠ useful; the structural gates (`audit-orphans`, `route-reachability`, `smoke-test`) prove reach, never actionability — only this question does.

If no activation path exists, do one of these and re-check:

- Add the pointer to the nearest workflow / `routing.yaml` task / rule in the **same commit** that adds the reference entry
- Promote the entry to a `rules/` line or `workflows/` checklist item if short enough to live there directly
- Skip recording; the lesson isn't costly enough to justify a reference file no task will read

This gate applies to **every** record, not just high-cost ones. Unactivated `references/` entries inflate disk and token budget without ever being consulted — indistinguishable from not recording at all. The writer's burden is proving the entry is reachable, not arguing it is valuable.

**Tier exception (Progressive Rigor):** At Folder-light tier the activation path can target a `SKILL.md` routing row or a bullet in `rules/*.md` — `workflows/` need not exist. At Single-file tier with no `rules/` either, skip recording: the lesson has not earned the upgrade pressure. The gate never forces tier escalation; it forces honesty about whether the current tier has a reachable path.

**Escalation rung — recorded, activated, yet it recurred:** when a landmine that is already recorded *and* on an activated path still bites again, prose has hit its ceiling — consider promoting it to a **machine gate inside the tool that triggers it** (a launcher/build/script check that refuses to proceed, with an explicit env-var escape hatch for legitimate overrides). Strictly for verified recurrence with real cost; the imagined-pain rule applies doubly to hard gates. This is the design-axis counterpart of the enforcement ladder in [`../references/permission-model.md`](../references/permission-model.md).

**Write the "why" out loud:** in the commit body (or PR description), one sentence on why the chosen activation point is the right one ("this pitfall triggers during the auth-setup workflow, so the pointer goes in workflows/auth-setup.md § Step 3"). Not machine-verifiable — the point is that ceremonial pointers feel wrong when you have to defend them in prose. Backstop: [`scripts/audit-orphans.sh`](../scripts/audit-orphans.sh) catches orphans the gate missed.

### When NOT to Record

- One-off workarounds (only relevant to this specific bug, won't recur)
- Things immediately obvious from reading the code (e.g. "this function takes two parameters")
- Minor personal preferences (e.g. "I think this variable name is bad")
- Content already clearly documented in official framework docs (don't copy official docs into rules)
- **Content whose only purpose is to move an external metric / score (Goodhart).** An eval, benchmark, or usage score is a *signal to improve the skill* — run its lessons through these same gates (threshold, generalization, activation) — never a *target to optimize*. Test: would you write this if the metric didn't exist? No → drop it. (Sibling of SKILL.md Common Pitfalls #10, imagined-pain engineering: both are doing work for the wrong reason.)

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
5. **Update references** — if an entire file is deleted, update `routing.yaml`, run `scripts/sync-routing.sh`, and update the sync trigger table

### Surfacing Deprecation Candidates

Proactive scan — do not wait for "I noticed this feels stale":

```bash
(cd "skills/<skill-name>" && bash scripts/audit-orphans.sh)
```

An orphan (zero inbound links from workflows, rules, SKILL.md, or shells) is either a forgotten activation pointer or a candidate for deletion. Read the file before deleting; the orphan report is a heuristic, not a verdict.

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
