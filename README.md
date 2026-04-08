# Skill-Based Architecture

> Restructure oversized single-file skills and scattered project rules into a clean, modular `skills/<name>/` directory.

## The Problem

| Symptom | Pain |
|---------|------|
| Single SKILL.md with 400+ lines | Agent reads everything on every task — wastes tokens, hard to maintain |
| Rules scattered across AGENTS.md, .cursor/rules/, CLAUDE.md | Duplicated, inconsistent, unclear which is authoritative |
| Rules only grow, never shrink | Docs become bloated, useful rules drowned by obsolete ones |
| Skill doesn't trigger when expected | Description written as passive summary instead of activation conditions |
| Hard-won lessons buried in docs | Costly pitfalls never surface during actual task execution |
| Agent skips after-action review | AAR treated as optional add-on, not part of task completion |
| Records too project-specific | Lessons written as project narratives instead of reusable knowledge |

## The Solution

```
skills/<name>/
├── SKILL.md          # ≤100 lines: always-read list + task routing
├── rules/            # Long-lived constraints (what is always true)
├── workflows/        # Step-by-step procedures (how to do things)
├── references/       # Background: architecture, gotchas, indexes
│   └── gotchas.md    # Known pitfalls (often the highest-value content)
└── docs/             # Optional: prompts, reports, external docs
```

### Core Principles

1. **SKILL.md is a router** — navigates, never exhausts; ≤100 lines
2. **One skill, one folder** — all formal docs under `skills/<name>/`, no scattering
3. **Rules ≠ Flows** — `rules/` for constraints, `workflows/` for procedures; never mix
4. **Thin shells with inline routing** — entry files embed routing tables that survive context summarization
5. **Description = trigger condition** — explicit activation phrases, not a passive summary
6. **Two-layer routing** — "Always Read" (2-3 files) + "Common Tasks" (task-specific reads)
7. **Task Closure Protocol** — AAR is part of task completion, not an optional extra step
8. **Recording threshold** — at least 2/3 criteria (repeatable + costly + not obvious from code) before recording
9. **Generalization rule** — records must be reusable knowledge, not project-specific narratives
10. **Activation over storage** — pitfalls must appear in the task execution path, not just in reference files
11. **Self-maintaining** — line count signals trigger evaluation; split only when topics are separable
12. **Start minimal, grow structured** — small skills use the minimal template; upgrade when rules start to sprawl

## Files

| File | Content |
|------|---------|
| [SKILL.md](SKILL.md) | Skill entry: when to use, target structure, core principles |
| [WORKFLOW.md](WORKFLOW.md) | Migration: 8 phases + quick-start scaffold script |
| [REFERENCE.md](REFERENCE.md) | Templates, activation verification, anti-patterns, troubleshooting |
| [TEMPLATES.md](TEMPLATES.md) | Starter template + workflow templates (update-rules, fix-bug, maintain-docs) |
| [EXAMPLES.md](EXAMPLES.md) | 16 before/after scenarios covering migration, evolution, activation, edge cases |
| [skill.yaml](skill.yaml) | Machine-readable metadata |

## Usage

```bash
# Install to Cursor user-level skills
bash scripts/sync-skill-to-cursor.sh

# Check if installed version matches source
bash scripts/sync-skill-to-cursor.sh --check
```

Then in any project, tell your agent:

> "Use skill-based-architecture to refactor the project rules"

## Compatibility

Works with **Cursor**, **Claude Code**, **Codex**, **Windsurf**, and **OpenClaw**.

## Version History

Current: **v1.11**

| Version | Highlights |
|---------|------------|
| v1.0 | Basic directory structure and migration workflow |
| v1.1 | Thin shell templates, anti-patterns, multi-project support |
| v1.2 | Content classification guidelines, incremental migration |
| v1.3 | Self-evolution (after-action review), self-maintenance (doc health checks), token efficiency |
| v1.4 | Two-layer routing (Always Read + Common Tasks), monorepo support |
| v1.5 | Skill auto-discovery via wildcard scanning |
| v1.6 | Enhanced update-rules / maintain-docs templates with recording thresholds |
| v1.7 | Task-closing hooks, activation over storage, fix-bug template |
| v1.8 | Description as trigger condition, gotchas as first-class content, auto-triggers, activation verification |
| v1.9 | Official minimal template alignment, minimal starter template, boundary examples |
| v1.10 | Behavior-change closure loops, UI/interaction/z-index triggers, AAR miss examples |
| v1.11 | Task Closure Protocol, generalization rule for records, thin shell template DRY, troubleshooting table |
