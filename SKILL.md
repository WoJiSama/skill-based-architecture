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

- A single SKILL.md exceeds ~150 lines, mixing rules, workflows, and background material
- Project rules are scattered across `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `.cursor/rules/`, `.claude/`, etc.
- User explicitly requests Skill-based architecture or rule consolidation

## When NOT to Use

- Very small projects (fewer than 3 rule/doc files)
- Temporary repos with no long-term maintenance needs
- Teams with a well-functioning documentation system who don't want to migrate

## Progressive Rigor

Grow only under pressure. Tiers: **Single-file** (`SKILL.md` only, < 3 topics) → **Folder-light** (`+ rules/`, 3–5 topics or 1 recurring workflow) → **Full** (`+ workflows/` + `references/` + thin shells; ≥ 3 routed tasks, gotcha log, or multi-harness repo). Upgrade triggers: SKILL.md body > 90 lines or description > 25 lines, same pitfall surfaces twice, a task needs step-by-step instructions, or two harnesses share routing. **Split by abstraction (骨架/肉)** when content tangles invariant design theory with current-code facts: abstract theory → `architecture/`, code maps → `references/`, house style → `conventions/`, per-module landmines → `gotchas/` (methodology stays in `rules/`). Downgrade when content shrinks. Details: [references/progressive-rigor.md](references/progressive-rigor.md).

## Target Structure

```text
skills/<name>/
├── SKILL.md          # dual budget (description ≤ 25 + body ≤ 90 lines): always-read list, task routing, priority
├── architecture/     # abstract design theory (骨架) — layering/contract principles, the "why" — NOT the module map
├── conventions/      # house style (肉) — naming, paths, commands, formats
├── gotchas/          # code-coupled landmines (肉) — split by independently routed module; index only when it selects a leaf
├── workflows/        # step-by-step procedures (骨架 — process theory)
├── references/       # code maps + background (肉) — module tree, dir layout, source index, build/env
└── docs/             # Optional: prompts, reports, external-facing material
```

Root entries (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`) → thin shells with a `routing.yaml` bootstrap, not duplicated route tables.
`.cursor/skills/<name>/SKILL.md` → Cursor registration entry (required for discovery). See [REFERENCE.md](REFERENCE.md) for templates.

## Core Principles

1. **Single concise entry** — `SKILL.md` keeps a dual budget: description ≤ 25 lines (trigger phrases + activation) + body ≤ 90 lines (navigation). It navigates, not exhausts. ✓ Check: smoke-test reports both separately; over either → split intent clusters / move detail to sub-files.
2. **One skill folder** — all formal docs under `skills/<name>/`, not scattered at repo root. ✓ Check: `ls *.md` at root shows only thin shells, not rule/workflow files.
3. **Rules ≠ Flows** — `rules/` for constraints, `workflows/` for procedures. ✓ Check: any numbered steps in `rules/`? Any "always/never" in `workflows/`? Either = mixing.
4. **Routing.yaml as source** — task routes live in `routing.yaml`; shells only say how to read it. ✓ Check: route changed without running sync/check? No → drift risk.
5. **Cursor registration entry** — `.cursor/skills/<name>/SKILL.md` must exist. ✓ Check: `ls .cursor/skills/` — missing = Cursor cannot discover the skill.
6. **Progressive Rigor** — three tiers (Single-file / Folder-light / Full); grow only under pressure — see [Progressive Rigor section above](#progressive-rigor) + [details](references/progressive-rigor.md). ✓ Check: can you name the specific pressure that forced the current tier? "It felt right" ≠ pressure.
7. **Description = coarse activation** — domain boundary + real user trigger phrases; never enumerate workflow keywords nor summarize a workflow's steps — a step-summary becomes a shortcut the agent runs instead of reading the body ([ref](references/layout.md#description-as-trigger-condition)). ✓ Check: (a) can Common Tasks change without rewriting the description? (b) does the description or any route label carry HOW an agent could act on without opening the body/workflow? "no" to (a) or "yes" to (b) → fix.
8. **Gotchas are highest-value** — maintain costly pitfalls actively; keep them discoverable. ✓ Check: is each high-cost gotcha reachable from a Common Tasks route, not only buried in `references/`?
9. **Progressive disclosure** — every loaded file or expanded read must name the missing decision information, the judgment it can change, the smallest sufficient slice, and the evidence that stops further search; universal co-loads merge unless ownership/generation requires separation. ✓ Check: can each read answer all four? No → narrow, conditionally route, merge, or remove it.
10. **Task Execution + Closure** — after routing, one clear action/check executes directly; otherwise establish a Task Anchor (Goal + Done When + optional Boundaries), present it proportionally instead of dumping a fixed chat template, use the harness-native Plan without repeating visible steps, and run a compact Anchor Checkpoint before every main step so evidence—not drift—advances the task, then enter Task Closure ([ref](references/protocols.md#task-execution-protocol)). Workflow remains the domain procedure; Plan is only this Session's runtime instance, with no planning-file persistence. ✓ Check: immediately before the current step, can you name the Goal, remaining Done When evidence, step check, and Closure proof without replacing or skipping the matched Workflow?
11. **Durable-record rule** — generic records generalize across projects; business global models stay project-specific but must survive implementation replacement ([ref](references/protocols.md#generalization-rule)). ✓ Check: use the destination's test—cross-project pattern or cross-implementation business truth—without mixing code details into either.
12. **Self-maintenance** — line counts signal evaluation, not automatic action. Split only for independently selected tasks; merge files universally co-loaded/co-changed unless ownership or generation explains the boundary. ✓ Check: can the before/after load matrix prove less irrelevant reading without losing definitions, conditions, boundaries, or reasons?
13. **Activation over storage** — content in `references/` alone is not "captured"; it must be on the task path **and change what the agent does when read**. Reached-but-inert (correct, on-route, yet the agent would have proceeded identically without it) is a distinct failure from absent or unreachable — and no structural gate (orphan / route-reachability / smoke-test) can see it, only judgment can. ✓ Check: (a) trace the normal route — Agent hits the entry without hunting? (b) does hitting it change the next action — a file it now reads, a check it now runs, a step it now skips? "no" to either → stored, not activated.
14. **Token efficiency** — optimize correctness-gated context, not context size alone: keep Always Read to 2–3 files, then route → locate symbols → read local implementation → inspect one-hop consumers/tests → expand only while decision evidence is missing. ✓ Check: did stopping preserve the key call chain and semantic completeness?
15. **Rationalizations Table** — captures verbatim excuses from real pressure-test failures, organic or proven by a [baseline run](references/scenario-testing.md) before shipping ([ref](templates/skill/workflows/task-closure.md#rationalizations-to-reject), [Phase 9](workflows/full-migration.md#phase-9-pressure-test-the-skill)). ✓ Check: every row traces to a real failure — no failure observed and unwilling to baseline it → imagined-pain, drop it.
16. **Response discipline** — output short, precise, direct answers; avoid process narration, self-congratulation, gratuitous confirmations, and requirement restatement. Correct objective errors neutrally; do not infer user stance. ✓ Check: does each sentence serve the explicit request? No → delete it.

## Common Pitfalls

1. **Missing Cursor registration entry** — Formal skill at `skills/<name>/` but no `.cursor/skills/<name>/SKILL.md` → Cursor never discovers the skill; all rules/workflows silently ignored
2. **Soft-pointer-only shell** — Thin shell says only "go read SKILL.md" without a `routing.yaml` bootstrap → instruction lost after context summarization in long conversations
3. **Vague / wrong-scope description** — Description is passive, wrong-language, too narrow ("fix bug" only), or bloated with every workflow keyword → skill misses natural requests or over-fires; keep description domain-level and route tasks in SKILL.md
4. **Stored but not activated — or activated but inert** — Costly pitfall recorded in `references/` but not surfaced in any workflow checklist or SKILL.md routing → future agents still miss it. Subtler form: it *is* on the route and gets read, but it's "correct but inert" — written as a background fact, not as a next action — so the agent reads it and proceeds unchanged. Reachable ≠ useful; the entry must change what the agent does, not merely be present and correct
5. **Task Closure Protocol skipped when it should have fired** — Agent considers itself "done" after main work and skips the 30-second AAR scan even though the Trigger Policy admitted the task (code/doc change happened) → lessons not captured. AAR is a completion gate when triggered, not an optional add-on. Pure Q&A / read-only tasks are correctly exempt — do not run AAR on them either
6. **Project-specific records** — Lessons written as project narratives ("in our product module, we found…") instead of reusable knowledge → useless outside current context; apply generalization rule before recording
7. **No SessionStart hook on long sessions** — `/clear` or `/compact` silently drops SKILL.md from context; agent loses all routing and protocol awareness without the user noticing → install SessionStart hook if your harness supports it (see [references/thin-shells.md § SessionStart Hook](references/thin-shells.md#sessionstart-hook-optional))
8. **Route skipping in multi-task sessions** — Agent reads SKILL.md for the first task, then skips re-reading for subsequent tasks in the same session ("I already know the rules"). New tasks may match different routes; context may have been compressed. Result: agent works from partial/stale memory, misses critical rules, debugs in wrong direction for hours → SKILL.md template ships a tiered Session Discipline (re-match the route every task; re-read files only on route-change or compaction — cheap re-match catches different routes without re-reading everything); all shells carry the trigger
9. **Missing or performative Task Anchor / long-task drift** — Agent starts a non-Simple task without a stable Goal/Done When, invents them only at the end, or dumps a fixed labeled block that duplicates the native Plan → use `templates/skill/workflows/task-execution.md`; keep the Anchor as runtime state, present only useful alignment, and run `reboot-check.md` before final validation/commit if the original constraints are no longer fresh
10. **Imagined-pain engineering** — Agent 提议加任何机制(规则/脚本/文件结构/模板章节)前没反问"这解决的是真痛点还是脑补":为未发生的失败加保险、为想象用户预建脚手架、为不存在的协议加 marker / 监控、给假设的"agent 偏差"立规矩。✓ Check:能给一个具体场景(file+line / commit / session)证明这事真发生过吗?给不出 → 不上。Historic: 5 ghost scripts (砍 2026-05-19), dossier schema (砍 2026-05-19), reflection-first mode shift (弃 2026-05-20), observations 日志 (拒上 2026-05-20)

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
- [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) — Starter templates + meta-workflow templates
- [EXAMPLES.md](EXAMPLES.md) + [examples/](examples/) — behavior failures + before/after scenarios
