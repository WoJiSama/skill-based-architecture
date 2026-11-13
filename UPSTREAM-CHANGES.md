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

## 2026-11-13 - Verify moved entry points and replay the reported defect

- Changed: Quick Start and full migration verify previously active discovery surfaces when the entry moves between roots. The fix-bug workflow replays the original scenario when lower-level checks cannot observe the reported effect.
- Why it matters: a valid installed skill can coexist with a stale local registration that wins discovery. A prior fix or a passing component check can also leave the original user-visible defect unverified.
- Downstream action: carry the acceptance wording into the existing migration or defect workflow where applicable. Keep discovery paths, runtime tools, and fixtures project-owned.

## 2026-11-11 - Keep fitted upgrades selected and make sync results truthful

- Changed: vendor refresh preserves the local selection and checks write/readback failures; status compares the fetched tracking revision and includes archived notes. First materialization and fitted refresh share `scripts/render-fitted-conformance.sh`; the Single-file live verifier runs in the fixture directory.
- Why it matters: same-version refresh previously expanded valid fitted projects, failed copies reported success, and archived changes or stale local HEADs hid pending updates.
- Downstream action: absorb the current sync/status scripts and upgrade workflow; keep the local vendor subset and project assertions. Refresh fitted checks from their declared owners, not the complete scaffold. No project requires newly unselected protocols.
- Validation: deterministic lifecycle, filesystem-failure, local-Git status, and live-harness stub regressions are part of `scripts/check-all.sh`; real Agent behavior remains a separate opt-in proof.

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
