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
