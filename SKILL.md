---
name: skill-based-architecture
description: >
  This skill should be used when the user asks to "organize the project rules",
  "clean up scattered documentation", "把规则迁移到 skills 目录", "优化 skill 路由",
  "提高 description 命中率", or "减少薄壳重复维护".
  Activate when a SKILL.md is too large, rules are duplicated across agent entry
  files, task routing or trigger_examples miss natural user language, or
  templates / thin shells / validation scripts need drift-resistant maintenance.
---

# Skill-Based Architecture

Restructure oversized single-file Skills or scattered project rules into a well-organized Skill directory. Builds on the official minimal Agent Skill contract (`name` + `description`) and kicks in when a single small `SKILL.md` is no longer enough.

## When to Use

- A single `SKILL.md` exceeds ~150 lines, mixing rules, workflows, and background material; or project rules are scattered across `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `.cursor/rules/`, `.claude/`, etc.
- Recurring tasks need procedures, fitted verification, or reliable completion checks; or the user explicitly requests Skill-based architecture or rule consolidation.
- Skip temporary repos with no durable routing need, teams with a working compact instruction system, and small projects; an explicit SBA request may still materialize a complete direct `SKILL.md` carrier.

## Progressive Rigor

Grow only under pressure. The materializer derives **Single-file**, **Folder-light**, or **Full/broad** internally from target evidence; users do not select a tier, profile, capability pack, or install mode. `routing.yaml`, Task Execution, Task Closure, maintenance checks, and each harness surface need their own routing/loading/ownership pressure. **Split by abstraction (骨架/肉)** when content tangles invariant design theory with current-code facts: abstract theory → `architecture/`, code maps → `references/`, house style → `conventions/`, per-module landmines → `gotchas/` (methodology stays in `rules/`). Downgrade when content shrinks. Details: [references/progressive-rigor.md](references/progressive-rigor.md).

## Evidence-Selected Structure

```text
# direct
skills/<name>/SKILL.md
# folder-light or broad: only admitted owners/directories
skills/<name>/{SKILL.md,rules/,workflows/,references/,scripts/}
```

`routing.yaml` appears only when route data has an independent owner; root/tool entry and registration surfaces appear only for proven readers. Existing root entries are preserved. Emitted routed entries use a generated `routing.yaml` bootstrap; direct entries point to the sole `SKILL.md` procedure. Cursor registration exists only when Cursor is detected, declared, currently used, or explicitly requested. See [REFERENCE.md](REFERENCE.md) for sources.

## Core Principles

1. **Single concise entry** — `SKILL.md` keeps a dual budget: description ≤ 25 lines (trigger phrases + activation) + body ≤ 90 lines (navigation); it navigates, not exhausts. ✓ Check: smoke-test reports both separately; over either → split intent clusters / move detail to sub-files.
2. **One skill folder when a folder is admitted** — folder-light and broad results keep formal docs under `skills/<name>/`; a direct result may remain a complete single `SKILL.md` carrier. ✓ Check: no emitted root entry becomes a second rule/workflow owner.
3. **Rules ≠ Flows** — `rules/` for constraints, `workflows/` for procedures. ✓ Check: any numbered steps in `rules/`, or "always/never" in `workflows/`, = mixing.
4. **Routing.yaml as source when admitted** — a direct carrier owns its sole route in `SKILL.md`; multiple/shared routes live only in `routing.yaml`, with routed shells generated from it. ✓ Check: is there an independent selector or consumer that justifies the manifest, and does its fitted sync check pass?
5. **Harness surfaces follow readers** — create/merge only entries and registrations supported by existing files/config, the current harness, repository/team declaration, or an explicit request. ✓ Check: can every emitted surface name its reader, and was every existing entry preserved?
6. **Progressive Rigor** — three carriers (Single-file / Folder-light / Full) grow only under pressure and are not user package choices. ✓ Check: can you name the independent responsibility that forced every generated file?
7. **Description = coarse activation** — domain boundary + real user trigger phrases; never enumerate workflow keywords nor summarize a workflow's steps. ✓ Check: can `routing.yaml` task routes change without rewriting the description, and does no description/label carry HOW an agent could act on without opening the body?
8. **Gotchas are highest-value** — maintain costly pitfalls actively; keep them discoverable. ✓ Check: is each high-cost gotcha activated by the admitted route owner (`SKILL.md` or `routing.yaml`), not only buried in `references/`?
9. **Progressive disclosure** — every loaded file needs an independent task-time reason; conditional content leaves the startup read set; files every real caller co-loads should merge unless ownership/generation requires separate storage. ✓ Check: for each route read, can you name a request that needs it now and a next action it changes? No → conditionally route, merge, or remove.
10. **Task Execution + Closure** — only one clear read-only or fixed-contract maintenance action with no new desired behavior executes directly; anything that adds or changes user-visible behavior, a business flow/state, or an external contract follows `requirement-ready -> Task Anchor -> implementation-ready -> Native Plan -> mutation`; Present alignment proportionally and run a compact Anchor Checkpoint before each main step. Workflow is the domain procedure; Native Plan is only this Session's runtime step owner, with no planning-file persistence. Full protocol: [references/protocols.md § Task Execution Protocol](references/protocols.md#task-execution-protocol).
11. **Durable-record rule** — generic records generalize across projects; business global models stay project-specific but must survive implementation replacement. ✓ Check: use the destination's test—cross-project pattern or cross-implementation business truth—without mixing code details into either ([ref](references/protocols.md#generalization-rule)).
12. **Self-maintenance** — line counts signal evaluation, not automatic action; split only for independently selected tasks; merge files universally co-loaded/co-changed unless ownership or generation explains the boundary. ✓ Check: can the before/after load matrix prove less irrelevant reading without losing definitions, conditions, boundaries, or reasons?
13. **Activation over storage** — content in `references/` alone is not "captured"; it must be on the task path **and change what the agent does when read**; reached-but-inert (correct, on-route, yet the agent would have proceeded identically) is a distinct failure no structural gate can see, only judgment can. ✓ Check: trace the normal route — does hitting the entry change the next action (a file read, a check run, a step skipped)?
14. **Token efficiency** — Always Read defaults to empty; every addition needs proof that all real tasks require it before workflow selection; domain and lifecycle knowledge loads only when evidence or a phase boundary can change the next action. ✓ Check: can any startup read be delayed without changing the first workflow decision? If yes, move it to that workflow checkpoint.
15. **Rationalizations Table** — captures verbatim excuses from real pressure-test failures only. ✓ Check: every row traces to a real failure — no failure observed and unwilling to baseline it → imagined-pain, drop it ([ref](templates/skill/workflows/task-closure.md#rationalizations-to-reject), [Phase 9](workflows/full-migration.md#phase-9-pressure-test-the-skill)).
16. **Response discipline** — output short, precise, direct answers; avoid process narration, self-congratulation, gratuitous confirmations, and requirement restatement. ✓ Check: does each sentence serve the explicit request? No → delete it.
17. **Proof claims stay separated** — fitted structural checks, source-disposition migration evidence, and live Agent behavior prove different things; green structure cannot be promoted into semantic or behavioral correctness. ✓ Check: does the final claim name the exact layer actually run, and report unavailable live evidence as no verdict?

## Common Pitfalls

1. **Missing admitted harness surface** — a project proves a Cursor/Claude/etc. reader but its fitted registration/entry is absent → that harness never discovers the formal owner; the opposite error (emitting every harness without evidence) imposes permanent maintenance cost.
2. **Wrong routing carrier** — a routed shell says only "go read SKILL.md" without the generated routing.yaml bootstrap, or a direct project gains an empty manifest merely for uniformity → either recovery breaks or false machinery appears.
3. **Vague / wrong-scope description** — passive, wrong-language, too narrow ("fix bug" only), or bloated with every workflow keyword → misses natural requests or over-fires; keep it domain-level and route tasks in `SKILL.md`.
4. **Stored but not activated — or activated but inert** — a costly pitfall recorded in `references/` but not surfaced in an owning workflow checkpoint, or on-route yet written as a background fact, never changes the agent's next action; reachable ≠ useful.
5. **Completion responsibility lost during materialization** — the agent considers itself done after main work although the admitted workflow/Closure owner requires fitted verification or AAR; a simple workflow may own that inline; pure Q&A/read-only tasks remain exempt.
6. **Project-specific records** — lessons written as project narratives ("in our product module, we found…") are useless outside current context; apply the generalization rule before recording.
7. **No SessionStart hook on long sessions** — `/clear` or `/compact` silently drops SKILL.md from context without the user noticing → install a SessionStart hook if your harness supports it ([references/thin-shells.md § SessionStart Hook](references/thin-shells.md#sessionstart-hook-optional)).
8. **Route skipping in multi-task sessions** — the agent reuses the last task's route for a new task and works from stale memory, missing critical rules → re-match the route every task (tiered Session Discipline; all shells carry the trigger).
9. **Missing or performative Task Anchor / long-task drift** — the agent starts a non-Simple task without a stable Goal/Done When or dumps a labeled block duplicating the native Plan → use `templates/skill/workflows/task-execution.md`; keep the Anchor as runtime state and run `reboot-check.md` before final validation/commit.
10. **Imagined-pain engineering** — before adding any mechanism (rule/script/file/template section), give a concrete scenario (file+line / commit / session) proving it really happened; none → don't add it. Historic: 5 ghost scripts (cut 2026-05-19), dossier schema (cut 2026-05-19), reflection-first mode shift (dropped 2026-05-20), observations log (rejected 2026-05-20).

## Content Classification

| Content type — tier by **abstraction**: 骨架 (architecture/workflows/rules = invariant theory) vs 肉 (conventions/gotchas/references = current-code facts) · [split playbook](references/skeleton-flesh-split.md) | Target | Kind |
|---|---|---|
| Abstract design theory — layering/contract/orchestration/transaction **principles**, the "why" (**NOT** the module map) | `architecture/` | 骨架 |
| Code maps + background — module tree, dir layout, source index, build/env notes | `references/` | 肉 |
| House style — naming, paths, commands, formats, must/never conventions | `conventions/` | 肉 |
| Code-coupled landmines (symptom → cause → fix), split only by independently routed module | `gotchas/` (selecting `gotchas/index.md` only after multi-file pressure) | 肉 |
| Step-by-step task procedures (process theory) | `workflows/` | 骨架 |
| Prompts/reports/docs · editor config (thin shells) | `docs/` · `.cursor/` `.claude/` | — |

## Multi-Skill & Composition

**Multi-skill repos** — see [references/multi-skill-routing.md](references/multi-skill-routing.md) (operating + fission + coexistence). For **invoking other skills** from your workflows (embedded / serial / subagent delegation), see [references/skill-composition.md](references/skill-composition.md) + starter [templates/skill/workflows/invoke-skill.md.example](templates/skill/workflows/invoke-skill.md.example).

## Resources

- [WORKFLOW.md](WORKFLOW.md) — Migration procedure (Quick Start + 9 phases + Downstream Upgrade)
- [REFERENCE.md](REFERENCE.md) + [references/](references/) — Templates, decision guides, anti-patterns, troubleshooting, self-hosting routing source
- [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) — Starter templates + meta-workflow templates; [EXAMPLES.md](EXAMPLES.md) + [examples/](examples/) — behavior failures + before/after scenarios
