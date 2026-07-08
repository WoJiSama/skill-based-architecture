# Refactor Fan-out Workflow

> **Pervasive reverse-question — default habit**: Inside this workflow's Phase 2 batch edit (and any other sub-step), ask "Is watching the whole process redundant for the main agent?" If yes → **directly** `spawn_agent` per Subagent Contract format. See [`subagent-driven.md` § Mode 1: Direct Auxiliary Delegation](subagent-driven.md#mode-1-direct-auxiliary-delegation) for the trigger criteria and [`subagent-orchestration.md`](subagent-orchestration.md) for the full multi-batch orchestration this workflow uses (mode triggers: `subagent-driven.md` § Mode 2).

Use this for refactors that touch **N independent usage points** of the same construct: renaming a function across 30 files, changing an API signature with many callers, extracting an interface with multiple implementations, migrating a config key.

For single-region refactors (one file, one component), use `workflows/change-managed.md` instead — subagent dispatch only pays off when the work genuinely fans out.

## When to Use

Trigger this workflow when **all** of these are true:

- The change has **one well-defined source-of-truth edit** (the new name, signature, or interface) PLUS **≥ 5 independent application sites** that must follow
- Application sites are **independent**: changing one does not require reading the others' diff
- The same edit pattern repeats across sites (rename, swap call, adapt to new signature) — not bespoke per-site logic

If any condition fails: use `change-managed.md` and do the change sequentially in the main context. The dispatch overhead of subagent fan-out is wasted on < 5 sites or on sites that aren't independent.

## Harness Compatibility

Same as [`subagent-driven.md` § Harness Compatibility](subagent-driven.md#harness-compatibility-shared-by-both-modes) — full parallel dispatch on Claude Code (and Codex with global authorization); degraded harnesses run the batches sequentially with contract discipline: you keep the safety, you lose the parallelism.

## Three Phases

### Phase 1 — Find usage + plan cut-points

Done by the main agent in the main context.

1. **Locate the source-of-truth edit** — the function, type, signature, or config key whose definition will change. Read it.
2. **Find all usage sites** — `grep -rln`, IDE references, or a language-server-driven search. Produce the **literal list** of files (and the line ranges within each, when a file has multiple sites).
3. **Decide cut-points** — group sites into N batches such that:
   - Sites in the same batch can be edited without reading sites in another batch
   - Each batch is roughly even in size (avoid one giant batch + several trivial ones)
   - Shared files (a file containing sites from multiple batches) become a **Forbidden Zone** for all but one batch, or get edited in a Phase 0 by the main agent before fan-out begins
4. **Write down the plan** — list each batch with: files included, the literal find/replace pattern (or transformation rule), the test or check that proves the batch is done. Persist this in `docs/plans/YYYY-MM-DD-<slug>/` if the work justifies a plan folder; otherwise inline in the conversation.

**Stop condition for Phase 1**: the list of batches + per-batch acceptance check is fully written before dispatching the first worker.

### Phase 2 — Fan out

For each batch, dispatch one subagent. Use the **Subagent Contract** format from `workflows/subagent-orchestration.md` Phase 1:

| Field | What goes here |
|---|---|
| **Goal** | "Apply *<the literal transformation>* to all usage sites in *<the list of files>*; do not change behavior beyond the transformation." |
| **Inputs** | The transformation rule (one-line spec), the list of files for this batch only, and the source-of-truth definition the new shape was derived from. **Do not** pass the full usage list across batches — each worker sees only its own slice. |
| **Outputs** | The diff for the batch's files. |
| **Forbidden Zones** | All files not in this batch, plus any "drive-by" edits (no formatting fixes, no comment polish, no rename of nearby identifiers). |
| **Acceptance Criteria** | The literal check from Phase 1 (e.g., `grep -c 'oldName' <files>` returns 0; `bash <test-command>` exits 0). |

Dispatch in parallel — batches are independent by Phase 1 construction.

### Phase 3 — Merge + verify

When workers return, the main agent runs **two stages** per batch (same as `subagent-orchestration.md` Phase 3):

**Stage A — Spec compliance**

- [ ] Worker touched only its batch's files (`git diff --stat` confirms)
- [ ] Acceptance check passes when re-run by the main agent
- [ ] No drive-by edits

If Stage A fails: revert the worker's diff, rewrite the contract, re-dispatch.

**Stage B — Cross-batch consistency**

After all batches' Stage A pass, the main agent runs the **whole-repo check**:

- [ ] `grep -c '<old-pattern>'` across the **entire repo** returns 0 (or only in expected leftovers — declared in Phase 1)
- [ ] Full test suite passes
- [ ] No two batches introduced inconsistent variants of the new pattern (e.g., one batch used `newName` and another used `new_name`)

If Stage B finds inconsistencies → record which batch deviated, re-dispatch with a tighter contract for that batch only. **Do not** patch inline in the main context.

## Rationalizations to Reject

| Rationalization | Rebuttal |
|---|---|
| "I'll just do all the sites myself; 5 isn't that many" | The point is not just speed; it's keeping the main context clean for the **next** task. Even at N=5, subagent dispatch saves the main window. |
| "One worker for everything is fine, the sites are similar" | A single worker handling all sites loses the parallelism. If sites are truly identical, batch by physical region anyway to enable parallel dispatch. |
| "I'll let the worker also fix the typo I noticed nearby" | Drive-by edits violate the contract. Drive-bys are how refactor PRs become unreviewable. Open a follow-up task. |
| "Phase 1 takes too long, I'll just start dispatching" | The cost of a wrong cut-point at Phase 1 is wasted dispatches. The cost of a Phase 1 thirty seconds longer is thirty seconds. |
| "The whole-repo grep in Stage B is paranoid" | The whole-repo grep is exactly how you catch the site you missed at Phase 1. Run it. |

## Red Flags — STOP

- You catch yourself rewriting the contract mid-batch → cancel, fix the contract, re-dispatch.
- Two workers' diffs overlap on the same file → Phase 1 had a bad cut-point. Revert, redo Phase 1.
- A worker asks for the "context" of the broader refactor → contract too narrow. Cancel, expand `Inputs`, re-dispatch.
- The whole-repo grep in Stage B finds matches you didn't expect → there are sites you missed; do not merge until each is decided (in a new batch, or as an intentional leftover).

## Closure

After all batches merge and Stage B passes: run the **Task Closure Protocol** from `workflows/task-closure.md` exactly once (not per batch). A multi-site refactor often produces one or two real lessons — about the old shape, the new shape, or the migration mechanic itself. Apply the recording threshold.

<!-- OPTIONAL: project-specific Stage B commands (test runner, lint, type-check) -->
<!-- OPTIONAL: project-specific Forbidden Zone defaults (e.g., migrations/, vendored deps) -->
