# Gotchas

<!--
Format per entry:

## **[topic]** <short title>

**Symptom:** what you see when you hit this
**Cause:** why it happens (one paragraph max)
**Fix:** the minimal correct response
**Prevent:** how future tasks avoid this (links to workflow checklist if activated)

Tag reference:
  [topic]  — short reusable noun for dedup clustering (e.g. [lifecycle], [auth], [styling])
           — reuse existing topics; same topic in one file = check for duplicates

Only record entries that pass the Recording Threshold (repeatable + costly + not obvious from code — at least 2 of 3).
Generalize before writing: `specific finding → abstract pattern → consequence of ignoring`.

═════════════════════════════════════════════════════════════════════════
Organization upgrade path — pick the stage that matches your current size:

(1) ≤ 10 entries: flat list with **[topic]** tags is enough.
    `grep -oP '\*\*\[([^\]]+)\]' references/gotchas.md | sort | uniq -c`
    quickly shows topic clusters and duplicates.

(2) 10–25 entries: group under H2 categories.
    Promote frequent [topic] tags to ## headings and turn entry titles into ###.
    Example shape (do NOT pre-fill — wait until clusters emerge from real entries):

      ## Data Flow
      ### **[lifecycle]** Tabs re-open does not re-fetch
      ### **[lifecycle]** ServiceStore.removeStore race

      ## Forms
      ### **[validation]** addRule receives undefined value

    Goal: any new author can find "is my pitfall already recorded?" in
    O(category) instead of O(file).

(3) > 25 entries OR > 400 lines OR any category itself reaches stage-2 size:
    Split into domain-specific pitfall files (e.g. `data-flow-pitfalls.md`,
    `form-pitfalls.md`). Run `workflows/maintain-docs.md § Step 1b` first
    to confirm the split decision is real (separable topics, each part ≥
    30 lines, no broken cross-references after).

Smoke-test enforces:
  - line count ≤ $GOTCHAS_MAX_LINES (default 400)
  - no duplicate ## headings (signals copy-paste recurrence — same entry
    added twice without checking dedup)

If two entries describe the same root cause but were noticed in different
contexts, merge into ONE entry with both contexts listed under Symptom.
═════════════════════════════════════════════════════════════════════════
-->

<!-- OPTIONAL: this file starts empty. Entries grow via After-Action Review. Do NOT pre-populate. -->
