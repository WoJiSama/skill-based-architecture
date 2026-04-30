# Documentation Health Maintenance

Keep the skills directory from degrading: files not too long, not too fragmented, no broken links, no duplicated content.

**Core principle: line counts are signals, not commands.** Exceeding a threshold triggers evaluation, not action. Only split when "over threshold + topics genuinely separable"; only merge when "fragmented + topics genuinely belong together".

## When to Run

- After completing the `update-rules.md` workflow, quickly check modified file line counts
- Proactive maintenance: when files feel "hard to navigate" or "too long to want to read"
- **Not required** after every small change

## Step 1: Size Scan

Check line counts for all files under `skills/{{NAME}}/` and flag those that may need attention:

| File type | Reference range | Triggers evaluation | Fragment signal |
|---|---|---|---|
| `SKILL.md` | ≤ 100 lines | > 100 lines | — |
| `rules/*.md` | 50–200 lines | > 200 lines | < 30 lines |
| `workflows/*.md` | 30–150 lines | > 150 lines | < 15 lines |
| `references/*.md` | 50–300 lines | > 300 lines | < 30 lines |
| Thin shells | Routing + compatibility notes only | Rule/workflow bodies or project-specific process detail | — |

Note: these numbers are **reference values**, not hard thresholds. A 250-line rules file with a single coherent topic is perfectly fine to keep.

## Step 1b: Accumulation Check (all file types)

Accumulation rot is not limited to gotchas. Check **every** file under `skills/{{NAME}}/`:

| File type | Entry count trigger | Action |
|---|---|---|
| `references/gotchas.md` | > 30 entries | Evaluate: group by domain, remove resolved, merge duplicates |
| `rules/*.md` | > 25 bullet-level rules in one file | Evaluate: are any duplicates? Any obsolete after recent changes? |
| `references/*.md` (non-gotchas) | > 40 entries | Evaluate: can entries be grouped under better H2/H3 sections? |

For each file that exceeds the trigger:

1. **Dedup scan** — search for entries that say the same thing in different words. Use `**[topic]**` tags to cluster related entries quickly: `grep -oP '\*\*\[([^\]]+)\]' <file>` lists all topics; duplicate topics in the same file are the first place to look. Merge into one entry keeping the clearest wording.
2. **Staleness scan** — are any entries about technology/patterns that have since been removed from the project? Delete stale entries or mark `<!-- DEPRECATED: reason, YYYY-MM -->`.
3. **Structural scan** — are entries grouped under meaningful headings, or piled at the bottom? Re-anchor orphan entries under the correct H2/H3 section.
4. **Tag audit** — do entries carry `**[topic]**` tags? If a file has > 50% untagged entries, tag them during this pass to make the next scan faster.

## Step 1c: External Fact Freshness

External vendor/tool/runtime facts age differently from project rules. A rule like "tool X scans path Y" can go stale even when this repo never changes.

1. Facts about external tools, official behavior, hosted services, model names, APIs, CLIs, or framework semantics must carry a nearby marker:
   `<!-- external-fact: verified=YYYY-MM-DD source=https://official.example/docs -->`
2. Run `bash scripts/check-external-facts.sh` from the skill root, or `bash skills/{{NAME}}/scripts/check-external-facts.sh .` from the repo root.
3. If a marker is older than the freshness window, refresh from the primary source and update the date, or delete/scope the stale claim.
4. Do not mark project-internal facts; freshness for those is handled by code inspection, tests, and cross-reference checks.

A gotchas file that's too long to scan quickly defeats its purpose — the whole point is "brief, scannable list." The same applies to any file that agents read as part of task routing.

## Step 2: Evaluate — Should You Split?

When a file exceeds the reference range, answer these questions:

1. **Are the topics separable?** — Does the file contain 2+ independent topics where removing one doesn't affect understanding of the other?
2. **Is navigation difficult?** — Would someone looking for a specific section need to scroll through hundreds of lines to find it?
3. **Can each part stand alone?** — Would each resulting file have enough content (> 30 lines) to be independently useful?

**All three "yes" → splitting has value. Any "no" → don't split.**

### When NOT to Split

- File is long but highly coherent
- Splitting would create a sub-file too small (< 30 lines) to maintain independently
- Splitting would force readers to jump between two files to understand one concept
- File barely exceeds the reference value with no actual navigation difficulty

### Executing a Split

1. **Identify boundaries** — find independent topic blocks (usually H2 headings)
2. **Name new files** — rules: `*-rules.md`, workflows: verb-noun, references: noun-based
3. **Migrate content** — move to new files, keep heading levels reasonable
4. **Update routing** — edit `routing.yaml`, then run `scripts/sync-routing.sh`
5. **Update referrers** — other rule files that cross-reference the split files
6. **Verify** — no broken links, no duplicated content, nothing left behind

## Step 3: Evaluate — Should You Merge?

When fragment files are detected, answer these questions:

1. **Are the topics related?** — Do these small files belong to the same subject area?
2. **Is finding things easier after merging?** — Do readers frequently need to look at multiple files together?
3. **Will the merged file stay within limits?**

**All three "yes" → merging has value. Otherwise keep as-is.**

### Executing a Merge

1. **Merge** — combine content into one file, use H2 headings to separate original topics
2. **Check limits** — merged file should not exceed the type's reference limit
3. **Update references** — all locations that referenced the original files
4. **Clean up** — delete the original files

## Step 4: Reference Integrity Check

Run after any split, merge, rename, or deletion of files under `skills/{{NAME}}/`:

- [ ] All links in SKILL.md's Always Read and generated Common Tasks are valid
- [ ] All `workflows/*.md` "Read First" sections reference existing files
- [ ] Cross-references between rules/references files point to valid targets
- [ ] Thin shells still point to the current `skills/{{NAME}}/SKILL.md` or documented multi-skill router, and generated bootstraps match `routing.yaml`
- [ ] No orphaned files (file exists but no entry links to it)
- [ ] No duplicated content (each rule maintained in exactly one place)
- [ ] If a file was deleted, no other file still references it

## Completion Criteria

- Evaluated over-threshold files and made a **reasoned judgment** to keep or split
- If any file was split, merged, renamed, or deleted, reference integrity check passes
- `routing.yaml` and SKILL.md navigation match current file structure
