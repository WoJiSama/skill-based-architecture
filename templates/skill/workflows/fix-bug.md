# Fix Bug Workflow

Use this route to determine whether observed behavior is an implementation defect and, if so, prove a semantically complete repair. For a non-Simple task, [`task-execution.md`](task-execution.md) turns these domain steps into the current Task Anchor and Native Plan without weakening the gates below. Read [`subagent-auxiliary.md`](subagent-auxiliary.md) only for an admitted independent investigation or long result-only check.

## Mandatory Pre-Step

Re-match the task route. Do not preload domain knowledge and do not patch before expected behavior and the actual root cause are established. An explicit business-rule request or a governing Requirement/Plan that already declares the applicable business-domain owner may activate `domain-routing.yaml` immediately after workflow selection; otherwise inspect the smallest reproduction/source slice first. Read the governing Requirement and any consuming Plan directly; their existence alone does not activate a domain. Keywords alone identify candidates. Activate one domain only when expected behavior remains unresolved because of a business type, flow, state, boundary, or invariant.

Reuse a clear observed/expected contract as the fast path. When expected behavior, authority, preserved behavior, scope, or acceptance is still material, use [`change-contract.md`](../protocol-blocks/change-contract.md); when only the technical entry/owner/change point is unresolved, consume [`source-localization.md`](../protocol-blocks/source-localization.md). The resulting bound contract must identify the repair target and root-cause path before mutation.

**Design-or-defect gate:** when behavior depends on business semantics, compare the routed business model, architecture/contracts, and code/tests/runtime. Classify:

- `IMPLEMENTATION_BUG` — implementation violates the current model/contract;
- `DESIGN_CHANGE` — the requested result changes a business type, flow direction, state machine, or core invariant, or moves a stable business boundary;
- `INSUFFICIENT_BUSINESS_CONTEXT` — evidence cannot establish intended behavior.

A Design Change leaves this workflow for an approved Implementation Plan. For insufficient context, search evidence first and cross-check it against any existing user-confirmed answer. Execute [`ambiguous-request-gate.md` § Implementation-Fact Question Gate](../protocol-blocks/ambiguous-request-gate.md#implementation-fact-question-gate): close every decision-relevant trigger/entry, caller, write target or target branch/state, ordering/progression, guard/protection/validation/failure, and UI/API ownership hop; trace distinct flows independently. If evidence and confirmed answers align, continue without another question. Otherwise enter [`define-requirement.md`](define-requirement.md), present the current understanding and real conflict, and ask only a remaining normative ambiguity that could change repair classification or expected behavior. Never ask the user to choose a Current implementation fact, request exhaustive detail, or define an abstract concept from scratch. If the user says the answer is in code, stop asking and finish the trace first. A completely absent model is created only if the user chooses "now". Obvious technical failures need no business model.

Replay the relevant user-confirmed Requirement Decision Context before defining expected behavior or changing code; when the behavior is business-bearing, also read the routed business rule. If a consuming Plan exists, replay only its relevant technical decisions. Purely technical Design-derived work may consume the Plan without requiring a business model. Code/tests/runtime are `current implementation fact`, not authority to rewrite `desired business truth`. If the proposed or in-progress fix would drift from the Requirement mainline, invoke [`task-execution.md` § User Decision Drift Gate](task-execution.md#user-decision-drift-gate) immediately; pause the affected path and consult the user instead of smuggling the change through Bug Fix or reporting it only at Closure.

During Fix Bug, the only source eligible for a `references/business/<module>.md` record is the user's explicit business statement: a correction, answer, expected rule, rationale, boundary, or rejected direction that carries business meaning. The Agent may decide whether that user content is clear, cross-implementation stable, and load-bearing enough to persist, then invoke [`workflows/rule-update/business-truth.md` § Active Bug-Fix Input](rule-update/business-truth.md#active-bug-fix-input) immediately instead of waiting for Task Closure. Preserve the user's meaning faithfully. Do not derive a business rule from the Bug: Bug symptoms, root cause, repaired behavior, code, tests, runtime evidence, and Agent summaries are not `desired business truth`. After Step 8 proves an engineering failure and repair, invoke [`workflows/rule-update/verified-failure.md` § Verified Failure Input](rule-update/verified-failure.md#verified-failure-input) immediately; its technical prevention never enters business as user intent. Fix Bug owns these triggers and current-task acceptance; the typed Rule Update owners own admission, fidelity, reconciliation, provenance, activation, and lifecycle outcome.

## Steps

1. Restate the observed behavior, affected scope, and expected result. Before the first mutation, read [`change-discipline.md`](../rules/change-discipline.md).
2. Classify with the Design-or-defect gate.
3. Reproduce the defect with a failing automated check for the reported reason; if automation is impossible, give repeatable manual steps and why. If the current artifact may already contain a fix, run the original acceptance scenario before deciding whether any edit is needed.
4. Trace the real root cause. Identify the violated invariant, state ownership/provenance, producer-to-consumer call chain, and every affected full/incremental/read/write path. If several independent hypotheses survive and delegation has positive Net Benefit, use `subagent-auxiliary.md`; synthesis stays with the main agent.
5. Apply the **Repair-depth gate** — default to Product Development and repair the invariant-owning boundary, including coordinated multi-layer changes when required. Use Operational Stabilization only for an explicit production/availability/frozen-scope constraint; containment must be reversible and leave the structural repair visibly unresolved.
6. Implement the smallest semantically complete repair; dependency count increases validation duty but cannot veto the correct boundary. Avoid unrelated cleanup.
7. Inspect direct and indirect consumers plus changed contracts, data compatibility, shared state/config, events, and async ordering. Resolve any unknown that could invalidate the fix.
8. Run the same acceptance check to green and the smallest relevant regression across every affected path. If the reported defect depends on a user interaction, entry-point wiring, or a later effect that the lower-level check cannot observe, replay the original scenario through that entry and verify its reported effect on the current artifact. If the required runtime, identity, or data is unavailable, report that scenario as unverified. Escalate to broader runtime or release evidence only when the changed behavior requires it.
9. For each verified engineering failure, run Verified Failure Input now and re-verify any deliverable changed by its canonical write or activation path.
10. Run the [Task Closure Protocol](task-closure.md). Its final AAR handles only additional lessons; it does not defer the verified-failure write.

After three failed approaches, stop and report the attempts and false premise instead of trying a fourth variant.

## Completion Check

- Classification and design basis are explicit.
- The failing check reproduced the real defect before code changed and passes afterward. If no repair was needed, report what the original scenario actually did on the current artifact.
- Invariant ownership, call chain, all affected paths, direct/indirect impact, compatibility, and residual uncertainty were inspected.
- Product Development vs Operational Stabilization was selected from task evidence, not implementation convenience.
- No type/flow/state/invariant change was smuggled through Bug Fix.
- Relevant Requirement decisions and Plan technical choices were replayed, and any normative drift was resolved with the user before continuing.
- Any missing business question was grounded in a concrete flow and an evidence-backed working conclusion before the user was asked to compare or correct it.
- The decision-relevant implementation path was closed; distinct flows were traced independently and no interface, write target, branch protection, call order, or state progression was presented as a user choice.
- Implementation evidence and existing user-confirmed answers were cross-checked; aligned points did not trigger another question, and only ambiguity that could change classification or expected behavior was asked.
- Explicit user business statements were evaluated for durability and qualifying content was faithfully reconciled through `workflows/rule-update/business-truth.md` before Closure. No Bug-derived or Agent-derived content entered the business model, and every verified engineering failure received an immediate technical learning outcome through `workflows/rule-update/verified-failure.md` after red-to-green proof.
- Task Closure ran once after the integrated fix.
- Any activated Change Contract was consumed into the defect classification, repair owner, preserved behavior, and red-to-green proof without copying its complete fields or state transitions here.

## Final Report

Report classification/design basis, root cause, change, red→green verification, blast radius, and uncovered risk. Do not narrate the whole diff.
