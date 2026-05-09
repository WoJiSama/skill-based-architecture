# Reference — Progressive Rigor

Not every skill needs the full `skills/<name>/` tree. Start at the smallest tier that fits, and upgrade only when a concrete pressure fires. Default to the cheapest structure that works — over-structuring a small skill adds maintenance cost with no compression-survival benefit.

## The three tiers

| Tier | Layout | Use when | Typical SKILL.md size |
|---|---|---|---|
| **Single-file** | `SKILL.md` only (official minimum) | < 3 topics, no task routing needed, no lesson-capture history | ≤ 60 lines |
| **Folder-light** | `skills/<name>/SKILL.md` + `rules/` | 3–5 topics, OR 1 recurring workflow that needs step-by-step instructions, OR a growing list of project conventions | 60–100 lines, `rules/` adds 1–3 files |
| **Full** | `skills/<name>/{SKILL,rules,workflows,references}/` + thin shells + Cursor registration entry | ≥ 3 routed task types, gotcha log needs a home, multi-harness repo (Cursor + Claude + Codex + Gemini), or lessons-learned across multiple sessions | Close to 100 lines, multiple files per subdir |

## Upgrade triggers

Add structure when **any** of these fires, not before:

1. **Line pressure** — `SKILL.md` crosses 100 lines despite compression attempts. Move content to a sub-file in the next tier down (e.g. workflows go to `workflows/` once you have 2+).
2. **Recurrence pressure** — the same pitfall is recorded in Common Pitfalls twice, or the same question gets asked by the agent twice in different sessions. Promote it to `references/gotchas.md` with a dedicated section.
3. **Procedure pressure** — you catch yourself writing "how to do X in steps" inside a rule file. Steps belong in `workflows/`, not `rules/`. Create the `workflows/` directory.
4. **Harness-sharing pressure** — two harness entries (e.g. `AGENTS.md` and `CLAUDE.md`) need the same route lookup logic, or you're manually keeping them in sync. Move task data into `routing.yaml` and generate thin-shell blocks.
5. **Cross-session lesson pressure** — you want a lesson from today to persist into a `/clear`-fresh session next week. A single-file skill with no `references/` has no durable place for it.

**Downgrade is also fine.** If a skill lost a domain or shed complexity, collapse back. Structure serves the content, not the other way around. Empty `workflows/` or `references/` directories are a smell.

## Why this matters

Over-structuring a small skill:

- Adds 5–10 files the user must open and keep up to date
- Pushes simple "always do X" rules into `rules/` folders, then forces thin shells to point at them
- Creates false invariants (thin shells claim the skill routes tasks, when the skill has one task)

Under-structuring a growing skill:

- Grows SKILL.md past 100 lines, defeating Principle 1
- Mixes rules and workflows in one file, defeating Principle 3
- Loses routing discipline, forcing the agent to read the whole file for every task

The tier table above is the concrete decision gate. Re-evaluate on each significant skill revision, not on every edit.

## Three-axis profile

Skill shape is not one flat choice. Profile it on three independent axes:

| Axis | Values | Question |
|---|---|---|
| Structure tier | Single-file / Folder-light / Full | How much routing and durable documentation does the project need? |
| Execution mode | Rule-only / Assisted-executable / Executable | Does the skill merely guide work, or does it own scripts, external calls, and output contracts? |
| Domain topology | Single-skill / Multi-skill candidate | Do trigger language and rules form one domain or several separable domains? |

A project can be `Full + Rule-only + Single-skill`, or `Folder-light + Executable + Single-skill`. Keep the axes separate so one pressure does not force unrelated structure.

For execution-mode pressure, see [executable-skill-architecture.md](executable-skill-architecture.md). For multi-skill topology, see [multi-skill-routing.md](multi-skill-routing.md).

## Simple Route vs Advanced Route

Most routes need only `id`, `labels`, `route`, `required_reads`, `workflow`, and `trigger_examples`. Keep them simple.

Use optional advanced fields only for high-risk routing where a wrong match has a real cost:

| Field | Use for |
|---|---|
| `positive_signals` | High-signal phrases or structural evidence that should enter this route |
| `negative_signals` | Nearby phrases that should route elsewhere or be refused |
| `confidence` | HIGH/MEDIUM/LOW decision rules and when to clarify |
| `slots` | Required inputs and where to derive or ask for them |
| `target` | The exact capability, workflow, or external skill handoff |

Typical advanced-route cases: deploys, database/schema changes, remote config writes, status transitions, external skill delegation, expensive API calls. These fields are documentation and generation input; `sync-routing.sh` must stay compatible with routes that do not define them.
