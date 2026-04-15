# Examples — Migration & Refactor Patterns

How to restructure existing rules into skill-based architecture. See [README.md](README.md) for the full index.

## Example 1: Oversized Single SKILL.md

### Before

A single `SKILL.md` with 400+ lines mixing project rules, coding standards, workflow steps, architecture notes, and pitfall lists.

### After

```text
skills/<name>/
├── SKILL.md                     # ~60 lines: entry + navigation
├── rules/project-rules.md       # scope, boundaries, priorities
├── rules/coding-standards.md    # comment/editing conventions
├── rules/frontend-rules.md      # UI framework constraints
├── workflows/add-page.md        # step-by-step: new page
├── workflows/fix-bug.md         # step-by-step: debug flow
├── references/architecture.md   # system design overview
└── references/pitfalls.md       # known gotchas
```

### Content Comparison

**Before** — single SKILL.md (excerpt, ~400 lines total):

```md
# My Project Skill

## Project Rules
- This is a Next.js project using App Router...
- Always use Server Components by default...
- (50 more lines of rules)

## Coding Standards
- Use English for all code comments...
- Never add obvious comments...
- (30 more lines)

## How to Add a New Page
1. Create route directory under app/...
2. Add page.tsx with metadata...
3. (20 more steps mixed with explanations)

## Architecture
The project uses a layered architecture...
(100 lines of explanation)

## Known Pitfalls
- Don't use useEffect for data fetching...
- (30 lines of gotchas)
```

**After** — SKILL.md (~60 lines, navigates only):

```md
---
name: my-project
description: Next.js App Router application.
---

# My Project

Next.js 14 App Router application with Server Components.

## Always Read
1. `rules/project-rules.md`
2. `rules/coding-standards.md`

## Common Tasks
- Add page → read `rules/coding-standards.md` + follow `workflows/add-page.md`; ref: `references/architecture.md`
- Fix bug → read task-relevant `rules/*.md` + follow `workflows/fix-bug.md`
- Other → proceed with Always Read rules; check `workflows/` and `references/` for closest match

## Project Boundaries
- Next.js 14 App Router only; no Pages Router
- Server Components by default; Client Components only when needed
```

Original content distributed across `rules/project-rules.md`, `rules/coding-standards.md`, `workflows/add-page.md`, `references/architecture.md`, and `references/pitfalls.md` — each independently maintained.

### Why

- SKILL.md went from 400 to 60 lines — dramatically lower context load for the Agent
- Rules, workflows, and references can be found and maintained independently
- Editing one rule doesn't require scrolling through a giant file

---
## Example 2: Scattered Rules → Unified Skill

### Before

- `AGENTS.md` and `.cursor/rules/frontend.mdc` duplicate 80% of content
- `.cursor/rules/frontend.mdc` is the only detailed reference (500 lines)
- `README.md` mixes setup, rules, architecture, and troubleshooting

### After

```text
skills/<name>/
├── SKILL.md
├── rules/project-rules.md
├── rules/frontend-rules.md
├── rules/backend-rules.md
├── workflows/add-new-tool.md
├── workflows/fix-bug.md
├── references/architecture.md
└── references/routes-and-modules.md
AGENTS.md                        # ~10 lines: summary + pointer
CLAUDE.md                        # ~8 lines: mirrors AGENTS.md
.cursor/rules/frontend.mdc      # ~15 lines: thin shell
README.md                        # overview + navigation only
```

### Why

- Eliminates massive duplication between AGENTS.md and .cursor
- .cursor is no longer the sole source of truth
- Agent has a clear reading order instead of guessing where to start

---
## Example 3: Thin Shell Rewrite

### Bad

```md
# frontend.mdc
(500 lines: rules, workflows, pitfalls, examples, architecture...)
```

### Good

```md
---
description: Cursor compatibility shell.
globs: ["src/**/*.{ts,tsx,js,jsx}"]
alwaysApply: false
---
Scan `skills/*/SKILL.md` — pick the one matching your current task, then follow its routing.
Conflicts → formal docs in `skills/` win.
```

---
## Example 9: Self-Fission — Evaluated Split

### Scenario

After months of updates, `rules/backend-rules.md` has grown to 350 lines, covering Controller conventions, Service patterns, Mapper rules, exception handling, and auth patterns. The health check flags it as over the 200-line reference threshold.

### Before

```text
rules/
├── project-rules.md        # 80 lines ✓
├── coding-standards.md     # 60 lines ✓
├── backend-rules.md        # 350 lines ✗ — needs evaluation
└── frontend-rules.md       # 120 lines ✓
```

### Evaluation

```text
Three-question check:
1. Are topics separable?
   → ✅ Controller, Service, Mapper layers are independent —
     removing one doesn't affect understanding of others
2. Is navigation difficult?
   → ✅ Finding Controller conventions requires scrolling through 350 lines
3. Can each part stand alone?
   → ✅ Controller at 80 lines and Service at 70 lines are both viable standalone

Conclusion: splitting has value.

Split plan:
- Controller conventions (80 lines) → controller-rules.md
- Service patterns (70 lines) → service-rules.md
- Mapper rules + exception handling + auth (200 lines) → backend-rules.md (retained)
```

### After

```text
rules/
├── project-rules.md        # 80 lines ✓
├── coding-standards.md     # 60 lines ✓
├── controller-rules.md     # 80 lines ✓ (new)
├── service-rules.md        # 70 lines ✓ (new)
├── backend-rules.md        # 200 lines ✓ (slimmed down)
└── frontend-rules.md       # 120 lines ✓

References updated:
- SKILL.md Common Tasks routing updated: controller/service tasks now reference the new files
- .cursor/rules/backend.mdc thin shell unchanged (still points to SKILL.md)
- workflows/add-controller.md now references controller-rules.md
```

---
## Example 10: Self-Merge — Fragment Consolidation

### Scenario

A project over-split its references into too many tiny files. The health check detects fragmentation.

### Before

```text
references/
├── architecture.md          # 45 lines ✓
├── env-setup.md             # 12 lines ✗ — too small
├── build-notes.md           # 18 lines ✗ — too small
├── deploy-notes.md          # 15 lines ✗ — too small
├── ci-config.md             # 10 lines ✗ — too small
└── routes-and-modules.md    # 150 lines ✓
```

### Evaluation

```text
Three-question check:
1. Are topics related?
   → ✅ env-setup, build-notes, deploy-notes, ci-config all belong to
     "environment & deployment"
2. Easier to find after merging?
   → ✅ Currently need to check 4 files for deployment-related info
3. Will merged file stay within limits?
   → ✅ 12+18+15+10 = 55 lines, well within the 300-line reference limit

Conclusion: merging has value.
```

### After

```text
references/
├── architecture.md          # 45 lines ✓
├── env-and-deploy.md        # 55 lines ✓ (merged)
└── routes-and-modules.md    # 150 lines ✓

References updated:
- SKILL.md references section updated
- Original 4 small files deleted
```

---
## Example 11: When NOT to Split

### Scenario

`references/routes-and-modules.md` reaches 280 lines — a complete routing table listing every Controller → Service → Mapper mapping. The size scan flags it (reference files recommend ≤ 300).

### Evaluation

```text
Three-question check:
1. Are topics separable?
   → ❌ The entire file is one routing table — completely single-topic
2. Is navigation difficult?
   → ❌ Readers come to look up routes — Ctrl+F finds anything instantly
3. Can each part stand alone?
   → ❌ Splitting alphabetically into A-M and N-Z would be meaningless

Conclusion: don't split. File is near the reference limit but is coherent
and easy to search. Keep as-is.
```

### Why

- Avoids splitting for the sake of splitting
- The health check's job is to "make you think about it", not "force you to act"
- One complete lookup table is far more useful than two incomplete ones

---
