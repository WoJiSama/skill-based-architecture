# Ambiguous Request Gate

Drop this block into any shell, workflow, or SKILL.md where the agent needs a pre-routing check on request clarity. Complements `protocol-blocks/red-flags-stop.md` (discipline erosion) and `protocol-blocks/reboot-check.md` (mid-task disorientation); this one catches the ambiguity **at the start** before any work begins.

## Trigger

A request is **ambiguous** and must not be routed when it satisfies BOTH:

1. **Vague improvement verb** is present: `refactor / clean up / optimize / make it better / streamline / modernize / restructure / 整理 / 重构 / 优化 / 让它更好 / 让 X 更清晰 / 清理一下`
2. **Scope is underspecified** — at least one missing: concrete module/file/page, specific behavior change, verifiable outcome ("faster than X ms", "no more of error Y", "passes test Z").

If only one condition holds (e.g. "refactor the `auth` module for readability" — vague verb but concrete scope), route normally.

## Action

**Stop.** Apply `rules/agent-behavior.md` Principle 1 (Think Before Coding):

1. Name which part is ambiguous (verb only, scope only, both)
2. Ask the user: which module/file/page? what does "better" mean (faster, more readable, fewer bugs, something else)?
3. Wait for an answer. If the user answers with another ambiguous phrase, repeat — do not start planning.
4. Only after scope is concrete, route via the task table.

## Anti-patterns (all forbidden pre-clarification)

- **"Let me scan the project first, then ask"** — the scan itself is unrequested work and primes a biased answer
- **"Here are 3 possible directions, pick one"** — still offers plans; just ask what the user meant
- **"Let me give a rough plan so you can steer"** — starts speculative work in violation of Principle 2 (Simplicity First)
- **"This looks big, I'll propose phases"** — authority transfer; you are guessing scope
- **"I'll use the planner agent to generate a detailed plan"** — delegates the gate violation to another agent

## When the gate does NOT fire

- Scope was established in a prior turn of the same session and has not been contradicted
- The task table matches the request by a specific verb+noun ("add page X", "fix bug in Y", "update rule Z")
- The user has answered the clarifying question and scope is now concrete

## Origin

Observed in Haiku 4.5 tests against wj-small-tools (2026-04): Haiku systematically produced partial-plan responses ("here's a 4-phase refactor", "2 options, which one?", "I'll use planner agent") when the original request lacked a concrete target — even with a convention-level routing-table warning against it. Moving the warning OUT of the task table and INTO a pre-routing gate (this block) with explicit anti-patterns reduced but did not eliminate the behavior. The gate is still worth installing: it raises the bar, and for Sonnet-tier models it closes the loophole entirely.
