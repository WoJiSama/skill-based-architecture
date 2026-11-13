# Migration Workflow

Step-by-step procedure for restructuring a long SKILL.md or scattered rules into Skill-based architecture.

## Quick Start

Quick Start has one ordinary-user action: let the Agent inspect the target and
materialize the smallest complete carrier for the evidence it finds. The Agent
does not ask the user to choose Single-file, Folder-light, Full, a profile, a
capability pack, or an install mode.

### Evidence-selected shape

The shape is an implementation result, not a user option:

| Target evidence | Typical carrier | What is admitted |
|---|---|---|
| One small task, no independent procedure or maintenance pressure | `direct` / Single-file | `SKILL.md` owns the sole route and direct completion behavior; no empty `routing.yaml` |
| A small rules surface or one recurring procedure | `folder` / Folder-light | Only the detected rule/procedure owners and the supported entry/registration surfaces |
| Multiple independently selected tasks, harnesses, managed execution, Closure, fitted validation, or upstream pressure | `broad` / routed | `routing.yaml` plus only the workflows, lifecycle owners, checks, and harness surfaces admitted by evidence |

The names above describe the generated result for diagnostics; they are not
installation tiers the user manages. A project may later grow a new owner or
route through normal maintenance when a real pressure appears. Use the full
9-phase procedure only when the migration itself needs that deeper analysis or
pressure-test; it does not prescribe a universal output tree.

**Step 1 — Profile and inventory before writing.** Read the upstream [`templates/skill/workflows/profile-project.md`](templates/skill/workflows/profile-project.md), then inspect the target repository before creating scaffold files. Begin with a read-only code/config/rule scan: inspect README and build/package files, CI, entry points, configs, module layout, tests, existing instruction entries (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/workflow.mdc`, and project-specific equivalents), and existing harness Skill registrations. Their meaning must be migrated instead of overwritten.

- For an ordinary request such as `用 SBA 整理这个项目的规则`, do not ask whether the user wants to brainstorm before this scan. The Agent owns discoverable implementation facts and technical destinations; the user does not select a structure tier, harness package, or file layout.
- Classify conclusions as `Confirmed from code/config`, `User-confirmed desired truth`, `Inferred`, or `Unknown`. Treat a clear user answer, selection, rejection, or correction as the highest-authority input for the corresponding normative product/business decision, but not as proof of current implementation. Preserve its question/context and establish current implementation facts from local evidence.
- Ask only when evidence cannot resolve a normative product/business decision, permission boundary, support scope, preserved behavior, or acceptance choice whose alternatives would change durable rules or materialized responsibilities. State the evidence-backed working conclusion and ask the user to correct or choose against it; never ask for a current implementation fact or an Agent-resolvable technical destination.
- If no such user-owned ambiguity remains, continue directly to preview and apply. Keep non-material uncertainty labeled `Unknown`; keep searching when an unresolved technical fact could change the materialization result.
- An explicit brainstorm request may calibrate desired meaning, but it does not replace code/config verification before stable rules are written. A conflict with a confirmed mainline invokes [`task-execution.md` § User Decision Drift Gate](templates/skill/workflows/task-execution.md#user-decision-drift-gate); this migration workflow owns the immediate pause/consult action, not the gate's complete resolution procedure.
- Only after this evidence and decision boundary is closed may project content be written into `rules/`, `workflows/`, `references/`, and `SKILL.md`. Normative business rules may come from faithfully preserved user-confirmed decisions with provenance; technical/current-state claims require code/config evidence.

After the evidence scan, product projects may present **business-global-model candidates**: modules whose stable types, macro flow, states, boundaries, or invariants are repeatedly needed and not obvious from code. Explain why each candidate matters and ask `model now / later / not needed`. Only `now` adopts `workflows/profile-business-model.md.example` and creates a routed model after evidence search + user calibration. `later` and `not needed` create no file, directory, index, route, or persistent queue.

**Step 2 — Preview and apply the materializer.** The upstream command is the only Quick Start write path. It defaults to a read-only evidence inventory and preview, reports every create/preserve/conflict decision, rejects reruns over an existing skill, stages before apply, and never overwrites existing project entry files.

```bash
# Assumes skill-based-architecture is cloned as a sibling, or $UPSTREAM points at it.
UPSTREAM="${UPSTREAM:-../skill-based-architecture}"
NAME="<name>"          # project identifier, kebab-case
SUMMARY="<one-line project summary>"

# Read-only preflight. Existing entries are reported as PRESERVE.
bash "$UPSTREAM/scripts/scaffold-downstream.sh" \
  --target "$PWD" --name "$NAME" --summary "$SUMMARY"

# Apply only after the Agent has inspected the inventory and profile evidence.
bash "$UPSTREAM/scripts/scaffold-downstream.sh" \
  --target "$PWD" --name "$NAME" --summary "$SUMMARY" --apply
```

The inventory is evidence, not a completed migration. For every `PRESERVE` row,
the Agent owns the semantic merge: extract durable project rules into the
selected owners, keep only entry-specific instructions in the thin shell, and
integrate the generated routing bootstrap without dropping old meaning. Do not
ask the user to compare files or decide technical destinations that project
evidence can establish. Before declaring migration complete, trace each
decision-changing source clause to exactly one migrated/merged destination or
an explicit exclusion reason in the current session evidence.

**Why a materializer instead of raw copy?** Inline heredoc generation lost
sections, while `cp -R templates/shells/. .` silently replaced real project
instructions and copied author-only machinery into every project.
`scripts/scaffold-downstream.sh` inventories evidence first, selects canonical
carriers and only admitted owners, previews the path plan, creates only missing
entry files, records the upstream baseline when maintenance pressure exists,
and rolls back newly created paths if apply fails. Existing entry content
remains untouched until the Agent performs the evidence-backed semantic merge.

**Step 3 — Fill content.** Two kinds of placeholders, two different mechanisms:

| Marker | How to fill |
|---|---|
| `{{NAME}}`, `{{SUMMARY}}` | Done by the scaffold command in Step 2 |
| `<!-- FILL: … -->` | Requires judgment — you must read each marker and write real project content |

Agent-facing check for pending project-specific content:

```bash
grep -rn 'FILL:' "skills/$NAME" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor
```

Every hit is mandatory for the agent before shipping the skill. A user should not have to interpret these markers; they are migration work items.

For a routed result, Always Read lists, the Common Tasks action hook, and shell
bootstraps are generated from canonical `skills/$NAME/routing.yaml`; exact task
rows remain only in that manifest. A direct Single-file result owns its sole
route in `SKILL.md` and has no independent routing manifest. Domain-free
projects omit `domain-routing.yaml`; the first real business owner materializes
a non-empty manifest in the same change. Run the same command after either
manifest changes:

```bash
bash "skills/$NAME/scripts/sync-routing.sh" "$NAME"
```

Do not hand-edit generated Always Read / Common Tasks action-hook content in `SKILL.md` or generated blocks in thin shells. Domain entries remain out of those startup summaries and are validated only for delayed workflow use.

**Step 4 — Verify structure and migration evidence.** After all FILLs and preserved-entry merges are resolved, run the automated smoke test:

```bash
# Checks SKILL.md plus every routing/shell/workflow owner actually materialized.
bash "skills/$NAME/scripts/smoke-test.sh" "$NAME"

# Routing manifest drift check (also run by smoke-test when routing.yaml exists)
bash "skills/$NAME/scripts/sync-routing.sh" "$NAME" --check

# (Optional) Surface rules/ or references/ files with zero inbound links
(cd "skills/$NAME" && bash scripts/audit-orphans.sh)

# Agent-owned, session-scoped evidence; write the inventory to a temporary JSON
# file and do not commit it. The path is not a persistent downstream ledger.
MIGRATION_EVIDENCE_JSON="$(mktemp "${TMPDIR:-/tmp}/sba-migration-evidence.XXXXXX.json")"
trap 'rm -f "$MIGRATION_EVIDENCE_JSON"' EXIT
# The Agent writes the Step 1 inventory and Step 2 dispositions here before checking.
bash "$UPSTREAM/scripts/check-migration-evidence.sh" \
  --root "$PWD" --manifest "$MIGRATION_EVIDENCE_JSON"
```

`smoke-test.sh` validates only applicable structural responsibilities: `SKILL.md` is universal; separate routing, rules, workflows, harness entries, Cursor registration, and conformance are strict only when materialized. It rejects both unresolved `FILL:` markers and the historical `FILLED:` rename shortcut. A green result explicitly does **not** prove semantic migration or live Agent behavior.

When an entry moves to a different repository, workspace root, or installed skill, replay discovery from the directory where users actually start each affected harness. Use the Step 1 inventory to verify that each previously active shell, registration, and startup hook resolves to the current owner or has been retired after its unique instructions were reconciled. Include app subdirectories or other roots outside the skill when the harness discovers entries there. A valid installed skill and a hook's zero exit status leave discovery unverified if the old registration can still take precedence or the hook emits no required context.

The structural result does **not** prove that pre-existing user instructions survived. Migration completion still requires source-to-destination evidence for the Step 1 inventory; the evidence checker makes its disposition and activation integrity executable without replacing semantic review.

`check-migration-evidence.sh` makes the Step 1 inventory and Step 2 disposition executable without creating a permanent downstream ledger. Every decision-changing source clause receives exactly one mapping or exclusion. Verbatim mappings are machine-checked and must end on a complete activation chain. Faithful rewrites carry explicit review evidence; the checker verifies that evidence is present but does not claim that string search proves semantic equivalence.

For description-quality judgment (too narrow / weak or off-language trigger phrases) — re-read the `description` block aloud and check it uses the user's actual phrasing. `smoke-test.sh` now WARNs on the over-broad / keyword-stuffed case (> 12 quoted phrases), but no script substitutes for the rest of that judgment.

For complex migrations (large projects, heavily scattered rules), follow
[`workflows/full-migration.md`](workflows/full-migration.md) for the Phase 1–9
process. The procedure still derives its physical result from evidence.

## If a Phase Crashes

The scaffold command rolls back paths it created when apply itself fails. If interruption happens later during Agent-led content migration, do not rerun the scaffold over the existing skill: inspect `git status --short`, compare the current source-instruction inventory with migrated destinations, and resume from the first unverified item. Existing entry files preserved by the scaffold remain the recovery source until their semantic merge is verified.

Use `bash skills/$NAME/scripts/smoke-test.sh $NAME --phase N` to verify a materialized phase before moving on. A Single-file result may pass without Full-only phases or files; a complete scaffold remains strict for every owner it materializes. If Closure pressure is admitted, Phase 9 is a manual attestation: at least one row in `workflows/task-closure.md` § Rationalizations to Reject came from a real pressure test. Otherwise run the fitted natural-language journey and do not create Closure machinery merely to satisfy the phase.

## Upgrading an Existing Downstream Project

When upstream releases new templates, hooks, scripts, or workflow improvements,
do **not** re-migrate. Use the agent-led upstream refresh path documented at
[`templates/skill/workflows/update-upstream.md`](templates/skill/workflows/update-upstream.md).
The user just says "上游项目更新了,帮我更新一下" or "update from upstream",
and the agent follows the downstream `skills/<name>/workflows/update-upstream.md`
owner only when that maintenance route was actually materialized.
