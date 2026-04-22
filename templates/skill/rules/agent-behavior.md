# Agent Behavior — Defaults

Universal coding-behavior defaults for any agent working inside this skill. Pre-filled, not `FILL` placeholders: these apply regardless of project. Delete or override a principle only if this project explicitly needs different behavior (write the override in `rules/project-rules.md` with reasoning).

Origin: Andrej Karpathy's observations on LLM coding pitfalls (2025). Principles 1–6 condensed from [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) and [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files); principle 7 from the [SemVer specification](https://semver.org) and downstream breakage evidence in `examples/behavior-failures.md`; principle 8 from evidence of CHANGELOG discipline before merge; principle 9 from evidence of perf regression shipping costs (`examples/behavior-failures.md` Scenario 4); principles 10–12 from user evidence of deployment safety, code review discipline, and security pairing.

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

Transform imperative tasks into verifiable goals:

| Imperative (weak) | Verifiable (strong) |
|---|---|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure test suite passes before and after — no behavior change" |

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

## 6. Write Tests That Fail Before the Refactor, Pass After

**Prove refactors preserve behavior; don't assume it.**

When refactoring existing code without changing its contract:

- Write a test that exercises the current behavior (should pass before the refactor).
- Refactor the code under test.
- Re-run the test; it must still pass after the refactor.
- If the test fails post-refactor, the refactor broke something — fix it or revert.
- This pattern prevents silent behavior drift; it's not about adding new test coverage, it's about protecting existing behavior during a change.

✓ Check: for every refactored module, is there a test that was green before and remains green after? If you only added tests *during* the refactor, you have no proof that behavior was preserved.

## 7. Use Semantic Versioning for All Releases

**Version numbers are a contract. Breaking that contract silently breaks consumers.**

Every release must follow [SemVer](https://semver.org): MAJOR.MINOR.PATCH.

- Increment PATCH for backward-compatible bug fixes only.
- Increment MINOR for backward-compatible new functionality.
- Increment MAJOR for any breaking change — no exceptions, no "soft" breaks.
- Pre-release labels (`-alpha.1`, `-rc.2`) signal instability; never ship them as stable.
- Document every version increment in a CHANGELOG entry before tagging the release.
- Do not reuse or retract published version tags; if a release is wrong, publish a new version.

✓ Check: does the version bump match the nature of the change? If the diff breaks a public API, removes a parameter, or changes observable behavior, it is MAJOR — not MINOR, not PATCH.

## 8. Always Document Breaking Changes in CHANGELOG Before Merging

**If it breaks the contract, record it before the PR lands — not after.**

When a change removes, renames, or alters the behavior of a public API, CLI flag, config key, file format, or data schema:

- Add a CHANGELOG entry under the appropriate version heading before the PR is merged.
- The entry must include: what changed, what the old behavior was, what the new behavior is, and the migration path (or "no migration path — irreversible").
- "Breaking change" means any consumer depending on the previous contract would need to update their code or config without any action from this repo.
- If no CHANGELOG exists in the project, create one at the repo root before merging the breaking change.
- Do not defer the entry to a follow-up commit — the PR and the CHANGELOG entry are a single atomic unit.

✓ Check: before merging, does the CHANGELOG contain an entry for every breaking change in this PR? If the answer is "I'll add it later" or "it's obvious from the diff" — the PR is not ready to merge.

## 9. Run Benchmarks Before Any Performance-Related Edit

**Measure before, measure after. Don't ship perf work without deltas.**

When modifying code for performance (caching, batching, algorithm simplification, or optimization):

- Establish a baseline: run the performance test suite or manual benchmark on the current code and record the result.
- Make the change.
- Re-run the same test under identical conditions. Compare the two measurements.
- If the change regresses (slower, higher memory, more CPU), revert it or fix the regression before shipping.
- If no regression, document the delta in the commit message or PR body.
- Never rely on "it should be faster" or code review to catch perf regressions — measurement is the gate.

✓ Check: for every performance-related change, can you cite the before-and-after benchmark results? If "no" or "I didn't measure" — the change isn't done.

## 10. Pair Program on All Security-Sensitive Changes

**Never ship auth, crypto, or data-boundary code solo.**

Security-sensitive changes include: authentication and authorization logic, cryptographic operations, secrets handling, user data access or mutation, input sanitization at trust boundaries, and network-facing attack surface.

- Before starting, name the security-sensitive surface explicitly in a comment or task note.
- Implement the change, then request a second human review before the PR merges — not just CI approval.
- If a dedicated security reviewer is available, route to them; otherwise ensure a second engineer with security awareness reviews the diff.
- Do not self-merge security-sensitive PRs, even if you are the only approver.
- If a security question arises mid-implementation that you cannot resolve with confidence, stop and surface it — don't guess and ship.

✓ Check: has a second human reviewed the security-sensitive surface of this change, not just the surrounding code? "CI passed" or "looks fine to me" from the author does not count.

## 11. Never Commit Directly to Main Without PR Review

**All changes require code review; no force-pushes, no exceptions.**

- Create a feature branch for any non-trivial change (more than a comment or version bump).
- Open a PR early; wait for explicit review approval before merge.
- Do not bypass with force-push or direct commits to main.
- If CI fails, fix it before merge — don't ignore red checks.
- Document *why* the change exists in commit message or PR description.

✓ Check: is the change on a feature branch with a PR that has passed review? If you pushed directly to main or merged without approval, you skipped this principle.

## 12. Always Document the Deployment Rollback Plan Before Shipping a Breaking Change

**Plan the way back before you go forward.**

- Breaking changes (MAJOR versions) must ship with a documented rollback procedure.
- Rollback documentation includes: how to revert the deployment, how to detect rollback failure, what data cleanup (if any) is needed before reverting, and how long the rollback window stays open.
- The rollback procedure is tested *before* the breaking change ships — not discovered post-facto.
- If the change cannot be rolled back safely, document why and spell out the irreversible impact clearly in release notes.

✓ Check: for any MAJOR version release, can a peer reviewing the release notes find a concrete "how to rollback" procedure? If the answer is "assume rollback is possible" without explaining steps, the release is not ready to ship.

## Observable Signals — Is This Working?

These defaults are being activated (not just stored) if diffs and sessions show:

- **Fewer drive-by changes** — every changed line traces to the request; no style churn, renaming, or dead-code deletion that wasn't asked for.
- **Clarifying questions come before code, not after mistakes** — ambiguity is surfaced at the start of a turn, not during cleanup two iterations in.
- **Shorter first drafts** — simple implementations that grow only when real pressure forces them; no speculative flags, strategy classes, or config for one-use code.
- **Concrete verification per step** — every claimed "done" cites a test, grep result, or manual repro; no "looks right" or "should work."

If none of these signals appear across several sessions, the defaults are stored but not activated. Log the incident in [`references/behavior-failures.md`](../references/behavior-failures.md) rather than re-reading the rule again — storage without activation is itself a tracked failure mode, not a reminder problem.

---

## When to override

These defaults bias toward caution over speed. For trivial edits (typo fix, one-line comment, dependency version bump), use judgment — the full rigor isn't always warranted. But for any non-trivial change, all twelve apply.

Project-specific overrides go in `rules/project-rules.md` and must cite the reason (e.g. "rapid prototyping phase, simplicity first suspended until Milestone 2").
