# scripts/

Tooling for the skill-based-architecture project — both upstream maintenance scripts (this directory) and the canonical check suite shipped to downstream skills (under `templates/skill/scripts/`). The matrix below is the single source of truth for **which check covers which gap and when to run it**.

## Check Suite Matrix

Each retained check covers a different blocking drift dimension. Scripts under `templates/skill/scripts/` are also delivered to downstream skills.

### Drift dimensions

| Dimension | Question it answers | Check |
|---|---|---|
| Routing source-of-truth (downstream) | Did SKILL.md / shells drift from first-workflow `routing.yaml`? Is optional `domain-routing.yaml` non-empty, owner-complete, and delayed; do cross-owner refs pass workspace-root validation? | `sync-routing.sh --check [--workspace-root <path>]` |
| Shell + activation source-of-truth (self-hosting) | Did this repo's root shells drift from generated content, or `skill.yaml` description drift from `SKILL.md`? | `check-self-shells.sh` |
| Template hook runtime contract | Does `templates/hooks/session-start` emit the right per-harness JSON shape and inject at most one router? | `check-template-hooks.sh` *(upstream-only)* |
| Self-hosting manifest route proof | Does a named prompt literal, route row, and first-workflow target stay synchronized without eager task reads? This is static manifest proof, not Agent behavior. | `check-self-scenarios.sh` (upstream-only) |
| Self-hosting shell/bootstrap/link subset | Do the root harness shells, Cursor rule shell, session hook, and markdown links remain usable? This does not scan intentional template markers as a downstream Skill. | `check-all.sh` (upstream-only subset) |
| Responsibility-aware structure | Does `SKILL.md` pass its universal checks, and does every actually materialized routing, rule, workflow, shell, Cursor, link, budget, and fitted conformance owner satisfy its own contract? | `smoke-test.sh` + `check-validation-contract.sh` + real direct/folder/broad journeys in `check-all.sh` |
| Upgrade lifecycle | Does a fitted result remain unchanged on same-version refresh, update only selected vendor files, retain declared owners, and apply current fitted checks? | Existing lifecycle fixtures in `check-all.sh`; `render-fitted-conformance.sh` is shared with first materialization |
| First-migration evidence integrity | Does Quick Start preview without writes, preserve existing entries, give every inventoried source clause one mapped/excluded disposition, preserve verbatim clauses, and connect mapped content to an activation chain? | `scaffold-downstream.sh` + `check-migration-evidence.sh` + the existing-project journey in `check-all.sh` *(upstream-only)* |
| Live Agent behavior | Can a real Codex instance complete both a fresh-project Single-file task and the ordinary code-first SBA migration prompt, including evidence-backed rule migration and fitted smoke? | `check-live-agent-journey.sh --mode single-file|migration` or `check-all.sh --live-agent` *(opt-in; network/auth/model dependent)* |
| Orphan content-tier + workflow files | Recursively scan `rules/`/`references/`/`architecture/`/`gotchas/`/`conventions/`/`workflows/` for zero inbound links. Workflows match by basename; both task workflows and delayed domain owners count as routing roots | `audit-orphans.sh` |
| Unactivated task files | Active-tier files, `workflows/`, and nested `references/business/` leaves on no task route/overlay — link-reachable but never read (stored-not-activated) | `route-reachability.sh` |
| **Fitted content conformance** | Did a materialized owner omit a phrase or reintroduce an anti-pattern promised by the manifest fitted to that result? | `check-version-conformance.sh <skill> [--conformance <fitted-manifest>]` — supports `must_contain` + `must_not_contain`; the current `templates/skill/conformance.yaml` is specifically the complete scaffold contract |
| **Content presence (upstream-canon)** | Does THIS repo still teach what its templates promise? | `check-version-conformance.sh . --conformance references/self-hosting-conformance.yaml` |
| UPSTREAM-CHANGES coverage | Downstream-facing edit landed without an update note? | `check-upstream-changes.sh` *(upstream pre-commit)* |

### Where each script lives

| Script | Path | Audience |
|---|---|---|
| `check-all.sh` | `scripts/` | Upstream maintainer — orchestrator that runs the full gate before commit/push |
| `check-validation-contract.sh` | `scripts/` | Upstream-only — proves valid Single-file and complete scaffold results are judged by their own responsibilities, and rejects marker laundering |
| `check-migration-evidence.sh` | `scripts/` | Upstream/Agent migration helper — validates clause disposition, verbatim preservation, review evidence, and activation-chain integrity from a session-scoped JSON manifest |
| `check-live-agent-journey.sh` | `scripts/` | Upstream-only, opt-in — named Single-file and ordinary-migration Codex black-box modes; exit 3 means external transport/auth/model access unavailable, not a behavior verdict |
| `check-template-hooks.sh` | `scripts/` | Upstream-only (validates hook template runtime output without installing hooks) |
| `check-self-shells.sh` | `scripts/` | Upstream-only (calls `sync-self-shells.sh --check` + validates SKILL.md/skill.yaml description identity) |
| `check-self-scenarios.sh` | `scripts/` | Upstream-only (static self-hosting manifest route proofs) |
| `check-upstream-changes.sh` | `scripts/` | Upstream-only (UPSTREAM-CHANGES.md guard) |
| `check-upstream-supersedes.sh` | `scripts/` | Upstream-only (validates `Status: superseded by` refs in UPSTREAM-CHANGES{.md,-archive.md}) |
| `scaffold-downstream.sh` | `scripts/` | Upstream Quick Start materializer — target-evidence inventory, fitted owner/harness selection, dry-run preview, collision/symlink guard, preserved existing entries, staged apply, and rollback of newly created paths |
| `sync-self-shells.sh` | `scripts/` | Upstream-only (generates root shells from `self-hosting-shell-base.md` + `self-hosting-shells.yaml`) |
| `render-fitted-conformance.sh` | `scripts/` | Upstream-only, stdout-only renderer shared by scaffold and upgrade; reads the existing fitted owner declaration and emits current applicable checks without changing project files |
| `skill-asset` | `scripts/` | Upstream-only consolidation helper; it is not copied by the scaffold |
| `smoke-test.sh` | `templates/skill/scripts/` | Downstream — Phase-aware structural gate |
| `sync-routing.sh` | `templates/skill/scripts/` | Downstream — `routing.yaml` is the source of truth |
| `audit-orphans.sh` | `templates/skill/scripts/` | Downstream + upstream — finds zero-inbound content-tier + workflow files |
| `route-reachability.sh` | `templates/skill/scripts/` | Downstream + upstream — finds active-tier/workflow files on no task route |
| `check-version-conformance.sh` | `templates/skill/scripts/` | Both — runs against any skill root + manifest |

### When to run what

| Trigger | Recommended check |
|---|---|
| Upstream maintainer about to commit | `bash scripts/check-all.sh` (deterministic structure and contract gate; does not claim live Agent behavior) |
| Upstream maintainer needs a real behavior signal | `bash scripts/check-all.sh --live-agent`; treat exit 3 as unavailable external evidence, never as a product pass or behavior failure |
| Upstream maintainer pre-commit hook | `bash scripts/check-all.sh --staged` |
| Upstream maintainer added `must_contain` / `must_not_contain` to `templates/skill/conformance.yaml` | Mirror the same anchor into `references/self-hosting-conformance.yaml` if a self-hosting file teaches the same protocol |
| Downstream just materialized | Run only the fitted checks that exist; direct/folder results do not need Full-only scripts, while an emitted `smoke-test.sh` validates every declared owner |
| Existing project migration | Agent builds a session-scoped clause inventory and runs `check-migration-evidence.sh --root <project> --manifest <temp-json>`; faithful rewrites still require the recorded semantic review |
| Downstream `update-upstream` | `smoke-test.sh` + `check-version-conformance.sh` against a manifest fitted to the owners actually materialized; refresh materializer-fitted declarations with `render-fitted-conformance.sh`, preserve custom assertions, and never apply the complete-scaffold manifest to a correct fitted result |
| Downstream doc edit | `audit-orphans.sh`; add `route-reachability.sh` when routing/activation changed |
| Downstream added a content file or split a tier | `route-reachability.sh` (is it actually on a route?), `audit-orphans.sh` |
| Suspected description hit-rate problem | Read SKILL.md description aloud; does it use the user's actual phrases? `routing.yaml` `trigger_examples` is the place to add more — no script substitute for human re-read. |

### Anti-pattern: bypass the matrix and add a new orphan check

For a two-root skill, run `audit-orphans.sh` and `route-reachability.sh` once per root with `--namespace skill|code --routing <skill-root>/routing.yaml`; zero-argument mode remains the single-root contract.

Cross-owner business reads are separate from the two-root skeleton/flesh split. Declare project-owned workspace-relative roots in `owner_roots`, reference them as `owner:<owner-id>:<path>`, and pass the real workspace root to `sync-routing.sh --check`. A check without that root reports target existence as unverified; project assembly should provide the argument so ordinary users do not configure it.

Every check above has a one-sentence "what gap it covers". Before adding a new check script, confirm none of the existing ones already cover it. If genuinely new, add it to this matrix and wire it into `check-all.sh` in the same commit.

`check-all.sh` intentionally ends with a bounded claim. Default green means deterministic structure, mapping-integrity, and contract checks passed. It does not mean a model followed the instructions. `--live-agent` adds two explicit named black-box journeys (Single-file task and ordinary SBA migration), and even those results prove only the named harnesses, prompts, workspaces, and terminal checks.

The reverse anti-pattern is just as expensive: shipping a script that *expects a protocol no one will follow* (e.g. requiring authors to hand-mark each external fact with a `<!-- verified=YYYY-MM-DD -->` comment so a script can check freshness). If the precondition is a discipline you cannot reasonably enforce, the script will run empty forever — that is "stored, not activated" in script form. Five such scripts (`check-external-facts.sh`, `test-trigger.sh`, `check-description-routing.sh`, `audit-references.sh`, `audit-route-paths.sh`) were removed in May 2026; see UPSTREAM-CHANGES for context before reintroducing anything similar.

---

## `skill-asset`

AAR-time consolidation helper. Surfaces existing sections that may overlap with a new lesson, before it's written into a rule file. Pure read-only — never modifies markdown.

### Three commands

| Command | Purpose |
|---|---|
| `where <keyword>...` | Suggest where a new lesson should be placed (ranked candidate sections) |
| `related <keyword>...` | Search all rule files for sections matching keywords |
| `group` | Scan all `##` headings and detect topic-similar sections across different files (duplicate-topic detector) |

### Quick examples

```bash
# When AAR identifies a new lesson, ask: where does this belong?
./scripts/skill-asset where renderAmis 第二参数 createObject

# When you want to see every place a topic is discussed
./scripts/skill-asset related "z-index"

# Periodic doc-health check: any topics scattered across files?
./scripts/skill-asset group
```

### Global flags

| Flag | Default | Purpose |
|---|---|---|
| `--top N` | where=5, related=10, group=20 | Limit number of results |
| `--json` | off | Emit JSON instead of human-formatted output (for piping or hook integration) |
| `--help`, `-h` | — | Print usage and exit |

### Search scope

The CLI looks in this order:

1. `./skills/`, `./rules/`, `./references/`, `./workflows/` (preferred — the canonical layout)
2. Top-level `*.md` (fallback for projects that don't use the structured layout)

### What the CLI does NOT do

- ❌ Detect stale rules (semantic obsolescence is unsolvable by tooling alone)
- ❌ Auto-write or auto-edit anything — it only **surfaces candidates**, the author decides
- ❌ Require frontmatter on rule files — operates on plain markdown content

### Exit codes

| Code | Meaning |
|---|---|
| 0 | Normal (including "no matches found") |
| 2 | Argument error |

## Integration into your workflow

The intended use is during **AAR / Task Closure Protocol**: when a new lesson has been identified and the author is about to record it, run `skill-asset where <keywords>` to surface candidate destination sections and avoid duplicate sections accumulating across files.

Optional ways to wire it in:

- Add a step to your `update-rules.md` workflow: "Before appending, run `./scripts/skill-asset where <keywords>` and check if the lesson belongs in an existing section."
- Run `./scripts/skill-asset group` periodically (e.g., before a release) to catch duplicate-topic sections that have crept in.
- Hook it into a maintenance script (`check-all.sh`-style) so duplicate detection runs on every CI build.

### Group output: heuristic, not authoritative

The `group` command reports **potential** topic-similar sections based on heading-token overlap. **Some matches are intentional**:

- Each `references/<topic>.md` having its own `## Anti-patterns` section is a valid cross-cutting pattern, not a duplicate to merge
- Same `## When To Use` heading across different `executable-skill-architecture.md` and `multi-skill-routing.md` reflects parallel reference structure, not redundancy

The CLI prints a footer disclaimer reminding the user to treat results as **candidates for review**, not commands to merge. Use it as a signal to *look*, not as a rule to *act*.

## Tests

`./scripts/test.js` provides smoke tests covering all commands, flags, error codes, frontmatter handling, BOM stripping, CJK tokenization, and the group disclaimer.

```bash
node scripts/test.js
```

## Requirements

- **Node.js 16+** (uses stdlib + `Intl.Segmenter` for CJK word segmentation)
- On Node 14 / 15, the CLI still runs but falls back to whitespace-only tokenization, which produces poor `group` results for Chinese-heavy projects.

## License

Same as the parent project.
