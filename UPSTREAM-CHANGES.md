# Upstream Changes

This file is a human- and agent-readable map for downstream refreshes.
When a downstream project asks to update from this upstream repo, read the
latest relevant entries first, then verify every candidate change against the
actual upstream/downstream file diff.

This is not a lockfile, upgrade manifest, changelog contract, or source of
truth. It is intentionally upstream-owned only. Downstream projects should not
copy, create, or maintain a local version of this file.

## How To Use

1. Clone the upstream repo named in `workflows/update-upstream.md`.
2. Read the newest entries below to identify likely files and intent.
3. Compare actual upstream and downstream files before editing.
4. Preserve downstream project-owned rules, gotchas, routing examples, and
   local workflows.
5. Patch useful upstream mechanism changes, then run the downstream validation
   commands from `workflows/update-upstream.md`.

## Entry Format

```text
## YYYY-MM-DD - short title

- Status: superseded by YYYY-MM-DD - newer-title    # OPTIONAL — see below
- Upstream commit: <hash> <subject>
- Changed areas: <files or directories>
- Why it matters: <intent>
- Downstream refresh guidance: <what to compare/port/preserve>
```

### Status field (optional)

Default = active (omit the `Status:` line). Add it only when an entry's guidance has been **reversed** (not merely extended) by a later commit:

- `Status: superseded by YYYY-MM-DD - <title>` — newer entry replaces this guidance. Downstream refresh agents follow the newer entry, skip this one.
- `Status: deprecated — <one-line reason>` — the mechanism this entry describes was removed entirely; no replacement exists. The entry stays as history.

**Writer protocol.** When your new entry reverses an older one — active or archived — edit the older entry to add the `Status: superseded by ...` line referencing your new entry's heading. Pointers are one-way (older → newer); the new entry can mention the supersede in prose but doesn't carry machine markup. Extending or building on a prior entry does **not** count as reversal — only reach for `superseded by` when reading the old guidance would lead a future agent astray.

**Check.** `scripts/check-upstream-supersedes.sh` (wired into `check-all.sh`) validates every `Status: superseded by` reference resolves to a real `## YYYY-MM-DD - title` heading in `UPSTREAM-CHANGES.md` or `UPSTREAM-CHANGES-archive.md`. Broken references fail the suite.

## Archive Policy

Downstream refresh agents almost always only read the most recent 3–5 entries. Old entries cost them context without changing decisions. When this file passes ~300 lines (or roughly 8 entries), move the oldest entries to `UPSTREAM-CHANGES-archive.md` and keep only the most recent 3–5 here.

The archive file has the same format and is read on demand if a downstream agent is investigating a specific historical change. `scripts/check-upstream-changes.sh` enforces a same-diff entry in `UPSTREAM-CHANGES.md` plus the archive policy limits; archived entries are out of the same-diff check's scope.

## 2026-09-20 - Enforce archive policy and SKILL.md dual budget

- Upstream commit: the commit containing this entry
- Changed areas:
  - `UPSTREAM-CHANGES.md` archived 60 aged-out entries (2026-08-11 and older)
    to the top of `UPSTREAM-CHANGES-archive.md`; the active file now holds the
    most recent 5 entries as its own policy requires.
  - `scripts/check-upstream-changes.sh` gained an always-on archive-policy
    gate: fail when the active file exceeds 8 entries or 320 lines
    (env-overridable `UPSTREAM_CHANGES_MAX_ENTRIES` / `UPSTREAM_CHANGES_MAX_LINES`).
  - `SKILL.md` body slimmed from 124 to 79 lines (within its own ≤ 90 budget);
    all principles and pitfalls kept, principle 10 now points to
    `references/protocols.md § Task Execution Protocol` as the detail owner.
  - `scripts/check-self-shells.sh` gained a SKILL.md dual-budget gate
    (description ≤ 25 + body ≤ 90 lines, env-overridable), so the first core
    principle now has an executable check.
- Why it matters: the repo's written policies (archive limits, dual budget)
  were violated by its own daily state with no gate able to see it; old
  changelog entries were silently taxing every downstream refresh agent's
  context, and the entry file every task reads was 38% over its own budget.
- Downstream refresh guidance: no template content changed; nothing to port.
  Downstream agents benefit directly from the smaller active changelog. If a
  downstream project maintains its own copied changelog gate, adopting the
  entry/line cap is optional.

## 2026-09-20 - User-facing plain-language rule in Presentation Gate

- Upstream commit: the commit containing this entry
- Changed areas:
  - `templates/skill/workflows/task-execution.md` § Presentation Gate now
    requires user-facing messages in the user's natural language; internal SBA
    terms (Task Anchor, `requirement-ready`, Native Plan, blast-radius, ...)
    may appear only with a one-sentence plain-language explanation at that
    spot, and Structured Brief section headers use plain user-language words
    (例如 目标 / 完成标准 / 边界 / 步骤), never internal terms such as
    "Goal / Done When / Boundaries".
  - `templates/skill/SKILL.single.md.template` carries the same rule as a
    fixed Always Read bullet for direct Single-file results.
  - `references/self-hosting-shell-base.md` extends the session
    presentation clause; self-hosting shells were regenerated.
  - `templates/skill/conformance.yaml` and
    `references/self-hosting-conformance.yaml` pin the new wording.
- Why it matters: internal vocabulary previously leaked into user-visible
  chat (Structured Brief headers mandated "Done When"), transferring SBA
  authoring complexity to ordinary users — the opposite of the product
  principle that users only own product/business decisions.
- Downstream refresh guidance: compare any materialized
  `workflows/task-execution.md` § Presentation Gate, Single-file `SKILL.md`
  Always Read lists, and conformance pins; port the plain-language rule and
  natural-language header requirement, and drop any local pin that still
  requires "Goal, Done When, material Boundaries, and Steps sections" as
  user-visible headers.

## 2026-08-14 - Keep Markdown link labels out of inline-path validation

- Upstream commit: the commit containing this entry
- Changed areas:
  - `templates/skill/scripts/smoke-test.sh` records same-line Markdown link
    label ranges and does not reinterpret backticked presentation text inside a
    label as a second standalone path dependency.
  - Local-reference scanning retains its original per-line context boundary;
    a reference cue on one line cannot activate an otherwise non-binding
    inline-code example on the next line.
  - `scripts/check-validation-contract.sh` protects the valid label shape while
    still proving that a missing standalone inline-code target and a renamed
    heading fragment fail independently.
- Why it matters: downstream workflows commonly display a backticked
  `rule-update/business-truth.md` path inside a Requirement Decision Source
  link label. The target already resolves relative to its source file;
  treating the label as another workspace-root path creates a false
  broken-reference failure.
- Downstream refresh guidance: port the scanner change into project-customized
  `smoke-test.sh` copies without replacing their path-root or workspace logic.
  Rerun the fitted local-reference phase and confirm both valid backticked-link
  labels and genuinely missing standalone inline targets retain opposite
  outcomes.

## 2026-08-13 - Separate Requirement Definition from implementation planning

- Upstream commit: the commit containing this entry
- Changed areas:
  - Added `workflows/define-requirement.md` as the independently selectable
    interaction owner for desired goal, scope/preservation, decision-bearing
    model/flow, rules/constraints, and observable acceptance. Clear sources may
    return `requirement-ready` without another confirmation; incomplete sources
    return current understanding, real risk/conflict, and only the minimum
    normative question.
  - `change-contract.md` remains the sole runtime semantic owner and now exposes
    the complete progression from `requirement-ready`, through source
    localization and Implementation Binding, to `implementation-ready`.
    Repository facts stay Agent-discoverable; code may prove Current behavior or
    contradict a premise but cannot choose desired product meaning.
  - `plan-feature.md` is now a strict consumer of a ready Requirement and proven
    Implementation Binding. It owns Current -> Target technical design, options
    that preserve the Requirement, Task Interfaces/order, risks/recovery, and
    acceptance-to-proof mapping. Normative gaps return to Requirement
    Definition, and tests or proof commands cannot invent acceptance.
  - Requirement Definition and Plan Feature now apply independent Artifact
    Pressure Gates. A requested Requirement-only PRD may finish at
    `requirement-ready`; when both durable owners exist, `prd.md` owns only
    normative Requirement meaning and `design.md` links it one way while owning
    Current -> Target, tasks, proof, and lifecycle. Technical evidence may
    rebind/replan directly only while Requirement meaning and Task Anchor remain
    unchanged.
  - Task Execution, Change Managed, Fix Bug, review/closure, business-model, and
    durable Plan consumers now preserve the order `requirement-ready -> Task
    Anchor -> implementation-ready -> Native Plan -> mutation`. The Anchor is a
    Session projection of Goal/Done When/Boundaries; neither Anchor nor Plan can
    become a second Requirement owner.
  - Self-hosting routing and fitted downstream materialization distinguish
    explicit Requirement discussion from implementation planning while keeping
    direct feature requests automatic. Single-file, Folder-light, routed, and
    broad carriers preserve the same boundary without adding a mandatory PRD,
    Requirement file, question log, or second runtime ledger.
  - Conformance, representative scenarios, and independent deletion mutations
    protect Requirement dimensions, no-guess handoff, Current-versus-desired
    authority, Anchor projection, `implementation-ready` ordering, Plan return
    behavior, proof subordination, and the absence of Plan owner inversion.
  - External delivery derives artifacts and requested terminal states only from
    the current user request and Governing Requirement as projected into the
    Task Anchor. Plans may identify, order, and read back only already-bound
    artifacts. Composite execution likewise reads Component meaning,
    boundaries, and acceptance from Requirements while Plans own only technical
    interfaces, adapters, ordering, risk, proof, and delivery mechanics; Task
    Execution alone projects the Integrating Anchor and later derives its
    Native Plan.
  - Rule Update names Requirement implementation handoff as the normative
    source and separates frozen Requirement provenance from frozen Plan
    technical provenance. Controlled owner-inversion mutations reject the old
    delivery and Composite Plan authority claims independently.
- Why it matters: the earlier requirement-first rule still left requirement
  brainstorming and implementation design inside one Plan workflow. That made
  it possible for a Plan or test to silently complete missing product meaning,
  and made “只讨论需求” indistinguishable from “根据确认需求制定实现计划”. The
  split gives each deliverable one owner without imposing author machinery on
  ordinary users.
- Downstream refresh guidance: port `define-requirement.md`, Change Contract,
  Plan Feature, Task Execution/Change Managed, routing, and fitted validation as
  one lifecycle change. Preserve project-specific workflows and business
  owners. Clear requests should remain zero-question; incomplete normative
  meaning must return upstream; technical owner discovery stays with the Agent.
  Do not add a durable Requirement or Plan artifact unless the downstream has an
  independent review, handoff, recovery, conflict, or lifecycle reason.

## 2026-08-13 - Requirement-first planning and bounded deterministic execution

- Upstream commit: pending in this working tree
- Changed areas:
  - The SBA Bible, Change Contract, Plan Feature, Task Execution, Change Managed,
    Plan archive guidance, and generated entry shells now treat a requirement as
    the target and a Plan as its revisable means. Any addition or change to
    user-visible behavior, a business flow/state, or an external contract must
    become `requirement-ready` and establish at least a concise Native Plan
    before mutation, even when the request is clear or appears local.
  - Clear requests retain the efficient path: they may reach
    `requirement-ready` without questions or expanded ceremony. A durable Plan
    file remains conditional on explicit user request or real recovery,
    handoff, review, conflict, or lifecycle pressure; logical planning does not
    imply one repository artifact per requirement.
  - Task Execution now reserves Simple for one read-only or fixed-contract
    maintenance action with no new desired behavior. If evidence exposes new
    behavior, dependent owners, contract fan-out, diagnosis, or drift risk, the
    task is reclassified in place and preserves the evidence already gathered.
  - Executable architecture and project profiling now downshift an operation
    only when low freedom and repeated or demonstrated high-error pressure both
    exist. The Agent retains goals, semantic parameters, target and authority
    choices, exception interpretation, alternatives, and escalation; structured
    APIs, existing CLIs, and existing scripts precede any new minimal script.
  - Long-running, asynchronous, backgrounded, noisy, or terminal-truncated work
    now requires authoritative re-readable evidence for the current execution:
    run identity, provenance, freshness, completeness/semantic validity, and the
    requested terminal state. File existence or an intermediate status cannot
    stand in for the requested outcome.
  - Fitted conformance and self-scenarios protect the clear-but-requirement-
    bearing status-grouped defect-filter journey. Independent mutations delete
    requirement authority, Simple exclusion, readiness ordering, Native-versus-
    durable Plan separation, in-place reclassification, both deterministic
    downshift gates, Agent judgment, the one-off direct path, and each readback
    dimension separately.
- Why it matters: a feature request could previously look small and explicit,
  bypass visible planning, then expand across state, count, pagination, and UI
  owners during implementation. Separately, repeated precision work could stay
  fragile, while indiscriminate script creation would reduce the Agent's
  judgment and adaptability. The new contract closes both failures without
  forcing questions, files, or scripts onto every task.
- Downstream refresh guidance: port the entry-shell/Task Execution boundary,
  Change Contract readiness semantics, Plan Feature target/means rule, Change
  Managed trigger, and fitted conformance together. Keep clear requirements on
  the no-question path but never on a no-Plan path. Adopt deterministic carriers
  operation by operation only after both gates pass, and require domain-owned
  current-run terminal evidence for admitted long-running operations. Do not
  copy the self-hosting Bible or author-only mutation harness into ordinary
  downstream Skills unless their own readers and validation pressure admit them.

## 2026-08-12 - Pre-command runtime preconditions and ordered conformance

- Upstream commit: pending in this working tree
- Changed areas:
  - Verified Failure and protocol owners now require stable project tool,
    runtime, or configuration preconditions to live in the nearest downstream
    testing/build owner and activate before the first protected command. The
    owner selects the environment and reads back what the command will actually
    use; an unavailable precondition stops the check instead of producing a
    tool-initialization false red.
  - Verified Failure now classifies two independent boundaries. An activation
    failure means applicable prevention was already stored but did not change
    the protected action in time. A learning-closure failure means the first
    proven stable prevention was not reconciled and activated during that task.
    Stored or post-failure-written knowledge cannot prove pre-action activation,
    and one correct run cannot prove durable learning for the next task.
  - `check-version-conformance.sh` and `conformance.yaml` add
    `must_contain_in_order`, so fitted manifests can distinguish an active
    preflight from the same phrases moved after the protected action.
  - `scripts/check-validation-contract.sh` mutation-protects the contract by
    deleting activation, selection, and effective-runtime readback separately,
    then moving the complete preflight after the protected command and requiring
    an explicit `OUT OF ORDER` failure. It also rejects empty/flow-style ordered
    groups, proves mapping-key order and quoted YAML scalars cannot erase an
    assertion, and requires target decode failures to produce a stable failed
    summary rather than a traceback or zero-assertion pass. Separate mutations
    also delete activation failure, learning-closure failure, and their
    non-substitution boundary so retaining one cannot make the other look done.
  - Installed-reference validation now derives the active `skills/` registry
    from the formal Skill path, so `skills/<sibling>/...` resolves identically
    whether smoke starts at the harness registry root or, as downstream update
    workflows require, inside the installed Skill root.
- Why it matters: compatibility prose and presence-only conformance could both
  be green while an Agent still inherited an incompatible machine default for
  its first test command, paid for a predictable infrastructure failure, and
  only selected the project runtime on retry.
- Downstream refresh guidance: port `must_contain_in_order` only when an
  admitted fitted manifest needs action-order protection. Keep exact versions,
  selectors, readback commands, tool symptoms, and stop behavior in the
  downstream project's testing/build owner; activate that owner before its
  first protected command and add project-specific ordered assertions. Diagnose
  and close stored-but-not-activated prevention separately from first-proven-but-
  not-persisted learning. Do not copy a concrete JDK version into the generic SBA
  template, change a user's machine default, or treat tool initialization as
  business red/green evidence.
