# Skill-Based Architecture

[English](README.md) | **中文**

> 一个**生产 skill 的 meta-skill**。把它对准任何代码库，它会把这个项目的规则、流程、踩坑经验**炼化**进一个专属的 `skills/<name>/` 目录 —— 一个**项目 skill**,成为所有 AI Agent(Cursor、Claude Code、Codex、Windsurf、Gemini)在每次任务前查阅的唯一权威来源。

**重点是产物本身。** 你得到的不是一个更整洁的文档文件夹,而是 **最懂你这个项目的那个 skill**:可路由、可自维护、能自动捕获经验、匹配任务时自动触发。

```
你的项目  ──►  skill-based-architecture  ──►  skills/<你的项目>/   ◄── 最懂这个项目的 skill
                    (meta-skill)               ├── SKILL.md   (路由器,≤100 行)
                                                ├── rules/     (始终成立的约束)
                                                ├── workflows/ (怎么做一件事)
                                                └── references/gotchas.md  (高代价的坑)
```

---

## 社区支持

学 AI,上 L 站 — [LinuxDO](https://linux.do/)

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

## 本 skill 在哪个坐标系里 —— Prompt / Context / Harness

Agent 稳定性分三层。**本 skill 不是银弹**——它只覆盖其中**一层半**，明确讲清楚可以防止误用：

| 层 | 解决什么 | 本 skill 的角色 |
|---|---|---|
| **Prompt** | 怎么把任务说清楚 | 间接——通过 `description` 作为触发条件 |
| **Context** | 怎么把信息递到模型 | **主战场**——路由、Always Read、薄壳、渐进披露 |
| **Harness** | 系统在真实执行中怎么稳住 | **部分覆盖**——会话纪律 + Rationalizations Table + 可选 SessionStart hook = 针对*长会话上下文重注入*的最小 harness |

**当 Agent 感觉"调不稳"时，根因很少是模型。** 先跑四原语体检：系统有没有 **state**（状态标记）、**validation**（节点校验）、**orchestration**（编排与检查点）、**recovery**（失败恢复）？三条"没有"就是 harness 问题，不是模型问题——调 prompt 救不回来。

本 skill **不覆盖**：工具调用执行恢复、长链路断点续跑、多 Agent 编排——这些属于各项目自己的工程工作，应该写进**各项目自己的** `rules/` 或 `workflows/`，**不要**塞进本 meta-skill 的 `templates/`。完整讨论与越界清单见 [references/layout.md § Positioning](references/layout.md#positioning-prompt--context--harness)。

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

### 会话纪律（Session Discipline）

同一会话中的每个新任务——哪怕是第二个、第三个任务——都必须重新读 SKILL.md、重新匹配常见任务路由表、重新读该路由要求的所有文件。

> "我刚才已经读过了"不是跳过的理由。上下文会被静默压缩；新任务可能匹配不同的路由；部分记忆比没有记忆更危险。重读只需几秒，跳过则可能浪费数小时的错误方向工作。

该规则在三个层面强制执行：SKILL.md 本身、每个工作流的硬性前置步骤、以及所有薄壳中嵌入的重读触发器（上下文压缩后的最后防线）。

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

### 基于 Checkpoint 的迁移恢复

9 阶段迁移可能半路崩溃 —— `/compact` 触发、shell 在 `sed` 中途退出、笔记本重启。此时"从 Phase 1 重跑一遍"**会放大污染**:Phase 5 残留的 `{{NAME}}` 占位符 Phase 3 的 rerun 看不到,导致后续 Phase 8 在一个破损的树上假性通过。

恢复机制(详见 [WORKFLOW.md § Resuming From a Failed Phase](WORKFLOW.md#resuming-from-a-failed-phase)):

- **`.migration-state`** —— 单行 checkpoint 文件(`phase=N`),每个 phase 通过自己的 per-phase 校验后写入
- **Per-phase 校验** —— `bash smoke-test.sh <name> --phase N` 只跑 Phase N 关心的子集,让中途校验真正有意义(不是只在最后一刀切)
- **`templates/migration/resume.sh`** —— 一条命令自动探测当前 phase(读 checkpoint 或按 artifact 签名反推),警告占位符残留,打印下一步

三者合起来把 [references/layout.md § Positioning — Prompt / Context / Harness](references/layout.md#positioning-prompt--context--harness) 点出的 state / validation / recovery 缺口补上。

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
- `templates/skill/scripts/` → `smoke-test.sh`（48 项自动化核查）+ `test-trigger.sh`（description 触发率测试）—— 脚手架步骤自动复制到 `skills/<name>/scripts/`
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
| 规则 > 150 行且跨文件重复 | **完整 9 阶段迁移** |

### 完整迁移（9 阶段）

| 阶段 | 做什么 |
|------|--------|
| **1. 审计** | 盘点所有规则来源 |
| **2. 设计** | 根据项目规模规划文件集 |
| **3. 编写 SKILL.md** | 创建 <= 100 行的入口 |
| **4. 提取规则** | 稳定约束移入 `rules/` |
| **5. 提取工作流** | 创建专用工作流文件 + 必需的元工作流 |
| **6. 提取引用** | 架构概述、坑点、索引移入 `references/` |
| **7. 创建入口** | Cursor 注册入口 + 所有工具的薄壳（含内联路由表） |
| **8. 验证** | 运行自动化 `smoke-test.sh`（48 项核查）—— 结构、路由、占位符、激活、description 质量 |
| **9. 压力测试** | 向子 agent 施加时间/沉没成本/权威压力，将逐字合理化借口折叠入 Rationalizations 表 |

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
| 7 | **会话纪律** | 同一会话的每个新任务都必须重读 SKILL.md 并重匹配路由；"我刚才读过了"不成立 |
| 8 | **Task Closure Protocol** | AAR 是任务完成的门槛，不是可选附加 |
| 9 | **录入标准** | 可重复 + 代价高 + 代码不可见，至少 2/3 才录入 |
| 10 | **泛化规则** | 记录必须是可复用知识，不是项目叙事 |
| 11 | **激活优于存储** | 陷阱必须出现在任务路径上，不能只埋在 references/ |
| 12 | **自维护** | 行数超标触发评估，话题可分离才拆分 |
| 13 | **从小开始，按需扩展** | 先用最小模板，规则膨胀时再升级 |

---

## 文件说明

| 文件 | 内容 |
|------|------|
| [SKILL.md](SKILL.md) | Skill 入口：使用时机、目标结构、核心原则、常见陷阱 |
| [WORKFLOW.md](WORKFLOW.md) | 迁移指南：决策树、快速脚手架、完整 9 阶段流程、增量迁移 |
| [REFERENCE.md](REFERENCE.md) | 存根 + 索引 — 指向 [`references/`](references/) 下按主题拆分的四份文件 |
| [references/](references/) | 布局、薄壳、协议、约定 — 按主题拆分为四份文件 |
| [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) | 起步模板 + 元工作流模板（update-rules、fix-bug、maintain-docs） |
| [EXAMPLES.md](EXAMPLES.md) | 存根 + 索引 — 指向 [`examples/`](examples/) 下按主题拆分的三份文件 |
| [examples/](examples/) | 16 个前后对比案例，按主题（migration / project-types / self-evolution）拆分 |
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
| **多任务会话路由跳过** | Agent 为第一个任务读 SKILL.md，第二个任务跳过（"我已经知道规则了"），用残缺记忆工作数小时 | SKILL.md 中的会话纪律规则 + 所有薄壳中的重读触发器 |
| **记录太项目化** | 脱离当前上下文就无用 | 录入前应用泛化规则 |

---

## 版本历史

当前版本：**v1.12**

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
| v1.12 | 会话纪律（同一会话每个新任务必须重读 SKILL.md）；自动化 `smoke-test.sh`（48 项）+ `test-trigger.sh` 放入 `templates/skill/scripts/`；迁移工作流新增第 9 阶段压力测试 |

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
