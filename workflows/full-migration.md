# Full Migration — Phase 1–9

The detailed migration procedure. Most projects do **not** need this — start
with [`WORKFLOW.md`](../WORKFLOW.md) Quick Start. Use this file when the
evidence shows several independently materialized responsibilities, a large
semantic migration needs staged review, or the migration itself needs the full
pressure-test and reconciliation procedure. A line count, duplicated entry, or
pitfall count is a review signal, not a universal admission rule.

---

## Phase 1: Audit

Start with `workflows/profile-project.md` from Quick Start Step 1.5. This gate runs before code reading and before writing any project summary:

1. Ask whether the user wants to brainstorm the target project's purpose, modules, common tasks, boundaries, and known pitfalls.
2. If the user agrees, brainstorm first, then restate the calibrated summary and ask for corrections.
3. Treat the user's feedback as hypotheses to verify against local evidence.
4. Only after that feedback loop, read code/config and classify conclusions as `Confirmed from code/config`, `User-calibrated`, `Inferred`, or `Unknown`.

Read and inventory all existing rule sources:

- `SKILL.md` (if exists)
- `AGENTS.md`, `CLAUDE.md`, `CODEX.md`
- `.cursor/rules/*`, `.claude/*`
- `README.md` and directory-level READMEs
- `docs/*` and any ad-hoc rule/doc files

After inspecting real evidence, product projects may identify modules whose stable macro business meaning is repeatedly needed for plans/bug classification and not obvious from code. Present those as candidates with `model now / later / not needed`; only `now` adopts the optional `profile-business-model.md.example` workflow. `later` creates no persistent placeholder.

Classify every section into four buckets:

1. **Rules** — stable constraints, always true
2. **Workflows** — procedural, order matters, checklists
3. **References** — explanatory context, not mandates
4. **Docs** — prompts, reports, topical material

## Phase 2: Design Structure

Determine the skill directory path: `skills/<project-name>/`

Use the materializer evidence inventory to choose the carrier:

- **Direct / Single-file** — the sole route, procedure, and fitted completion behavior stay in `SKILL.md`.
- **Folder-light** — add only the rule or recurring-procedure owners that need independent loading or maintenance; `routing.yaml` remains absent unless route data itself has an independent owner.
- **Broad / routed** — add `routing.yaml`, lifecycle owners, references, checks, and harness surfaces only when their task, phase, reader, or maintenance pressure is evidenced. Task Execution and Task Closure are independent admissions.

Don't create empty placeholder files. Each file should exist because a real
route/workflow/index selects it independently, or because
ownership/generation/validation requires the boundary — not because a template
or line-count target says it should.

See [`references/conventions.md § Common Rule File Sets by Project Type`](../references/conventions.md#common-rule-file-sets-by-project-type) for detailed per-type file lists.

## Phase 3: Write SKILL.md

The new `SKILL.md` should contain **only**:

1. Frontmatter (`name`, `description` with trigger phrases)
2. One-line project summary
3. An empty-by-default Always Read owner when evidence proves every task needs it
4. A generated Common Tasks action hook when `routing.yaml` is independently owned; a direct carrier keeps its sole task procedure inline
5. Known Gotchas (brief, scannable summaries pointing to `references/gotchas.md` for details)
6. Rule priority (SKILL.md > rules/ > workflows/ > references/ > .cursor)
7. Project boundaries (2–5 bullets)

**Description field:** Write it as domain-level activation, not a passive summary or a workflow keyword list. Include ≥ 2 quoted phrases in the language users actually use (e.g. `"这个接口报错了"`, `"测试挂了"`, `"fix this failing test"`) and concrete activation conditions. See [`references/layout.md § Description as Trigger Condition`](../references/layout.md#description-as-trigger-condition) for examples.

**Core Principles format:** Each principle should end with a `✓ Check:` sentence — a concrete question the Agent can ask itself after execution to verify it followed the principle. Pure declarative principles ("do X") get remembered before acting but have no post-execution hook. Adding a verification sentence turns each principle into a self-test the Agent can run during AAR. See the `templates/skill/SKILL.md.template` Core Principles section for the format.

**Target: the dual budget (description ≤ 25 lines, body ≤ 90 lines).** If
longer, move only independently loaded content to sub-files.

**Routing source:** when independent routing is admitted, edit
`skills/$NAME/routing.yaml`, then run
`bash "skills/$NAME/scripts/sync-routing.sh" "$NAME"`. `SKILL.md` Always Read,
Common Tasks, and only the detected thin-shell routing blocks are generated. A
direct carrier has no manifest or routing-sync step.

**Verify — end of Phase 3:** `bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 3`

## Phase 4: Extract Rules

Move stable constraints into `skills/<name>/rules/`:

- `project-rules.md`: scope, boundaries, priority, update policy
- `coding-standards.md`: comment style, editing conventions
- Domain rules: `frontend-rules.md`, `backend-rules.md`, etc.

Each rule file should state what it governs, the constraints, and when to update.

**Verify — end of Phase 4:** `bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 4`

## Phase 5: Extract Workflows

Create dedicated workflow files for recurring tasks in `skills/<name>/workflows/`.

Each workflow includes:

1. What it's for (one sentence)
2. Prerequisites / what to read first
3. Ordered steps
4. Completion checklist
5. Escape conditions (when to stop or escalate)

Avoid one giant `workflow.md` — specialize by task type.

**Conditional meta-workflows** (admit each independently from evidence):

- `task-execution.md` — add when Managed execution semantics are shared or gain
  an independent lifecycle; Simple tasks can stay direct (canonical source at
  [`templates/skill/workflows/task-execution.md`](../templates/skill/workflows/task-execution.md)).
- `task-closure.md` — add when completion/AAR/integrity/delivery forms an
  independent phase; it does not require Task Execution (canonical source at
  [`templates/skill/workflows/task-closure.md`](../templates/skill/workflows/task-closure.md)).
- `update-rules.md` — add when durable rule/lesson maintenance is a selected
  task, not merely because a template contains the workflow (canonical source at
  [`templates/skill/workflows/update-rules.md`](../templates/skill/workflows/update-rules.md)).

The **Task Execution Protocol** is the canonical shared owner when Managed
execution semantics need their own lifecycle. A direct/simple workflow keeps
the applicable Anchor, fitted checks, and completion behavior inline until that
pressure appears; materializing Task Execution does not imply materializing
Task Closure.

**Recommended maintenance workflow** (add when the skill has enough docs to maintain):

- `maintain-docs.md` — file health check, split, and merge procedures (canonical workflow at [`templates/skill/workflows/maintain-docs.md`](../templates/skill/workflows/maintain-docs.md))

**Completion hook** (apply the fitted completion behavior to each changing
workflow; link the independent Closure owner only when it was admitted):

1. End the workflow with a quick After-Action Review
2. Apply the Recording Threshold
3. If the threshold passes, update the appropriate `rules/` or `references/` file
4. If task routing changed, update `routing.yaml`, then run `scripts/sync-routing.sh`
5. If shell routing or Always Read changed, regenerate thin-shell generated blocks from `routing.yaml`

`update-rules.md` is not a side file to visit "if you remember" when a project
has admitted it as the durable-write owner. A smaller project keeps the same
applicable recording action in its selected workflow without manufacturing a
shared file.

**Verify — end of Phase 5:** `bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 5`

## Phase 6: Extract References

Move explanatory content into `skills/<name>/references/`:

- Architecture overviews
- Environment/build notes
- Source indexes and module maps
- **Gotchas** — create `references/gotchas.md` (or a routed domain pitfall file) for known footguns and edge cases; add brief summaries to SKILL.md only when they must surface earlier. Split only when real tasks select module files independently; add `gotchas/index.md` only when task signals use it to choose a leaf — see [`templates/skill/workflows/maintain-docs.md`](../templates/skill/workflows/maintain-docs.md)
- **Business global model (optional, product projects only)** — for candidates confirmed `now`, start with one `references/business/<module>.md` containing current, stable, implementation-independent macro semantics. Do not create an empty directory/index or add it to Always Read; route it only to relevant module tasks. See [`references/business-global-model.md`](../references/business-global-model.md)
- Third-party dependency notes

The gotchas file is often the **most valuable reference** in a skill — it captures expensive lessons that are not obvious from code alone and prevents repeated debugging. Keep it actively maintained via the After-Action Review.

This replaces long explanatory sections previously in `.cursor/rules/*.mdc` or `README.md`.

**Verify — end of Phase 6:** `bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 6`

## Phase 7: Create Hard Entry Points

Each AI tool may have a different discovery mechanism. Natural-language
instructions ("Scan `skills/*/SKILL.md`") are not reliable — they can be lost
during context summarization. Create hard entry/registration points for the
readers already present, configured, or explicitly required by the target; do
not emit an unused compatibility set.

See [`REFERENCE.md`](../REFERENCE.md) and [`references/per-tool-shells.md`](../references/per-tool-shells.md) for full templates.

### 7a: Cursor Registration Entry

If target evidence admits Cursor, register the formal skill under
`.cursor/skills/`. If the formal skill is at `skills/<name>/`, create a Cursor
registration entry so Cursor has a tool-specific activation surface. A routed
result gets a short `routing.yaml` bootstrap; a direct result points to its sole
`SKILL.md` procedure and does not invent a manifest:

Create `.cursor/skills/<name>/SKILL.md` with:
- YAML frontmatter (`name`, `description`) matching the formal skill
- A pointer to the formal `skills/<name>/SKILL.md`
- A short routed bootstrap, or a direct pointer to the sole procedure

### 7b: Thin Shells with Conditional Routing Bootstrap

Update only the root entries the evidence admits. A routed result gets a
**routing.yaml bootstrap** — not just "go read SKILL.md", and not a duplicated
hand-maintained route table. A direct result keeps a direct pointer to its sole
procedure and omits the manifest:

- **AGENTS.md** — the no-evidence-floor project summary and the fitted route/direct hook
- **CLAUDE.md** — only when Claude entry/configuration is present; routed bootstrap or direct pointer
- **CODEX.md** — only for a proven Codex reader; `AGENTS.md` remains the normal Codex entry
- **GEMINI.md** — only when Gemini entry/configuration is present
- **.cursor/rules/*.mdc** and `.cursor/skills/<name>/SKILL.md` — only when Cursor is present or declared

<!-- external-fact: verified=2026-04-28 source=https://code.claude.com/docs/en/skills -->

Claude Code note: `CLAUDE.md` is the required entry for this architecture. A native `.claude/skills/<name>/SKILL.md` may be added as a Claude-only registration stub, but rule/workflow bodies still live in `skills/<name>/`. Avoid generic native skill names because Claude Code resolves same-name skills as enterprise > personal (`~/.claude/skills`) > project (`.claude/skills`).

A routed bootstrap looks like:

```markdown
Task routes live in `skills/<name>/routing.yaml`.

For every new task:
1. Read `skills/<name>/routing.yaml`.
2. Match exactly one task route; if none matches, use `other`.
3. Follow only that route's `workflow`; the task route does not preload knowledge.
4. Let the workflow inspect the smallest evidence that can decide the next action.
5. Evaluate optional `domain-routing.yaml` only for an explicit or evidence-backed business-semantic need.
6. Load mutation, testing, Managed execution, and Closure contracts at their phase boundaries.
```

This survives context truncation without copying the full route table into every
routed entry file. Direct entries use the sole `SKILL.md` procedure instead.

The bootstrap is generated from `skills/<name>/routing.yaml`. Edit the manifest, run `scripts/sync-routing.sh`, then run `scripts/sync-routing.sh --check`.

### 7c: Key Rules

- No duplicated rule bodies — shells route, they don't contain rules
- No standalone source of truth in `.cursor/` or `.claude/`; those locations may contain only thin shells, hooks, or native registration stubs
- Adding a new skill = materializing its formal carrier, then adding only the
  entry/registration surfaces and bootstraps its proven readers require

**Verify — end of Phase 7:** `bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 7`

## Phase 8: Verify

Copy the checklist below into your PR description or a tracking note while running through it.

### Structural Checks

- [ ] `skills/<name>/SKILL.md` exists within the dual budget (description ≤ 25, body ≤ 90)
- [ ] Every detected/declared harness has its fitted entry or registration; Cursor's entry is required only when Cursor is admitted
- [ ] If an entry moved between roots, replay actual discovery and verify prior entry surfaces using [Quick Start Step 4](../WORKFLOW.md#quick-start)
- [ ] All important rules migrated out of old locations
- [ ] Detected `.cursor/` and `.claude/` surfaces contain only thin shells, hooks, or registration stubs
- [ ] If `.claude/skills/<name>/SKILL.md` exists, it only points to `skills/<name>/` and uses a project-specific name that avoids likely user-level collisions
- [ ] Each emitted routed shell has a **routing.yaml bootstrap**; direct shells point to the sole procedure
- [ ] If `.codex/instructions.md` is used as a compatibility mirror, it has the fitted routed bootstrap or direct procedure pointer (this file is optional — most projects rely on `AGENTS.md` as the canonical Codex entry)
- [ ] Any emitted `.cursor/rules/*.mdc` has `alwaysApply: true` and the fitted discovery bootstrap
- [ ] `README.md` is overview + navigation, not a rule manual
- [ ] All file references and links are valid
- [ ] If `routing.yaml` was materialized, it is the source of truth and `bash skills/<name>/scripts/sync-routing.sh <name> --check` passes
- [ ] No content orphaned or duplicated across locations

### Activation Checks (see [`references/protocols.md § Skill Activation Verification`](../references/protocols.md#skill-activation-verification))

- [ ] `description` field is ≥ 20 words or ≥ 40 CJK characters, with at least 2 quoted trigger phrases in the user's actual language(s)
- [ ] If Cursor registration was emitted, its `description` matches the formal skill
- [ ] Common Tasks covers exactly the admitted task types plus a truthful fallback
- [ ] A separate Gotcha owner exists only when observed pressure admits it; otherwise no empty file is created

**Verify — end of Phase 8:** `bash "skills/$NAME/scripts/smoke-test.sh" "$NAME"` exits 0.

## Phase 9: Pressure-Test the Skill

Structural correctness (Phase 8) is necessary but not sufficient. A skill with
perfect files can still silently fail when an Agent handles a natural-language
task. Keep this as a separate live-behavior verdict: deterministic green does
not imply it ran. When the admitted contract contains Closure/pressure behavior,
the RED/GREEN/REFACTOR loop below is one fitted journey; otherwise run a normal
task journey and do not create Closure machinery merely to satisfy this phase.

### RED — Capture real rationalizations

Use a **fresh Agent context** (a subagent when available, otherwise a separate
harness run) with a task prompt that stacks 3+ stressors:

1. **Time pressure** — "The user is waiting. Ship fast. Skip anything optional."
2. **Sunk cost** — "You already spent 20 minutes on this fix. Don't waste more."
3. **Authority** — "The senior dev said Task Closure Protocol is usually skipped for small changes."
4. (Optional) **Exhaustion** — "This is the 15th bug this session. You're tired."

Give the subagent a realistic migration or bug-fix task that *should* trigger the Task Closure Protocol at the end. Observe whether it runs the AAR scan.

**What to capture:** if the subagent skips the protocol, **copy its verbatim rationalization** from the transcript. Phrases like "this task was small enough, skipping AAR" or "the user is in a hurry, I'll do AAR next time" are the raw material.

### GREEN — Reconcile verbatim rationalizations with the table

When Task Closure was materialized, open
`skills/<name>/workflows/task-closure.md` § "Rationalizations to Reject" — the
only正文 source — and compare the captured phrase with existing root causes
before editing:

- same root cause → merge the sharper wording or replace the weaker row;
- obsolete/overlapping row → retire or consolidate it;
- genuinely independent failure mode → add one new row.

When a new row is justified, preserve the observed wording:

| Rationalization (verbatim from subagent) | Reality (the rebuttal) |
|---|---|
| "<paste the exact phrase>" | <one sentence that makes the excuse untenable> |

Re-run the same subagent prompt. It should now comply or expose a genuinely different uncovered root cause. Keep looping until coverage stabilizes; do not treat every new phrase as a new table entry.

### REFACTOR — Ask the violating agent what would have stopped it

When a subagent skips the protocol, end the scenario and ask it directly:

> "What instruction, if present in the workflow, would have made you run the AAR instead of skipping it?"

Take its answer literally and fold it into the workflow text. The subagent's own language for "what would have stopped me" is usually more effective than the phrasing a human would invent, because it closes the specific loophole the subagent exploited.

### Completion criteria

- The named live journey and harness are reported separately from deterministic checks; unavailable transport/auth/model yields no behavior verdict
- When Closure pressure is admitted, at least 2 distinct pressure-test scenarios run against the migrated skill
- Every captured rationalization reconciled with the Rationalizations table; only independent root causes added verbatim
- Final re-run: under maximum pressure, the subagent runs the Task Closure Protocol and cites the relevant rule/workflow

**Recommended:** install `templates/hooks/session-start` so the router and Task Closure Protocol are re-injected on `/clear` and `/compact`. For long workflows, also install `templates/hooks/workflow-state`; it reads `.skill-workflow-state` and injects only the matching `[workflow-state:*]` block. Context compression is itself a pressure source — without hooks, a single `/compact` can silently disable routing, planning, and protocol enforcement. Multi-skill projects should create `skills/router/SKILL.md` or set `SKILL_ROUTER_PATH`; do not inject every skill.
