# 从 Karpathy Skills 学到的四件事
# Four Things We Learned from Karpathy Skills

> 原项目 / Original project：[forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)
> 原始灵感 / Original inspiration：[Andrej Karpathy 关于 LLM 编码陷阱的推文 / Andrej Karpathy's tweet on LLM coding pitfalls](https://x.com/karpathy/status/2015883857489522876)

---

最近研究了一个结构很有意思的 Claude Code skill 项目。它把 Andrej Karpathy 总结的 LLM 编码反模式，打包成了一个可以直接 `/plugin install` 的行为准则 skill。整个项目只有 6 个文件、859 行，但有几个地方做得远比很多大型 skill 项目更扎实。

*We recently studied a well-structured Claude Code skill project. It packages Andrej Karpathy's LLM coding anti-patterns into a behavior-guideline skill installable via `/plugin install`. The whole project is just 6 files and 859 lines — but several design decisions are more solid than many larger skill projects.*

这篇文章不是对这个项目的整体评测，而是聚焦在**我们可以直接借鉴的四个具体做法**，以及每一个背后的深层原因。

*This article isn't a full review. It focuses on **four specific practices worth adopting directly**, and the deeper reasoning behind each.*

---

## 先说清楚项目是什么 / What the project actually is

Karpathy Skills 的核心是一个 67 行的 `SKILL.md`，里面有四条行为准则：

*The core of Karpathy Skills is a 67-line `SKILL.md` containing four behavioral guidelines:*

| 原则 / Principle | 对应的 LLM 反模式 / LLM anti-pattern it targets |
|---|---|
| **Think Before Coding** | 默默做假设、不暴露歧义、不提 tradeoff / Silent assumptions, hidden confusion, no tradeoffs surfaced |
| **Simplicity First** | 过度工程化、写 1000 行能用 100 行解决的问题 / Over-engineering, 1000 lines when 100 would do |
| **Surgical Changes** | 顺手改了不相关的代码、风格、注释 / Drive-by refactoring of adjacent code, style, comments |
| **Goal-Driven Execution** | 模糊执行、没有可验证的成功标准 / Vague execution, no verifiable success criteria |

每条准则很短，但有一个关键设计：**每条都附有一句可执行的检验句**，而不是纯声明。下文会详细说为什么这很重要。

*Each guideline is short, but has one critical design choice: **every principle ends with an executable verification sentence**, not a pure declaration. More on why this matters below.*

---

## 借鉴点一：原则 + 检验句，而不是原则 + 解释
## Lesson 1: Principle + Verification Sentence, Not Principle + Explanation

这是这个项目里我觉得最值得学的写法。

*This is the most valuable writing pattern in the project.*

大多数 coding guidelines 长这样：

*Most coding guidelines look like this:*

> **Be Simple.** Write the minimum code that solves the problem.
> **保持简洁。** 写解决问题所需的最少代码。

Karpathy Skills 的写法是：

*Karpathy Skills writes it like this:*

> **Simplicity First.** Minimum code that solves the problem. Nothing speculative.
>
> Ask yourself: **"Would a senior engineer say this is overcomplicated?"** If yes, simplify.
>
> ---
>
> **简洁优先。** 解决问题的最少代码，没有投机性的功能。
>
> 问自己：**"资深工程师会觉得这过度复杂吗？"** 如果是，就简化。

> **Surgical Changes.** Touch only what you must. Clean up only your own mess.
>
> The test: **Every changed line should trace directly to the user's request.**
>
> ---
>
> **精准修改。** 只改必须改的，只清理你自己造成的乱。
>
> 检验标准：**每一行改动都应该能直接追溯到用户的请求。**

区别在哪？前者是**声明**，告诉 Agent "应该这样"。后者是**检验句**——给 Agent 一个在执行后可以自我验证的问题。

*What's the difference? The first is a **declaration** — telling the Agent "should be this way." The second is a **verification sentence** — giving the Agent a question it can actually ask itself after execution.*

Agent 在生成代码之后，可以真的去问自己"每一行改动都能追溯到用户的请求吗"，然后根据答案决定要不要回滚某些行。而"Be Simple"这种声明句，Agent 只能在生成之前抽象地"记住"，在生成之后根本没有钩子去触发验证。

*After generating code, the Agent can genuinely ask itself "can every changed line trace back to the user's request?" and decide whether to roll back certain lines. A declaration like "Be Simple" can only be abstractly "remembered" before generation — there's no hook to trigger verification afterward.*

**可以借鉴的做法 / How to adopt this:**

把你 skill 里所有纯声明式的原则，改成"原则 + 一句检验句"的格式：

*Convert all purely declarative principles in your skill to "principle + one verification sentence" format:*

```markdown
## 1. One canonical location per rule
## 1. 每条规则只存在一个位置

每条规则在整个 skill 树里只存在一个位置，不重复。
Each rule exists in exactly one place across the entire skill tree — no duplication.

Check: `grep -r "rule keyword" skills/` returns exactly 1 result, not multiple.
检验：`grep -r "规则关键词" skills/` 只返回 1 条结果，不是多条。
```

```markdown
## 7. Description = trigger condition
## 7. description 字段写成触发条件

description 字段写成触发条件，不是被动描述。
The description field is written as a trigger condition, not a passive summary.

Check: does the description contain ≥ 2 quoted trigger phrases? If not, it's incomplete.
检验：description 里是否有 ≥2 个引号括起来的触发短语？没有就是没写完。
```

这种格式的好处是，检验句可以在 Task Closure Protocol 里自动触发——AAR 扫描时直接跑这些 check，不再依赖 Agent 的主观判断。

*The advantage of this format: verification sentences can be automatically triggered inside Task Closure Protocol — run these checks during the AAR scan, removing reliance on the Agent's subjective judgment.*

---

## 借鉴点二：代码行为层面的 ❌/✅ 对比示例
## Lesson 2: Behavior-Level ❌/✅ Code Examples, Not Just "Obvious Mistakes"

Karpathy Skills 的 EXAMPLES.md 有 522 行，全部都是代码级的 before/after 对比。比如"Surgical Changes"这一条：

*Karpathy Skills' EXAMPLES.md is 522 lines, all code-level before/after comparisons. Here's the "Surgical Changes" example:*

**❌ LLM 实际会做的 / What LLMs actually do**
（请求是"修复空 email 导致的崩溃" / Request: "fix the crash when email is empty"）

```diff
  def validate_user(user_data):
-     # Check email format
-     if not user_data.get('email'):
+     """Validate user data."""               # 加了 docstring（没被要求）
+                                             # Added docstring (not requested)
+     email = user_data.get('email', '').strip()
+     if not email:
          raise ValueError("Email required")
-     if '@' not in user_data['email']:
+     if '@' not in email or '.' not in email.split('@')[1]:   # "顺手"加强了校验
+                                                               # "Helpfully" strengthened validation
          raise ValueError("Invalid email")
      if not user_data.get('username'):
          raise ValueError("Username required")
+     if len(username) < 3:                  # 没被要求的 username 校验
+         raise ValueError("Username too short")  # Unrequested username validation
```

**✅ 应该只做的改动 / What should actually change**

```diff
  def validate_user(user_data):
      # Check email format  ← 保留原注释 / original comment preserved
-     if not user_data.get('email'):
+     email = user_data.get('email', '')
+     if not email or not email.strip():
          raise ValueError("Email required")
-     if '@' not in user_data['email']:
+     if '@' not in email:
          raise ValueError("Invalid email")
      # Check username ← 保持原样，没被要求改 / left as-is, not requested
      if not user_data.get('username'):
          raise ValueError("Username required")
```

这个例子为什么好？因为它展示的坏代码**看起来并不差**。docstring、更严格的邮箱校验、username 长度限制——这些在别的场景下都是好实践。问题是**时机错了**：在一个只需要修 bug 的 PR 里加进去，就是 surgical 原则的违反。

*Why is this example good? Because the bad code **doesn't look wrong**. Docstrings, stricter email validation, username length checks — these are all good practices in other contexts. The problem is **wrong timing**: adding them in a PR that only needs a bug fix violates the Surgical Changes principle.*

**很多 guidelines 文档的通病**是只展示"明显的错误"——内存泄漏、SQL 注入、死循环。但 Agent 的真实错误通常不是这种，而是"做了没被要求但看起来合理的事情"。Karpathy 的 EXAMPLES.md 专门针对这类**隐蔽性更高**的反模式。

*The common failure of guidelines documents is showing only **obvious errors** — memory leaks, SQL injection, infinite loops. But real Agent errors are usually "doing unrequested but seemingly reasonable things." Karpathy's EXAMPLES.md specifically targets these **harder-to-spot** anti-patterns.*

**可以借鉴的做法 / How to adopt this:**

我们自己的 examples/ 目前偏重**目录结构层面**的 before/after，但缺少**行为层面**的对比。可以加一类新的 examples，专门展示：

*Our own examples/ currently focuses on **directory structure** before/after, but lacks **behavior-level** comparisons. We can add a new category of examples showing:*

- Agent 在没有 Task Closure Protocol 时写的 AAR 借口原文，vs 有了 Rationalizations Table 之后的行为
  *Agent's actual excuse text without Task Closure Protocol, vs. correct behavior after Rationalizations Table is in place*
- Agent 在没有 `description` trigger phrases 时的静默激活失败路径，vs 加了之后的正确激活路径
  *Silent activation failure path without `description` trigger phrases, vs. correct activation path after adding them*
- "description written as passive summary" vs "description as trigger condition" 的实际输出对比
  *Actual output comparison: "description as passive summary" vs. "description as trigger condition"*

这类对比不需要代码，但需要模拟真实 Agent 行为，冲击力不低于代码 diff。

*These comparisons don't require code, but need to simulate real Agent behavior — their impact is no less than a code diff.*

---

## 借鉴点三：`.claude-plugin/` 打包，让 skill 可以一行安装
## Lesson 3: `.claude-plugin/` Packaging — From 6-Step Install to One Command

这是我们目前完全缺失的东西。

*This is something we completely lack right now.*

Karpathy Skills 的用户安装体验 / The user install experience:

```bash
# Option A：Claude Code plugin（推荐 / recommended）
/plugin marketplace add forrestchang/andrej-karpathy-skills
/plugin install andrej-karpathy-skills@karpathy-skills

# Option B：直接复制 CLAUDE.md / Copy CLAUDE.md directly
curl -o CLAUDE.md https://raw.githubusercontent.com/.../CLAUDE.md
```

实现这个能力的代码极其轻量——只有两个 JSON 文件：

*The implementation is extremely lightweight — just two JSON files:*

```
.claude-plugin/
├── plugin.json       # 11 行 / 11 lines — 告诉 Claude Code skills 在哪里 / tells Claude Code where skills are
└── marketplace.json  # 29 行 / 29 lines — 让 /plugin marketplace add 能找到这个 plugin
```

```json
// plugin.json
{
  "name": "andrej-karpathy-skills",
  "description": "Behavioral guidelines to reduce common LLM coding mistakes",
  "version": "1.0.0",
  "skills": ["./skills/karpathy-guidelines"]
}
```

```json
// marketplace.json
{
  "name": "karpathy-skills",
  "id": "karpathy-skills",
  "plugins": [{
    "name": "andrej-karpathy-skills",
    "source": "./",
    "category": "workflow",
    "version": "1.0.0"
  }]
}
```

**没有 plugin 打包时的安装路径 / Install path without plugin packaging:**

1. 找到 GitHub 仓库 / Find the GitHub repo
2. 看 README，理解目录结构 / Read README, understand structure
3. `git clone` 或手动 `cp` / `git clone` or manually copy
4. 知道文件应该放在哪个路径 / Figure out where files should go
5. 配置 CLAUDE.md / SKILL.md / Configure CLAUDE.md / SKILL.md
6. 验证激活 / Verify activation

**有 plugin 打包时的安装路径 / Install path with plugin packaging:**

1. `/plugin install <name>`

对"只是想试试"的用户来说，前者的摩擦力高到会直接放弃。这也是为什么很多设计良好的 skill 仓库，实际使用率远低于预期——不是内容不好，是入口太难找。

*For users who just want to try it, the first path has enough friction to make them give up entirely. This is why many well-designed skill repos have far lower adoption than expected — not because the content is bad, but because the entry point is too hard to find.*

**plugin 打包不是给"重度用户"的优化，是给"第一次接触"的用户降低门槛的唯一方式。**

***Plugin packaging isn't an optimization for power users — it's the only way to lower the barrier for first-time users.***

**可以借鉴的做法 / How to adopt this:**

给自己的 skill 仓库加 `.claude-plugin/` 两个 JSON 文件就够了，参考 Karpathy Skills 的结构直接仿写。唯一需要决策的是 `category`（workflow / coding / etc.）和 `keywords`。

*Adding `.claude-plugin/` with two JSON files is all it takes. The only decisions needed are `category` (workflow / coding / etc.) and `keywords`.*

---

## 借鉴点四：极简结构和"小到不需要拆"的自知之明
## Lesson 4: Minimal Structure and Knowing When "Small Enough Not to Split" Is Correct

这一点有点反直觉，但值得单独讲。

*This one is counterintuitive, but worth discussing on its own.*

很多 skill 项目一上来就搭完整架构：`rules/`、`workflows/`、`references/`、`hooks/`、多 harness 薄壳……甚至在内容还很少的时候就把架构撑起来。这会制造一种"这个项目很完整"的错觉，但实际上每个子目录里只有一两行占位符，维护成本反而更高。

*Many skill projects immediately scaffold a full architecture: `rules/`, `workflows/`, `references/`, `hooks/`, multiple harness thin shells… even when there's almost no content yet. This creates the illusion of completeness, while each subdirectory has only a line or two of placeholders — and the maintenance cost is actually higher.*

Karpathy Skills 的整个 skill 结构是这样的：

*The entire Karpathy Skills structure looks like this:*

```
skills/karpathy-guidelines/
└── SKILL.md   ← 全部内容都在这里 / all content lives here
```

没有 `rules/`，因为四条行为准则放在 SKILL.md 里就够了。
没有 `workflows/`，因为这个 skill 不绑定特定任务流程。
没有 `references/`，因为 Karpathy 的推文链接直接放在文件顶部就够了。

*No `rules/` — four behavioral guidelines fit comfortably in SKILL.md.*
*No `workflows/` — this skill doesn't bind to specific task flows.*
*No `references/` — a link to Karpathy's tweet at the top of the file is sufficient.*

这个判断是对的。**当一个 skill 的内容只有一个主题、几条规则、没有任务路由需求时，单文件就是最好的结构。** 硬拆成多目录只会让读者找不到东西，也让 Agent 多了很多不必要的文件需要读。

*This judgment is correct. **When a skill has one theme, a few rules, and no task-routing requirements, a single file is the best structure.** Forcing a multi-directory split just makes content harder to find and gives the Agent unnecessary files to read.*

这不是"偷懒"，是对架构复杂度有准确的感知：**结构服务于内容，而不是用结构来显示项目的完整性。**

*This isn't laziness — it's accurate judgment about architectural complexity: **structure serves content, not the other way around.***

当然，Karpathy Skills 的代价也很明显：没有自演化机制、没有 Task Closure Protocol、没有 AAR——同样的错误下次还会犯。它是一个**静态的行为提示**，不是一个**会自我更新的知识系统**。这不是它的缺陷，而是它的设计选择——它从一开始就知道自己要做什么，所以结构刚好够用。

*Of course, the tradeoff is clear: no self-evolution mechanism, no Task Closure Protocol, no AAR — the same mistakes will happen again. It's a **static behavioral prompt**, not a **self-updating knowledge system**. This isn't a flaw; it's a design choice. It knew what it needed to be from the start, so the structure is exactly enough.*

**可以借鉴的做法 / How to adopt this:**

在设计 skill 结构之前，先回答这三个问题：

*Before designing your skill's structure, answer three questions:*

| 问题 / Question | 如果答案是… / If the answer is… | 结论 / Conclusion |
|---|---|---|
| 这个 skill 有多少个不同主题的内容？/ How many distinct content themes does this skill have? | 少于 3 个 / Fewer than 3 | 单文件够了 / Single file is enough |
| 绑定了多少种任务流程？/ How many task flows does it bind to? | 没有 / None | 不需要 `workflows/` / No `workflows/` needed |
| 预期会随项目演进更新吗？/ Expected to evolve with the project? | 不会 / No | 不需要自演化机制 / No self-evolution needed |

三个问题都是否定答案的，就是单文件 skill 的场景。只有当"是"的答案出现时，才引入对应的目录层级。**按需引入复杂度，而不是一开始就摆全套架构。**

*All negative answers means single-file skill. Only when a "yes" appears should you introduce the corresponding directory level. **Introduce complexity on demand, don't scaffold the full architecture upfront.***

---

## 一个不借鉴的地方：CLAUDE.md 和 SKILL.md 逐字重复
## One Thing We Won't Adopt: CLAUDE.md and SKILL.md as Verbatim Duplicates

顺带提一个值得注意的问题：这个项目的 CLAUDE.md（65 行）和 SKILL.md（67 行，去掉 frontmatter 后几乎一样）内容几乎完全重复。

*Worth flagging: the project's CLAUDE.md (65 lines) and SKILL.md (67 lines, nearly identical after removing frontmatter) are almost verbatim copies of each other.*

这个做法的优点是"任何用户不管用哪种方式导入，都能得到完整内容"。缺点是维护时必须同步改两个文件，一旦忘记就会产生内容漂移。

*The advantage: any user, regardless of import method, gets the full content. The disadvantage: any update requires changing both files in sync — miss one and you have content drift.*

更好的做法是**薄壳模式**：CLAUDE.md 保持 3-5 行，只写一个指针指向 SKILL.md，Agent 通过路由读到完整内容，两者不需要同步。

*The better approach is the **thin-shell pattern**: CLAUDE.md stays 3-5 lines with a single pointer to SKILL.md. The Agent reads full content via routing — no sync needed.*

```markdown
<!-- CLAUDE.md — 薄壳示例 / thin shell example -->
# Project: my-skill

Active skill: `skills/my-skill/SKILL.md`

Read that file first. It contains routing, rules, and task workflows.
```

唯一例外：如果你的 skill 内容极少（5 行以内），且不会更新，可以在 CLAUDE.md 里内联——省去跳转。但超过这个体量，薄壳 + 路由才是可维护的做法。

*The only exception: if your skill content is very small (under 5 lines) and won't be updated, inline it directly in CLAUDE.md. But beyond that size, thin-shell + routing is the only maintainable approach.*

---

## 总结 / Summary

| 借鉴点 / Lesson | 核心价值 / Core Value | 实现成本 / Implementation Cost |
|---|---|---|
| 原则 + 检验句 / Principle + verification sentence | 把声明式规则变成可执行的自验证钩子 / Turns declarative rules into self-verifiable hooks | 低 / Low — 改写文字，不改结构 / rewrite text, no structural change |
| 代码行为层面的 ❌/✅ 对比 / Behavior-level ❌/✅ examples | 展示隐蔽性高的反模式 / Exposes high-concealment anti-patterns | 中 / Medium — 需要构造真实场景 / requires realistic scenario construction |
| `.claude-plugin/` 打包 / Plugin packaging | 从"读完 README 手动配"降到"一行命令" / From "read README and manually configure" to one command | 低 / Low — 2 个 JSON 文件 / 2 JSON files |
| 按需引入结构复杂度 / Introduce complexity on demand | 避免用架构外壳掩盖内容稀薄 / Avoid using architectural scaffolding to hide thin content | 低 / Low — 判断清晰就够了 / clear judgment is enough |

这四件事都不是什么新概念，但 Karpathy Skills 把它们落到了一个 6 文件的小项目里，干净利落。有时候最值得学的东西，就是"用最少的结构做到位该做的事"。

*None of these are new concepts, but Karpathy Skills lands all four in a 6-file project, cleanly and without waste. Sometimes the most valuable lesson is: use the minimum structure needed to do the job right.*
