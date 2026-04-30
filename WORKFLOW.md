# Migration Workflow

Step-by-step procedure for restructuring a long SKILL.md or scattered rules into Skill-based architecture.

## Quick Start

For small-to-medium projects, run the scaffold and fill in content. Skip the full 9-phase process.

### Which path should I take?

Answer these questions to decide:

1. **Is the total rule content > 150 lines across all files?** (Count SKILL.md + AGENTS.md + .cursor/rules/ + README rules sections combined, not just one file)
2. **Are rules duplicated across 2+ entry files?** (e.g., AGENTS.md and .cursor/rules/ overlap)
3. **Do you have recurring pitfalls that keep being rediscovered?** (same debugging lesson learned twice)

| Answers | Path |
|---------|------|
| All No | **Minimal single SKILL.md** — use the [minimal starter template](TEMPLATES-GUIDE.md) |
| 1 Yes, others No | **Quick Start scaffold** below — run the script, fill TODOs |
| 2+ Yes | **Full 9-phase migration** — follow Phase 1–9 below |

If the project has only one small skill, no duplicated entry files, and no growing rule/reference sprawl yet, **do not force the full architecture immediately**. Start with a single well-written `SKILL.md` using the minimal starter template in [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md), and upgrade only when one of the conditions above becomes true.

**Step 1 — Scaffold from pre-built templates.** Don't regenerate file bodies inline — the upstream ships byte-for-byte files under [`templates/`](templates/). Copy them into the target project and run a single `sed` pass.

```bash
# Assumes skill-based-architecture is cloned as a sibling, or $UPSTREAM points at it.
UPSTREAM="${UPSTREAM:-../skill-based-architecture}"
NAME="<name>"          # project identifier, kebab-case
SUMMARY="<one-line project summary>"

# 1) Copy skill tree: templates/skill/ → skills/$NAME/
mkdir -p "skills/$NAME"
cp -R "$UPSTREAM/templates/skill/." "skills/$NAME/"
mv "skills/$NAME/SKILL.md.template" "skills/$NAME/SKILL.md"

# 2) Copy entry shells to repo root (AGENTS.md, CLAUDE.md, CODEX.md, GEMINI.md, .codex/, .cursor/)
cp -R "$UPSTREAM/templates/shells/." .

# 3) Cursor registration entry: materialize SKILL.md, then rename the {{NAME}} placeholder directory
mv ".cursor/skills/{{NAME}}/SKILL.md.template" ".cursor/skills/{{NAME}}/SKILL.md"
mv ".cursor/skills/{{NAME}}" ".cursor/skills/$NAME"

# 4) Substitute mechanical placeholders (macOS sed syntax; on Linux drop the '' after -i)
find "skills/$NAME" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .codex .cursor \
  -type f \( -name '*.md' -o -name '*.mdc' \) \
  -exec sed -i '' \
    -e "s/{{NAME}}/$NAME/g" \
    -e "s/{{SUMMARY}}/$SUMMARY/g" \
    {} +

# 5) (Optional) install hooks — SessionStart re-injects one router on /clear and /compact
# mkdir -p .claude/hooks
# cp "$UPSTREAM/templates/hooks/session-start" .claude/hooks/session-start
# cp "$UPSTREAM/templates/hooks/agent-behavior-gate.sh" .claude/hooks/agent-behavior-gate.sh
# chmod +x .claude/hooks/session-start .claude/hooks/agent-behavior-gate.sh
# cp "$UPSTREAM/templates/hooks/hooks.json" .claude/hooks.json

# 6) Checkpoint: scaffold done — equivalent to completing Phases 3–7 in one pass
echo "phase=7" > .migration-state

echo "✅ Scaffold created at skills/$NAME/ (checkpointed: phase=7)"
echo "Next: fill every <!-- FILL: --> marker with real project content, then run smoke-test.sh for Phase 8."
echo "If this step crashes, see § Resuming From a Failed Phase — do NOT rerun from scratch."
```

**Why copy instead of generate?** Inline heredoc generation lost sections under pressure (Auto-Triggers dropped, routing tables mangled, description field left as trigger-phrase-less boilerplate). The `templates/` tree is the single source of truth — see [`templates/README.md`](templates/README.md) for byte budgets, placeholder conventions, and the "would two real projects disagree?" admission test. Template source files use `SKILL.md.template` so skill loaders do not treat them as real skills when this repo is installed; Quick Start renames them into real `SKILL.md` files after copying.

**Step 1.5 — Profile the project before filling content.** Follow `skills/$NAME/workflows/profile-project.md` (copied from `templates/skill/workflows/profile-project.md`) before writing project-specific `<!-- FILL: -->` content. Start with a user brainstorm gate: ask whether the user wants to brainstorm the target project's purpose, modules, common tasks, boundaries, and known pitfalls.

- If the user says yes / "没问题" / otherwise agrees: **do not read code yet**. First run the brainstorm, restate a short calibrated summary, and ask the user to correct or confirm it.
- Treat user feedback as **calibration input**, not verified fact. Use it to check whether your initial summary is aligned, then read local code/config to verify it.
- After the brainstorm feedback, inspect real evidence (README, build files, CI, entry points, configs, module layout, tests) and classify conclusions as `Confirmed from code/config`, `User-calibrated`, `Inferred`, or `Unknown`.
- Only then write project content into `rules/`, `workflows/`, `references/`, and `SKILL.md`. `rules/` and procedural `workflows/` must come from confirmed evidence, not brainstorm-only claims.
- If the user declines brainstorming or explicitly asks to skip it, proceed with code-first evidence scanning and mark unclear conclusions as `Unknown` instead of guessing.

**Step 2 — Fill content.** Two kinds of placeholders, two different mechanisms:

| Marker | How to fill |
|---|---|
| `{{NAME}}`, `{{SUMMARY}}` | Done by the `sed` pass in Step 1 |
| `<!-- FILL: … -->` | Requires judgment — you must read each marker and write real project content |

Run this to list every pending FILL:

```bash
grep -rn 'FILL:' "skills/$NAME" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .codex .cursor
```

Every hit is mandatory. A skill with unfilled FILL markers will silently fail to activate (agents read generic trigger phrases and never match user intent).

Always Read lists, Common Tasks, and shell bootstraps are generated from `skills/$NAME/routing.yaml`. Edit that manifest, then run:

```bash
bash "skills/$NAME/scripts/sync-routing.sh" "$NAME"
```

Do not hand-edit generated Always Read / Common Tasks in `SKILL.md` or generated blocks in thin shells.

**Step 3 — Verify.** After all FILLs are resolved, run the automated smoke test:

```bash
# Fully automated — checks structure, routing, placeholders, line budgets, and description quality
bash "skills/$NAME/scripts/smoke-test.sh" "$NAME"

# Routing manifest drift check (also run by smoke-test when routing.yaml exists)
bash "skills/$NAME/scripts/sync-routing.sh" "$NAME" --check

# Description scope + multi-skill overlap
bash "skills/$NAME/scripts/check-description-routing.sh" "$NAME"

# (Optional) Test skill trigger rate — checks if your description actually activates the skill
bash "skills/$NAME/scripts/test-trigger.sh" "$NAME"
```

`smoke-test.sh` covers everything: file existence, line count budgets, placeholder/FILL residue, description word count and trigger phrases, description scope / multi-skill overlap, routing-manifest drift, routing completeness (parses Common Tasks and verifies every referenced file exists), description consistency between SKILL.md and Cursor entry, and shell bootstrap consistency. Zero manual input needed.

`test-trigger.sh` tests description activation using quoted trigger phrases plus `routing.yaml` trigger examples, then either runs them through `claude -p` (if CLI is available) or falls back to static analysis. Route examples are smoke samples, not a requirement to list every workflow in `description`. This is most useful for Cursor users since Cursor relies on description-based semantic matching.

Then run the Phase 8 checklist below to confirm everything is wired up.

For complex migrations (large projects, heavily scattered rules), follow the full Phase 1–9 process:

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
- `.cursor/rules/*`, `.claude/*`, `.codex/*`
- `README.md` and directory-level READMEs
- `docs/*` and any ad-hoc rule/doc files

Classify every section into four buckets:

1. **Rules** — stable constraints, always true
2. **Workflows** — procedural, order matters, checklists
3. **References** — explanatory context, not mandates
4. **Docs** — prompts, reports, topical material

**Checkpoint — end of Phase 1:** `echo "phase=1" > .migration-state`

## Phase 2: Design Structure

Determine the skill directory path: `skills/<project-name>/`

Plan the file set based on project size:

- **Minimal single-file starter** — one small `SKILL.md`, no extra directories yet; best when the skill is still short and self-contained
- **Minimum viable set** (small projects): `rules/project-rules.md`, `workflows/update-rules.md` — start here and add files only when content justifies a separate file
- **Typical set** (most projects): add `rules/coding-standards.md`, `workflows/profile-project.md`, `workflows/update-upstream.md`, `workflows/fix-bug.md`, `workflows/change-managed.md`, `workflows/edit-templates.md`, `workflows/maintain-docs.md`, `references/architecture.md`
- **Add domain files** as needed: `frontend-rules.md`, `backend-rules.md`, `add-page.md`, `add-controller.md`, etc.
- **Fullstack / multi-domain**: combine; consider separate skills if domains diverge significantly

Don't create empty placeholder files. Each file should exist because it has meaningful content (at least 30 lines), not because a template says it should.

See [references/conventions.md § Common Rule File Sets by Project Type](references/conventions.md#common-rule-file-sets-by-project-type) for detailed per-type file lists.

**Checkpoint — end of Phase 2:** `echo "phase=2" > .migration-state`

## Phase 3: Write SKILL.md

The new `SKILL.md` should contain **only**:

1. Frontmatter (`name`, `description` with trigger phrases)
2. One-line project summary
3. Generated Always-read list from `routing.yaml` (2–3 core rule files that apply to every task)
4. Generated Common Tasks from `routing.yaml` with full file routing (each task lists labels, examples, required reads, and workflow — not just a workflow link)
5. Known Gotchas (brief, scannable summaries pointing to `references/gotchas.md` for details)
6. Rule priority (SKILL.md > rules/ > workflows/ > references/ > .cursor)
7. Project boundaries (2–5 bullets)

**Description field:** Write it as domain-level activation, not a passive summary or a workflow keyword list. Include ≥ 2 quoted phrases in the language users actually use (e.g. `"这个接口报错了"`, `"测试挂了"`, `"fix this failing test"`) and concrete activation conditions. See [references/layout.md § Description as Trigger Condition](references/layout.md#description-as-trigger-condition) for examples.

**Core Principles format:** Each principle should end with a `✓ Check:` sentence — a concrete question the Agent can ask itself after execution to verify it followed the principle. Pure declarative principles ("do X") get remembered before acting but have no post-execution hook. Adding a verification sentence turns each principle into a self-test the Agent can run during AAR. See the `templates/skill/SKILL.md.template` Core Principles section for the format.

**Target: ≤ 100 lines.** If longer, content belongs in sub-files.

**Routing source:** edit `skills/$NAME/routing.yaml`, then run `bash "skills/$NAME/scripts/sync-routing.sh" "$NAME"`. `SKILL.md` Always Read, Common Tasks, and thin-shell routing blocks are generated.

**Checkpoint — end of Phase 3:**
```bash
bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 3 && echo "phase=3" > .migration-state
```

## Phase 4: Extract Rules

Move stable constraints into `skills/<name>/rules/`:

- `project-rules.md`: scope, boundaries, priority, update policy
- `coding-standards.md`: comment style, editing conventions
- Domain rules: `frontend-rules.md`, `backend-rules.md`, etc.

Each rule file should state what it governs, the constraints, and when to update.

**Checkpoint — end of Phase 4:**
```bash
bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 4 && echo "phase=4" > .migration-state
```

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

- `update-rules.md` — rule sync + after-action review + learn-from-mistakes + deprecation (see [TEMPLATES-GUIDE.md § update-rules.md](TEMPLATES-GUIDE.md#update-rulesmd-enhanced-template))

**Recommended maintenance workflow** (add when the skill has enough docs to maintain):

- `maintain-docs.md` — file health check, split, and merge procedures (see [TEMPLATES-GUIDE.md § maintain-docs.md](TEMPLATES-GUIDE.md#maintain-docsmd-template))

**Task-closing hook** (apply to every project workflow, especially `fix-bug.md`, `add-*.md`, and `refactor-*.md`):

1. End the workflow with a quick After-Action Review
2. Apply the Recording Threshold
3. If the threshold passes, update the appropriate `rules/` or `references/` file
4. If task routing changed, update `routing.yaml`, then run `scripts/sync-routing.sh`
5. If shell routing or Always Read changed, regenerate thin-shell generated blocks from `routing.yaml`

`update-rules.md` is not a side file to visit "if you remember" — it is the shared exit path for documenting new knowledge discovered during real work.

**Checkpoint — end of Phase 5:**
```bash
bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 5 && echo "phase=5" > .migration-state
```

## Phase 6: Extract References

Move explanatory content into `skills/<name>/references/`:

- Architecture overviews
- Environment/build notes
- Source indexes and module maps
- **Gotchas** — create `references/gotchas.md` (or domain-specific pitfall files like `frontend-pitfalls.md`) for known gotchas, footguns, and edge cases; then add brief summaries to SKILL.md's Known Gotchas section
- Third-party dependency notes

The gotchas file is often the **most valuable reference** in a skill — it captures expensive lessons that are not obvious from code alone and prevents repeated debugging. Keep it actively maintained via the After-Action Review.

This replaces long explanatory sections previously in `.cursor/rules/*.mdc` or `README.md`.

**Checkpoint — end of Phase 6:**
```bash
bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 6 && echo "phase=6" > .migration-state
```

## Phase 7: Create Hard Entry Points

Each AI tool has a **different discovery mechanism**. Natural-language instructions ("Scan `skills/*/SKILL.md`") are not reliable — they get lost during context summarization in long conversations. You must create hard, tool-specific entry points.

See [REFERENCE.md](REFERENCE.md) for full templates.

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
- **CODEX.md** / **.codex/instructions.md** — compatibility mirrors with `routing.yaml` bootstrap + pointer to formal skill (keep `AGENTS.md` as the required Codex CLI entry)
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
- No standalone source of truth in `.cursor/`, `.claude/`, or `.codex/`; those locations may contain only thin shells, hooks, or native registration stubs
- Adding a new skill = dropping a folder into `skills/` + creating `.cursor/skills/<name>/SKILL.md` + updating thin-shell bootstraps

**Checkpoint — end of Phase 7:**
```bash
bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 7 && echo "phase=7" > .migration-state
```

## Phase 8: Verify

A standalone copyable checklist is available at [`templates/checklists/post-migration.md`](templates/checklists/post-migration.md). The sections below are the inline reference.

### Structural Checks

- [ ] `skills/<name>/SKILL.md` exists and is ≤ 100 lines
- [ ] `.cursor/skills/<name>/SKILL.md` registration entry exists (required for Cursor discovery)
- [ ] All important rules migrated out of old locations
- [ ] `.cursor/`, `.claude/`, `.codex/` contain only thin shells, hooks, or registration stubs
- [ ] If `.claude/skills/<name>/SKILL.md` exists, it only points to `skills/<name>/` and uses a project-specific name that avoids likely user-level collisions
- [ ] `AGENTS.md`, `CLAUDE.md`, `CODEX.md` each have a **routing.yaml bootstrap** (not just "go read SKILL.md")
- [ ] `.codex/instructions.md` exists as a compatibility mirror and has a routing bootstrap
- [ ] `.cursor/rules/*.mdc` has `alwaysApply: true` entry pointing to skill with a routing bootstrap
- [ ] `README.md` is overview + navigation, not a rule manual
- [ ] All file references and links are valid
- [ ] `routing.yaml` is the source of truth; `bash skills/<name>/scripts/sync-routing.sh <name> --check` passes
- [ ] No content orphaned or duplicated across locations

### Activation Checks (see [references/protocols.md § Skill Activation Verification](references/protocols.md#skill-activation-verification))

- [ ] `description` field is ≥ 20 words or ≥ 40 CJK characters, with at least 2 quoted trigger phrases in the user's actual language(s)
- [ ] `description` in `.cursor/skills/<name>/SKILL.md` matches the formal skill's description
- [ ] Common Tasks covers the project's 5–10 most common task types
- [ ] Known Gotchas section exists (even if empty at initial migration — it will grow via AAR)

**Checkpoint — end of Phase 8:**
```bash
bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" && echo "phase=8" > .migration-state
```

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

Open `skills/<name>/workflows/update-rules.md` § "Rationalizations to Reject" (or `templates/protocol-blocks/rationalizations-table.md` for the reusable version). Add a new row:

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

**Recommended:** install `templates/hooks/session-start` so the router and Task Closure Protocol are re-injected on `/clear` and `/compact`. Context compression is itself a pressure source — without the hook, a single `/compact` can silently disable all routing and protocol enforcement. Multi-skill projects should create `skills/router/SKILL.md` or set `SKILL_ROUTER_PATH`; do not inject every skill.

**Checkpoint — end of Phase 9:** `echo "phase=9" > .migration-state` (migration complete)

## Resuming From a Failed Phase

Migration crashes happen: the shell exits mid-`sed`, a `/compact` fires, the laptop reboots. Re-running from Phase 1 is tempting — **don't**. Half-baked artifacts from later phases (a partially-templated workflow file, a CODEX.md with `{{NAME}}` still in it) will produce false positives in earlier phases' checks, letting you "pass" a phase that is actually broken.

Instead, treat migration as a checkpoint-able state machine. One line in `.migration-state`, one re-entry detector, one per-phase validator.

### `.migration-state` — minimal checkpoint

The Quick Start script writes `.migration-state` (single line, `phase=<N>`) after each phase completes. A crashed run leaves the file pointing at the last known-good phase. Re-entry reads it, skips completed phases, resumes from `phase+1`.

If the file is missing, the snippet below auto-detects the current phase from artifact signatures.

### Phase artifact signatures

Each phase has a deterministic artifact. Passing the signature means the phase is done; failing means it must be re-run (and anything from later phases should be considered suspect).

| Phase | Artifact signature (bash-testable) |
|---|---|
| 3 | `test -f skills/$NAME/SKILL.md && test -f skills/$NAME/routing.yaml && [ $(wc -l < skills/$NAME/SKILL.md) -le 100 ]` |
| 4 | `test -f skills/$NAME/rules/project-rules.md && test -f skills/$NAME/rules/coding-standards.md` |
| 5 | `test -f skills/$NAME/workflows/update-rules.md && bash skills/$NAME/scripts/smoke-test.sh $NAME --phase 5` |
| 6 | `test -f skills/$NAME/references/gotchas.md` |
| 7 | `test -f .cursor/skills/$NAME/SKILL.md && test -f AGENTS.md && test -f CLAUDE.md && test -f CODEX.md && test -f GEMINI.md` |
| 7 (no placeholder residue) | `! grep -rn '{{NAME}}\|{{SUMMARY}}' skills/$NAME AGENTS.md CLAUDE.md CODEX.md GEMINI.md .codex .cursor` |
| 8 | `bash skills/$NAME/scripts/smoke-test.sh $NAME` exits 0 |
| 9 | At least one row in `skills/$NAME/workflows/update-rules.md` § Rationalizations to Reject came from a real pressure test (manual attestation) |

### One-command phase advance: `templates/migration/migrate.sh`

Instead of manually copy-pasting the checkpoint bash at the end of each phase, use the wrapper. It runs the smoke-test for the phase you claim to have finished and **only** writes the checkpoint if validation passes:

```bash
# Machine-validated phases (3–8) — validates then checkpoints; refuses on failure
NAME=my-project bash "$UPSTREAM/templates/migration/migrate.sh" 4

# Human-only phases (1, 2, 9) — prompts "Have you completed Phase N? [y/N]"
NAME=my-project bash "$UPSTREAM/templates/migration/migrate.sh" 1

# Status (delegates to resume.sh)
NAME=my-project bash "$UPSTREAM/templates/migration/migrate.sh" status
```

### Resuming after a crash: `templates/migration/resume.sh`

When the migration shell exits unexpectedly, run `resume.sh` to find out where you are:

```bash
NAME=my-project bash "$UPSTREAM/templates/migration/resume.sh"

# Also re-validate the last checkpoint before trusting it
NAME=my-project bash "$UPSTREAM/templates/migration/resume.sh" --advance
```

The script reads `.migration-state` (or auto-detects from artifact signatures), warns on placeholder residue (`{{NAME}}`/`{{SUMMARY}}` from a half-completed sed pass), and prints the next WORKFLOW phase to run. See [`templates/migration/README.md`](templates/migration/README.md).

### Detect-and-resume snippet (manual)

If you want to embed detection into your own shell without invoking the script, the equivalent logic is:

```bash
NAME="${NAME:?set NAME first}"
if [ -f .migration-state ]; then
  START=$(sed -n 's/^phase=//p' .migration-state)
  echo "Resuming: last completed phase=$START"
else
  # auto-detect highest completed phase
  START=0
  test -f "skills/$NAME/SKILL.md" && test -f "skills/$NAME/routing.yaml" && [ $(wc -l < "skills/$NAME/SKILL.md") -le 100 ] && START=3
  test -f "skills/$NAME/rules/coding-standards.md" && START=4
  test -f "skills/$NAME/workflows/update-rules.md" && bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" --phase 5 >/dev/null 2>&1 && START=5
  test -f "skills/$NAME/references/gotchas.md" && START=6
  test -f ".cursor/skills/$NAME/SKILL.md" && test -f GEMINI.md && START=7
  bash "skills/$NAME/scripts/smoke-test.sh" "$NAME" >/dev/null 2>&1 && START=8
  echo "Auto-detected last completed phase=$START"
fi
echo "Next phase to run: $((START + 1))"
```

### Per-phase validation — `smoke-test.sh --phase N`

The full smoke test runs 40+ checks and is only meaningful at Phase 8. Use the `--phase N` flag to run the subset relevant to a single phase:

```bash
bash skills/$NAME/scripts/smoke-test.sh $NAME --phase 4   # rules only
bash skills/$NAME/scripts/smoke-test.sh $NAME --phase 7   # shells + routing bootstraps
bash skills/$NAME/scripts/smoke-test.sh $NAME             # all (Phase 8)
```

Run `--phase N` at the tail of phase N before writing `phase=N` to `.migration-state`. A phase that fails validation must not be checkpointed.

### Anti-pattern: "Just rerun from the start"

A half-completed Phase 5 can leave `workflows/*.md` files with `{{NAME}}` still inside. A Phase 3 rerun will happily overwrite `SKILL.md` but leave the workflow stubs untouched — and a subsequent Phase 8 will pass the "SKILL.md ≤ 100 lines" check while the project is actually broken. Always detect-and-resume, or explicitly `rm -rf skills/$NAME .cursor/skills/$NAME .migration-state` before restarting. No in-between.

## Upgrading an Existing Downstream Project

When upstream adds new templates, hooks, protocol-blocks, scripts, or workflow improvements, existing downstream projects need an **agent-led upstream refresh** — not a full re-migration and not user-performed diffing. The user should be able to say "上游项目更新了,帮我更新一下"; the agent then follows `skills/<name>/workflows/update-upstream.md`.

The downstream template embeds the upstream source:

```text
https://github.com/WoJiSama/skill-based-architecture.git
```

No lockfile is required in the downstream project. The agent clones the latest upstream into a temp directory, compares local files itself, patches in useful upstream changes, and validates the result.

### Ownership Rules

- **Project-owned, never overwrite** — `rules/project-rules.md`, `rules/coding-standards.md`, `references/gotchas.md`, project-specific workflows, `SKILL.md` prose, `routing.yaml` trigger examples.
- **Mechanism-owned, agent may port changes** — `scripts/*.sh`, universal hooks, protocol-blocks, reusable workflow scaffolding. Still compare before editing; do not blind-copy over local changes.
- **Generated, never hand-edit** — Always Read lists, Common Tasks, and thin-shell bootstraps. Update `routing.yaml`, then run `scripts/sync-routing.sh`.

### Agent Procedure

1. Read `skills/<name>/workflows/update-upstream.md`.
2. Clone upstream to a temp directory.
3. Compare downstream vs upstream as the agent; do not ask the user to run or inspect diffs.
4. Apply small patches that preserve local project knowledge.
5. Ask the user only for semantic conflicts that cannot be resolved from code/docs evidence.
6. Run `sync-routing.sh`, `smoke-test.sh`, `check-description-routing.sh`, and orphan checks.
7. Report what upstream changes were adopted, what local customizations were preserved, and what was intentionally left untouched.

### What NOT to do

- Don't re-run `templates/migration/*.sh` on an already-migrated project — they'll clobber project-specific content
- Don't ask the user to manually diff upstream and downstream; the workflow exists so the agent does that work
- Don't use whole-file replacement unless the target is missing or the agent verifies the local file is an unmodified old upstream template
- Don't propagate experimental upstream additions (principles that accumulated in an over-cap `agent-behavior.md` during testing, etc.) — only the canonical clean state belongs downstream
- Don't use absolute paths in subagent prompts when probing — they bypass `isolation: worktree` and leak writes back to main (see `examples/behavior-failures.md`)

## Ongoing Maintenance

After initial migration, two mechanisms keep the documentation healthy over time:

1. **Self-evolution** — `update-rules.md` includes after-action review and learn-from-mistakes steps, so the Agent proactively records new patterns, pitfalls, and conventions discovered during tasks. The sync trigger table itself is also a living document that grows as new mapping relationships are discovered. The review is lightweight, but it still happens before the task is considered done.

2. **Self-maintenance** — `maintain-docs.md` provides file health checks, split procedures, and merge procedures. Line counts are **signals, not commands** — exceeding a threshold triggers evaluation, not automatic action. Only split when the file genuinely covers separable topics; only merge when fragments genuinely belong together.

## Incremental Migration

Not every project can migrate all 9 phases in one pass. A phased approach:

1. **Round 1 — Structure + Rules**: Create `skills/<name>/`, write `SKILL.md`, extract rules only
2. **Round 2 — Workflows**: Extract workflows; update `SKILL.md` task entries
3. **Round 3 — References + Thin shells**: Move references; convert root entries to thin shells

Key principles:

- Each round should leave the project in a **working state** — no broken references
- Old files can coexist temporarily; mark them with `<!-- MIGRATING: see skills/<name>/ -->` until fully moved
- Don't block daily work for migration; migrate a file when you next need to edit it
- After each round, run the Phase 8 checklist on the parts completed so far
