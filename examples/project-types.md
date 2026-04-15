# Examples — Project Types

Canonical structures for common project shapes. See [README.md](README.md) for the full index.

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
