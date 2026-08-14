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

The archive file has the same format and is read on demand if a downstream agent is investigating a specific historical change. `scripts/check-upstream-changes.sh` only enforces a same-diff entry in `UPSTREAM-CHANGES.md`; archived entries are out of its scope.

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

## 2026-08-11 - Code-first first use and fitted validator hardening

- Upstream commit: pending in this working tree
- Changed areas:
  - `WORKFLOW.md`, `templates/skill/workflows/profile-project.md`, the
    self-hosting route, and generated shell templates now send the ordinary
    request `用 SBA 整理这个项目的规则` through migration. The Agent inventories
    code, configuration, tests, scripts, and existing instruction sources before
    asking anything; it asks only unresolved normative, permission, support, or
    acceptance choices that change generated responsibilities, and otherwise
    continues directly to preview/apply.
  - The fitted validator set now treats owner namespaces as containment
    boundaries, ignores non-live HTML/YAML comments and clearly optional prose,
    prevents unrelated harness registrations from satisfying a missing owner,
    resolves formal `skills/...` references from the active harness registry,
    preserves GitHub heading-slug behavior, accepts mapping keys independent of
    YAML order, and streams large Markdown inventories without placing every
    path in one process argument list. Complete-scaffold fixtures retain their
    declared domain, maintenance, permission, and activation owners.
  - Self-hosting smoke now resolves a root-owned Skill by its frontmatter name,
    validates `references/self-hosting-routing.yaml` through the owning shell
    check, and separates real root entry paths from authoring prose that teaches
    downstream placeholders and generated paths. Full-tree Markdown links and
    heading fragments remain strict; an executable root-layout fixture prevents
    regression without weakening installed `skills/...` resolution.
  - `scripts/check-self-scenarios.sh`,
    `scripts/check-validation-contract.sh`, template/self-hosting conformance,
    and the fitted two-root checks now mutation-protect those boundaries.
  - The declared-Full and existing-project journeys now model the complete
    semantic-merge lifecycle: after an Agent replaces preserved shell content,
    each regenerates canonical routing blocks before strict `--check`
    validation instead of treating post-merge drift as a materializer defect.
  - `scripts/check-live-agent-journey.sh` exposes named `single-file` and
    `migration` black-box journeys. `scripts/check-all.sh --live-agent` runs
    both and reports unavailable transport, authentication, or model access as
    exit `3` / `NO VERDICT`, separate from deterministic pass/fail evidence.
  - README and script documentation describe the two proof layers and journeys
    without promoting structural green into semantic or live-Agent correctness.
- Why it matters: the natural first-use request could previously enter a
  pre-scan brainstorm gate and charge ordinary users for implementation facts
  already present in the repository. The stronger path checks also exposed
  false greens from root escapes, cross-Skill collisions, and routing comments,
  plus false reds from optional examples, valid YAML key order, GitHub slugs,
  active-harness Skill paths, self-hosting owner-root confusion, and large
  documentation trees. These changes make first use code-first and
  keep each validation claim bounded to evidence it actually observes.
- Downstream refresh guidance: do not copy the upstream migration workflow,
  live-Agent runner, or validation fixtures into an ordinary downstream merely
  for uniformity. When a downstream already owns the broad validator scripts,
  compare and port the containment/comment/registration/slug/inventory fixes as
  one coupled validator change, preserve project-specific routes and owners,
  fit conformance to the materialized result, and rerun its own sync, smoke,
  orphan, reachability, route-health, and content-conformance checks. No
  downstream consumer was assembled or mutated by this upstream change.

## 2026-08-10 - Evidence-selected downstream materializer

- Upstream commit: pending in this working tree
- Changed areas:
  - `scripts/scaffold-downstream.sh` now inventories target instructions, recurring-task evidence, harness readers, and lifecycle/maintenance pressure before any write. It derives `direct`, `folder`, or `broad` internally; previews `CREATE` / `PRESERVE` / `CONFLICT`; preserves existing entries; stages and rolls back apply; guards parent symlinks and destination escape; and keeps temporary evidence outside the downstream repository.
  - New concrete carrier templates cover complete Single-file, direct/routed folder, fitted lightweight workflow, independently admitted Managed Execution and Closure, direct root entry, and evidence-selected Cursor registration. They are materializer author inputs, not a universal downstream tree.
  - `scripts/check-all.sh` now exercises the real materializer against empty-target Single-file, one-procedure Folder-light direct, broad/complete, and existing-entry migration targets. The independent `managed-only`, `closure-only`, `both`, and `neither` lifecycle combinations, macOS Bash 3.2 empty arrays, quoted/backslashed YAML evidence, and parent-symlink escape are covered by fitted journeys/checks.
  - `SKILL.md`, `WORKFLOW.md`, README files, template/reference guides, and the completed `docs/plans/2026-08-04-default-downstream-simplification/prd.md` now describe one natural-language migration request, evidence-selected physical ownership, conditional `routing.yaml`, independently admitted Task Execution/Closure, and harness surfaces that follow real readers.
- Why it matters: the old Quick Start copied Full author machinery into every project and made ordinary users pay for SBA's internal taxonomy. The new path keeps each generated downstream complete for its admitted responsibilities while allowing a true single-task project to remain a complete `SKILL.md`, a routed project to promote one route owner, and a broad project to retain every mechanism its evidence actually requires.
- Downstream refresh guidance: do not copy the new materializer, evidence checker, live journey, or author templates into an ordinary downstream as a package. Existing projects should keep their current complete owners and evolve through normal project maintenance. When rematerializing or migrating a project, inventory and preserve every existing entry, admit only proven routes/lifecycle/harness/maintenance owners, complete project-specific semantic merging, and run only the fitted checks owned by the result. Do not ask users to choose a tier/profile/capability pack or treat `READY FOR SEMANTIC MERGE` as semantic completion.

## 2026-08-10 - Responsibility-aware validation and bounded green claims

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/scripts/smoke-test.sh` now treats only `SKILL.md` as universal. A valid Single-file Skill may omit `routing.yaml`, separate rules/workflows/gotchas, Cursor registration, and root harness shells; every owner that is actually materialized is still checked. Missing optional files no longer abort budget helpers under `set -e`, and the historical `FILL:` -> `FILLED:` laundering shortcut is an explicit failure.
  - `scripts/check-validation-contract.sh` protects both sides of the oracle: a real Single-file fixture passes without Full-only files, a complete scaffold retains all declared Full surfaces, and renamed migration markers fail. The Full fixture now replaces project-specific markers with concrete content instead of mechanically relabeling them.
  - `scripts/check-migration-evidence.sh` validates a Session-scoped clause inventory, exactly one mapped/excluded disposition, verbatim destination presence, explicit review evidence for rewrites, and a complete activation chain. It explicitly does not claim that phrase search proves rewrite equivalence.
  - `scripts/check-all.sh` calls the new deterministic contracts and ends with a bounded structure/mapping/content claim. `--live-agent` separately runs `check-live-agent-journey.sh` in a fresh project; external transport/auth unavailability returns no behavior verdict instead of being confused with product pass or failure.
  - `templates/skill/conformance.yaml` and the validation documentation now identify the current manifest as the complete-scaffold content contract. Evidence-selected results use a fitted manifest only when their actual owners have repeatable machine-check pressure.
  - `WORKFLOW.md` now initializes the session-scoped migration-evidence manifest with `mktemp`, explicitly keeping it out of the downstream repository; self-hosting conformance guards that executable example.
  - The self-hosting Phase 7 check is named as a shell/bootstrap/link subset because the root repository intentionally retains template markers; downstream Skill structure is proven by the fitted Single-file and complete-scaffold fixtures.
- Why it matters: the prior suite could reject a correct Single-file result for lacking the Full physical inventory while accepting a complete scaffold whose project-specific work was merely renamed from `FILL:` to `FILLED:`. Static route and phrase checks were also easy to summarize as Agent behavior. The new boundary preserves useful structural regression coverage without allowing deterministic green to overclaim semantic or behavioral correctness.
- Downstream refresh guidance: port the adaptive `smoke-test.sh` behavior when a downstream legitimately supports Single-file or conditional harness owners. Keep strict checks for every surface the project actually materializes, reject both unresolved and renamed FILL markers, and fit conformance to those owners rather than applying the complete-scaffold manifest universally. `check-validation-contract.sh`, `check-migration-evidence.sh`, and `check-live-agent-journey.sh` are upstream/Agent-side acceptance tools; do not copy them into an ordinary downstream unless independent recurring maintenance pressure makes one a real project-owned responsibility.

## 2026-08-10 - Requested-artifact completion scope and user-first README

- Upstream commit: pending in this working tree
- Changed areas:
  - `protocol-blocks/external-delivery-verification.md` now binds a Session-only requested artifact set when delivery spans multiple artifacts, repositories, or systems, or when the user asks an aggregate completion question. Each item keeps its own owner, requested terminal state, authoritative readback, and typed result; aggregate completion covers only the current request and Governing Requirement as projected into the Task Anchor. A Plan may only supply technical identity, ordering, and readback for an already-bound artifact.
  - `workflows/task-closure.md` consumes that bounded set and requires every requested artifact to reach its exact terminal state. Local readiness, commit, push, MR/PR, approval, merge, assembly, deploy, and publication remain distinct states; neighboring or historical work cannot enter completion implicitly.
  - Template and self-hosting conformance protect the requested-artifact boundary, exact-state verification, and the existing guarantee that optional subagent dispatch degrades to the same bounded inline work without weakening the workflow or its checks.
  - `docs/sba-bible.md` records the stable completion-scope principle. `README.md` and `README.zh-CN.md` were rebuilt around the ordinary-user journey, executable safeguards, and an explicit separation between the current full-scaffold implementation and the draft evidence-driven materializer.
- Why it matters: an Agent could previously report an aggregate task as complete after checking a nearby delivery state, import unrelated repository history into the answer, or let an unavailable optimization look like a correctness blocker. The new boundary makes completion match the exact current request while the README now exposes the safeguards users can actually rely on without presenting roadmap behavior as shipped.
- Downstream refresh guidance: port `task-closure.md`, `external-delivery-verification.md`, and their conformance anchors together. Preserve project-specific artifact types, target identities, authoritative readbacks, approval/merge/deploy semantics, permission rules, and delivery commands. Do not create a persistent delivery ledger, treat an intermediate state as the requested terminal state, import adjacent repositories automatically, or let unavailable subagent dispatch skip or weaken required work. The README/Bible restructuring itself requires no downstream scaffold update; downstream-facing documentation may adopt the clearer current-versus-roadmap wording when relevant.

## 2026-08-06 - Runtime context kernels and canonical task routing

- Upstream commit: pending in this working tree
- Changed areas:
  - `workflows/task-execution.md` is now the continuity kernel. Composite Plan execution and User Decision Drift move to independently triggered protocol owners under `protocol-blocks/`; the kernel keeps only their activation, immediate boundary, and returned outcome. Task Anchor, Native Plan, checkpoints, recovery, evidence handling, schema gating, Verified Failure handoff, new-message handling, and Closure exit remain in the kernel.
  - `workflows/task-closure.md` remains the sole readiness/completion owner while Plan/Knowledge reconciliation, external artifact verification, and post-completion workflow proposal logic move to three conditional protocol owners. Ordinary local Closure no longer loads Composite/business-leaf reconciliation, delivery retry semantics, or workflow-distillation evidence unless their triggers exist.
  - `routing.yaml` is the sole owner of exact task route ids, labels, trigger examples, workflow paths, fallback, notes, and route metadata. Generated `SKILL.md` Common Tasks is now one manifest-read/select/fallback action hook; thin shells retain the independent bootstrap. Sync, smoke, conformance, fixtures, and reference docs validate the structured manifest rather than a duplicate Markdown route catalog.
  - Self-scenarios add a local preflight that rejects unescaped Markdown backticks inside double-quoted assertion operands before Bash can execute them as command substitution.
- Why it matters: high-frequency project workflows were repeatedly loading route data twice and carrying low-frequency Composite, decision-drift, delivery, and distillation definitions through ordinary tasks. The new owners preserve one execution mainline and one Closure state while moving only independently triggered semantics off unrelated paths.
- Downstream refresh guidance: adapt the kernels and conditional owners into the downstream's existing Task Execution and Closure surfaces; add every new protocol block to its canonical vendor/assembly manifest and fitted conformance. Make `routing.yaml` the only exact task-route catalog, regenerate the Common Tasks action hook and shells, and move route-count/path/trigger assertions to YAML. Preserve project-specific root entries, read-only routes, business leaves, testing/permission/database gates, delivery mechanics, canonical-source provenance, and assembly commands. Do not copy generic files over project owners wholesale, add a second runtime state, create another completion owner, remove terminal read-only behavior, or infer commit/push/MR/deploy/database authority.

## 2026-08-07 - Semantic fidelity and lifecycle audit corrections

- Upstream commit: 6805893 fix: preserve user source semantics across workflows
- Changed areas:
  - `task-execution.md` now preserves the full Simple/Managed/Design classifier, freezes a risk-sized Done Contract before the first Managed step, binds every bounded read to a next-decision and stop boundary, treats truncated/Top-N output as incomplete evidence, and gives Structured Brief precedence without forcing ceremony onto Simple work.
  - `user-decision-drift.md`, `plan-feature.md`, `maintain-docs.md`, Task Execution, and Closure now preserve user brainstorm source authority. Source capture precedes synthesis: already-clear wording stays verbatim; optional readability editing is limited to punctuation, obvious typo, grammar, or word order; speech act/force, ownership, timing/commitment, uncertainty/emphasis, definitions, conditions, boundaries, negations, reasons, authority, scope, and status remain reconstructable. Any Agent summary is explicitly derived and cannot replace the source as the sole normative record.
  - `plan-knowledge-closure.md` now enumerates one-way `consumes`, reads Components at their canonical owners, distinguishes frozen `done`, unfinished `draft`/`executing`, true `subplan_of`, and independent Component lifecycles, and requires Plan Leaf Reconciliation before implementation handoff rather than first-writing at Closure.
  - External delivery verification distinguishes `stale` source/verification inputs from `premise-changed` artifact/target/authority/scope changes. Pattern B composition examples use validator-safe local workflow paths and explicitly hand off to external Skills instead of embedding unchecked paths.
  - The audit also documents the Single-file fast path and adds the missing conditional protocol owners to the template guide, conformance, and self-scenarios.
- Why it matters: the prior reduction preserved structural green checks while deleting or weakening clauses that changed how a fresh Agent would classify user intent, preserve a long-task mainline, reconcile composite Plans, or prove an external artifact. These corrections restore the user-to-Plan authority boundary and prevent progressive disclosure from becoming semantic deletion or user-facing routing burden.
- Downstream refresh guidance: port the generic kernels and protocol blocks through the downstream's canonical app-skill owners, preserving application-specific permission, business-leaf, code-root, database, UI/API, and delivery contracts. Reconcile every changed clause against the existing owner before replacing text; do not copy generated consumers directly, make Simple tasks load Managed/Closure machinery, create Component status mirrors, or let Closure perform the first business-leaf write. Update conformance and representative journeys to prove semantic reconstruction, not only file presence.

## 2026-08-05 - Rule Update progressive disclosure owners

- Upstream commit: pending in this working tree
- Changed areas:
  - `workflows/update-rules.md` is now the compact shared durable-write contract and ambiguous-request dispatcher. It keeps classification, source/authority fidelity, targeted reconciliation, action-changing activation, placement/generalization, synchronization, verification, and unchanged authority, but no longer embeds every typed procedure.
  - `workflows/rule-update/` adds four independently loaded owners: `business-truth.md`, `verified-failure.md`, `knowledge-reconciliation.md`, and `workflow-distillation.md`. Known callers enter the applicable owner directly; only an input such as `记录一下` whose type is still unknown enters the dispatcher first.
  - Requirement implementation handoff, standalone business modeling, Fix Bug, Task Execution, Task Closure, documentation maintenance, Gotcha guidance, and protocol summaries now link to the typed owner at the lifecycle boundary where its evidence exists.
  - Template and self-hosting conformance plus self-scenarios assert complete branch semantics, direct links, negative cross-branch loading, the shared activation/authority contract, and the nested workflow paths. No second index, routing manifest, Memory store, candidate ledger, mode, or user-visible configuration was added.
- Why it matters: the previous 23 KB owner forced a proven JDK/Mockito failure to load business modeling and workflow-distillation rules, while a Requirement implementation handoff loaded recurrence and enforcement semantics. The new shape preserves the same decisions and authority while each normal journey loads only the shared contract plus its one typed owner.
- Downstream refresh guidance: adapt from the downstream's current Rule Update owner rather than replacing it wholesale. Preserve project-specific business leaves, Plan reconciliation, code-root ownership, cross-app paths, promotion boundaries, canonical-source provenance, assembly commands, and fitted verification. Add only the typed owners the project actually admits; update known callers to direct links; keep ambiguous explicit recording on `update-rules.md`; generate/install through the canonical owner and verify real consumers instead of hand-editing installed copies.

## 2026-08-04 - Post-completion proactive workflow distillation

- Status: superseded by 2026-08-05 - Rule Update progressive disclosure owners
- Upstream commit: pending in this working tree
- Changed areas:
  - `task-closure.md` may normalize repeated-procedure evidence during execution but presents at most one optional proposal only after `Closure Complete` and the completion report. Two independently completed semantic instances are required; retries, adjacency, frequency, and command similarity do not qualify. Pure composition is silent, decline/defer is Session-only, and no candidate store or exhaustive history scan is created.
  - `update-rules.md` receives only a user-accepted candidate, treats that consent as the approved scoped upgrade plan, and chooses `extend`, pure `compose`, or `create` after inspecting existing owners. It resolves downstream/meta/package provenance, mutates one canonical owner, requires owned assembly/install plus downstream readback, and keeps complete cross-repository orchestration in one owner with thin local hooks.
  - Bible principle 14 and `references/protocols.md` preserve the stable product and operating boundary. Template/self-hosting conformance plus sixteen transcript-shaped self-scenarios protect evidence, timing, suppression, ownership, source-to-consumer activation, proposal payload, acceptance transition, authority, and the absence of a new route/store/Always Read surface.
- Why it matters: repeated end-to-end delivery work was easy to leave as transient chat even when the stable relations among steps, authority checkpoints, and integrated acceptance could reduce future user effort. Automatically generating workflows or tracking every task would create prompt fatigue, duplicate owners, and a new subsystem; the useful capability is a result-first consent question backed by proven repetition and ordinary maintenance only after acceptance.
- Downstream refresh guidance: adapt the two-owner contract into the downstream's existing Closure and Rule Update owners, then fit conformance/scenarios to real repeated procedures. Preserve project-specific routes, workflow names, parameters, permission checkpoints, canonical source provenance, installation/assembly commands, and verification evidence. If a meta-repository or package owns the workflow, edit only that source and verify every actual consumer; if the downstream owns it directly, keep the complete owner there. Do not copy example platform/product values, add a workflow-candidate route/store/ledger/counter/signature database, scan all task history, ask before verified completion, persist refusals, wrap pure composition, hand-edit generated copies, duplicate complete cross-repository bodies, or infer commit/push/MR/deploy/database/work-item/version/reviewer/publish/merge authority from workflow consent.

## 2026-08-04 - First proven failure writes to active prevention

- Status: superseded by 2026-08-05 - Rule Update progressive disclosure owners
- Upstream commit: pending in this working tree
- Changed areas:
  - `task-execution.md` keeps failed commands, tests, runtime checks, delivery actions, and premise changes as one Session-only candidate until root cause and red-to-green proof exist; nontrivial diagnosis reclassifies Simple work to Managed, and every proven failure hands off to Rule Update before Closure.
  - `update-rules.md` is the complete durable owner. A first proven actionable failure bypasses only the ordinary Recording Threshold, reconciles directly into the nearest canonical rule/Gotcha/workflow/reference/executable owner, and activates before the next mistake-prone action. It returns one bounded outcome, matches recurrence by root cause + applicability + prevention, repairs missed activation before adding prose, and preserves machine-gate, promotion, delivery, and external authority boundaries.
  - `fix-bug.md` invokes verified engineering learning immediately after fitted red-to-green proof while keeping Bug evidence out of desired business truth. `task-closure.md` accounts for completed outcomes and additional AAR lessons; it no longer diagnoses root cause or defers the first write.
  - `references/protocols.md` and Bible principle 13 preserve the operating/product boundary without adding a Memory route, ledger, counter, chronology, database, new workflow, or default Always Read content.
  - Template/self-hosting conformance and self-scenarios protect direct first write, Session-only hypotheses, retry/recurrence separation, activation repair, lifecycle outcomes, authority non-expansion, and the absence of Closure-only engineering learning.
- Why it matters: repeated Mockito/JDK, test-construction, duplicate-coverage, and stale-evidence failures showed that completion-time AAR and stored notes can be too late. The useful contract is not another failure history; it is that proven prevention changes the next applicable action at its existing owner.
- Downstream refresh guidance: port `task-execution.md`, `update-rules.md`, `fix-bug.md`, `task-closure.md`, the compact protocol summary, and fitted conformance/scenarios together. Preserve project-specific testing/runtime facts, Gotcha locations, business leaves, routes, validation commands, and authority rules. For example, a project-specific JDK constraint belongs in that project's activated testing owner, not in the generic SBA template. Remove wording that sends proven engineering lessons only to final Closure/AAR. Do not add a Memory route/store, failure ledger/counter, eager read, generic error catalog, automatic personal/team promotion, or shared/costly machine gate without the existing approval boundary.

## 2026-08-03 - Plan composition and database-change artifacts

- Upstream commit: pending in this working tree
- Changed areas:
  - `plan-feature.md` distinguishes ordinary dependencies, independently authoritative Component Plans, durable Integrating dossiers, and true `subplan_of` children. Composition stays Session-only unless persistence pressure exists, promotes an existing truthful common-outcome owner before creating another Plan, and records only one-way `consumes` / `subplan_of` / `supersedes` graph edges without status mirrors.
  - `task-execution.md` derives exactly one Integrating Task Anchor, Native Plan, and semantic `Current Task`; validates Component lifecycle/interface preconditions; returns conflicts to the narrowest owning Plan; and requires active Decision Deltas or frozen successors without adding runtime stores or durable progress states.
  - `task-closure.md` reconciles every affected Component owner before integrated acceptance and delivery. Missing, abandoned, unresolved, unfinished, or superseded-but-still-consumed Components block completion; abandoning an Integrating Plan leaves independent Components unchanged.
  - `docs/plans/README.md` and `_TEMPLATE.md` own the durable archive shape and graph metadata. The completed Requirement-Semantics Plan moved into its existing composition owner as a dossier `prd.md` with a repository-local `consumes` edge; frozen semantic content remained unchanged.
  - Database-structure changes now require a separately disclosed user checkpoint and a natural Plan-local `.sql` sibling before implementation: authoritative complete target DDL, forward schema/data update, historical-data treatment, read-only verification, and safe rollback or explicit backup/stop/forward-repair recovery.
  - Template and self-hosting conformance plus behavior scenarios protect the single Native Plan, Component-first Closure, non-mirrored graph, frozen-successor boundary, conditional SQL creation, SQL completeness, and the distinction between a reviewed SQL artifact and authorized database delivery.
- Why it matters: two independently valid Plans can govern one outcome without either surrendering ownership, but parallel runtime Plans and physically parallel archives made integration state, conflict authority, and final reconciliation ambiguous. Separately, prose-only schema impact let application persistence code advance without an explicit database contract or user-visible execution boundary.
- Downstream refresh guidance: adapt the composition and database gates into the downstream's existing Plan, execution, Closure, conformance, and database-delivery owners as one contract. Preserve project-specific business/domain rules, permission/security gates, test/browser acceptance, generated/source boundaries, and the real migration or version-platform workflow. Keep one runtime Native Plan, resolve Component truth at each owner, use successors for frozen semantic changes, and create SQL siblings only for real schema impact. Do not copy archive paths, project-specific SQL/dialects, generic status fields, reverse-consumer indexes, or direct database execution commands; a SQL dossier never authorizes bypassing the downstream database workflow.

## 2026-08-03 - Product semantics to proven code owner

- Upstream commit: pending in this working tree
- Changed areas:
  - New `protocol-blocks/change-contract.md` is the single complete owner for conditional product-language translation, desired-meaning authority, Semantic Intent readiness, Current -> Target implementation binding, evidence-driven return/expansion, and Session-only lifetime.
  - New `protocol-blocks/source-localization.md` independently owns adaptive technical narrowing: bounded owner regions, deterministic candidate search, selected-source tracing, canonical owner/source proof, generated-source return, and a Session-only runtime map.
  - `plan-feature.md`, `fix-bug.md`, `change-managed.md`, `ambiguous-request-gate.md`, `task-execution.md`, and `task-closure.md` receive thin trigger/input/output/acceptance hooks. Clear requests, confirmed Plans, observed/expected contracts, and proven targets retain direct fast paths; Closure remains a consumer of the final expanded contract.
  - Template and self-hosting conformance plus self-scenarios protect authority separation, normal Current/Target binding, progressive source exposure, technical-fact ownership, consumer non-duplication, no eager route/read, and no persistent contract/map artifact.
  - The SBA Bible records the product boundary: the Agent translates product semantics into an executable change contract and proves the current code owner; users decide only unresolved normative meaning, authority, permission, scope, preservation, acceptance, and high-cost trade-offs.
- Why it matters: product-language requests previously relied on users or developers to translate PRDs/design inputs into repository vocabulary before SBA workflows could act safely. That gap could omit material surfaces, turn references or inference into fake authority, expand related behavior without approval, stop on noisy lexical matches, or bind a coherent change to the wrong implementation owner.
- Downstream refresh guidance: compare and port both protocol owners as one composed capability, then map the six thin hooks to the downstream's actual Plan, Bug Fix, Managed Change, question, execution, and Closure owners. Preserve project-specific business leaves, authority rules, routes, validation commands, delivery permissions, and generated/source boundaries; do not add a first-workflow route, Always Read entry, global keyword dictionary, visible mandatory form, search wrapper/index service, or persistent Change Contract/technical map. Verify known-target fast paths and one ambiguous product-language task against real downstream code before assembly or delivery. Treat project adaptation, generated-copy refresh, commit, push, MR, and release as separately authorized work.

## 2026-07-31 - Pressure-triggered planning artifacts

- Upstream commit: pending in this working tree
- Changed areas:
  - `plan-feature.md` first classifies the requested deliverable. Explaining a planning method, reviewing an existing Plan, or brainstorming direction stays bounded read-only advisory work; only an explicit concrete Plan request activates full Design-Slice closure and artifact decisions.
  - `plan-feature.md` now treats complexity as analysis depth only. Planning starts inline, closes one evidence-bearing Design Slice at a time, stops evidence expansion when the current question is resolved/falsified or the next semantic owner is known, preserves compact user authority, and creates a durable Plan only when an explicit request or independent persistence, consumer, review, validation, lifecycle, conflict-reconciliation, or handoff pressure appears.
  - Interactive Complex/Large planning now pauses after the first Slice that exposes a user-owned normative choice or high-impact assumption. It discusses that one topic before unrelated evidence expansion; only an explicit artifact-only/end-to-end request authorizes uninterrupted completion.
  - The brainstorm owner is now named `Progressive Brainstorm Handoff` to match its actual timing; downstream consumers should update the heading/anchor together rather than waiting for a completed document.
  - Active Plans with multiple Open Questions resume from the highest-impact unresolved decision and load only evidence fitted to that question; other questions and evidence paths stay unopened until their turn.
  - `plan-large.md` no longer maps perspectives to sibling files. It keeps architecture/domain/data/integration/risk/rollout/decomposition analysis integrated until a sibling can independently change the synthesis, task boundary, risk treatment, or proof.
  - `docs/plans/README.md` and `_TEMPLATE.md` replace complexity-driven one-file/directory selection plus the fixed canonical section skeleton with a current-contract model: no artifact by default, one file while one carrier is enough, and a `prd.md` directory only when an independently useful sibling already exists.
  - The SBA Bible, conformance manifests, and self-scenarios protect pressure-triggered materialization, Design Slice completeness, authority separation, real alternatives, stale-question removal, and the rejection of placeholder decomposition/file taxonomies.
- Why it matters: the prior workflow could create `prd.md` before the problem was understood, encourage a transcript to masquerade as a design contract, and turn Large analysis lenses into many small files. Structural completeness then obscured missing owners, semantic consumers, failure boundaries, and observable proof.
- Downstream refresh guidance: port `plan-feature.md`, `plan-large.md`, and the Plan archive/template contract together. Remove any route or complexity rule that creates Plan files automatically; preserve local business/domain owners and validation commands. Do not pre-create `prd.md`, `design.md`, risk/database/contract files, or a Plan directory. Let current evidence activate design dimensions, and create only the smallest artifact with a demonstrated independent job.

## 2026-07-31 - Evidence-bearing stage completion

- Upstream commit: pending in this working tree
- Changed areas:
  - The SBA Bible now states that a main step advances only on evidence that changes the next decision or can be consumed by the next stage; commands, generated files, and successful exit codes are not stage completion by themselves.
  - `task-execution.md` binds each main step to an unresolved question, evidence that can resolve or falsify it, and an advance/return condition. Contradictory evidence returns to the owning earlier step; inconclusive evidence keeps the step open instead of consuming a retry quota or advancing the Plan.
  - The matched domain Workflow defines valid evidence for its material risks. Task Closure rejects a successful command as completion when it does not validate target behavior or feed the next step.
  - Self-hosting Bible conformance, downstream conformance, and scenario contracts protect the stage-evidence boundary without adding an evidence ledger, persistent state, fixed evidence type, or domain-specific command to the default scaffold.
- Why it matters: a green build, generated artifact, or successful tool call can prove its own narrow contract while leaving the requested runtime, UI, migration, routing, or delivery behavior unverified. Treating action completion as outcome completion creates false progress and lets local green checks replace decision-relevant evidence.
- Downstream refresh guidance: port the Task Execution evidence question and advance/return logic together with the Closure exit-code rationalization and conformance anchors. Preserve each project's actual validation commands and domain evidence. Do not create a per-step evidence file or force every task through the same proof type; require only evidence that resolves the current question, changes the next action, or is consumed by the next stage.

## 2026-07-30 - Evidence-driven workflow and delayed domain routing

- Upstream commit: pending in this working tree
- Changed areas:
  - Task routes now select only the first workflow. Task-level `required_reads`, executable `route` bodies, and inline `domain_overlays` are rejected; workflows start from the smallest decision-relevant evidence and acquire rules, references, testing, Managed execution, and Closure contracts at their lifecycle boundaries.
  - `domain-routing.yaml` is an optional, separately timed second-stage manifest. Only two states are valid: no business owner and no manifest, or one-or-more business owners with a non-empty validated manifest. The first business-owner workflow materializes the owner plus route atomically, and routing, orphan, reachability, health, smoke, and conformance checks reject missing, empty, unsafe, unregistered, or workflow-replacing domain routes.
  - Keywords produce domain candidates only. Explicit business-rule work or a known source-Plan owner evaluates the manifest immediately after workflow selection; ambiguous work waits for evidence of a business type/flow/state/boundary/invariant decision; clearly technical work never reads it. A domain owner appends knowledge and never replaces the selected workflow; cross-domain expansion requires new evidence.
  - REMOVED the universal `rules/agent-behavior.md`, `references/agent-behavior-meta.md`, and `agent-behavior-gate.sh` aggregation path. Unique semantics moved to their lifecycle owners, including `protocol-blocks/ambiguous-request-gate.md`, `rules/change-discipline.md`, `workflows/task-execution.md`, delegation workflows, and Task Closure. Always Read now defaults to empty.
  - Shell generators, migration/upgrade guidance, diagrams, and validation scenarios now express the evidence boundary without a hard token, byte, file-count, or elapsed-time correctness budget. The SBA Bible remains self-hosting product cognition and is never an ordinary downstream runtime dependency.
  - Task Closure now spans the late delivery boundary without adding a delivery workflow or granting side-effect authority. It may declare `Ready for Delivery` after local verification, AAR, conditional distillation, and integrity checks, but remains open until the matched workflow verifies the requested commit, push, MR, deploy, publication, report, or other artifact. External-only retries reuse unchanged local evidence; changed source or premises return to fitted verification.
  - The default scaffold no longer exposes `subagent-driven` as a task-size sibling route. The primary workflow is selected by intent first; Managed Task Execution loads the long-run workflow only as an evidence-backed cross-cutting modifier, matching the existing multi-skill routing rule and preventing task size from replacing fix/change/plan semantics.
- Why it matters: selecting a workflow and probable business knowledge in one startup step made first use load a broad project-document bundle before source evidence. Shortening files did not fix that timing error and a fixed budget would trade correctness against an arbitrary threshold. The new contract preserves one canonical semantic owner while delaying every optional read until it can change the next action.
- Downstream refresh guidance: perform a one-time source migration. Move each task `required_reads` item to the owning workflow's initial-evidence or later decision checkpoint; move inline overlays to a non-empty `domain-routing.yaml`; migrate project-specific content out of `agent-behavior.md` to its lifecycle owner; then delete the aggregation/meta/hook artifacts and registrations. Port the Closure readiness/completion boundary into the local `task-execution.md`, `task-closure.md`, protocol summary, and conformance anchors while preserving project-specific delivery commands and authorization. Domain-free projects omit the manifest. Domain-bearing projects must add the first owner and route together, run `sync-routing.sh --check`, smoke, orphan, reachability, route-health, and conformance, and prove generated shells/copies match their canonical source. Preserve project task routes, business truth, validation commands, and local permission boundaries; do not keep a dual compatibility runtime or copy the SBA Bible.

## 2026-07-30 - Business leaf and Gotcha single-owner boundary

- Upstream commit: pending in this working tree
- Changed areas:
  - `update-rules.md` makes the business leaf the complete owner of cross-implementation normative truth and the Gotcha the complete owner of costly, non-obvious implementation failure experience; ordinary implementation maps remain technical references.
  - `docs/plans/README.md` no longer treats multiple audiences as permission to copy a complete conclusion into multiple active files.
  - `profile-business-model.md.example` and `maintain-docs.md` detect business truth stranded in Gotchas, implementation detail leaked into leaves, and complete-rule duplication across the two destinations.
  - Conformance protects the boundary and rejects restoration of the old "it goes in both places" wording.
- Why it matters: business-sensitive Fix Bug and Plan tasks can load both a domain leaf and routed Gotchas. Repeating the same complete rule in both wastes context, creates two authorities, and lets implementation history silently redefine desired business truth. Keeping one owner plus a minimal action link preserves local actionability without semantic drift.
- Downstream refresh guidance: preserve project-specific leaf and Gotcha file boundaries, but port the owner test into the local recording and maintenance workflows. Then reconcile real content pairs: lift stable business truth into the routed leaf, keep symptoms/current-code causes/wrong shortcuts/repair guidance in Gotchas, move ordinary code maps to references, and replace repeated normative bodies with minimal owner links.

## 2026-07-29 - Implementation facts before business questions

- Status: superseded by 2026-07-30 - Evidence-driven workflow and delayed domain routing
- Upstream commit: pending in this working tree
- Changed areas:
  - `rules/agent-behavior.md` adds the evidence-backed Implementation-Fact Question Gate: close decision-relevant entry/caller/write-target/branch-or-state/order/guard/failure/UI-API hops before asking, trace distinct flows independently, and never ask the user to choose current implementation facts.
  - Plan, business-modeling, and Fix Bug workflows activate the owner locally and keep only their task-specific next action and acceptance check.
  - `examples/behavior-failures.md` records the real downstream failure that justified spending Always Read surface: two incomplete branch/merge flows were collapsed into a user-facing binary question even though code contained the answer.
- Why it matters: a question can mention business concepts yet still transfer repository discovery to the user. Closing only one nearby endpoint is not evidence closure, and relating two incomplete flows produces false choices instead of a normative decision.
- Downstream refresh guidance: preserve project-specific code paths and route wording, but add one shared fact-closure owner plus local workflow hooks. When users say the answer is in code, stop the question, finish the trace, state the current fact, and ask only whether the future rule should change.

## 2026-07-29 - Standalone modeling and confirmed-gap Plan upgrade

- Upstream commit: pending in this working tree
- Changed areas:
  - `references/business-global-model.md` makes the routed leaf the default standalone-modeling deliverable. Interview length, file count, and complexity no longer create a PRD.
  - A four-condition `confirmed implementation gap` gate is the only narrow exception: user-confirmed stable truth, implementation evidence of noncompliance, explicit difference/impact, and real implementation-handoff value.
  - `profile-business-model.md.example` writes truth and gap into the leaf immediately, creates/reuses one draft dossier, continues the agreed modeling scope, then hands the complete deduplicated gap set to `plan-feature.md`.
  - `update-rules.md` owns direct leaf admission and prevents transcripts, Agent reading history, unconfirmed candidates, and evidence-poor differences from becoming PRDs.
- Why it matters: forcing every business interview through Plan Feature creates duplicate process records, while forbidding active truth until implementation lands loses confirmed business meaning. The narrow upgrade keeps the leaf authoritative and creates an implementation artifact only when delivery work genuinely exists.
- Downstream refresh guidance: route pure modeling directly to the domain owner leaf. Reuse an existing Plan when present; otherwise allow only one draft gap dossier per agreed modeling scope, keep collecting until that scope is complete, then discuss implementation themes without reconfirming settled business truth.

## 2026-07-29 - Detailed brainstorm after Plan completion

- Upstream commit: pending in this working tree
- Changed areas:
  - `workflows/plan-feature.md` separates pre-Plan option divergence from the new Plan-Complete Brainstorm Handoff.
  - After internal checks, Simple/Complex/Large Plans automatically enter user-facing discussion unless the user requested artifact-only delivery, paused, or stopped.
  - Each topic must replay enough mainline context and explain current conclusion, evidence/constraints, remaining normative question, concrete impacts/trade-offs, Agent recommendation, and one user decision point; each answer updates Decision Delta and affected Plan sections immediately.
  - Conformance rejects three-line summaries, batch confirmation checklists, and implementation offers before the substantive discussion converges.
- Why it matters: a syntactically complete PRD can still leave the user without enough context to judge its load-bearing choices. Short summaries make the user reopen code/PRD and hide the exact trade-off that still needs owner authority.
- Downstream refresh guidance: preserve local Plan paths and terminology, but make Plan completion a discussion handoff rather than a stop signal. Choose discussion depth from real decision pressure, explain one topic in decision-ready detail, and never invent extra options merely to satisfy a quota.

## 2026-07-28 - Business-domain progressive split gate

- Upstream commit: pending in this working tree
- Changed areas:
  - `references/business-global-model.md` and `workflows/profile-business-model.md.example` define one business domain, not one code module, as the default file unit. Size and section count start a review but never force a split.
  - A same-owner domain becomes a directory only when real task signals select independently understandable business submodules and the split reduces irrelevant context. Different business owners or domain boundaries become sibling domain leaves instead.
  - Split directories use a selecting `index.md`, optional shared `overview.md`, and one leaf per business submodule or decision surface. Aspect slices such as `types.md` / `states.md` / `lifecycle.md` are rejected when callers still need them together.
  - Conformance and self-hosting scenarios protect the review trigger, non-mechanical decision, business-submodule unit, and index boundary.
- Why it matters: one-file-per-domain is cheap and predictable while a model is small, but without an explicit pressure gate it can harden into an oversized leaf. Splitting by document headings creates navigation without reducing task context; splitting by independently routed business submodules preserves domain ownership while allowing narrower reads.
- Downstream refresh guidance: keep existing small domain leaves intact. Add review signals around 120 nonblank lines, more than 10 substantive H2 sections, or repeated independent task selection; then split only when the independent-load test passes. Convert the domain file into a directory with a selecting index and submodule leaves, preserve shared invariants once, and update domain overlays and inbound links.

## 2026-07-28 - Evidence-grounded business questions

- Upstream commit: pending in this working tree
- Changed areas:
  - `workflows/plan-feature.md` makes the Question Gate own an evidence-before-questioning contract: trace one concrete business flow, inspect the available implementation evidence, form a working conclusion, then cross-check it with existing user-confirmed answers. Aligned or decision-irrelevant points stop without another question; only unresolved ambiguity that could change the decision reaches the user.
  - `workflows/profile-business-model.md.example` and `workflows/fix-bug.md` keep only local action hooks plus the Question Gate owner link.
  - Conformance and self-hosting scenarios reject blank abstract-definition prompts when a concrete business flow is inspectable.
- Why it matters: asking "what is this concept essentially, why does it exist, and when does it end?" before reading enough code transfers Agent discovery work to the user and produces detached, low-value business models. Turning later clarification into an exhaustive questionnaire repeats the same cost. Code does not define normative truth, but implementation evidence and existing user-confirmed answers can eliminate settled or decision-irrelevant questions before the Agent asks anything new.
- Downstream refresh guidance: strengthen the local Plan Question Gate, then link business-model and Fix Bug clarification paths to it. Preserve the distinction that the Agent's conclusion is proposed/current implementation fact while the user's answer supplies normative business meaning.

## 2026-07-28 - Active business-knowledge capture during Bug Fix

- Status: superseded by 2026-08-04 - First proven failure writes to active prevention

- Upstream commit: pending in this working tree
- Changed areas:
  - `workflows/fix-bug.md` now treats the user's explicit business statement as the only possible business-recording source during diagnosis. The Agent may judge that content's durability and invoke `update-rules.md` immediately instead of waiting for Task Closure, but must not derive a business rule from the Bug, repair, evidence, or its own summary.
  - `workflows/update-rules.md` owns the Active Bug-Fix Input admission path, user-meaning fidelity, provenance, and the user-content-only boundary. Reusable engineering lessons still flow through normal Closure/AAR into gotcha, rule, or reference destinations rather than business.
  - Conformance and self-hosting scenarios protect the immediate owner link, non-deferral behavior, explicit-user-source rule, Bug/Agent-derived exclusion, and engineering-lesson destination without copying the complete recording procedure into Fix Bug.
- Why it matters: a user can state durable business truth while reporting or clarifying a Bug even when no source Plan exists. That user statement can be lost if evaluation waits until Closure, but the Bug and its repair are evidence about implementation, not authority for inventing user intent.
- Downstream refresh guidance: add a small active-recording trigger and completion check to the local Fix Bug workflow, link it to the local `update-rules.md` owner, and add an Active Bug-Fix Input entry there. Allow only explicit user business content into that path; preserve its meaning faithfully, keep Bug/repair/evidence/Agent summaries out of business leaves, and send reusable engineering lessons through Closure/AAR. Preserve project-specific owner paths and do not duplicate the complete recording gates inside Fix Bug.

## 2026-07-27 - User-confirmed Plan mainline and immediate implementation-drift gate

- Upstream commit: pending in this working tree
- Changed areas:
  - `plan-feature.md` makes the Plan folder the authority for decision-bearing brainstorm evidence. Clear user answers, selections, rejections, and corrections are recorded with question/context, `Authority: user-confirmed`, scope, and current-conversation provenance; unselected candidates remain proposed and clear answers are not redundantly reconfirmed.
  - At design-to-implementation handoff, stable confirmed normative business meaning is distilled into the routed business owner as `desired business truth` with Plan provenance. Code, tests, and runtime remain separate `current implementation fact`; a known gap is explicit rather than hidden or treated as proof that the desired rule changed.
  - Task Execution, Change Managed, Fix Bug, and Receiving Review replay the relevant Plan mainline before Plan edits, code reasoning/implementation, or review. The new User Decision Drift Gate pauses the affected path immediately when implementation diverges, presents constraints/cost/risk and options, and resumes only after an explicit user decision; first disclosure at Closure is invalid.
  - Business-model guidance, rule recording, Plan lifecycle/archive docs, protocol summaries, conformance, and the SBA Bible now carry the same authority, provenance, activation, and drift semantics.
  - `maintain-docs.md` now owns the semantic-ownership judgment: complete definitions, state transitions, and multi-step procedures normally have one owner, while consumers may retain the smallest trigger, immediate action, and task acceptance hook needed to act locally. Full repetition requires task evidence that it is cheaper than navigation/loading/generation; generated copies are reserved for independently delivered/used artifacts and require deterministic drift validation.
  - Task Execution is explicitly the complete Drift Gate owner. Change, Fix Bug, Review, Closure, business-model, protocol, and migration consumers link to it and no longer compete for its proposed/superseded transition procedure. Conformance validates full semantics at the owner and activation/local responsibility at consumers; the self-scenario simulates the affected-path rule and rejects copied full transitions.
- Why it matters: brainstorm answers were easy to lose as transient chat or freeze as inert Plan provenance, letting later work follow current code or Agent preference instead of the user's confirmed business mainline. The first delivery also touched 20 files and coupled validation to repeated wording. This extension keeps each complete semantic change at its lifecycle owner while preserving locally actionable consumers, so structural green no longer requires or rewards hand-maintained full copies.
- Downstream refresh guidance: reconcile local Plan/Decision Context, business-model, Task Execution, feature/fix/review, recording, and Closure workflows together; do not port only the storage wording. Preserve project Plan and business-leaf paths. Keep the complete Drift Gate in Task Execution, replace consumer copies with a direct owner link plus the smallest local trigger/action/check, and refit conformance to validate owners fully and consumers by activation. Do not copy raw chat transcripts, add a generic decisions directory, introduce generation inside one Skill merely to remove a few repeated lines, or make touched-file count a success metric.

## 2026-07-27 - Evidence-first request judgment and safe first-migration journey

- Upstream commit: pending in this working tree
- Changed areas:
  - The Ambiguous Request Gate and every downstream shell summary now treat vague wording as an uncertainty signal rather than an automatic stop. Agents route likely intent, inspect the smallest read-only evidence set, derive technical scope from project truth, and ask only for an unresolved normative preference, authority boundary, or materially different outcome. Mutation still waits for a verifiable requested outcome.
  - NEW `scripts/scaffold-downstream.sh` replaces the Quick Start raw `cp -R templates/shells/. .` path. It defaults to dry-run, reports create/preserve/conflict decisions, rejects reruns over an existing skill or Cursor registration, never overwrites existing project entry files, substitutes placeholders only in new scaffold content, records the upstream baseline, and rolls back newly created paths on apply failure.
  - `WORKFLOW.md` profiles and inventories existing instruction sources before writes. Preserved entries are semantically merged by the Agent; ordinary users are not asked to compare files. Structural smoke green is explicitly separated from source-to-destination migration evidence.
  - `scripts/check-all.sh` now calls the real scaffolder for both an empty-project happy path and an existing-project journey. The latter proves dry-run leaves the target unchanged, apply preserves old entries byte-for-byte, migrated instruction content survives byte-for-byte in routed skill rules, and the integrated scaffold still passes smoke, routing, orphan, and reachability checks.
- Why it matters: the previous lexical gate weakened Agent judgment by blocking evidence gathering, while the previous empty-directory scaffold test stayed green even though the documented first-use command silently overwrote real `AGENTS.md` and `CLAUDE.md` files. These changes align the executable path with SBA's product direction: absorb technical discovery cost, preserve user-owned semantics, and never use structural green as a proxy for user success.
- Downstream refresh guidance: re-vendor the Ambiguous Request Gate and update thin-shell summaries together. Existing downstream projects do not rerun the first-migration scaffolder; use their normal `update-upstream` workflow. New migrations should invoke the upstream scaffold command from `WORKFLOW.md`, preserve every existing entry, and require source-to-destination evidence in addition to smoke-test results.

## 2026-07-23 - Orthogonal domain context and knowledge-retirement integrity

- Status: superseded by 2026-07-30 - Evidence-driven workflow and delayed domain routing
- Upstream commit: pending in this working tree
- Changed areas:
  - `sync-routing.sh` accepts optional `domain_overlays` that append domain reads without replacing the one task route's workflow. Overlay-enabled generated entries keep only current-Session `task_route_id`, `domain_overlay_ids`, and `merged_required_reads`; the default scaffold declares no overlay and exposes no extra routing concept.
  - Cross-owner reads use project-declared `owner_roots` plus `owner:<owner-id>:<path>`. `--workspace-root` verifies real targets and rejects undeclared owners, absolute/traversal paths, boundary escape, and missing files; without it the check explicitly reports target existence as unverified. No project/app whitelist is embedded upstream.
  - `audit-orphans.sh` recursively scans nested content; `route-reachability.sh` treats recursively nested `references/business/` leaves as active knowledge that must be reachable from a task route or overlay. Routing line-budget reporting keeps optional overlays separate from the task core.
  - Business-model and Plan/Closure/Update Rules guidance conditionally requires source, destination, owner, activation, and fitted validation before durable knowledge is retired. Existing Plans or temporary migration records carry the proof; no permanent dossier, fixed ledger, or ordinary-task double maintenance is introduced.
  - The SBA Bible and runtime workflows state that load-bearing conclusions cannot be silently overwritten when evidence changes, and normative business judgments require business-owner confirmation. This adds no proposed/confirmed/superseded state protocol.
  - Verification now binds each material risk to fitted evidence and an explicit stop/escalation condition before checks run. Task Execution and Closure stop when that contract is satisfied and escalate only on failed evidence, a newly crossed boundary, or remaining uncertainty; test count is not treated as evidence quality.
- Why it matters: a downstream migration made nested business knowledge unreachable while structural checks stayed green, and domain routes competed with task workflows. The absorbed mechanism repairs activation and reviewability while leaving project domains, owner names, and migration inventory downstream-owned.
- Downstream refresh guidance: re-vendor the routing/integrity scripts and workflow clauses only if the project has real domain leaves or knowledge retirement pressure. Preserve project task routes and domain names. Add `domain_overlays` only for existing independently activated business knowledge; declare real owner roots and make assembly pass `--workspace-root`. Do not copy another project's app whitelist, trigger list, ledger, or legacy paths.

## 2026-07-23 - SBA product Bible and direction route

- Upstream commit: pending in this working tree
- Changed areas:
  - NEW `docs/sba-bible.md` fixes the product boundary: SBA remains a Skill that improves how the current Agent uses its harness-native Plan, Subagent, and tools; it does not become an Agent OS, task/state platform, resident service, or independent scheduler. It also records the product owner's highest goal: ordinary project members should clone/pull a complete, reliable Agent rule system without becoming Skill authors or carrying complexity SBA can absorb.
  - The Bible turns three expectations into product direction: build a sufficiently complete decision view, judge direction without a standard answer, and coordinate other agents/tools through standards and contracts to produce verified outcomes.
  - `references/self-hosting-routing.yaml` adds the self-hosting-only `product-direction` route. SBA positioning, external capability absorbs, and major mechanism decisions now read the Bible before `plan-feature.md`; ordinary tasks and downstream templates do not load or copy it.
  - README/REFERENCE discovery links, route scenarios, and self-hosting conformance protect the activation path and load-bearing language.
- Why it matters: isolated principles can optimize local workflows while the product drifts toward more author vocabulary, more centralization, or more activity without better judgment. A stable product constitution gives future choices a common direction and an explicit rejection gate.
- Downstream refresh guidance: no downstream refresh impact. This is upstream product intent and self-hosting routing only; do not copy the Bible into project skills or add it to downstream Always Read sets.

## 2026-07-22 - Subagent provenance and vendor path ownership guards

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/protocol-blocks/subagent-contract.md` and all dispatch/review consumers add `Task Ref` plus the bounded `explore | implement | review | verify` Role, then require returned Evidence for Context Read, Files Changed, Checks Run, and Remaining Risks.
  - Worker Evidence is explicitly an index for context provenance, not completion proof; the main agent still checks actual paths/diff, Forbidden Zones, and reruns Acceptance Criteria before advancing the owning Native Plan step.
  - `templates/skill/workflows/update-upstream.md` now classifies vendor, project-owned, generated, and runtime-data owners. Unlisted paths default to project-owned; generated output comes from its generator; runtime data stays local/gitignored.
  - `sync-vendor.sh` parses only the `vendor:` block and rejects paths outside `sync-manifest.yaml`, `protocol-blocks/**`, and `scripts/**`, plus absolute/traversal paths and any destination with a symlink component. The upstream suite covers section isolation and each rejection class.
  - Downstream conformance protects both contracts without adding a task database, provenance log, or centralized ownership manifest.
- Why it matters: a worker's confident summary cannot establish what context it used, and a permissive manifest parser can accidentally turn project-owned/generated/runtime paths into mechanically overwritten vendor files. A bounded envelope and default-deny write boundary make both claims reviewable without persistent coordination machinery.
- Downstream refresh guidance: re-vendor `protocol-blocks/subagent-contract.md` and `scripts/sync-vendor.sh`; reconcile Task Ref/Role/Evidence wording across local subagent workflows and plan handoffs; port the four owner classes into `update-upstream.md`; update the local conformance snapshot after validation. Preserve stricter local Forbidden Zones, runtime-data ignore rules, and project-specific workflows; do not introduce a provenance datastore or move project-owned paths into `vendor:`.

## 2026-07-22 - Semantic completeness before minimality

- Status: superseded by 2026-07-30 - Evidence-driven workflow and delayed domain routing
- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/rules/agent-behavior.md` replaces Simplicity First with **Semantic Completeness Before Minimality**: Product Development is the default; agents trace invariant, ownership/provenance, producer-to-consumer call chain, and all full/incremental/read/write paths before choosing repair depth. Minimality becomes a tie-breaker among semantically complete solutions.
  - `templates/skill/workflows/fix-bug.md` adds a Repair-depth gate between root-cause discovery and implementation; `change-managed.md` adds the same ownership and semantic-fan-out ordering for features/refactors.
  - Operational Stabilization is now an explicit exception for production incidents, hotfix/availability containment, stop-the-bleeding work, or frozen scope. Containment must be reversible and report that structural repair remains unresolved.
  - Conformance and self-hosting scenarios protect the default mode, invariant-owning boundary, cross-path inspection, and minimality ordering.
- Why it matters: an availability-first default can produce a locally usable patch while leaving the real invariant broken, such as mutating a collection without tracing its immutable owner or updating one incremental path without the shared filter used by the full path. Dependency count measures repair risk; it must not silently redefine correctness.
- Downstream refresh guidance: replace or reconcile existing Simplicity First wording rather than appending another Always Read principle. Port the Repair-depth gate into bug and managed-change workflows, preserve stricter project-specific production controls, then validate both an ownership/mutation case and a full-vs-incremental invariant case.

## 2026-07-21 - Task Anchor and harness-native execution plans

- Status: superseded by 2026-07-30 - Evidence-driven workflow and delayed domain routing
- Upstream commit: pending in this working tree
- Changed areas:
  - NEW `templates/skill/workflows/task-execution.md` — classifies Simple / Managed / Design tasks; Managed tasks establish Goal, Done When, optional material Boundaries, and a task-specific Plan using the harness's native Plan/Task surface. Anchor state is separate from presentation: natural-language alignment is the default, visible Native Plan steps are not duplicated in chat, and a complete structured brief is reserved for long, complex, scope-sensitive, confirmation-dependent, or no-native-Plan work. Before every main step, a compact Anchor Checkpoint re-centers Goal, remaining evidence, the step check, and relevant Boundaries; it repeats after correction, failed/surprising evidence, Subagent return, or interruption. The loop owns runtime progress, evidence-backed advancement, replanning, and new-message handling entirely inside the current Session, with no planning-file persistence.
  - `agent-behavior.md`, generated Session Discipline/Auto-Triggers, and self-hosting shells activate the protocol after routing while preserving zero ceremony for one clear action/check.
  - Fix Bug, Change Managed, Plan Feature, Subagent, and Task Closure workflows now share an explicit boundary: Workflow owns reusable domain procedure; Task Anchor owns the current outcome; Native Plan owns current step state; Closure decides completion only after Goal-level evidence.
  - `conformance.yaml`, scenario checks, guides, README files, and `docs/task-anchor-native-plan.md` protect and explain the user-visible behavior and non-goals (no task database, fixed three-file schema, or cross-tool state sync).
- Why it matters: routing can select the right Workflow while a long Session still drifts away from the user's current goal. A fixed labeled Anchor block can also interrupt ordinary conversation and duplicate the native Plan. Proportional presentation keeps user-visible ceremony matched to task risk, while the internal Recitation Loop keeps the full Anchor in working attention without turning the Skill into a persistent task engine.
- Downstream refresh guidance: add `workflows/task-execution.md` as a non-vendor reusable workflow, port the Goal-Driven Execution, Recitation Loop, and shell activation lines, reconcile local Domain Workflow gates rather than replacing them, and add the Closure Entry Gate. Preserve local validation/permission boundaries and use the local harness's native Plan capability; do not introduce durable planning files, recovery scripts, or cross-Session state for this mechanism.

## 2026-07-20 - Goal contracts and risk-sized checkpoints

- Status: superseded by 2026-07-30 - Evidence-driven workflow and delayed domain routing
- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/rules/agent-behavior.md` — Goal-Driven Execution now starts from one observable goal, explicit non-goals, and acceptance evidence; scoped reversible work runs through its checks without per-step approval, while real decision, authority, shared, or irreversible boundaries still pause.
  - The same rule distinguishes purposeful discovery from execution drift and treats rankings/process metrics as diagnostic signals rather than objectives; opaque rubrics or task mix cannot justify suppressing necessary exploration or evidence.
  - `templates/skill/references/agent-behavior-meta.md` records the activation signals and corrects the existing principle 6/7 origin mapping; `templates/skill/conformance.yaml` protects the three load-bearing phrases.
- Why it matters: blanket approval checkpoints raise user cost, while no checkpoints blur authority and decision boundaries. The risk-sized contract preserves autonomous closure for safe work without optimizing behavior for an opaque score or mistaking necessary discovery for drift.
- Downstream refresh guidance: reconcile the three Goal-Driven Execution bullets in place instead of appending a new principle. Preserve project-specific permission rules, validation commands, and stricter shared/production controls. No new file, route, index, or placeholder is required; run conformance and the normal skill structure checks after adoption.

## 2026-07-17 - Simplify default scaffold and make integrity checks truthful

- Status: superseded by 2026-07-30 - Evidence-driven workflow and delayed domain routing
- Upstream commit: branch `codex/simplify-template-maintenance-20260717` (`96cd072` plus the conformance literal follow-up)
- Changed areas:
  - REMOVED `footprint.sh`, `check-cross-references.sh`, and `check-growth-health.sh`: the first undercounted mandatory reads and failed on two-root prefixes; the second guessed semantic drift from mtime and duplicated link checks; the third emitted permanent review noise while always succeeding.
  - `audit-orphans.sh` and `route-reachability.sh` now accept `--namespace skill|code --routing <path>` and keep identical `skill:` / `code:` paths distinct; route reachability now includes workflows. Single-root zero-argument behavior remains.
  - `_parse_conformance.py` was merged into the public `check-version-conformance.sh` CLI; conformance assertions now protect fewer load-bearing contracts instead of duplicating file existence and wording.
  - Conformance phrases are passed to `grep` after `--`, so a required or forbidden literal beginning with `-` / `--` cannot be misread as a command option; the main suite covers both positive and negative option-like phrases.
  - REMOVED the implicit-Always-Read `minimal-sufficient-context.md`; concise context/evidence escalation now lives in Always Read `agent-behavior.md`, while Fix Bug, Change Managed, and Task Closure retain only task/timing-specific decisions.
  - `agent-behavior.md`, subagent workflows, Fix Bug, Change Managed, Receiving Review, and Task Closure were reconciled and compressed. The three subagent modes remain separate because their selection timing differs; only the main agent runs Task Closure after integrated work.
  - Tests-as-Spec and Permission Model moved from the default downstream scaffold to upstream adoption guides under `references/`. Projects materialize them only after real testing/operation pressure and add a project-specific activation path.
  - Editor-local `.idea/` files were removed; template indexes, sync manifest, diagrams, update guidance, and validation were updated.
- Why it matters: a green structural suite was hiding inaccurate reports, duplicate thresholds, implicit co-loading, and opt-in files copied to every project. The smaller scaffold makes every retained file/check answer an independent question and strengthens actual two-root activation.
- Downstream refresh guidance: remove the three deleted report scripts and `_parse_conformance.py`; re-vendor the retained integrity/conformance scripts; delete `minimal-sufficient-context.md` only after moving any project-specific expansion/validation rules into an actual Always Read rule or task workflow. Keep adopted local Tests-as-Spec/Permission rules if the project has real baselines, but stop treating them as universal template files. Preserve project-specific Fix Bug/validation semantics while removing duplicate core/checklist text. Regenerate routing and run smoke, orphan, route-reachability, route-health, and conformance checks.

## 2026-07-17 - Business global model, durable-record gates, and conditional loading

- Upstream commit: pending in this working tree
- Changed areas:
  - NEW `references/business-global-model.md` and opt-in `templates/skill/workflows/profile-business-model.md.example` — model only stable, implementation-independent macro business types/flows/states/boundaries/invariants; distinguish absent, locally unclear, conflicting, and sufficient states; “later” creates no artifact.
  - `plan-feature.md`, `fix-bug.md`, `change-managed.md`, and `minimal-sufficient-context.md` — business model → architecture/contracts → code/tests/runtime comparison; explicit `business-model impact`; bug classification (`IMPLEMENTATION_BUG` / `DESIGN_CHANGE` / `INSUFFICIENT_BUSINESS_CONTEXT`); type/flow/state/invariant changes exit bugfix and require an approved Plan.
  - `update-rules.md`, `maintain-docs.md`, `gotchas.md`, `references/protocols.md`, `references/layout.md`, `references/skeleton-flesh-split.md`, `route-reachability.sh`, and `SKILL.md` — fidelity + five-way reconciliation + activation gates; generic cross-project vs business cross-implementation durability; no chronological Gotcha append; independent load-reason and semantic before/after audits; known leaves route directly and selecting indexes appear only after real multi-file pressure.
  - NEW `plan-large.md` and `subagent-auxiliary.md`; `plan-feature.md` and `subagent-driven.md` are now small conditional routers. Large analysis and day-to-day auxiliary delegation no longer inflate ordinary Plan/Mode-2 task paths. The auxiliary/Mode-2 split retains the latest inline-default, positive-Net-Benefit, bounded-fan-out, and no-spawn-then-wait rules from the 2026-07-15 scheduling change.
  - `references/self-hosting-routing.yaml` and `templates/skill/routing.yaml` — planning and plan distillation use separate phases; single-skill routing does not preload multi-skill guidance; ordinary rule edits do not preload layout; update-rules classifies before selecting Gotcha vs behavior-failure evidence.
  - REMOVED `protocol-blocks/rationalizations-table.md` and `protocol-blocks/red-flags-stop.md` — `workflows/task-closure.md` is the sole body source; sync manifest and references were updated.
  - Conformance, migration guidance, scenario checks, budgets, and template indexes now assert the new conditional files and contracts.
- Why it matters: code shows current behavior but not necessarily intended business meaning. The new opt-in layer gives Plan and Fix Bug a stable semantic baseline without turning business detail into Always Read context. The same change closes two knowledge-rot paths: lossy summaries and append-only documents, while reducing route-time co-loading.
- Downstream refresh guidance: add `plan-large.md` and `subagent-auxiliary.md`; port the business-semantics gates and update-rules/maintain-docs contracts while preserving project-owned rules and Gotchas. Remove the two deleted protocol blocks and their vendor entries. Regenerate routing after adopting conditional update-rules reads. Product projects should copy/rename the business-model example only after a real module passes admission; non-product projects keep it inactive. Run conformance, sync-routing, smoke-test, orphan/reachability, and relevant behavior scenarios.

## 2026-07-15 - Subagent scheduling: inline default, Net Benefit gate, and no spawn-then-wait

- Upstream commit: pending in this working tree
- Changed areas: `templates/skill/rules/agent-behavior.md`, `templates/skill/workflows/subagent-driven.md`, orchestration/fix/change/plan/refactor activation paths, rationalizations, behavior-failure evidence, and conformance tooling (`must_not_contain` in the parser/checker plus manifest regression guards).
- Why it matters: the previous Mode 1 Iron Law mapped any mechanical/time-consuming/result-only sub-step to mandatory dispatch, while a later paragraph said dispatch was invalid when the main agent could only wait. The stronger early rule won in practice: ordinary grep/tests/edits spawned many workers, the main agent entered repeated wait loops, and coordination cost displaced useful work.
- Downstream refresh guidance: replace mandatory reverse-question/auto-spawn language with an inline default and five-part Admission Gate (independence, result-only consumption, real overlap, positive Net Benefit, bounded fan-out). Port the non-blocking rule: never spawn when the next action is wait; wait only when every remaining critical path depends on already-running workers; never poll-loop. Remove fixed review-agent and one-worker-per-file/test/lens rules. Add local conformance phrases so the old wording cannot return.

## 2026-07-15 - Restore harness-aware subagent fallback

- Status: superseded by 2026-07-15 - Subagent scheduling: inline default, Net Benefit gate, and no spawn-then-wait
- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/subagent-driven.md` — restores the decision-time fallback from the previously published market snapshot: when Codex or another harness has no proactive subagent authorization, Mode 1 continues inline instead of stalling on its dispatch Iron Law. The fallback is explicitly separated from an unexpected execution-time tool denial, which still follows Interception Transparency.
- Why it matters: market version 1.12 commit `2301541` captured a real Codex harness constraint, but the fallback was lost while later upstream work added the Parallelism Premise and worker Return Status vocabulary. Without the fallback, a downstream can read "must dispatch" and "dispatch is unauthorized" as a blocking conflict even though inline execution is valid for that harness.
- Downstream refresh guidance: port the Harness Compatibility row and the inline capability fallback if the downstream can run under per-turn subagent authorization. Preserve local dispatch primitives, the current Parallelism Premise, Return Status handling, and execution-time Interception Transparency; do not replace the whole workflow with the older market copy.

## 2026-07-09 - Minimal sufficient context route intake

- Status: superseded by 2026-07-17 - Simplify default scaffold and make integrity checks truthful
- Upstream commit: pending in this working tree
- Changed areas:
  - NEW `templates/skill/references/minimal-sufficient-context.md` — shared route-intake protocol: start from Always Read + route `required_reads` + workflow, expand context only on concrete signals, and escalate validation from command evidence to runtime/release evidence only when needed.
  - `templates/skill/SKILL.md.template` and `templates/skill/routing.yaml` — clarify that `required_reads` are core reads, not safety-blanket context; do not split routes/workflows into small/large variants.
  - `templates/skill/workflows/fix-bug.md` and `templates/skill/workflows/change-managed.md` — Read First sections now point to the shared protocol instead of broad default `rules/*.md` / `references/*.md` reads.
  - `templates/skill/conformance.yaml`, `templates/README.md`, `TEMPLATES-GUIDE.md` — register and document the new required reference.
- Why it matters: small tasks were paying the full skill cost because context, validation, and closure rigor were being encoded inside each workflow. This keeps workflow intent cores stable while route intake owns variable rigor. "Small" now means narrow context footprint, not weaker proof.
- Downstream refresh guidance: add the new reference, update generated SKILL/routing prose, and trim workflow Read First blocks that default to broad reads. Preserve project-specific validation commands, but move any generic light/heavy ladder out of individual workflows and into this shared route-intake protocol. Run `sync-routing.sh --check`, `smoke-test.sh`, and conformance against the refreshed upstream manifest.

## 2026-07-08 - Skill upgrade plan-only gate

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/update-rules.md` — adds a plan-only gate for high-impact skill upgrades: external-project absorbs, benchmark/eval lessons, major template/default scaffold changes, Always Read/routing behavior, or new reusable mechanisms must first produce an upgrade plan and stop until the user approves that exact plan. Also adds a net-benefit + validation gate before adding rules/workflows/references/hooks/scripts/templates.
  - `templates/skill/workflows/edit-templates.md` — points external absorbs and reusable mechanism changes to the plan-only gate before editing copied scaffold artifacts.
  - `references/scenario-testing.md` — adds a case split for skill upgrades: incident, candidate rule, regression case, boundary case, and holdout challenge; holdout is post-rule validation, not rule-design input.
- Why it matters: distilled from `compass-skills` without importing its personal task OS. The useful pattern is not task DAG/profile/session state; it is the lightweight discipline that large skill upgrades first surface candidates, rejected items, impact, activation path, net benefit, and validation before mutating shared scaffolds.
- Downstream refresh guidance: optional but recommended workflow update for projects that absorb external skill patterns or maintain shared scaffolds. No script, conformance, routing, or default harness behavior changed.

## 2026-07-08 - Hosted preview demo uses copy-paste input

- Upstream commit: pending in this working tree
- Changed areas:
  - `README.md`, `README.zh-CN.md`, `EXAMPLES.md` — hosted preview pointers now target `examples/simple-repo/COPY-PASTE-INPUT.md` and set expectation that the bundled demo is a minimal smoke-test input.
  - `examples/simple-repo/` — adds a single copy-paste input bundle and clarifies that hosted agents should not clone, fetch, or inspect the GitHub folder; README now states the generated output should be small because the fixture is intentionally tiny.
- Why it matters: Hermes-style hosted previews may block clone flows that try to clean `/tmp` paths, so the safe demo path must pass the small fixture as pasted context instead of asking the hosted agent to read a GitHub directory.
- Downstream refresh guidance: no downstream scaffold action. This is only an upstream README/examples demo-path clarification; projects that copied the previous hosted-preview wording may update it, but no templates, scripts, routing, or conformance behavior changed.

## 2026-07-08 - Skill authoring judgement checks

- Upstream commit: pending in this working tree
- Changed areas:
  - `references/layout.md` — description quality now includes a near-miss anti-trigger check: name similar user requests that should not activate the skill, or the domain is probably too broad.
  - `references/executable-skill-architecture.md` — adds a Degrees of Freedom classifier before promoting a skill toward script/CLI-first execution.
- Why it matters: borrowed from `skill-authoring` as lightweight judgement checks, not mechanisms. They help avoid over-broad activation and premature executable scaffolding without adding default workflow burden.
- Downstream refresh guidance: optional reference-doc update only; no template, conformance, script, or user-facing behavior change.

## 2026-07-07 - Black-box downstream scaffolding internals

- Upstream commit: pending in this working tree
- Changed areas:
  - `WORKFLOW.md` — Quick Start no longer references optional `.codex`, records a real `.upstream-sync` baseline from the upstream checkout, and frames remaining `FILL:` markers as agent migration work rather than user-facing setup.
  - `templates/skill/protocol-blocks/` — protocol blocks moved inside the copied skill tree; workflow links now resolve locally (`../protocol-blocks/...`) after scaffold. Runtime contract fields use `FIELD:` and optional seed rows use `OPTIONAL:` so downstream smoke tests do not treat internal forms as unfinished migration work.
  - `templates/skill/references/*`, selected workflows, and `SKILL.md.template` — empty seed logs / opt-in advanced sections switched from mandatory `FILL:` to `OPTIONAL:` to avoid fake content just to satisfy validation.
  - `templates/skill/scripts/upstream-status.sh` — missing or placeholder sync points now list the newest upstream entries for a first refresh instead of hard-failing before the agent can recover.
  - `scripts/check-all.sh` — upstream suite now instantiates a temporary downstream skill and runs downstream `sync-routing --check` + `smoke-test --phase 8`, catching scaffold-only failures that self-hosting checks miss.
  - `scripts/check-template-hooks.sh` + `scripts/README.md` — upstream-only SessionStart hook contract check verifies the template emits the right per-harness JSON shape and injects one unambiguous router; wired into `check-all.sh`.
  - `templates/README.md`, `TEMPLATES-GUIDE.md`, `workflows/upgrade-downstream.md`, `references/multi-skill-routing.md` — wording aligned around agent-owned internals and user-hidden update state.
- Why it matters: user-facing downstream setup should be "ask the agent to migrate/update" rather than making users understand `.upstream-sync`, protocol-block placement, optional seed logs, hook JSON shapes, or smoke-test internals. A sample downstream previously exposed `.codex` errors, broken protocol-block links, placeholder sync failures, and mandatory-empty `FILL:` markers despite upstream checks passing.
- Downstream refresh guidance: re-run `update-upstream.md`. Vendor sync will pick up scripts and protocol-blocks for tracking downstreams; manually port the Quick Start/docs wording only if the downstream keeps local copies. If a downstream still has placeholder `.upstream-sync`, the refreshed `upstream-status.sh` will show newest entries and the final update step will write the real sync point.

## 2026-07-06 - Downstream absorb (chaos): red/green bugfix loop, fork posture, §7 corrections

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/fix-bug.md` — **reproduce-first weak form**: new step 3 (express the bug as a repeatable check — test, script, or written manual sequence — and confirm it fails *for the reported reason* before touching code) and step 7 validates with the **same check** red→green; new **Final Report (to the user)** five-field template (root cause / change / verification / blast radius / uncovered risk). The root-cause-first gate is unchanged — reproduction precedes root-causing; the write-the-test-first strong form is deliberately NOT here.
  - `templates/skill/references/tests-as-spec.md` — new **"The bugfix loop (red → green)"** section: the opt-in strong form (acceptance test first, run red, same check green; escape hatch for the un-automatable).
  - `templates/skill/workflows/task-closure.md` — fresh-evidence gate extended one clause: **fresh command ≠ fresh artifact** (validation through a build product requires the product to postdate this task's source changes).
  - `templates/skill/workflows/update-rules.md` — explicit no-restating injunction (closure-gate content exists only in `task-closure.md`) + **escalation rung** in Activation Check: recorded + activated + *recurred* → promote to a machine gate inside the triggering tool (env-var escape hatch; verified recurrence only, imagined-pain rule applies doubly).
  - `templates/skill/workflows/plan-feature.md` — step 8 gains a **project-owned destination** extension point (e.g. product/domain facts → the project's own live docs library) gated on a read-back path; the "no fourth bucket" stance is unchanged.
  - `templates/skill/workflows/update-upstream.md` — new **Posture: tracking (default) vs fork** section: fork is legitimate with three named standing costs (frozen conformance contract, no mechanical vendor fixes, fork points must be registered locally).
  - `templates/skill/workflows/change-managed.md` + `fix-bug.md` FILL comments — a project may declare its cheapest-sufficient validation path (e.g. hot-reload dev server) and the conditions that escalate to the expensive one.
  - `references/skeleton-flesh-split.md` (self-hosting, not shipped) — §7: **checkout-coupling test** decides repo placement (subordinate to §1's abstraction test; the two axes may legally disagree on one item — the fat-jar gotcha is flesh by tier yet skill_root by coupling), owns-table corrected (`gotchas/` / `references/` may split across roots; on overlapping globs the path prefix is the contract), cross-repo write guard, repo-root machine-check blind spot + shared-fragment equality-check warning; §4: reading the hub ≠ reading the content (explicit no-hit declaration required).
  - `references/multi-skill-routing.md` (self-hosting, not shipped) — **defect-class exception** to the ambiguity ladder (bug ownership is a fact: short read-only intake, route by evidence, never primary-fallback; cross-skill bugs share one acceptance check) + shared-resources table: protocol-blocks caveat under two-root/assembled layouts + a shared-workflow-skeleton row (equality check or it is pseudo-dedup).
- Why it matters: first absorb from the chaos downstream (a productized fork since 2026-07-04) — downstream-proven patterns that passed the Borrowed-Pattern Acceptance Test. Rejected as flesh (recorded here so the review isn't re-litigated): mandatory four-file requirement dossiers, the eight-category product-knowledge taxonomy, hand-kept traceability ledgers, and core+shell duplicated workflow copies (absorbed only as the equality-check warning). The script-level fixes from the same review shipped separately — see the entry below.
- Downstream refresh guidance: `fix-bug.md` — cherry-pick step 3 / step 7 / Final Report into your copy if you customized it; the tests-as-spec bugfix section applies only if you opted into that reference; the update-upstream posture section is worth porting if any of your downstreams forked.

## 2026-07-06 - Script debt repaid: two-root layout support + pipefail hardening in vendored scripts

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/scripts/sync-routing.sh` — **two-root prefix awareness** (`skill:`/`code:` normalized in schema + path validation; `code:` paths skipped — the code_root's own tooling validates them) + **inline-YAML parsing** (`labels: { zh: … }`, `required_reads: [a, b]`, `trigger_examples: [a, b]`) + summary formatter tolerates a missing `route:`. Fixes a docs-promised/scripts-refused contract break: `routing.yaml`'s two-root comment and skeleton-flesh-split §7's worked example previously hard-failed (prefixes, inline labels) or silently dropped (inline trigger lists) under the shipped parser. Budget raised 340 → 400 (dated note in `templates/README.md`).
  - `templates/skill/scripts/smoke-test.sh` — accepts a skill **directory path** / cwd (meta-repo layouts like `apps/<app>/skills/<name>`; name read from SKILL.md frontmatter; `skills/$NAME` remains the fallback); **`path_resolution`-gated exemption** — thin-shell / Cursor-entry / `.mdc` absence downgrades fail→warn *only* when `routing.yaml` declares two roots (single-root behavior unchanged); internal sync-routing call passes `$SKILL_DIR` instead of `$NAME`; **pipefail fixes** per the script's own maintenance note — `DUPLICATE_HEADINGS` grep (a gotcha file with no `## ` headings silently killed the entire run), `MDC_COUNT` find, `GOTCHA_FILE` find. Budget note corrected (file had drifted to 903 unrecorded; now ≤ 950, next addition forces extraction).
  - `templates/skill/scripts/route-health.sh` — inline `trigger_examples: [a, b]` parsing (previously dropped silently → false no-trigger smells).
  - `templates/skill/scripts/route-reachability.sh` — stale pointer fixed: `rate-of-change-split.md` → `skeleton-flesh-split.md`.
  - `templates/skill/scripts/check-growth-health.sh` + `templates/README.md` — per-script budget caps updated in both (they are a pair; a pairing note now says so in the budget table).
- Why it matters: upstream debt, surfaced by the chaos downstream carrying local fixes for it — the docs (routing.yaml two-root comment, skeleton-flesh-split §7 worked example) promised a layout and syntax the shipped scripts rejected or silently mis-parsed, and smoke-test violated its own pipefail maintenance rule (a whole run could die silently). Parser ideas absorbed from chaos's local patches, re-reviewed line-by-line; chaos's unconditional fail→warn downgrades were NOT taken (exemption here is gated on `path_resolution` presence).
- Downstream refresh guidance: all five files are vendor-class — `sync-vendor.sh` picks them up mechanically. Single-root downstreams: every change is a no-op for your layout except the pipefail fixes — take them. Two-root downstreams: this release makes the shipped scripts actually support your layout; retire any local parser forks you carried.

## 2026-07-02 - Permission model (opt-in): operation-authority engine + design↔operation double helix

- Status: superseded by 2026-07-17 - Simplify default scaffold and make integrity checks truthful
- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/references/permission-model.md` (**new, ships**) — the **operation axis** ("may the agent take this action?"), distinct from the design axis (code correctness: architecture/conventions/gotchas). **Not a list to match but a classifier you run** before any side-effecting op, keyed on **operation × target/environment** (the same action is 🟢 local/reversible, escalates against prod/shared/irreversible). Contents: the 3-question classifier (🔴 refuse / 🟡 propose-and-stop-*before*-acting / 🟢 default-not-a-list), tier semantics, the **🟡 proposal format** (the 5 things a stop must surface — else "stop and ask" is inert), the **enforcement ladder** (prose → remove-material → pre-commit → CI; "in a doc" ≠ enforced = theater; machine layers only for real-baseline rules, imagined-pain guard), and the **two-axis double helix** — independent-but-paired with the design axis, bound by three rungs. *Additive≠breaking* and *target-decides* refinements are baked into the classifier. report-not-block (🟡 judged by the user; only 🔴 earns a machine gate). Orthogonal to Blast-Radius Buckets (path/closure-rigor) and the subagent Negative list (delegation) — three axes.
  - `templates/skill/workflows/task-closure.md` — **rung #2 (opt-in)**: a one-line operation-authority closure check ("were any 🟡/🔴 ops taken, each surfaced *before* acting? an unannounced 🟡 = a logged overstep") — the operation strand of closure, beside the design-strand AAR.
  - `templates/skill/workflows/update-rules.md` — **rung #3 (opt-in)**: a one-line cross-axis prompt at recording time (a code gotcha ↔ an operation tier; an operation incident ↔ a design convention).
  - `templates/skill/workflows/change-managed.md` — one-line opt-in pointer in step 1 (pre-execution check), disambiguated from post-edit blast-radius buckets.
  - `references/progressive-rigor.md` (self-hosting) — a short "Permission model (advanced)" note.
- Why it matters: a real, already-landed baseline (secrets committed to a downstream repo's history; a prod credential pasted into a session) showed a prose-only "never commit secrets" rule does not prevent the incident. This adds the whole **operation-authority axis** the skill lacked — it could answer "is the code right?" but never "may I act?" — as a cohesive subsystem (engine skeleton + one project table), cross-checked against the design axis at three rungs (classify / closure / growth). Genuinely new to SBA, generalizable.
- Downstream refresh guidance: `permission-model.md` ships as an optional reference (now an **engine**, not a bare tri-color note); the task-closure / update-rules / change-managed hooks are one-line opt-in pointers — no behavior change unless adopted. No conformance change. The **project's concrete 🔴/🟡 table lives in code_root** as ONE full-color file (columns: operation | tier | scope | enforcement now→target (🔴) | blast/why); operation-🔴 lives there, **not** in the design-prohibitions file. Machine enforcement (pre-commit, `.env.example`, CI) is separate consuming-repo infra.

## 2026-07-01 - Tests-as-spec discipline (opt-in): spec-first cases + human oracle + trichotomy

- Status: superseded by 2026-07-17 - Simplify default scaffold and make integrity checks truthful
- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/references/tests-as-spec.md` (**new, ships**) — the full opt-in discipline: (1) write the plan's **test cases at plan time** as the spec; (2) the cases are the **question-generator** that surfaces boundary/failure decisions to the human, who is the **correctness oracle** (the agent can't verify "right thing" against its own single mental model → false-green); (3) cases constrain implementation, realized as unit tests; (4) a failing test = the **trichotomy** (code wrong | case/understanding wrong; revise-with-reason, never edit-to-green); (5) **verification modes** — automated test for unit-testable logic, **human sign-off** for subjective/visual/UX (never machine-tested). Includes when-NOT-to-adopt + the **reports-not-blocks** model: not a blocking gate — the agent generates to spec + lists cases/results transparently, and the user makes the final acceptance call (tests verify code-vs-cases; the user verifies cases-vs-intent).
  - `templates/skill/workflows/plan-feature.md` — a **one-line opt-in pointer** after Task Breakdown (cases feed each task's `Acceptance`; frontend style → user); the substance lives only in the reference, so non-adopters carry ~zero weight in the default workflow.
  - `templates/skill/workflows/task-closure.md` — a **one-line opt-in pointer** under the fresh-verification gate (realize cases → run fresh → trichotomy → report for the user to judge; not self-certified).
  - `references/progressive-rigor.md` (self-hosting) — a short "Tests as spec (advanced)" note.
- Why it matters: recurring production incidents after only light testing are a real (pattern-level) baseline. Tests-as-spec forces coverage (shallow-test root cause) and human-oracle clarification forces correctness (false-green root cause) — the two roots of "under-tested → incident". Captured as **opt-in / not in `conformance.yaml`**: it fits unit-testable work with such a baseline (e.g. a backend), and would be imagined-pain to force on a downstream without one (or on non-unit-testable UI). Enforcement is **not a blocking gate**: the agent's duty is faithful generation + transparent reporting; the user makes the final acceptance call.
- Downstream refresh guidance: `tests-as-spec.md` ships as an optional reference; the plan-feature / task-closure hooks are opt-in pointers, no behavior change unless you adopt the discipline. No conformance change. There is no blocking gate — a project that adopts it makes the *discipline* (write cases → run → report) its norm, and the user judges acceptance.

## 2026-06-30 - Document the two-root split (skill_root / code_root, skill:/code: routing)

- Upstream commit: pending in this working tree
- Changed areas:
  - `references/skeleton-flesh-split.md` § 7 (new) — captures the cross-repo scaling of the 骨架/肉 axis: when a skill's skeleton is shared across code checkouts (or centrally assembled), split it across **two roots** on the same abstraction line — `skill_root` (元仓) owns SKILL.md/routing.yaml/architecture/rules/workflows (skeleton + entry + routing); `code_root` owns conventions/gotchas/references (flesh, lives in the code repo). `routing.yaml` joins them with a `path_resolution` block + `skill:` / `code:` path prefixes so one route composes both. Includes a worked example.
  - `references/progressive-rigor.md` — added a short "Two-root split (advanced)" note framing it as a deployment **topology** beyond Full (not more rigor), pointing at § 7.
  - `templates/skill/routing.yaml` — 2-line advanced comment noting the `skill:`/`code:` + `path_resolution` option; **default single-root layout unchanged**.
- Why it matters: the two-root design (skeleton upstream/shared, flesh in the code repo, joined by `skill:`/`code:` routing) was a genuinely good pattern that had evolved only in a downstream skill and was undocumented in SBA. It is the exact skeleton/flesh line drawn at the repo boundary — a natural extension of the existing axis, not a new concept. Captured as **advanced/optional** (most single-repo skills stay single-root) so it adds no ceremony to default scaffolds.
- Downstream refresh guidance: docs-only for the references (SBA-internal, not shipped). The only shipped change is the 2-line comment in `routing.yaml` — informational; no behavior change, no action needed unless you actually adopt a two-root layout.

## 2026-06-29 - audit-orphans now covers workflows/ (catches dead workflows)

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/scripts/audit-orphans.sh` — now also audits `workflows/` for orphan status (previously only `rules/`/`references/`/`architecture/`/`gotchas/`/`conventions/`; workflows were scanned only as inbound-link *sources*). A workflow reachable from no route (`routing.yaml` `workflow:`/`required_reads`), no sibling workflow, no rule, SKILL.md, or shell is now flagged. Workflows match by **basename** (not full rel path) because siblings cross-link by bare same-dir filename (`task-closure.md`) while routing uses the full path (`skill:workflows/task-closure.md`) — basename catches both; `.example` files and `README.md`/`index.md` are exempt.
  - `scripts/README.md` Check Suite Matrix — audit-orphans row updated to reflect workflow coverage.
- Why it matters: a downstream review found dead workflow files (a `profile-project.md` that was de-routed during customization but left behind) that **no gate caught** — `audit-orphans` skipped workflows and `route-reachability` only covers active content tiers. Structure ≠ used: the same blind spot the actionability dimension addresses, now closed for workflow files too.
- Downstream refresh guidance: `audit-orphans.sh` is a vendor-class script — it arrives via `sync-vendor.sh` on the next `update-upstream`, no manual edit. After it lands, run it; if it flags a workflow, either route it / cross-reference it from another workflow, or delete it.

## 2026-06-27 - Activation gate gains an actionability dimension (eval-derived)

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/update-rules.md` § Activation Check — the gate asked two questions (will the entry be *reached*?). Added a third: **when the agent reads it, does it change the next action?** A "correct-but-inert" entry (read, understood, then the agent proceeds identically) is reached but not activated. The rule line now reads "reached *and acted on*."
  - `SKILL.md` (self-hosting) — Principle 13 "Activation over storage" and Pitfall #4 sharpened the same way: reached-but-inert is a distinct failure from absent/unreachable, and no structural gate can see it — only judgment.
  - `templates/skill/workflows/update-rules.md` § When NOT to Record — added a **Goodhart guard**: content whose only purpose is to move an external metric/score is not recordable; an eval is a signal to improve the skill (run through the normal gates), never a target to optimize. Test: would you write it if the metric didn't exist? (Sibling of the imagined-pain pitfall.)
- Why it matters: an external evaluation (a downstream LLM-judge scoring per-session skill *utility*) exposed a real SBA blind spot — every SBA gate (smoke-test, audit-orphans, route-reachability, conformance) checks *structure* (present / reachable / on-route / within budget), so a skill can pass them all and still be functionally inert (triggered, read, but changes nothing the agent does). Structure ≠ utility. This folds the durable, project-agnostic half of that lesson back into SBA. Deliberately **not** scripted: actionability is a judgment call; a script that "checks usefulness" would be imagined-pain engineering.
- Downstream refresh guidance: small insert into `update-rules.md` § Activation Check (add the third question + reword the rule line); cherry-pick, keep local FILL content. No script, routing, or conformance change. SKILL.md principle edits are self-hosting-only — downstream skills carry their own SKILL.md.

## 2026-06-27 - Borrowed superpowers patterns + plan-structure overhaul

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/plan-feature.md` — three additions: (1) a **canonical Plan Skeleton** (Context → Problem → Options Considered → Chosen Approach → Requirements & Acceptance → Out of Scope → Task Breakdown → Open Questions), now the single source of truth for plan structure; (2) a **Task Breakdown** section — each task declares Files / Consumes / Produces / Acceptance (borrowed from superpowers `writing-plans`' interface declaration, *without* its bite-sized-code-block ceremony) and maps 1:1 onto a Mode 2 subagent contract; (3) a **Brainstorm — diverge before converging** section (≥ 2 distinct options; present design before the Task Breakdown for Large work); plus **立体 angle governance** (each angle file opens with `> Conclusion:`, `prd.md` carries a `## Synthesis` index). `docs/plans/_TEMPLATE.md` + `docs/plans/README.md` (self-hosting only) now point at this canonical skeleton instead of redefining it.
  - `templates/skill/workflows/task-closure.md` — **Fresh verification evidence gate**: no "tests pass / done" claim without running the command in the same message and reading its exit code; a hedge word ("should/probably/seems") before a status claim is the tell. Added as a sub-point of protocol step 1 + a Rationalizations row + a Red Flag.
  - `templates/skill/workflows/fix-bug.md` — **Three Strikes** section: after 3 failed fixes, stop and question the architecture/premise instead of a 4th symptom patch; + a checklist item.
  - `templates/skill/protocol-blocks/subagent-contract.md` + `templates/skill/workflows/subagent-orchestration.md` + `templates/skill/workflows/subagent-driven.md` — **Worker Return Status** vocabulary (`DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED`, adapted from superpowers): the contract block carries the return word, orchestration Phase 4 routes on it, and the Mode-2 router + Phase 1 cross-link the plan's Task Breakdown → contract handoff (lift Files/Consumes/Produces/Acceptance with zero re-derivation).
  - `templates/skill/workflows/receiving-review.md` — **NEW workflow**: acting on code-review feedback with anti-sycophancy (no "you're absolutely right"), verify-before-implement, YAGNI check, push-back-with-evidence. Routed in `templates/skill/routing.yaml`.
- Why it matters: a comparative pass over the superpowers plugin (6.0.3) found SBA and superpowers had largely converged; the net borrow is a small surgical set of mechanisms SBA genuinely lacked. The plan-structure overhaul fixes three real defects — plans were requirements docs with flat step checklists (no executable task decomposition), the self-hosting `_TEMPLATE.md` and the `plan-feature.md` prose described two divergent skeletons, and 立体 angle files had no index/conclusion contract.
- Downstream refresh guidance:
  - `plan-feature.md` is the big one — diff and port the Plan Skeleton + Task Breakdown + Brainstorm sections; preserve any project-specific complexity-gate rows or validation steps. Conformance phrases (Complexity Gate / Question Gate / Gate A–C / Complex Plan / prd.md / workflow-state:planning) are unchanged.
  - `task-closure.md` / `fix-bug.md` / `subagent-orchestration.md` — small inserts; cherry-pick into the local file, keep local FILL content.
  - `receiving-review.md` is a **new optional workflow** — copy it in if the project does code review, add the `receiving-review` route to local `routing.yaml`, then re-run `sync-routing.sh`. It is intentionally NOT in `conformance.yaml` (not mandatory).
  - After porting: `sync-routing.sh`, `smoke-test.sh`, `audit-orphans.sh`, `route-reachability.sh`.

## 2026-06-24 - Content axis re-based on skeleton/flesh (abstraction over rate-of-change)

- Upstream commit: pending in this working tree
- Changed areas:
  - `SKILL.md` Content Classification + Target Structure: the axis is now **abstraction (骨架 invariant theory vs 肉 current-code facts)**, not rate of change. `architecture/` = abstract design theory only (layering/contract/orchestration **principles**) — **the module map / dir layout / call graph are flesh and move to `references/`**. `workflows/`+`rules/` = skeleton; `conventions/`+`gotchas/`+`references/` = flesh.
  - `references/rate-of-change-split.md` → renamed `references/skeleton-flesh-split.md`; §1 reframed around the judgement test (*after a refactor that renames modules / moves files, is it still true? → skeleton; describes current code → flesh*) + a fifth bucket (**code maps → references/**). Rate of change demoted to a heuristic note (it mislabels slow-drifting maps as architecture). §2–§6 mechanics unchanged.
  - `references/progressive-rigor.md` trigger 3, `references/layout.md`, `TEMPLATES-GUIDE.md § Classification Guide` — aligned to abstraction; module map → `references/`.
  - `templates/skill/workflows/task-closure.md` — added a non-script **skeleton purity** review: a new `architecture/` file that is a map/name/path of the current code is flesh → `references/`.
- Why it matters: tiering by rate of change conflated two stable-ish things — the abstract skeleton (invariant) and slow-drifting code maps (flesh) — so module trees landed in `architecture/`, making it diverge (re-describing the code) and drift instead of converging on the few invariant principles. Abstraction is the real cut; the skill holds both skeleton and flesh but no longer mixes them.
- Downstream refresh guidance: move module trees / directory layouts / call-graph maps out of `architecture/` into `references/` (mark them "drifts with refactor"); keep only invariant principles in `architecture/`. Re-run `audit-orphans` + `route-reachability` (paths change, reachability shouldn't). Mostly docs; no script behavior change beyond the renamed reference + the task-closure prompt.

## 2026-06-24 - plan-feature: depth scales with complexity + a Large tier with multi-perspective (立体) analysis

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/plan-feature.md` — Complexity Gate gains a **Large** tier (multi-subsystem / irreversible / high-uncertainty) above Complex; new **Large Plan — analyze from several angles (立体)** section: plan depth scales with task complexity, and a Large task is examined from several lenses (architecture / risks / alternatives / contracts / integration / rollout / decomposition), each its own file, with `prd.md` as the short synthesis/index. Lenses are an independent-analysis menu → optional parallel dispatch as Mode 2 subagents. Completion Checklist gains a Large-plan depth item.
- Why it matters: every anti-bloat lever ("keep `prd.md` short", "one file is correct and complete", "don't pre-create files") pushed only toward minimalism, with no counter-pressure for genuine largeness — and the Complexity Gate capped at a flat "Complex", so a multi-subsystem architecture change and a 3-file change got identical treatment. Result: real Large tasks shipped 100-line single-file plans (under-analysis). The Large tier + depth-scaling reconciles with the anti-bloat rules — `prd.md` stays short; the depth moves into warranted angle files, which is exactly the existing "add siblings only when the task needs them" rule applied to a task that needs them.
- Downstream refresh guidance: `plan-feature.md` is project-owned (not vendor-class), so this does not auto-propagate. Port the Large tier + Large Plan section into your skill's `workflows/plan-feature.md` if your project takes on multi-subsystem planning.

## 2026-06-24 - NEW route-reachability.sh — guarantees active-tier files are activated, not just link-reachable

- Upstream commit: pending in this working tree
- Changed areas:
  - NEW `templates/skill/scripts/route-reachability.sh` (vendor-class) — from `routing.yaml` (always_read + required_reads + route text) it transitively follows hub-navigation edges (a routed file listing another file's skill-root-relative path) and asserts every active-tier file (`architecture/` `conventions/` `gotchas/` `rules/`) is in the reachable set. `references/` `docs/` (lookup tiers) and `workflows/` (routed by `workflow:` + covered by `check-cross-references.sh`) are exempt. Exit 1 on any unreachable file.
  - `templates/skill/sync-manifest.yaml` — added (vendor-class).
  - `templates/skill/workflows/task-closure.md` — path-integrity gate now runs it next to `audit-orphans.sh` (whenever a content file is added or routing changes).
  - `scripts/README.md` — documented in all three matrices; `references/rate-of-change-split.md` § 6 added it to the validation list.
- Why it matters: `audit-orphans.sh` only proves a file is *link*-reachable (its path is mentioned somewhere — e.g. the `SKILL.md` manifest). A fine-grained split can leave a file link-reachable but on **no task route** — "stored, not activated", pure waste. Real case: `architecture/transactions-locks.md` passed audit-orphans but no route led there, so transactional work never read the transaction invariants. This check closes that gap and is the enforcement behind the `references/rate-of-change-split.md` § 4 "route the hub, not every file" rule.
- Downstream refresh guidance: vendor-class — re-vendor via `sync-vendor.sh`. Run after adding any `architecture/`/`conventions/`/`gotchas/`/`rules/` file or changing routing; also wired into the task-closure path-integrity gate.

## 2026-06-24 - Distilled the rate-of-change split playbook from the chaos pilot (real-use feedback)

- Upstream commit: pending in this working tree
- Changed areas:
  - NEW `references/rate-of-change-split.md` — playbook for splitting an existing skill's tiers by rate of change, distilled from doing it twice on a real code-coupled skill: the **four** buckets (incl. methodology stays in `rules/`), verbatim-no-duplication authoring, **split-is-a-path-migration** (repoint / stub / delete every old-path reference), **every fine-grained tier needs a routed `index.md` hub** (link-reachable ≠ route-reachable: a file in the `SKILL.md` manifest but on no task route is stored-not-activated waste — the gotchas-hub pattern generalized to `architecture/`+`conventions/` with a "read when" column; route the hub, not every file), orphan-inbound mechanics (root-relative inline-code = inbound; relative `[]()` link = smoke-test link check), **routing re-derivation** (the `fix-bug`-reads-pitfalls-but-not-the-rule failure), validation, the assembled/vendored-copy trap, and the "batch ~4 concurrent" subagent-fanout note (avoids `ECONNRESET`).
  - `references/progressive-rigor.md` — trigger 3 now names all four buckets and that `rules/` keeps methodology; links the playbook.
  - `SKILL.md` Content Classification — header notes `rules/` keeps cross-cutting agent-behavior; links the playbook.
  - `references/layout.md`, `workflows/full-migration.md` (Phase 6) — link the playbook.
- Why it matters: the framework taught the rate-of-change *axis* but not the *mechanics*. Real use surfaced load-bearing gaps the docs didn't cover — methodology has no architecture/conventions home (the 4th bucket), a split breaks every old-path reference, per-module gotchas silently orphan without a hub registered as root-relative inline-code, and routes go incoherent if `required_reads` aren't re-derived across the new tiers.
- Downstream refresh guidance: documentation only; no script/behavior change. Read `references/rate-of-change-split.md` before splitting a tier.

## 2026-06-23 - Content Classification re-tiered by rate of change (architecture/ conventions/ gotchas/)

- Upstream commit: pending in this working tree
- Changed areas:
  - `SKILL.md` — Content Classification table + Target Structure now teach the rate-of-change axis: stable structure → `architecture/`, volatile house style → `conventions/`, code-coupled landmines → per-module `gotchas/` (+ `gotchas/index.md` hub); Progressive Rigor gained a "split `rules/` by rate of change" trigger.
  - `references/progressive-rigor.md` — Full-tier layout + upgrade triggers updated (recurrence → per-module `gotchas/`; new "rate-of-change tangle" trigger → split `rules/` into `architecture/`+`conventions/`).
  - `references/layout.md`, `TEMPLATES-GUIDE.md` § Classification Guide — aligned to the new tiers.
  - `templates/skill/scripts/smoke-test.sh` — `routing.yaml` cap 120 → 140 (tiered skills route to more files per task); SKILL.md body-overflow hint lists the new tiers.
- Why it matters: the old `rules/` (normative) vs `references/` (background) split is orthogonal to rate of change, so stable architecture and volatile gotchas tangled in the same files — every volatile edit re-touched stable material and refactors churned files that should stay put. Tiering by rate of change keeps the stable spine small/cacheable/always-read and isolates volatile detail so refactors and conformance only touch the volatile set.
- Downstream refresh guidance: NOT a forced migration. `rules/` stays a valid content tier (the tooling — audit-orphans / footprint / check-cross-references / sync-routing / smoke-test — already treats all tiers). Adopt the split when a `rules/` file tangles stable + volatile or a subsystem's gotchas pile up; worked split in `references/progressive-rigor.md`. Re-vendor the scripts (vendor-class) to pick up the cap + tier coverage.

## 2026-06-23 - footprint / check-cross-references / sync-routing / smoke-test made tier-aware

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/scripts/footprint.sh` — read-everything baseline now sums `.md` under every content tier (`architecture/` `gotchas/` `conventions/` added to `rules/` `workflows/` `references/`); tiered skills were previously undercounted.
  - `templates/skill/scripts/check-cross-references.sh` — workflow→content extraction and reverse lookup now match all content tiers, not just `(rules|references)/`.
  - `templates/skill/scripts/sync-routing.sh` — `always_read` path-prefix allowlist now accepts `architecture/` `gotchas/` `conventions/` (previously rejected an always-read architecture spine).
  - `templates/skill/scripts/smoke-test.sh` — 1a-gotchas recognizes a `gotchas/` directory (preferred) as the gotchas surface; the line-cap + duplicate-`## `-heading scan (2a) now also covers `gotchas/*.md` (skips `gotchas/index.md`); 1a-rules now accepts a constraint surface in `rules/` OR `architecture/` OR `conventions/` (was hardcoded to `rules/project-rules.md` + `rules/coding-standards.md`, which a skill that split `rules/` by rate of change no longer has); routing.yaml cap raised 120 → 140 and the SKILL.md body-overflow hint lists the new tiers.
- Why it matters: companion to the audit-orphans tier fix below. These four still enumerated only `rules/`+`references/`, so a skill that adopted `architecture/`/`gotchas/` got an undercounted footprint, missed cross-reference staleness, a rejected always-read spine, and an unenforced gotchas line cap — the new taxonomy was only half-enforced.
- Downstream refresh guidance: all four are vendor-class (`sync-manifest.yaml`); re-vendor via `sync-vendor.sh`. No behavior change for skills that never adopted the new tiers — the extra dirs simply don't exist and are skipped.

## 2026-06-23 - audit-orphans covers all content tiers + scans routing.yaml

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/scripts/audit-orphans.sh` — generalized from `rules/`+`references/` to all content tiers (`rules/` `references/` `architecture/` `gotchas/` `conventions/`) via a `TIER_DIRS` array (existence-guarded — partial-tier skills behave exactly as before); added `routing.yaml` as an inbound-link source, so a file referenced only from a task's `required_reads` counts as reachable (whether that route can match is still route-health's job). 92 lines (was 84).
  - `templates/skill/workflows/task-closure.md` (path-integrity gate line), `templates/README.md`, `scripts/README.md` — wording updated from "rules/ or references/" to "content-tier" to match the new coverage.
- Why it matters: a skill that organizes gotchas/architecture/conventions into their own directories previously had ZERO orphan protection on exactly those files — the old script only audited `rules/`+`references/` and only counted inbound links from those dirs, so a new gotcha/architecture file could be created, never routed, and silently rot with no closure gate catching it. The mandatory path-integrity gate now actually covers the tiered structure.
- Downstream refresh guidance: re-vendor `scripts/audit-orphans.sh` (vendor-class in `sync-manifest.yaml`; `sync-vendor.sh` overwrites an unedited local copy). After splitting content into `architecture/` / `gotchas/` / `conventions/` and wiring routing, run `(cd skills/<name> && bash scripts/audit-orphans.sh)` — any new-tier file with no inbound link from a workflow, another tier file, or `routing.yaml` now fails the gate.

## 2026-06-23 - Downstream token/latency cut: dedupe required_reads + split agent-behavior.md

- Status: superseded by 2026-07-30 - Evidence-driven workflow and delayed domain routing
- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/routing.yaml` — removed always_read files (`project-rules` / `coding-standards` / `agent-behavior`, including the `rules/*.md` glob) from per-route `required_reads`; routes now list only route-specific files (only `update-rules` keeps `gotchas` + `behavior-failures`). Added a FILL note stating the rule.
  - `templates/skill/SKILL.md.template` — regenerated ROUTING_SUMMARY via `sync-routing.sh` (de-duped routes now show "reads none"); no hand edits.
  - `templates/skill/rules/agent-behavior.md` — split: the 6 principles + ✓ Checks stay always-read (100 → 85 lines); origin / admission-threshold / Observable-Signals audit moved out.
  - `templates/skill/references/agent-behavior-meta.md` — NEW; holds the moved meta, read only when editing the rule.
- Why it matters: cuts what a downstream pays per task/session with zero function loss. Re-listing an always_read file inside a route's `required_reads` forced a redundant re-read of already-resident content (worst case the `rules/*.md` glob re-pulled ~6.8 KB of `agent-behavior.md` on every change task). Splitting `agent-behavior.md` trims ~400–500 tok off the always-read floor every session and frees cap headroom.
- Downstream refresh guidance: in your `routing.yaml`, drop any always_read file re-listed in a route's `required_reads` (keep genuinely route-specific reads), then run `scripts/sync-routing.sh <name>`. If you customized `rules/agent-behavior.md`, port the split — keep your principles always-read, move origin/admission/observable-signals into `references/agent-behavior-meta.md` and link it from the rule. Re-run `smoke-test.sh`.

## 2026-06-23 - ANTI-TEMPLATES.md: Borrowed-Pattern Acceptance Test (four gates)

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/ANTI-TEMPLATES.md` — new "Borrowed-Pattern Acceptance Test" section (recurrence / generativity / distinctiveness / boundary) that gates any externally-borrowed mechanism before the existing cost gate; maps the existing "would two real projects disagree?" test to the distinctiveness gate.
- Why it matters: sharpens the templates admission gate for the recurring "should we copy X from an admired project?" decision; distilled from a comparison with an external meta-skill.
- Downstream refresh guidance: optional, no code/behavior impact. If your project maintains its own `ANTI-TEMPLATES.md` or admission gate, consider adding the four-gate test for borrowed patterns.

## 2026-06-15 - plan-feature.md: Decision-Completeness scan (distilled from a downstream plan review)

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/workflows/plan-feature.md` — new "## Decision Completeness
    (≠ section completeness)" subsection (after Complex Steps) + 3 Completion
    Checklist lines. Cues a plan author to check four recurring *decisions* that
    pass section-level checks but bite at execution: (1) external-dependency
    failure behavior (unreachable/timeout/5xx, fail-open vs fail-closed) — not
    just the config-missing branch; (2) schema/contract changes carrying a
    concrete migration/DDL artifact in the repo's existing convention, with
    unique-key column nullability/type pinned, not a prose field list; (3)
    cross-file consistency in multi-file dossiers (including "see Dx" refs that
    now contradict Dx); (4) Open-Questions hygiene — track unresolved decisions
    incl. failure modes, and don't bury a blocker under a "non-blocking" header.
    Deliberately does **not** add a mandatory test-plan or observability section.
- Why it matters: distilled from a real downstream complex-plan review. A
  structurally complete dossier (every required section present) still omitted
  its single most consequential failure-mode decision (external service
  unreachable), shipped a load-bearing table as prose with no DDL against a repo
  that has a hand-written migration convention, and let two sibling files
  contradict each other (one citing the very decision it reversed). Section-
  completeness ≠ decision-completeness; the smoke-test cannot detect a *missing*
  decision, so the cue lives in the planning workflow itself.
- Downstream refresh guidance: if your downstream keeps a local plan-feature
  workflow, port the Decision-Completeness subsection + the 3 checklist lines;
  the cues are universal (no project terms). Preserve any project-specific
  question gates. If your executing workflow makes backend tests opt-in, keep it
  — this change deliberately does not mandate a test section.

## 2026-06-10 - sync-vendor.sh + sync-manifest.yaml: mechanical vendor sync + wrong-checkout guard

- Upstream commit: pending in this working tree
- Changed areas:
  - **NEW `templates/skill/sync-manifest.yaml`** — machine-readable list of
    vendor-class files (all `scripts/*` + the manifest itself): byte-identical
    upstream copies that downstream must not edit.
  - **NEW `templates/skill/scripts/sync-vendor.sh`** — mechanical vendor sync.
    Base = the upstream version at your `.upstream-sync` `synced_sha` (read from
    upstream git history — no new state files): local == base → provably
    unedited → auto-update to upstream HEAD; local != base → LOCAL-EDIT,
    reported, never overwritten; missing → NEW, copied; gone upstream →
    DROPPED, reported. Dry-run by default, `--apply` writes. Replaces the
    per-file hand-archaeology of update-upstream steps 5–7 for scripts.
  - `templates/skill/scripts/upstream-status.sh` — wrong-checkout guard: scans
    sibling `git worktree` checkouts for `.upstream-sync`. No pointer here but
    a sibling has one → "WRONG CHECKOUT?" stop-warning (the stale-copy case);
    sibling pointer with a different `synced_sha` → divergence warning.
  - `templates/skill/workflows/update-upstream.md` — new step 0 (verify you are
    in the skill-maintenance checkout before porting); step 5 rewritten to run
    sync-vendor.sh (manual scan remains only for non-vendor mechanism files);
    Hard Rule #4 + step 4 note the vendor-class subset; step 6 scoped to
    non-vendor files.
- Why it matters: every refresh × every downstream re-paid "which files do I
  copy whole" reading plus per-script git archaeology, and the changelog's
  prose guidance grew with every entry — the sync tax scaled with time and
  with the number of adopters. The vendor manifest machine-izes the file
  classification update-upstream step 4 already described in prose. The
  wrong-checkout guard mechanizes a real 2026-06-08 incident (an upgrade ran
  in a stale business-branch checkout and had to be rolled back).
- Downstream refresh guidance: copy `sync-manifest.yaml` +
  `scripts/sync-vendor.sh` once by hand (this is the bootstrap case), re-vendor
  `scripts/upstream-status.sh`, and port the update-upstream.md step changes
  (step 0, step 5, Hard Rule #4 — preserve your local FILLs). From the next
  refresh on, step 5 is one command instead of a file-by-file comparison.

## 2026-06-10 - Budget pass: extract subagent-orchestration.md; fix stale harness table

- Upstream commit: pending in this working tree
- Changed areas:
  - **NEW `templates/skill/workflows/subagent-orchestration.md`** — Mode 2's
    four phases (Plan / Dispatch / Two-Stage Review / Merge-or-Reject) +
    Degraded Mode, extracted verbatim from `subagent-driven.md` (which was 299
    lines vs its 250 budget). `subagent-driven.md` (now 223) keeps the mode
    router: triggers (§ Mode 2: When to Invoke), Iron Law, Parallelism Premise,
    Negative list, Interception Transparency, shared Rationalizations / Red
    Flags, plus a pointer to the new file.
  - Cross-refs repointed to `subagent-orchestration.md`: `refactor-fanout.md`
    (Phase 1 / Phase 3 + top banner), `fix-bug.md` (hypothesis fan-out contract
    format), `references/subagent-verification.md` (Phase 1 + Degraded Mode).
    `plan-feature.md`'s § Mode 2 trigger anchor still resolves (heading stayed).
  - `templates/skill/workflows/refactor-fanout.md` — its local Harness
    Compatibility table contradicted `subagent-driven.md` (still listed Codex
    as degraded; stale since the 2026-05-21 Codex global-authorization change).
    Replaced with a pointer to the canonical table.
  - Budget trims, no semantic change: `SKILL.md.template` body 93 → 90 (merged
    redundant comment blocks), `plan-feature.md` 105 → 100 (compressed the
    non-canonical-filenames example block).
  - `templates/README.md` + `check-growth-health.sh` — sync-routing.sh cap
    320 → 340 recorded with rationale; new budget rows for
    `sync-vendor.sh` / `sync-manifest.yaml`; `subagent-orchestration.md` added
    to the ≤ 100 workflow row; scripts tree listing completed (footprint /
    route-health / upstream-status had aged out of the doc).
- Why it matters: the upstream enforces budgets on downstream skills while
  carrying its own overages — that asymmetry erodes the budgets' credibility.
  Mode 1 / Mode 2 also pass the Self-maintenance split test (independently
  navigable; readers usually want exactly one), and the stale harness table
  was actively misinforming Codex users following refactor-fanout.
- Downstream refresh guidance: mirror the extraction in your local copy —
  create `workflows/subagent-orchestration.md` from your local
  `subagent-driven.md`'s Mode 2 phases + Degraded Mode (preserve local edits
  and language; same pattern as the 2026-05-29 task-closure extraction), leave
  the trigger section + shared rules in `subagent-driven.md`, add the pointer,
  then repoint your local Phase 1 / Phase 3 / Degraded references (grep for
  `subagent-driven.md` Phase and § Degraded). If your harness-compat tables
  were copied per-workflow, replace them with pointers to the canonical one.
  No routing.yaml change required (routes still enter via subagent-driven.md);
  no conformance.yaml change (neither file carries must_contain entries).

## 2026-06-08 - Subagent verification patterns: adversarial verify + loop-until-dry

- Upstream commit: pending in this working tree
- Changed areas:
  - **NEW `templates/skill/references/subagent-verification.md`** — two
    harness-agnostic patterns that extend `subagent-driven.md`'s two-stage
    review from *worker compliance* to *output correctness + discovery
    completeness*: (1) **adversarial verification** — for an uncertain finding
    (bug / security / research claim), dispatch N independent verifiers each
    contracted to *refute* it, default-to-refuted, keep only on majority
    survival; perspective-diverse variant gives each verifier a distinct lens.
    (2) **loop-until-dry** — for open-ended discovery (no known task-list size),
    dispatch finder rounds, dedup against all-seen, stop after K empty rounds;
    multi-modal rounds + no-silent-caps. Both carry an explicit "when NOT to
    reach for these" (mechanically-checkable output or bounded task list → the
    existing single review is enough).
  - `templates/skill/workflows/subagent-driven.md` — Phase 3 (Two-Stage Review)
    gains a one-line pointer to the new reference for the judgment / discovery
    case (compliance review necessary but not sufficient).
- Why it matters: the existing subagent surface (`subagent-driven.md`,
  `refactor-fanout.md`) is built for **decomposable known work** and reviews
  **worker compliance** (did it follow the contract). It had no pattern for the
  case where the worker's *conclusion* may be plausible-but-wrong, or where the
  problem has *no known size* — exactly the gap a multi-agent "exhaustive mode"
  fills. Distilled to the two harness-agnostic patterns; the harness-specific
  orchestration API (Claude Code's `Workflow` / parallel-`Task` fan-out
  primitives) is deliberately **excluded** per `ANTI-TEMPLATES.md` § "Subagent
  type registries / harness-specific dispatch code" — predefining one harness's
  dispatch API would lie to every other harness.
- Downstream refresh guidance: copy `references/subagent-verification.md` whole
  (project-agnostic) and add the Phase 3 pointer line to your local
  `subagent-driven.md`. No `routing.yaml` or `conformance.yaml` change required
  — these are optional optimization patterns, not safety contracts (same posture
  as `refactor-fanout.md`). On harnesses with no parallel / background dispatch,
  the patterns degrade to sequential verifier passes — you keep the adversarial /
  loop discipline, you lose the parallelism. If your project has never needed
  adversarial verification or open-ended discovery, skip the file and re-pull
  when the situation actually appears.

## 2026-06-08 - smoke-test.sh: activate hook / stuffing / conformance checks

- Upstream commit: pending in this working tree
- Changed areas:
  - `templates/skill/scripts/smoke-test.sh` — three new checks, all closing
    gaps where a real downstream (`chaos`) drifted while passing the old
    smoke-test:
    - **1d SessionStart hook (WARN)** — when `.claude/` exists but no
      `SessionStart` hook is wired in `.claude/settings*.json`, warn (Pitfall
      #7: routing silently drops after `/clear` or `/compact`). Never fails —
      harness-dependent.
    - **4c-stuffing (WARN)** — description with > `$DESCRIPTION_MAX_TRIGGERS`
      (default 12) quoted phrases is flagged as workflow-keyword stuffing
      (Pitfall #3 / Principle #7). The old check only caught *too few* (< 2)
      quoted phrases; this catches *too many*.
    - **Section 9 Content Conformance (FAIL)** — if a `conformance.yaml` exists,
      run `check-version-conformance.sh` so the one check people run after every
      change also catches *content* drift (e.g. a renamed "Task Closure
      Protocol"). Skipped silently when no manifest. Runs in full / `--phase 8`
      only — not in `--phase 7`, so `check-all` self-hosting verify is unaffected.
  - `templates/skill/scripts/check-growth-health.sh` — raised `smoke-test.sh`
    soft cap 850 → 900 (the verifier legitimately grew by the three checks above).
- Why it matters: structural checks (files exist, links resolve, routing in sync)
  were gated and ran easily; the checks that catch hook/description/content drift
  existed but were manual ("stored, not activated"). A downstream passed
  smoke-test green while missing its hook, stuffing its description to 25 quoted
  phrases, and regressing a conformance-required phrase. These three additions
  move those checks onto the path that actually runs.
- Downstream refresh guidance: re-vendor `smoke-test.sh` and
  `check-growth-health.sh` from this upstream. §9 depends on the conformance
  checker, so re-vendor `check-version-conformance.sh` + `_parse_conformance.py`
  as a coupled set (if `conformance.yaml` is present but the checker is missing,
  §9 now WARNs rather than silently skipping). After re-vendoring, run
  `bash skills/<name>/scripts/smoke-test.sh <name>` (full, so §9 runs) — new
  WARNs/FAILs surface pre-existing drift; fix them (wire a SessionStart hook,
  trim the description, re-add any conformance-required phrase) rather than
  suppressing the checks. In multi-skill repos the §1d hook check is skill-aware:
  it only passes when a hook re-injects THIS skill's `skills/<name>/` router.
- Known remaining gap (by design, not yet closed): the hook (§1d) and stuffing
  (§4c) checks are WARN-only (harness-dependent / judgment), so re-drift of P1/P3
  is detected but non-blocking; only conformance (§9) is FAIL-gated. And
  smoke-test is still human/agent-triggered — no pre-commit or CI auto-runs it
  downstream. Pick a gate (pre-commit, closure-step, or periodic update-upstream)
  per project; a `SMOKE_STRICT=1` promote-WARNs-to-FAIL mode can be added when a
  CI consumer exists.
