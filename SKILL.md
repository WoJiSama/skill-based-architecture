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
- Project rules are scattered across `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `.cursor/rules/`, `.claude/`, `.codex/`, etc.
- User explicitly requests Skill-based architecture or rule consolidation

## When NOT to Use

- Very small projects (fewer than 3 rule/doc files)
- Temporary repos with no long-term maintenance needs
- Teams with a well-functioning documentation system who don't want to migrate

## Progressive Rigor

Grow only under pressure. Tiers: **Single-file** (`SKILL.md` only, < 3 topics) → **Folder-light** (`+ rules/`, 3–5 topics or 1 recurring workflow) → **Full** (`+ workflows/` + `references/` + thin shells; ≥ 3 routed tasks, gotcha log, or multi-harness repo). Upgrade triggers: SKILL.md > 100 lines, same pitfall surfaces twice, a task needs step-by-step instructions, or two harnesses share routing. Downgrade when content shrinks. Details: [references/layout.md § Progressive Rigor](references/layout.md#progressive-rigor).

## Target Structure

```text
skills/<name>/
├── SKILL.md          # ≤100 lines: always-read list, task routing, priority
├── rules/            # Long-lived constraints (what is always true)
├── workflows/        # Step-by-step procedures (how to do a task)
├── references/       # Background: architecture, pitfalls, indexes
│   └── gotchas.md    # Recommended: known gotchas / footguns (most valuable reference)
└── docs/             # Optional: prompts, reports, external-facing material
```

Root entries (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`, `.codex/`) → thin shells with a `routing.yaml` bootstrap, not duplicated route tables.
`.cursor/skills/<name>/SKILL.md` → Cursor registration entry (required for discovery). See [REFERENCE.md](REFERENCE.md) for templates.

## Core Principles

1. **Single concise entry** — `SKILL.md` ≤ 100 lines; it navigates, not exhausts. ✓ Check: `wc -l` ≤ 100; over → move content to sub-files.
2. **One skill folder** — all formal docs under `skills/<name>/`, not scattered at repo root. ✓ Check: `ls *.md` at root shows only thin shells, not rule/workflow files.
3. **Rules ≠ Flows** — `rules/` for constraints, `workflows/` for procedures. ✓ Check: any numbered steps in `rules/`? Any "always/never" in `workflows/`? Either = mixing.
4. **Routing.yaml as source** — task routes live in `routing.yaml`; shells only say how to read it. ✓ Check: route changed without running sync/check? No → drift risk.
5. **Cursor registration entry** — `.cursor/skills/<name>/SKILL.md` must exist. ✓ Check: `ls .cursor/skills/` — missing = Cursor cannot discover the skill.
6. **Progressive Rigor** — three tiers (Single-file / Folder-light / Full); grow only under pressure — see [Progressive Rigor section above](#progressive-rigor) + [details](references/layout.md#progressive-rigor). ✓ Check: can you name the specific pressure that forced the current tier? "It felt right" ≠ pressure.
7. **Description = coarse activation** — describe the skill's domain boundary and real user trigger phrases, not every workflow keyword ([ref](references/layout.md#description-as-trigger-condition)). ✓ Check: can Common Tasks change without rewriting description? No → description is doing routing's job.
8. **Gotchas are highest-value** — maintain costly pitfalls actively; keep them discoverable. ✓ Check: is each high-cost gotcha reachable from a Common Tasks route, not only buried in `references/`?
9. **Progressive disclosure** — SKILL.md links one level deep; deep content pulled only when task-routed. ✓ Check: open SKILL.md and follow every link — does any target file link further to a third level that should have been reachable from SKILL.md directly? If yes, SKILL.md is hiding its routing structure.
10. **Task Closure Protocol** — finalization includes original-constraint check + AAR, not just "tests passed" ([ref](TEMPLATES-GUIDE.md#task-closure-protocol)); behavior change covers interaction, schema/renderer, styling, overlay/z-index, and host-compat too. ✓ Check: can you restate the user's original constraints and all AAR answers before marking done?
11. **Generalization rule** — records must make sense outside current project context ([ref](TEMPLATES-GUIDE.md#generalization-rule)). ✓ Check: replace project name with a different one — still makes sense? No → rewrite as pattern.
12. **Self-maintenance** — line counts signal evaluation, not automatic action. ✓ Check before splitting: topics independently navigable? Reader ever wants only one part? Both yes → split.
13. **Activation over storage** — pitfall in `references/` alone is not "captured"; must also be on the task path. ✓ Check: trace normal route for this scenario — Agent hits the entry without hunting? No → stored, not activated.
14. **Token efficiency** — Always-read stays 2–3 files; domain files via Common Tasks only. ✓ Check: Always Read > 3 entries? Demote lowest-frequency.
15. **Rationalizations Table** — captures verbatim excuses from real pressure-test failures ([ref](TEMPLATES-GUIDE.md#rationalizations-to-reject), [Phase 9](WORKFLOW.md#phase-9-pressure-test-the-skill)). ✓ Check: every row traces to a real failure — speculative rows dilute pressure value; remove them.
16. **Response discipline** — output short, precise, direct answers; avoid process narration, self-congratulation, gratuitous confirmations, and requirement restatement. Correct objective errors neutrally; do not infer user stance. ✓ Check: does each sentence serve the explicit request? No → delete it.

## Common Pitfalls

1. **Missing Cursor registration entry** — Formal skill at `skills/<name>/` but no `.cursor/skills/<name>/SKILL.md` → Cursor never discovers the skill; all rules/workflows silently ignored
2. **Soft-pointer-only shell** — Thin shell says only "go read SKILL.md" without a `routing.yaml` bootstrap → instruction lost after context summarization in long conversations
3. **Vague / wrong-scope description** — Description is passive, wrong-language, too narrow ("fix bug" only), or bloated with every workflow keyword → skill misses natural requests or over-fires; keep description domain-level and route tasks in SKILL.md
4. **Stored but not activated** — Costly pitfall recorded in `references/` but not surfaced in any workflow checklist or SKILL.md routing → future agents still miss it
5. **Task Closure Protocol skipped** — Agent considers itself "done" after main work, skips the 30-second AAR scan → lessons not captured; use Task Closure Protocol to make AAR a completion gate, not an optional add-on
6. **Project-specific records** — Lessons written as project narratives ("in our product module, we found…") instead of reusable knowledge → useless outside current context; apply generalization rule before recording
7. **No SessionStart hook on long sessions** — `/clear` or `/compact` silently drops SKILL.md from context; agent loses all routing and protocol awareness without the user noticing → install SessionStart hook if your harness supports it (see [references/thin-shells.md § SessionStart Hook](references/thin-shells.md#sessionstart-hook-optional))
8. **Route skipping in multi-task sessions** — Agent reads SKILL.md for the first task, then skips re-reading for subsequent tasks in the same session ("I already know the rules"). New tasks may match different routes; context may have been compressed. Result: agent works from partial/stale memory, misses critical rules, debugs in wrong direction for hours → SKILL.md template now includes Session Discipline section; all shells include re-read trigger
9. **Long-task final drift** — Agent follows the route early, then invents at the end after many tool calls or corrections → run `templates/protocol-blocks/reboot-check.md` before final validation/commit if original constraints are no longer fresh

## Content Classification

| Content type | Target |
|---|---|
| Stable constraints, must-follow rules | `rules/` |
| Step-by-step task procedures | `workflows/` |
| Architecture, pitfalls, source indexes | `references/` |
| Known gotchas, footguns, edge cases | `references/gotchas.md` (or domain-specific pitfall files) |
| Prompts, reports, external docs | `docs/` |
| Editor/tool-specific config | `.cursor/` / `.claude/` (thin shells) |

## Multi-Skill & Composition

- **Multi-skill repos** — [references/multi-skill-routing.md](references/multi-skill-routing.md) (operating) + [references/layout.md § Multi-Skill Projects](references/layout.md#multi-skill-projects) (fission).
- **Invoking other skills** from your workflows (embedded / serial chain / subagent delegation) — [references/skill-composition.md](references/skill-composition.md) + starter [templates/skill/workflows/invoke-skill.md.example](templates/skill/workflows/invoke-skill.md.example).

## Resources

- [WORKFLOW.md](WORKFLOW.md) — Migration procedure (Quick Start + 9 phases + Downstream Upgrade)
- [REFERENCE.md](REFERENCE.md) + [references/](references/) — Templates, decision guides, anti-patterns, troubleshooting, self-hosting routing source
- [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) — Starter templates + meta-workflow templates
- [EXAMPLES.md](EXAMPLES.md) + [examples/](examples/) — behavior failures + before/after scenarios
