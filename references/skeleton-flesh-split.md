# Reference — Splitting a Skill by Abstraction (骨架 / 肉)

When a `rules/` (or `references/`) file tangles invariant design theory with current-code facts, split it by **abstraction** ([Progressive Rigor](progressive-rigor.md) trigger 3). This is the playbook, distilled from doing it on two real code-coupled skills. It is a *re-tiering of an existing skill*, not the initial scattered→skill migration ([full-migration.md](../workflows/full-migration.md)).

**The judgement test:** *after a big refactor that renames modules and moves files, is this statement still true and useful? Yes → 骨架 (skeleton: invariant theory). It describes the current code — a map / name / path / a landmine at a symbol → 肉 (flesh: current-code facts).*

> Rate of change is a correlated heuristic, but it mislabels **slow-drifting maps** (the module tree) as architecture — they are stable-ish yet they are flesh (a map of the code, not an invariant law). Abstraction is the real cut.

## 1. Classify by abstraction — five buckets

The split is not binary. Going section by section, each lands in one of:

| Bucket | → | Kind | Example |
|---|---|---|---|
| **Abstract design theory** — layering/contract/orchestration **principles**, the "why" (NOT the module map) | `architecture/` | 骨架 | "an existing HTTP contract is a compatibility boundary" |
| **Code maps** — module tree, package/dir layout, source index, the call graph with real symbols | `references/` | 肉 | "modules: web → biz/shared → core → common/dal" |
| Volatile house style — naming, route shapes, paths, commands, formats | `conventions/` | 肉 | "`POST /{entity}/create`", "param names `page`/`limit`" |
| Code-coupled landmines — symptom→cause→fix on specific symbols | `gotchas/` (per module) | 肉 | "change a Controller, rebuild the `start` fat-jar or you run stale bytecode" |
| **Cross-cutting agent behavior / methodology** — delegation discipline, change-discipline, transparency-on-block, AAR triggers | **stays in `rules/`** | 骨架 | subagent-delegation Iron Law |

**Two buckets get missed.** (1) The **code map** looks like architecture but is flesh — `modules-and-packages.md`, a directory layout, a call graph with class names *describe the current code* and drift on every refactor; they go in `references/`, not `architecture/`. Mixing them in makes `architecture/` diverge (re-describing the code) instead of converging on the few invariant principles. (2) **Methodology** is neither architecture nor convention nor gotcha — `rules/` survives as its home (why the template ships `rules/agent-behavior.md`). `architecture/` should end up small and sparse: abstraction is compact.

## 2. Author the new files: verbatim, no duplication, cross-link

- **Reproduce technical content verbatim.** Method names, paths, field names, commands, error codes are the value — never paraphrase or summarize a rule or a gotcha.
- **Do not duplicate content that already lives in another tier file.** A new `architecture/api-contract.md` must not re-print the response-envelope mechanism already in `architecture/response-envelope.md` — cross-link (`[[response-envelope]]`) instead. Duplication re-creates the scatter you are trying to fix.
- **Gotchas stay whole, one file per module.** A bug should read one small module file (`gotchas/hotfix.md`), not a 200-line dump. Don't lump unrelated modules into one file.
- **Consolidate existing scatter.** If the same concept is stated across several old files (one principle repeated in `rules/` and a pitfall file; a module table duplicated in two references; a rule and its later rollback as separate entries), collapse it into one canonical home in the new tier and cross-link from the rest — don't carry the duplication forward. Likewise **elevate** a stable structural fact that was mis-filed as a gotcha up into `architecture/`, so routing surfaces it.

## 3. A split is a path migration — repoint or stub every old-path reference

Moving content out of `rules/backend-rules.md` or `references/gotchas.md` changes the path other files point at. Before deleting an old file:

1. `grep` for every reference to the old path across `workflows/`, `routing.yaml`, thin shells, and `SKILL.md`.
2. **Repoint** the references you own to the new tier paths.
3. For paths hard-referenced by files you can't or won't edit yet (e.g. assembled/vendored copies), leave a **redirect stub** that points to the new home and *actively corrects the stale instruction* ("record new gotchas in `gotchas/<module>.md`, not here"), then delete it once those references are mirrored.
4. **Delete old files with zero remaining references.** An unreferenced redirect stub is itself an orphan — only keep a stub that something still points at.

> A markdown `[]()` link is validated by `smoke-test`'s link check; a bare path in inline code is not. So a redirect's `[]()` links must resolve, but inline-code path mentions are free.

## 4. Every fine-grained tier needs a routed index hub — link-reachable ≠ activated

There are two different "reachable", and they are easy to conflate:

- **Link-reachable** (what `audit-orphans.sh` checks) — some scanned file mentions the path, so it isn't an orphan. **Necessary but not sufficient.**
- **Route-reachable** (activation) — some task's route actually leads the agent to read it during work.

A file can pass `audit-orphans` (e.g. listed in the `SKILL.md` manifest) yet **never be read**, because it is on no task route. That is "stored, not activated" at fine grain — and it is pure waste: you split the file out for cohesion, but the task that needs it never sees it. Real case: a skill split `architecture/` into 9 files but routed only ~4; `architecture/transactions-locks.md` was link-reachable but on no route, so transactional work never read the transaction invariants.

The fix is the hub pattern gotchas already use, applied to **every** fine-grained tier:

- Give each fine tier an `index.md` hub with a **"read when"** column (`transactions-locks.md → read when multi-step write / lock / async`).
- **Route the hub, not every file.** A task's `required_reads` is the relevant hubs (`architecture/index.md`, `conventions/index.md`, `gotchas/index.md`) — small, and complete. The agent reads the hubs and pulls the specific files its change touches. Enumerating every file in every route instead either balloons `required_reads` or silently drops the conditional ones.
- List each file in its hub as an **inline-code skill-root-relative path** (e.g. `architecture/transactions-locks.md`) — that one string doubles as the `audit-orphans` inbound *and* the path the agent reads. Register a new file in its hub the moment you create it, or it is born unreachable. (A *relative* markdown link to just `transactions-locks.md` does **not** satisfy `audit-orphans` — it lacks the tier prefix.)

## 5. Re-derive routing — the split is also a routing redesign

A move that leaves routing untouched produces incoherent routes.

- **Repoint `always_read`** off the split files onto the small cross-cutting set (agent-behavior + change-discipline, optionally the structural spine) — not the old mixed governance files.
- **Re-derive each route's `required_reads`** as the relevant tier hubs (§4) so the agent reaches the specific files it needs, together. The classic failure: `fix-bug` read the pitfalls file but not the architecture rule it needed to act — half an answer.

## 6. Validate

- `audit-orphans.sh` → **0 orphans** (every tier file is link-reachable).
- `route-reachability.sh` → **0 unreachable** (every active-tier file is route-reachable — on a route or in a routed index hub, §4; this is the check that catches the stored-not-activated waste).
- `smoke-test.sh <name>` → tier checks pass (`constraint surface` across rules/architecture/conventions; gotchas tier recognized); `routing.yaml` ≤ 140 lines.
- `route-health.sh <name>` → no routing-quality smells.

## Mechanical notes

- **Watch for assembled / vendored copies.** If the file you're editing is a byte-identical assembled copy of an upstream source (vendor-class, or generated by an assembler), editing it in place gets clobbered on the next sync — confirm the source of truth first.
- **Fanning out the authoring?** If you dispatch one subagent per target file in parallel, **batch ~4 concurrent**. A burst of a dozen+ heavy file-authoring agents reliably trips API connection resets (`ECONNRESET`); small batches do not.
