# Examples — Index

Worked scenarios that appear elsewhere in the repo. Each example is pulled from a realistic (sometimes sanitized) situation so the lesson is concrete, not abstract.

## How to read these

Every example follows the same shape:

1. **Scenario** — what the project looked like before
2. **Problem** — what went wrong or what's hard to maintain
3. **Restructuring** — the skill-based response
4. **Outcome** — what improved, measured against the original pain

Skim the headings first; read the full body only when the scenario matches yours.

## By topic

| File | Covers | When to read |
|---|---|---|
| [migration.md](migration.md) | Patterns for converting existing docs into `skills/<name>/` — oversized SKILL.md, scattered rules, thin-shell rewrites, split/merge criteria, when **not** to split | Starting a migration, or facing a large/fragmented rule set |
| [project-types.md](project-types.md) | Canonical shapes for Java/Spring Boot, Python CLI / data, multi-skill fullstack, and the "small enough that a single SKILL.md is right" case | Starting fresh, picking a skeleton, or deciding whether the full architecture is overkill |
| [self-evolution.md](self-evolution.md) | After-Action Review, Learn-from-Mistakes, recording thresholds, activation over storage, description trigger failures, and Task Closure Protocol under pressure | Maintaining a skill over time, debugging why a rule "was written but never fired" |
| [behavior-failures.md](behavior-failures.md) | **Behavior-layer** ❌/✅ scenarios — verbatim Agent rationalizations before / after each mechanism kicks in (AAR skip, passive-summary description, same-session route skip) | Debugging a skill that looks correct on paper but still drifts in practice |

## Topic map by numbered example

Original `EXAMPLES.md` had 16 numbered examples. Here's where each landed:

| # | Title | File |
|---|---|---|
| 1 | Oversized Single SKILL.md | [migration.md](migration.md) |
| 2 | Scattered Rules → Unified Skill | [migration.md](migration.md) |
| 3 | Thin Shell Rewrite | [migration.md](migration.md) |
| 4 | Java / Spring Boot Project | [project-types.md](project-types.md) |
| 5 | Python CLI / Data Project | [project-types.md](project-types.md) |
| 6 | Multi-Skill Coexistence | [project-types.md](project-types.md) |
| 7 | Self-Evolution — After-Action Review | [self-evolution.md](self-evolution.md) |
| 8 | Learn from Mistakes | [self-evolution.md](self-evolution.md) |
| 9 | Self-Fission — Evaluated Split | [migration.md](migration.md) |
| 10 | Self-Merge — Fragment Consolidation | [migration.md](migration.md) |
| 11 | When NOT to Split | [migration.md](migration.md) |
| 12 | Bug Fix → References Update | [self-evolution.md](self-evolution.md) |
| 13 | Recorded But Not Activated | [self-evolution.md](self-evolution.md) |
| 14 | Description Trigger Phrases — Silent Activation Failure | [self-evolution.md](self-evolution.md) |
| 15 | When a Small Single SKILL.md Is Better | [project-types.md](project-types.md) |
| 16 | Rules Exist, But AAR Still Got Skipped | [self-evolution.md](self-evolution.md) |

## What these examples are **not**

- They are not templates to copy verbatim — see [`templates/`](../templates/) for that.
- They are not exhaustive — only scenarios that keep recurring made the cut.
- They are not success stories — several examples document what we **got wrong** before fixing it, and that's intentional.
