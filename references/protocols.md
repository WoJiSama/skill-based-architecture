# Reference — Protocols & Verification

## Contents

- [Meta-Workflow Templates](#meta-workflow-templates)
- [Task Execution Protocol](#task-execution-protocol)
- [Task Closure Protocol](#task-closure-protocol)
- [Recording Threshold](#recording-threshold)
- [Where To Record](#where-to-record)
- [Recording Destination Guide](#recording-destination-guide)
- [Generalization Rule](#generalization-rule)
- [When References Alone Are Not Enough](#when-references-alone-are-not-enough)
- [Skill Activation Verification](#skill-activation-verification)

## Meta-Workflow Templates

The canonical workflow templates live under `templates/skill/workflows/`. Every project should adopt at least these:

- [`task-execution.md`](../templates/skill/workflows/task-execution.md) — cross-cutting task-start and progress contract: Simple/Managed/Design classification, Task Anchor state with proportional presentation, harness-native Plan, per-step Anchor Checkpoints, evidence-backed advancement, and replan/new-message gates.
- [`task-closure.md`](../templates/skill/workflows/task-closure.md) — cross-cutting closure gate (Task Closure Protocol, AAR, Rationalizations, Red Flags); referenced by every behavior-changing workflow at closure.
- [`update-rules.md`](../templates/skill/workflows/update-rules.md) — recording mechanics the gate calls into: threshold, fidelity, reconciliation, activation, destination durability, sync, and retirement.
- [`maintain-docs.md`](../templates/skill/workflows/maintain-docs.md) — independent-load-reason audit, semantic before/after reconciliation, file health, split/merge/index decisions, and reference integrity.

For a higher-level orientation and the minimal starter scaffold, see [`TEMPLATES-GUIDE.md`](../TEMPLATES-GUIDE.md).

## Task Execution Protocol

Canonical source: [`templates/skill/workflows/task-execution.md`](../templates/skill/workflows/task-execution.md).

Task Execution sits after route selection and before Task Closure. One clear action with one direct check stays Simple and pays no planning cost. Other tasks establish Task Anchor state: one observable Goal, Done When evidence, and material Boundaries only when present. That state is not a fixed chat template. Default Managed work uses a short natural-language alignment only when it helps the user verify direction; a visible native Plan owns step display and is not repeated in chat. Long, complex, scope-sensitive, confirmation-dependent, or no-native-Plan work may use one complete structured task brief. Before each main step and after correction, failed/surprising evidence, Subagent return, or interruption, a compact Anchor Checkpoint brings Goal, remaining Done When evidence, current-step output/check, and relevant Boundaries back into current attention. Before verification, bind material risk to fitted evidence and a stop/escalation condition; stop when that contract is satisfied rather than treating test count as evidence quality. It is Session recitation, not durable planning-file state.

The separation is load-bearing: Workflow owns the reusable domain procedure and mandatory gates; Task Anchor owns this task's outcome; Native Plan owns current runtime step state; Task Closure owns the final completion decision. A user-visible Plan may group Workflow steps but cannot replace the Workflow or weaken a gate. New independent tasks re-route and replace the old Anchor/Plan; refinements update the current one.

For the user-facing design and examples, see [`docs/task-anchor-native-plan.md`](../docs/task-anchor-native-plan.md).

## Task Closure Protocol

Canonical source: [`templates/skill/workflows/task-closure.md`](../templates/skill/workflows/task-closure.md#task-closure-protocol).

This reference deliberately gives only the operating summary: task closure
applies only when the **Trigger Policy** admits the task (code or doc was
changed); for those tasks, closure means main-work verification, the 30-second
AAR scan, and any triggered recording, path-integrity, route-path, cross-
reference, behavior-validation, or external-fact checks. Keep the exact gate
wording and trigger table in `task-closure.md` so the protocol does not drift
across guide/reference copies.

Verification freshness follows edits, not conversation boundaries: a recorded
result that postdates the final relevant edit remains valid after context
compaction. Closure consumes the task's cheapest-sufficient Done Contract; once
it is green and all triggered gates are handled, green is a stop condition, not
a reason to invent stronger checks.

**Pure Q&A, code explanation, read-only investigation, and advice with no file
changes are exempt** — do not enter the protocol, do not run AAR, do not run
`smoke-test.sh`. `smoke-test.sh` is a skill structure/routing/link validator,
not a default closure action for ordinary code changes or read-only work.

### Blast-Radius Buckets (closure trigger refinement)

The Trigger Policy table in `task-closure.md` asks "what kind of file changed?"
Blast-radius buckets give the **file-path classification** used to answer that
for this repo. Classification is by path alone — no content inspection, no
intent judgment.

**Bucket A — full closure (AAR + smoke-test + path-integrity gates):**

- `SKILL.md`
- `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md` (entry shells)
- `references/self-hosting-routing.yaml`
- `scripts/*.sh`
- `templates/skill/SKILL.md.template`, `templates/skill/routing.yaml`, `templates/skill/*.tpl`

**Bucket B — lightweight AAR only (no smoke-test):**

- `templates/skill/rules/*.md`
- `templates/skill/workflows/*.md` (excluding `*.example`)
- `references/*.md` linked from `SKILL.md` body (`progressive-rigor.md`,
  `multi-skill-routing.md`, `skill-composition.md`, `layout.md`,
  `protocols.md`)
- `workflows/full-migration.md`

**Bucket C — skip closure entirely:**

- `README.md`, `README.zh-CN.md`
- `examples/**`
- `docs/**`
- `UPSTREAM-CHANGES*.md`
- `templates/skill/workflows/*.md.example`
- `references/*.md` not linked from `SKILL.md` body

**Bucket rules:**

- **Multiple files in one task** → take the max bucket (A > B > C). One A-bucket edit anywhere in the task pulls the whole closure into A.
- **Path not in any list** → default to B (conservative). Promote to A or C in the next routing maintenance pass.
- **Trivial edit in an A-bucket file** (typo, whitespace, comment) still triggers full closure. The bucket measures **what could break**, not **what changed semantically**. Letting the model judge "real vs trivial" is unreliable; the rule is mechanical by design.

The bucket lists are **per-repo** — they encode this repo's blast-radius
layout. A downstream project using the meta-skill maintains its own list under
the same A/B/C headings, anchored in its own `references/protocols.md`.

> **Reconcile tip (gate 3)**: before writing a recorded lesson, run `bash scripts/skill-asset where <keywords>` to surface existing sections that may already cover the topic. Avoids duplicate sections accumulating across files. See [`scripts/README.md`](../scripts/README.md) for `where` / `related` / `group` usage.

### AAR Scan

Use the canonical questions and exemptions in
[`templates/skill/workflows/task-closure.md`](../templates/skill/workflows/task-closure.md#after-action-review).
Do not maintain a second question list here.

## Recording Threshold

Record only when at least 2 of these 3 are true:

1. **Repeatable** — likely to recur in future work
2. **Costly** — missing it wastes meaningful time or causes real regressions
3. **Not obvious from code** — a future reader would not infer it quickly from implementation alone

Typical high-value records:

- framework lifecycle gotchas
- registration timing pitfalls
- hidden routing dependencies
- non-obvious synchronization or state reset requirements

Skip recording:

- one-off workarounds
- style preferences
- facts already obvious from existing code
- content already well covered by official docs and not project-specific

Passing the threshold is only admission. Before writing, follow the three canonical gates in [`update-rules.md`](../templates/skill/workflows/update-rules.md): preserve decision-bearing meaning (**fidelity**), integrate/correct/retire existing knowledge before adding (**reconciliation**), and prove an action-changing task path (**activation**).

## Where To Record

*Operating summary — canonical: [`update-rules.md`](../templates/skill/workflows/update-rules.md) § Where To Record. Keep the two in sync when destinations change.*

Use the lightest useful destination:

- Stable constraint or convention → `rules/`
- Pitfall, lifecycle gotcha, architecture note, source index → `references/`
- Stable project-specific macro business types, flows, states, boundaries, or invariants → routed `references/business/<module>.md`; only current effective semantics, using the cross-implementation stability test
- Ordered task step or completion check → `workflows/`
- Task routing changed → `routing.yaml`, then `scripts/sync-routing.sh`
- Always-read set changed → `routing.yaml`, then `scripts/sync-routing.sh`
- Tool entry routing or Always Read changed → `routing.yaml`, then regenerate thin-shell generated blocks (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`)

Prefer integrating into the closest existing entry/section over creating a parallel entry or file. Create a new file only when a real task selects it independently and activation points to it.

## Recording Destination Guide

*Operating summary — canonical: [`update-rules.md`](../templates/skill/workflows/update-rules.md) § Recording Destination. Keep in sync.*

When the user explicitly asks to "record this", "remember this", or "save this for later", the agent must decide where to store the knowledge. Many AI tools (Claude Code, Gemini CLI) have their own memory systems (e.g., `~/.claude/projects/.../memory/`) that auto-load each session. These compete with the skill's documentation structure.

**Decision test:** "Would a different agent or person working on this same project benefit from this knowledge?"

| Answer | Destination | Examples |
|---|---|---|
| **Yes** — project-level knowledge | `skills/<name>/references/`, `rules/`, or `workflows/` | Technical patterns, conventions, pitfalls, architecture notes |
| **No** — personal/user-level knowledge | Agent's own memory system (`~/.claude/.../memory/`, etc.) | Communication preferences, personal shortcuts, user-specific context |

**Default to skill docs.** In practice, most "record this" requests during development are technical and project-scoped. The agent's own memory should only be used for content that is truly personal and would not help another contributor.

Apply the same threshold plus fidelity/reconciliation/activation gates as AAR-initiated recordings. If the user says a business-model candidate is for “later”, keep it only in the current session; do not create a memory entry, file, directory, index, or placeholder route.

## Generalization Rule

Use the durability test that matches the destination:

- Generic rules, workflows, architecture notes, and gotchas must remain useful in another project of the same type: `specific finding → reusable pattern → consequence`.
- Business global models are intentionally project-specific; require **cross-implementation stability** instead. If modules/classes are renamed and APIs, storage, or frameworks are replaced, the macro business statement must still hold.

Do not erase legitimate business names merely to satisfy cross-project reuse, and do not admit code names/fields/paths into a business model merely because they are project-specific.

For worked examples of good vs bad records, see [`templates/skill/workflows/update-rules.md`](../templates/skill/workflows/update-rules.md) (the canonical Generalization Rule section).

## When References Alone Are Not Enough

Recording a pitfall in `references/` preserves it, but does **not** guarantee a future task will read it.

If a lesson is both:

- **costly** enough to repeatedly waste meaningful time, and
- **task-relevant** to a recurring workflow such as fixing bugs, adding pages, adding renderers, or wiring multi-step integrations

then do **not** leave it buried in `references/` only. Also surface it in at least one activation path:

- add or update a completion check in the relevant `workflows/*.md`
- update `routing.yaml` so generated Common Tasks and thin-shell blocks point at the pitfall/reference file
- if the lesson is really a stable constraint, promote a concise summary into `rules/`

Rule of thumb:

- `references/` stores the explanation
- `workflows/` prevents omission at task closure
- `routing.yaml`-generated `SKILL.md` Always Read, Common Tasks, and thin-shell bootstraps make the right file more likely to be read

If a future agent could still miss the lesson while following the normal task path, the knowledge is stored but not yet activated.

## Skill Activation Verification

Phase 8 checks structural correctness; full runtime activation still needs human judgment. `smoke-test.sh` now partly automates two of these — it WARNs on a missing SessionStart hook (Pitfall #7, §1d) and on a keyword-stuffed description (§4c). The rest below remain manual. Use these additional checks after migration.

### Description Quality Check

| Check | Pass criteria |
|---|---|
| Length | ≥ 20 words or ≥ 40 CJK characters |
| Trigger phrases | At least 2 quoted trigger phrases in the user's actual language(s) (e.g. "refactor project rules", "重构项目规则") |
| Format | Third-person: "This skill should be used when…" |
| Scope | Coarse domain / intent-cluster activation; not "helps with development" and not a list of every workflow |
| Specificity | Mentions concrete activation conditions, not just category labels |

A description that fails these checks may silently never fire — the skill exists but the Agent never picks it up.

Re-read the `description` block aloud after editing frontmatter. Listen for over-broad scope, workflow keyword stuffing, missing quoted phrases in the user's actual language, and (in multi-skill repos) duplicate trigger phrases shared with another skill. The earlier `check-description-routing.sh` script was removed in 2026-05 — it parsed 125 lines of YAML to surface things a human eyeballs in 30 seconds; the discipline is content judgment, not a tooling gap.

### Routing Coverage Check

Verify that `SKILL.md` Common Tasks covers the project's actual task distribution:

1. List the 5–10 most common task types in the project
2. For each, confirm `routing.yaml` has a matching entry with correct file routing
3. If a common task is missing, add it — uncovered tasks fall through to the generic "Other" route and may miss important rules/references
4. Run `scripts/sync-routing.sh --check` so generated `SKILL.md` Always Read / Common Tasks and thin-shell blocks cannot drift
