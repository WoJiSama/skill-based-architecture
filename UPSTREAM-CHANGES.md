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

## 2026-07-22 - Semantic completeness before minimality

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/rules/agent-behavior.md` replaces Simplicity First with **Semantic Completeness Before Minimality**: Product Development is the default; agents trace invariant, ownership/provenance, producer-to-consumer call chain, and all full/incremental/read/write paths before choosing repair depth. Minimality becomes a tie-breaker among semantically complete solutions.
  - `templates/skill/workflows/fix-bug.md` adds a Repair-depth gate between root-cause discovery and implementation; `change-managed.md` adds the same ownership and semantic-fan-out ordering for features/refactors.
  - Operational Stabilization is now an explicit exception for production incidents, hotfix/availability containment, stop-the-bleeding work, or frozen scope. Containment must be reversible and report that structural repair remains unresolved.
  - Conformance and self-hosting scenarios protect the default mode, invariant-owning boundary, cross-path inspection, and minimality ordering.
- Why it matters: an availability-first default can produce a locally usable patch while leaving the real invariant broken, such as mutating a collection without tracing its immutable owner or updating one incremental path without the shared filter used by the full path. Dependency count measures repair risk; it must not silently redefine correctness.
- Downstream refresh guidance: replace or reconcile existing Simplicity First wording rather than appending another Always Read principle. Port the Repair-depth gate into bug and managed-change workflows, preserve stricter project-specific production controls, then validate both an ownership/mutation case and a full-vs-incremental invariant case.

## 2026-07-21 - Task Anchor and harness-native execution plans

- Upstream commit: pending in this working tree
- Changed areas:
  - NEW `templates/skill/workflows/task-execution.md` — classifies Simple / Managed / Design tasks; Managed tasks establish Goal, Done When, optional material Boundaries, and a task-specific Plan using the harness's native Plan/Task surface. Anchor state is separate from presentation: natural-language alignment is the default, visible Native Plan steps are not duplicated in chat, and a complete structured brief is reserved for long, complex, scope-sensitive, confirmation-dependent, or no-native-Plan work. Before every main step, a compact Anchor Checkpoint re-centers Goal, remaining evidence, the step check, and relevant Boundaries; it repeats after correction, failed/surprising evidence, Subagent return, or interruption. The loop owns runtime progress, evidence-backed advancement, replanning, and new-message handling entirely inside the current Session, with no planning-file persistence.
  - `agent-behavior.md`, generated Session Discipline/Auto-Triggers, and self-hosting shells activate the protocol after routing while preserving zero ceremony for one clear action/check.
  - Fix Bug, Change Managed, Plan Feature, Subagent, and Task Closure workflows now share an explicit boundary: Workflow owns reusable domain procedure; Task Anchor owns the current outcome; Native Plan owns current step state; Closure decides completion only after Goal-level evidence.
  - `conformance.yaml`, scenario checks, guides, README files, and `docs/task-anchor-native-plan.md` protect and explain the user-visible behavior and non-goals (no task database, fixed three-file schema, or cross-tool state sync).
- Why it matters: routing can select the right Workflow while a long Session still drifts away from the user's current goal. A fixed labeled Anchor block can also interrupt ordinary conversation and duplicate the native Plan. Proportional presentation keeps user-visible ceremony matched to task risk, while the internal Recitation Loop keeps the full Anchor in working attention without turning the Skill into a persistent task engine.
- Downstream refresh guidance: add `workflows/task-execution.md` as a non-vendor reusable workflow, port the Goal-Driven Execution, Recitation Loop, and shell activation lines, reconcile local Domain Workflow gates rather than replacing them, and add the Closure Entry Gate. Preserve local validation/permission boundaries and use the local harness's native Plan capability; do not introduce durable planning files, recovery scripts, or cross-Session state for this mechanism.

## 2026-07-20 - Goal contracts and risk-sized checkpoints

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/rules/agent-behavior.md` — Goal-Driven Execution now starts from one observable goal, explicit non-goals, and acceptance evidence; scoped reversible work runs through its checks without per-step approval, while real decision, authority, shared, or irreversible boundaries still pause.
  - The same rule distinguishes purposeful discovery from execution drift and treats rankings/process metrics as diagnostic signals rather than objectives; opaque rubrics or task mix cannot justify suppressing necessary exploration or evidence.
  - `templates/skill/references/agent-behavior-meta.md` records the activation signals and corrects the existing principle 6/7 origin mapping; `templates/skill/conformance.yaml` protects the three load-bearing phrases.
- Why it matters: blanket approval checkpoints raise user cost, while no checkpoints blur authority and decision boundaries. The risk-sized contract preserves autonomous closure for safe work without optimizing behavior for an opaque score or mistaking necessary discovery for drift.
- Downstream refresh guidance: reconcile the three Goal-Driven Execution bullets in place instead of appending a new principle. Preserve project-specific permission rules, validation commands, and stricter shared/production controls. No new file, route, index, or placeholder is required; run conformance and the normal skill structure checks after adoption.

## 2026-07-17 - Simplify default scaffold and make integrity checks truthful

- Upstream commit: branch `codex/simplify-template-maintenance-20260717` (`96cd072` plus the conformance literal follow-up)
- Changed areas:
  - REMOVED `footprint.sh`, `check-cross-references.sh`, and `check-growth-health.sh`: the first undercounted mandatory reads and failed on two-root prefixes; the second guessed semantic drift from mtime and duplicated link checks; the third emitted permanent review noise while always succeeding.
  - `audit-orphans.sh` and `route-reachability.sh` now accept `--namespace skill|code --routing <path>` and keep identical `skill:` / `code:` paths distinct; route reachability now includes workflows. Single-root zero-argument behavior remains.
  - `_parse_conformance.py` was merged into the public `check-version-conformance.sh` CLI; conformance assertions now protect fewer load-bearing contracts instead of duplicating file existence and wording.
  - Conformance phrases are passed to `grep` after `--`, so a required or forbidden literal beginning with `-` / `--` cannot be misread as a command option; the main suite covers both positive and negative option-like phrases.
  - REMOVED the implicit-Always-Read `minimal-sufficient-context.md`; concise context/evidence escalation now lives in Always Read `agent-behavior.md`, while Fix Bug, Change Managed, and Task Closure retain only task/timing-specific decisions.
  - `agent-behavior.md`, subagent workflows, Fix Bug, Change Managed, Receiving Review, and Task Closure were reconciled and compressed. The three subagent modes remain separate because their selection timing differs; only the main agent runs Task Closure after integrated work.
  - Tests-as-Spec and Permission Model moved from the default downstream scaffold to upstream adoption guides under `references/`. Projects materialize them only after real testing/operation pressure and add a project-specific activation path.
  - Editor-local `.idea/` files were removed; template indexes, sync manifest, diagrams, update guidance, and validation were updated.
- Why it matters: a green structural suite was hiding inaccurate reports, duplicate thresholds, implicit co-loading, and opt-in files copied to every project. The smaller scaffold makes every retained file/check answer an independent question and strengthens actual two-root activation.
- Downstream refresh guidance: remove the three deleted report scripts and `_parse_conformance.py`; re-vendor the retained integrity/conformance scripts; delete `minimal-sufficient-context.md` only after moving any project-specific expansion/validation rules into an actual Always Read rule or task workflow. Keep adopted local Tests-as-Spec/Permission rules if the project has real baselines, but stop treating them as universal template files. Preserve project-specific Fix Bug/validation semantics while removing duplicate core/checklist text. Regenerate routing and run smoke, orphan, route-reachability, route-health, and conformance checks.

## 2026-07-17 - Business global model, durable-record gates, and conditional loading

- Upstream commit: pending in this working tree
- Changed areas:
  - NEW `references/business-global-model.md` and opt-in `templates/skill/workflows/profile-business-model.md.example` — model only stable, implementation-independent macro business types/flows/states/boundaries/invariants; distinguish absent, locally unclear, conflicting, and sufficient states; “later” creates no artifact.
  - `plan-feature.md`, `fix-bug.md`, `change-managed.md`, and `minimal-sufficient-context.md` — business model → architecture/contracts → code/tests/runtime comparison; explicit `business-model impact`; bug classification (`IMPLEMENTATION_BUG` / `DESIGN_CHANGE` / `INSUFFICIENT_BUSINESS_CONTEXT`); type/flow/state/invariant changes exit bugfix and require an approved Plan.
  - `update-rules.md`, `maintain-docs.md`, `gotchas.md`, `references/protocols.md`, `references/layout.md`, `references/skeleton-flesh-split.md`, `route-reachability.sh`, and `SKILL.md` — fidelity + five-way reconciliation + activation gates; generic cross-project vs business cross-implementation durability; no chronological Gotcha append; independent load-reason and semantic before/after audits; known leaves route directly and selecting indexes appear only after real multi-file pressure.
  - NEW `plan-large.md` and `subagent-auxiliary.md`; `plan-feature.md` and `subagent-driven.md` are now small conditional routers. Large analysis and day-to-day auxiliary delegation no longer inflate ordinary Plan/Mode-2 task paths. The auxiliary/Mode-2 split retains the latest inline-default, positive-Net-Benefit, bounded-fan-out, and no-spawn-then-wait rules from the 2026-07-15 scheduling change.
  - `references/self-hosting-routing.yaml` and `templates/skill/routing.yaml` — planning and plan distillation use separate phases; single-skill routing does not preload multi-skill guidance; ordinary rule edits do not preload layout; update-rules classifies before selecting Gotcha vs behavior-failure evidence.
  - REMOVED `protocol-blocks/rationalizations-table.md` and `protocol-blocks/red-flags-stop.md` — `workflows/task-closure.md` is the sole body source; sync manifest and references were updated.
  - Conformance, migration guidance, scenario checks, budgets, and template indexes now assert the new conditional files and contracts.
- Why it matters: code shows current behavior but not necessarily intended business meaning. The new opt-in layer gives Plan and Fix Bug a stable semantic baseline without turning business detail into Always Read context. The same change closes two knowledge-rot paths: lossy summaries and append-only documents, while reducing route-time co-loading.
- Downstream refresh guidance: add `plan-large.md` and `subagent-auxiliary.md`; port the business-semantics gates and update-rules/maintain-docs contracts while preserving project-owned rules and Gotchas. Remove the two deleted protocol blocks and their vendor entries. Regenerate routing after adopting conditional update-rules reads. Product projects should copy/rename the business-model example only after a real module passes admission; non-product projects keep it inactive. Run conformance, sync-routing, smoke-test, orphan/reachability, and relevant behavior scenarios.

## 2026-07-15 - Subagent scheduling: inline default, Net Benefit gate, and no spawn-then-wait

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/rules/agent-behavior.md`, `templates/skill/workflows/subagent-driven.md`, orchestration/fix/change/plan/refactor activation paths, rationalizations, behavior-failure evidence, and conformance tooling (`must_not_contain` in the parser/checker plus manifest regression guards).
- Why it matters: the previous Mode 1 Iron Law mapped any mechanical/time-consuming/result-only sub-step to mandatory dispatch, while a later paragraph said dispatch was invalid when the main agent could only wait. The stronger early rule won in practice: ordinary grep/tests/edits spawned many workers, the main agent entered repeated wait loops, and coordination cost displaced useful work.
- Downstream refresh guidance: replace mandatory reverse-question/auto-spawn language with an inline default and five-part Admission Gate (independence, result-only consumption, real overlap, positive Net Benefit, bounded fan-out). Port the non-blocking rule: never spawn when the next action is wait; wait only when every remaining critical path depends on already-running workers; never poll-loop. Remove fixed review-agent and one-worker-per-file/test/lens rules. Add local conformance phrases so the old wording cannot return.

## 2026-07-15 - Restore harness-aware subagent fallback

- Status: superseded by 2026-07-15 - Subagent scheduling: inline default, Net Benefit gate, and no spawn-then-wait
- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/subagent-driven.md` — restores the decision-time fallback from the previously published market snapshot: when Codex or another harness has no proactive subagent authorization, Mode 1 continues inline instead of stalling on its dispatch Iron Law. The fallback is explicitly separated from an unexpected execution-time tool denial, which still follows Interception Transparency.
- Why it matters: market version 1.12 commit `2301541` captured a real Codex harness constraint, but the fallback was lost while later upstream work added the Parallelism Premise and worker Return Status vocabulary. Without the fallback, a downstream can read "must dispatch" and "dispatch is unauthorized" as a blocking conflict even though inline execution is valid for that harness.
- Downstream refresh guidance: port the Harness Compatibility row and the inline capability fallback if the downstream can run under per-turn subagent authorization. Preserve local dispatch primitives, the current Parallelism Premise, Return Status handling, and execution-time Interception Transparency; do not replace the whole workflow with the older market copy.

## 2026-07-09 - Minimal sufficient context route intake

- Status: superseded by 2026-07-17 - Simplify default scaffold and make integrity checks truthful
- Upstream commit: pending in this working tree
- Changed areas:
  - NEW `templates/skill/references/minimal-sufficient-context.md` — shared route-intake protocol: start from Always Read + route `required_reads` + workflow, expand context only on concrete signals, and escalate validation from command evidence to runtime/release evidence only when needed.
  - `templates/skill/SKILL.md.template` and `templates/skill/routing.yaml` — clarify that `required_reads` are core reads, not safety-blanket context; do not split routes/workflows into small/large variants.
  - `templates/skill/workflows/fix-bug.md` and `templates/skill/workflows/change-managed.md` — Read First sections now point to the shared protocol instead of broad default `rules/*.md` / `references/*.md` reads.
  - `templates/skill/conformance.yaml`, `templates/README.md`, `TEMPLATES-GUIDE.md` — register and document the new required reference.
- Why it matters: small tasks were paying the full skill cost because context, validation, and closure rigor were being encoded inside each workflow. This keeps workflow intent cores stable while route intake owns variable rigor. "Small" now means narrow context footprint, not weaker proof.
- Downstream refresh guidance: add the new reference, update generated SKILL/routing prose, and trim workflow Read First blocks that default to broad reads. Preserve project-specific validation commands, but move any generic light/heavy ladder out of individual workflows and into this shared route-intake protocol. Run `sync-routing.sh --check`, `smoke-test.sh`, and conformance against the refreshed upstream manifest.

## 2026-07-08 - Skill upgrade plan-only gate

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/update-rules.md` — adds a plan-only gate for high-impact skill upgrades: external-project absorbs, benchmark/eval lessons, major template/default scaffold changes, Always Read/routing behavior, or new reusable mechanisms must first produce an upgrade plan and stop until the user approves that exact plan. Also adds a net-benefit + validation gate before adding rules/workflows/references/hooks/scripts/templates.
  - `templates/skill/workflows/edit-templates.md` — points external absorbs and reusable mechanism changes to the plan-only gate before editing copied scaffold artifacts.
  - `references/scenario-testing.md` — adds a case split for skill upgrades: incident, candidate rule, regression case, boundary case, and holdout challenge; holdout is post-rule validation, not rule-design input.
- Why it matters: distilled from `compass-skills` without importing its personal task OS. The useful pattern is not task DAG/profile/session state; it is the lightweight discipline that large skill upgrades first surface candidates, rejected items, impact, activation path, net benefit, and validation before mutating shared scaffolds.
- Downstream refresh guidance: optional but recommended workflow update for projects that absorb external skill patterns or maintain shared scaffolds. No script, conformance, routing, or default harness behavior changed.

## 2026-07-08 - Hosted preview demo uses copy-paste input

- Upstream commit: pending in this working tree
- Changed areas:
  - `README.md`, `README.zh-CN.md`, `EXAMPLES.md` — hosted preview pointers now target `examples/simple-repo/COPY-PASTE-INPUT.md` and set expectation that the bundled demo is a minimal smoke-test input.
  - `examples/simple-repo/` — adds a single copy-paste input bundle and clarifies that hosted agents should not clone, fetch, or inspect the GitHub folder; README now states the generated output should be small because the fixture is intentionally tiny.
- Why it matters: Hermes-style hosted previews may block clone flows that try to clean `/tmp` paths, so the safe demo path must pass the small fixture as pasted context instead of asking the hosted agent to read a GitHub directory.
- Downstream refresh guidance: no downstream scaffold action. This is only an upstream README/examples demo-path clarification; projects that copied the previous hosted-preview wording may update it, but no templates, scripts, routing, or conformance behavior changed.

## 2026-07-08 - Skill authoring judgement checks

- Upstream commit: pending in this working tree
- Changed areas:
  - `references/layout.md` — description quality now includes a near-miss anti-trigger check: name similar user requests that should not activate the skill, or the domain is probably too broad.
  - `references/executable-skill-architecture.md` — adds a Degrees of Freedom classifier before promoting a skill toward script/CLI-first execution.
- Why it matters: borrowed from `skill-authoring` as lightweight judgement checks, not mechanisms. They help avoid over-broad activation and premature executable scaffolding without adding default workflow burden.
- Downstream refresh guidance: optional reference-doc update only; no template, conformance, script, or user-facing behavior change.

## 2026-07-07 - Black-box downstream scaffolding internals

- Upstream commit: pending in this working tree
- Changed areas:
  - `WORKFLOW.md` — Quick Start no longer references optional `.codex`, records a real `.upstream-sync` baseline from the upstream checkout, and frames remaining `FILL:` markers as agent migration work rather than user-facing setup.
  - `templates/skill/protocol-blocks/` — protocol blocks moved inside the copied skill tree; workflow links now resolve locally (`../protocol-blocks/...`) after scaffold. Runtime contract fields use `FIELD:` and optional seed rows use `OPTIONAL:` so downstream smoke tests do not treat internal forms as unfinished migration work.
  - `templates/skill/references/*`, selected workflows, and `SKILL.md.template` — empty seed logs / opt-in advanced sections switched from mandatory `FILL:` to `OPTIONAL:` to avoid fake content just to satisfy validation.
  - `templates/skill/scripts/upstream-status.sh` — missing or placeholder sync points now list the newest upstream entries for a first refresh instead of hard-failing before the agent can recover.
  - `scripts/check-all.sh` — upstream suite now instantiates a temporary downstream skill and runs downstream `sync-routing --check` + `smoke-test --phase 8`, catching scaffold-only failures that self-hosting checks miss.
  - `scripts/check-template-hooks.sh` + `scripts/README.md` — upstream-only SessionStart hook contract check verifies the template emits the right per-harness JSON shape and injects one unambiguous router; wired into `check-all.sh`.
  - `templates/README.md`, `TEMPLATES-GUIDE.md`, `workflows/upgrade-downstream.md`, `references/multi-skill-routing.md` — wording aligned around agent-owned internals and user-hidden update state.
- Why it matters: user-facing downstream setup should be "ask the agent to migrate/update" rather than making users understand `.upstream-sync`, protocol-block placement, optional seed logs, hook JSON shapes, or smoke-test internals. A sample downstream previously exposed `.codex` errors, broken protocol-block links, placeholder sync failures, and mandatory-empty `FILL:` markers despite upstream checks passing.
- Downstream refresh guidance: re-run `update-upstream.md`. Vendor sync will pick up scripts and protocol-blocks for tracking downstreams; manually port the Quick Start/docs wording only if the downstream keeps local copies. If a downstream still has placeholder `.upstream-sync`, the refreshed `upstream-status.sh` will show newest entries and the final update step will write the real sync point.

## 2026-07-06 - Downstream absorb (chaos): red/green bugfix loop, fork posture, §7 corrections

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/fix-bug.md` — **reproduce-first weak form**: new step 3 (express the bug as a repeatable check — test, script, or written manual sequence — and confirm it fails *for the reported reason* before touching code) and step 7 validates with the **same check** red→green; new **Final Report (to the user)** five-field template (root cause / change / verification / blast radius / uncovered risk). The root-cause-first gate is unchanged — reproduction precedes root-causing; the write-the-test-first strong form is deliberately NOT here.
  - `templates/skill/references/tests-as-spec.md` — new **"The bugfix loop (red → green)"** section: the opt-in strong form (acceptance test first, run red, same check green; escape hatch for the un-automatable).
  - `templates/skill/workflows/task-closure.md` — fresh-evidence gate extended one clause: **fresh command ≠ fresh artifact** (validation through a build product requires the product to postdate this task's source changes).
  - `templates/skill/workflows/update-rules.md` — explicit no-restating injunction (closure-gate content exists only in `task-closure.md`) + **escalation rung** in Activation Check: recorded + activated + *recurred* → promote to a machine gate inside the triggering tool (env-var escape hatch; verified recurrence only, imagined-pain rule applies doubly).
  - `templates/skill/workflows/plan-feature.md` — step 8 gains a **project-owned destination** extension point (e.g. product/domain facts → the project's own live docs library) gated on a read-back path; the "no fourth bucket" stance is unchanged.
  - `templates/skill/workflows/update-upstream.md` — new **Posture: tracking (default) vs fork** section: fork is legitimate with three named standing costs (frozen conformance contract, no mechanical vendor fixes, fork points must be registered locally).
  - `templates/skill/workflows/change-managed.md` + `fix-bug.md` FILL comments — a project may declare its cheapest-sufficient validation path (e.g. hot-reload dev server) and the conditions that escalate to the expensive one.
  - `references/skeleton-flesh-split.md` (self-hosting, not shipped) — §7: **checkout-coupling test** decides repo placement (subordinate to §1's abstraction test; the two axes may legally disagree on one item — the fat-jar gotcha is flesh by tier yet skill_root by coupling), owns-table corrected (`gotchas/` / `references/` may split across roots; on overlapping globs the path prefix is the contract), cross-repo write guard, repo-root machine-check blind spot + shared-fragment equality-check warning; §4: reading the hub ≠ reading the content (explicit no-hit declaration required).
  - `references/multi-skill-routing.md` (self-hosting, not shipped) — **defect-class exception** to the ambiguity ladder (bug ownership is a fact: short read-only intake, route by evidence, never primary-fallback; cross-skill bugs share one acceptance check) + shared-resources table: protocol-blocks caveat under two-root/assembled layouts + a shared-workflow-skeleton row (equality check or it is pseudo-dedup).
- Why it matters: first absorb from the chaos downstream (a productized fork since 2026-07-04) — downstream-proven patterns that passed the Borrowed-Pattern Acceptance Test. Rejected as flesh (recorded here so the review isn't re-litigated): mandatory four-file requirement dossiers, the eight-category product-knowledge taxonomy, hand-kept traceability ledgers, and core+shell duplicated workflow copies (absorbed only as the equality-check warning). The script-level fixes from the same review shipped separately — see the entry below.
- Downstream refresh guidance: `fix-bug.md` — cherry-pick step 3 / step 7 / Final Report into your copy if you customized it; the tests-as-spec bugfix section applies only if you opted into that reference; the update-upstream posture section is worth porting if any of your downstreams forked.

## 2026-07-06 - Script debt repaid: two-root layout support + pipefail hardening in vendored scripts

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/scripts/sync-routing.sh` — **two-root prefix awareness** (`skill:`/`code:` normalized in schema + path validation; `code:` paths skipped — the code_root's own tooling validates them) + **inline-YAML parsing** (`labels: { zh: … }`, `required_reads: [a, b]`, `trigger_examples: [a, b]`) + summary formatter tolerates a missing `route:`. Fixes a docs-promised/scripts-refused contract break: `routing.yaml`'s two-root comment and skeleton-flesh-split §7's worked example previously hard-failed (prefixes, inline labels) or silently dropped (inline trigger lists) under the shipped parser. Budget raised 340 → 400 (dated note in `templates/README.md`).
  - `templates/skill/scripts/smoke-test.sh` — accepts a skill **directory path** / cwd (meta-repo layouts like `apps/<app>/skills/<name>`; name read from SKILL.md frontmatter; `skills/$NAME` remains the fallback); **`path_resolution`-gated exemption** — thin-shell / Cursor-entry / `.mdc` absence downgrades fail→warn *only* when `routing.yaml` declares two roots (single-root behavior unchanged); internal sync-routing call passes `$SKILL_DIR` instead of `$NAME`; **pipefail fixes** per the script's own maintenance note — `DUPLICATE_HEADINGS` grep (a gotcha file with no `## ` headings silently killed the entire run), `MDC_COUNT` find, `GOTCHA_FILE` find. Budget note corrected (file had drifted to 903 unrecorded; now ≤ 950, next addition forces extraction).
  - `templates/skill/scripts/route-health.sh` — inline `trigger_examples: [a, b]` parsing (previously dropped silently → false no-trigger smells).
  - `templates/skill/scripts/route-reachability.sh` — stale pointer fixed: `rate-of-change-split.md` → `skeleton-flesh-split.md`.
  - `templates/skill/scripts/check-growth-health.sh` + `templates/README.md` — per-script budget caps updated in both (they are a pair; a pairing note now says so in the budget table).
- Why it matters: upstream debt, surfaced by the chaos downstream carrying local fixes for it — the docs (routing.yaml two-root comment, skeleton-flesh-split §7 worked example) promised a layout and syntax the shipped scripts rejected or silently mis-parsed, and smoke-test violated its own pipefail maintenance rule (a whole run could die silently). Parser ideas absorbed from chaos's local patches, re-reviewed line-by-line; chaos's unconditional fail→warn downgrades were NOT taken (exemption here is gated on `path_resolution` presence).
- Downstream refresh guidance: all five files are vendor-class — `sync-vendor.sh` picks them up mechanically. Single-root downstreams: every change is a no-op for your layout except the pipefail fixes — take them. Two-root downstreams: this release makes the shipped scripts actually support your layout; retire any local parser forks you carried.

## 2026-07-02 - Permission model (opt-in): operation-authority engine + design↔operation double helix

- Status: superseded by 2026-07-17 - Simplify default scaffold and make integrity checks truthful
- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/references/permission-model.md` (**new, ships**) — the **operation axis** ("may the agent take this action?"), distinct from the design axis (code correctness: architecture/conventions/gotchas). **Not a list to match but a classifier you run** before any side-effecting op, keyed on **operation × target/environment** (the same action is 🟢 local/reversible, escalates against prod/shared/irreversible). Contents: the 3-question classifier (🔴 refuse / 🟡 propose-and-stop-*before*-acting / 🟢 default-not-a-list), tier semantics, the **🟡 proposal format** (the 5 things a stop must surface — else "stop and ask" is inert), the **enforcement ladder** (prose → remove-material → pre-commit → CI; "in a doc" ≠ enforced = theater; machine layers only for real-baseline rules, imagined-pain guard), and the **two-axis double helix** — independent-but-paired with the design axis, bound by three rungs. *Additive≠breaking* and *target-decides* refinements are baked into the classifier. report-not-block (🟡 judged by the user; only 🔴 earns a machine gate). Orthogonal to Blast-Radius Buckets (path/closure-rigor) and the subagent Negative list (delegation) — three axes.
  - `templates/skill/workflows/task-closure.md` — **rung #2 (opt-in)**: a one-line operation-authority closure check ("were any 🟡/🔴 ops taken, each surfaced *before* acting? an unannounced 🟡 = a logged overstep") — the operation strand of closure, beside the design-strand AAR.
  - `templates/skill/workflows/update-rules.md` — **rung #3 (opt-in)**: a one-line cross-axis prompt at recording time (a code gotcha ↔ an operation tier; an operation incident ↔ a design convention).
  - `templates/skill/workflows/change-managed.md` — one-line opt-in pointer in step 1 (pre-execution check), disambiguated from post-edit blast-radius buckets.
  - `references/progressive-rigor.md` (self-hosting) — a short "Permission model (advanced)" note.
- Why it matters: a real, already-landed baseline (secrets committed to a downstream repo's history; a prod credential pasted into a session) showed a prose-only "never commit secrets" rule does not prevent the incident. This adds the whole **operation-authority axis** the skill lacked — it could answer "is the code right?" but never "may I act?" — as a cohesive subsystem (engine skeleton + one project table), cross-checked against the design axis at three rungs (classify / closure / growth). Genuinely new to SBA, generalizable.
- Downstream refresh guidance: `permission-model.md` ships as an optional reference (now an **engine**, not a bare tri-color note); the task-closure / update-rules / change-managed hooks are one-line opt-in pointers — no behavior change unless adopted. No conformance change. The **project's concrete 🔴/🟡 table lives in code_root** as ONE full-color file (columns: operation | tier | scope | enforcement now→target (🔴) | blast/why); operation-🔴 lives there, **not** in the design-prohibitions file. Machine enforcement (pre-commit, `.env.example`, CI) is separate consuming-repo infra.

## 2026-07-01 - Tests-as-spec discipline (opt-in): spec-first cases + human oracle + trichotomy

- Status: superseded by 2026-07-17 - Simplify default scaffold and make integrity checks truthful
- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/references/tests-as-spec.md` (**new, ships**) — the full opt-in discipline: (1) write the plan's **test cases at plan time** as the spec; (2) the cases are the **question-generator** that surfaces boundary/failure decisions to the human, who is the **correctness oracle** (the agent can't verify "right thing" against its own single mental model → false-green); (3) cases constrain implementation, realized as unit tests; (4) a failing test = the **trichotomy** (code wrong | case/understanding wrong; revise-with-reason, never edit-to-green); (5) **verification modes** — automated test for unit-testable logic, **human sign-off** for subjective/visual/UX (never machine-tested). Includes when-NOT-to-adopt + the **reports-not-blocks** model: not a blocking gate — the agent generates to spec + lists cases/results transparently, and the user makes the final acceptance call (tests verify code-vs-cases; the user verifies cases-vs-intent).
  - `templates/skill/workflows/plan-feature.md` — a **one-line opt-in pointer** after Task Breakdown (cases feed each task's `Acceptance`; frontend style → user); the substance lives only in the reference, so non-adopters carry ~zero weight in the default workflow.
  - `templates/skill/workflows/task-closure.md` — a **one-line opt-in pointer** under the fresh-verification gate (realize cases → run fresh → trichotomy → report for the user to judge; not self-certified).
  - `references/progressive-rigor.md` (self-hosting) — a short "Tests as spec (advanced)" note.
- Why it matters: recurring production incidents after only light testing are a real (pattern-level) baseline. Tests-as-spec forces coverage (shallow-test root cause) and human-oracle clarification forces correctness (false-green root cause) — the two roots of "under-tested → incident". Captured as **opt-in / not in `conformance.yaml`**: it fits unit-testable work with such a baseline (e.g. a backend), and would be imagined-pain to force on a downstream without one (or on non-unit-testable UI). Enforcement is **not a blocking gate**: the agent's duty is faithful generation + transparent reporting; the user makes the final acceptance call.
- Downstream refresh guidance: `tests-as-spec.md` ships as an optional reference; the plan-feature / task-closure hooks are opt-in pointers, no behavior change unless you adopt the discipline. No conformance change. There is no blocking gate — a project that adopts it makes the *discipline* (write cases → run → report) its norm, and the user judges acceptance.

## 2026-06-30 - Document the two-root split (skill_root / code_root, skill:/code: routing)

- Upstream commit: pending in this working tree
- Changed areas:
  - `references/skeleton-flesh-split.md` § 7 (new) — captures the cross-repo scaling of the 骨架/肉 axis: when a skill's skeleton is shared across code checkouts (or centrally assembled), split it across **two roots** on the same abstraction line — `skill_root` (元仓) owns SKILL.md/routing.yaml/architecture/rules/workflows (skeleton + entry + routing); `code_root` owns conventions/gotchas/references (flesh, lives in the code repo). `routing.yaml` joins them with a `path_resolution` block + `skill:` / `code:` path prefixes so one route composes both. Includes a worked example.
  - `references/progressive-rigor.md` — added a short "Two-root split (advanced)" note framing it as a deployment **topology** beyond Full (not more rigor), pointing at § 7.
  - `templates/skill/routing.yaml` — 2-line advanced comment noting the `skill:`/`code:` + `path_resolution` option; **default single-root layout unchanged**.
- Why it matters: the two-root design (skeleton upstream/shared, flesh in the code repo, joined by `skill:`/`code:` routing) was a genuinely good pattern that had evolved only in a downstream skill and was undocumented in SBA. It is the exact skeleton/flesh line drawn at the repo boundary — a natural extension of the existing axis, not a new concept. Captured as **advanced/optional** (most single-repo skills stay single-root) so it adds no ceremony to default scaffolds.
- Downstream refresh guidance: docs-only for the references (SBA-internal, not shipped). The only shipped change is the 2-line comment in `routing.yaml` — informational; no behavior change, no action needed unless you actually adopt a two-root layout.

## 2026-06-29 - audit-orphans now covers workflows/ (catches dead workflows)

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/scripts/audit-orphans.sh` — now also audits `workflows/` for orphan status (previously only `rules/`/`references/`/`architecture/`/`gotchas/`/`conventions/`; workflows were scanned only as inbound-link *sources*). A workflow reachable from no route (`routing.yaml` `workflow:`/`required_reads`), no sibling workflow, no rule, SKILL.md, or shell is now flagged. Workflows match by **basename** (not full rel path) because siblings cross-link by bare same-dir filename (`task-closure.md`) while routing uses the full path (`skill:workflows/task-closure.md`) — basename catches both; `.example` files and `README.md`/`index.md` are exempt.
  - `scripts/README.md` Check Suite Matrix — audit-orphans row updated to reflect workflow coverage.
- Why it matters: a downstream review found dead workflow files (a `profile-project.md` that was de-routed during customization but left behind) that **no gate caught** — `audit-orphans` skipped workflows and `route-reachability` only covers active content tiers. Structure ≠ used: the same blind spot the actionability dimension addresses, now closed for workflow files too.
- Downstream refresh guidance: `audit-orphans.sh` is a vendor-class script — it arrives via `sync-vendor.sh` on the next `update-upstream`, no manual edit. After it lands, run it; if it flags a workflow, either route it / cross-reference it from another workflow, or delete it.

## 2026-06-27 - Activation gate gains an actionability dimension (eval-derived)

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/update-rules.md` § Activation Check — the gate asked two questions (will the entry be *reached*?). Added a third: **when the agent reads it, does it change the next action?** A "correct-but-inert" entry (read, understood, then the agent proceeds identically) is reached but not activated. The rule line now reads "reached *and acted on*."
  - `SKILL.md` (self-hosting) — Principle 13 "Activation over storage" and Pitfall #4 sharpened the same way: reached-but-inert is a distinct failure from absent/unreachable, and no structural gate can see it — only judgment.
  - `templates/skill/workflows/update-rules.md` § When NOT to Record — added a **Goodhart guard**: content whose only purpose is to move an external metric/score is not recordable; an eval is a signal to improve the skill (run through the normal gates), never a target to optimize. Test: would you write it if the metric didn't exist? (Sibling of the imagined-pain pitfall.)
- Why it matters: an external evaluation (a downstream LLM-judge scoring per-session skill *utility*) exposed a real SBA blind spot — every SBA gate (smoke-test, audit-orphans, route-reachability, conformance) checks *structure* (present / reachable / on-route / within budget), so a skill can pass them all and still be functionally inert (triggered, read, but changes nothing the agent does). Structure ≠ utility. This folds the durable, project-agnostic half of that lesson back into SBA. Deliberately **not** scripted: actionability is a judgment call; a script that "checks usefulness" would be imagined-pain engineering.
- Downstream refresh guidance: small insert into `update-rules.md` § Activation Check (add the third question + reword the rule line); cherry-pick, keep local FILL content. No script, routing, or conformance change. SKILL.md principle edits are self-hosting-only — downstream skills carry their own SKILL.md.

## 2026-06-27 - Borrowed superpowers patterns + plan-structure overhaul

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/plan-feature.md` — three additions: (1) a **canonical Plan Skeleton** (Context → Problem → Options Considered → Chosen Approach → Requirements & Acceptance → Out of Scope → Task Breakdown → Open Questions), now the single source of truth for plan structure; (2) a **Task Breakdown** section — each task declares Files / Consumes / Produces / Acceptance (borrowed from superpowers `writing-plans`' interface declaration, *without* its bite-sized-code-block ceremony) and maps 1:1 onto a Mode 2 subagent contract; (3) a **Brainstorm — diverge before converging** section (≥ 2 distinct options; present design before the Task Breakdown for Large work); plus **立体 angle governance** (each angle file opens with `> Conclusion:`, `prd.md` carries a `## Synthesis` index). `docs/plans/_TEMPLATE.md` + `docs/plans/README.md` (self-hosting only) now point at this canonical skeleton instead of redefining it.
  - `templates/skill/workflows/task-closure.md` — **Fresh verification evidence gate**: no "tests pass / done" claim without running the command in the same message and reading its exit code; a hedge word ("should/probably/seems") before a status claim is the tell. Added as a sub-point of protocol step 1 + a Rationalizations row + a Red Flag.
  - `templates/skill/workflows/fix-bug.md` — **Three Strikes** section: after 3 failed fixes, stop and question the architecture/premise instead of a 4th symptom patch; + a checklist item.
  - `templates/skill/protocol-blocks/subagent-contract.md` + `templates/skill/workflows/subagent-orchestration.md` + `templates/skill/workflows/subagent-driven.md` — **Worker Return Status** vocabulary (`DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED`, adapted from superpowers): the contract block carries the return word, orchestration Phase 4 routes on it, and the Mode-2 router + Phase 1 cross-link the plan's Task Breakdown → contract handoff (lift Files/Consumes/Produces/Acceptance with zero re-derivation).
  - `templates/skill/workflows/receiving-review.md` — **NEW workflow**: acting on code-review feedback with anti-sycophancy (no "you're absolutely right"), verify-before-implement, YAGNI check, push-back-with-evidence. Routed in `templates/skill/routing.yaml`.
- Why it matters: a comparative pass over the superpowers plugin (6.0.3) found SBA and superpowers had largely converged; the net borrow is a small surgical set of mechanisms SBA genuinely lacked. The plan-structure overhaul fixes three real defects — plans were requirements docs with flat step checklists (no executable task decomposition), the self-hosting `_TEMPLATE.md` and the `plan-feature.md` prose described two divergent skeletons, and 立体 angle files had no index/conclusion contract.
- Downstream refresh guidance:
  - `plan-feature.md` is the big one — diff and port the Plan Skeleton + Task Breakdown + Brainstorm sections; preserve any project-specific complexity-gate rows or validation steps. Conformance phrases (Complexity Gate / Question Gate / Gate A–C / Complex Plan / prd.md / workflow-state:planning) are unchanged.
  - `task-closure.md` / `fix-bug.md` / `subagent-orchestration.md` — small inserts; cherry-pick into the local file, keep local FILL content.
  - `receiving-review.md` is a **new optional workflow** — copy it in if the project does code review, add the `receiving-review` route to local `routing.yaml`, then re-run `sync-routing.sh`. It is intentionally NOT in `conformance.yaml` (not mandatory).
  - After porting: `sync-routing.sh`, `smoke-test.sh`, `audit-orphans.sh`, `route-reachability.sh`.

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
