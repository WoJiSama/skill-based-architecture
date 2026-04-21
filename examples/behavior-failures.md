# Behavior-Level Failures — ❌ / ✅ Scenarios

These examples are **behavior-layer** before/after pairs: what an Agent actually says or does in the failure mode, and what the correct path looks like after the architecture's protections kick in.

Unlike `migration.md` (directory structure) or `project-types.md` (layout variants), these scenarios show the **rationalizations and drift patterns** that cause skill-based architecture to silently degrade — and the specific mechanism (薄壳 Red Flags / Session Discipline / Rationalizations Table) that catches each one.

Every scenario here was captured from a real pressure-test failure. The "reject" column rebuts the Agent's actual words, not a speculative version.

---

## Scenario 1 — Skipping the AAR on a "small" task

**Context:** User asks for a one-line bug fix. Agent applies the fix, tests pass, Agent wraps up.

### ❌ Agent behavior without Task Closure Protocol

> **Agent:** "Done. Changed one line in `UserService.js:47` to null-check the email field. All tests pass. Anything else?"

What the Agent skipped:
- Did not run the 30-second AAR scan
- Missed that the bug recurred because **the same null-check was missing in three sibling services** — a repeatable pattern worth a rule
- Did not record that null-email edge case surfaces at service boundaries, not just input validation

Cost two weeks later: same bug in `OrderService`, same debug path, same 45-minute round trip.

### ✅ Agent behavior with Task Closure Protocol + Rationalizations Table

> **Agent:** "Fix applied to `UserService.js:47`, tests pass.
>
> Running 30-second AAR:
> - New pattern? Yes — null-email check at service layer (other services likely have the same gap)
> - New pitfall? Yes — input validation at controller doesn't guarantee service-layer safety
> - Missing rule? Yes — no rule currently says "service methods must null-check all optional DTO fields"
> - Outdated rule? No
>
> 2/3 rows passed the recording threshold. Added one bullet to `references/gotchas.md#service-layer-validation` and one line to `rules/backend-rules.md`. Done."

**The mechanism that caught it:** `templates/skill/workflows/update-rules.md § Task Closure Protocol` forces the 4-question scan **before** "complete" is allowed. The Agent's borrowed time (30 seconds) is cheaper than the next duplicate bug.

**Rationalization that would have bypassed it:**

| Excuse | Reject |
|---|---|
| "The task was one line — AAR is overkill" | Small tasks are where lessons hide. 30-second scan < 45-minute re-debug. |

See [templates/skill/workflows/update-rules.md § Rationalizations to Reject](../templates/skill/workflows/update-rules.md) for the full table.

---

## Scenario 2 — Description written as passive summary → skill never activates

**Context:** User has a skill for generating API endpoints. Skill file exists, rules are good, but Agent keeps writing endpoints by hand without reading the skill.

### ❌ Passive-summary description

```yaml
---
name: api-generator
description: Helps with API development and endpoint creation.
---
```

User prompt: *"Add a `/users/:id/orders` endpoint with pagination"*

Agent behavior: Writes the endpoint from scratch. Skipped the skill entirely. Endpoint ships without the project's standard error envelope, without the pagination cursor pattern, without the auth middleware — all defined in the skill the Agent never opened.

**Why:** Claude models are biased toward *undertrigger* (safe activation). A vague summary like "helps with API development" doesn't look like an imperative match for "add a `/users/:id/orders` endpoint" — they feel like different topics even though they aren't.

### ✅ Trigger-condition description

```yaml
---
name: api-generator
description: >
  This skill should be used when the user asks to "add a new API endpoint",
  "write a REST route", "add pagination to a list endpoint", or "add auth
  to an endpoint". Activate when the task involves creating, modifying, or
  reviewing HTTP routes, request/response shapes, pagination, or endpoint-level
  authentication in this project.
---
```

Agent behavior: Skill activates immediately on "Add a `/users/:id/orders` endpoint". Reads rules, matches the "pagination" trigger, follows `workflows/add-endpoint.md`, produces a correctly-structured endpoint that passes review on the first pass.

**The mechanism that caught it:** `SKILL.md § Core Principles #7` requires ≥ 2 quoted trigger phrases + `Activate when...` condition. Project's `smoke-test.sh` check category 4 ("Content quality") flags descriptions that miss these.

**Rationalization that would have left the bad description in place:**

| Excuse | Reject |
|---|---|
| "The description reads naturally — the model will figure out activation" | Model bias is toward undertrigger; "naturally readable" ≠ "reliably activates". The quoted-trigger format is verified to raise activation rate in `test-trigger.sh` runs. |

---

## Scenario 3 — Same-session new task: Agent skips re-routing

**Context:** Long session. First task was "fix a backend bug", Agent read `rules/backend-rules.md` + `workflows/fix-bug.md` and resolved it. User then asks to "add a new dashboard page" — a frontend task with completely different rules.

### ❌ Agent behavior without Session Discipline

> **Agent:** "Sure, I'll add the dashboard page. Starting with the component structure…"

What the Agent skipped:
- Did not re-read `SKILL.md`
- Did not re-match Common Tasks — so it never routed to "Add page"
- Did not read `rules/frontend-rules.md` — missed the atomic design + Recoil atom conventions
- Produced a working but off-convention component that triggered 3 rounds of PR review before merge

Even worse: by this point in the session `/compact` had already fired silently. The Agent's "memory" of backend rules was a residual summary, not the actual rules. And none of that memory applied to frontend work anyway.

### ✅ Agent behavior with Session Discipline enforcement

> **Agent:** "New task detected — re-reading `SKILL.md` and re-matching route before proceeding.
>
> - SKILL.md re-read ✓
> - Task 'add a dashboard page' matches Common Tasks route: 'Add page' → read `rules/frontend-rules.md` + follow `workflows/add-page.md`
> - Reading those now, then starting work."

Then proceeds with the correct rules loaded, ships on first-pass review.

**The mechanism that caught it:** Three-layer redundancy documented in [SKILL.md § Common Pitfalls #8](../SKILL.md):

1. `SKILL.md § Core Principles` — declares re-read as a hard rule
2. `workflows/*.md § Step 0` — every workflow starts with "re-read SKILL.md if session has ≥ 1 prior task"
3. `CLAUDE.md / AGENTS.md` thin shells — include `**New task in same session** → re-read` auto-trigger

Each layer can be silenced by compression; the next layer catches it.

**Rationalizations that would have bypassed it:**

| Excuse | Reject |
|---|---|
| "I already read SKILL.md earlier in this session" | Context may have compressed. The new task may match a different route. Partial memory is worse than no memory. |
| "I remember the rules well enough" | Re-read costs 10 seconds; remembering wrong costs hours. |
| "The two tasks are related — backend rules partly apply" | They don't. Different layer, different conventions, different file paths. Routes are not aesthetically joinable. |

See [templates/skill/workflows/update-rules.md § Rationalizations to Reject](../templates/skill/workflows/update-rules.md) for the full table (rows 7 and 8 cover this exact failure mode).

---

## How to add new scenarios here

This file grows only via **real pressure-test failures** — same rule as the Rationalizations Table:

1. Catch an Agent behaving badly in a real session
2. Capture the exact rationalization or drift pattern verbatim
3. Write the ❌ (Agent's actual words / actions)
4. Write the ✅ (what happens once the specific mechanism activates)
5. Name the mechanism and link to its authoritative definition in this repo

**Do not add speculative scenarios.** Invented failures dilute the value of real ones.
