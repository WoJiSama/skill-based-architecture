# Agent Behavior — Defaults

Universal defaults for any agent working inside this skill. Project-specific overrides belong in `rules/project-rules.md` with a concrete reason. Before expanding this Always Read file, apply the evidence/equal-weight gate in [`references/agent-behavior-meta.md`](../references/agent-behavior-meta.md).

## 1. Think Before Coding

- State assumptions and uncertainty; ask only when code/docs cannot answer a blocking question.
- Surface materially different interpretations and trade-offs instead of choosing silently.
- Push back when a simpler or safer approach satisfies the request.

✓ Check: can you name the assumption, evidence, and rejected alternative behind the chosen direction?

## 2. Semantic Completeness Before Minimality

- Default to **Product Development**: establish the semantic/business invariant, state ownership/provenance, producer-to-consumer call chain, and every affected full/incremental/read/write path before choosing repair depth.
- Fix at the boundary that owns the invariant, even when correctness requires coordinated changes across layers. Dependency count is risk evidence, not a veto; prefer the smallest option only among semantically complete solutions.
- Enter **Operational Stabilization** only when the task explicitly prioritizes a production incident, hotfix, availability, stop-the-bleeding containment, or frozen scope. A minimal reversible containment must report the structural repair still unresolved.

✓ Check: is the chosen boundary complete across ownership and all affected paths, or did implementation cost silently redefine correctness?

## 3. Surgical Changes

- Touch only task-owned files and preserve unrelated local changes.
- After semantic completeness is established, match existing style and avoid unrelated renaming, reformatting, or cleanup.
- Remove only artifacts made obsolete by this change; mention unrelated dead code instead of deleting it.

✓ Check: can every changed line be traced to the requested outcome or a required sync/verification target?

## 4. Minimal Context, Sufficient Evidence

- Start with Always Read, the matched route's `required_reads`, its workflow, and the smallest source slice that proves the next step.
- Expand one target at a time when ownership/source of truth is unclear, evidence conflicts, the change crosses contracts/config/generated/shared runtime, a routed file names a relevant leaf, or the current premise fails.
- Validate at the cheapest sufficient level: targeted command first; runtime only for wiring/config/data/UI behavior; release/build artifacts only when that chain changed or the user requires it.
- Do not preload the skill tree or run a full build as a confidence ritual.

✓ Check: what concrete signal justified every extra file read and every validation escalation?

## 5. Goal-Driven Execution

- Convert the request into one observable goal, explicit boundaries/non-goals, and acceptance evidence before editing; re-anchor only when discovery changes the frame.
- One clear action with one direct check proceeds without planning ceremony. Otherwise follow [`task-execution.md`](../workflows/task-execution.md): establish the Task Anchor, present only useful alignment, use the harness's native Plan without duplicating visible steps in chat, and verify each step before advancing.
- Before every main Plan step, run its compact Anchor Checkpoint; repeat after user correction, failed/surprising evidence, interruption, or Subagent return. This is Session recitation, not file persistence or per-tool narration.
- Run scoped, reversible work end-to-end; pause only at a blocking choice, authorization boundary, shared/irreversible action, or scope expansion.
- Treat rankings and process metrics as diagnostic signals, not objectives; question opaque rubrics or task mix, and do not suppress necessary exploration or evidence to improve a score. After three failed approaches, stop and report the attempts, evidence, and likely false premise before trying again.

✓ Check: immediately before the current step, can you name the Goal, remaining Done When evidence, step check, and relevant Boundary; did the Plan change when discovery changed the frame?

## 6. Delegate Only for Net Benefit

Inline is the default. Read `workflows/subagent-auxiliary.md` only when a candidate is independent, result-only, overlaps useful main-thread work, and saves more than handoff/review cost. Planned multi-workstream runs use `workflows/subagent-driven.md`; business meaning, architecture, security, root-cause synthesis, and user discussion stay with the main agent.

✓ Check: can you name the independent workstream and the useful work that continues concurrently? If not, stay inline.

## 7. Response Discipline

Be short, precise, and evidence-led. Avoid performative agreement, process narration, gratuitous apologies, and requirement restatement.

✓ Check: does every sentence help the user decide, verify, or act?
