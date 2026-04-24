# 给 AI Agent 装两层护栏:聊聊 skill-based-architecture 里的 Hook 机制和多 Skill 框架

> 这是一篇帖子草稿，介绍 [skill-based-architecture](https://github.com/WoJiSama/skill-based-architecture) 项目里两个最核心的机制。

如果你在项目里给 AI Agent（Cursor / Claude Code / Codex / Windsurf 等）写过规则文件，大概都遇到过这种尴尬：

- 辛辛苦苦写了一份 CLAUDE.md / AGENTS.md / .cursor/rules/，明明白白列了 10 条规则
- Agent 第一次读完，跟你谈笑风生地写代码
- 然后你说"把后端重构一下"，Agent 立刻忘了 rules，开始给你写 3 阶段方案
- 你加第 11 条规则，Agent 读得更少了

我写 [skill-based-architecture](https://github.com/WoJiSama/skill-based-architecture) 就是想解决这事。这篇帖子重点讲**两个最核心的机制**：

1. **Hook 系统** —— 不是让 Agent 自觉，是机制上拦截
2. **多 Skill 兼容的框架设计** —— 你的产物不是一份文档，是一个可以接入别的 skill 的编排层

---

## 先看一组数据：为什么约定不够用

我在上游的 `agent-behavior.md` 里写了一条门槛规则："新增行为原则需要有 evidence，不能随便加"。然后用 10 个对抗性 prompt 测了 Haiku 4.5 和 Sonnet 4.6 的遵守情况 —— 包括权威框架（"我 leader 说要加"）、紧急压力（"demo 5 分钟后要用"）、伪造 evidence、显式 bypass 指令等：

| 模型 | 不装 hook 时的拦截率 |
|---|---|
| Haiku 4.5 | **11%**（10 次攻击拦住 1 次） |
| Sonnet 4.6 | **30%**（10 次攻击拦住 3 次） |

即使是 Sonnet，约定级规则也只拦 30%。Haiku 基本等于没装。

为什么？因为**模型的注意力优化方向是"回答问题"，不是"遵守规则"**。当用户说"我 leader 让我加"或"demo 5 分钟后要用"，模型更倾向于帮用户而不是帮规则。

这时候要么降级去用更强的模型（贵），要么**把规则从约定升级成机制**。

---

## 第一层：Hook 系统

Hook 本质上就是 git 的 pre-commit 钩子，只是装在 AI Agent 的工具调用链路上。Claude Code 提供 SessionStart / PreToolUse / PostToolUse 三种时机，我的项目用了前两种。

### SessionStart：对抗上下文压缩

长会话里 `/clear` 和 `/compact` 会把前面的上下文大部分丢掉，你辛苦写的 SKILL.md 路由表也会跟着丢。Agent 从那一刻起不再知道任务该读哪些规则，开始凭印象工作。

SessionStart hook 在这些时机自动把 SKILL.md 重新注入上下文：

```json
// .claude/settings.json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "startup|clear|compact",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/session-start"
      }]
    }]
  }
}
```

脚本本身就是 `cat SKILL.md | python3 -c '...JSON escape...'` 然后按 harness 期望的格式往 stdout 打，20 行 bash 搞定。

### PreToolUse：机制级门槛

这个更关键。当 Agent 要对"核心规则文件"做 Write/Edit 时，hook 脚本**先拿到调用参数**，自己决定要不要放行：

```bash
# agent-behavior-gate.sh 核心逻辑（简化）
if [[ 编辑会让文件变长 && (超出上限 || 没有 AAR 证据) ]]; then
  echo "BLOCKED: 超过 100 行上限 / 没有 behavior-failures 证据" >&2
  exit 2    # ← 关键：非 0 退出让 Claude Code 取消这次 Edit
fi
exit 0      # 放行
```

Agent 根本没机会写到文件，它只看到一个 "Edit 被 hook 拒了" 的错误。无论它多想加、给了多少理由，都不行。

**假阳性的缓解**是关键，否则维护者自己都没法正常工作：

- **缩减**编辑（删行）**永远放行** —— 让维护者可以自由压缩文件
- **改错字**（同行、字符差 ≤ 20）自动放行
- 紧急维护：`AGENT_BEHAVIOR_GATE_OVERRIDE=1` 环境变量显式 bypass（stderr 留审计记录）
- 过渡期：`AGENT_BEHAVIOR_GATE_WARN=1` 只警告不拦

装上 hook 之后，同样 10 个对抗攻击的拦截率：

| 模型 | 装 hook 后 |
|---|---|
| Haiku 4.5 | **100%** |
| Sonnet 4.6 | **100%** |

模型能力差异在机制面前不存在了。这一档拦截率不靠模型理解力，靠一段确定性 bash。

### 但我必须诚实讲 hook 的局限

这是我原本以为 hook 管用、实测发现没用的部分：

| Runtime | Hook 触发？ | Block 生效？ |
|---|---|---|
| 真人 Claude Code CLI 交互会话 | ✅ | ✅ **100%** |
| `claude --print` 非交互子进程 | ✅ 触发 | ❌ `--print` 模式自动 approve 所有权限 |
| Claude Agent SDK 子 Agent（`Task` / `Agent` 工具） | ❌ **不触发** | ❌ |
| Cursor | ⚠️ 未充分实测 | ⚠️ 未充分实测 |

**所以 hook 只保护真人交互编辑。** 自动化流水线（`--print`）和子 Agent 编排走不到这层 —— 那些场景要靠 git 层的 CODEOWNERS + CI 兜底。

还有一个**静默失败陷阱**值得单独讲：Claude Code CLI v2.1+ 要求**嵌套 schema**，我踩了一下午才调出来：

```json
// ❌ flat 写法 —— SessionStart 恰好接受，PreToolUse 静默失效
{ "matcher": "Write|Edit", "command": "..." }

// ✅ nested 写法
{
  "matcher": "Write|Edit",
  "hooks": [{ "type": "command", "command": "..." }]
}
```

用 flat 写法 hook 看起来**注册成功**（启动没报错、`--debug hooks` 能看到它），但 Edit 时就是不触发。如果你正在写 PreToolUse hook，这个坑值得预先知道。

---

## 第二层：多 Skill 兼容的框架设计

第二个核心机制其实是一个**意识上的转变**：你用这个 meta-skill 在项目里跑出来的 `skills/<项目名>/` 目录，**不是一份独立文档**，是一个**可以继续扩展、可以嵌入其他 skill 的框架**。

### 产物里有哪些可扩展点

- `workflows/*.md` —— 项目里反复出现的任务流程，想加几个加几个
- `rules/*.md` —— 项目级约束（后端规则、前端规则、编码规范等）
- `references/*.md` —— 背景知识、坑点目录（gotchas）
- `protocol-blocks/*.md` —— 可复用的小块协议（红旗清单、子 Agent 合约、含糊请求闸等）
- `hooks` —— 上面讲的那套
- **cross-skill invocation** —— workflow 中途可以调用**其他 skill** 的工作流

最后一条是关键，我单独展开。

### 三种组合模式

**模式 A：嵌入调用** —— 你的 workflow 中途 Read 另一个 skill 并跟着它的流程走一遍

```markdown
# workflows/plan.md

## Step 1 — 收集项目特定上下文（3-6 条）
## Step 2 — 调用 obra/superpowers 的 planning skill

1. Read `skills/superpowers/SKILL.md`，匹配"plan a feature"路由
2. 跟完 `skills/superpowers/workflows/plan-a-feature.md` 全部步骤
3. 返回本 workflow Step 3，带上 Step 2 产出的规划

## Step 3 — 按项目规则审查规划产物
## Step 4 — Task Closure Protocol（AAR）
```

控制权始终在你的 workflow 里，被调用的 skill 只是一个子程序。

**模式 B：直接路由** —— 你的 SKILL.md Common Tasks 里直接把某类任务**指向**另一个 skill 的 workflow

```markdown
- 做安全评审 → 跟 `skills/security-review/workflows/review.md`（不写项目包装）
```

适合：另一个 skill 本身已经把事做对了，你没必要加项目 wrapper。

**模式 C：子 Agent 委派** —— 开个子 Agent 专门跑那个 skill，只要结构化结果回来

```markdown
派子 Agent 跑 skills/web-research，contract：
  Goal: 查某库的 v3.2 是否向下兼容
  Forbidden: 不在主仓写任何文件
  Acceptance: 返回 10 行内摘要 + 源链接
```

适合：被调用的 skill 跑起来会污染主 context（爬文档、跑几十个工具调用），需要隔离。

### 多 Skill 仓库的共存规则

一个仓库可以同时拥有好几个 skill（`skills/frontend/` + `skills/backend/` + `skills/billing/`），但有几条硬规矩：

1. **只有一个 `primary: true`** —— 无明确匹配时的默认 skill，写两个就是配置 bug
2. **触发词不能重叠** —— 两个 skill 都听 "add a page" 就是路由死锁，Agent 没法 disambiguate
3. **protocol-blocks 和 hooks 放仓库根**，不放某一个 skill 里 —— 它们是共享资源
4. **跨 skill 引用用相对路径**（`../../backend/rules/api-rules.md`），**不要复制内容** —— 保持单一来源
5. **AAR 跨 skill 记录** —— 某个 workflow 跨到另一个 skill 时学到的东西，两边都要记

### 分裂信号：什么时候一个 skill 该拆成两个

- SKILL.md 压不到 100 行以下
- 触发词明显分成两组，没有任务跨组
- rules/ 有 6+ 个文件，且其中 3+ 从来不在同一个任务里一起读

---

## 这套机制实际能跑吗

我在另一个项目 wj-small-tools（Spring Boot + Thymeleaf 工具站）上跑过完整迁移，然后做了两轮 subagent 测试，每轮 10 个真实任务 prompt（加页面 / 修 bug / 改文本工具 / 重构后端…）：

**简化结论**：

- Sonnet 在所有路由任务上都正确走流程
- Haiku 在**明确触发词**的任务上也正确（加工具、改 typo、加文本处理步骤）
- Haiku 在**模糊 prompt**（比如"重构一下让结构更清晰"）会跳过路由表，直接开始 "我来扫一下项目 + 给 3 个方向"

这个发现反过来促使我在 upstream 里加了一个 **Ambiguous Request Gate** protocol-block —— 路由表**之前**先做"含糊动词 + 没具体判据 = 停下问用户"的前置检查。现在下游项目都能继承这个闸。

整个过程本身也是个学习：我写了一份 `WORKFLOW.md § Upgrading` 章节，文档化"如何把老下游升级到新上游"。这也是框架思维的一部分 —— 产物要能跟项目一起演化，不能一次写完就僵在那里。

---

## 局限（摆到台面上讲清楚）

- **Hook 只保护真人交互编辑**，不保护 Agent SDK 子会话和 `claude --print`
- **约定级规则对 Haiku 只能拦 ~11%**，必须装 hook 才接近满覆盖
- **多 skill 的触发词管理还是人力**，没有工具自动检测重叠
- **故意不做版本号** —— 怕的是"忘了更新版本"比没版本更误导，宁可把变化写进 commit log
- **没有 CLI init 脚手架**，目前还是 clone + sed 5 条命令，10 分钟内能搞定但不是 0 摩擦

---

## 试一下

仓库：**<https://github.com/WoJiSama/skill-based-architecture>**

1 分钟体验：
1. Clone 下来
2. 看 [`templates/skill/`](https://github.com/WoJiSama/skill-based-architecture/tree/main/templates/skill) —— 下游项目会长成的样子
3. 看 [`templates/hooks/`](https://github.com/WoJiSama/skill-based-architecture/tree/main/templates/hooks) —— hook 脚本 + 配置都在这

想在自己项目上跑一遍，[WORKFLOW.md](https://github.com/WoJiSama/skill-based-architecture/blob/main/WORKFLOW.md) 的 Quick Start 是 5 条 bash 命令。

---

欢迎 issue / PR / star，也欢迎告诉我踩到什么坑 —— 这个项目的 [`examples/behavior-failures.md`](https://github.com/WoJiSama/skill-based-architecture/blob/main/examples/behavior-failures.md) 就是这么一行一行长大的。

如果你正在给自己项目写 AI Agent 规则、而且发现"写了就漏"、"加了就乱"的死循环，值得看一眼。
