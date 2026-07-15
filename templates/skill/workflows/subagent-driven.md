# Workflow: Subagent-Driven Development

> Two modes — pick the one that fits the task shape:
>
> - **Mode 1: Direct Auxiliary Delegation** — main-agent inline is the default. **Inside any workflow, before doing a sub-step, ask self** "主 agent 看这一步的全过程是多余的吗? / Is watching the whole sub-step redundant for the main agent?". Answer **yes** → **directly** `spawn_agent` (assumes global authorization — see Harness Compatibility), main conversation only sees the result. **This is a continuous self-judgment + auto-dispatch habit, not a step-level reminder**; the signal list below is just common typical examples, **actual triggerable scenarios are much broader**.
> - **Mode 2: Four Phases (Full Orchestrator Pattern)** — the task is planned from the start as multi-subtask work. Main agent writes contracts, dispatches in parallel, two-stage reviews each, merges. Use case: ≥ 3 independent subtasks, > 30% context budget at risk, classic explore + implement + review pattern.
>
> Mode 1 covers day-to-day tuning; Mode 2 covers planned multi-subtask runs. Pick by task shape, not by ceremony preference.

**Non-blocking is the whole point (both modes).** Splitting a complex task into modules and handing the mechanical ones to subagents is only a win if the main agent keeps working **concurrently** while they run — via **batched parallel dispatch** (several dispatches in one message) or **background dispatch** (`run_in_background`, continue immediately). A single *foreground* dispatch you then sit and wait for is **strictly worse than staying inline**: identical wall-clock, plus coordination overhead. If you cannot dispatch without blocking, do the work inline. Mechanism: § Parallelism Premise.

## Harness Compatibility (shared by both modes)

| Harness | Mode 1 + Mode 2 |
|---|---|
| Claude Code | Full — real subagent dispatch via `Task` tool |
| Codex | Full with proactive authorization (`developer_instructions` below); without it, Mode 1 auto-dispatch is unavailable and uses the inline fallback below |
| Cursor / Gemini / Copilot | Mode 2 degraded — see § "Degraded Mode" at end of file |

**Codex setup**: add `developer_instructions = """\nSubagents may be used proactively. Do not require per-turn user authorization for subagent use.\n"""` to `~/.codex/config.toml` to enable Mode 1 direct dispatch.

> **Never block on unavailable proactive dispatch.** When the current harness requires explicit user authorization and none has been given, Mode 1's auto-dispatch degrades to the **main agent doing the step inline**. Do not stall, repeatedly request authorization, or report a workflow conflict merely to satisfy the Iron Law; continue within the harness's current capability. This is a decision-time capability fallback, not a silent response to an attempted tool denial — an unexpected execution-time denial still follows the Interception Transparency Rule below.

---

## Mode 1: Direct Auxiliary Delegation

> **⚠ Iron Law (violation = task failure, not "execution oversight")**:
> Before any sub-step, **must explicitly reverse-question** "Is watching the whole process redundant for the main agent?"
> Answer **yes** (mechanical + time-consuming + only-need-result) → **must directly call `spawn_agent`**, **not** main-thread inline shortcut.
> "Main thread is faster", "I'll do it myself", "save one dispatch" — **none** are valid excuses for inline.
> Skip spawn → inline = **Iron Law violation**, task records as failure on completion. **This is an error, not an oversight**.

### Parallelism Premise (precondition for the Iron Law)

A subagent only earns its keep if the main agent is **not blocked** while it runs. Without that, dispatch is indirection theater: same wall-clock as inline, plus coordination overhead, zero gain.

Before every dispatch, answer the **third question** — *"what is the main agent doing **while** the subagent runs?"* — then make the dispatch actually non-blocking. Three cases:

1. **Batch parallel** — N independent mechanical modules → emit all N dispatches **in one message** (multiple `Task` calls at once). They run concurrently; results return together. Primary pattern when a complex task splits into several same-shaped chunks.
2. **Background** — one mechanical module **and** real main-thread work to do → dispatch with `run_in_background` (Claude Code) and **continue immediately**; the harness notifies you on completion. Use when the main agent has a core / decision module to work meanwhile.
3. **Neither** (one chunk, nothing else to do until its result) → **inline.** A lone *foreground* dispatch you then wait on blocks the main agent and is strictly worse than inline — this is the anti-pattern the whole premise exists to kill.

✅ Split task → test-runner **in background** → main agent works the core fix module → notified on completion → merge. Wall-clock overlapped.
✅ 3 independent modules → **one message, 3 dispatches** → run in parallel → review each on return. Wall-clock collapsed.
❌ test-runner in the **foreground** → main agent idles waiting → reads result → continues. Identical wall-clock to inline, pure coordination overhead. A blocked main agent is worse than no subagent at all.

**Context-isolation exception**: when inline reads would drown the main context with raw file content (e.g. surveying 15+ files to answer one question), a foreground dispatch is defensible *without* parallel work — but the value is **context-budgeting, not wall-clock** (small result, large process). Iron Law's three traits (mechanical + time-consuming + only-need-result) still must hold.

### Default habit

Before each sub-step in any workflow, the main agent **auto-asks itself**:

> "Is watching the whole process redundant for the main agent?"

- **Yes** (mechanical + time-consuming + only-need-result) → auxiliary, **directly** call `spawn_agent`, main conversation only sees result
- **No** (discussion / decision / clarification with user is main-agent job) → inline

This is a **continuous self-judgment + auto-dispatch habit**, not a step-level reminder. The signal list below is just common examples — **actual triggerable scenarios are broader**.

### Signal admission test (gatekeeper for adding new signals)

agent reverse-questions every sub-step freely, **not gated by the signal list**. The two gates below are **for adding a new typical scenario to the list**, preventing list bloat:

1. **Reverse-question passes** — "Is watching the whole process redundant?" answers **yes** in typical cases
2. **Scenario is specific** — mechanical + time-consuming + only-need-result

Pass only #1 (reverse-question yes but scenario fuzzy) → don't add (would encourage "everything is redundant").
Pass only #2 (scenario concrete but reverse-question fails) → don't add (overlaps with main-agent's actual job).

### Signal list (5 typical examples, not exhaustive)

1. **Running tests** — any `mvn test` / `pytest` / `jest` / `go test` etc. (time-consuming; main conversation doesn't need every line of output)
2. **Running build / dependency resolution** — `npm install` / `gradle build` / `mvn install` etc.
3. **Wide search / find usage** — accumulated file hits enough to drown main conversation (typically ≥ 10, but not limited)
4. **Batch homogeneous edits** — N files getting same-shape import add/remove / rename / annotation; if planned as fanout from start, go to [`refactor-fanout.md`](refactor-fanout.md) directly
5. **Scanning a large code region for pattern** — flipping through code to find a few callsites

**Not limited to this list**. Any sub-step matching all three traits (mechanical + time-consuming + only-need-result) qualifies.

### Job-vs-auxiliary distinction (not file-counting; ask what the content is used for)

After reading / running, ask:

- Does the main agent **need the content as discussion / decision substrate** (user might ask about details, design choice needs reference, explanation to user uses it) → **main-agent job**, do it inline
- Does the main agent **only need the result for the next decision** (process won't be re-referenced, user won't ask "how did you run it") → **auxiliary**, can dispatch

Examples:

| Scenario | What main agent uses the content for | Verdict |
|---|---|---|
| Fix NPE; read 3 files to locate root cause | Use context to decide the fix + discuss with user | Main-agent job |
| Explore "how does auth work"; read 5 files | Understand it + explain to user | Main-agent job |
| Find 12 callsites of X; pick which to change | Only need the list | **Auxiliary** (dispatch for list) |
| Find 12 callsites of X; review each to decide change | Need each file's content | Main-agent job |

**Key**: same action (read N files) can be main-agent's job or auxiliary, **depending on what the content is used for**. The cut is by purpose, not by action size.

### Decision flow

```text
main agent runs workflow inline
    ↓
about to do next sub-step: ask self "Is watching the whole process redundant?"
    ├── no, main-agent's job  → inline
    └── yes, auxiliary (mechanical + time-consuming + only-need-result)
            ↓
        third question: "what does the main agent do WHILE it runs?"
            ├── N independent chunks → batch dispatch (all in ONE message) ─┐
            ├── 1 chunk + other work → background dispatch, continue now ───┤
            │        → main agent works other modules meanwhile             │
            │        → integrate each result as it returns ─────────────────┘
            └── nothing to do until the result, no context-isolation gain → inline
```

**Properties**:

- Signal recognition is **agent judgment**, not mechanical measurement
- Yes dispatches a **single sub-step**, not the remaining whole task
- Dispatch is **non-blocking**: background (`run_in_background`) or batched in one message — the main agent keeps working meanwhile and never sits idle waiting on a foreground worker. If it would have to sit idle, the dispatch wasn't worth it → inline
- Same task may trigger multiple dispatch events (one for testing, one for wide grep, etc.); each is independent and can overlap
- **No user Y/N round-trip** — global authorization (CC's native dispatch + Codex `developer_instructions`) makes this direct

### Negative list (never delegate, no matter how time-consuming)

The following are **main-agent job, reverse-question should answer "no"**:

- **User-requested core implementation** (business logic, API design, core algorithms)
- **Architecture decisions** (module boundaries, dependency direction, schema, serialization protocols)
- **Security-sensitive operations** (credentials, permissions, encryption, SQL injection risk points)
- **Destructive operations** (`rm -rf`, `git reset --hard`, production config changes, schema deletion / reset, force-push to release branches)
- **Deep-reasoning judgments** (root cause analysis, design tradeoffs, complex business rule interpretation)
- **Back-and-forth user discussion / clarification** (requirement clarification, scope confirmation, tradeoff decisions)

Subagent delegation **only applies to** auxiliary mechanical tasks. Trying to delegate items from the list above = **wrong**, these are main-agent's job, do inline.

**Reverse-failure Pitfall**: delegating core implementation / architecture decisions to subagents. Subagent has no user context → its judgment will drift from actual user needs → main conversation must overturn during review. **2x slower than inline**.

### Common failure modes (Pitfalls)

- **Inspect → Dispatch transition missed (most severe in practice)** — After main agent completes pre-work (reading rules / scanning report / identifying multiple independent targets), it continues inline by inertia into reading implementation details / writing files, **without explicitly switching phase** at the "multiple targets identified" moment. Failure language anchor: **"extending report-screening phase main-thread work into implementation-phase serial work"**.
  - Correct action:
    1. **Stop immediately after identifying multiple targets**, explicitly judge: "Are these targets multiple independent + parallelizable?"
    2. **Yes** (multiple test classes / modules / callsites) → **explicitly announce division + `spawn_agent` separately**; main thread only does integration + verification
    3. **No** (single target / must serialize) → continue inline
    4. **Forbidden extension**: **cannot** go from "I identified N targets" directly into "I read the first target's implementation details"
  - Self-check reverse-question: "Am I in 'pre-work' phase or 'implementation' phase? **If multi-target identified, should I stop and switch phase?**"
- **Skip reverse-question, directly inline** — agent self-justifies "main thread is faster" without asking. **Violates Iron Law**
- **Asked but didn't dispatch** — reverse-question answered "yes" (confirmed auxiliary), but still inline. **Answer must lead to action**: yes → directly spawn; no → inline
- **Inline-job mis-dispatched** — delegating core implementation / architecture to subagent. See Negative list reverse-failure

### Signal is *not*

- Not a task-size signal (test ≥ 3 cycle / refactor ≥ 5 callsites / large file / cross-repo — all rejected; reverse-question fails on them)
- Not a file-count or time threshold (too coarse; not causal with main-conversation pollution)
- Not "anything time-consuming the main agent does should be dispatched" — discussing code, clarifying with user, designing, deciding-where-to-change are all main-agent's job even if time-consuming
- Not a checkpoint block in workflow files (signal recognition is in the agent's head)
- Not a PostToolUse hook (simple tasks must have zero overhead)

---

## Mode 2: Four Phases (When to Invoke This Mode)

Trigger Mode 2 — not just inline + occasional Mode 1 direct dispatch — when **any** of:

- The task decomposes into **≥ 3 independent subtasks** (independent = can be specified, executed, and verified without reading each other's output)
- A single subtask will consume **> 30% of remaining context budget** if done inline
- The work involves **exploratory search + implementation + review** (classic context-pollution pattern)
- You are about to start a **multi-hour autonomous run**

If none of the above apply, **don't invoke Mode 2** — Mode 1 direct dispatch inside an ordinary workflow handles smaller cases without ceremony.

**The four-phase procedure (Plan → Dispatch → Two-Stage Review → Merge/Reject) and its Degraded Mode live in [`subagent-orchestration.md`](subagent-orchestration.md).** Read it when the triggers above fire. The Iron Law, Parallelism Premise, Negative list, Interception Transparency Rule, and the Rationalizations / Red Flags below bind Mode 2 workers and their orchestrator too.

**Coming from a plan?** If the work already has a [`plan-feature.md` § Task Breakdown](plan-feature.md), each task maps 1:1 onto a contract — lift Files / Consumes / Produces / Acceptance straight in, no re-derivation. Each worker ends with one **Return Status** word (`DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED`); the contract template and per-status routing live in [`../protocol-blocks/subagent-contract.md`](../protocol-blocks/subagent-contract.md) and `subagent-orchestration.md` Phase 4.

---

## Interception Transparency Rule (applies to all tools, both modes)

When the agent runs into **any** constraint / interception / permission denial / unavailable tool that it cannot resolve unilaterally, it **must immediately stop and tell the user** — **silent fall back / fallback to plan B / skip / degrade is forbidden**.

Typical: `spawn_agent` blocked by some platform constraint, tool permission denied, command needs interactive input but environment doesn't support, file / network access blocked. **Any obstruction counts**, not limited to this list.

### Wrong behaviors

- ❌ Silent fall back to inline without telling user
- ❌ Switch to plan B (other tool / other path) without telling user
- ❌ Conflate "got blocked" with "I judged this shouldn't be done"

### Right action

1. Stop immediately, tell the user: "I tried X, got blocked by Y / error Z"
2. Offer choices: user does it / I use alternative method W / skip and continue / you authorize me
3. Wait for user decision before proceeding

(Distinction from § Mode 1 Decision: that's **decision-time** self-judgment; this is **execution-time** obstruction that must be surfaced.)

---

## Rationalizations to Reject (both modes)

| Rationalization | Rebuttal |
|---|---|
| "It's faster to just do it myself in the main context" | True for 1 task, false for 3+. You're optimizing the wrong loop. |
| "The worker almost got it right, I'll patch the last 10%" | Inline patching re-pollutes the main context. Re-dispatch with a tighter contract. |
| "I don't have time to write a contract for this small task" | If the task is small enough to skip a contract, it's small enough to not need a subagent. Decide which. |
| "Parallel dispatch is risky, I'll do them sequentially" | Sequential dispatch without a data dependency is a latency defect. Justify it in writing or parallelize. |
| "The worker can figure out the acceptance criteria from context" | Workers have no context. That's the point. Write the criteria. |
| "I'll let the worker spawn its own helpers" | Recursive dispatch makes review impossible. Flatten the plan in Phase 1. |
| "Mode 1: I'll skip the reverse-question, I know this is auxiliary" | The reverse-question is the admission test. Skipping it = inline on auxiliary tasks that should have been dispatched. Just ask the question. |
| "Mode 1: main thread is faster, I'll do it myself" | **Imagined-pain engineering reverse case** — agent self-justifies inline on auxiliary work. Once reverse-question answers "yes", **directly dispatch**. No "I'll do this one inline" exception. |
| "Multi-target identified, but I'll start implementing the first one to save time" | **Inspect → Dispatch transition missed**. Stop at "multi-target identified", explicitly switch phase, then dispatch. No "I'll just do the first one inline". |

## Red Flags — STOP (both modes)

Stop the workflow and reassess if any of these appear:

- You find yourself reading worker output and editing it inline in the main context
- You dispatched a worker without a written contract (Mode 2) or skipped the reverse-question for an auxiliary sub-step (Mode 1)
- A worker returned, Stage A failed, and you're tempted to "just accept it and fix later"
- You're on the third re-dispatch of the same contract → the contract is wrong, not the worker
- You notice the main context has grown past 50% — you're losing the point of the pattern
- A worker asks a clarifying question mid-task → cancel, rewrite contract, re-dispatch
- Mode 1: reverse-question "Is watching whole process redundant?" answered on a main-agent's job task (reading 1-3 files to understand a bug) → admission test failed; revisit job-vs-auxiliary distinction
- Mode 1: reverse-question answered "yes" but you still inlined the work → **Iron Law violation**
- **Any tool / permission / constraint blocked you and you didn't surface it to the user** → see § Interception Transparency Rule
