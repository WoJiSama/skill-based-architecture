# Workflow: Subagent-Driven Development

> Dispatch independent subtasks to fresh-context worker agents instead of doing everything in the main context. Keeps the main context clean, makes review objective, enables long autonomous runs.

## When to Use

Trigger this workflow when **any** of the following is true:

- The task decomposes into **≥ 3 independent subtasks** (independent = can be specified, executed, and verified without reading each other's output)
- A single subtask will consume **> 30% of remaining context budget** if done inline
- The work involves **exploratory search + implementation + review** (classic context-pollution pattern)
- You are about to start a **multi-hour autonomous run**

If none of the above apply, do the work inline — subagent dispatch has overhead.

## Harness Compatibility

| Harness | Support | Notes |
|---|---|---|
| Claude Code | Full | Native `Task` tool + subagent types |
| Cursor | Degraded | No native dispatch; follow the checklist in a single context |
| Codex CLI | Degraded | Open a fresh session manually per subtask, or run inline |
| Gemini / Copilot / OpenCode | Degraded | Same as Codex |

**Degraded mode is not worthless** — the two-stage review checklist and the subagent contract still catch real defects even without process isolation. Run the protocol; skip only the literal dispatch.

## The Four Phases

### Phase 1 — Plan

Write the full task list **before** touching any subagent or file.

For each item, produce a **Subagent Contract** (see [`templates/protocol-blocks/subagent-contract.md`](../../../templates/protocol-blocks/subagent-contract.md)). Every contract has exactly five fields:

1. **Goal** — one sentence, outcome-focused, not procedure-focused
2. **Inputs** — exact file paths, data, or upstream artifacts the worker may read
3. **Outputs** — exact file paths the worker must produce or modify
4. **Forbidden Zones** — files, directories, or side effects the worker must not touch
5. **Acceptance Criteria** — the literal checks the main agent will run in Phase 3

Reject any contract you can't verify mechanically. "Make it clean" is not an acceptance criterion. "`grep -c FILL skills/{{NAME}}/` returns 0" is.

**Stop condition for Phase 1:** the full plan must be written down (in a scratch file, the conversation, or a TodoWrite list) before dispatching the first worker. Verbal plans drift.

### Phase 2 — Dispatch

For each contract:

1. Spawn a fresh worker (Claude Code: `Task` tool with the appropriate `subagent_type`; degraded mode: execute inline but reset your mental context — re-read only the contract)
2. Pass the contract verbatim as the task prompt. Do **not** paste the main conversation history.
3. Include the **Iron Law header** (see [`templates/protocol-blocks/iron-law-header.md`](../../../templates/protocol-blocks/iron-law-header.md)) so the worker knows Task Closure Protocol applies to them too.
4. Dispatch workers **in parallel** when their contracts have no ordering dependency. Sequential dispatch is a defect unless justified.

**Dispatch discipline:**

- Never stream mid-task "clarifications" into the worker's context. If the contract was wrong, cancel and rewrite the contract.
- Never let a worker spawn its own workers (no recursion). Flatten the plan instead.
- Never ask a worker to review its own output.

### Phase 3 — Two-Stage Review

When a worker returns, the main agent runs **both stages** against its output. Do not merge after only one stage.

**Stage A — Spec Compliance**

- [ ] Did the worker produce every file listed in `Outputs`?
- [ ] Did the worker touch any file in `Forbidden Zones`? (Run `git status` / `git diff --stat` to verify.)
- [ ] Does every acceptance criterion pass when executed literally?
- [ ] Are there drive-by changes not covered by the contract? (Drive-bys are defects even if they look helpful.)

If any Stage A check fails → **reject and re-dispatch** with a corrected contract. Do not patch the worker's output inline in the main context; that re-pollutes the main window.

**Stage B — Quality Review**

- [ ] Code quality per `skills/{{NAME}}/rules/coding-standards.md`
- [ ] No swallowed errors, no silent fallbacks, no hardcoded secrets
- [ ] New gotchas surfaced? → candidate for `references/gotchas.md`
- [ ] Task Closure Protocol 30-second AAR scan on the delta (see [SKILL.md](../SKILL.md) Principle 10)
- [ ] Recording threshold (2/3) applied to any new findings

If Stage B finds issues but Stage A passed → record the issues, then decide: re-dispatch (preferred for non-trivial issues) or accept with a follow-up contract queued.

### Phase 4 — Merge or Reject

- **Merge**: only when both stages pass. Write one summary line per merged contract into the running task log.
- **Reject**: cancel the worker's changes (`git restore`, revert the diff, or discard the worker's patch). Rewrite the contract. Re-dispatch. Do **not** fall into the "I'll just fix it myself in the main context" trap — that's the exact failure mode subagent-driven development is designed to prevent. See the Rationalizations table.

## Rationalizations to Reject

| Rationalization | Rebuttal |
|---|---|
| "It's faster to just do it myself in the main context" | True for 1 task, false for 3+. You're optimizing the wrong loop. |
| "The worker almost got it right, I'll patch the last 10%" | Inline patching re-pollutes the main context. Re-dispatch with a tighter contract. |
| "I don't have time to write a contract for this small task" | If the task is small enough to skip a contract, it's small enough to not need a subagent. Decide which. |
| "Parallel dispatch is risky, I'll do them sequentially" | Sequential dispatch without a data dependency is a latency defect. Justify it in writing or parallelize. |
| "The worker can figure out the acceptance criteria from context" | Workers have no context. That's the point. Write the criteria. |
| "I'll let the worker spawn its own helpers" | Recursive dispatch makes review impossible. Flatten the plan in Phase 1. |

## Red Flags — STOP

Stop the workflow and reassess if any of these appear:

- You find yourself reading worker output and editing it inline in the main context
- You dispatched a worker without a written contract
- A worker returned, Stage A failed, and you're tempted to "just accept it and fix later"
- You're on the third re-dispatch of the same contract → the contract is wrong, not the worker
- You notice the main context has grown past 50% — you're losing the point of the pattern
- A worker asks a clarifying question mid-task → cancel, rewrite contract, re-dispatch

## Degraded Mode (no native dispatch)

When the harness has no subagent primitive, simulate the discipline:

1. Write the contract in a scratch file
2. Clear your mental state: re-read **only** the contract, ignore prior conversation
3. Execute the contract
4. Return to "main agent" mode: re-read the contract, run Stage A + Stage B against the diff
5. Merge or revert

You lose process isolation but keep contract discipline and two-stage review. That alone catches most drive-by defects.

<!-- FILL: project-specific Phase 3 verification commands (test runner, lint, type-check) -->
<!-- FILL: project-specific Forbidden Zone defaults (e.g., migrations/, vendored deps) -->
