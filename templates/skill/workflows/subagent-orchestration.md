# Workflow: Subagent Orchestration (Mode 2 — Four Phases)

> This is **Mode 2 of [`subagent-driven.md`](subagent-driven.md)** — the full orchestrator pattern for work planned as multi-subtask from the start. Read `subagent-driven.md` first for the mode triggers (§ Mode 2: When to Invoke), the Iron Law, the Parallelism Premise, the Negative list, the Interception Transparency Rule, and the shared Rationalizations / Red Flags — they all bind Mode 2 dispatches too.

### Phase 1 — Plan

Write the full task list **before** touching any subagent or file.

For each item, produce a **Subagent Contract** with these five dispatch fields (the worker adds a Return Status on the way back — Phase 4 routes on it):

1. **Goal** — one sentence, outcome-focused, not procedure-focused
2. **Inputs** — exact file paths, data, or upstream artifacts the worker may read
3. **Outputs** — exact file paths the worker must produce or modify
4. **Forbidden Zones** — files, directories, or side effects the worker must not touch
5. **Acceptance Criteria** — the literal checks the main agent will run in Phase 3

Reject any contract you can't verify mechanically. "Make it clean" is not an acceptance criterion. "`grep -c FILL skills/{{NAME}}/` returns 0" is.

**If a plan already exists** ([`plan-feature.md` § Task Breakdown](plan-feature.md)): each task block already carries Files / Consumes / Produces / Acceptance — lift them into the five fields rather than re-deriving the decomposition from scratch. That is the "zero re-derivation" handoff the plan promised.

**Stop condition for Phase 1:** the full plan must be written down (in a scratch file, the conversation, or a TodoWrite list) before dispatching the first worker. Verbal plans drift.

### Phase 2 — Dispatch

For each contract:

1. Spawn a fresh worker (Claude Code: `Task` tool with the appropriate `subagent_type`; degraded mode: execute inline but reset your mental context — re-read only the contract)
2. Pass the contract verbatim as the task prompt. Do **not** paste the main conversation history.
3. Include the **Iron Law header** ("NO TASK IS COMPLETE WITHOUT A TASK CLOSURE PROTOCOL SCAN" — main work + 30-second AAR + record-if-needed) so the worker knows Task Closure Protocol applies to them too.
4. Dispatch workers **in parallel** when their contracts have no ordering dependency — emit the independent dispatches **in a single message** (multiple `Task` calls at once) so they run concurrently, or give each `run_in_background` and keep working. Dispatching one worker in the foreground and blocking on it before sending the next is a defect unless a data dependency forces the order.

**Dispatch discipline:**

- Require a **Return Status**: the worker must end its report with exactly one of `DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED` (defined in [`../protocol-blocks/subagent-contract.md`](../protocol-blocks/subagent-contract.md) § Worker Return Status). Phase 4 routes on this word.
- Never stream mid-task "clarifications" into the worker's context. If the contract was wrong, cancel and rewrite the contract.
- Never let a worker spawn its own workers (no recursion). Flatten the plan instead.
- Never ask a worker to review its own output.

### Phase 3 — Two-Stage Review

When a worker returns, the main agent runs **both stages** against its output. Do not merge after only one stage.

> When the worker's output is a **judgment or a discovery** (a bug report, a security finding, an exhaustive search) rather than a mechanical edit, compliance review is necessary but **not sufficient** — see [`../references/subagent-verification.md`](../references/subagent-verification.md) for adversarial verification (refute uncertain findings by independent vote) and loop-until-dry (open-ended discovery).

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

**Route on the worker's Return Status first** (this decides *what happens next*); the **Merge / Reject mechanics** below are *how* you execute the DONE and re-dispatch branches.

- `DONE` → run Stage A + B; merge if both pass.
- `DONE_WITH_CONCERNS` → read the flagged concern, then Stage A + B; queue a follow-up contract if the concern is real.
- `NEEDS_CONTEXT` → do not review; widen the contract's `Inputs` and re-dispatch.
- `BLOCKED` → resolve the obstruction (surface to the user per the Interception Transparency Rule if you cannot), then re-dispatch.
- *No status word at all* → treat as `NEEDS_CONTEXT` (per [`../protocol-blocks/subagent-contract.md`](../protocol-blocks/subagent-contract.md) rule 6): clarify and re-dispatch.

**Mechanics:**

- **Merge** (the DONE / DONE_WITH_CONCERNS branch, both stages passing): write one summary line per merged contract into the running task log.
- **Reject** (the re-dispatch branch): cancel the worker's changes (`git restore`, revert the diff, or discard the worker's patch). Rewrite the contract. Re-dispatch. Do **not** fall into the "I'll just fix it myself in the main context" trap.

---

## Degraded Mode (Mode 2 specific, no native dispatch)

When the harness has no subagent primitive and you're invoking **Mode 2** (Cursor / Gemini / Copilot without `Task`-like tools), simulate the discipline:

1. Write the contract in a scratch file
2. Clear your mental state: re-read **only** the contract, ignore prior conversation
3. Execute the contract
4. Return to "main agent" mode: re-read the contract, run Stage A + Stage B against the diff
5. Merge or revert

You lose process isolation but keep contract discipline and two-stage review. That alone catches most drive-by defects.

<!-- OPTIONAL: project-specific Phase 3 verification commands (test runner, lint, type-check) -->
<!-- OPTIONAL: project-specific Forbidden Zone defaults (e.g., migrations/, vendored deps) -->
