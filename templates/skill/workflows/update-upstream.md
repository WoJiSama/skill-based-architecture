# Update From Upstream

Use when the user says the upstream skill-based-architecture project changed and asks the agent to update this downstream project. The user should not have to run diffs; the agent owns comparison, patching, and validation.

<!-- upstream-source: repo=https://github.com/WoJiSama/skill-based-architecture.git -->

## Hard Rules

1. **No blind overwrite** — never copy an upstream file over a downstream file without reading both.
2. **Project knowledge wins** — preserve project-filled rules, gotchas, workflows, routing examples, descriptions, boundaries, and validation commands.
3. **Agent does the diff** — do not ask the user to compare files. Ask only when a semantic conflict cannot be resolved from local evidence.
4. **Patch, don't replace** — apply upstream improvements as small edits with `apply_patch` or equivalent. Whole-file replacement is allowed only for a missing file or a file verified to be an unmodified old upstream template.
5. **Generated shells stay generated** — do not hand-edit generated routing blocks; update `routing.yaml`, then run `scripts/sync-routing.sh`.

## Procedure

1. **Preflight** — run `git status --short`; note existing local changes and do not revert them. Identify `NAME` and `skills/<name>/`.
2. **Fetch upstream** — clone the latest upstream to a temp directory:
   ```bash
   tmp="$(mktemp -d)"
   git clone https://github.com/WoJiSama/skill-based-architecture.git "$tmp/upstream"
   ```
3. **Classify files before editing**
   - Project-owned: `rules/project-rules.md`, `rules/coding-standards.md`, `references/gotchas.md`, project-specific workflows, `SKILL.md` prose, `routing.yaml` task examples. Preserve; merge manually if needed.
   - Mechanism-owned: `scripts/*.sh`, universal hooks, protocol-blocks, reusable workflow scaffolding. Compare and port useful upstream changes.
   - Generated: Always Read, Common Tasks, thin-shell bootstraps. Regenerate only.
4. **Compare as the agent** — for each candidate upstream file, inspect local and upstream versions (`git diff --no-index` is fine). If local contains project-specific edits, keep them and cherry-pick upstream improvements into the local file.
5. **Use upstream history only as evidence** — if considering whole-file replacement, verify the local file matches a previous upstream version from the cloned repo's history. If no exact historical match, do not replace.
6. **Update routing deliberately** — add a route only when the downstream project should expose that task. Preserve existing task ids and trigger examples unless clearly obsolete.
7. **Validate**
   ```bash
   bash "skills/$NAME/scripts/sync-routing.sh" "$NAME"
   bash "skills/$NAME/scripts/sync-routing.sh" "$NAME" --check
   bash "skills/$NAME/scripts/smoke-test.sh" "$NAME"
   bash "skills/$NAME/scripts/check-description-routing.sh" "$NAME"
   (cd "skills/$NAME" && bash scripts/audit-references.sh --orphans)
   ```
8. **Final report** — list upstream changes adopted, local customizations preserved, files intentionally left untouched, validation results, and any unresolved semantic conflicts.

## Stop Conditions

- Upstream cannot be fetched and the user did not provide a local upstream path.
- A file has both upstream mechanism changes and local semantic rewrites that cannot be reconciled from evidence.
- Validation fails after the merge and the cause is not isolated.

Do not solve stop conditions by overwriting downstream project knowledge.
