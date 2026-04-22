# Multi-Skill Routing

When a repo owns **multiple skills** in `skills/` (not just one), the routing, triggering, and resource-sharing conventions need more nuance than the single-skill case. This file covers those.

## When you need multiple skills

A single project skill is enough when the whole project shares one set of rules and one routing table. Split into multiple skills when **any** of these is true:

- Two subsystems have **non-overlapping trigger phrases** (a user asking about "billing" and "onboarding" should land on different Common Tasks)
- Two subsystems have **contradicting rules** (frontend rules say "prefer Web Components", backend rules say irrelevant) — forcing them into one skill loads conflicting constraints on every task
- One subsystem is a **standalone reusable library** that could be extracted later — giving it its own skill is a low-cost pre-split

One skill with multiple domains (`rules/frontend-rules.md` + `rules/backend-rules.md`) is NOT multi-skill — it's one skill covering several domains. Multi-skill means separate `skills/<name>/` directories each with their own SKILL.md + rules + workflows.

## The `primary: true` default

With multiple skills, one should be marked `primary: true` in its frontmatter:

```yaml
---
name: web-app
description: ...
primary: true
---
```

**Rule:** the primary skill is the default read when a task doesn't clearly match another skill's description. Only one skill per repo gets `primary: true`.

If no skill has `primary: true`, the Agent has to match description-by-description on every task — slower, error-prone.

## Description discipline — no overlapping trigger phrases

With multiple skills, trigger phrases are the disambiguator. Two skills with overlapping triggers guarantee mis-routing.

**Bad** (both fire on "add page"):
```yaml
# skills/frontend/SKILL.md
description: Use when the user asks to "add a page", "fix styling", ...

# skills/cms/SKILL.md
description: Use when the user asks to "add a page", "edit content", ...
```

**Good** (trigger phrases disjoint):
```yaml
# skills/frontend/SKILL.md
description: Use when the user asks to "add a UI page", "style a component", "fix a rendering bug", ...

# skills/cms/SKILL.md
description: Use when the user asks to "add a content page", "edit article", "publish draft", ...
```

**Check:** grep each skill's trigger phrases. If two skills share a phrase verbatim, rewrite one.

## Shared resources — where they live in a multi-skill repo

Some resources apply across all skills in the repo:

| Resource | Layout in multi-skill repo |
|---|---|
| Root shells (`AGENTS.md`, `CLAUDE.md`, etc.) | ONE set at repo root. Each shell's Always Read preamble lists the Always Read of the primary skill. Each shell's routing table has rows from ALL skills, prefixed or grouped. |
| Protocol-blocks | `protocol-blocks/` at **repo root** (not inside any one skill). Each skill's workflows link to them with relative paths like `../../protocol-blocks/reboot-check.md`. |
| Hooks (`.claude/hooks/`) | ONE set at repo root. A hook that gates one skill's file uses env vars or path checks to scope its effect. |
| References | Per-skill under each `skills/<name>/references/`. Only move to repo root if a reference legitimately applies to all skills (rare). |
| `WORKFLOW.md` / migration scripts | Single copy at repo root. Migration is repo-level. |

## Cross-skill references

A workflow in `skills/frontend/workflows/add-page.md` can reference `skills/backend/rules/api-rules.md` when a page consumes an API. The mechanism is just a relative path:

```markdown
Before wiring the API call, read `../../backend/rules/api-rules.md` for the contract conventions.
```

Do NOT duplicate the content into `skills/frontend/rules/`. The cross-reference preserves one source of truth.

**Rule:** if skill A's workflows reference skill B's rules more than twice, evaluate whether those rules belong at repo root in a shared `rules/` directory, or whether the two skills should actually merge.

## Routing under ambiguity — which skill owns this task?

When a user request could match multiple skills, the resolution order:

1. **Explicit user cue** — "in the frontend, ...", "for the billing service, ..." — the Agent picks the named skill unconditionally.
2. **Trigger phrase exact match** — user's verb-noun matches one skill's description word-for-word; pick that skill.
3. **Primary skill fallback** — no cue, no unambiguous match → pick the `primary: true` skill.
4. **Ask the user** — two skills match equally; pick neither, ask "is this a frontend task or a backend task?"

Never "try both" — reading two full SKILL.md's on every ambiguous task is token waste and confuses routing.

## Task Closure across skills

When a task's workflow lives in skill A but touches files owned by skill B (e.g., `skills/frontend/workflows/add-page.md` modifies a backend endpoint), the AAR at the end has **two** rule-update targets:

- Learnings about the frontend workflow → `skills/frontend/references/gotchas.md`
- Learnings about the API contract or backend constraint → `skills/backend/references/gotchas.md`

Record in both, not just in the originating skill. The Task Closure Protocol is owner-agnostic; it serves whichever skill's knowledge the learning belongs to.

## Fission signals — when to split a single skill into multiple

Signs that a single skill is ready to split:

- `SKILL.md` > 100 lines and can't compress without losing routing detail
- Trigger phrases cluster into two or more disjoint groups (no user ever asks a task that crosses groups)
- `rules/` has 6+ files and 3+ of them are never read together on the same task
- One subsystem's AAR entries don't teach anything useful to the other subsystem

Fission procedure: see [`references/layout.md § Multi-Skill Projects`](layout.md#multi-skill-projects) for the split mechanics. This file (`multi-skill-routing.md`) covers how to operate *after* the split.

## Anti-patterns

- **Creating multiple skills for a single-domain project just because it feels modular.** If the skills always read each other's files on every task, the split is fake. Merge.
- **Listing every skill's rules in every shell's Always Read preamble.** Pollutes every session with everyone else's rules. Only the primary skill's Always Read goes in the shell preamble; other skills are routed to explicitly.
- **Identical description text across skills.** The Agent can't distinguish. Every skill's description must be uniquely identifying.
- **`primary: true` on multiple skills.** The `primary` is an exclusive designation; more than one is a config bug.

## Example layout (3-skill repo)

```
repo-root/
├── AGENTS.md              ← single thin shell, routes to all 3 skills
├── CLAUDE.md
├── CODEX.md
├── GEMINI.md
├── .cursor/rules/workflow.mdc
├── .cursor/skills/         ← registration entries for each
│   ├── web-app/SKILL.md
│   ├── billing/SKILL.md
│   └── admin-cli/SKILL.md
├── protocol-blocks/        ← shared across all 3 skills
│   ├── reboot-check.md
│   └── subagent-contract.md
├── .claude/
│   ├── settings.json       ← one hook config for the repo
│   └── hooks/*
└── skills/
    ├── web-app/            ← primary: true
    │   ├── SKILL.md
    │   ├── rules/
    │   ├── workflows/
    │   └── references/
    ├── billing/
    │   └── ...
    └── admin-cli/
        └── ...
```

The `AGENTS.md` routing table shows rows for all three skills, each prefixed by the skill name so the Agent knows which `skills/<name>/` to Read for that task.
