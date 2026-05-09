# scripts/

Tooling for the skill-based-architecture project — both upstream maintenance scripts (this directory) and the canonical check suite shipped to downstream skills (under `templates/skill/scripts/`). The matrix below is the single source of truth for **which check covers which gap and when to run it**.

## Check Suite Matrix

Each check covers a different drift dimension. The columns are intentional: a check that's "report-only" never blocks a build, and a check that lives in `templates/skill/scripts/` is **also delivered to every downstream skill** when they scaffold.

### Drift dimensions

| Dimension | Question it answers | Check |
|---|---|---|
| Routing source-of-truth (downstream) | Did SKILL.md / shells drift from `routing.yaml`? | `sync-routing.sh --check` |
| Routing source-of-truth (self-hosting) | Did this repo's root shells / `skill.yaml` description drift from `SKILL.md`? | `check-self-routing.sh` |
| Routing trigger coverage | Do `trigger_examples` actually route to the intended workflow? | `check-self-scenarios.sh` (upstream), `test-trigger.sh` (downstream) |
| Description activation | Is `description` over-broad, too narrow, or trigger-phrase-less? | `check-description-routing.sh` |
| Structural budgets | SKILL.md ≤ 100 lines, FILL markers, placeholder residue | `smoke-test.sh` |
| Growth pressure | Are files growing past evaluation thresholds? | `check-growth-health.sh` *(report-only)* |
| Route-path activation | Is every `routing.yaml` `required_reads` reachable? | `audit-route-paths.sh` *(report-only)* |
| Reference orphans | References pointed at by no route or workflow | `audit-references.sh --orphans` |
| Cross-references | Broken inline markdown link targets | `check-cross-references.sh` |
| External fact freshness | `<!-- external-fact: verified=YYYY-MM-DD -->` markers stale | `check-external-facts.sh` |
| **Content presence (downstream)** | Did downstream forget to copy a mandatory upstream section/phrase? | `check-version-conformance.sh <skill> --conformance <upstream-clone>/templates/skill/conformance.yaml` |
| **Content presence (upstream-canon)** | Does THIS repo still teach what its templates promise? | `check-version-conformance.sh . --conformance references/self-hosting-conformance.yaml` |
| UPSTREAM-CHANGES coverage | Downstream-facing edit landed without an update note? | `check-upstream-changes.sh` *(upstream pre-commit)* |

### Where each script lives

| Script | Path | Audience |
|---|---|---|
| `check-all.sh` | `scripts/` | Upstream maintainer — orchestrator that runs the full gate before commit/push |
| `check-self-routing.sh` | `scripts/` | Upstream-only (self-hosting routing manifest) |
| `check-self-scenarios.sh` | `scripts/` | Upstream-only (self-hosting trigger routing) |
| `check-upstream-changes.sh` | `scripts/` | Upstream-only (UPSTREAM-CHANGES.md guard) |
| `sync-self-routing.sh` | `scripts/` | Upstream-only (regenerates self-hosting bootstraps) |
| `skill-asset` | `scripts/` | Both — AAR consolidation helper (ships to downstream) |
| `smoke-test.sh` | `templates/skill/scripts/` | Downstream — Phase-aware structural gate |
| `sync-routing.sh` | `templates/skill/scripts/` | Downstream — `routing.yaml` is the source of truth |
| `check-description-routing.sh` | `templates/skill/scripts/` | Downstream + upstream (works on `.`) |
| `check-growth-health.sh` | `templates/skill/scripts/` | Downstream + upstream |
| `check-external-facts.sh` | `templates/skill/scripts/` | Downstream + upstream |
| `audit-references.sh` | `templates/skill/scripts/` | Downstream + upstream |
| `audit-route-paths.sh` | `templates/skill/scripts/` | Downstream + upstream (with `--manifest`) |
| `check-cross-references.sh` | `templates/skill/scripts/` | Downstream |
| `test-trigger.sh` | `templates/skill/scripts/` | Downstream (Cursor-flavored) |
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
| Downstream doc edit | `audit-references.sh --orphans`, `check-cross-references.sh`, `check-external-facts.sh` |
| Suspected description hit-rate problem | `check-description-routing.sh`, then `test-trigger.sh` |

### Anti-pattern: bypass the matrix and add a 12th orphan check

Every check above has a one-sentence "what gap it covers". Before adding a new check script, write the gap in that form and confirm none of the existing eleven already cover it. If yes, extend the existing one. If genuinely new, add it AND a row in this matrix AND wire it into `check-all.sh` in the same commit — the conformance check itself is the cautionary tale: it shipped a release ahead of being wired in, so for one cycle it was "stored, not activated" (Pitfall #4 in [SKILL.md](../SKILL.md)).

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
