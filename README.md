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

## Target Structure

```
skills/<name>/
├── SKILL.md          # <= 100 lines: always-read list + generated Common Tasks
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

`SKILL.md` keeps a short generated **Always Read** list for every task, then uses a generated **Common Tasks** summary to route the agent to extra files only when needed. In downstream projects, `routing.yaml` is the editable source of truth for Always Read files, Common Tasks, trigger examples, required reads, workflows, and thin-shell bootstraps.

### Thin Shells with Routing Bootstrap

Every entry file (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.codex/instructions.md`, `.cursor/rules/*.mdc`) embeds a short bootstrap that points to `routing.yaml` and explains how to match `labels` / `trigger_examples`. The route data itself is not duplicated across shells.

### Description as Trigger Condition

The `description` field decides whether the agent activates the skill. Keep it at the **domain / intent-cluster** level, with real phrases users say, for example both `"this endpoint is failing"` and `"这个接口报错了"`. Do not list every workflow there — `SKILL.md` Common Tasks handles task-level routing after activation. `check-description-routing.sh` catches obvious over-broad descriptions and multi-skill trigger overlap.

### Session Discipline

Every new task — even the second or third in the same session — must re-read SKILL.md, re-match the route in `routing.yaml`, and re-read all files listed for that route.

This avoids stale partial memory after `/compact`, `/clear`, or a long multi-task session.

### Task Closure and Freshness Checks

Non-trivial tasks end with a short After-Action Review: verify the work, decide whether any repeatable/costly/non-obvious lesson should be recorded, and check whether any rule has gone stale. Doc edits also run description-routing, link, orphan-reference, cross-reference, and external-fact freshness checks.

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

After activation, the agent copies the pre-built scaffold from [`templates/`](templates/) into `skills/<name>/`, creates the thin shells, fills every `<!-- FILL: -->` marker, and verifies the result. The exact command lives in [WORKFLOW.md Quick Start](WORKFLOW.md#quick-start-copy-dont-generate).

### Pre-built Templates

[`templates/`](templates/) is the copy source for skill files, thin shells, hooks, scripts, and protocol blocks. Copy these files instead of regenerating them inline. See [`templates/README.md`](templates/README.md) for the template map and [`templates/ANTI-TEMPLATES.md`](templates/ANTI-TEMPLATES.md) for content that intentionally stays out of reusable templates.

---

## What Happens After You Trigger It

The README only shows the operating shape. The detailed migration checklist lives in [WORKFLOW.md](WORKFLOW.md).

1. **Audit current guidance** — find rule sources such as `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, README notes, and existing docs.
2. **Create the project skill** — copy the scaffold into `skills/<name>/`, then fill `SKILL.md`, `rules/`, `workflows/`, and `references/` with project-specific evidence.
3. **Wire entry files** — create thin shells for the tools you use, keeping rule bodies in `skills/<name>/`.
4. **Validate** — run the copied scripts for structure, routing, placeholders, links, orphaned references, and external-fact freshness.

Use the full [WORKFLOW.md](WORKFLOW.md) when you are actually performing a migration; keep the README as the short orientation page.

---

## Extending the Skill

After the first migration, keep growing the project skill through routing instead of copying rule text into more places:

- Add project-specific workflows such as `plan.md`, `review.md`, or `deploy-check.md`.
- Let a workflow invoke another skill when that is the natural tool for the subtask.
- Add reusable protocol blocks when the same discipline problem repeats.
- Add one task to `routing.yaml` whenever a new recurring task appears, then run `scripts/sync-routing.sh`.
- When this upstream project changes, tell the agent "update from upstream"; it should follow `workflows/update-upstream.md`, clone the GitHub source, patch locally, and preserve project-specific rules.

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

All entry files **must** contain a `routing.yaml` bootstrap — natural-language-only instructions get lost during context summarization, but duplicating the full route table in every shell creates drift pressure.

For Claude Code native skills, avoid generic project skill names that may collide with `~/.claude/skills/`: a personal skill with the same name overrides the project native skill. The project `skills/<name>/` directory remains the source of truth through `CLAUDE.md` and optional SessionStart routing.

---

## Files in This Repo

| File | Content |
|------|---------|
| [SKILL.md](SKILL.md) | Skill entry: when to use, target structure, and core principles |
| [WORKFLOW.md](WORKFLOW.md) | Migration guide: decision tree, quick-start scaffold, full 9-phase process, downstream upgrade |
| [REFERENCE.md](REFERENCE.md) | Stub + index — redirects to [`references/`](references/) |
| [references/](references/) | Layout, thin shells, protocols, conventions, multi-skill routing, skill composition, and self-hosting routing |
| [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) | Annotated guide for template families and Task Closure Protocol |
| [templates/](templates/) | Byte-for-byte scaffold files copied into downstream projects |
| [EXAMPLES.md](EXAMPLES.md) | Stub + index — redirects to [`examples/`](examples/) |
| [examples/](examples/) | Migration, project-type, self-evolution, and behavior-failure examples |
| [skill.yaml](skill.yaml) | Machine-readable metadata for tool discovery |

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
The recording threshold (2/3: repeatable + costly + not obvious) filters out low-value records. The deprecation workflow in `update-rules.md` removes obsolete rules. `maintain-docs.md`, `check-description-routing.sh`, reference audits, cross-reference checks, and `check-external-facts.sh` catch oversized files, vague triggers, orphaned references, stale links, and stale external claims.

**Q: How do downstream projects receive upstream improvements?**
Ask the agent to update from upstream. The copied `workflows/update-upstream.md` contains the GitHub source URL and tells the agent to clone the latest upstream, compare files itself, patch useful mechanism changes, preserve project-owned rules/gotchas, then run validation.

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
