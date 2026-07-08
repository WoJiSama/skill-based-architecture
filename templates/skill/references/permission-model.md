# Reference — Permission Model (operation-authority engine) · OPT-IN

The **operation axis**: not "is the code right?" (the design axis — architecture/conventions/gotchas) but **"may the agent take this action?"** An opt-in discipline for skills whose agent performs side-effecting operations. **Not a list you match — a classifier you run** before any such operation; the project's concrete lists are its worked outputs. report-not-block: 🟡 is proposed by the agent and judged by the user, not a gate it self-certifies; only 🔴 earns a machine gate.

## The classifier (run before any side-effecting op; input = operation × target)

**The tier is a function of `operation × target/environment`, not the operation alone.** The same action is 🟢 against a local/reversible target and escalates against a production/shared/irreversible one. Ask in order:

1. **🔴?** Irreversible **and** catastrophic/security — touches **production or shared** data/config/infra, commits a secret, destroys shared history (force-push a release), weakens a security posture → **refuse, even if asked in passing**; name which 🔴 it is + offer a compliant alternative.
2. **🟡?** Blast radius exceeds the current task — **breaks** an existing external contract, changes data shape/schema, alters transaction/lock/idempotency/authz semantics, affects a **non-local** environment, is hard to reverse, or deletes a file **still referenced elsewhere** → **propose (format below), stop, await explicit approval**, then act.
3. **else 🟢** — autonomous (read, local build/test, generate-diff-without-applying). 🟢 is the **default, not a list**.

*Additive ≠ breaking:* adding an optional field is 🟢; removing/renaming/narrowing one is 🟡. *Target decides:* authoring a migration file is 🟡; running it against prod is 🔴; against a local dev DB, 🟢.

## Tier semantics

| Tier | Before acting | Obligation |
|---|---|---|
| 🟢 | just do it | no ask; report honestly at closure |
| 🟡 | **stop** | propose → await explicit OK → then act (**pre-execution**, not report-after) |
| 🔴 | **don't** | refuse + name the rule + offer an alternative; no exception on request |

## 🟡 proposal format (what a stop must surface — else "stop and ask" is inert)

1. **Operation + target** — what, against which environment/contract/data
2. **Exactly what it touches** — field / table / index / lock / route / config
3. **Reversal cost** — can it be undone, how expensive
4. **Downstream blast** — who consumes this contract/data
5. **Recommendation + alternatives** — which you'd pick, why

## Enforcement ladder (how a 🔴 gets teeth)

prose (declares; doesn't block) → remove-the-material (`.env.example`, deploy-time creds — nothing to copy) → pre-commit (machine scan at commit) → CI / server-side (hard block). **The more catastrophic, the further down it must reach; stopping at "it's in a doc" is theater.** Two corollaries: a layer that only tells the agent to self-check is **still layer 1**; don't build a layer for a gate that doesn't exist — machine layers only for rules with a real baseline (imagined-pain guard).

## The two axes cross-check (design ↔ operation — three rungs)

This axis is **independent from but paired with** the design axis (code correctness) — a double helix. Bind them at three points:

1. **At classification (operation ← design):** if the action touches an architecturally load-bearing area or a known gotcha, raise it **at least to 🟡** even if unlisted — design weight lifts the operation tier.
2. **At closure (read both strands):** task-closure asks, beyond "is the code right?", **"were any 🟡/🔴 operations taken, and was each surfaced for judgment before acting?"** A 🟡 done unannounced = a logged overstep.
3. **At growth (mutual template):** when recording a lesson, ask whether the paired strand needs a rung — a code gotcha may imply an operation tier ("editing X silently breaks prod → editing X is 🟡"); an operation incident may imply a design convention ("a secret leaked → secrets never in committed config, inject at deploy").

## Boundary / orthogonality

Opt-in; kept out of `conformance.yaml`. Orthogonal to **blast-radius buckets** (path → closure rigor) and the **subagent negative list** (operation → delegation) — cross-reference, never merge; three axes. The project's concrete 🔴/🟡 operations, with **scope** (target) and **enforcement-layer** columns, live in a single flesh table in the code repo.

<!-- OPTIONAL: the project's operation table (code_root, one file). Columns: operation | tier | scope (only when target = prod/shared) | enforcement (now→target, 🔴 only) | blast/why. 🟢 = default (not listed). Move operation-🔴 HERE, not into the design-prohibitions file. -->
