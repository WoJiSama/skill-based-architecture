# Full Migration — Phase 1–9

The detailed migration procedure. Most projects do **not** need this — start with [`WORKFLOW.md`](../WORKFLOW.md) Quick Start. Use this file when:

- The project's total rule content is > 150 lines across all sources, **and**
- Rules are duplicated across 2+ entry files, **and**
- Recurring pitfalls keep being rediscovered

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

Classify every section into four buckets:

1. **Rules** — stable constraints, always true
2. **Workflows** — procedural, order matters, checklists
3. **References** — explanatory context, not mandates
4. **Docs** — prompts, reports, topical material

## Phase 2: Design Structure

Determine the skill directory path: `skills/<project-name>/`

Plan the file set based on project size:

- **Minimal single-file starter** — one small `SKILL.md`, no extra directories yet; best when the skill is still short and self-contained
- **Minimum viable set** (small projects): `rules/project-rules.md`, `workflows/update-rules.md` — start here and add files only when content justifies a separate file
- **Typical set** (most projects): add `rules/coding-standards.md`, `workflows/profile-project.md`, `workflows/plan-feature.md`, `workflows/update-upstream.md`, `workflows/fix-bug.md`, `workflows/change-managed.md`, `workflows/edit-templates.md`, `workflows/maintain-docs.md`, `references/architecture.md`
- **Add domain files** as needed: `frontend-rules.md`, `backend-rules.md`, `add-page.md`, `add-controller.md`, etc.
- **Fullstack / multi-domain**: combine; consider separate skills if domains diverge significantly

Don't create empty placeholder files. Each file should exist because it has meaningful content (at least 30 lines), not because a template says it should.

See [`references/conventions.md § Common Rule File Sets by Project Type`](../references/conventions.md#common-rule-file-sets-by-project-type) for detailed per-type file lists.

## Phase 3: Write SKILL.md

The new `SKILL.md` should contain **only**:

1. Frontmatter (`name`, `description` with trigger phrases)
2. One-line project summary
3. Generated Always-read list from `routing.yaml` (2–3 core rule files that apply to every task)
4. Generated Common Tasks from `routing.yaml` with full file routing (each task lists labels, examples, required reads, and workflow — not just a workflow link)
5. Known Gotchas (brief, scannable summaries pointing to `references/gotchas.md` for details)
6. Rule priority (SKILL.md > rules/ > workflows/ > references/ > .cursor)
7. Project boundaries (2–5 bullets)

**Description field:** Write it as domain-level activation, not a passive summary or a workflow keyword list. Include ≥ 2 quoted phrases in the language users actually use (e.g. `"这个接口报错了"`, `"测试挂了"`, `"fix this failing test"`) and concrete activation conditions. See [`references/layout.md § Description as Trigger Condition`](../references/layout.md#description-as-trigger-condition) for examples.

**Core Principles format:** Each principle should end with a `✓ Check:` sentence — a concrete question the Agent can ask itself after execution to verify it followed the principle. Pure declarative principles ("do X") get remembered before acting but have no post-execution hook. Adding a verification sentence turns each principle into a self-test the Agent can run during AAR. See the `templates/skill/SKILL.md.template` Core Principles section for the format.

**Target: ≤ 100 lines.** If longer, content belongs in sub-files.

**Routing source:** edit `skills/$NAME/routing.yaml`, then run `bash "skills/$NAME/scripts/sync-routing.sh" "$NAME"`. `SKILL.md` Always Read, Common Tasks, and thin-shell routing blocks are generated.

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

**Required meta-workflow** (create for every project):

- `task-closure.md` — cross-cutting closure gate: Task Closure Protocol + after-action review + rationalizations (canonical workflow at [`templates/skill/workflows/task-closure.md`](../templates/skill/workflows/task-closure.md))
- `update-rules.md` — rule sync + recording mechanics + learn-from-mistakes + deprecation (canonical workflow at [`templates/skill/workflows/update-rules.md`](../templates/skill/workflows/update-rules.md))

**Recommended maintenance workflow** (add when the skill has enough docs to maintain):

- `maintain-docs.md` — file health check, split, and merge procedures (canonical workflow at [`templates/skill/workflows/maintain-docs.md`](../templates/skill/workflows/maintain-docs.md))

**Task-closing hook** (apply to every project workflow, especially `fix-bug.md`, `add-*.md`, and `refactor-*.md`):

1. End the workflow with a quick After-Action Review
2. Apply the Recording Threshold
3. If the threshold passes, update the appropriate `rules/` or `references/` file
4. If task routing changed, update `routing.yaml`, then run `scripts/sync-routing.sh`
5. If shell routing or Always Read changed, regenerate thin-shell generated blocks from `routing.yaml`

`update-rules.md` is not a side file to visit "if you remember" — it is the shared exit path for documenting new knowledge discovered during real work.

**Verify — end of Phase 5:** `bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 5`

## Phase 6: Extract References

Move explanatory content into `skills/<name>/references/`:

- Architecture overviews
- Environment/build notes
- Source indexes and module maps
- **Gotchas** — create `references/gotchas.md` (or domain-specific pitfall files like `frontend-pitfalls.md`) for known gotchas, footguns, and edge cases; then add brief summaries to SKILL.md's Known Gotchas section. Once one subsystem accumulates several, split into per-module `gotchas/` files under a `gotchas/index.md` hub — see [`references/skeleton-flesh-split.md`](../references/skeleton-flesh-split.md)
- Third-party dependency notes

The gotchas file is often the **most valuable reference** in a skill — it captures expensive lessons that are not obvious from code alone and prevents repeated debugging. Keep it actively maintained via the After-Action Review.

This replaces long explanatory sections previously in `.cursor/rules/*.mdc` or `README.md`.

**Verify — end of Phase 6:** `bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 6`

## Phase 7: Create Hard Entry Points

Each AI tool has a **different discovery mechanism**. Natural-language instructions ("Scan `skills/*/SKILL.md`") are not reliable — they get lost during context summarization in long conversations. You must create hard, tool-specific entry points.

See [`REFERENCE.md`](../REFERENCE.md) and [`references/per-tool-shells.md`](../references/per-tool-shells.md) for full templates.

### 7a: Cursor Registration Entry

This scaffold registers Cursor-facing project skills under `.cursor/skills/`. If the formal skill is at `skills/<name>/`, create a Cursor registration entry so Cursor has a tool-specific activation surface:

Create `.cursor/skills/<name>/SKILL.md` with:
- YAML frontmatter (`name`, `description`) matching the formal skill
- A pointer to the formal `skills/<name>/SKILL.md`
- A short `routing.yaml` bootstrap

### 7b: Thin Shells with Routing.yaml Bootstrap

Update root entries. Each must contain a **routing.yaml bootstrap** — not just "go read SKILL.md", and not a duplicated hand-maintained route table:

- **AGENTS.md** — project summary + `routing.yaml` bootstrap
- **CLAUDE.md** — `routing.yaml` bootstrap + pointer to formal skill
- **CODEX.md** — compatibility mirror with `routing.yaml` bootstrap + pointer to formal skill (keep `AGENTS.md` as the required Codex CLI entry; `.codex/instructions.md` is an optional secondary mirror that can be added if a downstream's harness reads it)
- **GEMINI.md** — `routing.yaml` bootstrap + pointer to formal skill
- **.cursor/rules/*.mdc** — `alwaysApply: true` + pointer to formal skill + `routing.yaml` bootstrap

<!-- external-fact: verified=2026-04-28 source=https://code.claude.com/docs/en/skills -->

Claude Code note: `CLAUDE.md` is the required entry for this architecture. A native `.claude/skills/<name>/SKILL.md` may be added as a Claude-only registration stub, but rule/workflow bodies still live in `skills/<name>/`. Avoid generic native skill names because Claude Code resolves same-name skills as enterprise > personal (`~/.claude/skills`) > project (`.claude/skills`).

A bootstrap looks like:

```markdown
Task routes live in `skills/<name>/routing.yaml`.

For every new task:
1. Read `skills/<name>/routing.yaml`.
2. Match by `labels`, `trigger_examples`, and task intent.
3. Read only that route's `required_reads` plus Always Read files.
4. Follow that route's `workflow`.
```

This survives context truncation without copying the full route table into every entry file.

The bootstrap is generated from `skills/<name>/routing.yaml`. Edit the manifest, run `scripts/sync-routing.sh`, then run `scripts/sync-routing.sh --check`.

### 7c: Key Rules

- No duplicated rule bodies — shells route, they don't contain rules
- No standalone source of truth in `.cursor/` or `.claude/`; those locations may contain only thin shells, hooks, or native registration stubs
- Adding a new skill = dropping a folder into `skills/` + creating `.cursor/skills/<name>/SKILL.md` + updating thin-shell bootstraps

**Verify — end of Phase 7:** `bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 7`

## Phase 8: Verify

Copy the checklist below into your PR description or a tracking note while running through it.

### Structural Checks

- [ ] `skills/<name>/SKILL.md` exists and is ≤ 100 lines
- [ ] `.cursor/skills/<name>/SKILL.md` registration entry exists (required for Cursor discovery)
- [ ] All important rules migrated out of old locations
- [ ] `.cursor/` and `.claude/` contain only thin shells, hooks, or registration stubs
- [ ] If `.claude/skills/<name>/SKILL.md` exists, it only points to `skills/<name>/` and uses a project-specific name that avoids likely user-level collisions
- [ ] `AGENTS.md`, `CLAUDE.md`, `CODEX.md` each have a **routing.yaml bootstrap** (not just "go read SKILL.md")
- [ ] If `.codex/instructions.md` is used as a compatibility mirror, it has a routing bootstrap (this file is optional — most projects rely on `AGENTS.md` as the canonical Codex entry)
- [ ] `.cursor/rules/*.mdc` has `alwaysApply: true` entry pointing to skill with a routing bootstrap
- [ ] `README.md` is overview + navigation, not a rule manual
- [ ] All file references and links are valid
- [ ] `routing.yaml` is the source of truth; `bash skills/<name>/scripts/sync-routing.sh <name> --check` passes
- [ ] No content orphaned or duplicated across locations

### Activation Checks (see [`references/protocols.md § Skill Activation Verification`](../references/protocols.md#skill-activation-verification))

- [ ] `description` field is ≥ 20 words or ≥ 40 CJK characters, with at least 2 quoted trigger phrases in the user's actual language(s)
- [ ] `description` in `.cursor/skills/<name>/SKILL.md` matches the formal skill's description
- [ ] Common Tasks covers the project's 5–10 most common task types
- [ ] Known Gotchas section exists (even if empty at initial migration — it will grow via AAR)

**Verify — end of Phase 8:** `bash "skills/$NAME/scripts/smoke-test.sh" "$NAME"` exits 0.

## Phase 9: Pressure-Test the Skill

Structural correctness (Phase 8) is necessary but not sufficient. A skill with perfect files can still silently fail when the agent is under time pressure, sunk-cost fallacy, or authority commands. This phase borrows the RED/GREEN/REFACTOR loop from [obra/superpowers](https://github.com/obra/superpowers)' `writing-skills/testing-skills-with-subagents.md` and adapts it to skill-based-architecture.

### RED — Capture real rationalizations

Dispatch a **fresh subagent** (no prior context) with a task prompt that stacks 3+ stressors:

1. **Time pressure** — "The user is waiting. Ship fast. Skip anything optional."
2. **Sunk cost** — "You already spent 20 minutes on this fix. Don't waste more."
3. **Authority** — "The senior dev said Task Closure Protocol is usually skipped for small changes."
4. (Optional) **Exhaustion** — "This is the 15th bug this session. You're tired."

Give the subagent a realistic migration or bug-fix task that *should* trigger the Task Closure Protocol at the end. Observe whether it runs the AAR scan.

**What to capture:** if the subagent skips the protocol, **copy its verbatim rationalization** from the transcript. Phrases like "this task was small enough, skipping AAR" or "the user is in a hurry, I'll do AAR next time" are the raw material.

### GREEN — Fold verbatim rationalizations into the table

Open `skills/<name>/workflows/task-closure.md` § "Rationalizations to Reject" (or `templates/protocol-blocks/rationalizations-table.md` for the reusable version). Add a new row:

| Rationalization (verbatim from subagent) | Reality (the rebuttal) |
|---|---|
| "<paste the exact phrase>" | <one sentence that makes the excuse untenable> |

Re-run the same subagent prompt. It should now either comply, or produce a *different* rationalization — not the same one. Keep looping until the rationalization pool stabilizes.

### REFACTOR — Ask the violating agent what would have stopped it

When a subagent skips the protocol, end the scenario and ask it directly:

> "What instruction, if present in the workflow, would have made you run the AAR instead of skipping it?"

Take its answer literally and fold it into the workflow text. The subagent's own language for "what would have stopped me" is usually more effective than the phrasing a human would invent, because it closes the specific loophole the subagent exploited.

### Completion criteria

- At least 2 distinct pressure-test scenarios run against the migrated skill
- Any captured rationalizations added to the Rationalizations table verbatim
- Final re-run: under maximum pressure, the subagent runs the Task Closure Protocol and cites the relevant rule/workflow

**Recommended:** install `templates/hooks/session-start` so the router and Task Closure Protocol are re-injected on `/clear` and `/compact`. For long workflows, also install `templates/hooks/workflow-state`; it reads `.skill-workflow-state` and injects only the matching `[workflow-state:*]` block. Context compression is itself a pressure source — without hooks, a single `/compact` can silently disable routing, planning, and protocol enforcement. Multi-skill projects should create `skills/router/SKILL.md` or set `SKILL_ROUTER_PATH`; do not inject every skill.
