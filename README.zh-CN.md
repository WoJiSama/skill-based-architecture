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

<p align="center"><a href="README.md">English</a> | <strong>中文</strong></p>

一个**面向 AI Agent 规则系统的生命周期管理框架**。把散落的提示词文档(`AGENTS.md`、`CLAUDE.md`、`.cursor/rules/`、README 规则)整理成位于 `skills/<name>/` 下、可路由、可验证、可更新的工程资产。

它关注规则系统本身:结构、路由、workflow、校验、任务复盘、上游/下游更新。它**不**提供具体技术栈规则 —— 后端、前端、部署等内容应放在下游项目 skill 里。

## 安装

**Claude Code —— 一行装好:**

```text
/plugin marketplace add WoJiSama/skill-based-architecture
/plugin install skill-based-architecture@skill-based-architecture
```

然后[触发它](#quick-start);之后用 `/plugin marketplace update` 拉更新。

**不安装先体验:** 可以通过 ClawMama Skill catalog 在 [Telegram 或 WhatsApp 中运行 Skill Based Architecture](https://app.clawmama.run/skills/i78bb1/hermes?utm_source=github&utm_medium=issue&utm_campaign=skill_outreach_wojisama_skill_based_architecture)。建议配合[简单 demo 仓库](examples/simple-repo/)或其他非敏感规则文件使用;真实项目迁移仍建议在本地用 Claude Code 安装或 clone 仓库。

**Cursor / Codex / Gemini / 其他 harness** 不共享 Claude Code 的插件系统 —— 改用 clone(见 [Quick Start](#quick-start))。

## 产物形态

```
散落的项目规则
AGENTS.md / CLAUDE.md / .cursor/rules / README 注记
        │
        ▼
skills/<project>/
├── SKILL.md          # 路由器: description ≤ 25 + body ≤ 90 行(双预算)
├── rules/            # 稳定约束
├── workflows/        # 可复用流程
├── references/       # 架构、坑点、索引
└── docs/             # 可选报告和提示词

工具入口文件
AGENTS.md / CLAUDE.md / CODEX.md / GEMINI.md / .cursor/rules / .codex
        └── 薄壳: 路由到 skills/<project>/, 不复制规则正文
```

## 解决什么问题

| 现状 | 实际后果 |
|---|---|
| 单个 SKILL.md 超过 400 行 | Agent 每次任务都读全部 —— 浪费 token、隐藏关键内容 |
| 规则散落在 AGENTS.md / .cursor/rules/ / CLAUDE.md | 内容漂移、规则矛盾、无单一权威源 |
| Skill 激活不稳定 | description 是被动摘要而非明确触发条件 |
| 踩坑经验埋在文档深处 | 高代价的坑下次任务根本不会被读到 |
| 规则只增不减 | 有用规则被废弃规则淹没 |

架构对应回答:路由源 `routing.yaml`、其他位置全是薄壳、description 即触发条件、AAR + 记录阈值、line-count 信号触发拆分/合并。

## 不适用场景

- 总规则内容 < 50 行(单个 `CLAUDE.md` 就够)
- 单一 harness、不需要团队共享、没有重复任务
- 短命独立项目(< 2 周)

先用 `CLAUDE.md` 或 `.cursor/rules/workflow.mdc`,内容多了再迁移。[WORKFLOW.md](WORKFLOW.md) 有这种情况下的 Quick Start 升级路径。

## Quick Start

### 1. 把这个 meta-skill 拉到本地

**Claude Code:** 用[上面的一行安装](#安装)装好就行 —— 直接跳到第 2 步。

**Cursor / Codex / Gemini / 其他 harness:** 用**任何方式**(`git clone`、download zip、submodule、fork…)把这个仓库放到**任何位置** —— 唯一的要求是**你和 agent 都知道它在哪**。

只要 agent 在被触发时能定位到这个目录就行。如果它不在 agent 的默认搜索路径上(例如 Cursor 的 `~/.cursor/skills/`、`.cursor/skills/`,或项目内的 `skills/`),就在 `CLAUDE.md` / `AGENTS.md` / `.cursor/rules/` 里写一行,告诉 agent 路径在哪。

最常见的放置位置:

- 项目内:`skills/skill-based-architecture/`
- 项目并排:`../skill-based-architecture/`
- Cursor 用户级:`~/.cursor/skills/skill-based-architecture/`
- Cursor 项目级:`.cursor/skills/skill-based-architecture/`

示例(项目内 clone):

```bash
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  skills/skill-based-architecture
```

### 2. 在目标项目里触发

让 agent 使用本地 meta-skill:

> "用 skill-based-architecture 重构项目规则"

等价触发:"整理项目规则"、"把规则迁移到 skills 目录"、"organize the project rules"。

Agent 会从 [`templates/`](templates/) 复制预制 scaffold 到 `skills/<name>/`,创建薄壳,填充每一个 `<!-- FILL: -->` 标记,跑校验。完整流程:[WORKFLOW.md](WORKFLOW.md)。

想先安全试跑? 用 [`examples/simple-repo/`](examples/simple-repo/) 当目标项目输入。它是一个假的小项目,故意放了重复的 `AGENTS.md`、`CLAUDE.md`、Cursor 规则和 README notes,可以展示迁移效果,但不暴露私有代码。

### 3. (仅 Codex)手动触发 sub-agent / 并行处理

这个 meta-skill 的几条 workflow 会用到 sub-agent 委派和并行 agent 扇出(见 [`templates/skill/workflows/subagent-driven.md`](templates/skill/workflows/subagent-driven.md)、[`templates/skill/workflows/refactor-fanout.md`](templates/skill/workflows/refactor-fanout.md))。大多数 harness 里仓库内的规则足以让 agent 自己决定何时扇出,直接走默认就行。

**Codex 是例外。** 它的运行环境给 `spawn_agent` 工具加了一条工具级规则:**只有当用户明确要求 sub-agent、delegation 或并行 agent 工作时**,才允许调用 `spawn_agent`。这条工具级规则**优先级高于**仓库里的 `AGENTS.md` / skill 规则 —— 即使 workflow 文档里写了"用 sub-agent",扇出模式也**不会**自动触发。

在 Codex 里如果想让 sub-agent 真的被调起来 —— 不论是扇出还是别的场景 —— 都要**显式授权**。两种等价写法:

**按任务点名** —— 指明具体哪件事交给 sub-agent:

> "请使用 sub-agent 来重构这几个规则文件。"
> "用 sub-agent 并行 review 每个 workflow 文件。"
> "Use a sub-agent to scan the templates directory."

**整段会话放权** —— 在会话开头一次性放开:

> "在这个会话我允许你使用 sub-agent。"
> "本次会话需要扇出的步骤你可以随意起 sub-agent 委派。"
> "In this session you may use sub-agents whenever the workflow calls for it."

任一种说法都能让工具级规则放行。**少了这一句**,即使 workflow 文档里写了"用 sub-agent",Codex 也会静默跳过委派步骤。

## 关键特性

- **两层路由**:`SKILL.md` 维护一个生成的 **Always Read** 列表;**Common Tasks** 仅在需要时把 agent 路由到额外文件。下游用 `routing.yaml` 作可编辑的单一路由源。
- **薄壳 + 路由 bootstrap**:每个入口文件嵌入指向 `routing.yaml` 的短 bootstrap。路由表不在每个 shell 里复制 —— 自然语言指令在长会话压缩中会丢失。
- **description 即触发条件**:用用户实际语言的领域级激活短语,不是 workflow 关键字堆砌。改完后**朗读一遍** —— 听起来不像真用户就重写,脚本替代不了这件事。
- **Session Discipline + Task Closure**:同一 session 每个新任务重读 SKILL.md;非小任务以 30 秒 AAR + 记录阈值结束,不允许"测试通过=完成"。
- **自维护**:行数信号触发评估而非自动操作;split/merge 流程 + 新鲜度检查保持文档精简。
- **跨 harness**:Cursor、Claude Code、Codex、Windsurf、Gemini、OpenCode、AGENTS.md 类工具均兼容。

## 工具兼容

<!-- external-fact: verified=2026-04-28 source=https://docs.cursor.com/en/context -->
<!-- external-fact: verified=2026-04-28 source=https://code.claude.com/docs/en/skills -->
<!-- external-fact: verified=2026-04-28 source=https://developers.openai.com/codex/guides/agents-md -->
<!-- external-fact: verified=2026-04-28 source=https://docs.windsurf.com/windsurf/cascade/memories -->
<!-- external-fact: verified=2026-04-28 source=https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md -->
<!-- external-fact: verified=2026-04-28 source=https://opencode.ai/docs/rules/ -->

| 工具 | 必需入口 |
|---|---|
| **Cursor** | `.cursor/skills/<name>/SKILL.md` + `.cursor/rules/*.mdc` |
| **Claude Code** | `CLAUDE.md`(可选 `.claude/skills/<name>/SKILL.md` 注册 stub) |
| **Codex CLI / Copilot CLI / OpenCode / 其他** | `AGENTS.md` |
| **Windsurf** | `.windsurf/rules/*.md` 或共用 `AGENTS.md` |
| **Gemini CLI** | `GEMINI.md` |

所有入口都必须包含 `routing.yaml` bootstrap。Claude Code 原生 skill 由于 enterprise > personal > project 同名优先级,建议用项目特定名(如 `<project>-review`)。

各工具具体模板:[`references/per-tool-shells.md`](references/per-tool-shells.md)。

## 仓库文件

| 文件 | 内容 |
|---|---|
| [SKILL.md](SKILL.md) | Skill 入口:何时使用、目标结构、核心原则 |
| [WORKFLOW.md](WORKFLOW.md) | 迁移指南:Quick Start scaffold、9-phase 流程、下游升级 |
| [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) | 模板族注释指南 + Task Closure Protocol |
| [REFERENCE.md](REFERENCE.md) + [references/](references/) | layout(含 positioning)、progressive-rigor、thin-shells、protocols、conventions |
| [EXAMPLES.md](EXAMPLES.md) + [examples/behavior-failures.md](examples/behavior-failures.md) | 迁移形态、项目形态、真实压力测试失败 |
| [templates/](templates/) | 字节级 scaffold,直接复制到下游 |
| [scripts/](scripts/) | 上游维护 + check 套件([scripts/README.md](scripts/README.md) 有矩阵) |

## FAQ

**这个替代官方 Anthropic skill 模板吗?**
不替代。官方模板定义最小 skill 形态(SKILL.md + frontmatter)。这个 meta-skill 从其上一层开始 —— 当单个小 SKILL.md 不够用时再启用。

**可以渐进迁移吗?**
可以。第一轮:抽取 rules。第二轮:抽取 workflows。第三轮:抽取 references + 改薄壳。每轮结束项目都处于可工作状态。

**下游怎么收上游更新?**
让 agent 跑 update from upstream。复制过去的 `workflows/update-upstream.md` 会克隆最新上游、读上游 `UPSTREAM-CHANGES.md`、自己 diff 文件、合上游机制改动、保留下游内容、跑 conformance 校验(对的是上游 contract,不是本地 snapshot)。

---

LinuxDO 学 AI — [LinuxDO](https://linux.do/)

## Star History

<a href="https://www.star-history.com/?repos=WoJiSama%2Fskill-based-architecture&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=WoJiSama/skill-based-architecture&type=date&legend=top-left" />
 </picture>
</a>
