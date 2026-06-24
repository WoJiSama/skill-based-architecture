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

## 2026-06-24 - Content axis re-based on skeleton/flesh (abstraction over rate-of-change)

- Upstream commit: pending in this working tree
- Changed areas:
  - `SKILL.md` Content Classification + Target Structure: the axis is now **abstraction (骨架 invariant theory vs 肉 current-code facts)**, not rate of change. `architecture/` = abstract design theory only (layering/contract/orchestration **principles**) — **the module map / dir layout / call graph are flesh and move to `references/`**. `workflows/`+`rules/` = skeleton; `conventions/`+`gotchas/`+`references/` = flesh.
  - `references/rate-of-change-split.md` → renamed `references/skeleton-flesh-split.md`; §1 reframed around the judgement test (*after a refactor that renames modules / moves files, is it still true? → skeleton; describes current code → flesh*) + a fifth bucket (**code maps → references/**). Rate of change demoted to a heuristic note (it mislabels slow-drifting maps as architecture). §2–§6 mechanics unchanged.
  - `references/progressive-rigor.md` trigger 3, `references/layout.md`, `TEMPLATES-GUIDE.md § Classification Guide` — aligned to abstraction; module map → `references/`.
  - `templates/skill/workflows/task-closure.md` — added a non-script **skeleton purity** review: a new `architecture/` file that is a map/name/path of the current code is flesh → `references/`.
- Why it matters: tiering by rate of change conflated two stable-ish things — the abstract skeleton (invariant) and slow-drifting code maps (flesh) — so module trees landed in `architecture/`, making it diverge (re-describing the code) and drift instead of converging on the few invariant principles. Abstraction is the real cut; the skill holds both skeleton and flesh but no longer mixes them.
- Downstream refresh guidance: move module trees / directory layouts / call-graph maps out of `architecture/` into `references/` (mark them "drifts with refactor"); keep only invariant principles in `architecture/`. Re-run `audit-orphans` + `route-reachability` (paths change, reachability shouldn't). Mostly docs; no script behavior change beyond the renamed reference + the task-closure prompt.

## 2026-06-24 - plan-feature: depth scales with complexity + a Large tier with multi-perspective (立体) analysis

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/plan-feature.md` — Complexity Gate gains a **Large** tier (multi-subsystem / irreversible / high-uncertainty) above Complex; new **Large Plan — analyze from several angles (立体)** section: plan depth scales with task complexity, and a Large task is examined from several lenses (architecture / risks / alternatives / contracts / integration / rollout / decomposition), each its own file, with `prd.md` as the short synthesis/index. Lenses are an independent-analysis menu → optional parallel dispatch as Mode 2 subagents. Completion Checklist gains a Large-plan depth item.
- Why it matters: every anti-bloat lever ("keep `prd.md` short", "one file is correct and complete", "don't pre-create files") pushed only toward minimalism, with no counter-pressure for genuine largeness — and the Complexity Gate capped at a flat "Complex", so a multi-subsystem architecture change and a 3-file change got identical treatment. Result: real Large tasks shipped 100-line single-file plans (under-analysis). The Large tier + depth-scaling reconciles with the anti-bloat rules — `prd.md` stays short; the depth moves into warranted angle files, which is exactly the existing "add siblings only when the task needs them" rule applied to a task that needs them.
- Downstream refresh guidance: `plan-feature.md` is project-owned (not vendor-class), so this does not auto-propagate. Port the Large tier + Large Plan section into your skill's `workflows/plan-feature.md` if your project takes on multi-subsystem planning.

## 2026-06-24 - NEW route-reachability.sh — guarantees active-tier files are activated, not just link-reachable

- Upstream commit: pending in this working tree
- Changed areas:
  - NEW `templates/skill/scripts/route-reachability.sh` (vendor-class) — from `routing.yaml` (always_read + required_reads + route text) it transitively follows hub-navigation edges (a routed file listing another file's skill-root-relative path) and asserts every active-tier file (`architecture/` `conventions/` `gotchas/` `rules/`) is in the reachable set. `references/` `docs/` (lookup tiers) and `workflows/` (routed by `workflow:` + covered by `check-cross-references.sh`) are exempt. Exit 1 on any unreachable file.
  - `templates/skill/sync-manifest.yaml` — added (vendor-class).
  - `templates/skill/workflows/task-closure.md` — path-integrity gate now runs it next to `audit-orphans.sh` (whenever a content file is added or routing changes).
  - `scripts/README.md` — documented in all three matrices; `references/rate-of-change-split.md` § 6 added it to the validation list.
- Why it matters: `audit-orphans.sh` only proves a file is *link*-reachable (its path is mentioned somewhere — e.g. the `SKILL.md` manifest). A fine-grained split can leave a file link-reachable but on **no task route** — "stored, not activated", pure waste. Real case: `architecture/transactions-locks.md` passed audit-orphans but no route led there, so transactional work never read the transaction invariants. This check closes that gap and is the enforcement behind the `references/rate-of-change-split.md` § 4 "route the hub, not every file" rule.
- Downstream refresh guidance: vendor-class — re-vendor via `sync-vendor.sh`. Run after adding any `architecture/`/`conventions/`/`gotchas/`/`rules/` file or changing routing; also wired into the task-closure path-integrity gate.

## 2026-06-24 - Distilled the rate-of-change split playbook from the chaos pilot (real-use feedback)

- Upstream commit: pending in this working tree
- Changed areas:
  - NEW `references/rate-of-change-split.md` — playbook for splitting an existing skill's tiers by rate of change, distilled from doing it twice on a real code-coupled skill: the **four** buckets (incl. methodology stays in `rules/`), verbatim-no-duplication authoring, **split-is-a-path-migration** (repoint / stub / delete every old-path reference), **every fine-grained tier needs a routed `index.md` hub** (link-reachable ≠ route-reachable: a file in the `SKILL.md` manifest but on no task route is stored-not-activated waste — the gotchas-hub pattern generalized to `architecture/`+`conventions/` with a "read when" column; route the hub, not every file), orphan-inbound mechanics (root-relative inline-code = inbound; relative `[]()` link = smoke-test link check), **routing re-derivation** (the `fix-bug`-reads-pitfalls-but-not-the-rule failure), validation, the assembled/vendored-copy trap, and the "batch ~4 concurrent" subagent-fanout note (avoids `ECONNRESET`).
  - `references/progressive-rigor.md` — trigger 3 now names all four buckets and that `rules/` keeps methodology; links the playbook.
  - `SKILL.md` Content Classification — header notes `rules/` keeps cross-cutting agent-behavior; links the playbook.
  - `references/layout.md`, `workflows/full-migration.md` (Phase 6) — link the playbook.
- Why it matters: the framework taught the rate-of-change *axis* but not the *mechanics*. Real use surfaced load-bearing gaps the docs didn't cover — methodology has no architecture/conventions home (the 4th bucket), a split breaks every old-path reference, per-module gotchas silently orphan without a hub registered as root-relative inline-code, and routes go incoherent if `required_reads` aren't re-derived across the new tiers.
- Downstream refresh guidance: documentation only; no script/behavior change. Read `references/rate-of-change-split.md` before splitting a tier.

## 2026-06-23 - Content Classification re-tiered by rate of change (architecture/ conventions/ gotchas/)

- Upstream commit: pending in this working tree
- Changed areas:
  - `SKILL.md` — Content Classification table + Target Structure now teach the rate-of-change axis: stable structure → `architecture/`, volatile house style → `conventions/`, code-coupled landmines → per-module `gotchas/` (+ `gotchas/index.md` hub); Progressive Rigor gained a "split `rules/` by rate of change" trigger.
  - `references/progressive-rigor.md` — Full-tier layout + upgrade triggers updated (recurrence → per-module `gotchas/`; new "rate-of-change tangle" trigger → split `rules/` into `architecture/`+`conventions/`).
  - `references/layout.md`, `TEMPLATES-GUIDE.md` § Classification Guide — aligned to the new tiers.
  - `templates/skill/scripts/smoke-test.sh` — `routing.yaml` cap 120 → 140 (tiered skills route to more files per task); SKILL.md body-overflow hint lists the new tiers.
- Why it matters: the old `rules/` (normative) vs `references/` (background) split is orthogonal to rate of change, so stable architecture and volatile gotchas tangled in the same files — every volatile edit re-touched stable material and refactors churned files that should stay put. Tiering by rate of change keeps the stable spine small/cacheable/always-read and isolates volatile detail so refactors and conformance only touch the volatile set.
- Downstream refresh guidance: NOT a forced migration. `rules/` stays a valid content tier (the tooling — audit-orphans / footprint / check-cross-references / sync-routing / smoke-test — already treats all tiers). Adopt the split when a `rules/` file tangles stable + volatile or a subsystem's gotchas pile up; worked split in `references/progressive-rigor.md`. Re-vendor the scripts (vendor-class) to pick up the cap + tier coverage.

## 2026-06-23 - footprint / check-cross-references / sync-routing / smoke-test made tier-aware

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/scripts/footprint.sh` — read-everything baseline now sums `.md` under every content tier (`architecture/` `gotchas/` `conventions/` added to `rules/` `workflows/` `references/`); tiered skills were previously undercounted.
  - `templates/skill/scripts/check-cross-references.sh` — workflow→content extraction and reverse lookup now match all content tiers, not just `(rules|references)/`.
  - `templates/skill/scripts/sync-routing.sh` — `always_read` path-prefix allowlist now accepts `architecture/` `gotchas/` `conventions/` (previously rejected an always-read architecture spine).
  - `templates/skill/scripts/smoke-test.sh` — 1a-gotchas recognizes a `gotchas/` directory (preferred) as the gotchas surface; the line-cap + duplicate-`## `-heading scan (2a) now also covers `gotchas/*.md` (skips `gotchas/index.md`); 1a-rules now accepts a constraint surface in `rules/` OR `architecture/` OR `conventions/` (was hardcoded to `rules/project-rules.md` + `rules/coding-standards.md`, which a skill that split `rules/` by rate of change no longer has); routing.yaml cap raised 120 → 140 and the SKILL.md body-overflow hint lists the new tiers.
- Why it matters: companion to the audit-orphans tier fix below. These four still enumerated only `rules/`+`references/`, so a skill that adopted `architecture/`/`gotchas/` got an undercounted footprint, missed cross-reference staleness, a rejected always-read spine, and an unenforced gotchas line cap — the new taxonomy was only half-enforced.
- Downstream refresh guidance: all four are vendor-class (`sync-manifest.yaml`); re-vendor via `sync-vendor.sh`. No behavior change for skills that never adopted the new tiers — the extra dirs simply don't exist and are skipped.

## 2026-06-23 - audit-orphans covers all content tiers + scans routing.yaml

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/scripts/audit-orphans.sh` — generalized from `rules/`+`references/` to all content tiers (`rules/` `references/` `architecture/` `gotchas/` `conventions/`) via a `TIER_DIRS` array (existence-guarded — partial-tier skills behave exactly as before); added `routing.yaml` as an inbound-link source, so a file referenced only from a task's `required_reads` counts as reachable (whether that route can match is still route-health's job). 92 lines (was 84).
  - `templates/skill/workflows/task-closure.md` (path-integrity gate line), `templates/README.md`, `scripts/README.md` — wording updated from "rules/ or references/" to "content-tier" to match the new coverage.
- Why it matters: a skill that organizes gotchas/architecture/conventions into their own directories previously had ZERO orphan protection on exactly those files — the old script only audited `rules/`+`references/` and only counted inbound links from those dirs, so a new gotcha/architecture file could be created, never routed, and silently rot with no closure gate catching it. The mandatory path-integrity gate now actually covers the tiered structure.
- Downstream refresh guidance: re-vendor `scripts/audit-orphans.sh` (vendor-class in `sync-manifest.yaml`; `sync-vendor.sh` overwrites an unedited local copy). After splitting content into `architecture/` / `gotchas/` / `conventions/` and wiring routing, run `(cd skills/<name> && bash scripts/audit-orphans.sh)` — any new-tier file with no inbound link from a workflow, another tier file, or `routing.yaml` now fails the gate.

## 2026-06-23 - Downstream token/latency cut: dedupe required_reads + split agent-behavior.md

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/routing.yaml` — removed always_read files (`project-rules` / `coding-standards` / `agent-behavior`, including the `rules/*.md` glob) from per-route `required_reads`; routes now list only route-specific files (only `update-rules` keeps `gotchas` + `behavior-failures`). Added a FILL note stating the rule.
  - `templates/skill/SKILL.md.template` — regenerated ROUTING_SUMMARY via `sync-routing.sh` (de-duped routes now show "reads none"); no hand edits.
  - `templates/skill/rules/agent-behavior.md` — split: the 6 principles + ✓ Checks stay always-read (100 → 85 lines); origin / admission-threshold / Observable-Signals audit moved out.
  - `templates/skill/references/agent-behavior-meta.md` — NEW; holds the moved meta, read only when editing the rule.
- Why it matters: cuts what a downstream pays per task/session with zero function loss. Re-listing an always_read file inside a route's `required_reads` forced a redundant re-read of already-resident content (worst case the `rules/*.md` glob re-pulled ~6.8 KB of `agent-behavior.md` on every change task). Splitting `agent-behavior.md` trims ~400–500 tok off the always-read floor every session and frees cap headroom.
- Downstream refresh guidance: in your `routing.yaml`, drop any always_read file re-listed in a route's `required_reads` (keep genuinely route-specific reads), then run `scripts/sync-routing.sh <name>`. If you customized `rules/agent-behavior.md`, port the split — keep your principles always-read, move origin/admission/observable-signals into `references/agent-behavior-meta.md` and link it from the rule. Re-run `smoke-test.sh`.

## 2026-06-23 - ANTI-TEMPLATES.md: Borrowed-Pattern Acceptance Test (four gates)

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/ANTI-TEMPLATES.md` — new "Borrowed-Pattern Acceptance Test" section (recurrence / generativity / distinctiveness / boundary) that gates any externally-borrowed mechanism before the existing cost gate; maps the existing "would two real projects disagree?" test to the distinctiveness gate.
- Why it matters: sharpens the templates admission gate for the recurring "should we copy X from an admired project?" decision; distilled from a comparison with an external meta-skill.
- Downstream refresh guidance: optional, no code/behavior impact. If your project maintains its own `ANTI-TEMPLATES.md` or admission gate, consider adding the four-gate test for borrowed patterns.

## 2026-06-15 - plan-feature.md: Decision-Completeness scan (distilled from a downstream plan review)

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/plan-feature.md` — new "## Decision Completeness
    (≠ section completeness)" subsection (after Complex Steps) + 3 Completion
    Checklist lines. Cues a plan author to check four recurring *decisions* that
    pass section-level checks but bite at execution: (1) external-dependency
    failure behavior (unreachable/timeout/5xx, fail-open vs fail-closed) — not
    just the config-missing branch; (2) schema/contract changes carrying a
    concrete migration/DDL artifact in the repo's existing convention, with
    unique-key column nullability/type pinned, not a prose field list; (3)
    cross-file consistency in multi-file dossiers (including "see Dx" refs that
    now contradict Dx); (4) Open-Questions hygiene — track unresolved decisions
    incl. failure modes, and don't bury a blocker under a "non-blocking" header.
    Deliberately does **not** add a mandatory test-plan or observability section.
- Why it matters: distilled from a real downstream complex-plan review. A
  structurally complete dossier (every required section present) still omitted
  its single most consequential failure-mode decision (external service
  unreachable), shipped a load-bearing table as prose with no DDL against a repo
  that has a hand-written migration convention, and let two sibling files
  contradict each other (one citing the very decision it reversed). Section-
  completeness ≠ decision-completeness; the smoke-test cannot detect a *missing*
  decision, so the cue lives in the planning workflow itself.
- Downstream refresh guidance: if your downstream keeps a local plan-feature
  workflow, port the Decision-Completeness subsection + the 3 checklist lines;
  the cues are universal (no project terms). Preserve any project-specific
  question gates. If your executing workflow makes backend tests opt-in, keep it
  — this change deliberately does not mandate a test section.

## 2026-06-10 - sync-vendor.sh + sync-manifest.yaml: mechanical vendor sync + wrong-checkout guard

- Upstream commit: pending in this working tree
- Changed areas:
  - **NEW `templates/skill/sync-manifest.yaml`** — machine-readable list of
    vendor-class files (all `scripts/*` + the manifest itself): byte-identical
    upstream copies that downstream must not edit.
  - **NEW `templates/skill/scripts/sync-vendor.sh`** — mechanical vendor sync.
    Base = the upstream version at your `.upstream-sync` `synced_sha` (read from
    upstream git history — no new state files): local == base → provably
    unedited → auto-update to upstream HEAD; local != base → LOCAL-EDIT,
    reported, never overwritten; missing → NEW, copied; gone upstream →
    DROPPED, reported. Dry-run by default, `--apply` writes. Replaces the
    per-file hand-archaeology of update-upstream steps 5–7 for scripts.
  - `templates/skill/scripts/upstream-status.sh` — wrong-checkout guard: scans
    sibling `git worktree` checkouts for `.upstream-sync`. No pointer here but
    a sibling has one → "WRONG CHECKOUT?" stop-warning (the stale-copy case);
    sibling pointer with a different `synced_sha` → divergence warning.
  - `templates/skill/workflows/update-upstream.md` — new step 0 (verify you are
    in the skill-maintenance checkout before porting); step 5 rewritten to run
    sync-vendor.sh (manual scan remains only for non-vendor mechanism files);
    Hard Rule #4 + step 4 note the vendor-class subset; step 6 scoped to
    non-vendor files.
- Why it matters: every refresh × every downstream re-paid "which files do I
  copy whole" reading plus per-script git archaeology, and the changelog's
  prose guidance grew with every entry — the sync tax scaled with time and
  with the number of adopters. The vendor manifest machine-izes the file
  classification update-upstream step 4 already described in prose. The
  wrong-checkout guard mechanizes a real 2026-06-08 incident (an upgrade ran
  in a stale business-branch checkout and had to be rolled back).
- Downstream refresh guidance: copy `sync-manifest.yaml` +
  `scripts/sync-vendor.sh` once by hand (this is the bootstrap case), re-vendor
  `scripts/upstream-status.sh`, and port the update-upstream.md step changes
  (step 0, step 5, Hard Rule #4 — preserve your local FILLs). From the next
  refresh on, step 5 is one command instead of a file-by-file comparison.

## 2026-06-10 - Budget pass: extract subagent-orchestration.md; fix stale harness table

- Upstream commit: pending in this working tree
- Changed areas:
  - **NEW `templates/skill/workflows/subagent-orchestration.md`** — Mode 2's
    four phases (Plan / Dispatch / Two-Stage Review / Merge-or-Reject) +
    Degraded Mode, extracted verbatim from `subagent-driven.md` (which was 299
    lines vs its 250 budget). `subagent-driven.md` (now 223) keeps the mode
    router: triggers (§ Mode 2: When to Invoke), Iron Law, Parallelism Premise,
    Negative list, Interception Transparency, shared Rationalizations / Red
    Flags, plus a pointer to the new file.
  - Cross-refs repointed to `subagent-orchestration.md`: `refactor-fanout.md`
    (Phase 1 / Phase 3 + top banner), `fix-bug.md` (hypothesis fan-out contract
    format), `references/subagent-verification.md` (Phase 1 + Degraded Mode).
    `plan-feature.md`'s § Mode 2 trigger anchor still resolves (heading stayed).
  - `templates/skill/workflows/refactor-fanout.md` — its local Harness
    Compatibility table contradicted `subagent-driven.md` (still listed Codex
    as degraded; stale since the 2026-05-21 Codex global-authorization change).
    Replaced with a pointer to the canonical table.
  - Budget trims, no semantic change: `SKILL.md.template` body 93 → 90 (merged
    redundant comment blocks), `plan-feature.md` 105 → 100 (compressed the
    non-canonical-filenames example block).
  - `templates/README.md` + `check-growth-health.sh` — sync-routing.sh cap
    320 → 340 recorded with rationale; new budget rows for
    `sync-vendor.sh` / `sync-manifest.yaml`; `subagent-orchestration.md` added
    to the ≤ 100 workflow row; scripts tree listing completed (footprint /
    route-health / upstream-status had aged out of the doc).
- Why it matters: the upstream enforces budgets on downstream skills while
  carrying its own overages — that asymmetry erodes the budgets' credibility.
  Mode 1 / Mode 2 also pass the Self-maintenance split test (independently
  navigable; readers usually want exactly one), and the stale harness table
  was actively misinforming Codex users following refactor-fanout.
- Downstream refresh guidance: mirror the extraction in your local copy —
  create `workflows/subagent-orchestration.md` from your local
  `subagent-driven.md`'s Mode 2 phases + Degraded Mode (preserve local edits
  and language; same pattern as the 2026-05-29 task-closure extraction), leave
  the trigger section + shared rules in `subagent-driven.md`, add the pointer,
  then repoint your local Phase 1 / Phase 3 / Degraded references (grep for
  `subagent-driven.md` Phase and § Degraded). If your harness-compat tables
  were copied per-workflow, replace them with pointers to the canonical one.
  No routing.yaml change required (routes still enter via subagent-driven.md);
  no conformance.yaml change (neither file carries must_contain entries).

## 2026-06-08 - Subagent verification patterns: adversarial verify + loop-until-dry

- Upstream commit: pending in this working tree
- Changed areas:
  - **NEW `templates/skill/references/subagent-verification.md`** — two
    harness-agnostic patterns that extend `subagent-driven.md`'s two-stage
    review from *worker compliance* to *output correctness + discovery
    completeness*: (1) **adversarial verification** — for an uncertain finding
    (bug / security / research claim), dispatch N independent verifiers each
    contracted to *refute* it, default-to-refuted, keep only on majority
    survival; perspective-diverse variant gives each verifier a distinct lens.
    (2) **loop-until-dry** — for open-ended discovery (no known task-list size),
    dispatch finder rounds, dedup against all-seen, stop after K empty rounds;
    multi-modal rounds + no-silent-caps. Both carry an explicit "when NOT to
    reach for these" (mechanically-checkable output or bounded task list → the
    existing single review is enough).
  - `templates/skill/workflows/subagent-driven.md` — Phase 3 (Two-Stage Review)
    gains a one-line pointer to the new reference for the judgment / discovery
    case (compliance review necessary but not sufficient).
- Why it matters: the existing subagent surface (`subagent-driven.md`,
  `refactor-fanout.md`) is built for **decomposable known work** and reviews
  **worker compliance** (did it follow the contract). It had no pattern for the
  case where the worker's *conclusion* may be plausible-but-wrong, or where the
  problem has *no known size* — exactly the gap a multi-agent "exhaustive mode"
  fills. Distilled to the two harness-agnostic patterns; the harness-specific
  orchestration API (Claude Code's `Workflow` / parallel-`Task` fan-out
  primitives) is deliberately **excluded** per `ANTI-TEMPLATES.md` § "Subagent
  type registries / harness-specific dispatch code" — predefining one harness's
  dispatch API would lie to every other harness.
- Downstream refresh guidance: copy `references/subagent-verification.md` whole
  (project-agnostic) and add the Phase 3 pointer line to your local
  `subagent-driven.md`. No `routing.yaml` or `conformance.yaml` change required
  — these are optional optimization patterns, not safety contracts (same posture
  as `refactor-fanout.md`). On harnesses with no parallel / background dispatch,
  the patterns degrade to sequential verifier passes — you keep the adversarial /
  loop discipline, you lose the parallelism. If your project has never needed
  adversarial verification or open-ended discovery, skip the file and re-pull
  when the situation actually appears.

## 2026-06-08 - smoke-test.sh: activate hook / stuffing / conformance checks

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/scripts/smoke-test.sh` — three new checks, all closing
    gaps where a real downstream (`chaos`) drifted while passing the old
    smoke-test:
    - **1d SessionStart hook (WARN)** — when `.claude/` exists but no
      `SessionStart` hook is wired in `.claude/settings*.json`, warn (Pitfall
      #7: routing silently drops after `/clear` or `/compact`). Never fails —
      harness-dependent.
    - **4c-stuffing (WARN)** — description with > `$DESCRIPTION_MAX_TRIGGERS`
      (default 12) quoted phrases is flagged as workflow-keyword stuffing
      (Pitfall #3 / Principle #7). The old check only caught *too few* (< 2)
      quoted phrases; this catches *too many*.
    - **Section 9 Content Conformance (FAIL)** — if a `conformance.yaml` exists,
      run `check-version-conformance.sh` so the one check people run after every
      change also catches *content* drift (e.g. a renamed "Task Closure
      Protocol"). Skipped silently when no manifest. Runs in full / `--phase 8`
      only — not in `--phase 7`, so `check-all` self-hosting verify is unaffected.
  - `templates/skill/scripts/check-growth-health.sh` — raised `smoke-test.sh`
    soft cap 850 → 900 (the verifier legitimately grew by the three checks above).
- Why it matters: structural checks (files exist, links resolve, routing in sync)
  were gated and ran easily; the checks that catch hook/description/content drift
  existed but were manual ("stored, not activated"). A downstream passed
  smoke-test green while missing its hook, stuffing its description to 25 quoted
  phrases, and regressing a conformance-required phrase. These three additions
  move those checks onto the path that actually runs.
- Downstream refresh guidance: re-vendor `smoke-test.sh` and
  `check-growth-health.sh` from this upstream. §9 depends on the conformance
  checker, so re-vendor `check-version-conformance.sh` + `_parse_conformance.py`
  as a coupled set (if `conformance.yaml` is present but the checker is missing,
  §9 now WARNs rather than silently skipping). After re-vendoring, run
  `bash skills/<name>/scripts/smoke-test.sh <name>` (full, so §9 runs) — new
  WARNs/FAILs surface pre-existing drift; fix them (wire a SessionStart hook,
  trim the description, re-add any conformance-required phrase) rather than
  suppressing the checks. In multi-skill repos the §1d hook check is skill-aware:
  it only passes when a hook re-injects THIS skill's `skills/<name>/` router.
- Known remaining gap (by design, not yet closed): the hook (§1d) and stuffing
  (§4c) checks are WARN-only (harness-dependent / judgment), so re-drift of P1/P3
  is detected but non-blocking; only conformance (§9) is FAIL-gated. And
  smoke-test is still human/agent-triggered — no pre-commit or CI auto-runs it
  downstream. Pick a gate (pre-commit, closure-step, or periodic update-upstream)
  per project; a `SMOKE_STRICT=1` promote-WARNs-to-FAIL mode can be added when a
  CI consumer exists.
