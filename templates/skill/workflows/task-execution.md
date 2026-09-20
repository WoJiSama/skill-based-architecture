# Task Execution Protocol

Use this after matching the task route when continuity is needed or the request adds or changes user-visible behavior, a business flow/state, or an external contract. The matched Domain Workflow remains authoritative for task-specific procedure and mandatory gates. Classify by whether an explicit goal or requirement changes execution, not by tool-call, file, estimate, or elapsed-time count.

## Task Classifier

| Class | Signal | Action |
|---|---|---|
| Simple | one clear read-only or fixed-contract maintenance action, one direct check, no new desired behavior/contract, little room to drift | execute directly; do not display an Anchor or Plan |
| Managed | a `requirement-ready` addition/change to user-visible behavior, business flow/state, or external contract; or dependent steps, meaningful boundaries, repeated verification, or material drift risk | establish a Task Anchor; after `implementation-ready`, use a concise Native Plan and present only useful alignment |
| Requirement | unresolved desired goal, scope, model/flow, rule/constraint, permission, preservation, or acceptance | use `define-requirement.md`; do not create an implementation Plan |
| Design | a technical architecture choice between implementations that preserve a ready Requirement | use `plan-feature.md`; after `implementation-ready`, convert its result into a Managed task |

Apparent code locality never makes requirement-bearing work Simple. If a legitimate Simple task exposes new desired behavior, diagnosis or repeated repair, dependent owners, contract fan-out, or material drift risk, reclassify before more mutation, preserve current evidence, and build only the remaining Native Plan rather than asking the user to restate the task.

## Evidence and Knowledge Gate

- Start with the selected workflow and the smallest source/runtime slice that can resolve the current decision. Requirement-bearing changes always evaluate [`change-contract.md`](../protocol-blocks/change-contract.md); clear input may satisfy `requirement-ready` immediately without questions, while a normative gap enters [`define-requirement.md`](define-requirement.md). After readiness, create the Task Anchor projection, then consume [`source-localization.md`](../protocol-blocks/source-localization.md) for technical ownership and complete Implementation Binding. Fixed-contract Simple tasks keep the direct fast path. Expand one target at a time only when ownership is unclear, evidence conflicts, a contract/generated/shared boundary is crossed, a routed file names a needed leaf, or the current premise fails.
- Do not read `domain-routing.yaml` at task startup. Read it immediately after workflow selection only for an explicit business-rule request or a governing Plan that already declares the applicable business-domain owner; for ambiguous work, read it only after minimal evidence exposes an unresolved business type/flow/state/boundary/invariant. Read every governing Plan directly through its workflow; a Plan's existence alone is not domain evidence. Keywords identify candidates, not activation. Clearly technical work skips the manifest.
- A domain route appends knowledge and never replaces the selected workflow. Load one owner by default; add another only with explicit cross-domain evidence.
- Treat `subagent-driven.md` as a cross-cutting modifier, never a first-workflow route. Read it only after the primary workflow and Task Anchor expose at least three plausible independent workstreams with useful execution overlap; task size or duration alone does not activate it.
- Before the first mutation, read `rules/change-discipline.md` and only the project/coding rules whose scope the planned change reaches. Load an adopted testing contract when constructing evidence, and load `task-closure.md` only after local execution is complete and either all goal evidence exists or only explicit delivery-dependent evidence remains.
- For every bounded search/read, name the current question, the result that would select the next read, and the evidence boundary that would make the result complete enough for this decision. Ranked, sampled, truncated, or Top-N output is candidate evidence, not an exhaustive inventory; expose the cap and the uninspected remainder before making a completeness claim.
- Treat read volume and elapsed time as diagnostic evidence, never correctness gates. Validate at the cheapest level that can falsify the material risk and stop when the declared evidence contract passes.

## Task Anchor

After `requirement-ready` and before implementation-binding discovery, freeze one
risk-sized Task Anchor in current-Session state: project the observable Goal,
Done When acceptance, and only material Boundaries such as scope, non-goals,
preservation, and permission limits from the Requirement Contract. Do not copy
the full Requirement or add implementation steps. The Anchor governs the
bounded localization/binding work that follows and the eventual stop point.

After source localization makes the Change Contract `implementation-ready`,
derive the Native Plan from the matched Domain Workflow and Implementation
Plan. The Native Plan owns only implementation/proof steps and live status; it
cannot infer or edit the Requirement. Before the first mutation, map each
material acceptance/risk to fitted evidence and its advance, return, stop, and
escalation conditions. Technical evidence that changes only Current facts,
owner, implementation premise, or ordering re-localizes, rebinds, and replans
without editing the Anchor. Evidence that conflicts with desired meaning or
would change Goal, Done When, scope, preservation, permission, or acceptance
returns to Requirement Definition; only after the authoritative Requirement is
updated and reaches `requirement-ready` again may Task Execution re-project the
Anchor and replace the remaining Native Plan. Neither Anchor nor Plan is
another persistent artifact.

For Design-derived work, retain every governing Requirement and Plan path. Replay relevant user-confirmed Requirement Decision Context before deriving or changing the Task Anchor, and replay only the Plan's technical decisions needed by the current step. Do not lose a rule, boundary, rationale, acceptance condition, or technical constraint. Only business-bearing decisions require a routed business rule.

### Composite Plan Handoff

When one outcome governed by a common Requirement projection consumes technical work from multiple independently maintained Component Plans, Task Execution first projects that Requirement into exactly one Integrating Task Anchor, then reads [`composite-plan-execution.md`](../protocol-blocks/composite-plan-execution.md) before mutation. The protocol validates Requirement-owned meaning/boundary/acceptance separately from Plan-owned interfaces/order/proof and returns technical integration readiness or a precise Requirement/Plan owner to revisit. Only after `implementation-ready` does Task Execution derive one Integrating Native Plan. Components never create competing runtime anchors, step stores, or semantic `Current Task` entries.

### Presentation Gate

Present only useful alignment for the user to verify direction; do not repeat a visible Native Plan merely to prove an Anchor exists. Write user-facing messages in the user's natural language. Internal SBA terms — protocol, gate, and state names such as Task Anchor, `requirement-ready`, Native Plan, or blast-radius — may appear only with a one-sentence plain-language explanation at that spot, and section headers use plain user-language words, never internal terms.

Evaluate **Structured Brief first**. If any Structured condition matches, it wins; Compact Alignment is allowed only when all Structured conditions are false.

- **Structured Brief**: trigger when the task is long, complex, scope-sensitive, confirmation-dependent, or lacks a visible native Plan surface. The first user-facing task-start message MUST begin with separate plain-language sections for the goal, completion criteria, material boundaries, and steps — headed with natural words in the user's language (例如 目标 / 完成标准 / 边界 / 步骤), never internal terms such as "Goal / Done When / Boundaries". Steps must be numbered; do not collapse the brief into prose or render empty headings.
- **Compact Alignment**: only when no Structured condition matches, use one compact natural-language alignment when useful. If the native Plan/Task surface is visible, do not repeat its steps in chat.

After `implementation-ready`, use the harness's native Plan/Task surface or a concise Session checklist for step state. Before that state, keep only the current Requirement/Anchor and bounded implementation-binding question; do not disguise discovery as an implementation Plan. This protocol does not create durable planning files or recover task state across Sessions. Proceed unless a real decision, authority boundary, scope expansion, or shared/irreversible action blocks.

## Workflow Boundary

Workflow is the reusable procedure and owner of domain gates/evidence; Native Plan is its task-specific instance and sole runtime step owner; Task Anchor owns Goal, Done When, and material Boundaries. A user-visible Plan may group Workflow steps but cannot omit or semantically reorder a mandatory gate.

## Database-Structure Mutation Gate

When evidence shows a table, column, index, constraint, sequence, trigger, type, or other persistent schema structure will change, do not mutate persistence/application code until the governing Plan's Database-Change Artifact Gate has passed: the user saw and confirmed a separate schema-impact checkpoint, the real current schema and dialect are known, a dedicated Plan-local SQL sibling is implementation-ready, and the project execution owner plus current DB authorization are explicit. Read-only discovery may continue. The SQL artifact is a review/handoff contract, never permission to bypass the project migration workflow or write a database.

## Recitation Loop

Before each main Plan step, bring a compact Anchor Checkpoint into current attention: `Goal`, remaining `Done When`, `Current Step` with unresolved question/evidence/advance-or-return condition, and only currently relevant `Boundaries`.

For Design-derived work, the checkpoint also names relevant user-confirmed decisions and, when business-bearing, any declared `desired business truth` / `current implementation fact` gap. Reference the Plan; do not duplicate its transcript.

Run the checkpoint again after a later user message, a failed check or surprising premise change, a Subagent return, an interruption/compaction, and immediately before scope expansion, a shared/irreversible action, or Closure. Keep it internal unless a status update or changed Goal matters to the user; do not narrate it before every tool call.

If the Goal or Done When can no longer be stated accurately from the current Session, stop mutation and reconstruct them from the user request, matched route, and Workflow before continuing. Do not invent missing task state or create persistence as a fallback.

## Verified Failure Handoff

When a command, test, runtime check, delivery action, or implementation premise fails, keep one Session-only failure candidate with the affected boundary and current evidence. Retries inside the same unresolved task remain one occurrence. Do not persist the raw message or first hypothesis. If diagnosis, repeated repair, or cross-step verification makes a Simple task nontrivial, reclassify it as Managed and preserve the candidate in the Task Anchor.

After evidence proves the root cause, the current repair, and fitted red-to-green behavior, invoke [`workflows/rule-update/verified-failure.md` § Verified Failure Input](rule-update/verified-failure.md#verified-failure-input) before the candidate can disappear or the task enters Closure. Verified Failure owns durable reconciliation and returns one learning outcome; Task Execution owns only the Session candidate, reclassification, and proof handoff.

## Execution Loop

1. Keep exactly one main step active; pending steps remain explicit.
2. Run the Anchor Checkpoint, then name the current step's unresolved question, the evidence that could resolve or falsify it, and the advance/return condition before acting.
3. Mark the step complete only when the resulting evidence satisfies that condition and either changes the next decision, is consumed by the next step, or satisfies remaining Done When evidence. Running a command, generating a file, receiving a successful exit code, writing code, spending effort, or a worker's claim is not completion evidence by itself.
4. If evidence satisfies the condition, advance only after confirming the next step serves the Goal and respects Boundaries. If it contradicts the premise, return to the owning earlier step; if it is inconclusive, keep the step open and change the check or escalate under the declared condition.
5. If technical evidence changes only the implementation premise or ordering,
   update Implementation Binding and the remaining Plan before more mutation;
   do not edit the Anchor. If it would change Goal, scope, Done When,
   preservation, permission, acceptance, or other desired meaning, return to
   Requirement Definition and re-project the Anchor only after the Requirement
   is authoritative and `requirement-ready` again.
6. Never silently overwrite a load-bearing conclusion. Re-check the governing Requirement mainline, acceptance, Boundaries, Task Anchor, and each Plan's technical choices; obtain the requirement/business owner's confirmation before adopting a normative judgment, and replan technical choices when only implementation evidence changes.

Independent Subagents may work concurrently, but the main task keeps one integration/decision focus. Their outputs are candidate evidence until the main Agent reviews them and runs the owning step's check.

## User Decision Drift Gate

When code, tests, runtime evidence, review, or a proposed implementation conflicts with user-confirmed product meaning, business rule, scope, flow, state, boundary, invariant, acceptance condition, or user-visible behavior, pause the affected path immediately and read [`user-decision-drift.md`](../protocol-blocks/user-decision-drift.md) before choosing or resuming. Ordinary implementation choices that preserve those decisions do not trigger this gate. Independent work may continue only when it cannot prejudge the decision. Domain workflows may repeat this trigger and immediate pause, but the protocol block owns evidence, user consultation, Decision Delta transition, synchronization, and resume conditions, including updating the Task Anchor and remaining Native Plan before more mutation. Never silently compromise a confirmed mainline to fit current code.

## New Message Gate

For each later user message: a refinement/correction first updates the Requirement through [`define-requirement.md` § Decision Authority And Source Fidelity](define-requirement.md#decision-authority-and-source-fidelity), then re-projects the Anchor, rebinds implementation facts, and replaces the remaining Plan as needed; a new independent outcome re-matches the route and replaces them; a status question reports Goal/current step/verified results without changing state; pause/stop leaves unverified steps incomplete. Already-clear wording stays verbatim, optional grammar/word-order cleanup cannot delete a clause or change its force, ownership, timing, uncertainty, reason, boundary, or status, and an Agent-derived summary cannot be the only normative record.

## Exit To Closure

Enter `task-closure.md` only when every non-delivery Plan step is verified, local evidence for the governing Requirement acceptance is present, Boundaries were respected, each triggered conditional protocol returned a resolved outcome, and every verified failure has a Rule Update learning outcome. Any remaining Done When evidence must be explicitly delivery-dependent and named. Closure decides readiness/completion and conditionally loads specialized proof owners; it does not finish implementation work, diagnose root cause, or grant delivery authority.
