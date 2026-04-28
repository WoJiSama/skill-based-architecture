# Agent Behavior — Defaults

Universal coding-behavior defaults for any agent working inside this skill. Pre-filled, not `FILL` placeholders: these apply regardless of project. Delete or override a principle only if this project explicitly needs different behavior (write the override in `rules/project-rules.md` with reasoning).

Origin: principles 1–4 condensed from [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (Andrej Karpathy's observations on LLM coding pitfalls, 2025); principle 5 from [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files); principle 6 from this project's response-discipline rule.

**Before adding new principles, read the admission threshold in `templates/ANTI-TEMPLATES.md § Admission Threshold for Behavioral Principles`.** This file is capped at 100 lines; growth requires evidence of a real miss or an equal-weight replacement, not borrowing from an admired project.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State assumptions explicitly. If uncertain, ask — don't guess.
- If multiple interpretations exist, present them; don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask, and consult code owners when uncertain.

✓ Check: can you name the assumption(s) you made and the alternatives you rejected? If "no" or "I didn't think about it" — stop, re-read the request, surface the assumption before writing more code.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code (no Strategy pattern for one branch).
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for scenarios that can't happen.
- If the solution is 200 lines and could be 50, rewrite it.
- Prefer the standard library over third-party dependencies wherever it covers the need without meaningful trade-off.

✓ Check: would a senior engineer reviewing this diff say "this is overcomplicated for what was asked"? If yes, delete the speculative parts before submitting.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables that YOUR changes orphaned; leave pre-existing dead code alone unless asked.
- Document the assumption behind every changed line inline (comment or commit message detail). Why did this line need to change? What dependency, constraint, or requirement drove it?

✓ Check: can every changed line be traced directly to the user's request? Any line you can't justify — revert it. Run `git diff` and ask line-by-line "did the user ask for this?" and "can I explain *why* this specific change was necessary?".

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform imperative tasks into verifiable goals: "fix the bug" → reproduce then pass; "refactor X" → before/after checks pass; "add validation" → invalid-input tests pass.

For multi-step tasks, state the plan with per-step verification:

```
1. [Step] → verify: [concrete check]
2. [Step] → verify: [concrete check]
3. [Step] → verify: [concrete check]
```

✓ Check: for every change in this task, is there a concrete check (test, grep, manual repro) that proves "done"? "I think it works" or "looks right" is not a verification.

## 5. Three-Strike Stop Condition

**Loop until verified — but halt the loop at 3 failed attempts.**

Principle 4 says "loop until verified." Unbounded looping on the same approach is how sessions burn hours producing identical failures. Before a 4th attempt, change the frame — not just the inputs.

- **Attempt 1** — execute the plan; if it fails, diagnose the concrete error (don't re-run blindly).
- **Attempt 2** — try a different path (different tool, library, or data shape). If it fails the same way, the assumption is wrong.
- **Attempt 3** — reconsider the assumption itself (wrong file? wrong abstraction? wrong success criterion?). Do not just retry with small tweaks.
- **After 3 failures** — stop. Report to the user: what was tried, why each failed, what you now suspect is wrong. No silent 4th attempt.

✓ Check: can you cite what *frame* changed between attempts? If attempts differ only by a flag value, a retry count, or a rephrased prompt — the frame hasn't changed; you're looping, not iterating.

Origin: condensed from [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) 3-Strike Error Protocol.

## 6. Response Discipline
**Short, precise, direct. No performative wrapping.**
- Output only useful task content; avoid process narration, self-congratulation, gratuitous confirmations/apologies, and requirement restatement.
- Correct objective errors neutrally. Do not infer the user's stance or motive; distinguish questions from claims before challenging.
✓ Check: can every sentence justify its utility to the user's explicit request? If not, delete it.

## Observable Signals — Is This Working?

These defaults are being activated (not just stored) if diffs and sessions show:

- **Fewer drive-by changes** — every changed line traces to the request; no style churn, renaming, or dead-code deletion that wasn't asked for.
- **Clarifying questions come before code, not after mistakes** — ambiguity is surfaced at the start of a turn, not during cleanup two iterations in.
- **Shorter first drafts** — simple implementations that grow only when real pressure forces them; no speculative flags, strategy classes, or config for one-use code.
- **Concrete verification per step** — every claimed "done" cites a test, grep result, or manual repro; no "looks right" or "should work."

If none of these signals appear across several sessions, the defaults are stored but not activated. Log the incident in [`references/behavior-failures.md`](../references/behavior-failures.md) rather than re-reading the rule again — storage without activation is itself a tracked failure mode, not a reminder problem.

---

## When to override

These defaults bias toward caution over speed. For trivial edits (typo fix, one-line comment, dependency version bump), use judgment — the full rigor isn't always warranted. But for any non-trivial change, all six apply.

Project-specific overrides go in `rules/project-rules.md` and must cite the reason (e.g. "rapid prototyping phase, simplicity first suspended until Milestone 2").
