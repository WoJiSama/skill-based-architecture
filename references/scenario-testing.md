# Scenario Testing for Skills

Structural checks prove the skill is shaped correctly. Scenario tests prove the
agent is likely to do the right thing for a real user request.

## Test Layers

Use only the layers justified by the skill's risk:

| Layer | Proves | Add when |
|---|---|---|
| Unit | Script functions handle parsing, config, and formatting | `scripts/` contains reusable logic |
| Contract | Docs, indexes, constants, and error registries stay synchronized | The skill has generated indexes, error codes, API paths, or output contracts |
| Golden | CLI output stays stable for callers | Workflows depend on exact script stdout shape |
| Scenario | User language routes to the expected reads, calls, and final behavior | A route is high-risk, ambiguous, side-effectful, or expensive to get wrong |

Rule-only skills often need only structural and contract checks. Executable
skills usually need all four layers for their highest-risk routes.

## Contract Test Patterns

Good contract tests are deterministic and harness-neutral:

- Directory index consistency: every file in `tools/`, `capability/`, or
  `workflows/` appears in the matching `INDEX.md`, and every index entry points
  to a real file.
- Error code registry: every `ERR_*` referenced by capability or workflow docs
  is defined in the central error file.
- Script constant consistency: every documented external path, command name, or
  schema key is registered in the script constants it depends on.
- Routing target existence: every route target points to an existing workflow,
  reference, rule, or external skill invocation note.

Keep these tests local and cheap so they can run before commit.

## Scenario Test Pattern

A scenario test should be a small transcript-shaped proof:

1. Provide one realistic user prompt in the language users actually use.
2. Run the agent or a route simulator in an isolated workspace.
3. Stub external calls so no real remote side effects occur.
4. Record actual reads, commands, or mocked API calls.
5. Assert a loose subset: required files were read, expected calls occurred,
   forbidden calls did not occur, and the final answer used the mocked result.

Prefer subset assertions over exact transcript matching. Agents can legitimately
change wording or intermediate order while preserving behavior.

This upstream repo keeps only minimal self-hosting route proofs in
`scripts/check-self-scenarios.sh`. That script is intentionally not copied as a
default downstream harness; downstream projects add their own scenario tests
only for routes with real behavior risk.

### Case Split for Skill Upgrades

When a rule or workflow change is meant to fix a behavior failure, do not test
only the incident that inspired it. Split cases before applying:

- **Incident** — the original failure or pressure scenario.
- **Candidate rule** — the durable behavior being proposed, phrased without the
  source project's names.
- **Regression case** — a normal task that should still work after the change.
- **Boundary case** — a near-negative where the new rule should not over-fire.
- **Holdout challenge** — kept back until after the rule is written; never use
  it to invent the rule, only to validate generalization.

If the holdout fails, revise the rule or reject it. Do not add another special
case unless it passes the recording, activation, and net-benefit gates.

## When To Add Scenario Tests

Add a scenario test when one of these is true:

- The route performs or prepares a non-idempotent action.
- The user wording overlaps multiple routes and a wrong choice is costly.
- A previous behavior failure came from route selection rather than missing
  files.
- A workflow depends on external skill invocation or mocked external systems.
- A route has custom slot-filling or confirmation logic.

Do not ship a heavy scenario harness in the default template. Start with this
reference and add project-owned tests only when the project has real behavior to
protect.

## Context Efficiency Evaluation

Use this evaluation when claiming that routing or retrieval reduces time,
reading, or Token cost. Run the same representative tasks and correctness oracle
through these variants:

1. **Ordinary Agent** — proficient `rg`/LSP plus targeted local reads; no
   intentionally naive whole-repository preload.
2. **SBA routing only** — Always Read plus the matched route and its workflow,
   with the layered retrieval clauses disabled as an explicit ablation.
3. **SBA plus layered retrieval** — routed knowledge → symbol location → local
   implementation → one-hop callers/consumers/tests → evidence-driven expansion.
4. **SBA plus an optional relationship backend** — only when such a backend is
   already available. Its absence skips this variant; never install one merely
   to complete the benchmark.

Correctness and semantic completeness are admission gates, not weighted metrics.
Define the expected decision, invariant, and key call-chain relationships before
the run. A result that saves time or Tokens but misses any load-bearing item
fails; do not average that miss into an efficiency win.

For every admitted run, record:

- elapsed completion time;
- actual source/output characters or Tokens read;
- tool-call count and files/symbols/line spans inspected;
- key call-chain coverage and final-decision correctness;
- whether truncation was disclosed and detail was requested only when needed;
- any index build, refresh, query, and stale-result recovery cost.

Keep the task, repository revision, harness/model class, available tools, and
acceptance oracle comparable. Include localized, ordinary cross-file, and
complex-call-chain tasks instead of selecting only graph-friendly cases. If an
optional backend is measured, report cold, warm, and amortized cost separately;
its preprocessing is not free. Prefer distributions and failure cases over one
headline percentage.

## Baseline-First for Discipline Content

The layers above verify *routing and behavior* — they prove a finished skill does
the right thing. This is a different activity: how you *author* discipline-enforcing
content (a red flag, a rationalization-table row, an "always/never" rule) so it
actually changes behavior instead of sitting inert.

**Core idea (skills-as-TDD):** the rule is "production code"; the "test" is a
pressure scenario on a fresh agent. RED = the agent violates the rule *without* it
present; GREEN = it complies *with* it present. If you never watched the agent fail
without the rule, you don't know the rule teaches the right thing — same logic as
code TDD.

**This is not a mandatory gate on every edit.** It is scoped and tiered so it
never taxes normal iteration:

| Situation | What to do | Cost |
|---|---|---|
| Editing reference / descriptive content | Nothing — no behavior to fail | 0 |
| Discipline rule, and you already watched the agent fail this session / known recurring pain | Baseline is organic — record the verbatim failure, write the rule | 0 (no subagent) |
| Discipline rule for a failure you have **not** observed ("just in case") | Run a baseline to prove it, **or** drop the rule | ~2 min, or 0 |

The last row is the only place you spend a subagent run — and it is exactly the
imagined-pain fork (SKILL.md Common Pitfalls #10). Baseline-first makes that
pitfall *executable*: instead of arguing whether a hypothetical failure is real,
prove it cheaply or don't ship. If you won't spend two minutes proving it, that
answers whether it deserves permanent context weight.

**Running a baseline (only for the unevidenced case):**

1. Write one pressure scenario — the task plus the pressure that tempts the
   violation (time, sunk cost, authority, exhaustion).
2. Dispatch a subagent that does **not** have the candidate rule in context. Watch
   what it does; record its rationalization **verbatim** — that exact wording
   becomes the rationalization-table row.
3. No failure → the rule is imagined-pain; stop, don't ship it.
4. Failure confirmed → write the rule targeting that exact rationalization.
   Optional GREEN (high-stakes rules only): re-run with the rule to confirm
   compliance.

Reuse organic failures whenever you have them — they are free baselines.
Manufacture a baseline only when you have a hunch but no evidence.
