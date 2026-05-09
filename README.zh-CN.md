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

[English](README.md) | **中文**

一个**面向 AI Agent 规则系统的生命周期管理框架**。把散落的提示词文档(`AGENTS.md`、`CLAUDE.md`、`.cursor/rules/`、README 规则)整理成位于 `skills/<name>/` 下、可路由、可验证、可更新的工程资产。

它关注规则系统本身:结构、路由、workflow、校验、任务复盘、上游/下游更新。它**不**提供具体技术栈规则 —— 后端、前端、部署等内容应放在下游项目 skill 里。

## 产物形态

```
散落的项目规则
AGENTS.md / CLAUDE.md / .cursor/rules / README 注记
        │
        ▼
skills/<project>/
├── SKILL.md          # 路由器: Always Read + Common Tasks (≤ 100 行)
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

| 使用场景 | clone 目标 |
|---|---|
| Cursor 用户级 | `~/.cursor/skills/skill-based-architecture` |
| Cursor 项目级 | `.cursor/skills/skill-based-architecture` |
| 其他 agent | `skills/skill-based-architecture` 在目标项目内,或 `../skill-based-architecture` 在它旁边 |

```bash
git clone https://github.com/WoJiSama/skill-based-architecture.git \
  skills/skill-based-architecture
```

### 2. 在目标项目里触发

让 agent 使用本地 meta-skill:

> "用 skill-based-architecture 重构项目规则"

等价触发:"整理项目规则"、"把规则迁移到 skills 目录"、"organize the project rules"。

Agent 会从 [`templates/`](templates/) 复制预制 scaffold 到 `skills/<name>/`,创建薄壳,填充每一个 `<!-- FILL: -->` 标记,跑校验。完整流程:[WORKFLOW.md](WORKFLOW.md)。

## 关键特性

- **两层路由**:`SKILL.md` 维护一个生成的 **Always Read** 列表;**Common Tasks** 仅在需要时把 agent 路由到额外文件。下游用 `routing.yaml` 作可编辑的单一路由源。
- **薄壳 + 路由 bootstrap**:每个入口文件嵌入指向 `routing.yaml` 的短 bootstrap。路由表不在每个 shell 里复制 —— 自然语言指令在长会话压缩中会丢失。
- **description 即触发条件**:用用户实际语言的领域级激活短语,不是 workflow 关键字堆砌。`check-description-routing.sh` 校验。
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
