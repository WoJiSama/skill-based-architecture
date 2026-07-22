# Change-Managed Workflow

Use this for non-bug changes whose partial edits can drift: features, refactors, generated/copied files, shared configuration, or changes with derived targets. For a non-Simple task, [`task-execution.md`](task-execution.md) turns these domain steps into the current Task Anchor and Native Plan; this workflow remains authoritative for their meaning and order. Use [`subagent-auxiliary.md`](subagent-auxiliary.md) only for one admitted auxiliary workstream and [`refactor-fanout.md`](refactor-fanout.md) only for several independent usage batches.

## Steps

1. **Define scope** — name owned files/modules and the observable outcome. For business-bearing work, record `business-model impact: unchanged / proposed change / unknown`; a proposed type/flow/state/boundary/invariant change requires an approved Plan.
2. **Find the source of truth and owner** — distinguish canonical content/state from generated, copied, or downstream consumers; trace provenance and the producer-to-consumer call chain.
3. **Map semantic fan-out** — name the invariant and list every affected full/incremental/read/write path, derived target, registration, test, and doc/index that must stay synchronized.
4. **Choose the owning boundary** — default to Product Development and make every coordinated change needed for semantic completeness. Operational Stabilization requires an explicit production/availability/frozen-scope constraint and must expose unresolved structural work.
5. **Make the smallest semantically complete change** — use minimality only to choose among complete solutions; preserve unrelated edits and avoid adjacent cleanup.
6. **Sync derived files** with the owning generator/copy process.
7. **Check drift** across all mapped targets and semantic paths.
8. **Validate behavior** with the cheapest sufficient fresh evidence; escalate only when concrete runtime/release risk requires it.
9. **Run [Task Closure](task-closure.md)** once after the integrated change.

If templates, scaffolds, entry shells, or reusable project structure change, also follow [`edit-templates.md`](edit-templates.md). If this project has already activated an operation-permission model, apply its pre-operation classifier and closure check; the default scaffold assumes none.

## Completion Check

Scope, invariant, ownership/provenance, call chain, all semantic paths, fan-out targets, sync, drift, targeted validation, and Task Closure are all accounted for.
