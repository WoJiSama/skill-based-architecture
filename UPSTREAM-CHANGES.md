# Upstream Changes

This file is a human- and agent-readable map for downstream refreshes.
When a downstream project asks to update from this upstream repo, read the
latest relevant entries first, then verify every candidate change against the
actual upstream/downstream file diff.

This is not a lockfile, upgrade manifest, changelog contract, or source of
truth. It is intentionally upstream-owned only. Downstream projects should not
copy, create, or maintain a local version of this file.

## How To Use

1. Clone the upstream repo named in `workflows/update-upstream.md`.
2. Read the newest entries below to identify likely files and intent.
3. Compare actual upstream and downstream files before editing.
4. Preserve downstream project-owned rules, gotchas, routing examples, and
   local workflows.
5. Patch useful upstream mechanism changes, then run the downstream validation
   commands from `workflows/update-upstream.md`.

## Entry Format

```text
## YYYY-MM-DD - short title

- Status: superseded by YYYY-MM-DD - newer-title    # OPTIONAL — see below
- Upstream commit: <hash> <subject>
- Changed areas: <files or directories>
- Why it matters: <intent>
- Downstream refresh guidance: <what to compare/port/preserve>
```

### Status field (optional)

Default = active (omit the `Status:` line). Add it only when an entry's guidance has been **reversed** (not merely extended) by a later commit:

- `Status: superseded by YYYY-MM-DD - <title>` — newer entry replaces this guidance. Downstream refresh agents follow the newer entry, skip this one.
- `Status: deprecated — <one-line reason>` — the mechanism this entry describes was removed entirely; no replacement exists. The entry stays as history.

**Writer protocol.** When your new entry reverses an older one — active or archived — edit the older entry to add the `Status: superseded by ...` line referencing your new entry's heading. Pointers are one-way (older → newer); the new entry can mention the supersede in prose but doesn't carry machine markup. Extending or building on a prior entry does **not** count as reversal — only reach for `superseded by` when reading the old guidance would lead a future agent astray.

**Check.** `scripts/check-upstream-supersedes.sh` (wired into `check-all.sh`) validates every `Status: superseded by` reference resolves to a real `## YYYY-MM-DD - title` heading in `UPSTREAM-CHANGES.md` or `UPSTREAM-CHANGES-archive.md`. Broken references fail the suite.

## Archive Policy

Downstream refresh agents almost always only read the most recent 3–5 entries. Old entries cost them context without changing decisions. When this file passes ~300 lines (or roughly 8 entries), move the oldest entries to `UPSTREAM-CHANGES-archive.md` and keep only the most recent 3–5 here.

The archive file has the same format and is read on demand if a downstream agent is investigating a specific historical change. `scripts/check-upstream-changes.sh` only enforces a same-diff entry in `UPSTREAM-CHANGES.md`; archived entries are out of its scope.

## 2026-06-01 - Subagent: make the Parallelism Premise non-blocking-by-mechanism

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/subagent-driven.md` — the 2026-05-28 Parallelism
    Premise stated the *requirement* (main agent must keep working while a
    subagent runs) but gave no *mechanism*, so the decision flow read as a single
    **foreground** dispatch that blocks. Added the concrete non-blocking
    mechanism in three cases: (1) **batch parallel** — N independent chunks
    dispatched in one message run concurrently; (2) **background** —
    `run_in_background` + continue immediately when there is real main-thread
    work; (3) **neither** → inline (a lone foreground dispatch you wait on is
    worse than inline). Updated: top-of-file invariant ("non-blocking is the
    whole point, both modes"), the Parallelism Premise body + ✅/❌ examples, the
    Mode 1 decision-flow diagram, the Mode 1 Properties bullet, and Mode 2
    Phase 2 step 4 (name the "single message / `run_in_background`" mechanic).
  - `references/self-hosting-routing.yaml` — `long-run` route `workflow:` fixed
    from `templates/protocol-blocks/subagent-contract.md` (the Mode 2 fill-in
    contract) → `templates/skill/workflows/subagent-driven.md` (the Mode 1/Mode 2
    decision logic). A "big task" was being routed straight to the contract
    template, skipping the mode + non-blocking decision. Contract stays reachable
    as a sub-artifact subagent-driven.md links to.
- Why it matters: a foreground dispatch the main agent then waits on has the same
  wall-clock as inline plus coordination overhead — strictly worse than not
  dispatching. The premise existed to prevent exactly this but, lacking a
  mechanism, agents would still block. Naming the two concurrency primitives
  (batch-in-one-message, `run_in_background`) makes "main agent keeps moving" an
  executable instruction rather than an aspiration. Builds on (does not reverse)
  the 2026-05-28 Parallelism Premise entry.
- Downstream refresh guidance:
  - `subagent-driven.md` is a template workflow you copy. Port the non-blocking
    mechanism (the three-case Parallelism Premise, the decision-flow branches,
    the Properties bullet, Mode 2 Phase 2 step 4) into your local copy, preserving
    your project-specific FILL blocks (Phase 3 verification commands, Forbidden
    Zone defaults) and any local Mode 1 signal rows.
  - Map the harness primitives to yours: "batch in one message" + `run_in_background`
    are Claude Code's. Codex `spawn_agent` users adapt to their concurrency model;
    on harnesses with no background/parallel dispatch, the honest fallback is
    inline (Case 3), not a blocking foreground dispatch.
  - If your routing manifest sends a "large/multi-subtask" route at the contract
    block, repoint it at `workflows/subagent-driven.md` so the mode + non-blocking
    decision happens first.

## 2026-05-29 - Extract Task Closure Protocol into its own canonical workflow

- Upstream commit: pending in this working tree
- Changed areas:
  - **NEW `templates/skill/workflows/task-closure.md`** — the cross-cutting
    closure gate now has its own correctly-named home: Task Closure Trigger
    Policy, the six closure steps, the 30-second AAR scan, Rationalizations to
    Reject, Red Flags. Its "record if needed" step (3) points into
    `update-rules.md` for the recording mechanics.
  - `templates/skill/workflows/update-rules.md` — closure gate + AAR +
    Rationalizations + Red Flags removed (moved to `task-closure.md`). Kept:
    Classification Guide, Sync Targets, and the **recording mechanics**
    (Recording Threshold, Search Before Record, Where To Record, Activation
    Check, Generalization Rule, Entry Tagging, Structural Placement), plus Rule
    Deprecation and Post-Update Health Check. New `## Task Closure` pointer
    section + `## Recording Lessons` H2 parent for the recording H3s.
  - `templates/skill/conformance.yaml` — split the `update-rules.md`
    must_contain block: closure-gate assertions (`## Task Closure Protocol`,
    `### Rationalizations to Reject`, `### Red Flags`, `## After-Action Review`)
    moved to a new `workflows/task-closure.md` entry; recording assertions
    (`### Recording Threshold`, `### Activation Check`, `### Generalization
    Rule`) stay on `update-rules.md`. Added `task-closure.md` to required_files.
  - Repointed closure-step refs (`fix-bug`, `change-managed`, `edit-templates`,
    `refactor-fanout`, `skill-composition.md`, `thin-shells.md`), Rationalizations
    refs (`SKILL.md`, `WORKFLOW.md`, `full-migration.md`, `behavior-failures.md`,
    `TEMPLATES-GUIDE.md`, `protocols.md`), and all shells (3 template shells +
    4 generated root shells via `self-hosting-shell-base.md`) from
    `update-rules.md` → `task-closure.md`.
- Why it matters: the closure gate is cross-cutting (every behavior-changing
  task runs it) but its canonical text lived inside a file named for rule
  updates, so every other workflow said "run Task Closure Protocol from the
  rule-update workflow" — an ownership inversion held together only by
  hand-written cross-refs. `rationalizations-table.md` / `red-flags-stop.md`
  were already extracted to `protocol-blocks/`; this completes that half-done
  extraction. The gate now decides *whether* to record; `update-rules.md`
  decides *how*.
- Downstream refresh guidance:
  - **STOP — do not apply the default "copy new mechanism files whole" step for
    this change if your `update-rules.md` is localized or structurally diverged**
    (translated to another language, or you keep Blast-Radius Buckets / extra
    sections inside it). Dropping upstream's English `task-closure.md` in as-is
    leaves the closure gate **duplicated in two files** — your localized
    `update-rules.md` still holds it, now alongside an English `task-closure.md`.
    Instead, **extract your own closure sections** (Task Closure Protocol, Trigger
    Policy, Rationalizations to Reject, Red Flags, After-Action Review) out of your
    local `update-rules.md` into a new `task-closure.md`, preserving your language
    and local placement, then **delete those sections from `update-rules.md`**.
  - This is an **additive** change at the *upstream* level (chosen over renaming
    `update-rules.md`, which would risk losing downstream-local content on every
    refresh) — but inside *your* repo it is still a content move, not a file copy.
    Keep your project-specific recording targets and any locally-added
    Rationalizations rows.
  - Repoint every `workflows/update-rules.md` reference that means "run the
    closure gate" or "§ Rationalizations to Reject" → `workflows/task-closure.md`.
    Refs that mean "recording threshold / activation / generalization" stay on
    `update-rules.md`.
  - Update your `conformance.yaml` exactly as above (move the closure-gate
    assertions to a `workflows/task-closure.md` entry; keep the recording ones on
    `update-rules.md`; add `task-closure.md` to required_files), then validate
    against the freshly-cloned **upstream** manifest:
    `bash skills/<name>/scripts/check-version-conformance.sh skills/<name> --conformance <upstream-clone>/templates/skill/conformance.yaml`.
  - **conformance is presence-only — it verifies `task-closure.md` *has* the gate
    headings, never that `update-rules.md` no longer does.** A half-finished
    migration (new file created, old sections left in place) passes green. After
    migrating, **manually `grep` your `update-rules.md`** to confirm
    `## Task Closure Protocol`, `### Rationalizations to Reject`, `### Red Flags`,
    and `## After-Action Review` are **gone**. No check catches a leftover copy;
    it will silently drift from the canonical `task-closure.md`.

## 2026-05-29 - Self-hosting routing: kill spin-routes, merge overlap, demote long-run to modifier

- Upstream commit: pending in this working tree
- Changed areas:
  - `references/self-hosting-routing.yaml` — three routing-clarity fixes:
    1. Merged `revise-skill-principle` + `revise-reference` into one route
       `revise-skill-doc`. Both were the same underlying task (edit a skill
       doc, then close) and overlapped with no disambiguator. Added a `note:`
       pointing routing/description hit-rate work to `improve-activation-routing`.
    2. Both old routes' `workflow:` pointed back at a doc section already in
       their `required_reads` (`SKILL.md#core-principles`, `references/README.md`)
       — a route that does no routing. The merged route's `workflow:` now points
       to the real procedure `templates/skill/workflows/update-rules.md`.
    3. `long-run` reframed from a standalone task to a cross-cutting modifier
       via label + `note:` ("apply ON TOP of the matched primary route"). It
       routes by task *size*, not intent, so it competed with every real route
       (a big migration matched both `migrate-downstream` and `long-run`).
- Why it matters: self-hosting shells do NOT render the task list (the routing
  block in `scripts/sync-self-shells.sh` is hardcoded; the yaml is read at
  runtime and only path-validated at sync). So these edits change agent routing
  behavior without any shell drift. Removes two false route choices and one
  size/intent category confusion — the structural-complexity tax the simpler
  single-flow skills avoid by construction.
- Downstream refresh guidance:
  - This is a self-hosting-only manifest; downstream projects own their own
    `routing.yaml`. No file to port. The transferable lesson: a `workflow:`
    that points back into its own `required_reads` is a spin-route — point it
    at a real procedure or delete it. And task-size belongs as a modifier
    layered on the matched route, never as a sibling task entry.

## 2026-05-28 - Subagent Mode 1: Parallelism Premise + stale anchor cleanup

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/subagent-driven.md` — new
    `### Parallelism Premise (precondition for the Iron Law)` subsection
    inserted between the Iron Law block and `### Default habit`. Adds a
    third question before every `spawn_agent`: "what is the main agent
    doing **while** the subagent runs?" Without parallel work the
    dispatch is indirection theater — same wall-clock as inline plus
    coordination overhead, zero efficiency gain. Includes a
    context-isolation exception for cases where inline reads would
    drown the main context with raw file content.
  - `templates/skill/workflows/{plan-feature,change-managed,fix-bug}.md` —
    three stale `#mode-1-surface-sub-step-auxiliary-delegation` anchor
    fragments repaired to `#mode-1-direct-auxiliary-delegation`, with
    the display text "§ Mode 1: Surface" updated to
    "§ Mode 1: Direct Auxiliary Delegation". Followup to upstream
    `c0bc072` (2026-05-20) which renamed the Mode 1 heading but left
    these cross-refs stale.
- Why it matters: the existing Iron Law's "mechanical + time-consuming +
  only-need-result" trigger implicitly assumed the main agent has parallel
  work, but never said so. Agents would `spawn_agent`, then idle waiting
  for the result, paying coordination cost with no wall-clock gain.
  Parallelism Premise makes the precondition explicit and surfaces the
  honest context-budgeting exception. The anchor cleanup is path-integrity
  debt from `c0bc072`; discovered via the cut/stop (C) audit, not via a
  user trip — but it would silently misroute any agent following the link.
- Downstream refresh guidance:
  - Port the `Parallelism Premise` subsection verbatim into your local
    `subagent-driven.md` between Iron Law and `Default habit`. The
    principle is project-agnostic; only adjust path references inside
    the examples if your skill renames Mode 1's framing.
  - Search local workflows for any `#mode-1-surface-sub-step-auxiliary-delegation`
    references and replace with `#mode-1-direct-auxiliary-delegation`.
    If you haven't pulled the `c0bc072` rename yet, port both in the
    same pass.

## 2026-05-25 - Blast-radius bucket closure triggers

- Upstream commit: pending in this working tree
- Changed areas:
  - `references/protocols.md` — added § "Blast-Radius Buckets (closure
    trigger refinement)" subsection under Task Closure Protocol.
    Introduces per-path A/B/C classification (A = full closure incl.
    smoke + path-integrity gates, B = lightweight AAR only,
    C = skip closure entirely), the multi-file max-bucket rule, the
    unknown-path default-B rule, and the "trivial edit in A still =
    full closure" mechanical rule. Bucket path lists are this repo's
    specific layout.
  - `references/self-hosting-shell-base.md` — replaced the 3-bullet
    task-type closure trigger with a 6-bullet blast-radius bullet
    block that names A/B/C buckets, key combination rules, the
    Q&A/read-only exemption, and a pointer to protocols.md for full
    path lists. All 4 root shells (AGENTS / CLAUDE / CODEX / GEMINI)
    + `.cursor/rules/workflow.mdc` regenerated via
    `sync-self-shells.sh`.
- Why it matters: the prior trigger model (Pure Q&A / Code change /
  Skill docs) was too coarse — every non-Q&A edit ran lightweight
  AAR even on README / examples / unlinked references, paying
  recurring "load template + reason through 4 questions" overhead
  with near-zero hit rate. Blast-radius keys the trigger off the
  file path itself, so low-risk content edits (Bucket C) skip
  closure outright; only entry shells, routing yaml, scripts, and
  template `.tpl` files (A) still get the full gate.
- Downstream refresh guidance:
  - The blast-radius methodology is project-agnostic; the **A/B/C
    path lists are per-repo**. Downstream projects adopting this
    refinement should mirror the subsection structure in their own
    `skills/<name>/references/protocols.md` and fill in their own
    file classifications.
  - The shell-base bullets reference blast-radius with parenthetical
    examples ("entry shells / SKILL.md / routing yaml / scripts /
    `*.tpl`"). Adjust the parentheticals when porting if the
    downstream's high-risk surface differs.
  - **No template file changed.** This is currently a
    self-hosting-only refinement. Promote to
    `templates/skill/workflows/update-rules.md` only after a second
    project pressure-tests the bucket model — applying SKILL.md
    Rule 10 (no template additions without two-project pressure).

## 2026-05-21 - Mode 1 → Direct Auxiliary Delegation + Inspect→Dispatch Pitfall + Interception Transparency

- Upstream commit: pending in this working tree
- Changed areas: rewrote `templates/skill/workflows/subagent-driven.md`
  (Mode 1 章节 renamed "Direct Auxiliary Delegation", removed
  degraded-harness information-display isolation entire section,
  simplified Decision flow to no Y/N user round-trip, added Iron Law
  declaration, added Negative list + reverse-failure Pitfall, added
  Inspect→Dispatch transition Pitfall with named anchor, added new
  top-level "Interception Transparency Rule" section, updated
  Rationalizations + Red Flags); added top-level pervasive
  reverse-question cross-refs to `fix-bug.md`, `plan-feature.md`,
  `change-managed.md`, `refactor-fanout.md`.
- Why it matters: the chaos project's subagent-driven Mode 1 went
  through 6+ iteration rounds on real chaos task screenshots (5/19 →
  5/21). Key empirical findings now propagated to upstream:
    1. **Global authorization removes the Y/N round-trip** — once
       `~/.codex/config.toml` has `developer_instructions = "Subagents
       may be used proactively..."`, Codex no longer guards
       `spawn_agent`. Earlier "被拦截才问" / "Surface Y/N then spawn"
       designs were Codex workaround content; obsolete with global
       config.
    2. **Inspect → Dispatch transition** is the most severe real
       failure mode observed — main agent finishes pre-work (reading
       rules / report / identifying multiple targets) and continues
       inline by inertia into implementation, missing the explicit
       phase switch. Anchor name lets agent self-check and user
       interrupt use the same vocabulary.
    3. **Interception transparency is a universal rule**, not just
       a `spawn_agent` workaround — any tool / permission / constraint
       block should surface to the user, not silently fall back to
       plan B. This is a separate concern from Mode 1's decision-time
       self-judgment.
    4. **LLM bias is real and structural** — even with Iron Law +
       named Pitfalls + explicit two-step separation, the agent will
       sometimes skip the reverse-question and inline. Soft rules
       improve the trigger rate but don't root-cause it. User
       monitoring remains the necessary backstop. Documented in the
       Pitfalls section.
- Downstream refresh guidance: for each downstream `subagent-driven.md`:
    1. Replace Mode 1 章节 header / content with the new "Direct
       Auxiliary Delegation" version
    2. Remove the "Mode 1 on degraded harness: information-display
       isolation" section entirely (obsolete with global Codex auth)
    3. Add the new "Interception Transparency Rule" section
    4. Update Decision flow to remove Y/N round-trip
    5. Update Rationalizations + Red Flags per upstream
  For each of `fix-bug.md` / `plan-feature.md` / `change-managed.md` /
  `refactor-fanout.md`: add top-level pervasive reverse-question
  cross-ref. Project-specific workflows (e.g. chaos's
  `implement-feature.md`, chaos_web's `add-page-or-module.md` etc.)
  should mirror the same top-level cross-ref. Downstream should also
  consider adding the Inspect → Dispatch Pitfall + Negative list +
  Interception transparency content somewhere always-read (e.g.
  `rules/project-rules.md`) — chaos puts it there, you can too.
  No routing.yaml or conformance.yaml changes required.

## 2026-05-20 - Surface mode in subagent-driven (Mode 1) — sub-step auxiliary delegation

- Upstream commit: pending in this working tree
- Changed areas: restructured `templates/skill/workflows/subagent-driven.md`
  into two modes — new `## Mode 1: Surface (Sub-step Auxiliary Delegation)`
  (signal admission test + 5-signal reverse-question list + decision flow
  + job-vs-auxiliary distinction + display-isolation fallback for Codex
  and other degraded harnesses); renamed original `## When to Use` to
  `## Mode 2: Four Phases (When to Invoke This Mode)`; shared sections
  (Harness Compatibility / Rationalizations / Red Flags / Degraded Mode)
  retained and re-labelled. Updated cross-refs in
  `templates/skill/workflows/fix-bug.md` Step 6 (test/build → Surface
  signals #1/#2), `templates/skill/workflows/plan-feature.md` Step 3
  (wide grep → Surface signal #3) and Step 7 (multi-hour
  multi-subtask → Mode 2 Four Phases), and
  `templates/skill/workflows/change-managed.md` Step 3 (≥ 5-file
  batch homogeneous edits → Surface signal #4 or `refactor-fanout.md`
  if planned from start). Companion plan at
  `docs/plans/2026-05-20-subagent-surface-hints.md`.
- Why it matters: three earlier chaos screenshots showed main-agent
  doing test debugging / wide explore / batch edits inline when the
  work was clearly auxiliary (mechanical + time-consuming +
  only-need-result). Previous tuning attempts (fix-bug Hypothesis
  Fan-out, plan-feature Step 3/7 subagent hints, refactor-fanout
  workflow) didn't catch these moments because they framed dispatch
  as "task-size triggered" — and the agent's task-size judgment is
  systematically biased toward inline ("I'll just do one more file").
  Reverse-question framing ("是不是多余") inverts the bias: the agent
  must defend "not redundant" instead of "should dispatch", and
  defending "not redundant" on mechanical sub-steps is hard. The
  admission test (reverse-question passes + scenario specific)
  filters out task-size signals that previously slipped through.
  Mode 1 is default — main-agent inline stays as fallback; Mode 2
  Four Phases is the existing pattern for planned multi-subtask work.
  Codex / Cursor / Gemini get display-isolation fallback (Yes = paste
  conclusion only; No = paste full output), which gives visible
  benefit on degraded harnesses even though context isolation is
  impossible there.
- Downstream refresh guidance: this is an **incremental insertion**,
  not a file replacement. For each downstream `subagent-driven.md`:
  (1) insert the new `## Mode 1: Surface` block before the existing
  `## When to Use`; (2) rename `## When to Use` → `## Mode 2: Four
  Phases (When to Invoke This Mode)`; (3) add a "two modes" overview
  at the file top; (4) leave all other sections (Phase 1-4
  descriptions / Rationalizations / Red Flags / Degraded Mode /
  project-specific examples) untouched, including project-local
  edits. If the downstream `subagent-driven.md` has already added
  its own sub-step delegation mechanism, diff against the new Mode 1
  and take the union — do not overwrite. Then patch the 3 workflow
  cross-refs in `fix-bug.md` / `plan-feature.md` /
  `change-managed.md` to point at Mode 1: Surface; mirror the same
  cross-ref pattern in project-specific workflows that share the
  inspect-then-edit / explore-then-action shape (chaos's
  `implement-feature.md`, chaos_web's
  `add-page-or-module.md` / `add-amis-page.md` /
  `add-hybrid-renderer.md` / `fix-schema-error.md`). No routing.yaml
  changes required; no conformance.yaml changes required (Mode 1 is
  a tuning, not a contract).

## 2026-05-19 - Surface subagent fan-out at the 3 highest-ROI downstream moments

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/workflows/fix-bug.md` (added § Hypothesis
  Fan-out section + cross-ref from Step 3); `templates/skill/workflows/plan-feature.md`
  (Step 3 + Step 7 now point at `subagent-driven.md` when scope justifies it);
  `templates/skill/workflows/refactor-fanout.md` (new file — 3-phase
  find-usage / fan-out / merge workflow for ≥5-site refactors);
  `templates/skill/routing.yaml` (new `refactor-fanout` task route + cross-ref
  from `change-managed` row); regenerated `templates/skill/SKILL.md.template`
  + thin shells via `sync-routing.sh`.
- Why it matters: downstream users' three highest-frequency tasks — fixing
  bugs, planning features, doing N-point refactors — each have a clear
  parallelism opportunity that the existing workflows did not surface:
    1. **Bugs with 2+ live hypotheses** — serial elimination pollutes the
       main context with rabbit holes. Fan-out gives each hypothesis its
       own subagent and brings back only verdicts. Optional, triggers only
       when ≥ 2 hypotheses + > 30% context budget at risk.
    2. **Plans whose inspection reads > 20 files** — Step 3 (Inspect first)
       was implicitly inline; now it explicitly suggests an `explore`
       subagent and returning a structured summary instead. Optional.
       Step 7 (Prepare execution context) now also flags that the
       implementer is often itself a subagent, so the reading list is
       planned as `Inputs` contracts rather than ad-hoc.
    3. **N-point refactors (rename / signature change / interface
       extract)** — new dedicated workflow because cut-points + parallel
       batches + cross-batch consistency check are different mechanics from
       generic `change-managed.md`. Routes only fire on ≥5-site refactors;
       smaller refactors still use `change-managed.md`.
  All three additions explicitly carry a "skip on degraded harness or when
  scope is small" clause — the dispatch overhead must be paid back by real
  context savings, otherwise it is reverse ROI. None of the three is added
  to `conformance.yaml` as a required section: they are optimization
  patterns, not safety mechanisms.
- Downstream refresh guidance: pull the three workflow files
  (`fix-bug.md` § Hypothesis Fan-out paragraph, `plan-feature.md` Step 3 +
  Step 7 updates, `refactor-fanout.md` whole-file copy) and add the
  `refactor-fanout` row to your local `routing.yaml` (in the order
  upstream put it — after `change-managed`). Then run
  `bash skills/<name>/scripts/sync-routing.sh <name>` to regenerate
  SKILL.md and shells. If your project has never had a 5+-site refactor,
  you can skip `refactor-fanout.md` and the routing row entirely — re-pull
  when the situation actually appears. The fan-out / explore-subagent
  recommendations are written as optional clauses, so downstream agents
  on Cursor / Codex / Gemini (no native dispatch) can ignore them
  without breaking the workflow shape.

## 2026-05-19 - Strip complex-plan canonical schema; only `prd.md` required

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/workflows/plan-feature.md` (rewrote § Complex
  Plan, § Complex Steps, workflow-state blocks, completion checklist),
  `docs/plans/README.md` (rewrote complex-plan section), `templates/skill/conformance.yaml`
  (removed `## Complex Task Dossier` / `decisions.md` / `implement.jsonl` /
  `check.jsonl` from `must_contain`; added `## Complex Plan` + `prd.md` instead),
  `references/thin-shells.md`, `TEMPLATES-GUIDE.md`,
  `templates/skill/workflows/update-rules.md` (Plan-closure prompt phrasing).
- Why it matters: the previous complex-plan ("dossier") schema mandated a
  7-file structure — `prd.md`, `decisions.md`, `checklist.md`, `research/`,
  `evidence/`, `implement.jsonl`, `check.jsonl` — for any plan that hit the
  Complexity Gate. Audit found:
    1. **0 plans ever used the dossier shape.** The one real plan in
       `docs/plans/` (`2026-05-12-thin-shells-generator.md`) satisfied
       multiple Complex triggers (architecture choice, external dependency,
       multiple files) yet the author wrote it as a simple single file.
       The protocol was rejected in its first contact with reality.
    2. **No consumer for the JSONL files.** `implement.jsonl` and
       `check.jsonl` chose JSONL over markdown, implying script consumption.
       `grep -rln '\.jsonl' scripts/ templates/skill/scripts/` → 0 hits.
       Same shape as the recently-removed `<!-- external-fact -->` marker:
       protocol defined, no consumer, runs empty forever.
    3. **Schema without template.** The simple plan had `_TEMPLATE.md`;
       the dossier had only prose description in README + workflow. Authors
       would have to hand-assemble 7 files from text instructions —
       "stored, not activated" (SKILL.md Pitfall #4).
    4. **100% cognitive tax on simple-plan authors.** Every reader of
       `docs/plans/README.md` (~20% dossier content) and `plan-feature.md`
       had to scan past the dossier rules to confirm "I don't need this".
    5. **Conformance manifest locked the shape into a contract.** Downstream
       skills running `check-version-conformance.sh` were required to
       reproduce `## Complex Task Dossier` + JSONL filenames — propagating
       the imagined-pain protocol as a hard contract.
  The form (a directory with multiple files) is not the problem — a real
  complex plan naturally wants more than one file. The problem was
  pre-defining **which** files, with **canonical names**, under a **forced
  trigger**, before any real complex plan existed to validate the schema.
  Now: complex plan = directory + `prd.md` (only required file). Everything
  else is the author's call; conventions earn the right to exist by
  appearing in two or more real plans first.
- Downstream refresh guidance: in your downstream copy of
  `workflows/plan-feature.md`, replace § Complex Task Dossier (or whatever
  your local equivalent is called) with the new minimum: directory +
  `prd.md` required, no canonical names for siblings. Remove any local
  copy of the JSONL row shape. Update completion checklist to drop hard
  references to `decisions.md` / `implement.jsonl` / `check.jsonl` / `research/`
  / `evidence/`. If your local `docs/plans/README.md` mirrors the upstream
  shape, apply the same trim. If a project's actual past plans found a
  sibling convention useful (e.g. a `decisions.md` log), that's fine —
  but keep it as observed convention, not enforced contract; don't add it
  to a local conformance manifest.

## 2026-05-19 - Remove 5 imagined-pain template scripts; merge into `audit-orphans.sh`

- Upstream commit: pending in this working tree
- Changed areas: deleted `templates/skill/scripts/check-external-facts.sh`,
  `templates/skill/scripts/test-trigger.sh`,
  `templates/skill/scripts/check-description-routing.sh`,
  `templates/skill/scripts/audit-references.sh`,
  `templates/skill/scripts/audit-route-paths.sh`;
  added `templates/skill/scripts/audit-orphans.sh` (84 lines, replaces
  audit-references + audit-route-paths' high-value 80%);
  updated `scripts/check-all.sh`, `scripts/check-self-scenarios.sh`,
  `scripts/README.md`, `templates/skill/scripts/smoke-test.sh § 4h`,
  `templates/skill/scripts/check-growth-health.sh` (script-size case
  branches), `templates/skill/workflows/update-rules.md`,
  `templates/skill/workflows/maintain-docs.md` (removed § 1c),
  `templates/skill/workflows/update-upstream.md`,
  `templates/README.md` (file listing + budget rows + Anti-Drift step 6),
  `README.md`, `README.zh-CN.md`, `WORKFLOW.md`,
  `references/self-hosting-routing.yaml`, `references/protocols.md`,
  `references/layout.md`, `references/multi-skill-routing.md`,
  `workflows/upgrade-downstream.md`, `examples/behavior-failures.md`,
  `docs/linuxdo-project-introduction.md`.
- Why it matters: a structural audit found these 5 scripts (~1166 lines)
  enforced disciplines no project would actually follow:
    - `check-external-facts.sh` required authors to hand-mark every
      vendor/tool/runtime fact with `<!-- external-fact: verified=... -->`
      comments. No project ever did; the script ran empty.
    - `test-trigger.sh` (554 lines) used `claude -p` to measure description
      activation rate. Almost no downstream cron-ran it.
    - `check-description-routing.sh` (125 lines of YAML parsing) flagged
      things a human eyeballs in 30 seconds re-reading description.
    - `audit-references.sh` (214) and `audit-route-paths.sh` (191) both
      validated "is this file linked?" at slightly different strictness;
      one combined script covers the high-value orphan check.
  The pattern: each script solved an *imagined* pain. The cost was real —
  every downstream skill carried ~1.2k lines of bash + workflow text
  pointing at protocols nobody enforced. **Stored, not activated** (SKILL.md
  Pitfall #4) applies to scripts as much as to references. Net delete:
  ~1082 lines after counting the 84-line replacement.
- Downstream refresh guidance: delete the same 5 files from
  `skills/<name>/scripts/`. Copy `audit-orphans.sh` from upstream. Run
  `(cd skills/<name> && bash scripts/audit-orphans.sh)` once after the
  refresh — if any orphan surfaces, decide per file whether to add an
  activation pointer or delete the file. Remove references to the deleted
  scripts from local copies of `workflows/update-rules.md`,
  `workflows/maintain-docs.md`, `workflows/update-upstream.md`. If your
  downstream wired any of the 5 into a CI step or a custom check-all
  orchestrator, drop those lines. The discipline they enforced moves to
  human re-read; the protocol-blocks rationalizations table stays.

## 2026-05-12 - Self-hosting thin-shell generator (`sync-self-shells.sh`)

- Upstream commit: pending in this working tree
- Changed areas: `references/self-hosting-shell-base.md` (new — common body),
  `references/self-hosting-shells.yaml` (new — per-harness deltas),
  `scripts/sync-self-shells.sh` (renamed from `sync-self-routing.sh`,
  rewritten for whole-shell generation),
  `scripts/check-self-shells.sh` (renamed from `check-self-routing.sh`,
  internal call updated),
  `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`,
  `.cursor/rules/workflow.mdc` (now generated, do NOT hand-edit),
  `scripts/check-all.sh` (label + script-name update),
  `scripts/README.md`, `REFERENCE.md`, `references/self-hosting-routing.yaml`
  (header comment), `templates/skill/scripts/smoke-test.sh § 7`,
  `UPSTREAM-CHANGES.md`
- Why it matters: the previous `sync-self-routing.sh` only managed the routing
  block between `<!-- SELF_ROUTING_BLOCK_START -->` markers (~12 lines per
  shell). The other ~18 lines per shell — opening, Auto-Triggers, Red Flags,
  per-harness notes — were hand-maintained. Direct diff of the four shells
  pre-generator showed **5 unintended drifts already present**:
    1. `AGENTS.md` had a unique 2-paragraph opening; the other three diverged
       on whether to link `[references/layout.md]`.
    2. CODEX/GEMINI lost the `"I already read it" is not valid — context
       compresses, routes differ` clause that AGENTS/CLAUDE carry.
    3. CODEX/GEMINI lost the `See § Rationalizations to Reject` reference
       in the first Red Flag bullet.
    4. CODEX had a short version of the ANTI-TEMPLATES Red Flag without the
       file reference.
    5. `.cursor/rules/workflow.mdc` Red Flag still said `SKILL.md stays ≤ 100
       lines` — outdated since 2026-05-09's dual-budget change (description
       ≤ 25 + body ≤ 90). Hand-maintained docs drift in proportion to file
       count × edit cadence.
  Pointer-style solutions ("CLAUDE.md says 'go read E'") fail by the same
  mechanism as the Soft-pointer-only shell pitfall (SKILL.md § Common
  Pitfalls #2): harness context-compaction can drop the pointer between
  session start and the moment the agent needs the protocol. Symlinks fail
  on Windows + force 100% identity, killing legitimate per-harness deltas
  (e.g. CODEX's `apply_patch` notes). Therefore: build-time generation,
  read-time literal content.

  Source-of-truth files:
    - `references/self-hosting-shell-base.md` — common body (Auto-Triggers +
      Red Flags). Single place to update the wording every shell shares.
    - `references/self-hosting-shells.yaml` — per-harness `file`, `title`,
      optional `frontmatter` (only `.mdc` uses), `opening`, optional
      `appended` (only CODEX uses for `## Codex-specific notes`).

  Generation:
    - `scripts/sync-self-shells.sh` composes each entry from base + yaml +
      hardcoded routing block, writes to disk. Targets: 4 root shells +
      `.cursor/rules/workflow.mdc` in full-file mode; `.cursor/skills/.../
      SKILL.md` in routing-block-only mode (the rest is Cursor-registration
      specific and stays hand-maintained; description identity is checked
      separately by `check-self-shells.sh`).
    - `--check` mode diffs generated content against on-disk and exits
      non-zero on drift — wired into `check-all.sh` ("self-hosting shells +
      activation check").

  Drift outcome after generation (verified by `diff` of resulting files):
    - CLAUDE ↔ GEMINI: differ by only the `# CLAUDE.md` / `# GEMINI.md` title.
    - CLAUDE ↔ CODEX: title + the legitimate `## Codex-specific notes`
      appended section.
    - AGENTS ↔ CLAUDE: title + AGENTS's unique 2-paragraph opening
      (intentionally preserved as per-harness delta — AGENTS is the most
      generic shell, read by tools that don't have a specific narrowing).
    - All five files: `--check` returns OK.

  No new external dependencies (custom yaml subset parser inline; pattern
  matches `_parse_conformance.py`). One Python composition bug (extra blank
  line from a stray `\n` in a join part) was caught by visual inspection of
  `head -8 CLAUDE.md` and fixed before this commit.
- Downstream refresh guidance: this generator is **upstream-only**
  maintenance. Do NOT copy `sync-self-shells.sh`, `self-hosting-shell-base.md`,
  `self-hosting-shells.yaml`, or `check-self-shells.sh` into downstream
  projects. Downstream shells follow `templates/shells/` (a separate seed
  set that each project owns after scaffold). If a downstream project finds
  its own four shells drifting and wants the same generator pattern, port
  the structure but keep the source files local — they are project knowledge,
  not template content.

## 2026-05-12 - `Status: superseded by` field + check for reversed UPSTREAM-CHANGES entries

- Upstream commit: pending in this working tree
- Changed areas: `UPSTREAM-CHANGES.md` (schema doc),
  `templates/skill/workflows/update-upstream.md` (step 3 read semantic),
  `scripts/check-upstream-supersedes.sh` (new),
  `scripts/check-all.sh` (wire new check), `UPSTREAM-CHANGES.md` (this entry)
- Why it matters: until now, UPSTREAM-CHANGES.md was a strictly append-only
  time log. The archive policy moves old entries out of context, but it does
  not address the second-order problem: **later commits can reverse the
  guidance of earlier entries, and the older entry has no signal that it has
  been overruled**. A downstream refresh agent reading an archived entry from
  3 months ago will follow its instructions verbatim — even if upstream
  removed the file it tells them to add. Probability across many downstream
  skills and a multi-quarter horizon approaches 1.

  Mechanism: entries gain an optional `Status:` line as their first bullet.
  Two values:
    - `Status: superseded by YYYY-MM-DD - <title>` — newer entry replaces this
      guidance; refresh agents follow the newer one, skip this one.
    - `Status: deprecated — <one-line reason>` — mechanism removed entirely;
      no replacement.
  Pointers are **one-way** (older entry → newer entry). The newer entry can
  mention the supersede in prose but does not carry machine markup —
  bidirectional references would double the bookkeeping cost without
  improving check coverage.

  Enforcement: `scripts/check-upstream-supersedes.sh` validates every
  `Status: superseded by` reference resolves to a real `## YYYY-MM-DD -
  title` H2 heading in `UPSTREAM-CHANGES.md` or
  `UPSTREAM-CHANGES-archive.md`. Fence-aware (schema examples inside
  ```` ```text ```` blocks are skipped, not treated as references).
  Wired into `check-all.sh` between the change-note guard and the routing
  manifest check.

  Read protocol: `templates/skill/workflows/update-upstream.md § Procedure
  step 3` now instructs downstream refresh agents to skip any entry whose
  first bullet starts with `- Status: superseded by …` or `- Status:
  deprecated …`.
- Downstream refresh guidance: pull the updated
  `workflows/update-upstream.md` as a mechanism-owned file. The
  `check-upstream-supersedes.sh` script is upstream-only maintenance —
  do NOT copy it into downstream projects. Downstream UPSTREAM-CHANGES
  consumption changes are read-only: when a refresh entry's first bullet
  is `Status: superseded by …`, follow the entry it points to instead.
  When `Status: deprecated`, skip entirely.

## 2026-05-12 - Tier-2 maintenance ledger (`.maintenance-log.yaml`)

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/workflows/maintain-docs.md`,
  `templates/skill/scripts/smoke-test.sh`, `templates/README.md`,
  `.maintenance-log.yaml` (new — upstream self-hosting bootstrap),
  `UPSTREAM-CHANGES.md`
- Why it matters: closes a dangling clock in the Tier 0/1/2 model shipped
  on 2026-05-11. The Tier-2 trigger list included "Smoke-test Tier-0
  flagged a duplicate **and** the previous Tier-2 pass was more than ~30
  days ago" but nothing in the architecture recorded when a Tier-2 pass
  actually ran. Three observable failure modes:
    1. **Never triggers** — agent reads the condition, finds no record,
       treats "no record" as "no event", skips Tier-2. The drift the tier
       was designed to catch accumulates silently (real example: chaos_web
       audit found 4 verbatim-dup entries before any agent noticed).
    2. **Always triggers** — different agent reads the same condition,
       treats "no record ≡ infinitely old", runs full reorg every time
       smoke-test reports a dup. Token cost balloons.
    3. **Inconsistent across sessions** — the two agents above are the
       same agent on different days. Tier-2 fires unpredictably and no
       decision is reproducible.
  Fix: introduce `.maintenance-log.yaml` at the skill root as the per-file
  Tier-2 timestamp. Schema is lenient (`path` required, `last_tier2`
  required once a pass has run, rest advisory) so the file stays
  hand-editable. `maintain-docs.md § Step 7` now adds the write step as a
  Tier-2 closure gate — Tier-2 is incomplete until the ledger is updated.
  `smoke-test.sh § 2a` reads the ledger on every detected dup `##` heading
  and prints one of three Tier-2 hints (no entry / > 30d / ≤ 30d). The
  duplicate itself still always fails; the ledger only governs the *reorg
  recommendation* on top.

  Side effect: `smoke-test.sh` budget raised from 800 to 850 lines in
  `templates/README.md`. The ~25 lines of helpers + advisory branch are
  the minimum that closes the dangling clock. **Next addition to
  `smoke-test.sh` forces extraction** into a `check-<concern>.sh`
  companion (same pattern as `check-description-routing.sh`); the next
  budget bump is not on the table.
- Downstream refresh guidance: pull the updated `workflows/maintain-docs.md`
  and `scripts/smoke-test.sh` as mechanism-owned files. Then, for each
  long-lived entries-style file in your skill (`references/gotchas.md`,
  any `*pitfall*.md`, plus optionally entry-style logs like a project's
  decision log or upstream-changes log), add an entry to a new
  `skills/<name>/.maintenance-log.yaml` per the schema in `Step 7`. If
  no Tier-2 has been run on that file yet, omit `last_tier2:` — smoke-test
  will treat the first dup as a baseline-trigger and recommend a Tier-2
  baseline pass. Do **not** copy the upstream `.maintenance-log.yaml`
  from this repo; it is upstream-state, not a template.

## 2026-05-12 - rules/*.md categorization guidance in maintain-docs Step 3

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/workflows/maintain-docs.md`,
  `UPSTREAM-CHANGES.md`
- Why it matters: Tier 2 § Step 3 "Categorize (before splitting)"
  previously described categorization only for entries-style files
  (gotchas / pitfalls — promote `**[topic]**` tags to H2 categories).
  For `rules/*.md`, which don't carry tags, the workflow gave no
  concrete recipe — agents crossing the Tier 2 trigger had to invent
  a grouping axis from scratch every time. Step 3 now distinguishes
  the two file types and articulates three common axes for
  `rules/*.md`: module / surface boundary, responsibility / lifecycle
  phase, and trigger scenario, with a "pick exactly one axis per file"
  constraint. Mixing axes is reframed as a split signal (Step 6), not
  a categorization signal. Single H2 growing past ~30 bullet-rules is
  the recommended sub-rule extraction threshold.
- Downstream refresh guidance: pull the updated
  `workflows/maintain-docs.md` as a mechanism-owned file. No migration
  required for existing rule files; the new guidance only fires when
  a `rules/*.md` crosses the Tier 2 bullet-rule trigger (> 25
  bullet-level rules) or when the user explicitly asks for cleanup.

## 2026-05-11 - Tiered maintenance triggers (bash gate / AAR scan / full pass)

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/workflows/update-rules.md`,
  `templates/skill/workflows/maintain-docs.md`, `UPSTREAM-CHANGES.md`
- Why it matters: agent-led file cleanup costs tokens. Running the full
  reorganization scan on every commit, or every time anyone touches a
  gotchas file, would burn tokens without proportional benefit. The
  workflow now articulates a three-tier trigger discipline so the
  expensive scan runs only when cheap signals have already flagged
  something:
    - Tier 0 (bash, free, every commit): smoke-test `grep | uniq -d` on
      `gotchas.md` / `*pitfall*.md` `##` headings — catches verbatim
      copy-paste duplicates deterministically.
    - Tier 1 (agent, cheap, on every AAR closure that records a new
      entry): `update-rules.md § Search Before Record` upgraded to
      include a gotchas-specific scan recipe — list existing tags + ##
      headings via grep, then have the agent read 3–5 candidate entries
      and decide append / merge / skip. Cheap because the agent is
      already in context and only reads the candidate set, not the whole
      file.
    - Tier 2 (agent, expensive, threshold-triggered): full
      reorganization (dedup + categorize + split if needed). Only fires
      when entry count > 25, line count > 80% of cap, a recurring Tier-0
      dup signals drift, or the user explicitly asks. Expected cadence is
      "once or twice per file per year", not "every commit".
  `maintain-docs.md § Step 1b` was rewritten to make these triggers
  explicit (table + trigger list + token-cost intuition).
- Downstream refresh guidance: pull the updated `workflows/update-rules.md`
  and `workflows/maintain-docs.md` as mechanism-owned files. The Search
  Before Record block in `update-rules.md` now mandates the gotchas
  similarity scan at append time — agents already in AAR context should
  run the cheap grep recipe before appending to any pitfall file.

## 2026-05-11 - Gotchas dedup check + classification upgrade path

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/scripts/smoke-test.sh`,
  `templates/skill/references/gotchas.md`,
  `templates/skill/workflows/maintain-docs.md`,
  `UPSTREAM-CHANGES.md`
- Why it matters: real-data audit of a downstream chaos_web pitfall log
  surfaced two problems the existing architecture did not catch:
  1. **Copy-paste duplicate entries**. The file had 4 entries whose `##`
     heading text matched another entry verbatim — same pitfall recorded
     twice because the author had no quick way to see "did I write this
     already?". The previous gotchas check only enforced line count,
     not duplicates. `smoke-test.sh § 2a` now grep-dedups `## ` headings
     in `gotchas.md` / `*pitfall*.md` and fails when any heading appears
     more than once. Deterministic check, very low false-positive rate.
  2. **No classification upgrade path**. The template `gotchas.md` told
     authors how to write one entry but said nothing about how to keep
     50 entries scannable. By the time a real file hits 25+ entries
     with no organization, finding "is this already recorded?" is O(file)
     and duplicates appear (see point 1). The template comment now
     teaches a three-stage upgrade: stage 1 flat with `**[topic]**` tags
     (≤ 10 entries), stage 2 H2 categories with `###` entries (10–25),
     stage 3 split files (> 25 or > 400 lines). `maintain-docs.md
     Step 1b` was reordered to enforce the same pipeline: dedup →
     staleness → **categorize before splitting** → structural → tag →
     split as last resort. Result: existing files reorganize before
     splitting prematurely, and new files start with the right structural
     instinct.
- Downstream refresh guidance: pull the updated `scripts/smoke-test.sh`,
  `references/gotchas.md` (template-side; **do not overwrite a downstream
  copy that already has real entries**, just port the new comment block
  to it), and `workflows/maintain-docs.md` as mechanism-owned files.
  After the refresh, run `smoke-test.sh <name>` — if you have copy-paste
  duplicates in your gotchas/pitfall files, the new check will list them
  and you can dedup in one pass. If your gotchas file is > 10 entries,
  follow `maintain-docs.md § Step 1b` to categorize before any split.

## 2026-05-09 - SKILL.md dual budget + test-trigger per-source rates

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/scripts/smoke-test.sh`,
  `templates/skill/scripts/check-growth-health.sh`,
  `templates/skill/scripts/test-trigger.sh`,
  `templates/skill/workflows/maintain-docs.md`,
  `templates/skill/conformance.yaml`,
  `templates/README.md`, `references/progressive-rigor.md`,
  `references/conventions.md`, `SKILL.md`, `AGENTS.md`, `CLAUDE.md`,
  `CODEX.md`, `GEMINI.md`, `README.md`, `README.zh-CN.md`, `EXAMPLES.md`,
  `UPSTREAM-CHANGES.md`
- Why it matters: closes two diagnostic gaps surfaced when auditing real
  downstream skills.
  1. **SKILL.md dual budget.** A single 100-line cap forced description
     quality to cannibalize body clarity (or vice versa) — when a skill
     wrote a proper 15-line description with quoted trigger phrases, body
     budget shrank to 85 lines and forced cramped routing tables. The
     budget now splits into description ≤ 25 lines (activation gate) +
     body ≤ 90 lines (navigation hub), enforced separately by
     `smoke-test.sh` and reported separately by `check-growth-health.sh`.
     Total cap effectively rises from 100 to 115, but each half has its
     own discipline — description can't bloat past 25 by stuffing
     workflow keywords, body can't bloat past 90 by inlining rule content.
  2. **test-trigger.sh per-source rates.** The script now reports
     trigger rate broken down by source (description quoted phrases vs.
     routing.yaml trigger_examples vs. Common Tasks vs. body candidates),
     not just one combined number. A large description-vs-routing gap
     (≥ 30 points) flags that the description is missing whole task
     categories the routing.yaml introduces — the most common cause of
     low real-world activation rates. Real-data example: chaos showed
     overall 69% but split into description 100% / routing 50% — the
     gap pointed straight at six trigger categories (plan / model / docs
     / upstream / rule-maintenance / fallback) that lived in routing.yaml
     but never made it into the description.
- Downstream refresh guidance: pull the updated `scripts/smoke-test.sh`,
  `scripts/check-growth-health.sh`, `scripts/test-trigger.sh`, and
  `workflows/maintain-docs.md` as mechanism-owned files. After the
  refresh:
  - Re-run `smoke-test.sh <name>` — your SKILL.md may previously have been
    a single-budget pass; if description was already ≤ 25 lines, the
    dual budget will still pass.
  - Re-run `test-trigger.sh <name>` — the per-source rates surface
    coverage gaps that the single number used to hide. A description ≤
    20% trigger rate against routing.yaml entries is the smoking-gun
    signal for the chaos-shaped gap.

## 2026-05-09 - test-trigger.sh body-candidate scan

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/scripts/test-trigger.sh`,
  `UPSTREAM-CHANGES.md`
- Why it matters: when a skill keeps trigger phrases inside SKILL.md body
  (e.g. executable-style Tier-2 routes with `positive_signals:` lists)
  instead of in the frontmatter description / routing.yaml / Common Tasks,
  the previous `test-trigger.sh` couldn't extract anything and silently
  bailed with "No test prompts could be generated". Activation analysis
  effectively gave up. The script now:
  1. Always scans the body for quoted candidate trigger phrases, labeled
     with their nearest preceding heading.
  2. In static-analysis mode reports those candidates and flags the
     promotion gap (description has 0 phrases but body has N → promote).
  3. In live `claude -p` mode, when description / routing.yaml / Common
     Tasks together yield zero prompts, prints the body candidates as
     promotion advice instead of failing silently.
  4. Accepts `--include-body` to feed those body candidates into the
     trigger test as-if-promoted, measuring potential trigger rate after
     promotion (vs. current rate).
  Standard skill layouts (description + routing.yaml + Common Tasks) are
  unchanged — body extraction runs in addition, not instead.
- Downstream refresh guidance: pull the updated
  `skills/<name>/scripts/test-trigger.sh` as a mechanism-owned file. No
  workflow text changes; no breaking changes for existing skills.

## 2026-05-09 - Backward-compatible refresh guards

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/scripts/sync-routing.sh`,
  `templates/skill/workflows/update-upstream.md`, `UPSTREAM-CHANGES.md`
- Why it matters: closes two refresh gaps that affect downstream projects
  scaffolded before the recent template trims:
  1. `sync-routing.sh` was changed to stop generating `.codex/instructions.md`
     when the recent commits made `.codex/` optional. That left existing
     downstream copies with stale routing blocks that would never auto-update.
     The script now keeps `.codex/instructions.md` in its target list **only
     when the file already exists** — old downstream skills keep getting
     synced; new scaffolds don't introduce the file.
  2. `update-upstream.md` had no explicit step for "scan upstream for new
     mechanism files that don't exist locally". When upstream introduced
     `conformance.yaml`, `check-version-conformance.sh`, and
     `_parse_conformance.py`, downstream agents could miss them entirely
     unless they happened to compare directory listings. A new step 5 now
     requires that scan before the per-file compare loop, with whole-file
     copy permitted under the existing Hard Rule #4 for missing files.
- Downstream refresh guidance: pull the updated `sync-routing.sh` and
  `update-upstream.md` as mechanism-owned files. Re-run
  `update-upstream.md` step 5 against your skill — it will surface any
  upstream mechanism files you don't yet have (most projects will need
  to copy `conformance.yaml`, `check-version-conformance.sh`, and
  `_parse_conformance.py` if they haven't yet).

## 2026-05-09 - Bloat reduction across templates, references, examples, READMEs

- Upstream commit: pending in this working tree
- Changed areas: 33 files. Deletions:
  `templates/migration/` (entire dir — `migrate.sh`, `resume.sh`, README),
  `templates/checklists/post-migration.md`,
  `templates/protocol-blocks/iron-law-header.md`,
  `templates/shells/.codex/instructions.md`, `.codex/instructions.md` (root),
  `examples/{migration,project-types,self-evolution,README}.md`.
  Major slims: `WORKFLOW.md` (-160 lines, removed migration FSM),
  `README.md` + `README.zh-CN.md` (-296 lines combined),
  `references/layout.md` (-167 lines, split out three new files),
  `references/thin-shells.md` (-141 lines, per-tool moved out).
  New references: `references/{progressive-rigor,positioning,per-tool-shells}.md`.
  Major rewrite: `EXAMPLES.md` (now consolidated body, was a stub).
  Mechanism updates: `scripts/sync-self-routing.sh` and
  `templates/skill/scripts/sync-routing.sh` no longer generate
  `.codex/instructions.md`; `smoke-test.sh` makes `.codex/instructions.md`
  optional instead of required; `examples/README.md` route in
  `references/self-hosting-routing.yaml` repointed to `EXAMPLES.md` +
  `examples/behavior-failures.md`.
  Net: +476 / −2117 lines.
- Why it matters: removed mechanisms that solved problems that don't
  recur — the migration state machine for crashes that don't happen, the
  duplicate Codex shell for harnesses that all read `AGENTS.md`, four
  long examples files that no route ever activated, the reusable
  `iron-law-header` block that was referenced once. Split two oversized
  references (`layout.md`, `thin-shells.md`) so routing pulls only the
  relevant subsection. The architecture's own "small focused files"
  principle now applies to itself.
- Downstream refresh guidance: when running `update-upstream`, expect to
  delete several files in your downstream skill if you scaffolded from a
  prior upstream:
  - Delete `skills/$NAME/.codex/instructions.md` if your harness does not
    explicitly read it (most don't — `AGENTS.md` is canonical).
    `smoke-test.sh` no longer requires it.
  - If your downstream copied `templates/migration/`, `templates/checklists/`,
    or `templates/protocol-blocks/iron-law-header.md`, remove them — they
    are no longer maintained upstream.
  - Old long-form example files were consolidated into root `EXAMPLES.md`.
    `examples/behavior-failures.md` is the only example file kept.
  - For inbound links to former `references/layout.md` sections,
    repoint: `#progressive-rigor` → `progressive-rigor.md`,
    `#multi-skill-projects` → `multi-skill-routing.md` (Coexistence rules),
    Positioning section → `positioning.md`.
  - For inbound links to former `references/thin-shells.md § Per-Tool …`,
    repoint to `references/per-tool-shells.md`.

## 2026-05-09 - Wire conformance into the check suite + self-hosting parity

- Upstream commit: pending in this working tree
- Changed areas: `scripts/check-all.sh`,
  `templates/skill/workflows/update-upstream.md`,
  `references/self-hosting-conformance.yaml` (new),
  `references/README.md`, `scripts/README.md`, `UPSTREAM-CHANGES.md`
- Why it matters: closes three follow-on gaps that were left by the previous
  conformance commit:
  1. The conformance check shipped without being wired into `check-all.sh` —
     it was a "stored but not activated" tool (Pitfall #4 in `SKILL.md`).
     Now `check-all.sh` runs both the template manifest and the new
     self-hosting manifest before commit/push.
  2. The downstream `update-upstream` workflow ran the local
     `conformance.yaml` (a snapshot from initial scaffold), which silently
     re-validates against an old contract whenever upstream bumps required
     sections. The workflow now mandates running the check against
     `$tmp/upstream/templates/skill/conformance.yaml` (the live upstream
     contract) and only after passing may the local manifest be overwritten
     as a mechanism-owned file.
  3. The upstream repo itself was outside the conformance net — it is
     self-hosting and has no `workflows/` folder, so the template manifest
     could not validate it. The new
     `references/self-hosting-conformance.yaml` asserts the upstream's
     canonical files (`SKILL.md`, `WORKFLOW.md`, `TEMPLATES-GUIDE.md`,
     `references/protocols.md`) still teach the protocols its templates
     promise downstream — Task Closure Protocol, AAR, Recording Threshold,
     Activation Check, Generalization Rule, Progressive Rigor, etc.
  Additionally `scripts/README.md` now carries a Check Suite Matrix so
  maintainers can answer "which check covers which gap" without reading
  every script header.
- Downstream refresh guidance: when running `update-upstream`, follow the
  updated step 9 (run conformance against the upstream clone's manifest, not
  the local one). Treat `conformance.yaml` and `_parse_conformance.py` as
  mechanism-owned — overwrite them from upstream after a successful refresh.
  Do NOT copy `references/self-hosting-conformance.yaml` or `check-all.sh`
  into downstream projects; they are upstream-only maintenance assets.

## 2026-05-09 - Content conformance manifest + check script

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/conformance.yaml` (new),
  `templates/skill/scripts/check-version-conformance.sh` (new),
  `templates/skill/scripts/_parse_conformance.py` (new),
  `UPSTREAM-CHANGES.md`
- Why it matters: adds a content-presence check that complements the existing
  guardrails. `check-upstream-changes.sh` enforces a downstream-impact note,
  `sync-routing.sh --check` keeps routing tables in sync, `smoke-test.sh`
  enforces structural budgets, `check-self-scenarios.sh` proves trigger
  routing, and `check-growth-health.sh` reports growth pressure. None of
  those validate that a downstream skill actually carries the workflow
  sections an upstream upgrade just shipped (Task Closure Protocol,
  Generalization Rule, Question Gate A/B/C, the dossier-folder block, and so
  on). The new manifest closes that gap: each commit IS the version, and
  `check-version-conformance.sh <skill-root>` asserts the listed sections /
  phrases / files all exist. Default manifest path is
  `<skill-root>/conformance.yaml`; downstream skills get a copy when they
  scaffold from `templates/skill/`. Upstream self-check:
  `bash templates/skill/scripts/check-version-conformance.sh templates/skill`.
- Downstream refresh guidance: when running `update-upstream`, after the
  existing routing sync and smoke test, run the conformance check on your
  skill root. If it reports missing sections, the upstream upgrade is
  incomplete — re-apply the missing template content before declaring the
  refresh done. Do NOT add `version:` fields to `conformance.yaml`; each
  upstream commit is the version, and downstream pulls the latest manifest
  from the upstream clone.

## 2026-05-08 - Architecture governance follow-through

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/workflows/profile-project.md`,
  `references/layout.md`, `references/executable-skill-architecture.md`,
  `references/scenario-testing.md`, `TEMPLATES-GUIDE.md`,
  `references/protocols.md`, `templates/skill/workflows/update-rules.md`,
  `templates/README.md`, `templates/skill/scripts/check-growth-health.sh`,
  `templates/skill/scripts/audit-route-paths.sh`,
  `scripts/check-self-scenarios.sh`, `scripts/check-all.sh`, `README.md`,
  `README.zh-CN.md`, `skill.yaml`, and `UPSTREAM-CHANGES.md`
- Why it matters: turns the architecture review into concrete governance:
  project profiling now uses separate structure / execution / topology axes,
  growth pressure is reported without failing by default, Task Closure has one
  canonical source, references can be audited by route path, and the
  self-hosting repo has minimal scenario checks for high-risk routing.
- Downstream refresh guidance: port the three-axis `profile-project` changes
  and the new report scripts if the downstream skill is starting to grow. Keep
  `check-growth-health.sh` and `audit-route-paths.sh` report-first unless the
  downstream project has stable thresholds. Do not copy
  `scripts/check-self-scenarios.sh`; it is upstream self-hosting validation.

---

Older entries (2026-05-08 through 2026-04-30) archived to [`UPSTREAM-CHANGES-archive.md`](UPSTREAM-CHANGES-archive.md).
