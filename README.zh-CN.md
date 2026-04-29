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

---

## 不只是一个 skill —— 是可以继续搭的框架

这个 meta-skill 生成的 `skills/<name>/` 目录不是一份平铺的文档，而是**你可以继续扩展的框架**。脚手架本身就留好了组合点：

- **写你自己的 workflows。** `workflows/` 是你的。加 `plan.md`、`review.md`、`deploy-check.md` —— 你项目里真正反复出现的任务都可以有独立文件。每个 workflow 把 Agent 路由到它真正需要的文件，带完成清单和停止条件。

- **在 workflows 里调用其他 skill。** 一个 workflow 可以在执行中途委托给另一个 skill。比如 `workflows/plan.md` 可以让 Agent 在做规划时调用 [obra/superpowers](https://github.com/obra/superpowers) 的 planning skill；或者在 `workflows/fix-bug.md` 里调用领域相关的测试 skill。你的项目 skill 就变成了**编排层**，不是终点。

- **组合 protocol-blocks。** `protocol-blocks/` 以可复用模块提供 —— 哪个 workflow 容易松懈就放 `rationalizations-table.md`；哪个路由模糊动词多就放 `ambiguous-request-gate.md`；哪个长任务中途可能迷路就放 `reboot-check.md`。自己写的块也按同样方式嵌入。

- **路由可演化，不用动架构。** 新增一类反复任务 = 给 `SKILL.md` Common Tasks 加一行 + 给 shell 加一行 + 写对应 workflow。没有重构，没有迁移。

- **可持续往上长。** Hooks（SessionStart、PreToolUse 闸）、行为默认、新规则文件、新 references —— 都能顺 `WORKFLOW.md § Upgrading` 传递。这套 skill 是**会一起长大的活系统**，跟项目同步演化。

一句话：产物不是"一份 skill 文件"，是**一套项目作用域的 skill 操作系统**，你和你的 agent 可以继续往上搭。新增规则和流程会通过各工具支持的入口路径被路由到，而不是把同一段规则复制进每个工具文件。

---

## 本 skill 在哪个坐标系里 —— Prompt / Context / Harness

Agent 稳定性分三层。**本 skill 不是银弹**——它只覆盖其中**一层半**，明确讲清楚可以防止误用：

| 层 | 解决什么 | 本 skill 的角色 |
|---|---|---|
| **Prompt** | 怎么把任务说清楚 | 间接——通过 `description` 作为触发条件 |
| **Context** | 怎么把信息递到模型 | **主战场**——路由、Always Read、薄壳、渐进披露 |
| **Harness** | 系统在真实执行中怎么稳住 | **部分覆盖**——会话纪律 + Rationalizations Table + 可选 SessionStart hook = 针对*长会话上下文重注入*的最小 harness |

**当 Agent 感觉"调不稳"时，根因很少是模型。** 先跑四原语体检：系统有没有 **state**（状态标记）、**validation**（节点校验）、**orchestration**（编排与检查点）、**recovery**（失败恢复）？三条"没有"就是 harness 问题，不是模型问题——调 prompt 救不回来。

本 skill **不覆盖**：通用工具调用执行恢复、迁移脚手架之外的任意长链路断点续跑、多 Agent 编排——这些属于各项目自己的工程工作，应该写进**各项目自己的** `rules/` 或 `workflows/`，**不要**塞进本 meta-skill 的 `templates/`。完整讨论与越界清单见 [references/layout.md § Positioning](references/layout.md#positioning-prompt--context--harness)。

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

根目录入口文件（`AGENTS.md`、`CLAUDE.md`、`CODEX.md`、`GEMINI.md`、`.cursor/rules/*.mdc`、`.codex/`）变为**薄壳** —— 只放内联路由和指向正式 Skill 的指针，不复制规则正文。

---

## 核心特性

### 两层路由

SKILL.md 使用两层系统，而非把所有文档一股脑塞给 Agent：

- **Always Read**（2-3 个短文件）—— 每个任务都加载
- **Common Tasks**（按任务路由）—— Agent 只读当前任务列出的文件

### 薄壳含内联路由表

每个入口文件都嵌入**路由表** —— 不只是"去读 SKILL.md"。这在长对话中上下文被压缩时依然有效。

### Description = 触发条件

`description` 字段不是被动描述 —— 它决定 Agent 在运行时是否激活这个 Skill。

触发短语要使用用户真实会说的语言。如果团队主要用中文提需求，就应该在 `description` 里写中文短语，而不是只写英文后假设 Agent 每次都会准确翻译匹配。

### 会话纪律（Session Discipline）

同一会话中的每个新任务——哪怕是第二个、第三个任务——都必须重新读 SKILL.md、重新匹配常见任务路由表、重新读该路由要求的所有文件。

> "我刚才已经读过了"不是跳过的理由。上下文会被静默压缩；新任务可能匹配不同的路由；部分记忆比没有记忆更危险。重读只需几秒，跳过则可能浪费数小时的错误方向工作。

该规则在三个层面强制执行：SKILL.md 本身、每个工作流的硬性前置步骤、以及所有薄壳中嵌入的重读触发器（上下文压缩后的最后防线）。

### Task Closure Protocol

每个非平凡任务在完成前必须执行 30 秒复盘：

1. **主要工作完成** —— 实现已验证
2. **AAR 扫描** —— 检查：新模式？新坑？缺失规则？过时规则？外部事实？
3. **按需记录** —— 满足录入门槛（2/3：可重复 + 代价高 + 代码不可见）才记录

如果本次改的是文档或规则，闭环还要跑对应完整性门槛：链接检查、入站 orphan 检查、交叉引用复核，以及针对易变供应商/工具/运行时事实的 `external-fact` 新鲜度检查。

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

### 自维护

内置机制防止文档随时间腐化：

- **文件健康检查** —— 用参考范围触发评估，不把行数当硬规则
- **按需拆分** —— 只有话题真的可分离时才拆
- **碎片合并** —— 合并属于同一主题的小文件
- **规则废弃** —— 用明确流程删除过时规则
- **引用完整性** —— 重命名、拆分、删除后检查链接和入站引用
- **外部事实新鲜度** —— 对供应商/工具/运行时事实加验证日期并检查是否过期

### 激活优于存储

仅记录在 `references/` 的高代价坑点**不算完全捕获** —— 还必须出现在任务执行路径上（工作流检查清单、SKILL.md 路由、或精简规则）。

### 行为生效信号

Skill 是否真的生效，不只看文件是否齐全，还要看 Agent 行为是否变化：

- 模糊请求会先澄清范围和成功标准，而不是直接扫描或开改
- diff 保持精准，没有顺手格式化、重命名或重构
- 实现先保持简单，只有真实压力出现时才加结构
- 完成时引用具体检查，而不是说"看起来可以"或"应该没问题"

如果真实任务里长期看不到这些信号，不要继续堆规则正文。把这次 miss 记录成 behavior failure，并把修复点放回对应任务路径。

### 基于 Checkpoint 的迁移恢复

9 阶段迁移可能半路崩溃 —— `/compact` 触发、shell 在 `sed` 中途退出、笔记本重启。此时"从 Phase 1 重跑一遍"**会放大污染**:Phase 5 残留的 `{{NAME}}` 占位符 Phase 3 的 rerun 看不到,导致后续 Phase 8 在一个破损的树上假性通过。

恢复机制(详见 [WORKFLOW.md § Resuming From a Failed Phase](WORKFLOW.md#resuming-from-a-failed-phase)):

- **`.migration-state`** —— 单行 checkpoint 文件(`phase=N`),每个 phase 通过自己的 per-phase 校验后写入
- **Per-phase 校验** —— `bash smoke-test.sh <name> --phase N` 只跑 Phase N 关心的子集,让中途校验真正有意义(不是只在最后一刀切)
- **`templates/migration/resume.sh`** —— 一条命令自动探测当前 phase(读 checkpoint 或按 artifact 签名反推),警告占位符残留,打印下一步

三者合起来把 [references/layout.md § Positioning — Prompt / Context / Harness](references/layout.md#positioning-prompt--context--harness) 点出的 state / validation / recovery 缺口补上。

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

在填写项目特定内容前，Agent 应先询问你是否要围绕目标项目的用途、模块、常见任务、边界和已知坑点进行头脑风暴。如果你同意，Agent 必须先头脑风暴，再复述一份校准后的项目总结让你纠正，然后再用本地代码和配置验证这些反馈，最后才写入 `rules/`、`workflows/`、`references/` 或 `SKILL.md`。用户反馈用于校准分析；能否进入规则或工作流，取决于本地证据是否确认。

### 预制模板目录

[`templates/`](templates/) 是脚手架内容的唯一权威来源：

- `templates/skill/` → 复制为 `skills/<name>/`（SKILL.md、规则 stub、工作流正文、空的 gotchas 种子）
- `templates/skill/scripts/` → `smoke-test.sh`、`test-trigger.sh`、`check-cross-references.sh`、`check-external-facts.sh`、`audit-references.sh` —— 脚手架步骤自动复制到 `skills/<name>/scripts/`
- `templates/shells/` → 所有 harness 的薄壳（AGENTS、CLAUDE、CODEX、GEMINI、`.codex/`、`.cursor/`）
- `templates/hooks/` → 可选的 `SessionStart` hook，在 `/clear` 和 `/compact` 时重新注入一个 router
- `templates/protocol-blocks/` → Task Closure Protocol 强化块（Rationalizations 表、Red Flags、Iron Law 标题）

**复制而不是再生**——Agent 在压力场景下会漏段落。详见 [`templates/README.md`](templates/README.md) 的字节预算和"两个真实项目会不同意吗"准入测试，以及 [`templates/ANTI-TEMPLATES.md`](templates/ANTI-TEMPLATES.md) 中**拒绝预制**的内容清单。

---

## 触发后会发生什么

README 只保留操作轮廓。完整迁移清单放在 [WORKFLOW.md](WORKFLOW.md)。

1. **审计现有规则来源** —— 找出 `AGENTS.md`、`CLAUDE.md`、`.cursor/rules/`、README 注记和现有 docs。
2. **创建项目 skill** —— 把脚手架复制到 `skills/<name>/`，再用项目证据填写 `SKILL.md`、`rules/`、`workflows/` 和 `references/`。
3. **接入工具入口** —— 为你实际使用的工具创建薄壳，规则正文仍然只放在 `skills/<name>/`。
4. **验证** —— 运行复制过去的脚本，检查结构、路由、占位符、链接、孤立引用和外部事实新鲜度。

真正执行迁移时看完整的 [WORKFLOW.md](WORKFLOW.md)；README 只作为快速理解入口。

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

## 记录去向指南

当用户说"记录一下"或"记住这个"时，Agent 需要先判断应该写到哪里。很多工具都有自己的 memory 系统，这会和项目 skill 的文档结构竞争。

**判断问题：** "另一个 Agent 或项目成员会从这条记录中受益吗？"

| 答案 | 去向 | 示例 |
|---|---|---|
| **会** | `skills/<name>/references/`、`rules/` 或 `workflows/` | 技术模式、项目约定、踩坑经验 |
| **不会** | Agent 自己的 memory 系统 | 个人偏好、沟通风格 |

默认写入 skill 文档。开发过程中的大多数"记录一下"都是技术性的、项目作用域的知识。

---

## 项目类型示例

### Java / Spring Boot

```text
skills/<name>/
├── SKILL.md
├── rules/
│   ├── project-rules.md
│   ├── coding-standards.md
│   └── backend-rules.md
├── workflows/
│   ├── add-controller.md
│   ├── fix-bug.md
│   ├── update-rules.md
│   └── maintain-docs.md
└── references/
    ├── architecture.md
    └── third-party-libs.md
```

### Frontend / React / Next.js

```text
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

### 多 Skill 项目

```text
skills/
├── app/
│   ├── SKILL.md
│   ├── rules/
│   └── workflows/
├── template-builder/
│   ├── SKILL.md
│   ├── rules/
│   └── workflows/
└── shared/
    └── coding-standards.md
```

---

## 核心原则

| # | 原则 | 含义 |
|---|------|------|
| 1 | **SKILL.md 是路由器** | 只做导航，不做穷举；<= 100 行 |
| 2 | **一个 Skill 一个文件夹** | 正式文档都在 `skills/<name>/`，不散落 |
| 3 | **规则 != 流程** | `rules/` 放约束，`workflows/` 放步骤，不混用 |
| 4 | **薄壳含内联路由表** | 入口文件嵌入路由表，对抗上下文压缩 |
| 5 | **Description = 触发条件** | 用用户真实语言写明确触发短语，不写被动摘要 |
| 6 | **两层路由** | Always Read（2-3 个文件）+ Common Tasks（按任务路由） |
| 7 | **会话纪律** | 同一会话的每个新任务都必须重读 SKILL.md 并重匹配路由；"我刚才读过了"不成立 |
| 8 | **Task Closure Protocol** | AAR 是任务完成的门槛，不是可选附加 |
| 9 | **录入标准** | 可重复 + 代价高 + 代码不可见，至少 2/3 才录入 |
| 10 | **泛化规则** | 记录必须是可复用知识，不是项目叙事 |
| 11 | **激活优于存储** | 陷阱必须出现在任务路径上，不能只埋在 references/ |
| 12 | **自维护** | 行数触发评估，链接/orphan/交叉引用/外部事实门槛防止腐化 |
| 13 | **从小开始，按需扩展** | 先用最小模板，规则膨胀时再升级 |

---

## 文件说明

| 文件 | 内容 |
|------|------|
| [SKILL.md](SKILL.md) | Skill 入口：使用时机、目标结构、核心原则、常见陷阱 |
| [WORKFLOW.md](WORKFLOW.md) | 迁移指南：决策树、快速脚手架、完整 9 阶段流程、增量迁移 |
| [REFERENCE.md](REFERENCE.md) | 存根 + 索引 — 指向 [`references/`](references/) |
| [references/](references/) | 布局、薄壳、协议、约定、多 skill 路由、skill 组合、自托管路由 |
| [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) | 模板族和 Task Closure Protocol 的注释指南 |
| [templates/](templates/) | 下游项目复制使用的字节级脚手架文件 |
| [EXAMPLES.md](EXAMPLES.md) | 存根 + 索引 — 指向 [`examples/`](examples/) |
| [examples/](examples/) | migration、project-types、self-evolution、behavior-failures 示例 |
| [skill.yaml](skill.yaml) | 机器可读的元数据 |

---

## 常见陷阱

| 陷阱 | 影响 | 修复 |
|------|------|------|
| **缺少 Cursor 注册入口** | Cursor 永远发现不了 Skill | 创建 `.cursor/skills/<name>/SKILL.md` |
| **薄壳只有软指针** | 长对话中上下文压缩后指令丢失 | 每个入口文件嵌入路由表 |
| **Description 太模糊 / 语言不匹配** | Skill 存在但 Agent 永远不激活 | 写足够具体，并包含 >= 2 个用户真实语言里的引用触发短语 |
| **存储但未激活** | 坑点在 references/ 但不在任何工作流中 | 同时在工作流检查清单或路由中呈现 |
| **跳过 Task Closure** | 教训未捕获，同样错误反复 | 把 AAR 作为完成门槛 |
| **多任务会话路由跳过** | Agent 为第一个任务读 SKILL.md，第二个任务跳过（"我已经知道规则了"），用残缺记忆工作数小时 | SKILL.md 中的会话纪律规则 + 所有薄壳中的重读触发器 |
| **记录太项目化** | 脱离当前上下文就无用 | 录入前应用泛化规则 |

---

## 反模式

| 反模式 | 为什么有害 | 修复 |
|---|---|---|
| 薄壳里放规则正文 | 两处都要维护，破坏单一事实源 | 薄壳只放路由、必读指针和兼容说明 |
| 把 SKILL.md 写成第二个 README | 上下文重复，超过 100 行预算 | README 放安装和概览，SKILL.md 只导航 |
| 规则和流程混写 | 检查清单难找，约束难更新 | `rules/` 放约束，`workflows/` 放步骤 |
| 超大子文件（500+ 行） | 把单文件问题搬到下一层 | 按子领域拆分 |
| 过度拆分（20 个十行文件） | 导航成本高于收益 | 合并相关文件，参考 50-200 行 |
| 什么都记录 | 低价值噪音让规则膨胀 | 使用 2/3 录入门槛 |

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
录入门槛（2/3：可重复 + 代价高 + 代码不可见）过滤低价值记录。`update-rules.md` 中的废弃工作流移除过时规则。`maintain-docs.md`、引用审计、交叉引用检查和 `check-external-facts.sh` 捕获超大文件、孤立引用、失效链接和过期外部事实。

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
