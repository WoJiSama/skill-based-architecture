# Task Closure Protocol

**This is the cross-cutting closure gate that every behavior-changing task runs — not specific to rule updates.** `fix-bug.md`, `change-managed.md`, `refactor-fanout.md`, `edit-templates.md`, and any other workflow reference this file at their closure step. The *recording mechanics* this gate calls into (threshold, search-before-record, where-to-record, activation check, generalization, tagging) live in [`update-rules.md`](update-rules.md) — closure decides **whether** to record; `update-rules.md` decides **how**.

## Task Closure Protocol

### Task Closure Trigger Policy

Decide the task type first, then decide whether to enter Task Closure Protocol. Do not pay rule-maintenance cost on pure Q&A or read-only tasks.

| Task type | Closure requirement |
|---|---|
| Pure Q&A, code explanation, read-only investigation, advice — and no files changed | No AAR, no smoke-test; just answer |
| Format-only, comment-only, behavior-preserving rename — and no new reusable lesson | No AAR; do text/format checks as needed |
| Modified production code, API / RPC contracts, response shape, validation/exception, transactions, locks, async tasks, or call chains | Run lightweight AAR scan; if all four answers are "no", stop |
| Modified the *meaning* of `skills/` rules / references / workflows documents | Run lightweight AAR, and run the gates whose trigger fires (Search Before Record / cross-reference sync / text checks) |
| Modified `routing.yaml`, `SKILL.md` generated blocks, entry shells, scripts, file paths, or skill structure | Run the corresponding route/structure checks; **only this category defaults to considering** `sync-routing.sh`, `smoke-test.sh`, or orphan audits |
| User explicitly asked for "run full validation / doc health check / smoke-test" | Execute as requested |

`smoke-test.sh` is a skill structure / routing / link / budget validator. It is **not** the default closure action for ordinary code changes, explanation tasks, or read-only investigation.

Once the policy says this task enters the protocol, the task is NOT complete until every triggered gate is handled:

1. **Main work + original-constraint check** — before final validation, restate the original request, chosen route, and forbidden shortcuts; if the task was long/interrupted and you cannot, run `protocol-blocks/reboot-check.md`, then verify/tests pass
2. **30-second AAR scan** — run the checklist below; all "no" = stop here
3. **Record if needed** — any "yes" → apply the **Recording Threshold** and follow the recording mechanics in [`update-rules.md`](update-rules.md) (§ Recording Threshold → Search Before Record → Where To Record → Activation Check → Generalization Rule). **Reconcile before writing** (run `bash scripts/skill-asset where <keywords>` to surface candidate destination sections; merge into the closest existing section, or create a new one only when no fit) → record at the chosen destination
4. **Path integrity gate** — fires only when this task modified skill routing, entry shells, scripts, file paths, generated blocks, or `.md` content that may break links/structure. Run these from the project repo root before commit; fix failures in the same commit:
   - `bash "skills/<skill-name>/scripts/sync-routing.sh" "<skill-name>" --check` — generated Always Read, Common Tasks, and bootstraps match `routing.yaml`
   - `bash "skills/<skill-name>/scripts/smoke-test.sh" "<skill-name>" --phase 8` — markdown links, structure, routing, and budgets still pass
   - `(cd "skills/<skill-name>" && bash scripts/audit-orphans.sh)` — no content-tier file (`rules/` `references/` `architecture/` `gotchas/` `conventions/`) has zero inbound links (link-reachable)
   - `(cd "skills/<skill-name>" && bash scripts/route-reachability.sh)` — every active-tier file (`architecture/` `conventions/` `gotchas/` `rules/`) is reachable by following `routing.yaml` + index hubs (route-reachable, i.e. actually read on a task — not just link-reachable). Fires whenever this task added a content file or changed routing
   - `bash "skills/<skill-name>/scripts/route-health.sh" "<skill-name>"` — advisory routing-quality smells (no/weak triggers, overlap, language); does not block, but review when this task added a route or changed its triggers
   - **Skeleton purity (judgement, not script)** — if this task added an `architecture/` file, apply the test: *after a refactor that renames modules and moves files, is it still true?* An invariant principle → keep. A map / name / path / call-graph of the current code → it is flesh, move it to `references/`. No script can tell a map from a principle; `architecture/` drifting back into a code map is caught here by discipline.
5. **Cross-reference content sync** — if this task changed the *meaning* of a `rules/` or `references/` file (not just paths), grep `workflows/` for files that reproduce the changed invariant and update them in the same commit. Rule meaning drifts silently otherwise; a workflow that repeats a now-wrong invariant actively misleads.
6. **Behavior validation fit** — if the edit adds or changes a high-risk route, non-idempotent workflow, executable script contract, or external skill handoff, decide whether a contract or scenario test is needed; structural smoke tests alone do not prove route behavior.

Do not run gates on tasks the Trigger Policy did not admit into the protocol. Steps 3–6 fire conditionally (3 on AAR hits, 4 on skill routing/structure/link-affecting changes, 5 on rules/references *meaning* changes, 6 on high-risk behavior changes) and are mandatory when their trigger fires.

**Plan-closure prompt — not a gate, but follow it:** if this task flipped a plan in `docs/plans/` to `status: done`, sort every conclusion (wherever in the plan directory or simple plan body it landed) into `rules/` (must / must not), `references/gotchas.md` or SKILL.md § Common Pitfalls (anti-pattern with reasoning), or "neither — pure provenance, stays archived only". Update the plan's `distilled_to:` frontmatter accordingly. No script verifies this — the cost of skipping it is silent: load-bearing content stranded in a frozen plan that nobody re-reads. See `plan-feature.md` step 8 for the full trichotomy.

### Rationalizations to Reject

When the Agent feels the urge to skip the AAR, these are the common excuses and their rebuttals. Every row was captured from a real pressure-test failure — do not argue with them, just refuse.

| Rationalization | Reality |
|---|---|
| "This task changed behavior but is small — skip AAR" | Behavior change is the trigger; size is not. The AAR scan takes 30 seconds; skipping it is slower than doing it. Read-only tasks are already exempted by the Trigger Policy — do not stretch the "small" excuse into "no AAR ever" |
| "I'll run AAR at the end of the session" | You will forget. The scan must happen at task closure, not batched |
| "Nothing new happened, just a routine fix" | If nothing new happened, the scan returns "no" on all four questions in 30 seconds. Do it anyway |
| "The user is in a hurry" | The protocol exists *because* hurry produces the worst pitfalls. Pressure is a reason to run AAR, not skip it |
| "I already know this lesson, don't need to record" | Recording is for future agents, not past you. Current knowledge is not durable |
| "This is covered by the existing rules" | Then the scan returns "no" in 10 seconds. Faster to run it than argue about it |
| "I already read SKILL.md for the previous task" | The new task may match a different route. Context compresses silently. Re-read costs seconds; skipping costs hours of wrong-direction work |
| "User said 'record this' — I'll also archive the full session as YYYY-MM-DD-session-notes.md in `references/`" | "Record" means extract a **generalized, reusable lesson** into `rules/` or `references/<topic>.md`. Dated session narratives belong in `git log` / `CHANGELOG`, never in `references/`. `references/` rejects date-named narrative files — they violate the generalization rule (project-specific story, not reusable knowledge) and the activation rule (no routing path will ever read them) |
| "I changed `rules/<x>.md` — workflows can be checked next task" | Cross-reference drift compounds silently. A workflow that repeats a now-wrong invariant is worse than one missing the new invariant; it actively misleads. The check takes seconds when the edit is fresh; next task, you'll forget what you changed |
| "I'll add the activation pointer to the workflow in a follow-up commit" | Same excuse family as "workflows can be checked next task". The moment you know where the new entry belongs is *now*; after the commit lands, the routing decision evaporates. Either declare the activation path in the same commit, or skip recording entirely |
| "The entry is so obviously useful someone will find it" | "Obvious" is survivor bias — you already know the lesson. Future agents arriving cold see only the route manifest and generated summary; unindexed references are invisible. Activation is navigation, not advertising |
| "I only renamed one file, links are probably fine" | Markdown links have zero compile-time verification — "probably fine" is exactly when drift accumulates. The check takes ~2 seconds; running it is faster than convincing yourself you don't need to |
| "I'll run smoke-test once at the end of the session" | Same failure mode as batched AAR: by the time you remember, you can no longer attribute breakage to a specific edit. Path integrity is per-commit, not per-session |
| "audit-orphans is just for orphans, my edit can't create orphans" | Wrong premise — deleting any inbound link can orphan a previously-linked file. The script runs in seconds; assumptions about what "can't" happen are how silent rot starts |
| "Let me add this safeguard / script / file structure just in case" | 反问:这个保险解决的"未来 / 想象用户"是真踩过的坑还是脑补?要给一个具体场景(file + line / commit / session)证明这事真发生过吗?给不出 → 不上。反模式名:**imagined-pain engineering**(想象痛点工程)— 为未发生的失败加保险、为想象用户预建脚手架、为不存在的协议加 marker / 监控、给假设的"agent 偏差"立规矩。最显眼的症状:agent 自己提议方案后没拷问就开始实施。这条 Rationalization 适用于任何"加东西"的提议,不仅是 update-rules 任务自身 |

### Red Flags — STOP if you catch yourself thinking any of these

- "Just this once" — every skip erodes the protocol
- "I'll fix it in the next task" — the next task will have its own closure
- "Nobody will know I skipped" — the next pitfall will
- "The AAR is for big changes" — scope does not determine value; novelty does
- "This is overhead, not work" — Task Closure *is* the task; anything that ships without it is half-done

## After-Action Review

The 30-second scan from step 2 of the Task Closure Protocol. Run only when the Trigger Policy says this task entered the protocol.

Skip entirely for: pure Q&A, code explanation, read-only investigation, advice with no file changes; formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors.

Checklist:

- [ ] **New pattern** — Did this task use an undocumented pattern or convention?
- [ ] **New pitfall** — Did you hit a problem that wastes significant time if you don't know about it upfront?
- [ ] **Missing rule** — Did the absence of a rule cause you to take a wrong turn?
- [ ] **Outdated/obsolete rule** — Did you find an existing rule that is inaccurate or no longer applicable?

If any answer is "yes", apply the relevant gate in [`update-rules.md`](update-rules.md) before writing anything down: Recording Threshold for new lessons, direct update for outdated rules. If all answers are "no", stop here. The review should stay lightweight, but it is still part of task closure.
