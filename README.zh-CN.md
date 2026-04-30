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

[English](README.md) | **中文**

> 一个**把散落的 AI Agent 规则整理成项目 skill 的 meta-skill**。它会审计 `AGENTS.md`、`CLAUDE.md`、`.cursor/rules/`、README 注记和本地流程文档，把长期规则、可复用流程、高代价踩坑统一沉淀到 `skills/<name>/`。

**产物不是另一份 README，而是一套项目规则系统。** `SKILL.md` 负责按任务路由；`rules/` 放稳定约束；`workflows/` 放操作流程；`references/` 放架构背景和坑点。各工具入口文件只保留薄壳路由和兼容说明，不再复制规则正文。

```
散落的项目规则
AGENTS.md / CLAUDE.md / .cursor/rules / README 注记
        │
        ▼
skill-based-architecture  (meta-skill)
        │
        ▼
skills/<project>/
├── SKILL.md          # 路由器: Always Read + Common Tasks
├── rules/            # 稳定约束
├── workflows/        # 可复用流程
├── references/       # 架构、坑点、索引
└── docs/             # 可选报告和提示词

工具入口文件
AGENTS.md / CLAUDE.md / CODEX.md / GEMINI.md / .cursor/rules / .codex
        └── 薄壳: 路由到 skills/<project>/, 不复制规则正文
```

## 为什么需要这个

AI 编程 Agent（Cursor、Claude Code、Codex、Windsurf、OpenCode 等）依赖项目文档来理解规则、约定和工作流。但随着项目增长，文档不可避免地变成一团乱麻：

| 现状 | 实际后果 |
|------|---------|
| 单个 SKILL.md 超过 400 行 | Agent 每次任务都读**全部内容** —— 浪费 token、拖慢响应、难以维护 |
| 规则散落在 AGENTS.md、.cursor/rules/、CLAUDE.md 等多处 | 内容重复、规则矛盾、不知道以哪个为准 |
| 规则只增不减 | 有用规则被废弃规则淹没，Agent 无法区分重要内容 |
| Skill 激活不稳定 | description 是被动摘要而非明确触发条件 |
| 踩坑经验埋在文档深处 | 高代价的坑（30+ 分钟调试）在任务执行时根本不会被读到 |
| Agent 跳过复盘 | 工作中发现的教训丢失，同样的错误反复发生 |
| 记录太项目化 | 教训写成项目叙事而非可复用、可迁移的知识 |

**结果：** Agent 浪费上下文读无关文档、漏掉关键规则、重复已知错误、产出不一致。

## 解决什么问题

Skill-Based Architecture 提供了一套 AI Agent 文档的**结构化模式**：

1. **最小化 token 浪费** —— Agent 每次任务只读 2-3 个核心文件，而非全部
2. **消除重复** —— 每条规则只有一个权威来源，其他位置全部是薄壳
3. **按任务路由** —— "Common Tasks" 路由表指引 Agent 到精确的文件
4. **稳定捕获经验** —— 内置复盘流程（AAR）配合录入门槛
5. **自维护** —— 健康检查、拆分/合并流程、废弃工作流保持文档精简
6. **跨 harness 兼容** —— 支持 Cursor、Claude Code、Codex、Windsurf、Gemini、OpenCode 和基于 AGENTS.md 的工具

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

根目录入口文件（`AGENTS.md`、`CLAUDE.md`、`CODEX.md`、`GEMINI.md`、`.cursor/rules/*.mdc`、`.codex/`）变为**薄壳** —— 只放内联路由和指向正式 Skill 的指针，不复制规则正文。

---

## 核心特性

### 两层路由

`SKILL.md` 保留一份生成的短 **Always Read** 列表，再用生成的 **Common Tasks** 摘要按任务追加需要读取的文件，避免每次都把全部文档塞给 Agent。下游项目里，`routing.yaml` 是 Always Read、Common Tasks、触发示例、必读文件、workflow 和薄壳 bootstrap 的可编辑单一事实源。

### 薄壳含 routing.yaml bootstrap

每个入口文件只嵌入一段短 bootstrap：告诉 Agent 去读 `routing.yaml`，并按 `labels` / `trigger_examples` 匹配任务。完整路由数据不再复制到每个薄壳里。

### Description = 触发条件

`description` 字段决定 Agent 会不会激活这个 Skill。它应该描述**领域边界 / 意图簇**，并使用用户真实会说的短语，例如 `"this endpoint is failing"` 和 `"这个接口报错了"`。不要把每个 workflow 都塞进 description；激活之后的任务级路由交给 `SKILL.md` Common Tasks。`check-description-routing.sh` 会检查明显过宽的 description 和多 skill 触发短语重叠。

### 会话纪律（Session Discipline）

同一会话中的每个新任务——哪怕是第二个、第三个任务——都必须重新读 SKILL.md、重新匹配 `routing.yaml` 中的路由、重新读该路由要求的所有文件。

这样可以避免 `/compact`、`/clear` 或长会话之后继续拿残缺记忆做事。

### 任务闭环和新鲜度检查

非平凡任务结束前做一次短复盘：确认工作已验证，判断是否有可重复、高代价、代码里看不出的经验需要记录，也检查是否有规则已经过时。文档改动还要跑 description 路由、链接、孤立引用、交叉引用和外部事实新鲜度检查。

---

## 什么时候不该用这个

不是所有项目都需要这套结构。以下场景可以先不迁移：

- **短期个人项目（少于 2 周）** —— 没有反复任务，也没有值得沉淀的规则
- **规则总量少于 50 行** —— 一个 `CLAUDE.md`、`AGENTS.md` 或 `.cursor/rules/workflow.mdc` 就够
- **只使用单一 harness** —— 不需要跨工具兼容
- **没有团队共享需求** —— 只有你自己使用 AI Agent，且项目足够小

这些场景可以先用普通入口文件；项目增长后再按 [WORKFLOW.md](WORKFLOW.md) 的 Quick Start 迁移。

---

## 如何使用

### 第一步 —— 拉取到本地

选择一个 Agent 能读到的位置。无论使用哪种工具，流程都一样：先把这个 meta-skill 放到本地，再到目标项目里触发。

| 使用场景 | 拉取位置 |
|---|---|
| Cursor 用户级 Skill | `~/.cursor/skills/skill-based-architecture` |
| Cursor 项目级 Skill | `.cursor/skills/skill-based-architecture` |
| Claude Code / Codex / Gemini / Windsurf / 基于 AGENTS.md 的工具 | 目标项目内的 `skills/skill-based-architecture`，或目标项目旁边的 `../skill-based-architecture` |

```bash
# Cursor 用户级安装
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  ~/.cursor/skills/skill-based-architecture

# Cursor 项目级安装
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  .cursor/skills/skill-based-architecture

# 通用项目内安装
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  skills/skill-based-architecture
```

如果你的 Agent 不会自动发现 skill，就在 `AGENTS.md`、`CLAUDE.md`、`CODEX.md`、`GEMINI.md` 或对应入口文件里加一个短指针：

```md
规则重构任务请使用 `skills/skill-based-architecture/` 中的 skill。
先读 `skills/skill-based-architecture/SKILL.md`。
```

如果你把仓库拉在目标项目旁边，就把路径换成 `../skill-based-architecture/SKILL.md`。

### 第二步 —— 在目标项目里触发

在目标项目中，让 Agent 使用本地 meta-skill：

> "Use skill-based-architecture to refactor the project rules"

也可以使用这些等价触发短语：

- "整理项目规则"
- "把规则重构成 skill-based architecture"
- "清理散乱的文档"
- "把规则整合到 skills 目录"
- "迁移规则到 skills/"

### 快速脚手架

激活后，Agent 会从 [`templates/`](templates/) 复制脚手架到 `skills/<name>/`，创建薄壳，填写所有 `<!-- FILL: -->` 标记，并运行验证。完整命令放在 [WORKFLOW.md Quick Start](WORKFLOW.md#quick-start-copy-dont-generate)。

### 预制模板目录

[`templates/`](templates/) 是 skill 文件、薄壳、hooks、脚本和协议块的复制来源。复制这些文件，不要让 Agent 临场生成。模板地图见 [`templates/README.md`](templates/README.md)，哪些内容不应该预制见 [`templates/ANTI-TEMPLATES.md`](templates/ANTI-TEMPLATES.md)。

---

## 触发后会发生什么

README 只保留操作轮廓。完整迁移清单放在 [WORKFLOW.md](WORKFLOW.md)。

1. **审计现有规则来源** —— 找出 `AGENTS.md`、`CLAUDE.md`、`.cursor/rules/`、README 注记和现有 docs。
2. **创建项目 skill** —— 把脚手架复制到 `skills/<name>/`，再用项目证据填写 `SKILL.md`、`rules/`、`workflows/` 和 `references/`。
3. **接入工具入口** —— 为你实际使用的工具创建薄壳，规则正文仍然只放在 `skills/<name>/`。
4. **验证** —— 运行复制过去的脚本，检查结构、路由、占位符、链接、孤立引用和外部事实新鲜度。

真正执行迁移时看完整的 [WORKFLOW.md](WORKFLOW.md)；README 只作为快速理解入口。

---

## 扩展这个 Skill

第一次迁移完成后，继续扩展项目 skill 时也保持“通过路由增长”，不要把规则正文复制到更多地方：

- 增加项目自己的 workflow，例如 `plan.md`、`review.md`、`deploy-check.md`。
- 某个子任务天然适合另一个 skill 时，在 workflow 里调用它。
- 同一个纪律问题反复出现时，再加入可复用的 protocol block。
- 新增反复任务时，只在 `routing.yaml` 里加一个 task，再运行 `scripts/sync-routing.sh`。
- 当这个上游项目更新时，直接让 agent “从上游更新一下”；它应按 `workflows/update-upstream.md` 拉取 GitHub 上游、自己比较并打补丁，同时保留下游项目规则。

---

## 工具兼容性

<!-- external-fact: verified=2026-04-28 source=https://docs.cursor.com/en/context -->
<!-- external-fact: verified=2026-04-28 source=https://code.claude.com/docs/en/skills -->
<!-- external-fact: verified=2026-04-28 source=https://developers.openai.com/codex/guides/agents-md -->
<!-- external-fact: verified=2026-04-28 source=https://docs.windsurf.com/windsurf/cascade/memories -->
<!-- external-fact: verified=2026-04-28 source=https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md -->
<!-- external-fact: verified=2026-04-28 source=https://opencode.ai/docs/rules/ -->

| 工具 | 发现机制 | 必需入口 | 需要内联路由？ |
|---|---|---|---|
| **Cursor** | 本脚手架使用 `.cursor/skills/` 作为项目 skill 注册入口 | `.cursor/skills/<name>/SKILL.md` | 是 |
| **Cursor rules** | `.cursor/rules/*.mdc` | `.cursor/rules/workflow.mdc` | 是 |
| **Claude Code** | 读取根目录 `CLAUDE.md`；原生 skills 扫描 `.claude/skills/`，同名优先级为 enterprise > personal > project | `CLAUDE.md`；可选 `.claude/skills/<project-name>/SKILL.md` 薄注册入口 | 是 |
| **Codex CLI** | 读取 `AGENTS.md` 层级；`AGENTS.override.md` 可覆盖项目指导 | `AGENTS.md`；`CODEX.md` / `.codex/instructions.md` 只作为你的 harness 会读取时的兼容镜像 | 是 |
| **Windsurf** | 读取 workspace memories/rules，例如 `.windsurf/rules/`；也可从 `AGENTS.md` 推断 memories | `.windsurf/rules/*.md` 或共享 `AGENTS.md` 薄壳 | 是 |
| **Gemini CLI** | 读取仓库根目录 `GEMINI.md`（+ 父/子目录） | `GEMINI.md` | 是 |
| **OpenCode** | 读取 `AGENTS.md` | `AGENTS.md` 共享薄壳 | 是 |
| **其他 Agent** | 读取 `AGENTS.md` | `AGENTS.md` | 是 |

Claude Code 原生 skill 要避免使用 `review`、`fix-bug` 这类泛名：如果用户的 `~/.claude/skills/` 下有同名 skill，会覆盖项目 `.claude/skills/` 下的同名 skill。项目根目录的 `skills/<name>/` 仍然通过 `CLAUDE.md` 和可选 SessionStart 路由作为正式来源。

---

## 文件说明

| 文件 | 内容 |
|------|------|
| [SKILL.md](SKILL.md) | Skill 入口：使用时机、目标结构和核心原则 |
| [WORKFLOW.md](WORKFLOW.md) | 迁移指南：决策树、快速脚手架、完整 9 阶段流程、增量迁移 |
| [REFERENCE.md](REFERENCE.md) | 存根 + 索引 — 指向 [`references/`](references/) |
| [references/](references/) | 布局、薄壳、协议、约定、多 skill 路由、skill 组合、自托管路由 |
| [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) | 模板族和 Task Closure Protocol 的注释指南 |
| [templates/](templates/) | 下游项目复制使用的字节级脚手架文件 |
| [EXAMPLES.md](EXAMPLES.md) | 存根 + 索引 — 指向 [`examples/`](examples/) |
| [examples/](examples/) | migration、project-types、self-evolution、behavior-failures 示例 |
| [skill.yaml](skill.yaml) | 机器可读的元数据 |

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
录入门槛（2/3：可重复 + 代价高 + 代码不可见）过滤低价值记录。`update-rules.md` 中的废弃工作流移除过时规则。`maintain-docs.md`、`check-description-routing.sh`、引用审计、交叉引用检查和 `check-external-facts.sh` 捕获超大文件、模糊触发、孤立引用、失效链接和过期外部事实。

**Q: 下游项目如何接收上游改进？**
直接让 agent 从上游更新。复制到下游的 `workflows/update-upstream.md` 内置 GitHub 上游地址，要求 agent 临时 clone 最新上游、自己比较文件、把有价值的机制改动 patch 进本地，并保留项目自己的规则和坑点。

---

## 社区支持

学 AI,上 L 站 — [LinuxDO](https://linux.do/)

---

## Star History

<a href="https://www.star-history.com/?repos=WoJiSama%2Fskill-based-architecture&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&legend=top-left" />
 </picture>
</a>
