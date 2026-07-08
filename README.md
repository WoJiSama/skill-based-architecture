<p align="center">
  <img src="assets/skill-based-architecture-title.png" alt="skill-ba" width="720">
</p>

# Skill-Based Architecture

<p align="center">
  <a href="https://github.com/WoJiSama/skill-based-architecture/stargazers">
    <img alt="GitHub stars" src="https://img.shields.io/github/stars/WoJiSama/skill-based-architecture?style=flat&logo=github">
  </a>
  <a href="https://github.com/WoJiSama/skill-based-architecture/forks">
    <img alt="GitHub forks" src="https://img.shields.io/github/forks/WoJiSama/skill-based-architecture?style=flat&logo=github">
  </a>
  <a href="LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/WoJiSama/skill-based-architecture?style=flat">
  </a>
  <img alt="Status" src="https://img.shields.io/badge/status-alpha-orange">
  <a href="https://linux.do/">
    <img alt="LinuxDO" src="https://img.shields.io/badge/LINUX-DO-f59e0b?style=flat">
  </a>
</p>

<p align="center"><strong>English</strong> | <a href="README.zh-CN.md">中文</a></p>

A **lifecycle framework for AI-agent rule systems.** Turns scattered prompt documents (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, README rules) into routable, verifiable, updatable engineering assets under `skills/<name>/`.

It focuses on the rule system itself: structure, routing, workflows, validation, after-action learning, and upstream/downstream updates. It does **not** ship technology-specific rules — those belong in your downstream project skill.

## Install

**Claude Code — one line:**

```text
/plugin marketplace add WoJiSama/skill-based-architecture
/plugin install skill-based-architecture@skill-based-architecture
```

Then [trigger it](#quick-start); pull updates later with `/plugin marketplace update`.

**Try without installing:** [Run Skill Based Architecture in Telegram or WhatsApp](https://app.clawmama.run/skills/i78bb1/hermes?utm_source=github&utm_medium=issue&utm_campaign=skill_outreach_wojisama_skill_based_architecture) via ClawMama's Skill catalog. Use it with the [copy-paste demo input](examples/simple-repo/COPY-PASTE-INPUT.md) or other non-sensitive rule files; for real project migration, install locally with Claude Code or clone the repo.

**Cursor / Codex / Gemini / other harnesses** don't share Claude Code's plugin system — clone the repo instead (see [Quick Start](#quick-start)).

## What it produces

```
scattered project guidance
AGENTS.md / CLAUDE.md / .cursor/rules / README notes
        │
        ▼
skills/<project>/
├── SKILL.md          # router: description ≤ 25 + body ≤ 90 lines (dual budget)
├── rules/            # stable constraints
├── workflows/        # repeatable procedures
├── references/       # architecture, gotchas, indexes
└── docs/             # optional reports and prompts

tool entry files
AGENTS.md / CLAUDE.md / CODEX.md / GEMINI.md / .cursor/rules / .codex
        └── thin shells: route to skills/<project>/, no duplicated rule bodies
```

## Why

| Symptom | What goes wrong |
|---|---|
| Single `SKILL.md` with 400+ lines | Agent reads everything every task — wastes tokens, hides what matters |
| Rules duplicated across `AGENTS.md`, `.cursor/rules/`, `CLAUDE.md` | Drift, contradictions, no source of truth |
| Skill activation is unreliable | Description is a passive summary instead of explicit trigger conditions |
| Hard-won lessons buried in docs | Costly pitfalls never surface during the next task |
| Rule files only grow, never shrink | Useful rules get buried by obsolete ones |

The architecture answers each: a routing source-of-truth (`routing.yaml`), thin shells everywhere else, description-as-trigger discipline, AAR with a recording threshold, and self-maintenance via line-count signals + split/merge procedures.

## When NOT to use

- Total rule content < 50 lines (a single `CLAUDE.md` is enough)
- Single harness, no team sharing, no recurring tasks
- Short-lived solo project (< 2 weeks)

Start with a plain `CLAUDE.md` or `.cursor/rules/workflow.mdc`; upgrade later when content sprawls. [WORKFLOW.md](WORKFLOW.md) has a Quick Start path for that upgrade.

## Quick Start

### 1. Make this meta-skill available locally

**Claude Code:** already done via the [one-line install above](#install) — skip to step 2.

**Cursor / Codex / Gemini / other harnesses:** pull this repo **any way you want** (`git clone`, download zip, submodule, fork…) to **any location** — the only requirement is that **you and the agent both know where it lives**.

As long as the agent can locate this directory when triggered, the path doesn't matter. If it isn't on the agent's default search path (e.g., Cursor's `~/.cursor/skills/`, `.cursor/skills/`, or the project's own `skills/`), write the path into `CLAUDE.md` / `AGENTS.md` / `.cursor/rules/` so the agent can find it.

Common placements:

- Inside the project: `skills/skill-based-architecture/`
- Next to the project: `../skill-based-architecture/`
- Cursor user-level: `~/.cursor/skills/skill-based-architecture/`
- Cursor project-level: `.cursor/skills/skill-based-architecture/`

Example (clone inside the project):

```bash
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  skills/skill-based-architecture
```

### 2. Trigger it from the target project

Ask the agent to use the local meta-skill:

> "Use skill-based-architecture to refactor the project rules"

Equivalent triggers: "Organize the project rules", "Migrate rules to skills/", "整理项目规则".

The agent then copies the pre-built scaffold from [`templates/`](templates/) into `skills/<name>/`, creates the thin shells, fills every `<!-- FILL: -->` marker, and runs validation. Full procedure: [WORKFLOW.md](WORKFLOW.md).

Want a safe first run? Use [`examples/simple-repo/COPY-PASTE-INPUT.md`](examples/simple-repo/COPY-PASTE-INPUT.md) in hosted previews, or [`examples/simple-repo/`](examples/simple-repo/) as a local target project input. It is a small fake project with duplicated `AGENTS.md`, `CLAUDE.md`, Cursor rules, and README notes, designed to show the migration without exposing private code.

### 3. (Codex only) Manually request sub-agent / parallel work

Several workflows in this meta-skill lean on sub-agent delegation and parallel agent fan-out (see [`templates/skill/workflows/subagent-driven.md`](templates/skill/workflows/subagent-driven.md) and [`templates/skill/workflows/refactor-fanout.md`](templates/skill/workflows/refactor-fanout.md)). In most harnesses the in-repo rules are enough — the agent decides on its own when to fan out.

**Codex is the exception.** Its runtime imposes a tool-level rule on `spawn_agent`: it may only be invoked when the user **explicitly** asks for sub-agent, delegation, or parallel agent work. That tool-level rule outranks anything in this repo's `AGENTS.md` or skill files, so the fan-out patterns will **not** fire automatically — even though the workflow documents tell the agent to use them.

If you're in Codex and want sub-agent work to actually happen — fan-out or anything else — you have to authorize it explicitly. Two equivalent patterns:

**Per-task** — name the specific work you want delegated:

> "Use a sub-agent to refactor the rule files."
> "Spawn sub-agents to review each workflow file in parallel."
> "请使用 sub-agent 来扫一遍 templates 目录。"

**Session-wide** — grant blanket permission once at the start:

> "In this session you may use sub-agents whenever the workflow calls for it."
> "本次会话我允许你使用 sub-agent。"
> "Feel free to delegate to sub-agents in this session."

Either form satisfies the tool-level rule. Without one of them, Codex will silently skip the delegation step — even when the workflow documents tell the agent to use sub-agents.

## Key features

- **Two-layer routing.** `SKILL.md` keeps a short generated **Always Read** list; **Common Tasks** routes the agent to extra files only when needed. `routing.yaml` is the editable source of truth in downstream projects.
- **Thin shells with routing bootstrap.** Every entry file embeds a short bootstrap that points to `routing.yaml`. The route table is not duplicated across shells; natural-language-only instructions get lost during context summarization.
- **Description as trigger condition.** Domain-level activation phrases in the user's actual language(s), not workflow keyword stuffing. Re-read aloud after edits — no script substitutes for hearing whether it sounds like a real user.
- **Session Discipline + Task Closure.** Re-match the route on every new task; re-read files only when the route changed or context was compacted; finish non-trivial tasks with a 30-second AAR scan + recording threshold, never "tests passed = done".
- **Self-maintenance.** Line-count signals trigger evaluation, not automatic action; split/merge procedures and freshness checks keep docs lean.
- **Cross-harness.** Compatible with Cursor, Claude Code, Codex, Windsurf, Gemini, OpenCode, and AGENTS.md-based tools.

## Tool compatibility

<!-- external-fact: verified=2026-04-28 source=https://docs.cursor.com/en/context -->
<!-- external-fact: verified=2026-04-28 source=https://code.claude.com/docs/en/skills -->
<!-- external-fact: verified=2026-04-28 source=https://developers.openai.com/codex/guides/agents-md -->
<!-- external-fact: verified=2026-04-28 source=https://docs.windsurf.com/windsurf/cascade/memories -->
<!-- external-fact: verified=2026-04-28 source=https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md -->
<!-- external-fact: verified=2026-04-28 source=https://opencode.ai/docs/rules/ -->

| Tool | Required entry |
|---|---|
| **Cursor** | `.cursor/skills/<name>/SKILL.md` + `.cursor/rules/*.mdc` |
| **Claude Code** | `CLAUDE.md` (optional `.claude/skills/<name>/SKILL.md` stub) |
| **Codex CLI / Copilot CLI / OpenCode / other** | `AGENTS.md` |
| **Windsurf** | `.windsurf/rules/*.md` or shared `AGENTS.md` |
| **Gemini CLI** | `GEMINI.md` |

All entries must contain a `routing.yaml` bootstrap — for Claude Code native skills, prefer project-specific names (`<project>-review`) since enterprise > personal > project precedence resolves same-name skills.

Per-tool templates: [`references/per-tool-shells.md`](references/per-tool-shells.md). Tool compatibility deep dive: same file.

## Files in this repo

| File | Content |
|---|---|
| [SKILL.md](SKILL.md) | Skill entry: when to use, target structure, core principles |
| [WORKFLOW.md](WORKFLOW.md) | Migration guide: Quick Start scaffold, full 9-phase process, downstream upgrade |
| [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) | Annotated guide for template families and Task Closure Protocol |
| [REFERENCE.md](REFERENCE.md) + [references/](references/) | Layout (incl. positioning), progressive rigor, thin shells, protocols, conventions |
| [EXAMPLES.md](EXAMPLES.md) + [examples/behavior-failures.md](examples/behavior-failures.md) | Migration shapes, project shapes, real pressure-test failures |
| [templates/](templates/) | Byte-for-byte scaffold files copied into downstream projects |
| [scripts/](scripts/) | Upstream maintenance + check suite ([scripts/README.md](scripts/README.md) has the matrix) |

## FAQ

**Does this replace the official Anthropic skill template?**
No. The official template defines the *minimal* skill shape (a folder with SKILL.md + frontmatter). This meta-skill starts one level later — it adds structure when a single small SKILL.md is no longer enough.

**Can I migrate incrementally?**
Yes. Round 1: extract rules. Round 2: extract workflows. Round 3: extract references and create thin shells. Each round leaves the project in a working state.

**How do downstream projects receive upstream improvements?**
Ask the agent to update from upstream. The copied `workflows/update-upstream.md` clones the latest upstream, reads `UPSTREAM-CHANGES.md` from the cloned repo, compares files itself, patches in mechanism changes, preserves project-owned content, and re-runs validation including conformance against upstream's own contract.

---

Learn AI on LinuxDO — [LinuxDO](https://linux.do/)

## Star history

<a href="https://www.star-history.com/?repos=WoJiSama%2Fskill-based-architecture&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&legend=top-left" />
 </picture>
</a>
