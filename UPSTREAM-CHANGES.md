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

- Upstream commit: <hash> <subject>
- Changed areas: <files or directories>
- Why it matters: <intent>
- Downstream refresh guidance: <what to compare/port/preserve>
```

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

## 2026-05-08 - Growth governance and executable skill guidance

- Upstream commit: pending in this working tree
- Changed areas: `references/executable-skill-architecture.md`,
  `references/scenario-testing.md`, `references/README.md`,
  `references/layout.md`, `references/protocols.md`, `TEMPLATES-GUIDE.md`,
  `templates/skill/workflows/profile-project.md`,
  `templates/skill/workflows/update-rules.md`,
  `templates/skill/routing.yaml`, `templates/README.md`,
  `templates/ANTI-TEMPLATES.md`, `scripts/check-upstream-changes.sh`, and
  `UPSTREAM-CHANGES.md`
- Why it matters: separates the lightweight core scaffold from optional
  executable-skill growth paths, adds behavior-testing guidance, and gives
  maintainers explicit growth-health triggers before templates or checks bloat.
- Downstream refresh guidance: compare and port the new references and the
  `profile-project` / `update-rules` workflow refinements when a downstream
  project needs executable-skill classification or high-risk route validation.
  Do not add `scripts/`, `tools/`, `capability/`, `conf/`, or a scenario harness
  to existing downstream skills unless their project evidence passes the new
  executable or scenario-testing gates.

## 2026-05-07 - One-command upstream check suite

- Upstream commit: see `git log -- scripts/check-all.sh` for the introducing
  commit; this entry documents the check suite added by that same change
- Changed areas: `scripts/check-all.sh`, `scripts/check-upstream-changes.sh`,
  `templates/README.md`, `README.md`, `README.zh-CN.md`, `skill.yaml`, and
  `UPSTREAM-CHANGES.md`
- Why it matters: gives upstream maintainers a single command for the full
  maintenance gate instead of relying on a remembered list of individual checks.
- Downstream refresh guidance: do not copy this root script into downstream
  projects. It is an upstream maintenance command; downstream projects keep
  using their copied `skills/<name>/scripts/*` validation commands.

## 2026-05-07 - README positioning statement

- Upstream commit: see `git log -- README.md README.zh-CN.md` for the
  introducing commit; this entry documents a README-only positioning change
- Changed areas: `README.md`, `README.zh-CN.md`, and `UPSTREAM-CHANGES.md`
- Why it matters: clarifies that this project is a lifecycle framework for
  Agent rule systems, not a technology-specific rule library.
- Downstream refresh guidance: no downstream refresh action is required unless
  a downstream project mirrors upstream README wording intentionally.

## 2026-05-07 - Guard upstream change notes

- Upstream commit: see `git log -- scripts/check-upstream-changes.sh` for the
  introducing commit; this entry documents the check added by that same change
- Changed areas: `scripts/check-upstream-changes.sh`, `UPSTREAM-CHANGES.md`,
  `WORKFLOW.md`, `README.md`, `README.zh-CN.md`, `skill.yaml`, and
  `templates/README.md`
- Why it matters: prevents downstream-facing upstream changes from landing
  without an update note for future downstream refresh agents.
- Downstream refresh guidance: do not copy this root script into downstream
  projects. It is an upstream maintenance guard; downstream agents only read
  the resulting `UPSTREAM-CHANGES.md` from a cloned upstream repo.

## 2026-05-07 - Upstream change notes for downstream refreshes

- Upstream commit: see `git log -- UPSTREAM-CHANGES.md` for the introducing
  commit; this entry documents the mechanism added by that same change
- Changed areas: `UPSTREAM-CHANGES.md`, `WORKFLOW.md`, `README.md`,
  `README.zh-CN.md`, `skill.yaml`, and
  `templates/skill/workflows/update-upstream.md`
- Why it matters: gives downstream refresh agents an upstream-owned update map
  to read before they inspect actual file diffs.
- Downstream refresh guidance: port the updated `update-upstream` workflow if a
  downstream project should read upstream notes first. Do not copy, create, or
  update `UPSTREAM-CHANGES.md` in downstream projects; read it from the cloned
  upstream repo during refresh.

## 2026-05-07 - README branding and planning workflow hooks

- Upstream commit: `12db598 Add README branding and planning workflow hooks`
- Changed areas: `README.md`, `README.zh-CN.md`, `WORKFLOW.md`,
  `references/thin-shells.md`, `templates/README.md`,
  `templates/checklists/post-migration.md`, `templates/hooks/*`,
  `templates/skill/SKILL.md.template`, `templates/skill/routing.yaml`,
  `templates/skill/workflows/plan-feature.md`, and
  `assets/skill-based-architecture-title.png`
- Why it matters: adds the README title asset and project badges, introduces
  the reusable `plan-feature` workflow/route, and adds the `workflow-state`
  hook so long-running work can surface the active workflow state.
- Downstream refresh guidance: compare hook files, routing, SKILL summary, and
  workflow scaffolding as mechanism-owned changes. Preserve downstream
  project-specific routes, examples, rules, gotchas, and workflow text unless
  the upstream change fixes a reusable mechanism.

## 2026-04-30 - Routing manifests and upstream refresh workflow

- Upstream commit: `9cc9e56 Add routing manifests and upstream refresh workflow`
- Changed areas: `templates/skill/routing.yaml`,
  `templates/skill/workflows/update-upstream.md`,
  `templates/skill/scripts/sync-routing.sh`,
  root/self-hosting routing references, and generated shell bootstraps
- Why it matters: makes `routing.yaml` the source of truth for generated Always
  Read lists, Common Tasks, trigger examples, required reads, workflows, and
  thin-shell bootstraps; introduces the agent-led upstream refresh workflow.
- Downstream refresh guidance: port the routing source-of-truth mechanism and
  `update-upstream` workflow when missing. Regenerate generated sections from
  local `routing.yaml`; do not hand-edit shell bootstraps or overwrite
  downstream task examples.
