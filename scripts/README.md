# scripts/

Tooling for the skill-based-architecture project — both upstream maintenance scripts (this directory) and the canonical check suite shipped to downstream skills (under `templates/skill/scripts/`). The matrix below is the single source of truth for **which check covers which gap and when to run it**.

## Check Suite Matrix

Each check covers a different drift dimension. The columns are intentional: a check that's "report-only" never blocks a build, and a check that lives in `templates/skill/scripts/` is **also delivered to every downstream skill** when they scaffold.

### Drift dimensions

| Dimension | Question it answers | Check |
|---|---|---|
| Routing source-of-truth (downstream) | Did SKILL.md / shells drift from `routing.yaml`? | `sync-routing.sh --check` |
| Shell + activation source-of-truth (self-hosting) | Did this repo's root shells drift from generated content, or `skill.yaml` description drift from `SKILL.md`? | `check-self-shells.sh` |
| Template hook runtime contract | Does `templates/hooks/session-start` emit the right per-harness JSON shape and inject at most one router? | `check-template-hooks.sh` *(upstream-only)* |
| Routing trigger coverage | Do `trigger_examples` actually route to the intended workflow? | `check-self-scenarios.sh` (upstream-only) |
| Structural budgets + content | SKILL.md dual budget (desc ≤ 25 + body ≤ 90), FILL/placeholder residue, broken links, SessionStart-hook presence, description keyword-stuffing, and content conformance (§9, when `conformance.yaml` exists) | `smoke-test.sh` |
| Growth pressure | Are files growing past evaluation thresholds? | `check-growth-health.sh` *(report-only)* |
| Orphan content-tier + workflow files | `rules/`/`references/`/`architecture/`/`gotchas/`/`conventions/`/`workflows/` files with zero inbound links (link-reachable). Workflows match by basename (sibling same-dir links + routing `workflow:`/`required_reads` both count); a workflow on no route and referenced by no other workflow is dead weight | `audit-orphans.sh` |
| Unactivated content files | active-tier files (`architecture/`/`conventions/`/`gotchas/`/`rules/`) on no task route — link-reachable but never read (stored-not-activated) | `route-reachability.sh` |
| Cross-references | Broken inline markdown link targets | `check-cross-references.sh` |
| **Content presence (downstream)** | Did downstream forget to copy a mandatory upstream section/phrase? | `check-version-conformance.sh <skill> --conformance <upstream-clone>/templates/skill/conformance.yaml` — also run by `smoke-test.sh` §9 against the skill's own `conformance.yaml` |
| **Content presence (upstream-canon)** | Does THIS repo still teach what its templates promise? | `check-version-conformance.sh . --conformance references/self-hosting-conformance.yaml` |
| UPSTREAM-CHANGES coverage | Downstream-facing edit landed without an update note? | `check-upstream-changes.sh` *(upstream pre-commit)* |

### Where each script lives

| Script | Path | Audience |
|---|---|---|
| `check-all.sh` | `scripts/` | Upstream maintainer — orchestrator that runs the full gate before commit/push |
| `check-template-hooks.sh` | `scripts/` | Upstream-only (validates hook template runtime output without installing hooks) |
| `check-self-shells.sh` | `scripts/` | Upstream-only (calls `sync-self-shells.sh --check` + validates SKILL.md/skill.yaml description identity) |
| `check-self-scenarios.sh` | `scripts/` | Upstream-only (self-hosting trigger routing) |
| `check-upstream-changes.sh` | `scripts/` | Upstream-only (UPSTREAM-CHANGES.md guard) |
| `check-upstream-supersedes.sh` | `scripts/` | Upstream-only (validates `Status: superseded by` refs in UPSTREAM-CHANGES{.md,-archive.md}) |
| `sync-self-shells.sh` | `scripts/` | Upstream-only (generates root shells from `self-hosting-shell-base.md` + `self-hosting-shells.yaml`) |
| `skill-asset` | `scripts/` | Both — AAR consolidation helper (ships to downstream) |
| `smoke-test.sh` | `templates/skill/scripts/` | Downstream — Phase-aware structural gate |
| `sync-routing.sh` | `templates/skill/scripts/` | Downstream — `routing.yaml` is the source of truth |
| `check-growth-health.sh` | `templates/skill/scripts/` | Downstream + upstream |
| `audit-orphans.sh` | `templates/skill/scripts/` | Downstream + upstream — finds zero-inbound content-tier + workflow files |
| `route-reachability.sh` | `templates/skill/scripts/` | Downstream — finds active-tier files on no route (link-reachable but not activated) |
| `check-cross-references.sh` | `templates/skill/scripts/` | Downstream |
| `check-version-conformance.sh` | `templates/skill/scripts/` | Both — runs against any skill root + manifest |
| `_parse_conformance.py` | `templates/skill/scripts/` | Helper for `check-version-conformance.sh` (no standalone use) |

### When to run what

| Trigger | Recommended check |
|---|---|
| Upstream maintainer about to commit | `bash scripts/check-all.sh` (full gate) |
| Upstream maintainer pre-commit hook | `bash scripts/check-all.sh --staged` |
| Upstream maintainer added a `must_contain` to `templates/skill/conformance.yaml` | Mirror the same anchor into `references/self-hosting-conformance.yaml` if a self-hosting file teaches the same protocol |
| Downstream just scaffolded | `bash skills/<name>/scripts/smoke-test.sh <name>` |
| Downstream `update-upstream` | `smoke-test.sh` + `check-version-conformance.sh <skill> --conformance $tmp/upstream/templates/skill/conformance.yaml` (use upstream's manifest, NOT local — the local file is a snapshot from initial scaffold) |
| Downstream doc edit | `audit-orphans.sh`, `check-cross-references.sh` |
| Downstream added a content file or split a tier | `route-reachability.sh` (is it actually on a route?), `audit-orphans.sh` |
| Suspected description hit-rate problem | Read SKILL.md description aloud; does it use the user's actual phrases? `routing.yaml` `trigger_examples` is the place to add more — no script substitute for human re-read. |

### Anti-pattern: bypass the matrix and add a new orphan check

Every check above has a one-sentence "what gap it covers". Before adding a new check script, write the gap in that form and confirm none of the existing ones already cover it. If yes, extend the existing one. If genuinely new, add it AND a row in this matrix AND wire it into `check-all.sh` in the same commit — the conformance check itself is the cautionary tale: it shipped a release ahead of being wired in, so for one cycle it was "stored, not activated" (Pitfall #4 in [SKILL.md](../SKILL.md)).

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
