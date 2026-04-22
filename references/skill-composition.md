# Skill Composition

How a project skill produced by this architecture can invoke, chain, or delegate to **other skills** — turning the project's `skills/<name>/` into an orchestration layer rather than a dead-end.

## Why compose

A project skill captures *this project's* rules and routing. General-purpose capabilities — planning, security review, writing tests, research — are better built once in a reusable skill (e.g. [`obra/superpowers`](https://github.com/obra/superpowers)) and **called from the project skill** where the task arises. The project skill stays focused on project-specific knowledge; reusable mechanics live elsewhere.

## Three composition patterns

### Pattern A — Embedded invocation (most common)

A workflow in your project skill explicitly reads and follows another skill mid-procedure.

**When to use:** the other skill provides a well-defined sub-procedure (e.g., "write a plan", "run a security review") that slots cleanly into one step of your workflow.

**How to write it** (inside e.g. `workflows/plan.md`):

```markdown
## Step 2 — Build the plan

1. Read `skills/superpowers/SKILL.md` to load its Common Tasks.
2. Match the current task against its "Plan a feature" route.
3. Follow `skills/superpowers/workflows/plan-a-feature.md` end-to-end; produce the plan artifact it prescribes.
4. Return to this workflow (Step 3) with the plan in hand.
```

**Key property:** control stays in *your* workflow. The invoked skill is a subroutine you return from, not an owner of the task.

See the copy-paste starter in [`templates/skill/workflows/invoke-skill.md.example`](../templates/skill/workflows/invoke-skill.md.example).

### Pattern B — Serial chain (route handoff)

Your project skill's `SKILL.md` Common Tasks routes certain task types *directly* to another skill's workflow — no intermediate workflow in your project.

**When to use:** the other skill already does the whole task correctly; your project skill doesn't add project-specific steps.

**How to write it** (in `SKILL.md` Common Tasks):

```markdown
- Security-review code → follow `skills/security-review/workflows/review.md` directly (no project-specific wrapper needed)
```

**Key property:** routing delegates the full task. Your skill stays lean; you haven't written a wrapper workflow just to forward.

### Pattern C — Subagent delegation (for isolation)

You dispatch a subagent whose whole job is to run the other skill, then return a structured result.

**When to use:** the other skill runs long, is noisy, or would pollute your context (e.g., scraping documentation, doing web research, running many tool calls). Isolate it.

**How to write it** (inside a workflow step):

```markdown
## Step 3 — Research the library

Dispatch a subagent with contract:
  Goal: answer X using skills/web-research
  Inputs: the target library name
  Outputs: a 10-line summary returned to this workflow
  Forbidden: writing any files in the main repo
  Acceptance: summary contains version, license, maintenance status

(See `protocol-blocks/subagent-contract.md` for the 5-field form.)
```

**Key property:** the subagent's context is throwaway. Only the structured result comes back.

## Choosing the pattern

| Situation | Pattern |
|---|---|
| One step of your workflow is exactly what another skill does | A (embedded) |
| A whole task category is better owned by another skill | B (serial chain) |
| The other skill's execution would bloat or destabilize your context | C (subagent delegation) |

## Anti-patterns (avoid)

- **Silent transitive dependencies.** If `workflows/plan.md` invokes `skills/superpowers/`, but `skills/superpowers/` is not guaranteed to be present in the downstream project, your workflow will fail silently. Either vendor the dependency (check it into `skills/`) or add an escape condition: "if `skills/superpowers/SKILL.md` is missing, stop and ask user to install it."

- **Recursive composition without a base case.** A invokes B invokes A. Agent loops until context exhausts. Always require one side to be leaf-only (no back-invocation to the caller).

- **Hidden ownership.** A workflow says "handle it with security-review skill" without naming it. The Agent guesses, picks whichever security skill is present, and you lose reproducibility. Always name the skill by its directory path.

- **Composition as a shortcut for missing project content.** If you keep invoking `skills/superpowers/plan` because you haven't written your own `workflows/plan.md`, that's OK for a while — but eventually *some* project-specific planning rules accumulate. Record them in your own workflow and call superpowers for the generic scaffolding only.

- **Passing through without Task Closure.** If your workflow invokes another skill and then ends, you skipped your project's AAR. Composition does not exempt the caller from Task Closure Protocol (see `templates/protocol-blocks/iron-law-header.md`).

## What "invoking" means in practice (per harness)

Agents don't have a formal `invoke(skill)` primitive. "Invoke" translates to:

- **Claude Code / Cursor / most harnesses:** the Agent reads `skills/<other>/SKILL.md` and follows its routing. The actual mechanism is Read + procedural following. A workflow that says "invoke skill X" means "Read that file, then execute what it says."
- **Harnesses with `/skill-name` slash commands (Claude Code plugins):** you can prompt the Agent to `/plan` (if `skills/superpowers/plan` is registered as a slash command). This is syntactic sugar for the same Read-and-follow.
- **Agent SDK subagent dispatch:** pass the other skill's SKILL.md contents in the subagent's initial prompt plus the task. Subagent boots with that context; see Pattern C.

The composition patterns above work on all three; only the literal command shape differs.

## Before you compose — verify the other skill exists and fits

A composition invocation that names a missing skill is a routing bug that surfaces only at runtime.

1. `ls skills/<other>/SKILL.md` — confirms presence
2. Read its `description` — confirms your invocation fits its trigger conditions
3. Run its smoke-test if present — confirms it's healthy

If any check fails, fix it before shipping the composition, or downgrade to "ask user to install" with a concrete install command.
