# Behavior Failures

Real incidents where an Agent violated one of the behavior defaults in [`rules/agent-behavior.md`](../rules/agent-behavior.md) — Think Before Coding, Semantic Completeness Before Minimality, Surgical Changes, Goal-Driven Execution, Three-Strike Stop Condition, Response Discipline, or Delegate Only for Net Benefit. Complements `gotchas.md` (which records *technical* traps); this file records *agent-behavior* traps.

<!--
Format per entry:

## **[principle]** <short title>

**What was asked:** the user's original request (1 line)
**What happened:** silent assumption / overcomplication / drive-by edit / fuzzy success criteria — name the failure mode
**Cost:** time wasted, rework, trust damage (concrete, not "some")
**Prevent:** concrete hook added to SKILL.md / workflow / rule / red-flag list (not "be more careful" — that never works)

Recording Threshold: at least one of {repeatable pattern, multi-hour cost, not obvious from the rule text}.
Generalization rule: replace the project name — still makes sense? If no, rewrite as a pattern.
-->

<!-- OPTIONAL: this file starts empty. Entries grow via After-Action Review. Do NOT pre-populate with Python examples or generic "don't assume null" defaults — those are noise. Only record failures actually paid for in this project. -->

## **[Delegate Only for Net Benefit]** Spawn-then-wait cascade

**What was asked:** update reusable rules across an upstream template, downstream forks, and assembled copies.
**What happened:** an Iron Law mapped every mechanical or time-consuming sub-step to mandatory worker dispatch. Ordinary searches, checks, and narrow edits spawned workers even when the main agent had no independent work, followed by repeated blocking waits and coordination errors.
**Cost:** worker management displaced the actual critical path, several waits produced no useful evidence, and the user had to interrupt the run to correct the behavior.
**Prevent:** Always Read now makes inline the default; `subagent-driven.md` requires positive Net Benefit plus real overlap, caps workers by independent workstreams, and forbids spawn-then-wait and repeated polling. Conformance protects the load-bearing phrases.
