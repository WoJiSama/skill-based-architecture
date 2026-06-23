# Agent Behavior — Meta (origin, admission, activation audit)

Read this when **editing** `rules/agent-behavior.md` (e.g. on the `update-rules` route) — not on every task. It holds the documentation-about-the-rule that has no per-task runtime value, kept out of the Always-Read floor so every downstream session pays less.

## Origin

Principles 1–4 condensed from [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (Andrej Karpathy's observations on LLM coding pitfalls, 2025); principle 5 from [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files); principle 6 from this project's response-discipline rule.

## Admission Threshold for New Principles

Before adding a new principle to `rules/agent-behavior.md`, read the admission threshold in `templates/ANTI-TEMPLATES.md § Admission Threshold for Behavioral Principles`. The file is capped at 100 lines; growth requires evidence of a real miss (an AAR row or a `behavior-failures.md` entry) or an equal-weight replacement — not borrowing from an admired project.

## Observable Signals — Is This Working?

These defaults are being activated (not just stored) if diffs and sessions show:

- **Fewer drive-by changes** — every changed line traces to the request; no style churn, renaming, or dead-code deletion that wasn't asked for.
- **Clarifying questions come before code, not after mistakes** — ambiguity is surfaced at the start of a turn, not during cleanup two iterations in.
- **Shorter first drafts** — simple implementations that grow only when real pressure forces them; no speculative flags, strategy classes, or config for one-use code.
- **Concrete verification per step** — every claimed "done" cites a test, grep result, or manual repro; no "looks right" or "should work."

If none of these signals appear across several sessions, the defaults are stored but not activated. Log the incident in [`behavior-failures.md`](behavior-failures.md) rather than re-reading the rule again — storage without activation is itself a tracked failure mode, not a reminder problem.
