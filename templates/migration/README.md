# Migration Scripts

Meta-level helpers for running or recovering the 9-phase migration itself.
These are **not** per-skill templates — they live alongside the skill-based-architecture repo and are invoked during/after migration.

## Files

| File | Purpose |
|---|---|
| `migrate.sh` | Atomic "run one phase + validate + checkpoint" helper. `bash migrate.sh <phase>` validates via `smoke-test.sh --phase N` and writes `.migration-state` only if validation passes. Human-only phases (1, 2, 9) prompt for confirmation instead. |
| `resume.sh` | Detect where a crashed migration left off (via `.migration-state` or artifact signatures) and print the next action. Pass `--advance` to re-run the last phase's smoke-test and keep the checkpoint honest. |

## Usage

From the target project's root (not this repo's root):

```bash
# Detect current state
NAME=my-project bash "$UPSTREAM/templates/migration/resume.sh"

# Detect and re-validate last checkpoint
NAME=my-project bash "$UPSTREAM/templates/migration/resume.sh" --advance

# Validate phase N and write checkpoint atomically (refuses to checkpoint a broken phase)
NAME=my-project bash "$UPSTREAM/templates/migration/migrate.sh" 4

# Human-only phases (1, 2, 9) — prompts y/N
NAME=my-project bash "$UPSTREAM/templates/migration/migrate.sh" 9

# Show status (delegates to resume.sh)
NAME=my-project bash "$UPSTREAM/templates/migration/migrate.sh" status
```

## Why a script and not just documentation

WORKFLOW.md § "Resuming From a Failed Phase" documents the *mechanism*; `resume.sh` makes it *executable* — one command instead of a bash snippet the user has to copy-paste and adapt. This is the difference between "declared a recovery mechanism" and "provided a recovery mechanism", per the four-primitive audit.

## Related

- `WORKFLOW.md` § Resuming From a Failed Phase — the authoritative spec
- `templates/skill/scripts/smoke-test.sh` — per-phase validator invoked by `--advance`
- `templates/protocol-blocks/rationalizations-table.md` — the "崩了我从头重跑" row
