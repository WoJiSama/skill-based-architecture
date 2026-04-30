# Reference — Layout & Structure

## Recommended Layout

```text
project/
├── skills/
│   └── <name>/
│       ├── SKILL.md
│       ├── rules/
│       │   ├── project-rules.md
│       │   ├── coding-standards.md
│       │   └── <domain>-rules.md
│       ├── workflows/
│       │   └── <task>.md
│       ├── references/
│       │   ├── gotchas.md         # recommended: known gotchas / footguns
│       │   └── <topic>.md
│       └── docs/                  # optional: prompts, reports, external material
├── AGENTS.md                      # thin shell (universal)
├── CLAUDE.md                      # thin shell (Claude)
├── CODEX.md                       # thin shell (Codex)
├── .cursor/rules/*.mdc            # thin shells (Cursor)
├── .claude/                       # thin shells (Claude Code)
└── .codex/                        # thin shells (Codex CLI)
```

## SKILL.md Template

```md
---
name: <project-name>
description: >
  This skill should be used when the user asks to "<trigger phrase 1 in real user language>",
  "<trigger phrase 2>", or "<trigger phrase 3>".
  Activate when <condition 1> or <condition 2>.
primary: true
---

# <Project Name>

One-line summary.

## Always Read

These files apply to every task. Read them first:
1. `rules/project-rules.md`
2. `rules/coding-standards.md`

Keep this list to 2–3 files max. Domain-specific rules do NOT go here.

## Common Tasks

Each task entry lists the exact files to read — don't read files not listed for your task:

- Add feature X → read `rules/<domain>-rules.md` + follow `workflows/<task>.md`
- Add feature Y → read `rules/<domain>-rules.md` + follow `workflows/<task>.md`; ref: `references/<topic>.md`
- Fix bug → read task-relevant `rules/*.md` + follow `workflows/fix-bug.md`; ref: `references/gotchas.md`
- **Other / unlisted task** → read `rules/project-rules.md` + `rules/coding-standards.md` (Already Read above), then match by workflow filename (verb-noun convention: `add-page.md`, `fix-bug.md`, etc.). If no filename matches, proceed with just the Always Read rules.

## Known Gotchas

Brief, scannable list of the most costly pitfalls. Full details in `references/gotchas.md`.

- Gotcha 1: one-line summary → see `references/gotchas.md#section`
- Gotcha 2: one-line summary → see `references/<topic>.md#section`

## Rule Priority
1. `skills/<name>/SKILL.md`
2. `skills/<name>/rules/`
3. `skills/<name>/workflows/`
4. `skills/<name>/references/`
5. Root `README.md`
6. `.cursor/rules/*.mdc` / `.claude/` / `.codex/` (compatibility only)

## Project Boundaries
- Boundary 1
- Boundary 2
```

### Description as Trigger Condition

The `description` field in frontmatter is **not** a passive summary — it is what the Agent uses at runtime to decide whether to activate the skill. It should answer "is this request in this skill's domain?", not "which workflow should run?" A vague description means the skill silently never fires; an overstuffed description becomes a brittle keyword list that competes with `SKILL.md` routing.

**Bad** (too vague — Agent can't match it):
```yaml
description: Helps with API testing
```

**Good** (domain / intent-cluster phrases + activation conditions):
```yaml
description: >
  This skill should be used when the user asks to work on this repository, such as
  "这个接口报错了", "这里返回不对", "测试挂了", "fix this failing test",
  or "debug this error".
  Activate when the task requires this repo's code, rules, workflows,
  known gotchas, or validation commands.
```

Guidelines:
- **Enough length** — aim for ≥ 20 English-style words or ≥ 40 CJK characters; short descriptions fail to activate reliably
- **Use the user's actual language(s)** — if users ask in Chinese, include Chinese quoted phrases alongside English; do not rely on translation / semantic similarity alone
- **Include quoted trigger phrases** — exact phrases the user would say for the skill's domain / intent cluster
- **Third-person format** — "This skill should be used when…" not "I help with…"
- **Include activation conditions** — describe the context, not just the action
- **Do not enumerate workflows** — `fix-bug`, `release`, `maintain-docs`, etc. belong in Common Tasks unless they identify a separate domain skill

Run `scripts/check-description-routing.sh` after changing frontmatter; it catches obvious over-broad descriptions, workflow keyword stuffing, and duplicate trigger phrases across multiple skills.

The template above uses a two-tier structure:

- **Always Read** (2–3 core files, ~150 lines total) — read every time; in the full scaffold this list is generated from `routing.yaml`
- **Common Tasks** (task-routed) — Agent reads ONLY the files listed for the current task; in the full scaffold these rows are generated from `routing.yaml`; always include a fallback entry for unlisted tasks

**Keep routing in sync:** When you create or rename an always-read, workflow, or reference file, add or update `routing.yaml`, then run `scripts/sync-routing.sh`. The `update-rules.md` workflow includes this as a checklist item.

**Common Tasks sizing:** Keep entries to 8–10 tasks maximum. Beyond that, agents waste tokens scanning unrelated entries. If you have more than 10 recurring task types, group related tasks under domain headings (e.g., `### Backend Tasks`, `### Frontend Tasks`) or merge low-frequency tasks into the "Other" fallback.

**"Other / unlisted task" matching:** The fallback entry should tell agents how to find the right workflow without reading every file. Workflow files use a verb-noun naming convention (`add-page.md`, `fix-bug.md`, `release.md`) — agents can match by filename alone. If that's not sufficient, add a one-line directory listing in the fallback entry: `Available workflows: add-controller, add-entity, fix-bug, release`.

This keeps per-task reading to the minimum set needed, rather than loading all rules for every task.

## Relation to Official Skill Template / Spec

Anthropic's public [`skills` repository](https://github.com/anthropics/skills) defines the **minimal** skill shape: a folder with a `SKILL.md`, plus frontmatter where `name` identifies the skill and `description` explains what it does and when to use it.

This meta-skill does **not** replace that minimum. It starts one level later:

- Use the official-style minimal single `SKILL.md` when the skill is still small, self-contained, and not scattered across multiple entry files.
- Upgrade to `skills/<name>/` with `rules/`, `workflows/`, and `references/` only when the skill starts to sprawl: long files, duplicated entries, or recurring knowledge that needs active maintenance.

Rule of thumb:

- Official template answers: "How do I create a valid skill?"
- `skill-based-architecture` answers: "How do I keep a growing project skill precise, navigable, and maintainable?"

Do not copy the full official spec into project docs. Link to the canonical source when helpful, and keep local docs focused on project structure and task routing.

## Progressive Rigor

Not every skill needs the full `skills/<name>/` tree. Start at the smallest tier that fits the current scope, and upgrade only when a concrete pressure fires. This borrows from OpenSpec's "Most changes should stay in Lite mode" discipline — default to the cheapest structure that works, because over-structuring a small skill adds maintenance cost with no compression-survival benefit.

### The three tiers

| Tier | Layout | Use when | Typical SKILL.md size |
|---|---|---|---|
| **Single-file** | `SKILL.md` only (official minimum) | < 3 topics, no task routing needed, no lesson-capture history | ≤ 60 lines |
| **Folder-light** | `skills/<name>/SKILL.md` + `rules/` | 3–5 topics, OR 1 recurring workflow that needs step-by-step instructions, OR a growing list of project conventions | 60–100 lines, `rules/` adds 1–3 files |
| **Full** | `skills/<name>/{SKILL,rules,workflows,references}/` + thin shells + Cursor registration entry | ≥ 3 routed task types, gotcha log needs a home, multi-harness repo (Cursor + Claude + Codex + Gemini), or lessons-learned across multiple sessions | Close to 100 lines, multiple files per subdir |

### Upgrade triggers

Add structure when **any** of these fires, not before:

1. **Line pressure** — `SKILL.md` crosses 100 lines despite compression attempts. Move content to a sub-file in the next tier down (e.g. workflows go to `workflows/` once you have 2+).
2. **Recurrence pressure** — the same pitfall is recorded in Common Pitfalls twice, or the same question gets asked by the agent twice in different sessions. Promote it to `references/gotchas.md` with a dedicated section.
3. **Procedure pressure** — you catch yourself writing "how to do X in steps" inside a rule file. Steps belong in `workflows/`, not `rules/`. Create the `workflows/` directory.
4. **Harness-sharing pressure** — two harness entries (e.g. `AGENTS.md` and `CLAUDE.md`) need the same route lookup logic, or you're manually keeping them in sync. Move task data into `routing.yaml` and generate thin-shell blocks.
5. **Cross-session lesson pressure** — you want a lesson from today to persist into a `/clear`-fresh session next week. A single-file skill with no `references/` has no durable place for it.

**Downgrade is also fine.** If a skill lost a domain or shed complexity, collapse back. Structure serves the content, not the other way around. Empty `workflows/` or `references/` directories are a smell.

### Why this matters

Over-structuring a small skill:

- Adds 5–10 files the user must open and keep up to date
- Pushes simple "always do X" rules into `rules/` folders, then forces thin shells to point at them
- Creates false invariants (thin shells claim the skill routes tasks, when the skill has one task)

Under-structuring a growing skill:

- Grows SKILL.md past 100 lines, defeating Principle 1
- Mixes rules and workflows in one file, defeating Principle 3
- Loses routing discipline, forcing the agent to read the whole file for every task

The tier table above is the concrete decision gate. Re-evaluate on each significant skill revision, not on every edit.

## Positioning: Prompt / Context / Harness

Agent reliability lives on three layers. This skill is **not** a silver bullet — it acts on the second and a slice of the third.

| Layer | Question it answers | What this skill provides |
|---|---|---|
| **Prompt Engineering** | How do I phrase the task so the model understands? | Indirect — via the `description` frontmatter as a trigger condition, and via the writing style guidance for rules / workflows |
| **Context Engineering** | How do I deliver the right information to the model? | **Primary focus** — two-layer routing (Always Read + Common Tasks), thin shells with inline routing, registration entry, progressive disclosure |
| **Harness Engineering** | How does the surrounding system keep execution stable when the model alone is not enough? | **Partial** — Session Discipline + Rationalizations Table + SessionStart hook = a minimal harness for *context re-injection across long sessions* |

### The Four-Primitive Audit

When an agent feels unstable, the root cause is rarely the model. Ask these four questions before blaming the prompt:

1. **State** — Is there an explicit marker of what step we are on, or does the agent re-derive it each turn?
2. **Validation** — Is there a check at each critical node, or do we only verify at the end?
3. **Orchestration** — Is there a task plan with checkpoints, or does every failure restart from step 1?
4. **Recovery** — Is there a resume path after a failed step, or does the agent always re-run everything?

Three "no"s = this is a harness problem, not a model problem. Re-tuning the prompt will not help.

### What This Skill Does **Not** Cover

Treat these as orthogonal concerns — do **not** extend this meta-skill's templates beyond the narrow migration scaffolding already provided:

- **Tool-execution stability** (browser clicks that silently no-op, API calls that return half-complete responses, page DOM changing under the agent). Use a verification-focused skill (e.g. superpowers' `verification-before-completion`) or a dedicated tool-agent harness.
- **General long-chain checkpoint / resume.** This repo provides a narrow migration recovery path (`.migration-state`, per-phase smoke checks, and `templates/migration/resume.sh`) because failed migration phases otherwise pollute the generated skill tree. Broader application workflows still need project-specific state, validation, and recovery inside that project's own `rules/` or `workflows/`.
- **Multi-agent orchestration.** See superpowers' `subagent-driven-development` or equivalent. This skill only routes *within one agent's session*.

Adding state / validation / recovery primitives beyond the migration scaffold is that downstream project's own engineering work — it belongs in the project's `rules/` or `workflows/`, not in this meta-skill.

## Multi-Skill Projects

This section covers the **structural layout** of multi-skill repos. For the **operating guide** (routing, description discipline, shared resources, cross-skill refs, fission signals) see [multi-skill-routing.md](multi-skill-routing.md).

When a repo has multiple skills (e.g. `skills/app/` + `skills/template-builder/`):

```text
skills/
├── app/                    # Main application skill
│   ├── SKILL.md
│   ├── rules/
│   └── workflows/
├── template-builder/       # Standalone feature skill
│   ├── SKILL.md
│   ├── rules/
│   └── workflows/
└── shared/                 # Optional: cross-skill shared rules
    └── coding-standards.md
```

**Coexistence rules:**

1. **Independent entries** — each skill has its own `SKILL.md`, self-contained, no implicit cross-dependencies
2. **Registration + auto-discovery** — each skill must have a `.cursor/skills/<name>/SKILL.md` registration entry for Cursor discovery, plus thin shells with `routing.yaml` bootstraps for Claude/Codex. Adding a skill = dropping a folder into `skills/` + creating the registration entry + updating thin shells.
3. **Priority** — when a task clearly belongs to one skill, that skill's rules take precedence; if ambiguous, Agent reads both skills' Always Read lists
4. **Shared rules** — conventions shared across skills (e.g. coding standards) go in `skills/shared/`; each skill's SKILL.md references them in its Always Read list
5. **Don't merge** — if two skills have very different domains (e.g. "app development" vs "template building"), keeping them separate is clearer than forcing a merge

**Monorepo variant:** In a monorepo with `packages/` or `apps/`, put skills at the **workspace root** (`skills/`). A single `skills/shared/` holds cross-package conventions; each package-level skill (`skills/pkg-a/`) adds package-specific rules. Auto-discovery still works — Agent scans all `skills/*/SKILL.md` and matches by description.

**When to split one skill into two:**

A growing skill may need to fission into independent skills. Evaluate when:

1. **Domains independent?** — Subdomains (e.g. frontend vs. backend) have rules that don't affect each other
2. **Description too broad?** — Agent frequently matches the skill for tasks that only touch one subdomain
3. **Common Tasks overloaded?** — Routing table exceeds 10 entries, most tasks only use one subdomain's files

All three Yes → split into separate skills under `skills/`. Move shared rules to `skills/shared/`.

**When to rebuild a skill from scratch:**

Sometimes a skill has drifted so far that patching it costs more than starting over. Evaluate rebuild when 2+ of these are true:

1. **> 30% of rules outdated or contradictory** — rules conflict with each other or describe removed features
2. **Common Tasks routing is fictional** — 3+ routes point to workflows/files that no longer match real project work
3. **Thin shells and SKILL.md have drifted apart** — generated Always Read, Common Tasks, and shell bootstraps disagree with `routing.yaml`, or manual re-alignment keeps failing
4. **Repeated agent errors trace back to "confusing rules"** — the last 5+ agent mistakes were caused by the rules themselves being unclear, not by missing rules

Rebuild path: `cp -R templates/skill/. skills/<name>/` to get a fresh skeleton, then manually migrate only the rules and gotchas that are still valid. Do not copy-paste the old structure — re-evaluate each piece through the recording threshold before including it.
