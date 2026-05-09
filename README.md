<p align="center">
  <img src="assets/skill-based-architecture-title.png" alt="skill-ba" width="720">
</p>

# Skill-Based Architecture

<p align="left">
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

**English** | [中文](README.zh-CN.md)

A **lifecycle framework for AI-agent rule systems.** Turns scattered prompt documents (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, README rules) into routable, verifiable, updatable engineering assets under `skills/<name>/`.

It focuses on the rule system itself: structure, routing, workflows, validation, after-action learning, and upstream/downstream updates. It does **not** ship technology-specific rules — those belong in your downstream project skill.

## What it produces

```
scattered project guidance
AGENTS.md / CLAUDE.md / .cursor/rules / README notes
        │
        ▼
skills/<project>/
├── SKILL.md          # router: Always Read + Common Tasks (≤ 100 lines)
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

| Use case | Clone target |
|---|---|
| Cursor user-level | `~/.cursor/skills/skill-based-architecture` |
| Cursor project-level | `.cursor/skills/skill-based-architecture` |
| Other agents | `skills/skill-based-architecture` inside the target project, or `../skill-based-architecture` next to it |

```bash
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  skills/skill-based-architecture
```

### 2. Trigger it from the target project

Ask the agent to use the local meta-skill:

> "Use skill-based-architecture to refactor the project rules"

Equivalent triggers: "Organize the project rules", "Migrate rules to skills/", "整理项目规则".

The agent then copies the pre-built scaffold from [`templates/`](templates/) into `skills/<name>/`, creates the thin shells, fills every `<!-- FILL: -->` marker, and runs validation. Full procedure: [WORKFLOW.md](WORKFLOW.md).

## Key features

- **Two-layer routing.** `SKILL.md` keeps a short generated **Always Read** list; **Common Tasks** routes the agent to extra files only when needed. `routing.yaml` is the editable source of truth in downstream projects.
- **Thin shells with routing bootstrap.** Every entry file embeds a short bootstrap that points to `routing.yaml`. The route table is not duplicated across shells; natural-language-only instructions get lost during context summarization.
- **Description as trigger condition.** Domain-level activation phrases in the user's actual language(s), not workflow keyword stuffing. Validated by `check-description-routing.sh`.
- **Session Discipline + Task Closure.** Re-read SKILL.md on every new task in the same session; finish non-trivial tasks with a 30-second AAR scan + recording threshold, never "tests passed = done".
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
