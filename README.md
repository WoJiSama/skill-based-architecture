# Skill-Based Architecture

<p align="left">
  <a href="https://github.com/WoJiSama/skill-based-architecture/stargazers">
    <img alt="GitHub stars" src="https://img.shields.io/github/stars/WoJiSama/skill-based-architecture?style=flat&logo=github">
  </a>
  <a href="LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/WoJiSama/skill-based-architecture?style=flat">
  </a>
  <img alt="Status" src="https://img.shields.io/badge/status-alpha-orange">
  <img alt="Commit activity" src="https://img.shields.io/github/commit-activity/m/WoJiSama/skill-based-architecture?style=flat">
  <a href="https://github.com/WoJiSama/skill-based-architecture/commits">
    <img alt="Last commit" src="https://img.shields.io/github/last-commit/WoJiSama/skill-based-architecture?style=flat&logo=github">
  </a>
  <img alt="Skill-Based Architecture" src="https://img.shields.io/badge/Skill--Based-Architecture-blue">
</p>

**English** | [中文](README.zh-CN.md)

> A **meta-skill for turning scattered AI-agent rules into a maintainable project skill.** It audits rule sources such as `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, README notes, and local workflow docs, then consolidates durable rules, repeatable workflows, and costly gotchas under `skills/<name>/`.

**The output is a project rule system, not another README.** `SKILL.md` routes the task; `rules/` holds stable constraints; `workflows/` holds procedures; `references/` holds architecture notes and gotchas. Tool-specific entry files stay as thin compatibility shells that point agents to the right task path without duplicating rule bodies.

```
scattered project guidance
AGENTS.md / CLAUDE.md / .cursor/rules / README notes
        │
        ▼
skill-based-architecture  (meta-skill)
        │
        ▼
skills/<project>/
├── SKILL.md          # router: Always Read + Common Tasks
├── rules/            # stable constraints
├── workflows/        # repeatable procedures
├── references/       # architecture, gotchas, indexes
└── docs/             # optional reports and prompts

tool entry files
AGENTS.md / CLAUDE.md / CODEX.md / GEMINI.md / .cursor/rules / .codex
        └── thin shells: route to skills/<project>/, no duplicated rule bodies
```

## Why This Exists

AI coding agents (Cursor, Claude Code, Codex, Windsurf, OpenCode, etc.) rely on project documentation to understand rules, conventions, and workflows. But as projects grow, that documentation inevitably becomes a mess:

| Symptom | What Actually Happens |
|---------|----------------------|
| Single SKILL.md with 400+ lines | Agent reads **everything** on every task — wastes tokens, slows responses, hard to maintain |
| Rules scattered across AGENTS.md, .cursor/rules/, CLAUDE.md | Duplicated content, contradictory rules, no single source of truth |
| Rules only grow, never shrink | Useful rules get buried by obsolete ones; agents can't distinguish what matters |
| Skill activation is unreliable | Description is a passive summary instead of explicit activation conditions |
| Hard-won lessons buried in docs | Costly pitfalls (30+ min debugging) never surface during task execution |
| Agent skips after-action review | Lessons discovered during work are lost; the same mistakes happen again |
| Records are project-specific | Lessons written as narratives instead of reusable, transferable knowledge |

**The result:** agents waste context reading irrelevant docs, miss critical rules, repeat known mistakes, and produce inconsistent output.

## What This Solves

Skill-Based Architecture provides a **structural pattern** for organizing AI agent documentation that:

1. **Minimizes token waste** — agents read 2-3 core files per task instead of everything
2. **Eliminates duplication** — one source of truth per rule, thin shells everywhere else
3. **Routes by task** — a "Common Tasks" table directs agents to exactly the files they need
4. **Captures lessons consistently** — built-in After-Action Review with recording thresholds
5. **Self-maintains** — health checks, split/merge procedures, and deprecation workflows keep docs lean
6. **Works across harnesses** — compatible with Cursor, Claude Code, Codex, Windsurf, Gemini, OpenCode, and AGENTS.md-based tools

---

## More Than a Single Skill — a Framework for Composition

The `skills/<name>/` directory this meta-skill produces is not a flat document — it is a **framework** you can keep building on. The scaffolding leaves explicit hooks for composition:

- **Write your own workflows.** `workflows/` is yours. Add `plan.md`, `review.md`, `deploy-check.md` — whatever recurring task your project actually has. Each workflow routes the agent through exactly the files it needs, with a completion checklist and escape conditions.

- **Invoke other skills from your workflows.** A workflow can delegate to another skill mid-procedure. For example, `workflows/plan.md` can instruct the agent to call [obra/superpowers](https://github.com/obra/superpowers)' planning skill during plan construction, or invoke a domain-specific testing skill inside `workflows/fix-bug.md`. Your project skill becomes an **orchestration layer**, not a dead-end.

- **Compose protocol-blocks.** `protocol-blocks/` ships as reusable building blocks — drop `rationalizations-table.md` into any workflow where discipline tends to erode; drop `ambiguous-request-gate.md` into routing where vague verbs show up; drop `reboot-check.md` into any long-running workflow where mid-task disorientation is a risk. Custom blocks follow the same pattern.

- **Evolve routing without architectural change.** A new recurring task means: append a row to `SKILL.md` Common Tasks + add a thin-shell row + write the workflow. No refactor. No migration.

- **Grow beyond the initial scaffold.** Hooks (SessionStart, PreToolUse gates), behavior defaults, new rule files, references — all propagate via `WORKFLOW.md § Upgrading`. The skill is a **living system** that co-evolves with the project.

In short: the output is not "a skill file" — it is a **project-scoped skill operating system** your agents (and you) can keep building on. New rules and workflows become reachable through the supported entry paths without copying the same rule body into every tool-specific file.

---

## Where This Fits — Prompt / Context / Harness

Agent reliability lives on three layers. This skill is **not** a silver bullet — it covers one-and-a-half of them, and being explicit about that prevents misuse.

| Layer | Solves | What this skill provides |
|---|---|---|
| **Prompt** | How to phrase the task | Indirect — via `description` as trigger condition |
| **Context** | How to deliver info to the model | **Primary focus** — routing, Always Read, thin shells, progressive disclosure |
| **Harness** | How the surrounding system keeps execution stable | **Partial** — Session Discipline + Rationalizations Table + optional SessionStart hook = a minimal harness for *context re-injection across long sessions* |

**When an agent feels unstable, the root cause is rarely the model.** Run the four-primitive audit: does the system have **state** tracking, node-level **validation**, **orchestration** with checkpoints, and **recovery** paths? Three "no"s = harness problem, not model problem. Prompt re-tuning cannot patch a missing harness.

This skill does **not** cover general tool-execution recovery, arbitrary checkpoint/resume outside its migration scaffold, or multi-agent orchestration — those are project-specific engineering that must live in each project's own `rules/` or `workflows/`, not in this meta-skill's templates. Full discussion and out-of-scope list in [references/layout.md § Positioning](references/layout.md#positioning-prompt--context--harness).

---

## Target Structure

```
skills/<name>/
├── SKILL.md          # <= 100 lines: always-read list + task routing table
├── rules/            # Long-lived constraints (what is always true)
├── workflows/        # Step-by-step procedures (how to do things)
├── references/       # Background: architecture, gotchas, indexes
│   └── gotchas.md    # Known pitfalls — often the highest-value content
└── docs/             # Optional: prompts, reports, external docs
```

Root entries (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`, `.codex/`) become **thin shells** — compatibility entry points with inline routing and pointers to the formal skill, not duplicated rule bodies.

---

## Key Features

### Two-Layer Routing

Instead of dumping all documentation on the agent, SKILL.md uses a two-layer system:

- **Always Read** (2-3 short files) — loaded for every task
- **Common Tasks** (task-routed) — agent reads ONLY the files listed for the current task

```md
## Always Read
1. `rules/project-rules.md`
2. `rules/coding-standards.md`

## Common Tasks
- Add Controller → read `rules/backend-rules.md` + follow `workflows/add-controller.md`
- Fix bug → read task-relevant `rules/*.md` + follow `workflows/fix-bug.md`
- Other → proceed with Always Read rules; check `workflows/` for closest match
```

### Thin Shells with Inline Routing

Every entry file (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.codex/instructions.md`, `.cursor/rules/*.mdc`) embeds a **routing table** — not just "go read SKILL.md". This survives context summarization in long conversations where natural-language instructions get lost.

```md
| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| Add feature | `rules/<domain>-rules.md` | `workflows/<task>.md` |
```

### Description as Trigger Condition

The `description` field is not a passive summary — it determines whether the agent activates the skill at runtime.

```yaml
# Bad — skill never fires
description: Helps with API testing

# Good — reliable activation
description: >
  This skill should be used when the user asks to "test an API endpoint",
  "write integration tests for REST APIs", "测试 API 接口", or "调试失败的 HTTP 请求".
  Activate when the task involves HTTP status codes, request/response payloads,
  or API authentication flows.
```

Write trigger phrases in the language users actually use. If your team asks in Chinese, include Chinese quoted phrases; do not rely on the agent translating English-only descriptions every time.

### Session Discipline

Every new task — even the second or third in the same session — must re-read SKILL.md, re-match the Common Tasks routing table, and re-read all files listed for that route.

> "I already read it earlier" is not valid. Context compresses silently; the new task may match a different route; partial memory is worse than no memory. Re-read costs seconds. Skipping costs hours of wrong-direction work.

This rule is enforced at three levels: SKILL.md itself, each workflow's mandatory pre-step, and the re-read trigger embedded in all thin shells (the last defense after context compression).

### Task Closure Protocol

Every non-trivial task runs a mandatory 30-second After-Action Review before completion:

1. **Main work done** — implementation verified, tests pass
2. **AAR scan** — check: new pattern? new pitfall? missing rule? outdated rule? external fact?
3. **Record if needed** — apply recording threshold (2/3: repeatable + costly + not obvious from code)

For doc/rule edits, the closure path also runs the relevant integrity gates: link checks, inbound orphan checks, cross-reference review, and `external-fact` freshness checks for volatile vendor/tool/runtime claims.

This prevents the common failure where agents "finish" tasks without capturing expensive lessons.

### Recording Threshold

Not everything gets documented. A potential lesson must meet at least 2 of 3 criteria:

| Criterion | Question |
|-----------|----------|
| **Repeatable** | Will this come up again in future tasks? |
| **Costly** | Would missing it waste 30+ minutes of debugging? |
| **Not obvious** | Can't a future reader infer it from the code alone? |

This keeps rules lean and high-value, preventing the documentation bloat that makes everything useless.

### Generalization Rule

Records must be reusable knowledge, not project-specific narratives:

| Bad (project narrative) | Good (generalized knowledge) |
|---|---|
| In the product module, pagination needs reset when switching tabs | When switching context (tabs, views, filters), reset pagination to page 1 |
| Our UserService.createUser method needs a duplicate check first | Uniqueness validation must happen before entity creation |
| admin-dashboard loads slowly because of missing pagination | List endpoints must support pagination; unpaginated queries become bottlenecks as data grows |

### Self-Maintenance

Built-in mechanisms prevent documentation from degrading over time:

- **File health checks** — size scanning with reference ranges (not hard limits)
- **Evaluated splits** — split only when topics are genuinely separable, not just because line count is high
- **Fragment consolidation** — merge tiny files that belong together
- **Rule deprecation** — explicit workflow for removing obsolete rules
- **Reference integrity** — link checking after any rename, split, or deletion
- **External fact freshness** — source-bound vendor/tool/runtime claims carry verification dates and are checked for staleness

### Activation Over Storage

A costly pitfall recorded only in `references/` is **not fully captured** — future agents may never read it. High-value lessons must also be surfaced in the task execution path:

- Add a completion check in the relevant `workflows/*.md`
- Update `SKILL.md` Common Tasks routing to point at the reference
- If the lesson is a stable constraint, promote it to `rules/`

### Behavior Activation Signals

The skill is working only if agent behavior changes, not just if files exist:

- Vague requests trigger clarification before scanning or editing
- Diffs stay surgical, with no drive-by formatting, renames, or refactors
- Solutions stay simple until real pressure justifies structure
- Completion cites concrete checks, not "looks good" or "should work"

If these signals do not appear across real tasks, do not add more rule text. Record the miss as a behavior failure and put the fix on the relevant task path.

### Checkpoint-Based Migration Recovery

A 9-phase migration can crash mid-flight — `/compact` fires, the shell exits during `sed`, a laptop reboots. Restarting from Phase 1 is tempting but **amplifies pollution**: a half-completed Phase 5 leaves `{{NAME}}` stubs that a Phase 3 rerun cannot see, and a subsequent Phase 8 passes on a broken tree.

The recovery primitives (see [WORKFLOW.md § Resuming From a Failed Phase](WORKFLOW.md#resuming-from-a-failed-phase)):

- **`.migration-state`** — single-line checkpoint file (`phase=N`), written after each phase passes its per-phase validator
- **Per-phase validation** — `bash smoke-test.sh <name> --phase N` runs only the subset of checks relevant to phase N, so mid-flight validation is meaningful (not just the all-or-nothing final sweep)
- **`templates/migration/resume.sh`** — one command that detects the current phase (via checkpoint file or artifact signatures), warns on placeholder residue, and prints the next action

Together these close the "state / validation / recovery" gap called out in [references/layout.md § Positioning — Prompt / Context / Harness](references/layout.md#positioning-prompt--context--harness).

---

## When NOT to Use This

Not every project needs this architecture. Skip it if:

- **Short-lived solo project (< 2 weeks)** — no recurring tasks, no rules worth capturing
- **Total rule content < 50 lines** — a single `CLAUDE.md`, `AGENTS.md`, or `.cursor/rules/workflow.mdc` file is enough
- **Single harness only** — you only use one AI tool and don't need cross-tool compatibility
- **No team sharing** — you're the only person using AI agents on this codebase, and it's small enough to keep in your head

In these cases, start with a plain `CLAUDE.md` or `.cursor/rules/workflow.mdc`. You can always migrate to the full architecture later when the project grows — [WORKFLOW.md](WORKFLOW.md) has a Quick Start path for exactly that upgrade.

---

## Quick Start

### Step 1 — Clone It Locally

Pick the location your agent can read. The flow is the same in every case: first make this meta-skill available locally, then trigger it from the target project.

| Use case | Clone target |
|---|---|
| Cursor user-level skill | `~/.cursor/skills/skill-based-architecture` |
| Cursor project-level skill | `.cursor/skills/skill-based-architecture` |
| Claude Code / Codex / Gemini / Windsurf / AGENTS.md-based agents | `skills/skill-based-architecture` inside the target project, or `../skill-based-architecture` next to it |

```bash
# Cursor user-level install
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  ~/.cursor/skills/skill-based-architecture

# Cursor project-level install
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  .cursor/skills/skill-based-architecture

# Generic project-local install
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  skills/skill-based-architecture
```

If your agent does not discover skills automatically, add a short pointer in `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, or the equivalent entry file:

```md
For rule restructuring tasks, use the skill at `skills/skill-based-architecture/`.
Read `skills/skill-based-architecture/SKILL.md` first.
```

If you cloned the repo next to the target project instead, replace the path with `../skill-based-architecture/SKILL.md`.

### Step 2 — Trigger It From the Target Project

In the target project, ask the agent to use the local meta-skill:

> "Use skill-based-architecture to refactor the project rules"

Equivalent trigger phrases also work:

- "Organize the project rules"
- "Refactor the project rules into a skill-based architecture"
- "Clean up scattered documentation"
- "Consolidate rules into a skills directory"
- "Migrate rules to skills/"

### Scaffold a New Project

After activation, the agent scaffolds from the pre-built [`templates/`](templates/) tree — **copy, don't regenerate**. See `WORKFLOW.md` Quick Start for the full command, but in essence:

```bash
UPSTREAM="${UPSTREAM:-../skill-based-architecture}"
NAME="my-project"
SUMMARY="one-line project summary"
mkdir -p "skills/$NAME"
cp -R "$UPSTREAM/templates/skill/." "skills/$NAME/"
cp -R "$UPSTREAM/templates/shells/." .
mv ".cursor/skills/{{NAME}}" ".cursor/skills/$NAME"
find "skills/$NAME" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .codex .cursor \
  -type f \( -name '*.md' -o -name '*.mdc' \) \
  -exec sed -i '' -e "s/{{NAME}}/$NAME/g" -e "s/{{SUMMARY}}/$SUMMARY/g" {} +
```

Then fill every `<!-- FILL: -->` marker (list them with `grep -rn 'FILL:' skills/$NAME`). Each FILL is mandatory — leaving them unresolved causes silent skill-activation failures.

Before filling project-specific content, the agent should ask whether you want to brainstorm the target project's purpose, modules, common tasks, boundaries, and known pitfalls. If you agree, it must brainstorm first, restate the calibrated summary for your correction, then verify the feedback against local code/config before writing `rules/`, `workflows/`, `references/`, or `SKILL.md`. User feedback calibrates the analysis; confirmed local evidence decides what becomes a rule or workflow.

### Pre-built Templates

The [`templates/`](templates/) directory is the single source of truth for scaffold content:

- `templates/skill/` → becomes `skills/<name>/` (SKILL.md, rules stubs, workflow bodies, empty gotchas seed)
- `templates/skill/scripts/` → `smoke-test.sh`, `test-trigger.sh`, `check-cross-references.sh`, `check-external-facts.sh`, and `audit-references.sh` — auto-copied into `skills/<name>/scripts/` by the scaffold step
- `templates/shells/` → thin shells for every harness (AGENTS, CLAUDE, CODEX, GEMINI, `.codex/`, `.cursor/`)
- `templates/hooks/` → optional `SessionStart` hook that re-injects one router on `/clear` and `/compact`
- `templates/protocol-blocks/` → drop-in Task Closure Protocol reinforcement (Rationalizations table, Red Flags, Iron Law header)

Copy these instead of asking the agent to regenerate files inline — inline generation drops sections under pressure. See [`templates/README.md`](templates/README.md) for byte budgets and the "would two real projects disagree?" admission test, and [`templates/ANTI-TEMPLATES.md`](templates/ANTI-TEMPLATES.md) for content we intentionally do **not** pre-build.

---

## What Happens After You Trigger It

The README only shows the operating shape. The detailed migration checklist lives in [WORKFLOW.md](WORKFLOW.md).

1. **Audit current guidance** — find rule sources such as `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, README notes, and existing docs.
2. **Create the project skill** — copy the scaffold into `skills/<name>/`, then fill `SKILL.md`, `rules/`, `workflows/`, and `references/` with project-specific evidence.
3. **Wire entry files** — create thin shells for the tools you use, keeping rule bodies in `skills/<name>/`.
4. **Validate** — run the copied scripts for structure, routing, placeholders, links, orphaned references, and external-fact freshness.

Use the full [WORKFLOW.md](WORKFLOW.md) when you are actually performing a migration; keep the README as the short orientation page.

---

## Content Classification

| Content Type | Where It Goes | Examples |
|---|---|---|
| Stable constraints, must-follow rules | `rules/` | Naming conventions, module boundaries, dependency strategy |
| Step-by-step procedures | `workflows/` | add-controller, fix-bug, release, update-rules |
| Architecture, pitfalls, indexes | `references/` | System design, gotchas, route tables, third-party notes |
| Edge cases, footguns, costly bugs | `references/gotchas.md` | Lifecycle pitfalls, timing dependencies, framework quirks |
| Prompts, reports, external material | `docs/` | Templates, generated reports |
| Editor/tool config | `.cursor/`, `.claude/`, `.codex/` | Thin shells, hooks, or registration stubs only — no rule content |

---

## Tool Compatibility

<!-- external-fact: verified=2026-04-28 source=https://docs.cursor.com/en/context -->
<!-- external-fact: verified=2026-04-28 source=https://code.claude.com/docs/en/skills -->
<!-- external-fact: verified=2026-04-28 source=https://developers.openai.com/codex/guides/agents-md -->
<!-- external-fact: verified=2026-04-28 source=https://docs.windsurf.com/windsurf/cascade/memories -->
<!-- external-fact: verified=2026-04-28 source=https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md -->
<!-- external-fact: verified=2026-04-28 source=https://opencode.ai/docs/rules/ -->

| Tool | Discovery Mechanism | Required Entry | Inline Routing? |
|---|---|---|---|
| **Cursor** | Uses project skill registration under `.cursor/skills/` for this scaffold | `.cursor/skills/<name>/SKILL.md` | Yes |
| **Cursor rules** | `.cursor/rules/*.mdc` | `.cursor/rules/workflow.mdc` | Yes |
| **Claude Code** | Reads root `CLAUDE.md`; native skills scan `.claude/skills/` with enterprise > personal > project same-name precedence | `CLAUDE.md`; optional `.claude/skills/<project-name>/SKILL.md` stub | Yes |
| **Codex CLI** | Reads the `AGENTS.md` hierarchy; `AGENTS.override.md` can override project guidance | `AGENTS.md`; keep `CODEX.md` / `.codex/instructions.md` only as compatibility mirrors if your harness reads them | Yes |
| **Windsurf** | Reads workspace memories/rules such as `.windsurf/rules/`; can also infer memories from `AGENTS.md` | `.windsurf/rules/*.md` or shared `AGENTS.md` shell | Yes |
| **Gemini CLI** | Reads `GEMINI.md` at repo root (+ parent/child dirs) | `GEMINI.md` | Yes |
| **OpenCode** | Reads `AGENTS.md` | `AGENTS.md` shared shell | Yes |
| **Other agents** | Reads `AGENTS.md` | `AGENTS.md` | Yes |

All entry files **must** contain inline routing tables — natural-language-only instructions get lost during context summarization.

For Claude Code native skills, avoid generic project skill names that may collide with `~/.claude/skills/`: a personal skill with the same name overrides the project native skill. The project `skills/<name>/` directory remains the source of truth through `CLAUDE.md` and optional SessionStart routing.

---

## Recording Destination Guide

When the user asks to "record this" or "remember this", the agent must decide where to store it. Many AI tools have their own memory systems (e.g., Claude's `~/.claude/projects/.../memory/`) that auto-load each session — these compete with the skill's documentation structure.

**Decision test:** "Would a different agent or person on this project benefit from this?"

| Answer | Destination | Examples |
|---|---|---|
| **Yes** | `skills/<name>/references/`, `rules/`, or `workflows/` | Technical patterns, conventions, pitfalls |
| **No** | Agent's own memory system | Personal preferences, communication style |

**Default to skill docs.** Most "record this" requests during development are technical and project-scoped.

---

## Project Type Examples

### Java / Spring Boot

```
skills/<name>/
├── SKILL.md
├── rules/
│   ├── project-rules.md          # Module boundaries, dep strategy
│   ├── coding-standards.md       # Naming, DI style, comment rules
│   ├── backend-rules.md          # Controller/Service/Mapper conventions
│   └── frontend-rules.md         # Template engine, static resources
├── workflows/
│   ├── add-controller.md
│   ├── add-entity-and-mapper.md
│   ├── fix-bug.md
│   ├── update-rules.md           # Required meta-workflow
│   └── maintain-docs.md          # Required meta-workflow
└── references/
    ├── architecture.md
    ├── routes-and-modules.md
    └── third-party-libs.md
```

### Frontend / React / Next.js

```
skills/<name>/
├── SKILL.md
├── rules/
│   ├── project-rules.md
│   ├── frontend-rules.md
│   └── component-rules.md
├── workflows/
│   ├── add-page.md
│   ├── add-component.md
│   ├── fix-bug.md
│   ├── update-rules.md
│   └── maintain-docs.md
└── references/
    └── frontend-pitfalls.md
```

### Python CLI / Data

```
skills/<name>/
├── SKILL.md
├── rules/
│   ├── project-rules.md
│   └── cli-conventions.md
├── workflows/
│   ├── add-command.md
│   ├── release.md
│   ├── update-rules.md
│   └── maintain-docs.md
└── references/
    ├── api-index.md
    └── testing-notes.md
```

### Multi-Skill Projects

```
skills/
├── app/                    # Main application skill
│   ├── SKILL.md
│   ├── rules/
│   └── workflows/
├── template-builder/       # Standalone feature skill
│   ├── SKILL.md
│   ├── rules/
│   └── workflows/
└── shared/                 # Cross-skill shared rules
    └── coding-standards.md
```

---

## Core Principles

| # | Principle | What It Means |
|---|-----------|--------------|
| 1 | **SKILL.md is a router** | Navigates to the right files, never exhausts; <= 100 lines |
| 2 | **One skill, one folder** | All formal docs under `skills/<name>/`, no scattering |
| 3 | **Rules != Flows** | `rules/` for constraints, `workflows/` for procedures — never mix |
| 4 | **Thin shells with inline routing** | Entry files embed routing tables that survive context summarization |
| 5 | **Description = trigger condition** | Explicit activation phrases in users' real language(s), not passive summaries |
| 6 | **Two-layer routing** | Always Read (2-3 files) + Common Tasks (task-specific reads) |
| 7 | **Session Discipline** | Every new task in the same session must re-read SKILL.md and re-match routing; "I already read it" is not valid |
| 8 | **Task Closure Protocol** | AAR is part of task completion, not an optional extra |
| 9 | **Recording threshold** | 2/3 criteria (repeatable + costly + not obvious) before recording |
| 10 | **Generalization rule** | Records must be reusable knowledge, not project-specific narratives |
| 11 | **Activation over storage** | Pitfalls must appear in the task path, not just in reference files |
| 12 | **Self-maintaining** | Line counts trigger evaluation; link/orphan/cross-reference/external-fact gates prevent rot |
| 13 | **Start minimal, grow structured** | Use the minimal template first; upgrade when rules sprawl |

---

## Files in This Repo

| File | Content |
|------|---------|
| [SKILL.md](SKILL.md) | Skill entry: when to use, target structure, core principles, common pitfalls |
| [WORKFLOW.md](WORKFLOW.md) | Migration guide: decision tree, quick-start scaffold, full 9-phase process, downstream upgrade |
| [REFERENCE.md](REFERENCE.md) | Stub + index — redirects to [`references/`](references/) |
| [references/](references/) | Layout, thin shells, protocols, conventions, multi-skill routing, skill composition, and self-hosting routing |
| [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) | Annotated guide for template families and Task Closure Protocol |
| [templates/](templates/) | Byte-for-byte scaffold files copied into downstream projects |
| [EXAMPLES.md](EXAMPLES.md) | Stub + index — redirects to [`examples/`](examples/) |
| [examples/](examples/) | Migration, project-type, self-evolution, and behavior-failure examples |
| [skill.yaml](skill.yaml) | Machine-readable metadata for tool discovery |

---

## Common Pitfalls

These are the most costly mistakes when using this architecture. Each has caused real failures:

| Pitfall | Impact | Fix |
|---------|--------|-----|
| **Missing Cursor registration entry** | Cursor never discovers the skill; all rules silently ignored | Create `.cursor/skills/<name>/SKILL.md` |
| **Soft-pointer-only shell** | Instruction lost after context summarization | Embed inline routing table in every entry file |
| **Vague / wrong-language description** | Skill exists but agent never activates it | Write enough detail with >= 2 quoted phrases in users' real language(s) |
| **Stored but not activated** | Pitfall in `references/` but not in any workflow | Also surface in workflow checklist or SKILL.md routing |
| **Task Closure skipped** | Lessons not captured; same mistakes repeat | Use Task Closure Protocol as completion gate |
| **Route skipping in multi-task sessions** | Agent reads SKILL.md for task 1, skips re-reading for task 2 ("I already know the rules"), works from partial/stale memory for hours | Session Discipline rule in SKILL.md + re-read trigger in all thin shells |
| **Project-specific records** | Useless outside current context | Apply generalization rule before recording |

---

## Anti-Patterns

| Anti-Pattern | Why It Hurts | Fix |
|---|---|---|
| Rule bodies inside thin shells | Two places to update; defeats single source of truth | Keep shells to routing, always-read pointers, and compatibility notes |
| SKILL.md as second README | Redundant context; exceeds 100 lines | Keep setup in README; SKILL.md only navigates |
| Rules and workflows mixed | Hard to find checklists; hard to update constraints | Constraints in `rules/`, procedures in `workflows/` |
| Mega sub-file (500+ lines) | Same problem as oversized SKILL.md, one level down | Split by subdomain |
| Over-splitting (20 files, 10 lines each) | Navigation overhead exceeds benefit | Merge related files; aim for 50-200 lines |
| Record everything | Rules bloat with low-value noise | Apply recording threshold: 2/3 criteria |

---

## FAQ

**Q: Does this replace the official Anthropic skill template?**
No. The official template defines the *minimal* skill shape (a folder with SKILL.md + frontmatter). This meta-skill starts one level later — it adds structure when a single small SKILL.md is no longer enough.

**Q: When should I NOT use this?**
- Very small projects (fewer than 3 rule/doc files)
- Temporary repos with no long-term maintenance needs
- Teams with a well-functioning documentation system who don't want to migrate

**Q: Can I migrate incrementally?**
Yes. Round 1: create `skills/<name>/` and extract rules. Round 2: extract workflows. Round 3: extract references and create thin shells. Each round leaves the project in a working state.

**Q: What if my SKILL.md is still small?**
Keep it as a single file using the minimal starter template. Upgrade only when content starts to sprawl, duplicate, or accumulate non-obvious lessons.

**Q: How do I prevent documentation bloat?**
The recording threshold (2/3: repeatable + costly + not obvious) filters out low-value records. The deprecation workflow in `update-rules.md` removes obsolete rules. `maintain-docs.md`, reference audits, cross-reference checks, and `check-external-facts.sh` catch oversized files, orphaned references, stale links, and stale external claims.

---

## Community support

Learn AI on LinuxDO — [LinuxDO](https://linux.do/)

---

## Star History

<a href="https://www.star-history.com/?repos=WoJiSama%2Fskill-based-architecture&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&legend=top-left" />
 </picture>
</a>
