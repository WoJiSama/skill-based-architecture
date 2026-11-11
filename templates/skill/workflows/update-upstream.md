# Update From Upstream

Use when the user says the upstream skill-based-architecture project changed and asks the agent to update this downstream project. The user should not have to run diffs; the agent owns comparison, patching, and validation.

<!-- upstream-source: repo=https://github.com/WoJiSama/skill-based-architecture.git -->

## Hard Rules

1. **No blind overwrite** — never copy an upstream file over a downstream file without reading both.
2. **Project knowledge wins** — preserve project-filled rules, gotchas, workflows, routing examples, descriptions, boundaries, and validation commands.
3. **Agent does the diff** — do not ask the user to compare files. Ask only when a semantic conflict cannot be resolved from local evidence.
4. **Patch, don't replace** — apply upstream improvements as small edits with `apply_patch` or equivalent. Whole-file replacement is allowed only for a missing file or a file verified to be an unmodified old upstream template. For vendor-manifest files, `scripts/sync-vendor.sh` performs exactly that verification mechanically (local == upstream@synced_sha base).
5. **Upstream notes stay upstream** — read the active and archived upstream change notes when relevant, but never copy either changelog into the downstream project.
6. **Generated shells stay generated** — do not hand-edit generated routing blocks; update `routing.yaml`, then run `scripts/sync-routing.sh`.

## Posture: tracking (default) vs fork

This workflow assumes the **tracking posture** — the project follows upstream by `synced_sha`, selected vendor files sync mechanically, and current upstream checks are fitted to the project's declared owners. A downstream may instead deliberately **fork**: treat upstream as an idea source, absorb selectively, stop tracking SHAs. Legitimate — but it carries three standing costs; accept them explicitly rather than drifting into them:

1. **The local conformance contract freezes at the fork point** — nothing flags that upstream added a new mandatory section; local checks keep passing against a stale promise.
2. **Vendor-class fixes stop arriving mechanically** — every absorb becomes hand work whose completeness depends on someone's diligence, with no am-I-behind reporter.
3. **Fork points must be registered locally** (which files diverged, and why) — unregistered divergence turns every future absorb into rediscovered conflicts.

A forked downstream should still scan upstream's `UPSTREAM-CHANGES.md` on a cadence — it is written to be read idea-by-idea, entry-by-entry.

## Procedure

0. **Verify you are in the skill-maintenance checkout** — run `git worktree list`. With multiple checkouts of this repo, the live skill line is the one holding `skills/<name>/.upstream-sync` (step 3's `upstream-status.sh` also warns on a missing or diverging pointer). A checkout without the pointer — or with an older `synced_sha` than a sibling — is a stale copy: STOP and switch to the live checkout instead of porting into it.
1. **Preflight** — run `git status --short`; note existing local changes and do not revert them. Identify `NAME` and `skills/<name>/`.
2. **Fetch upstream** — clone the latest upstream to a temp directory:
   ```bash
   tmp="$(mktemp -d)"
   git clone https://github.com/WoJiSama/skill-based-architecture.git "$tmp/upstream"
   ```
3. **Read upstream update notes, scoped to your sync point** — run `bash "$tmp/upstream/templates/skill/scripts/upstream-status.sh" "skills/$NAME" --upstream "$tmp/upstream"`. It names the comparison revision and lists new entries across `UPSTREAM-CHANGES.md` and `UPSTREAM-CHANGES-archive.md`; moving an existing entry to the archive is not a new change. Read the listed source files, follow superseding entries, and skip deprecated guidance. A missing baseline requires a first-refresh review; a fetch or revision-resolution failure is not evidence that the project is current. Use notes as a map, not proof that a file should change. If a supplied local clone's checked-out HEAD differs from the reported revision, prepare a temporary checkout of that revision before comparison or copying; leave the supplied checkout intact. Set `$tmp/upstream` to that prepared checkout before continuing. All content, validation sources, and the final sync pointer must refer to that same revision.
4. **Classify files before editing**
   - Upstream-only: the active and archived upstream change notes. Read during refresh; never port into downstream.
   - Vendor: only paths explicitly listed under `vendor:` in the local `sync-manifest.yaml` and still offered by the upstream vendor catalog; payload owners are `protocol-blocks/**` and `scripts/**`. These stay byte-identical or are reported as LOCAL-EDIT. The local manifest is the project selection boundary and is preserved, including legacy self-listing entries; it is not a payload to replace with the complete upstream catalog.
   - Project-owned: every non-vendor source file, including rules, gotchas, routing, SKILL prose, workflows, hooks, the local vendor selection, local conformance additions, and `.upstream-sync`. Preserve and merge manually; absence from a list defaults here.
   - Generated: Always Read, Common Tasks action hook, and thin-shell bootstraps. Edit their source (`routing.yaml`) and regenerate with `sync-routing.sh`; never copy generated output as source.
   - Runtime-data: hook state, caches, secrets, and local runtime instances. Keep them local/gitignored; never add them to the manifest or upstream refresh.
5. **Sync vendor files mechanically** — run `bash "$tmp/upstream/templates/skill/scripts/sync-vendor.sh" "skills/$NAME" --upstream "$tmp/upstream"` (dry-run), review the report, then re-run with `--apply`. Use the freshly inspected upstream synchronizer so an old installed copy cannot expand the selection. NEW means a missing *selected* payload; an upstream-only addition does not become selected automatically. Files matching the synced-sha base may update; LOCAL-EDIT files remain untouched. Resolve dropped selections and local divergence explicitly before advancing the pointer. Path/type checks run before writes; any failed write/readback returns nonzero, and partial work must be inspected before retrying. For a pre-manifest skill, first fit the upstream vendor catalog to the responsibilities actually adopted and save that local selection. Newly adopted dependencies and non-vendor workflows/hooks require the same evidence-based admission and semantic review; absence alone never authorizes installing them.
6. **Compare as the agent (non-vendor files)** — for each remaining candidate upstream file (workflows, rules, references, conformance semantics), inspect local and upstream versions (`git diff --no-index` is fine). If local contains project-specific edits, keep them and cherry-pick upstream improvements into the local file.
7. **Use upstream history only as evidence** — if considering whole-file replacement, verify the local file matches a previous upstream version from the cloned repo's history. If no exact historical match, do not replace.
8. **Update routing deliberately** — add a route only when the downstream project should expose that task. Preserve existing task ids and trigger examples unless clearly obsolete.
9. **Validate only materialized checks** — run the commands below only when their script and owning responsibility exist; an absent Full-only checker is not a reason to install it. For split-root projects, supply the actual workspace root to smoke/routing checks and repeat orphan/reachability checks for both declared roots.
   ```bash
   bash "skills/$NAME/scripts/sync-routing.sh" "$NAME"
   bash "skills/$NAME/scripts/sync-routing.sh" "$NAME" --check
   bash "skills/$NAME/scripts/smoke-test.sh" "$NAME"
   (cd "skills/$NAME" && bash scripts/audit-orphans.sh)
   (cd "skills/$NAME" && bash scripts/route-reachability.sh)
   bash "skills/$NAME/scripts/route-health.sh" "$NAME"
   ```
   Two-root orphan/reachability checks use `--namespace skill|code --routing <skill-root>/routing.yaml`; identical `skill:` and `code:` paths cannot satisfy each other.
10. **Refresh applicable conformance from current upstream** — do not trust a stale local promise, and do not apply the complete-scaffold manifest to a fitted project. Preserve declared required owners even when a file is missing; inspecting only surviving files would hide deletions.
    - **Materializer-fitted contract** (its first line starts with `# Fitted content contract:`): render the current upstream requirements from the existing declaration into a temporary candidate. The same renderer is used by first materialization:
      ```bash
      bash "$tmp/upstream/scripts/render-fitted-conformance.sh" \
        "skills/$NAME/conformance.yaml" > "$tmp/fitted-conformance.yaml"
      bash "$tmp/upstream/templates/skill/scripts/check-version-conformance.sh" \
        "skills/$NAME" --conformance "$tmp/fitted-conformance.yaml"
      ```
    - **Complete-scaffold contract**: only when the project's adopted responsibilities match the complete reusable scaffold, check against `$tmp/upstream/templates/skill/conformance.yaml`.
    - **Custom contract or no conformance owner**: inspect applicable upstream changes and retain the project's fitted verification. Do not invent a complete-scaffold requirement. If ownership cannot be established, stop and resolve it before writing or advancing the pointer.
    A failed applicable check means the refresh is incomplete. Port the missing semantics into their selected owners. Merge the refreshed checks into local conformance, preserving project-specific assertions and explicitly reconciling superseded checks; the renderer does not carry custom assertions into its temporary candidate. Validate the merged local contract and the applicable current upstream candidate. Never overwrite local additions or enlarge the selected owner set just to turn the complete-scaffold check green.
11. **Update the sync pointer** — after a successful refresh with passing validation, record the upstream HEAD you synced from, so the next `upstream-status.sh` is precise:
    ```bash
    printf 'upstream: %s\nsynced_sha: %s\nsynced_date: %s\n' \
      "https://github.com/WoJiSama/skill-based-architecture" \
      "$(git -C "$tmp/upstream" rev-parse HEAD)" "$(date +%F)" > "skills/$NAME/.upstream-sync"
    ```
    (Preserve any leading comment lines if the file already has them.) This is what keeps "am I current?" a one-command check instead of a manual diff.
12. **Final report** — list upstream note entries consulted, upstream changes adopted, local customizations preserved, files intentionally left untouched, validation results (including current upstream checks fitted to the declared owners), any new mechanism files copied, and any unresolved semantic conflicts.

## Stop Conditions

- Upstream cannot be fetched and the user did not provide a local upstream path.
- A file has both upstream mechanism changes and local semantic rewrites that cannot be reconciled from evidence.
- Validation fails after the merge and the cause is not isolated.

Do not solve stop conditions by overwriting downstream project knowledge.
Do not solve missing upstream notes by creating a downstream `UPSTREAM-CHANGES.md`.
