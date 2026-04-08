# Skill-Based Architecture

**English** | [中文](#中文)

> A meta-skill for restructuring oversized single-file skills and scattered project rules into a clean, modular `skills/<name>/` directory that agents can navigate efficiently.

---

## The Problem

| Symptom | Pain |
|---------|------|
| Single SKILL.md with 400+ lines | Agent reads everything on every task — wastes tokens, hard to maintain |
| Rules scattered across AGENTS.md, .cursor/rules/, CLAUDE.md | Duplicated, inconsistent, no single source of truth |
| Rules only grow, never shrink | Docs bloat; useful rules get buried by obsolete ones |
| Skill never triggers | Description is a passive summary instead of explicit activation conditions |
| Hard-won lessons buried in docs | Costly pitfalls never surface during actual task execution |
| Agent skips after-action review | AAR treated as optional, not part of task completion |
| Records are project-specific | Lessons written as narratives instead of reusable knowledge |

## The Solution

```
skills/<name>/
├── SKILL.md          # ≤100 lines: always-read list + task routing
├── rules/            # Long-lived constraints (what is always true)
├── workflows/        # Step-by-step procedures (how to do things)
├── references/       # Background: architecture, gotchas, indexes
│   └── gotchas.md    # Known pitfalls — often the highest-value content
└── docs/             # Optional: prompts, reports, external docs
```

## How to Use

### Option 1 — Install as a Cursor user-level skill

Clone this repo into your Cursor skills directory so the skill is available in every project:

```bash
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  ~/.cursor/skills/skill-based-architecture
```

Then in any project, tell Cursor:

> "Use skill-based-architecture to refactor the project rules"

### Option 2 — Install as a project-level skill

Copy into your project's skill directory:

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

### Trigger phrases

Once installed, activate the skill with any of these:

- "Organize the project rules"
- "Refactor the project rules into a skill-based architecture"
- "Clean up scattered documentation"
- "Consolidate rules into a skills directory"
- "Migrate rules to skills/"

### Quick-start scaffold

After activation, the agent can generate a full directory structure for your project. Ask it to run the Quick Start from `WORKFLOW.md`:

```
NAME="my-project"
mkdir -p "skills/$NAME/rules" "skills/$NAME/workflows" "skills/$NAME/references"
# ... generates SKILL.md, rule templates, workflow templates, Cursor entry, all thin shells
```

## Files in This Repo

| File | Content |
|------|---------|
| [SKILL.md](SKILL.md) | Skill entry: when to use, target structure, core principles |
| [WORKFLOW.md](WORKFLOW.md) | Migration guide: quick-start scaffold + full 8-phase process |
| [REFERENCE.md](REFERENCE.md) | Templates, thin shell patterns, anti-patterns, troubleshooting |
| [TEMPLATES.md](TEMPLATES.md) | Starter template + workflow templates (update-rules, fix-bug, maintain-docs) |
| [EXAMPLES.md](EXAMPLES.md) | 16 before/after scenarios covering migration, evolution, activation, edge cases |
| [skill.yaml](skill.yaml) | Machine-readable metadata |

## Compatibility

Works with **Cursor**, **Claude Code**, **Codex**, **Windsurf**, and **OpenClaw**.

## Core Principles

1. **SKILL.md is a router** — navigates, never exhausts; ≤100 lines
2. **One skill, one folder** — all formal docs under `skills/<name>/`, no scattering
3. **Rules ≠ Flows** — `rules/` for constraints, `workflows/` for procedures; never mix
4. **Thin shells with inline routing** — entry files embed routing tables that survive context summarization
5. **Description = trigger condition** — explicit activation phrases, not a passive summary
6. **Two-layer routing** — "Always Read" (2-3 files) + "Common Tasks" (task-specific reads)
7. **Task Closure Protocol** — AAR is part of task completion, not an optional extra
8. **Recording threshold** — 2/3 criteria (repeatable + costly + not obvious) before recording
9. **Generalization rule** — records must be reusable knowledge, not project-specific narratives
10. **Activation over storage** — pitfalls must appear in the task path, not just in reference files
11. **Self-maintaining** — line counts signal evaluation; split only when topics are truly separable
12. **Start minimal, grow structured** — use the minimal template first; upgrade when rules sprawl

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

## 中文

**[English](#skill-based-architecture)** | 中文

> 一个 meta-skill，用于将过长的单文件 Skill 或散落各处的项目规则，重构为结构清晰的 `skills/<name>/` 目录，让 Agent 高效导航。

---

## 解决什么问题

| 现状 | 痛点 |
|------|------|
| 单个 SKILL.md 超过 400 行 | Agent 每次任务都读一遍，浪费 token，难以维护 |
| 规则散落在 AGENTS.md、.cursor/rules/、CLAUDE.md 等多处 | 重复、不一致，不知道以哪个为准 |
| 规则只增不减 | 文档越来越臃肿，有用规则被废弃规则淹没 |
| Skill 从不触发 | description 是被动摘要而非明确触发条件 |
| 踩坑经验埋在文档深处 | Agent 执行任务时根本不会读到 |
| Agent 跳过复盘 | AAR 被当成可选步骤，而非任务完成的一部分 |
| 记录太项目化 | 教训写成项目叙事而非可复用知识 |

## 目录结构

```
skills/<name>/
├── SKILL.md          # ≤100 行：必读列表 + 任务路由
├── rules/            # 长期约束（始终成立的规则）
├── workflows/        # 步骤化流程（怎么做一件事）
├── references/       # 背景资料：架构、坑点、索引
│   └── gotchas.md    # 已知坑点 —— 通常是价值最高的内容
└── docs/             # 可选：提示词、报告、对外文档
```

## 如何使用

### 方式一 —— 安装为 Cursor 用户级 Skill

克隆到 Cursor 的 skills 目录，在所有项目中都可用：

```bash
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  ~/.cursor/skills/skill-based-architecture
```

然后在任意项目中告诉 Cursor：

> "Use skill-based-architecture to refactor the project rules"

### 方式二 —— 安装为项目级 Skill

复制到项目的 skill 目录：

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

激活后，Agent 可以为你的项目生成完整目录结构。让它运行 `WORKFLOW.md` 中的 Quick Start：

```bash
NAME="my-project"
mkdir -p "skills/$NAME/rules" "skills/$NAME/workflows" "skills/$NAME/references"
# ... 自动生成 SKILL.md、规则模板、工作流模板、Cursor 注册入口、所有薄壳文件
```

## 文件说明

| 文件 | 内容 |
|------|------|
| [SKILL.md](SKILL.md) | Skill 入口：使用时机、目标结构、核心原则 |
| [WORKFLOW.md](WORKFLOW.md) | 迁移指南：快速脚手架 + 完整 8 阶段流程 |
| [REFERENCE.md](REFERENCE.md) | 模板、薄壳模式、反模式、故障排查 |
| [TEMPLATES.md](TEMPLATES.md) | 起步模板 + 工作流模板（update-rules、fix-bug、maintain-docs） |
| [EXAMPLES.md](EXAMPLES.md) | 16 个前后对比案例，覆盖迁移、进化、激活、边界场景 |
| [skill.yaml](skill.yaml) | 机器可读的元数据 |

## 兼容性

支持 **Cursor**、**Claude Code**、**Codex**、**Windsurf** 和 **OpenClaw**。

## 核心原则

1. **SKILL.md 是路由器** —— 只做导航，≤100 行
2. **一个 Skill 一个文件夹** —— 正式文档都在 `skills/<name>/`，不散落
3. **规则 ≠ 流程** —— `rules/` 放约束，`workflows/` 放步骤，不混用
4. **薄壳含内联路由表** —— 入口文件嵌入路由表，对抗上下文压缩
5. **Description = 触发条件** —— 写明确的触发短语，不写被动摘要
6. **两层路由** —— Always Read（2-3 个文件）+ Common Tasks（按任务路由）
7. **Task Closure Protocol** —— AAR 是任务完成的门槛，不是可选附加
8. **录入标准** —— 可重复 + 代价高 + 代码不可见，至少 2/3 才录入
9. **泛化规则** —— 记录必须是可复用知识，不是项目叙事
10. **激活优于存储** —— 陷阱必须出现在任务路径上，不能只埋在 references/
11. **自维护** —— 行数超标触发评估，话题可分离才拆分
12. **从小开始，按需扩展** —— 先用最小模板，规则膨胀时再升级
