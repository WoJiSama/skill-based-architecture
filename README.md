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

**Skill-Based Architecture (SBA) is a Skill, not an Agent operating system or a project-management platform.** It turns real project rules, business meaning, ownership, workflows, and validation contracts into a routable project skill, so an ordinary team member can clone a repository and let the Agent work reliably without first learning how to design Skills.

SBA absorbs the authoring and engineering complexity that should not belong to ordinary users. It helps the current Agent use the Plan, Subagent, and tool capabilities already provided by its harness, and degrades gracefully when a capability is unavailable. It does not add a resident service, task database, universal state machine, or independent execution runtime. Technology-specific facts still belong to the downstream project skill.

## What success looks like

SBA is not trying to make the Agent busier. It should make the Agent better at three things:

1. **See enough of the real situation.** Find the source of truth, owner, business invariant, producer-to-consumer path, contradictions, and evidence boundary without loading the whole repository.
2. **Judge without a standard answer.** Make trade-offs under incomplete information, state uncertainty honestly, and revisit the approach, acceptance criteria, boundaries, and Task Anchor when new evidence overturns a load-bearing conclusion.
3. **Organize reliable execution.** Turn intent into reviewable roles, inputs, outputs, forbidden zones, and validation contracts; delegate only for net benefit; and keep final synthesis and verification with the main Agent.

The outcome is not more files, tests, or process. It is a result that can be reviewed: sources, boundaries, owners, fitted evidence, and stop conditions are clear. Validation effort follows risk; test count is not a proxy for evidence quality.

Real leverage does not come from routing every action through one Agent. It comes from defining standards, judging risk, coordinating resources, and bringing out a result when information, resources, or requirements are incomplete.

## Install

**Claude Code — one line:**

```text
/plugin marketplace add WoJiSama/skill-based-architecture
/plugin install skill-based-architecture@skill-based-architecture
```

Then [trigger it](#quick-start); pull updates later with `/plugin marketplace update`.

**Try without installing:** [Run Skill Based Architecture in Telegram or WhatsApp](https://app.clawmama.run/skills/i78bb1/hermes?utm_source=github&utm_medium=issue&utm_campaign=skill_outreach_wojisama_skill_based_architecture) via ClawMama's Skill catalog. Use it with the [copy-paste demo input](examples/simple-repo/COPY-PASTE-INPUT.md) or other non-sensitive rule files. The bundled demo is deliberately the most basic smoke-test input, so the generated structure will be small; for real project migration, install locally with Claude Code or clone the repo.

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

Want a safe first run? Use [`examples/simple-repo/COPY-PASTE-INPUT.md`](examples/simple-repo/COPY-PASTE-INPUT.md) in hosted previews, or [`examples/simple-repo/`](examples/simple-repo/) as a local target project input. It is a deliberately tiny fake project with duplicated `AGENTS.md`, `CLAUDE.md`, Cursor rules, and README notes. Treat it as the most basic proof of routing/thin-shell behavior, not as a showcase of the full migration depth a real repo can produce.

Advanced workflows can use the current harness's native Plan, Subagent, and tool capabilities when they are available. SBA degrades to a serial or inline workflow when they are not. Some harnesses require explicit user authorization before delegation; that is a tool permission boundary, not another system the project member must install or maintain.

## Key features

- **Routed project truth.** `routing.yaml` selects one task workflow and only the extra domain context needed for the current decision. Business meaning, code facts, and historical evidence keep explicit owners and boundaries instead of becoming one undifferentiated knowledge dump.
- **Activation over storage.** A rule or lesson has value only when the normal task path reaches it and changes the Agent's next action. Thin shells and real user-language trigger conditions keep important knowledge live without duplicating rule bodies.
- **Goal and evidence discipline.** One clear action/check stays lightweight; other work establishes Goal, Done When, and material Boundaries. Before verification, each material risk is bound to fitted evidence and a stop/escalation condition. See [the Task Anchor design](docs/task-anchor-native-plan.md).
- **Reviewable coordination.** Delegated work carries role, inputs, outputs, forbidden zones, context provenance, checks, and remaining risks. Worker claims are candidate evidence; the main Agent still integrates and verifies the result.
- **Progressive rigor, small complete defaults.** Start with a single `SKILL.md`, grow only under real pressure, and remove or merge machinery when the pressure disappears. Ordinary users should not need to choose an architecture kit.
- **Graceful cross-harness operation.** Cursor, Claude Code, Codex, Windsurf, Gemini, OpenCode, and AGENTS.md-based tools use their native capabilities. A limitation in one harness does not redefine the overall product model.

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
| [docs/sba-bible.md](docs/sba-bible.md) | SBA product beliefs, development direction, and the decision gate for major new mechanisms |
| [WORKFLOW.md](WORKFLOW.md) | Migration guide: Quick Start scaffold, full 9-phase process, downstream upgrade |
| [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) | Annotated guide for template families, Task Execution, and Task Closure |
| [docs/task-anchor-native-plan.md](docs/task-anchor-native-plan.md) | User-facing Task Anchor, Native Plan, Workflow, and Closure model |
| [REFERENCE.md](REFERENCE.md) + [references/](references/) | Layout (incl. positioning), progressive rigor, thin shells, protocols, conventions |
| [EXAMPLES.md](EXAMPLES.md) + [examples/behavior-failures.md](examples/behavior-failures.md) | Migration shapes, project shapes, real pressure-test failures |
| [templates/](templates/) | Byte-for-byte scaffold files copied into downstream projects |
| [scripts/](scripts/) | Upstream maintenance + check suite ([scripts/README.md](scripts/README.md) has the matrix) |

## FAQ

**Is SBA an Agent operating system?**
No. SBA is a Skill that helps the current Agent use project rules, business semantics, workflows, and the harness's existing capabilities reliably. It does not own a task database, persistent scheduler, universal runtime, or project-management surface.

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
