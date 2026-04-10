---
name: skill-based-architecture
version: "1.11"
description: >
  This skill should be used when the user asks to "organize the project rules",
  "clean up scattered documentation", "refactor project rules",
  "consolidate scattered rules", "create skill-based architecture",
  "restructure skill documentation", or "migrate rules to skills directory".
  Activate when a SKILL.md exceeds ~150 lines, rules are duplicated across
  multiple entry files (AGENTS.md, .cursor/rules/, CLAUDE.md, etc.),
  documentation feels hard to navigate or maintain, or the user requests
  rule consolidation or documentation cleanup.
---

# Skill-Based Architecture

Restructure oversized single-file Skills or scattered project rules into a well-organized Skill directory.

This skill builds on the official minimal Agent Skill contract (`name` + `description`) and becomes useful when a single small `SKILL.md` is no longer enough.

## When to Use

- A single SKILL.md exceeds ~150 lines, mixing rules, workflows, and background material
- Project rules are scattered across `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `.cursor/rules/`, `.claude/`, `.codex/`, etc.
- User explicitly requests Skill-based architecture or rule consolidation

## When NOT to Use

- Very small projects (fewer than 3 rule/doc files)
- Temporary repos with no long-term maintenance needs
- Teams with a well-functioning documentation system who don't want to migrate

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

Root entries (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`, `.codex/`) → thin shells with inline routing tables.
`.cursor/skills/<name>/SKILL.md` → Cursor registration entry (required for discovery). See [REFERENCE.md](REFERENCE.md) for templates.

## Core Principles

1. **Single concise entry** — `SKILL.md` ≤ 100 lines; it navigates, not exhausts
2. **One skill folder** — all formal docs under `skills/<name>/`, not scattered at repo root
3. **Rules ≠ Flows** — `rules/` for constraints, `workflows/` for procedures; never mix
4. **Thin shells with inline routing** — `.cursor/`, `.claude/`, `.codex/`, `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md` only route to the skill, **but must embed an inline routing table** (task → required reads → workflow), not just "go read SKILL.md"
5. **Cursor registration entry** — when the formal skill lives at `skills/<name>/`, a registration entry **must** be created at `.cursor/skills/<name>/SKILL.md` (Cursor's agent_skill discovery only scans `.cursor/skills/`)
6. **Official minimum, local structure** — keep the official minimum contract clear: `name` identifies the skill, `description` explains what it does and when to use it; this skill adds project-scale structure only when that minimum shape stops being enough
7. **Description = trigger condition** — the `description` field in frontmatter is how the Agent decides whether to activate a skill; write it as a trigger condition with explicit quoted phrases, not a passive summary (see [REFERENCE.md § Description as Trigger Condition](REFERENCE.md#description-as-trigger-condition))
8. **Gotchas are the highest-value content** — edge cases, footguns, and costly pitfalls that are not obvious from code; maintain them actively and keep them easily discoverable (in `references/gotchas.md` or a Known Gotchas section in SKILL.md)
9. **Progressive disclosure** — SKILL.md links to one-level-deep support files
10. **Task Closure Protocol** — AAR is part of task completion, not an optional extra; every non-trivial task must run a 30-second scan before declaring done (see [TEMPLATES.md § Task Closure Protocol](TEMPLATES.md#task-closure-protocol))
11. **Generalization rule** — records must be reusable knowledge that makes sense outside the current project context, not project-specific narratives; apply the generalization check before writing (see [TEMPLATES.md § Generalization Rule](TEMPLATES.md#generalization-rule))
12. **Self-maintenance** — line counts signal evaluation, not automatic action; split only when topics are separable, merge only when fragments belong together
13. **Activation over storage** — a costly, task-relevant pitfall is not considered "captured" if it only lives deep in `references/`; it must also surface in the task path that should prevent the mistake next time (workflow checklist, task routing, or a concise rule summary)
14. **Token efficiency** — Always-read files stay minimal (2–3 core rules); domain files are read only when task-routed via Common Tasks
15. **Protocol reinforcement via Rationalizations Table** — the Task Closure Protocol is vulnerable to "just this once" erosion under pressure; maintain a Rationalizations to Reject table capturing verbatim excuses from pressure-test failures and their rebuttals (see [TEMPLATES.md § Rationalizations to Reject](TEMPLATES.md#rationalizations-to-reject) and [WORKFLOW.md § Phase 9](WORKFLOW.md#phase-9-pressure-test-the-skill))

**What counts as a behavior change?** Not only business logic or data flow changes. It also includes interaction changes, schema / renderer behavior changes, styling conventions that change outcomes, overlay / layering / z-index behavior, and host-compatibility changes that future agents could still misjudge without guidance.

## Common Pitfalls

These are the most costly mistakes when using this architecture. Each has caused real failures:

1. **Missing Cursor registration entry** — Formal skill at `skills/<name>/` but no `.cursor/skills/<name>/SKILL.md` → Cursor never discovers the skill; all rules/workflows silently ignored
2. **Soft-pointer-only shell** — Thin shell says "go read SKILL.md" without an inline routing table → instruction lost after context summarization in long conversations
3. **Vague description** — Description written as passive summary instead of trigger conditions with quoted phrases → skill exists but Agent never activates it (see [REFERENCE.md § Description as Trigger Condition](REFERENCE.md#description-as-trigger-condition))
4. **Stored but not activated** — Costly pitfall recorded in `references/` but not surfaced in any workflow checklist or SKILL.md routing → future agents still miss it
5. **Task Closure Protocol skipped** — Agent considers itself "done" after main work, skips the 30-second AAR scan → lessons not captured; use Task Closure Protocol to make AAR a completion gate, not an optional add-on
6. **Project-specific records** — Lessons written as project narratives ("in our product module, we found…") instead of reusable knowledge → useless outside current context; apply generalization rule before recording
7. **No SessionStart hook on long sessions** — `/clear` or `/compact` silently drops SKILL.md from context; agent loses all routing and protocol awareness without the user noticing → install SessionStart hook if your harness supports it (see [REFERENCE.md § SessionStart Hook](REFERENCE.md#sessionstart-hook-optional))

## Content Classification

| Content type | Target |
|---|---|
| Stable constraints, must-follow rules | `rules/` |
| Step-by-step task procedures | `workflows/` |
| Architecture, pitfalls, source indexes | `references/` |
| Known gotchas, footguns, edge cases | `references/gotchas.md` (or domain-specific pitfall files) |
| Prompts, reports, external docs | `docs/` |
| Editor/tool-specific config | `.cursor/` / `.claude/` (thin shells) |

## Multi-Skill Projects & Skill Fission

For repos with multiple skills, coexistence rules, monorepo guidance, and when-to-split criteria, see [REFERENCE.md § Multi-Skill Projects](REFERENCE.md#multi-skill-projects).

## Resources

- [WORKFLOW.md](WORKFLOW.md) — Migration procedure (Quick Start + 9 phases)
- [REFERENCE.md](REFERENCE.md) — Templates, decision guides, anti-patterns, troubleshooting
- [TEMPLATES.md](TEMPLATES.md) — Starter templates + meta-workflow templates
- [EXAMPLES.md](EXAMPLES.md) — 16 before/after scenarios
