# Skill-Based Architecture

**English** | [中文](README.zh-CN.md)

> A **meta-skill that produces skills.** Point it at any codebase and it distills the project's rules, workflows, and hard-won lessons into a dedicated `skills/<name>/` directory — a **project skill** that becomes the single source of truth every AI agent (Cursor, Claude Code, Codex, Windsurf, Gemini) consults before every task.

**The output is the point.** What you get is not just a tidier docs folder — it is *the skill that understands your project best*: routable, self-maintaining, lesson-capturing, and triggered automatically when the task matches.

```
your project  ──►  skill-based-architecture  ──►  skills/<your-project>/   ◄── the skill that knows your project best
                       (meta-skill)                ├── SKILL.md  (router, ≤100 lines)
                                                   ├── rules/    (what is always true)
                                                   ├── workflows/(how to do things)
                                                   └── references/gotchas.md  (costly lessons)
```

---

## Community support

Learn AI on LinuxDO — [LinuxDO](https://linux.do/)

---

## Why This Exists

AI coding agents (Cursor, Claude Code, Codex, Windsurf, etc.) rely on project documentation to understand rules, conventions, and workflows. But as projects grow, that documentation inevitably becomes a mess:

| Symptom | What Actually Happens |
|---------|----------------------|
| Single SKILL.md with 400+ lines | Agent reads **everything** on every task — wastes tokens, slows responses, hard to maintain |
| Rules scattered across AGENTS.md, .cursor/rules/, CLAUDE.md | Duplicated content, contradictory rules, no single source of truth |
| Rules only grow, never shrink | Useful rules get buried by obsolete ones; agents can't distinguish what matters |
| Skill never triggers automatically | Description is a passive summary instead of explicit activation conditions |
| Hard-won lessons buried in docs | Costly pitfalls (30+ min debugging) never surface during task execution |
| Agent skips after-action review | Lessons discovered during work are lost; the same mistakes happen again |
| Records are project-specific | Lessons written as narratives instead of reusable, transferable knowledge |

**The result:** agents waste context reading irrelevant docs, miss critical rules, repeat known mistakes, and produce inconsistent output.

## What This Solves

Skill-Based Architecture provides a **structural pattern** for organizing AI agent documentation that:

1. **Minimizes token waste** — agents read 2-3 core files per task instead of everything
2. **Eliminates duplication** — one source of truth per rule, thin shells everywhere else
3. **Routes by task** — a "Common Tasks" table directs agents to exactly the files they need
4. **Captures lessons automatically** — built-in After-Action Review with recording thresholds
5. **Self-maintains** — health checks, split/merge procedures, and deprecation workflows keep docs lean
6. **Works everywhere** — compatible with Cursor, Claude Code, Codex, Windsurf, and OpenClaw

---

## More Than a Single Skill — a Framework for Composition

The `skills/<name>/` directory this meta-skill produces is not a flat document — it is a **framework** you can keep building on. The scaffolding leaves explicit hooks for composition:

- **Write your own workflows.** `workflows/` is yours. Add `plan.md`, `review.md`, `deploy-check.md` — whatever recurring task your project actually has. Each workflow routes the agent through exactly the files it needs, with a completion checklist and escape conditions.

- **Invoke other skills from your workflows.** A workflow can delegate to another skill mid-procedure. For example, `workflows/plan.md` can instruct the agent to call [obra/superpowers](https://github.com/obra/superpowers)' planning skill during plan construction, or invoke a domain-specific testing skill inside `workflows/fix-bug.md`. Your project skill becomes an **orchestration layer**, not a dead-end.

- **Compose protocol-blocks.** `protocol-blocks/` ships as reusable building blocks — drop `rationalizations-table.md` into any workflow where discipline tends to erode; drop `ambiguous-request-gate.md` into routing where vague verbs show up; drop `reboot-check.md` into any long-running workflow where mid-task disorientation is a risk. Custom blocks follow the same pattern.

- **Evolve routing without architectural change.** A new recurring task means: append a row to `SKILL.md` Common Tasks + add a thin-shell row + write the workflow. No refactor. No migration.

- **Grow beyond the initial scaffold.** Hooks (SessionStart, PreToolUse gates), behavior defaults, new rule files, references — all propagate via `WORKFLOW.md § Upgrading`. The skill is a **living system** that co-evolves with the project.

In short: the output is not "a skill file" — it is a **project-scoped skill operating system** your agents (and you) can keep building on. Everything you layer in becomes available to every agent on every task, without context waste.

---

## Where This Fits — Prompt / Context / Harness

Agent reliability lives on three layers. This skill is **not** a silver bullet — it covers one-and-a-half of them, and being explicit about that prevents misuse.

| Layer | Solves | What this skill provides |
|---|---|---|
| **Prompt** | How to phrase the task | Indirect — via `description` as trigger condition |
| **Context** | How to deliver info to the model | **Primary focus** — routing, Always Read, thin shells, progressive disclosure |
| **Harness** | How the surrounding system keeps execution stable | **Partial** — Session Discipline + Rationalizations Table + optional SessionStart hook = a minimal harness for *context re-injection across long sessions* |

**When an agent feels unstable, the root cause is rarely the model.** Run the four-primitive audit: does the system have **state** tracking, node-level **validation**, **orchestration** with checkpoints, and **recovery** paths? Three "no"s = harness problem, not model problem. Prompt re-tuning cannot patch a missing harness.

This skill does **not** cover tool-execution recovery, long-chain checkpoint/resume, or multi-agent orchestration — those are project-specific engineering that must live in each project's own `rules/` or `workflows/`, not in this meta-skill's templates. Full discussion and out-of-scope list in [references/layout.md § Positioning](references/layout.md#positioning-prompt--context--harness).

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

Root entries (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `.cursor/rules/*.mdc`, `.codex/`) become **thin shells** — under 15 lines each, containing only a routing table and a pointer to the formal skill.

---

## Key Features

### Two-Layer Routing

Instead of dumping all documentation on the agent, SKILL.md uses a two-layer system:

- **Always Read** (2-3 files, ~150 lines) — loaded for every task
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

Every entry file (AGENTS.md, CLAUDE.md, .cursor/rules/*.mdc) embeds a **routing table** — not just "go read SKILL.md". This survives context summarization in long conversations where natural-language instructions get lost.

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
  "write integration tests for REST APIs", or "debug a failing HTTP request".
  Activate when the task involves HTTP status codes, request/response payloads,
  or API authentication flows.
```

### Session Discipline

Every new task — even the second or third in the same session — must re-read SKILL.md, re-match the Common Tasks routing table, and re-read all files listed for that route.

> "I already read it earlier" is not valid. Context compresses silently; the new task may match a different route; partial memory is worse than no memory. Re-read costs seconds. Skipping costs hours of wrong-direction work.

This rule is enforced at three levels: SKILL.md itself, each workflow's mandatory pre-step, and the re-read trigger embedded in all thin shells (the last defense after context compression).

### Task Closure Protocol

Every non-trivial task runs a mandatory 30-second After-Action Review before completion:

1. **Main work done** — implementation verified, tests pass
2. **AAR scan** — 4 questions: new pattern? new pitfall? missing rule? outdated rule?
3. **Record if needed** — apply recording threshold (2/3: repeatable + costly + not obvious from code)

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

### Activation Over Storage

A costly pitfall recorded only in `references/` is **not fully captured** — future agents may never read it. High-value lessons must also be surfaced in the task execution path:

- Add a completion check in the relevant `workflows/*.md`
- Update `SKILL.md` Common Tasks routing to point at the reference
- If the lesson is a stable constraint, promote it to `rules/`

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
- **Total rule content < 50 lines** — a single `CLAUDE.md` or `.cursorrules` file is enough
- **Single harness only** — you only use one AI tool and don't need cross-tool compatibility
- **No team sharing** — you're the only person using AI agents on this codebase, and it's small enough to keep in your head

In these cases, start with a plain `CLAUDE.md` or `.cursor/rules/workflow.mdc`. You can always migrate to the full architecture later when the project grows — [WORKFLOW.md](WORKFLOW.md) has a Quick Start path for exactly that upgrade.

---

## Quick Start

### Option 0 — Claude Code one-line install (recommended)

```bash
/plugin marketplace add WoJiSama/skill-based-architecture
/plugin install skill-based-architecture@skill-based-architecture
```

The repository ships `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` so Claude Code can discover and install it in a single command. After install, activate in any project by saying "Use skill-based-architecture to refactor the project rules".

### Option 1 — Install as a Cursor user-level skill

Clone into your Cursor skills directory so the skill is available in every project:

```bash
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  ~/.cursor/skills/skill-based-architecture
```

Then in any project:

> "Use skill-based-architecture to refactor the project rules"

### Option 2 — Install as a project-level skill

```bash
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  .cursor/skills/skill-based-architecture
```

### Option 3 — Use with Codex / Gemini / Windsurf

Copy the files into any location your agent reads from, then reference the skill in your `CLAUDE.md`, `AGENTS.md`, or equivalent entry file:

```md
For rule restructuring tasks, use the skill at `skills/skill-based-architecture/`.
Read `skills/skill-based-architecture/SKILL.md` first.
```

### Trigger Phrases

Once installed, activate with any of these:

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
- `templates/skill/scripts/` → `smoke-test.sh` (roughly 50-check automated verifier) + `test-trigger.sh` (description trigger rate tester) — auto-copied into `skills/<name>/scripts/` by the scaffold step
- `templates/shells/` → thin shells for every harness (AGENTS, CLAUDE, CODEX, GEMINI, `.codex/`, `.cursor/`)
- `templates/hooks/` → optional `SessionStart` hook that re-injects one router on `/clear` and `/compact`
- `templates/protocol-blocks/` → drop-in Task Closure Protocol reinforcement (Rationalizations table, Red Flags, Iron Law header)

Copy these instead of asking the agent to regenerate files inline — inline generation drops sections under pressure. See [`templates/README.md`](templates/README.md) for byte budgets and the "would two real projects disagree?" admission test, and [`templates/ANTI-TEMPLATES.md`](templates/ANTI-TEMPLATES.md) for content we intentionally do **not** pre-build.

---

## How It Works — Migration Process

### Decision: Which Path?

| Condition | Path |
|-----------|------|
| Total rules < 150 lines, no duplication, no recurring pitfalls | **Minimal single SKILL.md** — use the starter template |
| Rules > 150 lines but no duplication | **Quick Start scaffold** — run the script, fill TODOs |
| Rules > 150 lines AND duplicated across files | **Full 9-phase migration** |

### Full Migration (9 Phases)

| Phase | What Happens |
|-------|-------------|
| **1. Audit** | Inventory all rule sources: SKILL.md, AGENTS.md, CLAUDE.md, .cursor/rules/, README, docs/ |
| **2. Design** | Plan the file set based on project size (minimal, typical, or domain-specific) |
| **3. Write SKILL.md** | Create the <= 100-line entry with Always Read + Common Tasks + Known Gotchas |
| **4. Extract Rules** | Move stable constraints into `rules/` (project-rules, coding-standards, domain rules) |
| **5. Extract Workflows** | Create dedicated workflow files + required meta-workflows (update-rules, maintain-docs) |
| **6. Extract References** | Move architecture overviews, gotchas, source indexes into `references/` |
| **7. Create Entry Points** | Cursor registration entry + thin shells for all tools with inline routing tables |
| **8. Verify** | Run automated `smoke-test.sh` (roughly 50 checks) — structural, routing, placeholder, activation, and description quality |
| **9. Pressure-Test** | Dispatch subagents under time/sunk-cost/authority stressors; fold verbatim rationalizations into the Rationalizations table |

Incremental migration is supported — migrate in rounds without blocking daily work.

---

## Content Classification

| Content Type | Where It Goes | Examples |
|---|---|---|
| Stable constraints, must-follow rules | `rules/` | Naming conventions, module boundaries, dependency strategy |
| Step-by-step procedures | `workflows/` | add-controller, fix-bug, release, update-rules |
| Architecture, pitfalls, indexes | `references/` | System design, gotchas, route tables, third-party notes |
| Edge cases, footguns, costly bugs | `references/gotchas.md` | Lifecycle pitfalls, timing dependencies, framework quirks |
| Prompts, reports, external material | `docs/` | Templates, generated reports |
| Editor/tool config | `.cursor/`, `.claude/`, `.codex/` | Thin shells only — no rule content |

---

## Tool Compatibility

| Tool | Discovery Mechanism | Required Entry | Inline Routing? |
|---|---|---|---|
| **Cursor** | Scans `.cursor/skills/` only | `.cursor/skills/<name>/SKILL.md` | Yes |
| **Cursor rules** | `.cursor/rules/*.mdc` | `.cursor/rules/workflow.mdc` | Yes |
| **Claude Code** | Reads `CLAUDE.md` at repo root | `CLAUDE.md` | Yes |
| **Codex CLI** | Reads `AGENTS.md` + `.codex/instructions.md` | Both files | Yes |
| **Windsurf** | Reads `.windsurf/rules/` | `.windsurf/rules/*.md` | Yes |
| **Gemini CLI** | Reads `GEMINI.md` at repo root (+ parent/child dirs) | `GEMINI.md` | Yes |
| **Other agents** | Reads `AGENTS.md` | `AGENTS.md` | Yes |

All entry files **must** contain inline routing tables — natural-language-only instructions get lost during context summarization.

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
| 5 | **Description = trigger condition** | Explicit activation phrases, not passive summaries |
| 6 | **Two-layer routing** | Always Read (2-3 files) + Common Tasks (task-specific reads) |
| 7 | **Session Discipline** | Every new task in the same session must re-read SKILL.md and re-match routing; "I already read it" is not valid |
| 8 | **Task Closure Protocol** | AAR is part of task completion, not an optional extra |
| 9 | **Recording threshold** | 2/3 criteria (repeatable + costly + not obvious) before recording |
| 10 | **Generalization rule** | Records must be reusable knowledge, not project-specific narratives |
| 11 | **Activation over storage** | Pitfalls must appear in the task path, not just in reference files |
| 12 | **Self-maintaining** | Line counts signal evaluation; split only when topics are separable |
| 13 | **Start minimal, grow structured** | Use the minimal template first; upgrade when rules sprawl |

---

## Files in This Repo

| File | Content | Lines |
|------|---------|-------|
| [SKILL.md](SKILL.md) | Skill entry: when to use, target structure, core principles, common pitfalls | ~99 |
| [WORKFLOW.md](WORKFLOW.md) | Migration guide: decision tree, quick-start scaffold, full 9-phase process, incremental migration | ~330 |
| [REFERENCE.md](REFERENCE.md) | Stub + index — redirects to [`references/`](references/) (layout, thin-shells, protocols, conventions) | ~20 |
| [references/](references/) | Templates, thin shells, protocols, conventions — split across 4 topic files | ~690 |
| [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) | Minimal starter template, update-rules.md, fix-bug.md, maintain-docs.md meta-workflow templates | ~372 |
| [EXAMPLES.md](EXAMPLES.md) | Stub + index — redirects to [`examples/`](examples/) (migration, project-types, self-evolution) | ~20 |
| [examples/](examples/) | 16 before/after scenarios, split by topic across 3 files | ~720 |
| [skill.yaml](skill.yaml) | Machine-readable metadata for tool discovery | ~45 |

---

## Common Pitfalls

These are the most costly mistakes when using this architecture. Each has caused real failures:

| Pitfall | Impact | Fix |
|---------|--------|-----|
| **Missing Cursor registration entry** | Cursor never discovers the skill; all rules silently ignored | Create `.cursor/skills/<name>/SKILL.md` |
| **Soft-pointer-only shell** | Instruction lost after context summarization | Embed inline routing table in every entry file |
| **Vague description** | Skill exists but agent never activates it | Write >= 20 words with >= 2 quoted trigger phrases |
| **Stored but not activated** | Pitfall in `references/` but not in any workflow | Also surface in workflow checklist or SKILL.md routing |
| **Task Closure skipped** | Lessons not captured; same mistakes repeat | Use Task Closure Protocol as completion gate |
| **Route skipping in multi-task sessions** | Agent reads SKILL.md for task 1, skips re-reading for task 2 ("I already know the rules"), works from partial/stale memory for hours | Session Discipline rule in SKILL.md + re-read trigger in all thin shells |
| **Project-specific records** | Useless outside current context | Apply generalization rule before recording |

---

## Anti-Patterns

| Anti-Pattern | Why It Hurts | Fix |
|---|---|---|
| Fat thin shell (50+ lines) | Two places to update; defeats single source of truth | Strip back to <= 15 lines |
| SKILL.md as second README | Redundant context; exceeds 100 lines | Keep setup in README; SKILL.md only navigates |
| Rules and workflows mixed | Hard to find checklists; hard to update constraints | Constraints in `rules/`, procedures in `workflows/` |
| Mega sub-file (500+ lines) | Same problem as oversized SKILL.md, one level down | Split by subdomain |
| Over-splitting (20 files, 10 lines each) | Navigation overhead exceeds benefit | Merge related files; aim for 50-200 lines |
| Record everything | Rules bloat with low-value noise | Apply recording threshold: 2/3 criteria |

---

## Version History

Current: **v1.12**

| Version | Highlights |
|---------|------------|
| v1.0 | Basic directory structure and migration workflow |
| v1.1 | Thin shell templates, anti-patterns, multi-project support |
| v1.2 | Content classification guidelines, incremental migration |
| v1.3 | Self-evolution (AAR), self-maintenance (doc health checks), token efficiency |
| v1.4 | Two-layer routing (Always Read + Common Tasks), monorepo support |
| v1.5 | Skill auto-discovery via wildcard scanning |
| v1.6 | Enhanced update-rules / maintain-docs templates with recording thresholds |
| v1.7 | Task-closing hooks, activation over storage, fix-bug template |
| v1.8 | Description as trigger condition, gotchas as first-class content, auto-triggers |
| v1.9 | Official minimal template alignment, minimal starter template, boundary examples |
| v1.10 | Behavior-change closure loops, UI/interaction/z-index triggers, AAR miss examples |
| v1.11 | Task Closure Protocol, generalization rule for records, thin shell template DRY |
| v1.12 | Session Discipline (re-read SKILL.md for every new task in same session); automated `smoke-test.sh` (roughly 50 checks) + `test-trigger.sh` inside `templates/skill/scripts/`; Phase 9 pressure-test added to migration workflow |

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
The recording threshold (2/3: repeatable + costly + not obvious) filters out low-value records. The deprecation workflow in `update-rules.md` removes obsolete rules. The `maintain-docs.md` health checks catch oversized files.

---

## Star History


<a href="https://www.star-history.com/?repos=WoJiSama%2Fskill-based-architecture&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&theme=dark&legend=top-left&v=20260427" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&legend=top-left&v=20260427" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&legend=top-left&v=20260427" />
 </picture>
</a>
