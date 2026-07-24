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

**Skill-Based Architecture（SBA）是一个 Skill，不是 Agent 操作系统，也不是项目管理平台。**它把真实项目规则、业务语义、owner、工作流和验证契约组织成可路由的项目 Skill，让普通成员拉下仓库后，Agent 就能可靠工作，而不需要每个人先学会设计 Skill。

SBA 负责吸收不应由普通用户承担的作者和工程复杂度。它帮助当前 Agent 使用所在 harness 已有的 Plan、Subagent 和工具能力，并在能力不可用时优雅降级；它不增加常驻服务、任务数据库、统一状态机或独立执行 runtime。具体技术栈事实仍然属于下游项目 Skill。

## 什么才算成功

SBA 不是为了让 Agent 变得更忙，而是要让它更能做到三件事：

1. **看到足够完整的真实情况。** 找到 source of truth、owner、业务不变量、生产者到消费者的路径、矛盾和证据边界，而不是无边界读取整个仓库。
2. **在没有标准答案时做判断。** 在信息不完整时权衡收益、代价和风险，诚实表达不确定性；新证据推翻承重结论时，重新检查方案、验收、边界和 Task Anchor。
3. **组织别人可靠执行。** 把意图转成可复核的角色、输入、输出、禁止区和验证契约；只在有净收益时委派，并由主 Agent 保留最终整合与复核责任。

结果不应是更多文件、测试或流程，而应是一个可复核的交付：来源、边界、owner、适配证据和停止条件都清楚。验证成本跟随风险，不能用测试数量代替证据质量。

真正的杠杆不来自让所有动作都经过一个 Agent，而来自在信息不完整、资源不足或需求不清晰时，仍能定义标准、判断风险、协调资源并带出结果。

## 安装

**Claude Code —— 一行装好:**

```text
/plugin marketplace add WoJiSama/skill-based-architecture
/plugin install skill-based-architecture@skill-based-architecture
```

然后[触发它](#quick-start);之后用 `/plugin marketplace update` 拉更新。

**不安装先体验:** 可以通过 ClawMama Skill catalog 在 [Telegram 或 WhatsApp 中运行 Skill Based Architecture](https://app.clawmama.run/skills/i78bb1/hermes?utm_source=github&utm_medium=issue&utm_campaign=skill_outreach_wojisama_skill_based_architecture)。建议配合[可复制 demo 输入包](examples/simple-repo/COPY-PASTE-INPUT.md)或其他非敏感规则文件使用。内置 demo 故意是最基础的 smoke-test 输入,所以生成结构会很小;真实项目迁移仍建议在本地用 Claude Code 安装或 clone 仓库。

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

想先安全试跑? Hosted preview 里用 [`examples/simple-repo/COPY-PASTE-INPUT.md`](examples/simple-repo/COPY-PASTE-INPUT.md);本地 agent 可以用 [`examples/simple-repo/`](examples/simple-repo/) 当目标项目输入。它是一个故意做得很小的假项目,包含重复的 `AGENTS.md`、`CLAUDE.md`、Cursor 规则和 README notes。把它当作最基础的 routing / thin-shell 行为验证,不要把它当成真实项目迁移深度的展示上限。

高级工作流可以在当前 harness 支持时使用它原生的 Plan、Subagent 和工具能力；能力不可用时，SBA 会降级为串行或内联执行。某些 harness 在委派前要求用户显式授权，这是工具权限边界，不是普通项目成员还要安装或维护的另一套系统。

## 关键特性

- **路由到真实项目知识。** `routing.yaml` 为当前任务选择一个工作流，并只追加本次判断需要的领域上下文。业务语义、代码事实和历史证据保留清楚的 owner 与边界，不混成一份无差别知识库。
- **激活优先于存储。** 一条规则或经验只有被正常任务路径读到，并改变 Agent 的下一步动作，才真正产生价值。薄壳和真实用户语言的触发条件让重要知识保持生效，同时避免复制规则正文。
- **目标与证据纪律。** 一个明确动作和检查保持轻量；其他任务建立 Goal、Done When 和实质 Boundaries。验证前，把每个实质风险绑定到适配证据和停止 / 升级条件。详见 [Task Anchor 设计](docs/task-anchor-native-plan.md)。
- **可复核的协作。** 委派任务携带角色、输入、输出、禁止区、context provenance、检查和剩余风险。Worker 的结论只是候选证据，主 Agent 仍负责整合和复核。
- **渐进严格，小而完整的默认核心。** 从单个 `SKILL.md` 开始，只在真实压力下增长；压力消失时删除或合并机制。普通用户不应承担“该装哪套架构组件”的选择成本。
- **跨 harness 优雅降级。** Cursor、Claude Code、Codex、Windsurf、Gemini、OpenCode 和 AGENTS.md 类工具使用各自原生能力；某个 harness 的限制不应重新定义整体产品模型。

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
| [docs/sba-bible.md](docs/sba-bible.md) | SBA 产品信念、发展方向与重大机制的决策门禁 |
| [WORKFLOW.md](WORKFLOW.md) | 迁移指南:Quick Start scaffold、9-phase 流程、下游升级 |
| [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) | 模板族注释指南 + Task Execution / Task Closure |
| [docs/task-anchor-native-plan.md](docs/task-anchor-native-plan.md) | Task Anchor、原生 Plan、Workflow 与 Closure 的用户视角设计 |
| [REFERENCE.md](REFERENCE.md) + [references/](references/) | layout(含 positioning)、progressive-rigor、thin-shells、protocols、conventions |
| [EXAMPLES.md](EXAMPLES.md) + [examples/behavior-failures.md](examples/behavior-failures.md) | 迁移形态、项目形态、真实压力测试失败 |
| [templates/](templates/) | 字节级 scaffold,直接复制到下游 |
| [scripts/](scripts/) | 上游维护 + check 套件([scripts/README.md](scripts/README.md) 有矩阵) |

## FAQ

**SBA 是 Agent 操作系统吗？**
不是。SBA 是一个 Skill，帮助当前 Agent 可靠使用项目规则、业务语义、工作流和 harness 已有能力。它不拥有任务数据库、常驻调度器、统一 runtime 或项目管理界面。

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
