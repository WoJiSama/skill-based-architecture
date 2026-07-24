# Fix Bug Workflow

Use this route to determine whether observed behavior is an implementation defect and, if so, prove a semantically complete repair. For a non-Simple task, [`task-execution.md`](task-execution.md) turns these domain steps into the current Task Anchor and Native Plan without weakening the gates below. Read [`subagent-auxiliary.md`](subagent-auxiliary.md) only for an admitted independent investigation or long result-only check.

## Mandatory Pre-Step

Re-match the task route. No patch before expected behavior and the actual root cause are established.

**Design-or-defect gate:** when behavior depends on business semantics, compare the routed business model, architecture/contracts, and code/tests/runtime. Classify:

- `IMPLEMENTATION_BUG` — implementation violates the current model/contract;
- `DESIGN_CHANGE` — the requested result changes a business type, flow direction, state machine, or core invariant, or moves a stable business boundary;
- `INSUFFICIENT_BUSINESS_CONTEXT` — evidence cannot establish intended behavior.

A Design Change leaves this workflow for an approved Plan. For insufficient context, search evidence first and ask only the missing macro question; a completely absent model is created only if the user chooses “now”. Obvious technical failures need no business model.

## Steps

1. Restate the observed behavior, affected scope, and expected result; freeze the Done Contract: reproduction, smallest relevant regression, and concrete signals that would require broader validation.
2. Classify with the Design-or-defect gate.
3. Reproduce the defect with a failing automated check for the reported reason; if automation is impossible, give repeatable manual steps and why.
4. Trace the real root cause. Identify the violated invariant, state ownership/provenance, producer-to-consumer call chain, and every affected full/incremental/read/write path. If several independent hypotheses survive and delegation has positive Net Benefit, use `subagent-auxiliary.md`; synthesis stays with the main agent.
5. Apply the **Repair-depth gate** — default to Product Development and repair the invariant-owning boundary, including coordinated multi-layer changes when required. Use Operational Stabilization only for an explicit production/availability/frozen-scope constraint; containment must be reversible and leave the structural repair visibly unresolved.
6. Implement the smallest semantically complete repair; dependency count increases validation duty but cannot veto the correct boundary. Avoid unrelated cleanup.
7. Inspect direct and indirect consumers plus changed contracts, data compatibility, shared state/config, events, and async ordering. Resolve any unknown that could invalidate the fix.
8. **Validate the frozen set:** run the same acceptance check to green and the smallest relevant regression across every affected path. Escalate only when a named risk signal fired; green is the stop signal, not permission to add new coverage, runtime startup, or broader suites.
9. Run the [Task Closure Protocol](task-closure.md). Record only a lesson that passes its gates and has an action-changing route.

After three failed approaches, stop and report the attempts and false premise instead of trying a fourth variant.

## Completion Check

- Classification and design basis are explicit.
- The failing check reproduced the real defect before code changed and passes afterward.
- Invariant ownership, call chain, all affected paths, direct/indirect impact, compatibility, and residual uncertainty were inspected.
- Product Development vs Operational Stabilization was selected from task evidence, not implementation convenience.
- No type/flow/state/invariant change was smuggled through Bug Fix.
- Task Closure ran once after the integrated fix.

## Final Report

Report classification/design basis, root cause, change, red→green verification, blast radius, and uncovered risk. Do not narrate the whole diff.
