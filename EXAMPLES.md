# Examples

## Start Here

If you're reading this for the first time, start with these 4 examples — they cover the most common scenarios:

1. **[Example 1](#example-1-oversized-single-skillmd)** — Single oversized SKILL.md → structured directory (the core migration)
2. **[Example 4](#example-4-java--spring-boot-project)** — Full Java/Spring Boot migration with real file routing
3. **[Example 7](#example-7-self-evolution--after-action-review)** — How the recording threshold filters noise and keeps only high-value lessons
4. **[Example 14](#example-14-description-trigger-phrases--silent-activation-failure)** — Why a vague description kills your skill silently

The remaining examples cover edge cases (when NOT to split, when to merge), advanced patterns (activation vs. storage, AAR miss), and specific project types (Python CLI, multi-skill).

---

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

## Example 4: Java / Spring Boot Project

### Before

- `AGENTS.md` with 200 lines: package structure, Controller/Service/Mapper conventions, routing table, third-party libs
- `.cursor/rules/backend.mdc` duplicates `AGENTS.md` with 300 lines of backend rules
- `.cursor/rules/frontend.mdc` has 200 lines of Thymeleaf template conventions
- `CLAUDE.md` copies half of `AGENTS.md`; `CODEX.md` doesn't exist

### After

```text
skills/<name>/
├── SKILL.md                          # ~70 lines: Always Read + Common Tasks
├── rules/project-rules.md            # module boundaries, dep strategy, update policy
├── rules/coding-standards.md         # naming, DI style, comment rules
├── rules/backend-rules.md            # Controller/Service/Mapper conventions, return structure
├── rules/frontend-rules.md           # Thymeleaf layout, CSS variables, JS patterns
├── workflows/add-controller.md       # new Controller + route + template
├── workflows/add-entity-and-mapper.md # new Entity + Mapper + Service
├── workflows/fix-bug.md              # debug flow
├── references/architecture.md         # package map, tech stack versions
├── references/routes-and-modules.md   # full Controller → Service → Mapper routing table
└── references/third-party-libs.md     # Maven deps, version notes
AGENTS.md                             # ~6 lines: pointer to SKILL.md
CLAUDE.md                             # ~5 lines: thin shell
CODEX.md                              # ~5 lines: thin shell
.cursor/rules/backend.mdc             # ~5 lines: thin shell
.cursor/rules/frontend.mdc            # ~5 lines: thin shell
```

### SKILL.md excerpt for this project

```md
## Always Read
1. `rules/project-rules.md`
2. `rules/coding-standards.md`

## Common Tasks
- Add Controller → read `rules/backend-rules.md` + follow `workflows/add-controller.md`; ref: `references/routes-and-modules.md`
- Add Entity/Mapper → read `rules/backend-rules.md` + follow `workflows/add-entity-and-mapper.md`
- Edit Thymeleaf page → read `rules/frontend-rules.md`; ref: `references/architecture.md`
- Fix bug → read task-relevant `rules/*.md` + follow `workflows/fix-bug.md`
- Other → proceed with Always Read rules; check `workflows/` and `references/` for closest match
```

### Why

- Backend rules (Controller conventions, return structure, exception handling) no longer scattered across 3 files
- Adding a new Controller or Entity has a dedicated workflow — no guessing
- Routing reference and dependency notes live in references, not mixed into rules
- Agent reads only task-relevant files via Common Tasks instead of everything
- All thin shells are minimal: point to `SKILL.md`, nothing else

---

## Example 5: Python CLI / Data Project

### Before

One `AGENTS.md` with 300 lines: CLI conventions, testing rules, release workflow, API reference. `.cursor/rules/python.mdc` duplicates half of it.

### After

```text
skills/<name>/
├── SKILL.md
├── rules/project-rules.md       # scope, Python version, dep management
├── rules/cli-conventions.md     # argument parsing, output format, exit codes
├── workflows/add-command.md     # new CLI subcommand procedure
├── workflows/release.md         # version bump + publish steps
├── references/api-index.md      # module/function quick reference
└── references/testing-notes.md  # test strategy, fixtures, CI
.cursor/rules/python.mdc         # thin shell
```

### Why

- This architecture works for any project type, not just Web/Java
- Each operation (add command, release) has its own workflow doc
- Test strategy and API indexes don't clutter the rules

---

## Example 6: Multi-Skill Coexistence

### Scenario

A repo has two distinct domains: main application development + a standalone template/tool builder. Rules and workflows for each are very different.

### Layout

```text
skills/
├── app/                           # Main application skill
│   ├── SKILL.md
│   ├── rules/backend-rules.md
│   ├── rules/frontend-rules.md
│   ├── workflows/add-controller.md
│   └── references/architecture.md
├── template-builder/              # Template building skill
│   ├── SKILL.md
│   ├── rules/template-rules.md
│   ├── workflows/create-template.md
│   └── references/template-spec.md
└── shared/                        # Cross-skill shared rules
    └── coding-standards.md
AGENTS.md                          # auto-discovery shell (no manual routing)
```

### AGENTS.md (auto-discovery, same for any number of skills)

```md
# AGENTS.md

Multi-domain project.

Scan `skills/*/SKILL.md` — pick the one matching your current task, then follow its routing.

Formal docs live under `skills/`; this file is a compatibility shell.
```

The Agent reads both `skills/app/SKILL.md` (name: app, description: main application) and `skills/template-builder/SKILL.md` (name: template-builder, description: standalone template tool), then picks the one matching the current task. **No manual routing table needed — adding a third skill = dropping a new folder.**

### Why

- Two domains' rules don't interfere — each evolves independently
- Agent discovers and selects the right skill automatically via frontmatter
- Adding a new skill requires zero changes to AGENTS.md or any thin shell
- Shared rules exist in exactly one place, not duplicated across skills

---

## Example 7: Self-Evolution — After-Action Review

### Scenario

Agent completes a task: adding a new page that uses a Recoil atom + custom amis filter. During the task, it discovers that the atom naming pattern and the filter registration method aren't documented anywhere.

### After-Action Review

```text
Review scan:
1. New pattern? → ✅ Recoil atom naming uses `xxxAtom`, not documented
2. New pitfall? → ✅ Filter must be registered before app init, otherwise first render fails
3. Missing rule? → ✅ No standard procedure for filter registration
4. Outdated/obsolete rule? → No

Recording threshold — atom naming convention:
  Repeatable?         Yes, every new atom encounters this          → PASS
  Costly if missed?   No, inconsistent naming doesn't cause errors → FAIL
  Not obvious?        No, existing atoms clearly show the pattern  → FAIL
  Result: 1/3 met → Don't record (conventions learnable from code don't need docs)

Recording threshold — filter registration timing pitfall:
  Repeatable?         Yes, every new filter encounters this           → PASS
  Costly if missed?   Yes, first-render blank screen, 30+ min debug  → PASS
  Not obvious?        Yes, timing dependency not apparent from code   → PASS
  Result: 3/3 met → Record

Actions taken:
- Appended one bullet point to references/pitfalls.md about filter registration timing
- Added to sync trigger table: "New amis filter → references/pitfalls.md"
- Atom naming convention NOT recorded
```

### Why

- Only records pitfalls that "cost 30+ minutes if you don't know", not conventions "learnable from code"
- Rule files stay lean — every entry carries real value
- The threshold filtered out 1/3 of potential records, preventing bloat

---

## Example 8: Learn from Mistakes

### Scenario

Agent adds a new Controller but forgets to register the route in the menu config. User points out the page is invisible. Agent fixes it, then runs the learn-from-mistakes flow.

### Learn-from-Mistakes Flow

```text
Error analysis:
- Root cause: missing rule — workflows/add-controller.md has no "register menu" step
- Not outdated, not unfollowed — the rule simply didn't exist

Actions taken:
- Added step 4 to workflows/add-controller.md: "Register the route in the menu configuration"
- Added to completion checklist: "[ ] New route is visible in the menu"
```

### Why

- The same mistake won't happen twice
- Workflows become progressively more complete rather than staying at their initial version
- The Agent's "experience" is codified into reusable checklists

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

## Example 12: Bug Fix → References Update

### Scenario

Agent fixes a frontend bug in a modal dialog that contains Tabs and an inner data-loading service. The immediate bug is solved, but the real lesson is a non-obvious lifecycle pitfall: reopening the dialog only reloads the outer layer unless mount behavior and inner state reset are handled correctly.

### During the Fix

```text
Observed behavior:
- First open works
- Close and reopen only refreshes the outer API
- Inner tab content stays stale or never re-requests

Root cause:
- Dialog + Tabs + nested service chain created a lifecycle mismatch
- The bug was not obvious from reading one component in isolation
- The team had no written note about when to use mountOnEnter: false or when mixed React/embedded-render state must be reset
```

### Task Closure Review

```text
After-Action Review:
- New pattern? → No
- New pitfall? → ✅ Yes
- Missing rule? → ✅ Yes
- Outdated rule? → No

Recording Threshold:
- Repeatable?       Yes, dialogs, tabs, and nested loaders are common        → PASS
- Costly if missed? Yes, reproducing and isolating lifecycle bugs is slow     → PASS
- Not obvious?      Yes, the interaction spans multiple layers               → PASS

Result:
- 3/3 met → record it
```

### Actions Taken

```text
Documentation updates:
- Added the lifecycle pitfall to references/frontend-pitfalls.md
- Added the mixed-render exception/placement note to references/react-amis-hybrid.md
- Added a sync trigger row to workflows/update-rules.md:
  "Dialog / tabs / nested service lifecycle issue → update frontend-pitfalls.md,
   and update react-amis-hybrid.md when mixed rendering is involved"
- Added a completion reminder to workflows/fix-bug.md so future bug-fix tasks
  must re-check the same class of pitfall instead of relying on memory alone
- If the fix changed task routing, also update SKILL.md Common Tasks
```

### Why

- The task is not considered fully complete until the team decides whether the lesson is worth keeping
- The threshold prevents documenting every minor bug, but catches expensive framework/lifecycle gotchas
- Future agents can now find the pitfall before repeating the same debugging session

---

## Example 13: Recorded But Not Activated

### Scenario

Agent documents an expensive frontend lifecycle bug only in `references/frontend-pitfalls.md`. The note is correct, but the next similar task still misses it.

### Weak Outcome

```text
What happened:
- The pitfall was recorded in references/frontend-pitfalls.md
- No workflow checklist changed
- SKILL.md Common Tasks still routed "Fix bug" to generic files only
- The next bug-fix task never naturally read that reference

Result:
- Knowledge was stored
- Knowledge was not activated
- The team still repeated part of the debugging work
```

### Strong Outcome

```text
What changed:
- The pitfall stayed in references/frontend-pitfalls.md for the full explanation
- workflows/fix-bug.md gained a completion check pointing to update-rules.md
- SKILL.md Common Tasks for the relevant task now points to the pitfall reference

Result:
- Knowledge was stored in the right place
- The normal task path now surfaces the lesson
- Future agents are much less likely to miss it
```

### Why

- `references/` preserves lessons
- `workflows/` and routing make those lessons harder to skip
- High-cost pitfalls should be both documented and activated

---

## Example 14: Description Trigger Phrases — Silent Activation Failure

### Scenario

A project skill is properly structured with rules, workflows, and references, but the Agent never activates it. The user has to manually tell the Agent "read the skill" every time.

### Before (broken — skill never fires)

```yaml
---
name: my-api
description: API development helper
primary: true
---
```

5-word description. The Agent has no idea when to activate this skill. It scores 0 on the most heavily weighted check in skill quality audits. The skill exists but is functionally dead.

### After (reliable activation)

```yaml
---
name: my-api
version: "1.0"
description: >
  This skill should be used when the user asks to "add a new API endpoint",
  "write controller logic", "fix a backend bug", or "add a database migration".
  Activate when the task involves REST routes, request validation,
  service layer logic, or MyBatis mapper changes.
primary: true
---
```

### Why

- **Trigger phrases** (`"add a new API endpoint"`, `"fix a backend bug"`) tell the Agent exactly which user requests should activate this skill
- **Activation conditions** (REST routes, request validation, service layer) cover task contexts beyond the exact phrases
- **Third-person format** ("This skill should be used when…") matches the Agent's selection logic
- **≥ 20 words** ensures enough signal for reliable matching
- The difference between a working skill and a dead one is often a single frontmatter field

---

## Example 15: When a Small Single SKILL.md Is Better

### Scenario

A small project has one skill, one entry file, and only a handful of stable rules. Nothing is duplicated yet, and there are no recurring gotchas that need active maintenance.

### Better Choice

Keep a single concise `SKILL.md` instead of immediately creating:

```text
skills/<name>/
├── rules/
├── workflows/
├── references/
└── docs/
```

Use a minimal starter like:

```md
---
name: mini-project
description: >
  This skill should be used when the user asks to "update the mini project",
  "fix a bug", or "add a small feature".
  Activate when working inside this repo.
---

# Mini Project

Small internal tool with one main workflow.

## Always Read
1. `SKILL.md` itself

## Common Tasks
- Fix bug → inspect the affected file and keep changes minimal
- Add small feature → follow existing patterns in nearby code
```

### Why

- No duplicated entry files means there is nothing to consolidate yet
- Splitting too early adds navigation overhead without reducing real complexity
- A small, precise `SKILL.md` is easier to maintain than an empty directory tree
- Upgrade to full skill-based architecture only when content starts to sprawl, duplicate, or accumulate non-obvious lessons

---

## Example 16: Rules Exist, But AAR Still Got Skipped

### Scenario

A downstream project already has:

- `workflows/update-rules.md`
- thin-shell `Auto-Triggers`
- task routing in `SKILL.md`

The agent finishes a UI task that changed behavior: interaction timing, overlay layering, host compatibility, or styling that affects the actual outcome. The code fix works, but no rule or reference update happens.

### What Went Wrong

```text
Observed failure:
- The project already had an After-Action Review workflow
- The entry files already mentioned Auto-Triggers
- The task still ended right after the code fix and verification

Root cause:
- The workflow text treated update-rules as something to "also do"
- "Behavior change" was interpreted too narrowly as business logic only
- UI / interaction / layering changes were misclassified as low-value styling cleanup

Result:
- The rule system existed
- The lesson was still not recorded
- The next similar task could repeat the same debugging work
```

### Stronger Upstream Fix

```text
Template changes:
- fix-bug.md now says behavior-changing tasks must run update-rules.md before closure
- "Behavior change" explicitly includes interaction changes, schema / renderer behavior changes,
  styling conventions that change outcomes, overlay / z-index / layering behavior, and host-compatibility changes
- update-rules.md explicitly lists UI convention / host compatibility /
  layering issues as valid sync-trigger categories
- thin-shell Auto-Triggers mention the same broader behavior-change scope
```

### Why

- The problem was not "missing workflow", but "workflow too easy to treat as optional"
- Making the exit path harder to skip is more effective than adding more scattered reminders
- Once the upstream template is fixed, future downstream skills inherit the stronger closure behavior by default

---

## Summary

**Good fit:**

- SKILL.md or `.cursor/rules/*.mdc` exceeds ~150 lines
- Multiple entry files with significant content duplication
- Frontend/backend or multi-module projects needing clearer doc navigation

**Don't force it:**

- Very small projects (fewer than 3 rule files)
- Temporary repos with no long-term maintenance needs
- Teams with a well-functioning documentation system already in place
