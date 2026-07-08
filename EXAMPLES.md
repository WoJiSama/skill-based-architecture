# Examples

Concrete illustrations of skill-based architecture in action. Pick the subsection that matches your situation; nobody needs to read all of it.

For verbatim agent failure-mode patterns from real pressure tests (with rationalizations and the specific mechanism that catches each), see [`examples/behavior-failures.md`](examples/behavior-failures.md).

For a safe first-run fixture, use [`examples/simple-repo/`](examples/simple-repo/). Hosted previews should start from [`examples/simple-repo/COPY-PASTE-INPUT.md`](examples/simple-repo/COPY-PASTE-INPUT.md) so the agent does not need to clone or inspect a GitHub folder. It is a tiny fake project with duplicated `AGENTS.md`, `CLAUDE.md`, Cursor rules, and README notes, suitable for demos without exposing private code.

---

## Migration shapes

### Oversized single SKILL.md

A 400+ line `SKILL.md` mixing rules, workflows, references, and pitfalls is a context tax on every task. Restructure into:

```
skills/<name>/
├── SKILL.md           # description ≤ 25 + body ≤ 90 lines (dual budget): routing only
├── rules/             # stable constraints, by domain
├── workflows/         # step-by-step procedures, one per task
└── references/        # architecture, gotchas
```

`SKILL.md` goes from 400 → ~60 lines; agents read 2–3 task-relevant files instead of everything.

### Scattered rules across multiple entry files

`AGENTS.md` + `.cursor/rules/frontend.mdc` + `README.md` carry overlapping content; they drift. Consolidate one source of truth under `skills/<name>/`, replace each entry file with a thin shell that points at it. Eliminates the "two files disagree on the same convention" class of bug.

### Thin shell rewrite

A 500-line `.cursor/rules/frontend.mdc` becomes ~10 lines:

```md
---
description: Cursor compatibility shell.
alwaysApply: false
---
Scan `skills/*/SKILL.md`, pick the matching one, follow its routing.
Conflicts → formal docs in `skills/` win.
```

### Self-fission (split when content separates)

`rules/backend-rules.md` grows to 350 lines covering Controller / Service / Mapper independently. Three-question check:

- Are topics separable? → yes (layers don't depend on each other)
- Is navigation difficult? → yes (find Controller convention requires scrolling 350 lines)
- Can each part stand alone? → yes (≈80 lines per layer)

Three "yes" → split. Update `routing.yaml`, regenerate.

### Self-merge (merge when fragments don't justify files)

Four files of 10–18 lines (env-setup, build-notes, deploy-notes, ci-config) all belong to "environment & deployment". Merge into one `env-and-deploy.md` (~55 lines).

### When NOT to split

A 280-line routing table covering Controller → Service → Mapper for the entire app. Single topic, easy `Ctrl+F`, no natural split. Keep as-is — the size threshold flags for evaluation, not for forced action.

---

## Project shapes

### Java / Spring Boot

Backend with rules across `AGENTS.md` (200), `.cursor/rules/backend.mdc` (300), `.cursor/rules/frontend.mdc` (Thymeleaf, 200) →

```
skills/<name>/
├── SKILL.md
├── rules/{project,coding-standards,backend,frontend}.md
├── workflows/{add-controller,add-entity-and-mapper,fix-bug}.md
└── references/{architecture,routes-and-modules,third-party-libs}.md
```

All four root entry files become 5–8 line thin shells.

### Python CLI / data project

`AGENTS.md` (300 lines, mixing CLI conventions, testing, release workflow, API reference) → `skills/<name>/{SKILL.md, rules/cli-conventions.md, workflows/{add-command,release}.md, references/{api-index,testing-notes}.md}`. The architecture works for any project type, not just web/Java.

### Multi-skill repo (auto-discovery)

Two distinct domains (e.g. main app + standalone template builder) → `skills/app/` + `skills/template-builder/` + optional `skills/shared/coding-standards.md`. Root `AGENTS.md` is one auto-discovery line: "Scan `skills/*/SKILL.md` and pick the matching one." No manual routing table; adding a third skill is a `mkdir`.

### Stay small when small

Single skill, single entry file, no duplication, no recurring gotchas → don't migrate. Keep one `SKILL.md` with frontmatter + 1–2 Common Tasks. Upgrading to the full directory structure too early adds navigation overhead without solving anything.

---

## Self-evolution patterns

### After-Action Review with the Recording Threshold

Agent finishes adding a Recoil atom + amis filter. Two candidate lessons surface:

| Lesson | Repeatable? | Costly if missed? | Not obvious? | Verdict |
|---|---|---|---|---|
| Atom naming convention `xxxAtom` | yes | no (cosmetic) | no (visible in code) | 1/3 — don't record |
| Filter must register before app init | yes | yes (30+ min blank-screen debug) | yes (timing not visible) | 3/3 — record |

The threshold filters out conventions learnable from code reading. Only the costly, non-obvious lesson lands in `references/pitfalls.md`.

### Learn from mistakes

Agent forgets to register a new Controller's route in the menu config. Fix is two lines, but the lesson is missing-workflow-step, not missing-knowledge. Update `workflows/add-controller.md` step list and completion checklist; the same mistake won't ship twice.

### Recorded but not activated

A pitfall sits in `references/frontend-pitfalls.md` correctly, but the next bug-fix task never reads that reference. Knowledge stored ≠ knowledge captured. Wire it: update `workflows/fix-bug.md` completion check + `SKILL.md` Common Tasks pointer for the matching task type. References preserve lessons; workflows + routing make them harder to skip.

### Description that doesn't fire

```yaml
description: API development helper.
```

5 words, no trigger phrases. The skill exists but is functionally dead — Claude undertriggers safe-by-default. Replace with:

```yaml
description: >
  This skill should be used when the user asks to "add a new API endpoint",
  "write controller logic", "fix a backend bug", or "add a database migration".
  Activate when REST routes, request validation, service-layer logic, or
  mapper changes are involved.
```

≥ 20 words, ≥ 2 quoted user phrases, explicit `Activate when…` block.

### Behavior-change UI task that skipped AAR

Project has `workflows/task-closure.md` and thin-shell Auto-Triggers, but a UI fix that changed interaction timing / overlay layering ended right after code verification. Fix the upstream template, not the project: make the closure gate impossible to read as optional, broaden "behavior change" to explicitly include interaction / schema / renderer / overlay / styling-that-changes-outcomes.

---

## Behavior-layer failures

For verbatim agent rationalizations and the specific mechanism that catches each, see [`examples/behavior-failures.md`](examples/behavior-failures.md). Topics covered:

- Skipping AAR on a "small" task
- Description written as passive summary → skill never activates
- Same-session new task: agent skips re-routing
- Perf edit shipped without measuring baseline
- Vague "refactor / clean up" prompt bypasses routing
- Absolute paths in subagent prompts bypass `isolation: worktree`

These are the only examples actively maintained as a growing corpus — they only land here when captured from a real session, never speculatively.

---

## How to add to this file

- **Patterns and project shapes (above):** only when the same shape recurs across two or more real projects. Speculative variants stay out.
- **Behavior-layer failures (`examples/behavior-failures.md`):** captured verbatim from a real pressure-test failure only. Same admission rule as the Rationalizations Table in `templates/skill/workflows/task-closure.md`.
