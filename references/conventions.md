# Reference — Conventions & Troubleshooting

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

See [TEMPLATES-GUIDE.md § maintain-docs.md](TEMPLATES-GUIDE.md#maintain-docsmd-template) for the authoritative table with health ranges, evaluation triggers, and merge signals. Key principle: line counts are **reference values**, not hard limits — always evaluate topic separability before acting.

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
