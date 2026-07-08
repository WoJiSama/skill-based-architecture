# templates/ — Pre-Built Copy-Pasteable Content

This directory holds **ready-to-copy files** for downstream projects. WORKFLOW.md Quick Start copies this tree into the target project and runs a single `sed` pass to substitute placeholders. The goal: eliminate the "Agent generated the file inline and dropped half the sections" failure mode.

`SKILL.md` sources intentionally use the `.template` suffix. Codex-style skill loaders may recursively scan installed skills for `SKILL.md`; leaving raw template files with placeholder frontmatter under `templates/` makes them look like broken real skills. Quick Start renames `SKILL.md.template` to `SKILL.md` after copying into the downstream project.

## Layout

```
templates/
├── skill/                    → becomes skills/{{NAME}}/
│   ├── SKILL.md.template     (renamed to SKILL.md during Quick Start)
│   ├── routing.yaml            (single source for Always Read + Common Tasks + shell bootstraps)
│   ├── sync-manifest.yaml      (vendor-class file list consumed by scripts/sync-vendor.sh)
│   ├── rules/{project-rules,coding-standards,agent-behavior}.md
│   ├── workflows/{profile-project,plan-feature,update-upstream,update-rules,fix-bug,change-managed,edit-templates,maintain-docs,subagent-driven,subagent-orchestration}.md
│   ├── workflows/invoke-skill.md.example  (copy-paste template for Pattern A composition; rename and adapt)
│   ├── references/{gotchas,behavior-failures}.md
│   ├── protocol-blocks/       → internal Task Closure / routing reinforcement blocks
│   └── scripts/              → automated verification (lives inside the skill)
│       ├── smoke-test.sh                (fully automated structural + routing checks)
│       ├── sync-routing.sh              (generate/check routing summary + shell bootstraps from routing.yaml)
│       ├── sync-vendor.sh               (mechanical vendor-file sync from an upstream clone; base = synced_sha)
│       ├── upstream-status.sh           (am-I-behind reporter + wrong-checkout guard; reads .upstream-sync)
│       ├── footprint.sh                 (static per-task read-cost dashboard)
│       ├── route-health.sh              (static routing-quality lint; advisory)
│       ├── check-cross-references.sh    (workflows → rules/references staleness heuristic)
│       ├── check-growth-health.sh       (non-blocking growth pressure report)
│       ├── audit-orphans.sh             (content-tier files with zero inbound links)
│       └── check-version-conformance.sh (downstream contract: required sections / files present)
├── shells/                   → becomes repo-root entry files
│   ├── AGENTS.md / CLAUDE.md / CODEX.md / GEMINI.md
│   ├── .cursor/rules/workflow.mdc
│   └── .cursor/skills/{{NAME}}/SKILL.md.template
├── hooks/                    → optional SessionStart injection + mechanism-level gates
│   ├── session-start              (bash, per-harness JSON branching — re-inject one router)
│   ├── workflow-state             (bash, UserPromptSubmit — inject one active workflow hint)
│   ├── agent-behavior-gate.sh     (bash, PreToolUse — enforce Admission Threshold deterministically)
│   ├── hooks.json                 (Claude Code settings fragment — SessionStart + UserPromptSubmit + PreToolUse)
│   ├── hooks-cursor.json          (Cursor config — same as above, per-harness wiring)
│   ├── README.md                  (rollout / tuning / false-positive mitigations, per-hook)
│   └── SECURITY.md                (trust boundary: what may vs must not be written to hook-read files)
```

## Placeholders

Two kinds — each with a different "fill" mechanism:

| Marker | Meaning | Filled by |
|---|---|---|
| `{{NAME}}`, `{{SUMMARY}}` | Mechanical substitution | Single `sed` pass in Quick Start |
| `<!-- FILL: … -->` | Requires agent judgment before the skill ships | `grep -r 'FILL:'` lists pending migration work |
| `<!-- OPTIONAL: … -->` | Advanced or organically-grown content | Leave empty unless the project has real evidence or user asks |

**Audit after Quick Start:** run `grep -r 'FILL:' skills/{{NAME}} AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor` — every match is required agent work before shipping. Users should not need to interpret these markers.

## Byte Budgets (hard limits — enforce in review)

> The numbers below and the per-script caps in `skill/scripts/check-growth-health.sh` are a pair — change both in the same commit, or the report silently disagrees with the policy (this table had drifted from a script's real size once already).

| Path | Budget | Enforcement |
|---|---|---|
| `shells/*` | ≤ 60 lines | Thin shells must stay thin; > 60 = content leaking in. Must include generated Always Read + `routing.yaml` bootstrap + route-before-routing check for vague verbs (see `protocol-blocks/ambiguous-request-gate.md`) |
| `skill/routing.yaml` | ≤ 120 lines | Single source of truth for generated Always Read, Common Tasks, trigger examples, required reads, workflows, and thin-shell bootstraps; project-specific after fill |
| `skill/rules/project-rules.md`, `skill/rules/coding-standards.md` | ≤ 20 lines, ≥ 60% must be `<!-- FILL: -->` | Rule stubs are scaffolding, not content |
| `skill/rules/agent-behavior.md` | ≤ 100 lines, fully pre-filled | Universal coding defaults. Exception to the stub-only rule — ships as content. **Growth gated** by `ANTI-TEMPLATES.md § Admission Threshold` (convention-level, ~30% hostile-prompt block rate). For mechanism-level enforcement install `templates/hooks/agent-behavior-gate.sh` — blocks 100% of tested attack classes deterministically |
| `hooks/session-start`, `hooks/workflow-state`, `hooks/agent-behavior-gate.sh` | ≤ 150 lines each | Optional hook scripts. Keep per-harness branching in-script; see `hooks/README.md` |
| `hooks/README.md` | ≤ 150 lines | Per-hook rollout guidance; allowed larger because it documents optional installs + tuning |
| `skill/workflows/profile-project.md`, `plan-feature.md`, `update-upstream.md`, `fix-bug.md`, `change-managed.md`, `edit-templates.md`, `subagent-orchestration.md` | ≤ 100 lines | Task-specific workflows stay lean |
| `skill/workflows/update-rules.md`, `maintain-docs.md`, `subagent-driven.md` | ≤ 250 lines | Protocol-heavy workflows allowed more room |
| `skill/protocol-blocks/*` | ≤ 40 lines each | One idea per block |
| `skill/SKILL.md.template` | dual budget: description ≤ 25 lines + body ≤ 90 lines | Same hard cap as downstream SKILL.md (smoke-test enforces both separately). description carries quoted trigger phrases; body navigates rules/workflows/references. Keep each shorter when possible. |
| `skill/scripts/smoke-test.sh` | ≤ 950 lines (was 850; raised 2026-07-06 — file had already drifted to 903 unrecorded; +34 for two-root layout support (dir-path resolution, `path_resolution`-gated shell exemptions) + pipefail hardening, absorbed from the chaos downstream). **Next addition forces extraction** into a `check-<concern>.sh` companion script — no further raises. | Structural test harness; keep scenario behavior out of this script |
| `skill/scripts/sync-routing.sh` | ≤ 400 lines (was 340; raised 2026-07-06 — two-root `skill:`/`code:` prefix awareness + inline-YAML parsing, honoring the routing.yaml two-root contract the docs already promised; parser ideas absorbed from the chaos downstream) | Generator/checker for routing.yaml-derived blocks; keep dependency-free |
| `skill/scripts/sync-vendor.sh` | ≤ 160 lines | Mechanical vendor sync; base check via upstream git history — no new state files |
| `skill/sync-manifest.yaml` | ≤ 40 lines | Vendor-class file list only; project-owned files never belong here |
| `skill/scripts/check-growth-health.sh` | ≤ 220 lines | Non-blocking pressure report for line counts, route counts, and script/workflow budgets |
| `skill/scripts/audit-orphans.sh` | ≤ 120 lines | Zero-inbound report for content tiers (`rules/` `references/` `architecture/` `gotchas/` `conventions/`); scans `routing.yaml` too; heuristic, run before deleting flagged files |
| `skill/references/gotchas.md` | ≤ 25 lines (seed) | MUST stay near-empty — content grows post-deployment |
| `skill/references/behavior-failures.md` | ≤ 25 lines (seed) | MUST stay near-empty — agent-behavior violations logged via AAR |

Anything over budget needs either splitting or rejection. See `ANTI-TEMPLATES.md`.

## Growth Health

Review these signals during major template or skill updates. A threshold does
not force an automatic refactor; it forces an explicit decision.

| Signal | Review when | Default action |
|---|---:|---|
| `SKILL.md` description lines | > 25 | Split intent clusters or shorten activate-when clause |
| `SKILL.md` body lines | > 90 | Move detail to routed files or downgrade scope |
| Always Read files | > 3 | Demote domain-specific files to task routes |
| Concrete routes | > 10 | Group routes, merge low-frequency tasks, or evaluate multi-skill split |
| `references/` orphans | > 0 | Add an activation path or delete the reference |
| Workflow line count | > budget row above | Split only if sections are independently navigable |
| Check script line count | > budget row above | Extract checks or reject new mechanism weight |
| High-risk route scenarios | 0 covered | Add contract/scenario tests before trusting behavior |

Executable-skill pressure is a separate signal: if project evidence shows
external APIs/CLIs, remote side effects, repeated script logic, local config, or
stable output contracts, read `references/executable-skill-architecture.md`
before expanding the base template.

## The "Would Two Real Projects Disagree?" Test

Before adding anything to this directory, answer:

> "A Go backend microservice and a React animation site both pull this template. Would they both agree on this content?"

- **Yes** → it's structural protocol; may go in `templates/`.
- **No / probably not** → it's project-specific; move to `<!-- FILL: -->` comment or `examples/` instead.

No exceptions. If this test is hand-waved, `templates/` slides into opinionated defaults and downstream projects start looking identical.

New reusable mechanisms must also pass the [Mechanism Admission Gate](ANTI-TEMPLATES.md#mechanism-admission-gate): reduce repeated maintenance or prevent a verified recurring failure; otherwise keep them out of `templates/` as mechanisms.

## Anti-Drift Checks

Run these when templates change:

1. **Growth health report** — run `bash templates/skill/scripts/check-growth-health.sh .`; WATCH/REVIEW rows force an explicit decision, but do not fail by default.
2. **Placeholder audit** — `grep -r '{{' templates/` lists every placeholder; must match the `sed` substitution set in WORKFLOW.md Quick Start (no orphans).
3. **Loader-safety audit** — `find templates -name 'SKILL.md'` must return no rows; template sources use `SKILL.md.template` until Quick Start materializes them downstream.
4. **FILL audit** — `grep -r 'FILL:' templates/` must return only required migration-work markers (`rules/`, `SKILL.md.template`, `routing.yaml`). Empty seed logs and advanced opt-in sections use `OPTIONAL:`, not `FILL:`.
5. **Routing manifest audit** — run `bash templates/skill/scripts/sync-routing.sh templates/skill --check`; then instantiate a sample, fill `routing.yaml`, run `bash skills/<name>/scripts/sync-routing.sh <name> --check`; generated Always Read lists, summaries, and bootstraps must match.
6. **Orphan audit** — run `(cd skills/<name> && bash scripts/audit-orphans.sh)` to surface `rules/` or `references/` files with zero inbound links. Add an activation pointer or delete the file; read it before deleting.
7. **Homogeneity spot-check** — run Quick Start against two toy projects of very different types (Go CLI + Next.js site) and `diff -r` the output. Skeleton files should be near-identical; `rules/`, `gotchas.md`, `routing.yaml`, `SKILL.md` Always Read + Common Tasks must **not** be identical. If they are, the template overreached.
8. **Upstream check suite** — run `bash scripts/check-all.sh` from this upstream repo. It instantiates a temporary downstream skill and runs its smoke test so scaffold internals stay black-boxed. It also includes the upstream change-note gate: if downstream-facing upstream files changed, the same diff must update `UPSTREAM-CHANGES.md`; if there is no downstream refresh impact, record that explicitly there.
