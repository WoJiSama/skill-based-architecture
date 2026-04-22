# Deep Dive — Two Core Pillars

This document goes one layer below the [README](README.md) into the two mechanisms that make skill-based-architecture more than "a tidier docs folder":

1. **The Hook System** — mechanism-level guards that run deterministically, not just convention-level rules the Agent may or may not follow.
2. **The Framework for Composition & Multi-Skill** — the produced `skills/<name>/` is extensible by design: workflows can invoke other skills, one repo can own several skills, protocol-blocks plug in as reusable parts.

If the README tells you *what this is*, this doc tells you *how the two most consequential parts actually work* — including what they cover, what they don't, and when to install each.

---

## Pillar 1 — The Hook System

### What hooks are

A **hook** is a script Claude Code (or Cursor, or other compatible harness) runs at a defined lifecycle point. The script reads a JSON payload on stdin, does whatever it wants, and signals back via stdout JSON + exit code.

Think of hooks as **git pre-commit hooks for an AI agent**: the agent is about to do X; the hook decides whether X proceeds, what context is injected, or what the result should be. Hooks turn convention ("don't do X") into mechanism ("physically can't do X").

### What we use

This repo registers two hook types via `.claude/settings.json`:

| Hook | Fires on | Script | Purpose |
|---|---|---|---|
| **SessionStart** | session launch / `/clear` / `/compact` | `templates/hooks/session-start` | Re-inject `SKILL.md` into the agent's context, so routing and Task Closure Protocol survive context summarization |
| **PreToolUse** | every `Write` / `Edit` tool call | `templates/hooks/agent-behavior-gate.sh` | Gate edits to `rules/agent-behavior.md` — enforce the [Admission Threshold](templates/ANTI-TEMPLATES.md) deterministically instead of hoping the agent reads and respects it |

We intentionally don't register PostToolUse — nothing this architecture does needs post-tool cleanup, and every extra hook widens the trust surface.

### How SessionStart works (context survival)

Long sessions get summarized by the harness. `/clear` and `/compact` drop most of the context window. Without an anchor, the skill's routing table (`SKILL.md`) can silently disappear, and the agent starts answering tasks without the rules.

The SessionStart hook reads `SKILL.md` and emits it back into the agent's context as `additionalContext`:

```
event: SessionStart (startup | clear | compact)
  ↓
hook: cat skills/<name>/SKILL.md
  ↓
stdout: {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<SKILL.md body>"}}
  ↓
agent: receives SKILL.md fresh, routing table intact, continues
```

Minor cost (one file read per session lifecycle event); large durability win on sessions that last hours.

### How PreToolUse / agent-behavior-gate works (admission enforcement)

The [Admission Threshold](templates/ANTI-TEMPLATES.md) says `rules/agent-behavior.md` growth requires evidence. As convention, the gate blocked ~30% of hostile prompts on Sonnet and ~11% on Haiku (measured; see [hooks/README.md](templates/hooks/README.md) for the full matrix). That's better than zero but far from enforcement.

The PreToolUse hook makes it deterministic:

```
agent decides to call: Edit(rules/agent-behavior.md, old_string="...", new_string="...")
  ↓
harness invokes hook BEFORE the edit: bash agent-behavior-gate.sh <<< <tool-input-json>
  ↓
hook computes: line_delta, char_delta, current file line count, evidence file contents
  ↓
hook decides:
  - shrinking edit (line_delta < 0)       → exit 0, allow
  - typo fix (Δlines=0, Δchars ≤ 20)      → exit 0, allow
  - growing + cap exceeded                → exit 2, BLOCK with reasons on stderr
  - growing + no AAR evidence             → exit 2, BLOCK with reasons on stderr
  - otherwise                             → exit 0, allow
  ↓
harness: if exit 2, aborts the edit with the stderr message as the error
```

False-positive mitigations built in:

- **Shrinking always allowed** — refactoring the file back to cap never needs evidence
- **Typo tolerance** — same-line edits with ≤ 20 char change (`TYPO_TOLERANCE` env-var tunable) pass
- **Override env var** — `AGENT_BEHAVIOR_GATE_OVERRIDE=1` for legitimate maintenance, logged to stderr for audit
- **Warn mode** — `AGENT_BEHAVIOR_GATE_WARN=1` prints reasons but allows; useful during rollout on over-cap files

### Critical limitations — where hooks don't fire

Tested empirically April 2026:

| Runtime | SessionStart | PreToolUse | Notes |
|---|---|---|---|
| Interactive Claude Code CLI (`claude`) | ✅ | ✅ **blocks on exit 2** | Primary target environment |
| `claude --print` subprocess | ✅ fires | ❌ **deny ignored** | `--print` auto-approves permissions for pipeline use |
| Claude Agent SDK / Task tool subagents (incl. `isolation: worktree`) | ❌ **hook not invoked** | ❌ | Subagent dispatched edits bypass the hook |
| Cursor | ⚠️ likely yes (untested) | ⚠️ unknown | Hook contract may differ from Claude Code |

**What this means:**

- Hooks protect **interactive user-driven editing** via Claude Code CLI.
- Hooks do **not** protect automated pipelines (`--print`) or multi-agent dispatches (Task/Agent tool).
- For those surfaces, install git-level guards (CODEOWNERS + CI that re-checks the admission rules on every PR). The hook is one layer of defense; git protection is a second.

### Schema pitfall

Claude Code CLI v2.1+ requires the **nested** hooks format:

```json
// ✅ CORRECT — nested
"PreToolUse": [
  {
    "matcher": "Write|Edit",
    "hooks": [{ "type": "command", "command": "bash templates/hooks/agent-behavior-gate.sh" }]
  }
]

// ❌ BROKEN — flat (SessionStart happens to still work this way; PreToolUse silently doesn't)
"PreToolUse": [
  { "matcher": "Write|Edit", "command": "bash templates/hooks/agent-behavior-gate.sh", "async": false }
]
```

A flat-format hook will **appear to be registered** (no error on session start) but **never fire**. Verify via `claude --print --verbose --output-format=stream-json --include-hook-events`: `hook_started` events with your hook name confirm registration.

### When to install

| Scenario | Install hooks? |
|---|---|
| Solo maintainer, Sonnet/Opus, reviews every diff | Optional — convention gate covers the cases the maintainer already catches by eye |
| Team repo, multiple committers | Yes — convention alone fails 70% of hostile framings on Sonnet |
| Any repo where Haiku-class models do edits | Yes — convention fails 89% on Haiku |
| Automated CI/pipeline projects | Install hooks **AND** CI-level guards — hooks don't cover `--print` |

Install steps: `templates/hooks/README.md` § "Install — Claude Code" / "Install — Cursor".

---

## Pillar 2 — The Framework for Composition & Multi-Skill

### The core insight

The `skills/<name>/` directory this meta-skill produces is **not a flat docs folder**. It is a framework with explicit extension points. The produced skill is meant to grow with the project — adding workflows, invoking other skills, splitting into multiple skills as domains diverge.

If you think of the produced skill as "a doc I write once and forget", you'll underuse 80% of it. Think of it as "a project-scoped skill operating system" — an orchestration layer your agents keep accumulating knowledge into.

### Extension points

| Extension point | What goes there |
|---|---|
| `workflows/*.md` | Your project's recurring task procedures. Add as many as needed. |
| `rules/*.md` | Stable project-specific constraints. One file per concern. |
| `references/*.md` | Background knowledge, pitfall catalogs, domain notes. |
| `protocol-blocks/*.md` (shared at repo root when multi-skill) | Reusable drop-in blocks (rationalizations-table, red-flags-stop, reboot-check, ambiguous-request-gate, subagent-contract). Pull into any workflow. |
| Hooks (SessionStart, PreToolUse) | Runtime integration with the harness. |
| Cross-skill invocation | Workflows can Read and follow other skills mid-procedure. |

### Composition patterns (3 ways to invoke another skill)

Full detail in [references/skill-composition.md](references/skill-composition.md). Summary:

| Pattern | Shape | When to use |
|---|---|---|
| **A — Embedded invocation** | Your `workflows/plan.md` includes a step: "Read `skills/superpowers/SKILL.md`, follow its plan-a-feature workflow, come back" | One step of your workflow is exactly what another skill does |
| **B — Serial chain** | Your `SKILL.md` Common Tasks row points directly to another skill's workflow file (no wrapper in your skill) | A whole task category is better owned by another skill |
| **C — Subagent delegation** | Dispatch a subagent with a subagent contract (Goal/Inputs/Outputs/Forbidden/Acceptance) naming the other skill to run | The other skill's execution would pollute or destabilize your main context |

Copy-paste starter: [templates/skill/workflows/invoke-skill.md.example](templates/skill/workflows/invoke-skill.md.example) — demonstrates Pattern A with `obra/superpowers` as the invoked skill.

### Multi-skill repos — when one skill isn't enough

Full operating guide: [references/multi-skill-routing.md](references/multi-skill-routing.md). Key rules:

- **One skill per disjoint task domain.** If users of subsystem A and subsystem B never ask the same kinds of questions, they deserve separate skills.
- **Exactly one `primary: true`.** The default skill when nothing else matches. Multiple primaries is a config bug.
- **Trigger phrases must not overlap.** Two skills listening for "add a page" is routing gridlock — the agent can't disambiguate. Make each skill's triggers disjoint.
- **Shared resources live at repo root.** `protocol-blocks/`, `hooks/`, `WORKFLOW.md`, migration scripts — one copy per repo, referenced from each skill.
- **Cross-skill references use relative paths.** If a frontend workflow needs a backend rule, it reads `../../backend/rules/api-rules.md` — don't duplicate.

Fission signals (when a single skill should split): SKILL.md > 100 lines and can't compress; trigger phrases cluster into disjoint groups; rules/ has 6+ files and most never read together. See [references/layout.md § Multi-Skill Projects](references/layout.md#multi-skill-projects) for the layout mechanics of splitting.

### When to activate each capability

| Your project's state | What to use |
|---|---|
| Single-skill repo, everything routed through one `SKILL.md` | Just the basics — SessionStart hook + Always Read list is enough |
| Your workflows keep reinventing planning / research / review | Adopt **composition** (Pattern A or B) — invoke `obra/superpowers` or similar |
| Team routinely edits `agent-behavior.md`, principle creep starts | Install the **PreToolUse gate hook** |
| Repo now has two non-overlapping task domains | **Split into multiple skills**, use `primary: true` |
| Long sessions, agent keeps losing routing after `/clear` | Ensure **SessionStart hook** is installed |

---

## How the two pillars interlock

The hook system protects the **integrity** of the skill — it keeps rules from creeping, keeps SKILL.md in context across `/clear`. The framework-for-composition enables **growth** of the skill — new workflows, new invoked skills, new sub-skills, new protocol-blocks.

Together they give you a skill that can grow safely:

- Growth without integrity: `agent-behavior.md` balloons from accumulated "just this once" additions; SKILL.md grows past 100 lines and stops being readable; principles contradict. Predictable decay.
- Integrity without growth: rules stay clean, but the skill never learns new tricks. Every planning task re-invents planning; every review re-writes the review checklist.
- **Both** together: the skill picks up reusable mechanics via composition (planning from superpowers, testing from a test-discipline skill, etc.) while the hook + Admission Threshold prevents the accumulated wisdom from turning into bloat.

---

## Further reading

**Hooks:**
- [`templates/hooks/README.md`](templates/hooks/README.md) — install / rollout / tuning / full effectiveness matrix
- [`templates/hooks/SECURITY.md`](templates/hooks/SECURITY.md) — trust boundary for hook-injected files
- [`templates/ANTI-TEMPLATES.md § Admission Threshold`](templates/ANTI-TEMPLATES.md) — the rules the PreToolUse gate enforces

**Composition & Multi-Skill:**
- [`references/skill-composition.md`](references/skill-composition.md) — 3 composition patterns + anti-patterns
- [`templates/skill/workflows/invoke-skill.md.example`](templates/skill/workflows/invoke-skill.md.example) — copy-paste starter
- [`references/multi-skill-routing.md`](references/multi-skill-routing.md) — operating guide for 2+ skills
- [`references/layout.md § Multi-Skill Projects`](references/layout.md) — layout mechanics / fission procedure

**Protocol blocks (building materials for both pillars):**
- [`templates/protocol-blocks/`](templates/protocol-blocks/) — `rationalizations-table.md`, `red-flags-stop.md`, `reboot-check.md`, `subagent-contract.md`, `ambiguous-request-gate.md`, `iron-law-header.md`
