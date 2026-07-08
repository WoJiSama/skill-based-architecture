# Upgrade an Existing Downstream Project

When upstream adds new templates, hooks, protocol-blocks, scripts, or workflow improvements, existing downstream projects need an **agent-led upstream refresh** — not a full re-migration and not user-performed diffing.

The user should be able to say "上游项目更新了,帮我更新一下" or "update from upstream"; the agent then follows `skills/<name>/workflows/update-upstream.md`.

The downstream template embeds the upstream source:

```text
https://github.com/WoJiSama/skill-based-architecture.git
```

No user-managed lockfile is required. The scaffold records an internal `.upstream-sync` pointer so the agent can clone the latest upstream, compare local files itself, patch useful upstream changes, and validate the result.

The upstream repo also carries `UPSTREAM-CHANGES.md`. During a refresh, the agent should read it from the cloned upstream repo to identify likely changed areas and intended downstream handling. The file is only a map: actual upstream/downstream diffs remain the source of truth, and downstream projects should not copy, create, or maintain their own version.

Upstream maintainers should run `bash scripts/check-upstream-changes.sh` before committing downstream-facing upstream changes. The check fails when watched files change without a same-diff `UPSTREAM-CHANGES.md` update; if the change has no downstream refresh impact, record that explicitly in `UPSTREAM-CHANGES.md`.

## Ownership Rules

- **Project-owned, never overwrite** — `rules/project-rules.md`, `rules/coding-standards.md`, `references/gotchas.md`, project-specific workflows, `SKILL.md` prose, `routing.yaml` trigger examples.
- **Mechanism-owned, agent may port changes** — `scripts/*.sh`, universal hooks, protocol-blocks, reusable workflow scaffolding, `conformance.yaml`. Still compare before editing; do not blind-copy over local changes.
- **Generated, never hand-edit** — Always Read lists, Common Tasks, and thin-shell bootstraps. Update `routing.yaml`, then run `scripts/sync-routing.sh`.

## Agent Procedure

1. Read `skills/<name>/workflows/update-upstream.md`.
2. Clone upstream to a temp directory.
3. Read `$tmp/upstream/UPSTREAM-CHANGES.md` when present, using it as guidance rather than proof; do not copy it into downstream.
4. Compare downstream vs upstream as the agent; do not ask the user to run or inspect diffs.
5. Apply small patches that preserve local project knowledge.
6. Ask the user only for semantic conflicts that cannot be resolved from code/docs evidence.
7. Run `sync-routing.sh`, `smoke-test.sh`, and `audit-orphans.sh`.
8. Run `check-version-conformance.sh` against the upstream's manifest (not local) — see `update-upstream.md` step 9 for why.
9. Report what upstream note entries were consulted, what upstream changes were adopted, what local customizations were preserved, and what was intentionally left untouched.

## What NOT to do

- Don't re-run the Quick Start scaffold on an already-migrated project — it'll clobber project-specific content. Use the upstream-refresh path instead.
- Don't ask the user to manually diff upstream and downstream; the workflow exists so the agent does that work.
- Don't use whole-file replacement unless the target is missing or the agent verifies the local file is an unmodified old upstream template.
- Don't copy `UPSTREAM-CHANGES.md` into downstream projects; it is read only from the cloned upstream repo.
- Don't propagate experimental upstream additions (principles that accumulated in an over-cap `agent-behavior.md` during testing, etc.) — only the canonical clean state belongs downstream.
- Don't use absolute paths in subagent prompts when probing — they bypass `isolation: worktree` and leak writes back to main (see [`examples/behavior-failures.md`](../examples/behavior-failures.md)).

## Ongoing Maintenance

After initial migration, two mechanisms keep documentation healthy over time:

1. **Self-evolution** — `task-closure.md` includes the after-action review scan and `update-rules.md` the recording / learn-from-mistakes steps, so the Agent proactively records new patterns, pitfalls, and conventions discovered during tasks. The sync trigger table itself is also a living document that grows as new mapping relationships are discovered. The review is lightweight, but it still happens before the task is considered done.
2. **Self-maintenance** — `maintain-docs.md` provides file health checks, split procedures, and merge procedures. Line counts are **signals, not commands** — exceeding a threshold triggers evaluation, not automatic action. Only split when the file genuinely covers separable topics; only merge when fragments genuinely belong together.

## Incremental Migration

Not every project can migrate all 9 phases in one pass. A phased approach:

1. **Round 1 — Structure + Rules**: create `skills/<name>/`, write `SKILL.md`, extract rules only.
2. **Round 2 — Workflows**: extract workflows; update `SKILL.md` task entries.
3. **Round 3 — References + Thin shells**: move references; convert root entries to thin shells.

Key principles:

- Each round should leave the project in a **working state** — no broken references.
- Old files can coexist temporarily; mark them with `<!-- MIGRATING: see skills/<name>/ -->` until fully moved.
- Don't block daily work for migration; migrate a file when you next need to edit it.
- After each round, run the Phase 8 checklist on the parts completed so far.
