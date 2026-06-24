# Plan Feature Workflow

> **Pervasive reverse-question — default habit**: Before each sub-step, ask "Is watching the whole process redundant for the main agent?" If yes (mechanical + time-consuming + only-need-result) → **directly** `spawn_agent` (global authorization assumed), main conversation only sees the result. See [`subagent-driven.md` § Mode 1: Direct Auxiliary Delegation](subagent-driven.md#mode-1-direct-auxiliary-delegation). **Not limited to specific list**, any sub-step may trigger (prd inspection / wide exploration / running tests…).

Use this for planning requests. Only complex plans get a `docs/plans/.../` folder; simple plans stay inline in the conversation unless the user explicitly asks for a file.

## Complexity Gate

| Size | Signal | Action |
|---|---|---|
| Trivial | typo, comment, obvious one-line change | skip this workflow |
| Simple | clear goal, 1-2 files, no product ambiguity | ask at most one confirmation question; no folder |
| Complex | multiple files, unclear behavior, external dependency, architecture choice, or long run | create a plan folder and continue below |
| Large | multi-subsystem, irreversible / expensive, high uncertainty, or many unknowns to resolve before building | plan folder **+ multi-perspective analysis** (§ Large Plan) — depth and angle-count scale with the task; a thin single-file plan here is under-analysis |

## Question Gate

Before asking any question, pass all three gates:
1. **Gate A: Derivable?** If code, docs, configs, tests, issue text, or quick primary-source research can answer it, inspect first. Do not ask.
2. **Gate B: Meta / lazy?** Never ask "should I search?", "can you paste the code?", or "what does this repo look like?" when the repo or source is available. Take the action.
3. **Gate C: Blocking / Preference / Derivable?** Ask only `Blocking` or `Preference` questions. Resolve `Derivable` questions yourself and record evidence.

Ask one question at a time. Prefer 2-3 concrete options with trade-offs for preference questions.

## Simple Plan

For Simple tasks, do not create `docs/plans/` and do not write `.skill-workflow-state`. Produce a short inline plan with scope, steps, and validation. If one confirmation is needed, ask it before writing the plan.

## Complex Plan

For Complex tasks, create one directory:

```text
docs/plans/YYYY-MM-DD-<slug>/
└── prd.md       ← frontmatter goes here; everything else is your call
```

That is the entire required structure. Add whatever else this specific task needs — research notes, a decisions log (lifted into `rules/` / `references/gotchas.md` at closure, step 8), a research/ subfolder with quoted snippets + source paths/URLs — using natural filenames; none of these names are canonical. If the task only ever produces `prd.md`, that is correct and complete.

Keep `prd.md` short: goal, scope, requirements, acceptance criteria, out of scope, and current open questions. Push supporting material out into sibling files when `prd.md` itself starts to bloat — not preemptively.

## Large Plan — analyze from several angles (立体)

**Plan depth scales with task complexity.** The anti-bloat guidance above ("keep `prd.md` short", "one file is correct and complete") forbids *ceremony* — pre-created empty files, boilerplate sections, a test-plan stanza copied into every plan. It is **not** a licence to under-analyze a hard problem. The same "add siblings only when the task needs them" rule (Complex Steps #2) cuts the other way for a Large task: it genuinely needs them. A multi-subsystem, irreversible, or high-uncertainty task that produces a 100-line single-file plan is **under-planned** — the analysis is missing, not concise.

For a Large task, examine the problem from several **angles**, each its own file — a *lens* on the problem, not a boilerplate section. `prd.md` stays short and becomes the **synthesis/index**: it states the chosen path and points at the angle files; the depth lives in them. Pick the lenses this task actually warrants — this is a menu, not a checklist; an irrelevant lens is the ceremony the gate above forbids.

| Lens (natural filename) | The angle it analyzes |
|---|---|
| `architecture.md` | components, boundaries, data flow, where the change lands |
| `risks.md` | failure modes, blast radius, fail-open vs fail-closed, what state persists |
| `alternatives.md` | the design space — options weighed and why the chosen one wins |
| `contracts.md` | schema / API / wire-format / data-model impact + the concrete migration artifact |
| `integration.md` | what it touches, who depends on it, cross-repo / cross-service surface |
| `rollout.md` | sequencing, migration, rollback, verification strategy |
| `decomposition.md` | build order + parallelizable cut-points (feeds Mode 2 subagent contracts) |

Each angle is an **independent analysis** — ideal for parallel dispatch. When the lenses are independent, fan them out as analysis subagents ([`subagent-driven.md` § Mode 2](subagent-driven.md#mode-2-four-phases-when-to-invoke-this-mode)), one per lens, then **synthesize** their outputs in `prd.md`. That is the "立体" plan: one problem seen from several angles at once, not one linear pass. Before freezing, run **Decision Completeness** (below) and diff overlapping claims across the angle files — the same decision restated in two files drifts.

## Complex State File

For Complex tasks only, write `.skill-workflow-state` if the optional workflow-state hook is installed:

```text
workflow=skills/{{NAME}}/workflows/plan-feature.md
status=planning
task=docs/plans/YYYY-MM-DD-<slug>
```

Update `status` as the task moves. Delete the file when the plan is complete or the workflow is abandoned.

## Complex Steps

1. **Scan existing rules / gotchas / pitfalls first** — before drafting `prd.md`, glance through `rules/`, `references/gotchas.md` (or any `references/*pitfall*.md`), and SKILL.md § Common Pitfalls for entries that look related to your scope. Read the relevant ones. These are the active constraints; proposing something the existing canon already rejected wastes the plan. Skip if these locations are empty.
2. **Create the plan directory** — `mkdir docs/plans/YYYY-MM-DD-<slug>` and seed `prd.md`. Do not pre-create empty files; add siblings only when this task actually needs them.
3. **Inspect first** — gather repo evidence before questioning: similar features, entry points, config, scripts, tests, and current docs. **Before launching a wide search**, ask the reverse-question "主 agent 读完所有命中是多余的吗?" — if yes (typical when ≥ 10 file hits expected), see [`subagent-driven.md` § Mode 1: Direct Auxiliary Delegation](subagent-driven.md#mode-1-direct-auxiliary-delegation) signal #3 to optionally dispatch an explore subagent. Reading 1-5 files to build the planning context is main-agent's job, do it inline.
4. **Question gate** — classify each possible question through Gate A/B/C; ask only the highest-value next question.
5. **Define scope** — write requirements, acceptance criteria, and out-of-scope items in `prd.md`.
6. **Record decisions** — when choosing between approaches, write the trade-off down. Where exactly is your call: inline in `prd.md` if it's a single line; in a sibling file (name it whatever fits) if it grows enough that `prd.md` would suffer. These notes are intra-plan and mutable — they freeze with the plan archive on close. Load-bearing entries get lifted into the live structure at step 8.
7. **Prepare execution context** — make sure `prd.md` (or files clearly linked from it) gives the implementer and the reviewer everything they need to read first. No required filename or format for this — write it however it stays readable. **If implementation is multi-hour with multiple independent subtasks**, the work qualifies for [`subagent-driven.md` § Mode 2: Four Phases](subagent-driven.md#mode-2-four-phases-when-to-invoke-this-mode) — `prd.md`'s reading list maps to each subagent contract's `Inputs` field, and you should plan the cut-points (which files each implementer owns, which are shared, which are forbidden) now while the scope is fresh.
8. **On closure: lift load-bearing content into the live structure** — when `status` flips to `done`, sort every conclusion (wherever in the plan directory it landed) into one of three buckets:

   - **"Future work must / must not do X"** (a constraint that binds tasks beyond this plan) → add to a `rules/<topic>.md` file. Routing pulls `rules/` onto every relevant task path, so the constraint is read automatically.
   - **"We tried Y; here is why Y is wrong"** (anti-pattern, footgun, rejected alternative worth remembering) → add an entry to `references/gotchas.md` (or `references/*pitfall*.md`), or — if the lesson is high-value enough to surface early — promote it to SKILL.md § Common Pitfalls. Use the "alternatives rejected" framing while the context is still fresh; six months from now you cannot reconstruct it.
   - **Neither** — pure provenance ("what happened, why we did it then") with no future binding → leave it in the plan archive and omit `distilled_to:`. Note the judgment in the plan body so future readers can see you actively chose not to lift anything.

   Then set the plan's `distilled_to:` frontmatter to list the live-structure files that received content. If the conclusion fits two buckets (e.g. both a rule and a pitfall), it goes in both — different audiences, not duplicates. **There is no fourth bucket** called `references/decisions/`; that was tried and removed (silo problem — see [docs/plans/README.md](../../../docs/plans/README.md) "When a plan closes").

9. **Final readback** — summarize requirements, acceptance criteria, chosen approach, out-of-scope items, and plan directory path.

## Decision Completeness (≠ section completeness)

A complex plan can carry every section this workflow asks for — scope, acceptance criteria, open questions, reading list — and still be missing a load-bearing **decision**. Structural checks (and the smoke-test) verify sections *exist*; they cannot tell you a decision is *absent*. Before marking the plan ready, scan for these recurring blind spots. Each is a cue to *check*, not a section to *add* — keep prd.md short:

- **Failure-mode behavior, not just happy-path + config errors.** If the plan calls an external service or dependency, is its *unreachable / timeout / 5xx* behavior decided — fail-open vs fail-closed, and what state persists? Plans routinely nail "config missing → X" yet leave "dependency down → ?" blank; that blank is usually the most consequential branch.
- **A contract or schema change carries its artifact, the repo's existing way.** New table, column, enum, or wire format → point to the concrete migration / DDL / schema artifact in the convention the repo already uses, not a prose field list. Pin the load-bearing details (nullability of any column inside a unique key, type/length).
- **Multi-file dossiers get a consistency pass before freeze.** When a plan splits across siblings, the same decision restated in two files drifts. Diff the overlapping claims — especially any "see Dx / see &lt;file&gt;" cross-reference that may now state the opposite of what it cites.
- **Open Questions track unresolved *decisions*, and a blocker reads as a blocker.** A missing input value and a "what happens when the dependency is down" decision are both open questions — don't let the second live outside the list. Don't file a hard blocker under a "non-blocking" header.

This scan is judgment, not a script: a missing decision is invisible to section-level checks by definition. What it deliberately does **not** add — a mandatory test-plan or observability section. Those belong to the executing workflow and the project's own standard (which may legitimately make them opt-in), not to every plan.

## Workflow-State Blocks

[workflow-state:planning]
You are planning a complex task. Keep `prd.md` short, inspect code/docs before asking, and run Question Gate A/B/C before every user question.
[/workflow-state:planning]

[workflow-state:research]
External or cross-repo research is active. Summarize findings in dedicated files inside the plan directory (any filename that fits). Include source paths/URLs/file:line references for anything quoted; avoid unsupported paraphrase.
[/workflow-state:research]

[workflow-state:converging]
Requirements are being locked. Move answered questions into `prd.md`. Record approach trade-offs alongside — inline in `prd.md` if short, or a sibling file (pick a natural name) if it grows. Keep out-of-scope explicit.
[/workflow-state:converging]

[workflow-state:implementation-ready]
Planning is complete. Make sure `prd.md` lists or clearly links to everything the implementer and the reviewer must read before starting.
[/workflow-state:implementation-ready]

## Completion Checklist

- [ ] Trivial/simple tasks were not forced into a plan folder
- [ ] Simple plans stayed inline unless the user explicitly asked for a file
- [ ] Every asked question passed Gate A/B/C
- [ ] `prd.md` contains testable acceptance criteria
- [ ] Approach trade-offs are recorded somewhere in the plan dir when choices mattered (location is your call)
- [ ] Research and evidence are not mixed into `prd.md` if they grew enough to need their own files
- [ ] `prd.md` (or files linked from it) gives the implementer/reviewer their reading list
- [ ] `.skill-workflow-state` was removed or left with the correct active state
- [ ] If the plan landed (`status: done`): step 8 was actually performed — every load-bearing conclusion was sorted into `rules/` / `references/gotchas.md` / SKILL.md Pitfalls / "no, pure provenance"; `distilled_to:` frontmatter reflects what was lifted
- [ ] If the plan calls an external dependency: its unreachable/timeout behavior is decided, not only the config-missing case
- [ ] Schema/contract changes point to a concrete migration artifact in the repo's existing convention, with unique-key column nullability/type pinned
- [ ] Large task: plan depth and angle-count scaled with complexity — analyzed from the lenses it warranted (not a thin single-file plan); `prd.md` synthesizes the angle files
- [ ] Multi-file dossier: overlapping claims and every "see Dx" / cross-file reference were diffed for drift before freeze
