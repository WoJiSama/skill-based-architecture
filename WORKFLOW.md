# Migration Workflow

Step-by-step procedure for restructuring a long SKILL.md or scattered rules into Skill-based architecture.

## Quick Start

For small-to-medium projects, run the scaffold and fill in content. Skip the full 8-phase process.

### Which path should I take?

Answer these questions to decide:

1. **Is the total rule content > 150 lines across all files?** (Count SKILL.md + AGENTS.md + .cursor/rules/ + README rules sections combined, not just one file)
2. **Are rules duplicated across 2+ entry files?** (e.g., AGENTS.md and .cursor/rules/ overlap)
3. **Do you have recurring pitfalls that keep being rediscovered?** (same debugging lesson learned twice)

| Answers | Path |
|---------|------|
| All No | **Minimal single SKILL.md** — use the [minimal starter template](TEMPLATES.md) |
| 1 Yes, others No | **Quick Start scaffold** below — run the script, fill TODOs |
| 2+ Yes | **Full 8-phase migration** — follow Phase 1–8 below |

If the project has only one small skill, no duplicated entry files, and no growing rule/reference sprawl yet, **do not force the full architecture immediately**. Start with a single well-written `SKILL.md` using the minimal starter template in [TEMPLATES.md](TEMPLATES.md), and upgrade only when one of the conditions above becomes true.

**Step 1 — Scaffold.** Run the script below (replace `<name>` with your project name):

```bash
NAME="<name>"
mkdir -p "skills/$NAME/rules" "skills/$NAME/workflows" "skills/$NAME/references" .cursor/rules

# SKILL.md skeleton
cat > "skills/$NAME/SKILL.md" << 'TMPL'
---
name: <name>
version: "1.0"
description: >
  This skill should be used when the user asks to "TODO trigger phrase 1",
  "TODO trigger phrase 2", or "TODO trigger phrase 3".
  Activate when TODO condition.
primary: true
---

# <Project Name>

TODO one-line summary.

## Always Read
1. `rules/project-rules.md`
2. `rules/coding-standards.md`

## Common Tasks
- TODO task → read `rules/<x>.md` + follow `workflows/<y>.md`
- Fix bug → read task-relevant `rules/*.md` + follow `workflows/fix-bug.md`; ref: `references/gotchas.md`
- Other → proceed with Always Read rules; check `workflows/` and `references/` for closest match

## Known Gotchas
- TODO: add costly pitfalls here as they are discovered (see `references/gotchas.md` for details)

## Rule Priority
1. This SKILL.md
2. `rules/`
3. `workflows/`
4. `references/`
5. Root thin shells (compatibility only)

## Project Boundaries
- TODO
TMPL

# Minimal rule files
cat > "skills/$NAME/rules/project-rules.md" << 'TMPL'
# Project Rules

TODO: scope, boundaries, dependency strategy, update policy.
TMPL

cat > "skills/$NAME/rules/coding-standards.md" << 'TMPL'
# Coding Standards

TODO: naming, comment style, editing conventions.
TMPL

# Meta-workflows (copy from TEMPLATES.md and customize)
cat > "skills/$NAME/workflows/update-rules.md" << 'TMPL'
# Rule Update Workflow

TODO: copy the template from TEMPLATES.md and fill in project-specific sync triggers.
TMPL

cat > "skills/$NAME/workflows/maintain-docs.md" << 'TMPL'
# Documentation Health Maintenance

TODO: copy the template from TEMPLATES.md.
TMPL

# Cursor registration entry (required for Cursor discovery)
mkdir -p ".cursor/skills/$NAME"
cat > ".cursor/skills/$NAME/SKILL.md" << TMPL
---
name: $NAME
version: "1.0"
description: >
  This skill should be used when the user asks to "TODO trigger phrase 1",
  "TODO trigger phrase 2", or "TODO trigger phrase 3".
  (Must match skills/$NAME/SKILL.md description.)
---

# $NAME (Cursor Entry)

Formal skill content lives at \`skills/$NAME/SKILL.md\`.
**Read that file immediately, then follow its Always Read list and Common Tasks routing.**

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | \`rules/project-rules.md\` + \`rules/coding-standards.md\` | \`workflows/fix-bug.md\` |
| TODO task | \`rules/<x>.md\` | \`workflows/<y>.md\` |
| Other | \`rules/project-rules.md\` | Check \`workflows/\` for closest match |
TMPL

# Thin shells with inline routing tables
cat > AGENTS.md << 'SHELL'
# AGENTS.md

TODO one-sentence project summary.

Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| TODO task | `rules/<x>.md` | `workflows/<y>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |

## Auto-Triggers

- Before declaring any non-trivial task complete → run Task Closure Protocol (see `workflows/update-rules.md`)
- When user asks to "record/save/remember" something → project-level knowledge goes to `skills/` docs, personal preferences go to agent memory
SHELL

cat > CLAUDE.md << 'SHELL'
# CLAUDE.md

Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| TODO task | `rules/<x>.md` | `workflows/<y>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |

## Auto-Triggers

- Before declaring any non-trivial task complete → run Task Closure Protocol (see `workflows/update-rules.md`)
- When user asks to "record/save/remember" something → project-level knowledge goes to `skills/` docs, personal preferences go to agent memory
SHELL

cat > CODEX.md << 'SHELL'
# CODEX.md

Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| TODO task | `rules/<x>.md` | `workflows/<y>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |
SHELL

cat > GEMINI.md << 'SHELL'
# GEMINI.md

Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| TODO task | `rules/<x>.md` | `workflows/<y>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |

## Auto-Triggers

- Before declaring any non-trivial task complete → run Task Closure Protocol (see `workflows/update-rules.md`)
- When user asks to "record/save/remember" something → project-level knowledge goes to `skills/` docs, personal preferences go to agent memory
SHELL

mkdir -p .codex
cat > .codex/instructions.md << 'SHELL'
Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| TODO task | `rules/<x>.md` | `workflows/<y>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |
SHELL

cat > .cursor/rules/workflow.mdc << 'SHELL'
---
description: Compatibility shell — routes to formal skill.
globs: ["**/*"]
alwaysApply: true
---

Formal rules live in `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill.

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| TODO task | `rules/<x>.md` | `workflows/<y>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |

Conflicts → formal docs in `skills/` win.
SHELL

echo "✅ Scaffold created at skills/$NAME/"
echo "Next: fill in TODO placeholders, copy meta-workflow templates from TEMPLATES.md"
```

**Step 2 — Fill content.** Replace all `TODO` placeholders with real project content. For `update-rules.md` and `maintain-docs.md`, copy the full templates from [TEMPLATES.md](TEMPLATES.md) and customize the sync trigger table.

**Step 3 — Verify.** Check for unfilled placeholders: `grep -r "TODO" skills/<name>/`. Any remaining TODOs mean the migration is incomplete — agents will read broken descriptions and routing. Then run the Phase 8 checklist below to confirm everything is wired up.

For complex migrations (large projects, heavily scattered rules), follow the full Phase 1–8 process:

---

## Phase 1: Audit

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

## Phase 2: Design Structure

Determine the skill directory path: `skills/<project-name>/`

Plan the file set based on project size:

- **Minimal single-file starter** — one small `SKILL.md`, no extra directories yet; best when the skill is still short and self-contained
- **Minimum viable set** (small projects): `rules/project-rules.md`, `workflows/update-rules.md` — start here and add files only when content justifies a separate file
- **Typical set** (most projects): add `rules/coding-standards.md`, `workflows/fix-bug.md`, `workflows/maintain-docs.md`, `references/architecture.md`
- **Add domain files** as needed: `frontend-rules.md`, `backend-rules.md`, `add-page.md`, `add-controller.md`, etc.
- **Fullstack / multi-domain**: combine; consider separate skills if domains diverge significantly

Don't create empty placeholder files. Each file should exist because it has meaningful content (at least 30 lines), not because a template says it should.

See [REFERENCE.md § Common Rule File Sets by Project Type](REFERENCE.md#common-rule-file-sets-by-project-type) for detailed per-type file lists.

## Phase 3: Write SKILL.md

The new `SKILL.md` should contain **only**:

1. Frontmatter (`name`, `version`, `description` with trigger phrases)
2. One-line project summary
3. Always-read list (2–3 core rule files that apply to every task)
4. Common Tasks with full file routing (each task lists exactly which rules, workflows, and references to read — not just a workflow link)
5. Known Gotchas (brief, scannable summaries pointing to `references/gotchas.md` for details)
6. Rule priority (SKILL.md > rules/ > workflows/ > references/ > .cursor)
7. Project boundaries (2–5 bullets)

**Description field:** Write it as a trigger condition, not a passive summary. Include ≥ 2 quoted trigger phrases (e.g. `"add a new page"`, `"fix frontend bug"`) and concrete activation conditions. See [REFERENCE.md § Description as Trigger Condition](REFERENCE.md#description-as-trigger-condition) for examples.

**Target: ≤ 100 lines.** If longer, content belongs in sub-files.

## Phase 4: Extract Rules

Move stable constraints into `skills/<name>/rules/`:

- `project-rules.md`: scope, boundaries, priority, update policy
- `coding-standards.md`: comment style, editing conventions
- Domain rules: `frontend-rules.md`, `backend-rules.md`, etc.

Each rule file should state what it governs, the constraints, and when to update.

## Phase 5: Extract Workflows

Create dedicated workflow files for recurring tasks in `skills/<name>/workflows/`.

Each workflow includes:

1. What it's for (one sentence)
2. Prerequisites / what to read first
3. Ordered steps
4. Completion checklist
5. Escape conditions (when to stop or escalate)

Avoid one giant `workflow.md` — specialize by task type.

**Required meta-workflows** (create for every project):

- `update-rules.md` — rule sync + after-action review + learn-from-mistakes + deprecation (see [TEMPLATES.md § update-rules.md](TEMPLATES.md#update-rulesmd-enhanced-template))
- `maintain-docs.md` — file health check, split, and merge procedures (see [TEMPLATES.md § maintain-docs.md](TEMPLATES.md#maintain-docsmd-template))

**Task-closing hook** (apply to every project workflow, especially `fix-bug.md`, `add-*.md`, and `refactor-*.md`):

1. End the workflow with a quick After-Action Review
2. Apply the Recording Threshold
3. If the threshold passes, update the appropriate `rules/` or `references/` file
4. If task routing changed, sync `SKILL.md`
5. If shell routing changed, sync thin shells

`update-rules.md` is not a side file to visit "if you remember" — it is the shared exit path for documenting new knowledge discovered during real work.

## Phase 6: Extract References

Move explanatory content into `skills/<name>/references/`:

- Architecture overviews
- Environment/build notes
- Source indexes and module maps
- **Gotchas** — create `references/gotchas.md` (or domain-specific pitfall files like `frontend-pitfalls.md`) for known gotchas, footguns, and edge cases; then add brief summaries to SKILL.md's Known Gotchas section
- Third-party dependency notes

The gotchas file is often the **most valuable reference** in a skill — it captures expensive lessons that are not obvious from code alone and prevents repeated debugging. Keep it actively maintained via the After-Action Review.

This replaces long explanatory sections previously in `.cursor/rules/*.mdc` or `README.md`.

## Phase 7: Create Hard Entry Points

Each AI tool has a **different discovery mechanism**. Natural-language instructions ("Scan `skills/*/SKILL.md`") are not reliable — they get lost during context summarization in long conversations. You must create hard, tool-specific entry points.

See [REFERENCE.md](REFERENCE.md) for full templates.

### 7a: Cursor Registration Entry

Cursor's agent_skill discovery **only scans `.cursor/skills/`**. If the formal skill is at `skills/<name>/`, Cursor will never find it unless you create a registration entry:

Create `.cursor/skills/<name>/SKILL.md` with:
- YAML frontmatter (`name`, `description`) matching the formal skill
- A pointer to the formal `skills/<name>/SKILL.md`
- An inline routing table (task → required reads → workflow)

### 7b: Thin Shells with Inline Routing Tables

Update root entries. Each must contain an **inline routing table** — not just "go read SKILL.md":

- **AGENTS.md** — project summary + inline routing table
- **CLAUDE.md** — inline routing table + pointer to formal skill
- **CODEX.md** / **.codex/instructions.md** — inline routing table + pointer to formal skill
- **GEMINI.md** — inline routing table + pointer to formal skill
- **.cursor/rules/*.mdc** — `alwaysApply: true` + pointer to formal skill + inline routing table

An inline routing table looks like:

```markdown
| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| Add feature | `rules/<domain>-rules.md` | `workflows/<task>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |
```

This table survives context truncation because it is embedded directly in the entry file.

### 7c: Key Rules

- No duplicated rule bodies — shells route, they don't contain rules
- No standalone source of truth in `.cursor/`, `.claude/`, or `.codex/`
- Adding a new skill = dropping a folder into `skills/` + creating `.cursor/skills/<name>/SKILL.md` + updating thin shells

## Phase 8: Verify

### Structural Checks

- [ ] `skills/<name>/SKILL.md` exists and is ≤ 100 lines
- [ ] `.cursor/skills/<name>/SKILL.md` registration entry exists (required for Cursor discovery)
- [ ] All important rules migrated out of old locations
- [ ] `.cursor/`, `.claude/`, `.codex/` contain only thin shells
- [ ] `AGENTS.md`, `CLAUDE.md`, `CODEX.md` each have an **inline routing table** (not just "go read SKILL.md")
- [ ] `.codex/instructions.md` exists and has inline routing table
- [ ] `.cursor/rules/*.mdc` has `alwaysApply: true` entry pointing to skill with inline routing table
- [ ] `README.md` is overview + navigation, not a rule manual
- [ ] All file references and links are valid
- [ ] No content orphaned or duplicated across locations

### Activation Checks (see [REFERENCE.md § Skill Activation Verification](REFERENCE.md#skill-activation-verification))

- [ ] `description` field is ≥ 20 words with at least 2 quoted trigger phrases
- [ ] `description` in `.cursor/skills/<name>/SKILL.md` matches the formal skill's description
- [ ] Common Tasks covers the project's 5–10 most common task types
- [ ] Known Gotchas section exists (even if empty at initial migration — it will grow via AAR)

## Ongoing Maintenance

After initial migration, two mechanisms keep the documentation healthy over time:

1. **Self-evolution** — `update-rules.md` includes after-action review and learn-from-mistakes steps, so the Agent proactively records new patterns, pitfalls, and conventions discovered during tasks. The sync trigger table itself is also a living document that grows as new mapping relationships are discovered. The review is lightweight, but it still happens before the task is considered done.

2. **Self-maintenance** — `maintain-docs.md` provides file health checks, split procedures, and merge procedures. Line counts are **signals, not commands** — exceeding a threshold triggers evaluation, not automatic action. Only split when the file genuinely covers separable topics; only merge when fragments genuinely belong together.

## Incremental Migration

Not every project can migrate all 8 phases in one pass. A phased approach:

1. **Round 1 — Structure + Rules**: Create `skills/<name>/`, write `SKILL.md`, extract rules only
2. **Round 2 — Workflows**: Extract workflows; update `SKILL.md` task entries
3. **Round 3 — References + Thin shells**: Move references; convert root entries to thin shells

Key principles:

- Each round should leave the project in a **working state** — no broken references
- Old files can coexist temporarily; mark them with `<!-- MIGRATING: see skills/<name>/ -->` until fully moved
- Don't block daily work for migration; migrate a file when you next need to edit it
- After each round, run the Phase 8 checklist on the parts completed so far
