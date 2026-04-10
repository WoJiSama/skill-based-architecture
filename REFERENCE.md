# Reference

## Recommended Layout

```text
project/
├── skills/
│   └── <name>/
│       ├── SKILL.md
│       ├── rules/
│       │   ├── project-rules.md
│       │   ├── coding-standards.md
│       │   └── <domain>-rules.md
│       ├── workflows/
│       │   └── <task>.md
│       ├── references/
│       │   ├── gotchas.md         # recommended: known gotchas / footguns
│       │   └── <topic>.md
│       └── docs/                  # optional: prompts, reports, external material
├── AGENTS.md                      # thin shell (universal)
├── CLAUDE.md                      # thin shell (Claude)
├── CODEX.md                       # thin shell (Codex)
├── .cursor/rules/*.mdc            # thin shells (Cursor)
├── .claude/                       # thin shells (Claude Code)
└── .codex/                        # thin shells (Codex CLI)
```

## SKILL.md Template

```md
---
name: <project-name>
version: "1.0"
description: >
  This skill should be used when the user asks to "<trigger phrase 1>",
  "<trigger phrase 2>", or "<trigger phrase 3>".
  Activate when <condition 1> or <condition 2>.
primary: true
---

# <Project Name>

One-line summary.

## Always Read

These files apply to every task. Read them first:
1. `rules/project-rules.md`
2. `rules/coding-standards.md`

Keep this list to 2–3 files max. Domain-specific rules do NOT go here.

## Common Tasks

Each task entry lists the exact files to read — don't read files not listed for your task:

- Add feature X → read `rules/<domain>-rules.md` + follow `workflows/<task>.md`
- Add feature Y → read `rules/<domain>-rules.md` + follow `workflows/<task>.md`; ref: `references/<topic>.md`
- Fix bug → read task-relevant `rules/*.md` + follow `workflows/fix-bug.md`; ref: `references/gotchas.md`
- **Other / unlisted task** → read `rules/project-rules.md` + `rules/coding-standards.md` (Already Read above), then match by workflow filename (verb-noun convention: `add-page.md`, `fix-bug.md`, etc.). If no filename matches, proceed with just the Always Read rules.

## Known Gotchas

Brief, scannable list of the most costly pitfalls. Full details in `references/gotchas.md`.

- Gotcha 1: one-line summary → see `references/gotchas.md#section`
- Gotcha 2: one-line summary → see `references/<topic>.md#section`

## Rule Priority
1. `skills/<name>/SKILL.md`
2. `skills/<name>/rules/`
3. `skills/<name>/workflows/`
4. `skills/<name>/references/`
5. Root `README.md`
6. `.cursor/rules/*.mdc` / `.claude/` / `.codex/` (compatibility only)

## Project Boundaries
- Boundary 1
- Boundary 2
```

### Description as Trigger Condition

The `description` field in frontmatter is **not** a passive summary — it is what the Agent uses at runtime to decide whether to activate the skill. A vague description means the skill silently never fires.

**Bad** (too vague — Agent can't match it):
```yaml
description: Helps with API testing
```

**Good** (explicit trigger phrases + conditions):
```yaml
description: >
  This skill should be used when the user asks to "test an API endpoint",
  "write integration tests for REST APIs", or "debug a failing HTTP request".
  Activate when the task involves HTTP status codes, request/response payloads,
  or API authentication flows.
```

Guidelines:
- **≥ 20 words** — short descriptions fail to activate reliably
- **Include quoted trigger phrases** — exact phrases the user would say
- **Third-person format** — "This skill should be used when…" not "I help with…"
- **Include activation conditions** — describe the context, not just the action

The template above uses a two-tier structure:

- **Always Read** (2–3 core files, ~150 lines total) — read every time
- **Common Tasks** (task-routed) — Agent reads ONLY the files listed for the current task; always include a fallback entry for unlisted tasks

**Keep routing in sync:** When you create or rename a workflow/reference file, add or update the corresponding entry in Common Tasks. The `update-rules.md` workflow includes this as a checklist item.

**Common Tasks sizing:** Keep entries to 8–10 tasks maximum. Beyond that, agents waste tokens scanning unrelated entries. If you have more than 10 recurring task types, group related tasks under domain headings (e.g., `### Backend Tasks`, `### Frontend Tasks`) or merge low-frequency tasks into the "Other" fallback.

**"Other / unlisted task" matching:** The fallback entry should tell agents how to find the right workflow without reading every file. Workflow files use a verb-noun naming convention (`add-page.md`, `fix-bug.md`, `release.md`) — agents can match by filename alone. If that's not sufficient, add a one-line directory listing in the fallback entry: `Available workflows: add-controller, add-entity, fix-bug, release`.

This keeps per-task reading to the minimum set needed, rather than loading all rules for every task.

## Relation to Official Skill Template / Spec

Anthropic's public [`skills` repository](https://github.com/anthropics/skills) defines the **minimal** skill shape: a folder with a `SKILL.md`, plus frontmatter where `name` identifies the skill and `description` explains what it does and when to use it.

This meta-skill does **not** replace that minimum. It starts one level later:

- Use the official-style minimal single `SKILL.md` when the skill is still small, self-contained, and not scattered across multiple entry files.
- Upgrade to `skills/<name>/` with `rules/`, `workflows/`, and `references/` only when the skill starts to sprawl: long files, duplicated entries, or recurring knowledge that needs active maintenance.

Rule of thumb:

- Official template answers: "How do I create a valid skill?"
- `skill-based-architecture` answers: "How do I keep a growing project skill precise, navigable, and maintainable?"

Do not copy the full official spec into project docs. Link to the canonical source when helpful, and keep local docs focused on project structure and task routing.

## Multi-Skill Projects

When a repo has multiple skills (e.g. `skills/app/` + `skills/template-builder/`):

```text
skills/
├── app/                    # Main application skill
│   ├── SKILL.md
│   ├── rules/
│   └── workflows/
├── template-builder/       # Standalone feature skill
│   ├── SKILL.md
│   ├── rules/
│   └── workflows/
└── shared/                 # Optional: cross-skill shared rules
    └── coding-standards.md
```

**Coexistence rules:**

1. **Independent entries** — each skill has its own `SKILL.md`, self-contained, no implicit cross-dependencies
2. **Registration + auto-discovery** — each skill must have a `.cursor/skills/<name>/SKILL.md` registration entry for Cursor discovery, plus thin shells with inline routing tables for Claude/Codex. Adding a skill = dropping a folder into `skills/` + creating the registration entry + updating thin shells.
3. **Priority** — when a task clearly belongs to one skill, that skill's rules take precedence; if ambiguous, Agent reads both skills' Always Read lists
4. **Shared rules** — conventions shared across skills (e.g. coding standards) go in `skills/shared/`; each skill's SKILL.md references them in its Always Read list
5. **Don't merge** — if two skills have very different domains (e.g. "app development" vs "template building"), keeping them separate is clearer than forcing a merge

**Monorepo variant:** In a monorepo with `packages/` or `apps/`, put skills at the **workspace root** (`skills/`). A single `skills/shared/` holds cross-package conventions; each package-level skill (`skills/pkg-a/`) adds package-specific rules. Auto-discovery still works — Agent scans all `skills/*/SKILL.md` and matches by description.

**When to split one skill into two:**

A growing skill may need to fission into independent skills. Evaluate when:

1. **Domains independent?** — Subdomains (e.g. frontend vs. backend) have rules that don't affect each other
2. **Description too broad?** — Agent frequently matches the skill for tasks that only touch one subdomain
3. **Common Tasks overloaded?** — Routing table exceeds 10 entries, most tasks only use one subdomain's files

All three Yes → split into separate skills under `skills/`. Move shared rules to `skills/shared/`.

## .cursor/skills/\<name\>/SKILL.md Registration Entry Template

**Required for Cursor discovery.** Cursor's agent_skill mechanism only scans `.cursor/skills/`. If the formal skill lives at `skills/<name>/`, this registration entry is mandatory — without it the skill is invisible to Cursor.

```md
---
name: <project-name>
version: "1.0"
description: >
  This skill should be used when the user asks to "<trigger phrase 1>",
  "<trigger phrase 2>", or "<trigger phrase 3>".
  (Must match formal skill's description.)
---

# <Project Name> (Cursor Entry)

Formal skill content lives at `skills/<name>/SKILL.md`.
**Read that file immediately, then follow its Always Read list and Common Tasks routing.**

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| Add feature X | `rules/<domain>-rules.md` | `workflows/<task>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |
```

**Why inline routing?** In long conversations, Cursor summarizes earlier context. Instructions like "go read `skills/<name>/SKILL.md`" get truncated. The inline routing table is embedded directly and survives summary, ensuring the agent always knows which files to read for each task type.

## Common Thin Shell Body

All thin shells share the same core content. Copy this body into each entry file, then add the tool-specific header/frontmatter shown in the per-tool sections below.

```md
Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| Add feature X | `rules/<domain>-rules.md` | `workflows/<task>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |

## Auto-Triggers

- Before declaring any non-trivial task complete → run Task Closure Protocol (see `workflows/update-rules.md`)
- Skip only for: formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors
- When user asks to "record/save/remember" something → apply Recording Destination Guide: project-level knowledge goes to `skills/<name>/` docs, personal preferences go to agent memory
```

**Why inline routing instead of just "Scan skills/"?** The "Scan skills/*/SKILL.md" instruction is natural language that gets lost during context summarization. The inline routing table embeds the essential task→file mapping directly, so the agent retains actionable routing even after summary truncation.

**Why Auto-Triggers?** A skill knows *how* to do something; the project entry tells the Agent *when* to do it. Auto-Triggers encode event→action mappings so the Agent proactively runs workflows at the right moment without waiting for a prompt.

## Per-Tool Thin Shell Templates

Each template below shows **only the tool-specific parts**. Combine each with the common body above.

### AGENTS.md

`AGENTS.md` is the **universal entry** — all AI agents (Cursor, Claude Code, Codex, etc.) read it.

```md
# AGENTS.md

One-sentence project summary.

<!-- Paste common body here -->
<!-- Optional: add project-specific auto-triggers after the common ones -->
- Before pushing to production → run `workflows/preflight.md` (if exists)
```

### CLAUDE.md

```md
# CLAUDE.md

<!-- Paste common body here (routing + auto-triggers) -->
```

### CODEX.md

```md
# CODEX.md

<!-- Paste common body here -->
<!-- Note: Auto-Triggers section is optional for Codex -->
```

### .cursor/rules/*.mdc

```md
---
description: Compatibility shell — routes to formal skill.
globs: ["**/*"]
alwaysApply: true
---

<!-- Paste common body here, with these adjustments: -->
<!-- 1. Opening line: "Formal rules live in `skills/`." (shorter form) -->
<!-- 2. Append at end: "Conflicts → formal docs in `skills/` win." -->
```

**Note:** Set `alwaysApply: true` so Cursor always sees the routing table, regardless of which files are open. Use the shorter opening line ("Formal rules live in `skills/`…") to stay within the `.mdc` size budget.

### .codex/instructions.md

```md
<!-- No file header needed — Codex reads this file directly -->
<!-- Paste common body here (routing + auto-triggers) -->
```

### .windsurf/rules/*.md

```md
---
trigger: always
---

<!-- Paste common body here, with these adjustments: -->
<!-- 1. Opening line: "Formal rules live in `skills/`." (shorter form) -->
<!-- 2. Append at end: "Conflicts → formal docs in `skills/` win." -->
<!-- Note: Auto-Triggers section is optional for Windsurf -->
```

### GEMINI.md

Gemini CLI reads `GEMINI.md` at the repo root (configurable via `.gemini/settings.json`). It also scans parent directories and subdirectories for additional `GEMINI.md` files, concatenating all discovered context. Place the thin shell at the repo root.

```md
# GEMINI.md

<!-- Paste common body here (routing + auto-triggers) -->
```

### .gemini/ Directory Note

`.gemini/` holds Gemini CLI configuration (`settings.json`, `.env`), not rule content. Context files (`GEMINI.md`) live at the repo root. If you need Gemini to also read `AGENTS.md`, configure it in `.gemini/settings.json`:

```json
{
  "context": {
    "fileName": ["GEMINI.md", "AGENTS.md"]
  }
}
```

### .claude/ Directory Note

`.claude/` in Claude Code primarily holds `settings.json` (permissions) and `commands/` (custom slash commands), not rule content. Place all instructions in the root `CLAUDE.md` (thin shell pointing to the skill). If any instruction-like files exist in `.claude/`, follow the thin-shell principle:

```md
# .claude/CLAUDE.md (if used)

All rules and workflows live under `skills/`.
See root `CLAUDE.md` for entry point.
```

## Tool Compatibility Summary

| Tool | Discovery mechanism | Required entry | Must have inline routing? |
|---|---|---|---|
| **Cursor** | Scans `.cursor/skills/` only | `.cursor/skills/<name>/SKILL.md` | Yes |
| **Cursor rules** | `.cursor/rules/*.mdc` (`alwaysApply: true`) | `.cursor/rules/workflow.mdc` | Yes |
| **Claude Code** | Reads `CLAUDE.md` at repo root | `CLAUDE.md` | Yes |
| **Codex CLI** | Reads `AGENTS.md` + `.codex/instructions.md` | Both files | Yes |
| **Windsurf** | Reads `.windsurf/rules/` | `.windsurf/rules/*.md` | Yes |
| **Gemini CLI** | Reads `GEMINI.md` at repo root (+ parent/child dirs) | `GEMINI.md` | Yes |
| **Copilot CLI** | Reads `AGENTS.md` | `AGENTS.md` (shared shell) | Yes |
| **OpenCode** | Reads `AGENTS.md` | `AGENTS.md` (shared shell) | Yes |
| **Other agents** | Reads `AGENTS.md` | `AGENTS.md` | Yes |

**All entries must contain inline routing tables** — natural-language-only instructions ("Scan skills/") get lost during context summarization in long conversations.

Pre-built shells for every harness above ship under [`templates/shells/`](templates/shells/) — downstream projects should `cp -R` the tree rather than regenerate the files inline.

## SessionStart Hook (Optional)

Context compression (`/clear`, `/compact`) drops previously-loaded skill content from the active window. A `SessionStart` hook re-injects `SKILL.md` on each fresh session or compaction boundary, turning context loss into a self-healing event rather than a silent failure mode.

The upstream ships a ready-to-copy hook at [`templates/hooks/session-start`](templates/hooks/session-start) plus two config shims:

- [`templates/hooks/hooks.json`](templates/hooks/hooks.json) — Claude Code config (`startup|clear|compact` matcher)
- [`templates/hooks/hooks-cursor.json`](templates/hooks/hooks-cursor.json) — Cursor config (same script, different env var)

The script branches on `$CLAUDE_HARNESS` / `$SESSION_HARNESS` and emits the JSON shape each harness expects:

| Harness | JSON shape |
|---|---|
| Claude Code | `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":...}}` |
| Cursor | `{"additional_context": ...}` |
| Copilot CLI / Gemini / OpenCode | `{"additionalContext": ...}` |

Marked optional because not every harness supports SessionStart hooks. Install it only if your primary harness does and context compression is actually costing you skill activation.

## Meta-Workflow Templates

See [TEMPLATES.md](TEMPLATES.md) for the full `update-rules.md` and `maintain-docs.md` templates that every project should include. These cover rule sync, after-action review, recording thresholds, rule deprecation, file health checks, and split/merge procedures.

## Task Closure Protocol

A task is NOT complete until these steps are done:

1. Main work done and verified
2. 30-second AAR scan (all "no" = stop here)
3. If any "yes" → apply recording threshold → apply generalization rule → record if it passes

No workflow may skip step 2. See [TEMPLATES.md § Task Closure Protocol](TEMPLATES.md#task-closure-protocol) for the full template.

### AAR Scan Questions

1. Did this task reveal a recurring pitfall?
2. Was the debugging or design cost high?
3. Would a future agent miss this by reading code alone?
4. Did an existing rule turn out to be inaccurate or obsolete?

Skip only for: formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors.

## Recording Threshold

Record only when at least 2 of these 3 are true:

1. **Repeatable** — likely to recur in future work
2. **Costly** — missing it wastes meaningful time or causes real regressions
3. **Not obvious from code** — a future reader would not infer it quickly from implementation alone

Typical high-value records:

- framework lifecycle gotchas
- registration timing pitfalls
- hidden routing dependencies
- non-obvious synchronization or state reset requirements

Skip recording:

- one-off workarounds
- style preferences
- facts already obvious from existing code
- content already well covered by official docs and not project-specific

## Where To Record

Use the lightest useful destination:

- Stable constraint or convention → `rules/`
- Pitfall, lifecycle gotcha, architecture note, source index → `references/`
- Ordered task step or completion check → `workflows/`
- Task routing or always-read set changed → `SKILL.md`
- Tool entry routing changed → thin shells (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`)

Prefer appending to an existing file over creating a new one. Create a new file only when the topic is distinct enough to stay readable on its own.

## Recording Destination Guide

When the user explicitly asks to "record this", "remember this", or "save this for later", the agent must decide where to store the knowledge. Many AI tools (Claude Code, Gemini CLI) have their own memory systems (e.g., `~/.claude/projects/.../memory/`) that auto-load each session. These compete with the skill's documentation structure.

**Decision test:** "Would a different agent or person working on this same project benefit from this knowledge?"

| Answer | Destination | Examples |
|---|---|---|
| **Yes** — project-level knowledge | `skills/<name>/references/`, `rules/`, or `workflows/` | Technical patterns, conventions, pitfalls, architecture notes |
| **No** — personal/user-level knowledge | Agent's own memory system (`~/.claude/.../memory/`, etc.) | Communication preferences, personal shortcuts, user-specific context |

**Default to skill docs.** In practice, most "record this" requests during development are technical and project-scoped. The agent's own memory should only be used for content that is truly personal and would not help another contributor.

Apply the same recording threshold and generalization rule as AAR-initiated recordings — the destination changes, but the quality bar does not.

## Generalization Rule

Records must be reusable knowledge, not project-specific narratives. Before writing, check: would this record make sense in a different project of the same type? If it mentions specific module names or business terms without an abstract explanation, rewrite it.

Pattern: `specific finding → abstract as general pattern → state consequence of not following it`

See [TEMPLATES.md § Generalization Rule](TEMPLATES.md#generalization-rule) for examples of good vs bad records.

## When References Alone Are Not Enough

Recording a pitfall in `references/` preserves it, but does **not** guarantee a future task will read it.

If a lesson is both:

- **costly** enough to repeatedly waste meaningful time, and
- **task-relevant** to a recurring workflow such as fixing bugs, adding pages, adding renderers, or wiring multi-step integrations

then do **not** leave it buried in `references/` only. Also surface it in at least one activation path:

- add or update a completion check in the relevant `workflows/*.md`
- update `SKILL.md` Common Tasks routing so the task points at the pitfall/reference file
- if the lesson is really a stable constraint, promote a concise summary into `rules/`

Rule of thumb:

- `references/` stores the explanation
- `workflows/` prevents omission at task closure
- `SKILL.md` and thin shells make the right file more likely to be read

If a future agent could still miss the lesson while following the normal task path, the knowledge is stored but not yet activated.

## Skill Activation Verification

Phase 8 checks structural correctness, but doesn't verify the skill actually activates at runtime. Use these additional checks after migration.

### Description Quality Check

| Check | Pass criteria |
|---|---|
| Length | ≥ 20 words |
| Trigger phrases | At least 2 quoted trigger phrases (e.g. "refactor project rules") |
| Format | Third-person: "This skill should be used when…" |
| Specificity | Mentions concrete conditions, not just category labels |

A description that fails these checks may silently never fire — the skill exists but the Agent never picks it up.

### Routing Coverage Check

Verify that `SKILL.md` Common Tasks covers the project's actual task distribution:

1. List the 5–10 most common task types in the project
2. For each, confirm Common Tasks has a matching entry with correct file routing
3. If a common task is missing, add it — uncovered tasks fall through to the generic "Other" route and may miss important rules/references

## Common Rule File Sets by Project Type

### Java / Spring Boot

- `rules/project-rules.md` — package structure, module boundaries, dep strategy
- `rules/coding-standards.md` — naming, DI style (constructor injection), comment rules
- `rules/backend-rules.md` — Controller/Service/Mapper conventions, return structure (`Map<String,Object>` / ResponseEntity), exception handling, session/auth pattern
- `rules/frontend-rules.md` — template engine conventions (Thymeleaf/JSP), static resource rules, JS interaction patterns
- `workflows/add-controller.md` — new Controller + route + template
- `workflows/add-entity-and-mapper.md` — new Entity + Mapper + Service method
- `workflows/fix-bug.md` — debug flow
- `workflows/update-rules.md` — rule sync + after-action review + learn-from-mistakes
- `workflows/maintain-docs.md` — file health check, split, merge
- `references/architecture.md` — package map, tech stack versions
- `references/routes-and-modules.md` — Controller → Service → Mapper routing
- `references/third-party-libs.md` — Maven dependencies, version notes

### General-purpose

- `rules/project-rules.md`, `rules/coding-standards.md`
- `workflows/fix-bug.md`, `workflows/update-rules.md`, `workflows/maintain-docs.md`
- `references/architecture.md`, `references/source-index.md`

### Frontend-heavy

- `rules/frontend-rules.md`, `rules/component-rules.md`
- `workflows/add-page.md`, `workflows/add-component.md`, `workflows/update-rules.md`, `workflows/maintain-docs.md`
- `references/frontend-pitfalls.md`

### Python CLI / Data

- `rules/project-rules.md`, `rules/cli-conventions.md`
- `workflows/add-command.md`, `workflows/release.md`, `workflows/update-rules.md`, `workflows/maintain-docs.md`
- `references/api-index.md`, `references/testing-notes.md`

## Decision Guide

### Classify as Rule when

- Stable and long-lived
- Applies repeatedly across tasks
- Violating it causes errors or inconsistency

### Classify as Workflow when

- Procedural: order matters
- Triggered by a specific task type
- Benefits from a checklist

### Classify as Reference when

- Explanatory, not mandatory
- Useful context that aids understanding
- Helps search/navigation (indexes, maps)

### Edge case: both explanatory and violation-prone

Some content describes a pitfall that is explanatory (describes a gotcha) but violating it causes real errors (e.g., "input validation pitfalls in this project's stack"). Decide by the content's **form**:

- **"You must do X"** (prescriptive) → Rule
- **"Watch out for X"** (descriptive warning) → Reference (`references/gotchas.md`)

Both are valuable. The key difference: rules are constraints agents must follow; references/gotchas are warnings agents should be aware of. If a gotcha is costly enough that it should never be missed, also surface it in the relevant workflow checklist or SKILL.md routing (see Activation over Storage principle).

### Classify as Docs when

- External-facing: prompts, reports
- Topical: not tied to a recurring pattern
- May be replaced or versioned independently

## What to Preserve vs. Remove

**Preserve:**

- Stable architectural boundaries
- Hard technical constraints
- Known framework pitfalls
- Source indexes that reduce search cost
- Task checklists that prevent repeated mistakes

**Remove or shrink:**

- Duplicated rule bodies across multiple entry files
- Editor-specific files as sole source of truth
- Giant files mixing constraints + procedures + background
- README acting as both onboarding guide and full rule manual

## Anti-patterns

| Anti-pattern | Why it hurts | Fix |
|---|---|---|
| **Fat thin shell** — "compatibility shell" grows to 50+ lines with extra notes | Defeats single-source-of-truth; two places to update | Strip back to ≤ 15 lines: reading order + conflict rule only |
| **SKILL.md as second README** — repeats project setup, tech stack, onboarding | Agent reads redundant context; SKILL.md exceeds 100 lines | Keep setup in README; SKILL.md only navigates rules/workflows |
| **Rules ↔ Workflows mixed** — `backend-rules.md` contains step-by-step procedures | Hard to find the checklist when needed; hard to update constraints independently | Constraints → `rules/`, procedures → `workflows/` |
| **Implicit cross-skill dependency** — Skill A silently requires reading Skill B first | Agent misses context if it only reads one skill | Each skill self-contained; shared content → `skills/shared/` |
| **Mega sub-file** — one `backend-rules.md` at 500+ lines | Same problem as the original oversized SKILL.md, one level down | Split by subdomain: `controller-rules.md`, `mapper-rules.md`, etc. |
| **Over-splitting** — 20 tiny files with 10 lines each | Navigation overhead exceeds the benefit | Merge related files; aim for 50–200 lines per file |
| **Record everything** — Agent logs every trivial discovery as a rule | Rules bloat with low-value noise; important rules get buried | Apply recording threshold: repeat + high cost + not obvious from code (2/3) |
| **Missing registration entry** — formal skill at `skills/<name>/` but no `.cursor/skills/<name>/SKILL.md` | Cursor never discovers the skill; all rules/workflows silently ignored | Always create `.cursor/skills/<name>/SKILL.md` pointing to formal skill |
| **Soft-pointer-only shell** — thin shell says "go read SKILL.md" without inline routing table | Instruction lost after context summary truncation in long conversations | Embed task→reads→workflow routing table directly in every entry file |
| **Mechanical splitting** — split solely because line count exceeded threshold | Coherent files broken apart; readers jump between fragments | Line count triggers evaluation, not action; check topic separability first |
| **Process overhead** — full health check run after every tiny edit | Meta-work dominates real work | Only scan modified files; skip review for formatting/comment-only changes |

## Troubleshooting

Common symptoms and their fixes:

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Skill never triggers | Description too vague or too short (< 20 words) | Rewrite with ≥ 2 quoted trigger phrases + concrete activation conditions |
| Agent forgets rules in long conversations | Thin shells lack inline routing tables | Embed routing table in every entry file — natural language instructions get lost in context summarization |
| Agent keeps making the same mistake | Pitfall stored in `references/` but not in the task execution path | Surface the lesson in workflow checklist, SKILL.md routing, or a concise rule |
| AAR never runs | Auto-Triggers require agent to judge "behavior-changing"; agent defaults to skipping | Use Task Closure Protocol: trigger on "any non-trivial task", not "behavior-changing tasks" |
| Records are project-specific and unreadable outside context | No generalization check on recordings | Apply Generalization Rule: rewrite as reusable pattern before recording |
| Rules grow endlessly, quality declines | Recording threshold not enforced | Re-check 2/3 criteria (repeatable + costly + not obvious); run Rule Deprecation |
| Cursor can't see the skill | Missing `.cursor/skills/<name>/SKILL.md` registration entry | Create registration entry with matching description + inline routing |
| Broken links after file changes | Renamed or deleted files without integrity check | Run maintain-docs Step 4 after any rename, merge, split, or deletion |
| Common Tasks routing misses frequent tasks | Routing table doesn't reflect actual task distribution | List top 5–10 real tasks, confirm each has a Common Tasks entry |
| Agent reads too many files per task | Always Read list too large, or Common Tasks missing | Keep Always Read to 2–3 files; ensure every common task has specific file routing |

## File Size Guidelines

See [TEMPLATES.md § maintain-docs.md](TEMPLATES.md#maintain-docsmd-template) for the authoritative table with health ranges, evaluation triggers, and merge signals. Key principle: line counts are **reference values**, not hard limits — always evaluate topic separability before acting.

## Naming Conventions

- **File names**: `kebab-case.md` (e.g. `project-rules.md`, `add-controller.md`, `routes-and-modules.md`)
- **Directories**: lowercase, plural (`rules/`, `workflows/`, `references/`, `docs/`)
- **Skill directory**: `skills/<project-name>/` — use the same kebab-case project identifier
- **Suffixes by type**:
  - Rule files: `*-rules.md` (`frontend-rules.md`, `backend-rules.md`)
  - Workflow files: verb-noun (`add-page.md`, `fix-bug.md`, `release.md`)
  - Reference files: noun-based (`architecture.md`, `source-index.md`, `third-party-libs.md`)

## Optional: CI Validation

For teams that want automated guardrails, add a lightweight CI step to check documentation health. This is **entirely optional** — the self-maintenance workflow already handles this manually.

Example checks (shell script or CI job):

- **Broken internal links** — scan `skills/**/*.md` for Markdown links and verify targets exist
- **Oversized files** — warn if any `rules/*.md` exceeds 200 lines or `references/*.md` exceeds 300 lines
- **Orphan files** — list files under `skills/<name>/` not referenced by `SKILL.md`
- **Empty thin shells** — verify each thin shell file (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*.mdc`) contains at least a `SKILL.md` pointer

Keep CI checks as **warnings**, not hard failures — the line count thresholds are signals for evaluation, not laws.
