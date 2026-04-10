# Skill-Based Architecture

**English** | [中文](#中文)

> A meta-skill that transforms oversized single-file skills and scattered project rules into a clean, modular `skills/<name>/` directory — so AI agents read only what they need, every time.

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

### Option 3 — Use with Claude Code / Codex / Windsurf

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

### Pre-built Templates

The [`templates/`](templates/) directory is the single source of truth for scaffold content:

- `templates/skill/` → becomes `skills/<name>/` (SKILL.md, rules stubs, workflow bodies, empty gotchas seed)
- `templates/shells/` → thin shells for every harness (AGENTS, CLAUDE, CODEX, GEMINI, `.codex/`, `.cursor/`)
- `templates/hooks/` → optional `SessionStart` hook that re-injects SKILL.md on `/clear` and `/compact`
- `templates/protocol-blocks/` → drop-in Task Closure Protocol reinforcement (Rationalizations table, Red Flags, Iron Law header)

Copy these instead of asking the agent to regenerate files inline — inline generation drops sections under pressure. See [`templates/README.md`](templates/README.md) for byte budgets and the "would two real projects disagree?" admission test, and [`templates/ANTI-TEMPLATES.md`](templates/ANTI-TEMPLATES.md) for content we intentionally do **not** pre-build.

---

## How It Works — Migration Process

### Decision: Which Path?

| Condition | Path |
|-----------|------|
| Total rules < 150 lines, no duplication, no recurring pitfalls | **Minimal single SKILL.md** — use the starter template |
| Rules > 150 lines but no duplication | **Quick Start scaffold** — run the script, fill TODOs |
| Rules > 150 lines AND duplicated across files | **Full 8-phase migration** |

### Full Migration (8 Phases)

| Phase | What Happens |
|-------|-------------|
| **1. Audit** | Inventory all rule sources: SKILL.md, AGENTS.md, CLAUDE.md, .cursor/rules/, README, docs/ |
| **2. Design** | Plan the file set based on project size (minimal, typical, or domain-specific) |
| **3. Write SKILL.md** | Create the <= 100-line entry with Always Read + Common Tasks + Known Gotchas |
| **4. Extract Rules** | Move stable constraints into `rules/` (project-rules, coding-standards, domain rules) |
| **5. Extract Workflows** | Create dedicated workflow files + required meta-workflows (update-rules, maintain-docs) |
| **6. Extract References** | Move architecture overviews, gotchas, source indexes into `references/` |
| **7. Create Entry Points** | Cursor registration entry + thin shells for all tools with inline routing tables |
| **8. Verify** | Structural checks + activation checks (description quality, routing coverage) |

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
| 7 | **Task Closure Protocol** | AAR is part of task completion, not an optional extra |
| 8 | **Recording threshold** | 2/3 criteria (repeatable + costly + not obvious) before recording |
| 9 | **Generalization rule** | Records must be reusable knowledge, not project-specific narratives |
| 10 | **Activation over storage** | Pitfalls must appear in the task path, not just in reference files |
| 11 | **Self-maintaining** | Line counts signal evaluation; split only when topics are separable |
| 12 | **Start minimal, grow structured** | Use the minimal template first; upgrade when rules sprawl |

---

## Files in This Repo

| File | Content | Lines |
|------|---------|-------|
| [SKILL.md](SKILL.md) | Skill entry: when to use, target structure, core principles, common pitfalls | ~99 |
| [WORKFLOW.md](WORKFLOW.md) | Migration guide: decision tree, quick-start scaffold, full 8-phase process, incremental migration | ~406 |
| [REFERENCE.md](REFERENCE.md) | Templates, thin shell patterns, description guidelines, anti-patterns, troubleshooting, CI validation | ~580 |
| [TEMPLATES.md](TEMPLATES.md) | Minimal starter template, update-rules.md, fix-bug.md, maintain-docs.md meta-workflow templates | ~372 |
| [EXAMPLES.md](EXAMPLES.md) | 16 before/after scenarios: migration, evolution, activation, edge cases, AAR, multi-skill | ~752 |
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

Current: **v1.11**

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

---

## 中文

**[English](#skill-based-architecture)** | 中文

> 一个 meta-skill，用于将过长的单文件 Skill 或散落各处的项目规则，重构为结构清晰的 `skills/<name>/` 目录 —— 让 AI Agent 每次只读需要的内容。

---

## 社区支持

学 AI，上 L 站 — [LinuxDO](https://linux.do/)

---

## 为什么需要这个

AI 编程 Agent（Cursor、Claude Code、Codex、Windsurf 等）依赖项目文档来理解规则、约定和工作流。但随着项目增长，文档不可避免地变成一团乱麻：

| 现状 | 实际后果 |
|------|---------|
| 单个 SKILL.md 超过 400 行 | Agent 每次任务都读**全部内容** —— 浪费 token、拖慢响应、难以维护 |
| 规则散落在 AGENTS.md、.cursor/rules/、CLAUDE.md 等多处 | 内容重复、规则矛盾、不知道以哪个为准 |
| 规则只增不减 | 有用规则被废弃规则淹没，Agent 无法区分重要内容 |
| Skill 从不自动触发 | description 是被动摘要而非明确触发条件 |
| 踩坑经验埋在文档深处 | 高代价的坑（30+ 分钟调试）在任务执行时根本不会被读到 |
| Agent 跳过复盘 | 工作中发现的教训丢失，同样的错误反复发生 |
| 记录太项目化 | 教训写成项目叙事而非可复用、可迁移的知识 |

**结果：** Agent 浪费上下文读无关文档、漏掉关键规则、重复已知错误、产出不一致。

## 解决什么问题

Skill-Based Architecture 提供了一套 AI Agent 文档的**结构化模式**：

1. **最小化 token 浪费** —— Agent 每次任务只读 2-3 个核心文件，而非全部
2. **消除重复** —— 每条规则只有一个权威来源，其他位置全部是薄壳
3. **按任务路由** —— "Common Tasks" 路由表指引 Agent 到精确的文件
4. **自动捕获经验** —— 内置复盘流程（AAR）配合录入门槛
5. **自维护** —— 健康检查、拆分/合并流程、废弃工作流保持文档精简
6. **全平台兼容** —— 支持 Cursor、Claude Code、Codex、Windsurf 和 OpenClaw

---

## 目录结构

```
skills/<name>/
├── SKILL.md          # <= 100 行：必读列表 + 任务路由表
├── rules/            # 长期约束（始终成立的规则）
├── workflows/        # 步骤化流程（怎么做一件事）
├── references/       # 背景资料：架构、坑点、索引
│   └── gotchas.md    # 已知坑点 —— 通常是价值最高的内容
└── docs/             # 可选：提示词、报告、对外文档
```

根目录入口文件（`AGENTS.md`、`CLAUDE.md`、`CODEX.md`、`.cursor/rules/*.mdc`、`.codex/`）变为**薄壳** —— 每个不超过 15 行，仅包含路由表和指向正式 Skill 的指针。

---

## 核心特性

### 两层路由

SKILL.md 使用两层系统，而非把所有文档一股脑塞给 Agent：

- **Always Read**（2-3 个文件，~150 行）—— 每个任务都加载
- **Common Tasks**（按任务路由）—— Agent 只读当前任务列出的文件

### 薄壳含内联路由表

每个入口文件都嵌入**路由表** —— 不只是"去读 SKILL.md"。这在长对话中上下文被压缩时依然有效。

### Description = 触发条件

`description` 字段不是被动描述 —— 它决定 Agent 在运行时是否激活这个 Skill。

### Task Closure Protocol

每个非平凡任务在完成前必须执行 30 秒复盘：

1. **主要工作完成** —— 实现已验证
2. **AAR 扫描** —— 4 个问题：新模式？新坑？缺失规则？过时规则？
3. **按需记录** —— 满足录入门槛（2/3：可重复 + 代价高 + 代码不可见）才记录

### 录入门槛

不是所有东西都值得记录。潜在教训必须满足 3 条中的至少 2 条：

| 标准 | 问题 |
|------|------|
| **可重复** | 未来任务还会遇到吗？ |
| **代价高** | 不知道的话会浪费 30+ 分钟调试吗？ |
| **代码不可见** | 未来读者能仅从代码推断出来吗？ |

### 泛化规则

记录必须是可复用知识，不是项目叙事：

| 差（项目叙事） | 好（泛化知识） |
|---|---|
| 产品模块切换 tab 需要重置分页 | 切换上下文（tab、视图、筛选器）时重置分页到第 1 页 |
| 我们的 UserService.createUser 需要先做去重检查 | 唯一性验证必须在实体创建之前 |

### 激活优于存储

仅记录在 `references/` 的高代价坑点**不算完全捕获** —— 还必须出现在任务执行路径上（工作流检查清单、SKILL.md 路由、或精简规则）。

---

## 如何使用

### 方式一 —— 安装为 Cursor 用户级 Skill

```bash
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  ~/.cursor/skills/skill-based-architecture
```

然后在任意项目中告诉 Cursor：

> "Use skill-based-architecture to refactor the project rules"

### 方式二 —— 安装为项目级 Skill

```bash
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  .cursor/skills/skill-based-architecture
```

### 方式三 —— 配合 Claude Code / Codex / Windsurf 使用

将文件复制到 Agent 能读取的位置，然后在 `CLAUDE.md`、`AGENTS.md` 或对应入口文件中引用：

```md
规则重构任务请使用 `skills/skill-based-architecture/` 中的 skill。
先读 `skills/skill-based-architecture/SKILL.md`。
```

### 触发短语

安装后，用以下任意短语激活：

- "整理项目规则"
- "把规则重构成 skill-based architecture"
- "清理散乱的文档"
- "把规则整合到 skills 目录"
- "迁移规则到 skills/"

### 快速脚手架

激活后，Agent 从预制的 [`templates/`](templates/) 目录**复制**脚手架——**不要让 Agent 实时再生文件**。完整命令见 `WORKFLOW.md` Quick Start，核心步骤：

```bash
UPSTREAM="${UPSTREAM:-../skill-based-architecture}"
NAME="my-project"
SUMMARY="一句话项目简介"
mkdir -p "skills/$NAME"
cp -R "$UPSTREAM/templates/skill/." "skills/$NAME/"
cp -R "$UPSTREAM/templates/shells/." .
mv ".cursor/skills/{{NAME}}" ".cursor/skills/$NAME"
find "skills/$NAME" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .codex .cursor \
  -type f \( -name '*.md' -o -name '*.mdc' \) \
  -exec sed -i '' -e "s/{{NAME}}/$NAME/g" -e "s/{{SUMMARY}}/$SUMMARY/g" {} +
```

然后逐个填写 `<!-- FILL: -->` 标记（用 `grep -rn 'FILL:' skills/$NAME` 列出全部）。每一处 FILL 都是必填项——留空会导致技能激活静默失败。

### 预制模板目录

[`templates/`](templates/) 是脚手架内容的唯一权威来源：

- `templates/skill/` → 复制为 `skills/<name>/`（SKILL.md、规则 stub、工作流正文、空的 gotchas 种子）
- `templates/shells/` → 所有 harness 的薄壳（AGENTS、CLAUDE、CODEX、GEMINI、`.codex/`、`.cursor/`）
- `templates/hooks/` → 可选的 `SessionStart` hook，在 `/clear` 和 `/compact` 时重新注入 SKILL.md
- `templates/protocol-blocks/` → Task Closure Protocol 强化块（Rationalizations 表、Red Flags、Iron Law 标题）

**复制而不是再生**——Agent 在压力场景下会漏段落。详见 [`templates/README.md`](templates/README.md) 的字节预算和"两个真实项目会不同意吗"准入测试，以及 [`templates/ANTI-TEMPLATES.md`](templates/ANTI-TEMPLATES.md) 中**拒绝预制**的内容清单。

---

## 迁移流程

### 选择路径

| 条件 | 路径 |
|------|------|
| 规则总量 < 150 行，无重复，无反复踩坑 | **最小单文件 SKILL.md** —— 用起步模板 |
| 规则 > 150 行但无重复 | **快速脚手架** —— 运行脚本，填 TODO |
| 规则 > 150 行且跨文件重复 | **完整 8 阶段迁移** |

### 完整迁移（8 阶段）

| 阶段 | 做什么 |
|------|--------|
| **1. 审计** | 盘点所有规则来源 |
| **2. 设计** | 根据项目规模规划文件集 |
| **3. 编写 SKILL.md** | 创建 <= 100 行的入口 |
| **4. 提取规则** | 稳定约束移入 `rules/` |
| **5. 提取工作流** | 创建专用工作流文件 + 必需的元工作流 |
| **6. 提取引用** | 架构概述、坑点、索引移入 `references/` |
| **7. 创建入口** | Cursor 注册入口 + 所有工具的薄壳（含内联路由表） |
| **8. 验证** | 结构检查 + 激活检查 |

支持增量迁移 —— 分轮次迁移，不阻塞日常工作。

---

## 工具兼容性

| 工具 | 发现机制 | 必需入口 | 需要内联路由？ |
|---|---|---|---|
| **Cursor** | 仅扫描 `.cursor/skills/` | `.cursor/skills/<name>/SKILL.md` | 是 |
| **Claude Code** | 读取仓库根目录 `CLAUDE.md` | `CLAUDE.md` | 是 |
| **Codex CLI** | 读取 `AGENTS.md` + `.codex/instructions.md` | 两个文件都需要 | 是 |
| **Windsurf** | 读取 `.windsurf/rules/` | `.windsurf/rules/*.md` | 是 |
| **Gemini CLI** | 读取仓库根目录 `GEMINI.md`（+ 父/子目录） | `GEMINI.md` | 是 |
| **其他 Agent** | 读取 `AGENTS.md` | `AGENTS.md` | 是 |

---

## 核心原则

| # | 原则 | 含义 |
|---|------|------|
| 1 | **SKILL.md 是路由器** | 只做导航，不做穷举；<= 100 行 |
| 2 | **一个 Skill 一个文件夹** | 正式文档都在 `skills/<name>/`，不散落 |
| 3 | **规则 != 流程** | `rules/` 放约束，`workflows/` 放步骤，不混用 |
| 4 | **薄壳含内联路由表** | 入口文件嵌入路由表，对抗上下文压缩 |
| 5 | **Description = 触发条件** | 写明确的触发短语，不写被动摘要 |
| 6 | **两层路由** | Always Read（2-3 个文件）+ Common Tasks（按任务路由） |
| 7 | **Task Closure Protocol** | AAR 是任务完成的门槛，不是可选附加 |
| 8 | **录入标准** | 可重复 + 代价高 + 代码不可见，至少 2/3 才录入 |
| 9 | **泛化规则** | 记录必须是可复用知识，不是项目叙事 |
| 10 | **激活优于存储** | 陷阱必须出现在任务路径上，不能只埋在 references/ |
| 11 | **自维护** | 行数超标触发评估，话题可分离才拆分 |
| 12 | **从小开始，按需扩展** | 先用最小模板，规则膨胀时再升级 |

---

## 文件说明

| 文件 | 内容 |
|------|------|
| [SKILL.md](SKILL.md) | Skill 入口：使用时机、目标结构、核心原则、常见陷阱 |
| [WORKFLOW.md](WORKFLOW.md) | 迁移指南：决策树、快速脚手架、完整 8 阶段流程、增量迁移 |
| [REFERENCE.md](REFERENCE.md) | 模板、薄壳模式、description 指南、反模式、故障排查、CI 验证 |
| [TEMPLATES.md](TEMPLATES.md) | 起步模板 + 元工作流模板（update-rules、fix-bug、maintain-docs） |
| [EXAMPLES.md](EXAMPLES.md) | 16 个前后对比案例：迁移、进化、激活、边界场景、AAR、多 Skill |
| [skill.yaml](skill.yaml) | 机器可读的元数据 |

---

## 常见陷阱

| 陷阱 | 影响 | 修复 |
|------|------|------|
| **缺少 Cursor 注册入口** | Cursor 永远发现不了 Skill | 创建 `.cursor/skills/<name>/SKILL.md` |
| **薄壳只有软指针** | 长对话中上下文压缩后指令丢失 | 每个入口文件嵌入路由表 |
| **Description 太模糊** | Skill 存在但 Agent 永远不激活 | 写 >= 20 词，含 >= 2 个引用触发短语 |
| **存储但未激活** | 坑点在 references/ 但不在任何工作流中 | 同时在工作流检查清单或路由中呈现 |
| **跳过 Task Closure** | 教训未捕获，同样错误反复 | 把 AAR 作为完成门槛 |
| **记录太项目化** | 脱离当前上下文就无用 | 录入前应用泛化规则 |

---

## 版本历史

当前版本：**v1.11**

| 版本 | 要点 |
|------|------|
| v1.0 | 基础目录结构和迁移工作流 |
| v1.1 | 薄壳模板、反模式、多项目支持 |
| v1.2 | 内容分类指南、增量迁移 |
| v1.3 | 自进化（AAR）、自维护（文档健康检查）、token 效率 |
| v1.4 | 两层路由（Always Read + Common Tasks）、monorepo 支持 |
| v1.5 | Skill 通配符自动发现 |
| v1.6 | 增强 update-rules / maintain-docs 模板，含录入门槛 |
| v1.7 | 任务关闭钩子、激活优于存储、fix-bug 模板 |
| v1.8 | Description 作为触发条件、gotchas 作为一等内容、自动触发器 |
| v1.9 | 官方最小模板对齐、最小起步模板、边界示例 |
| v1.10 | 行为变更闭环、UI/交互/z-index 触发器、AAR 遗漏示例 |
| v1.11 | Task Closure Protocol、记录泛化规则、薄壳模板 DRY |

---

## 常见问题

**Q: 这会取代 Anthropic 官方的 Skill 模板吗？**
不会。官方模板定义了*最小* Skill 形态（一个文件夹 + SKILL.md + frontmatter）。这个 meta-skill 在那之上添加结构 —— 当单个小 SKILL.md 不够用时才需要。

**Q: 什么时候不该用？**
- 非常小的项目（规则/文档文件少于 3 个）
- 临时仓库，无长期维护需求
- 已有完善文档体系且不想迁移的团队

**Q: 可以增量迁移吗？**
可以。第 1 轮：创建 `skills/<name>/` 并提取规则。第 2 轮：提取工作流。第 3 轮：提取引用并创建薄壳。每轮结束后项目都处于可工作状态。

**Q: 如果我的 SKILL.md 还很小怎么办？**
保持单文件，使用最小起步模板。只在内容开始膨胀、重复、或积累非显而易见的教训时再升级。

**Q: 如何防止文档膨胀？**
录入门槛（2/3：可重复 + 代价高 + 代码不可见）过滤低价值记录。`update-rules.md` 中的废弃工作流移除过时规则。`maintain-docs.md` 的健康检查捕获超大文件。
