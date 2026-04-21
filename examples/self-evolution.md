# Examples — Self-Evolution, Activation & Task Closure

The maintenance loop: AAR → record → activate → stay-activated under pressure. See [README.md](README.md) for the full index.

## Example 7: Self-Evolution — After-Action Review

### Scenario

Agent completes a task: adding a new page that uses a Recoil atom + custom amis filter. During the task, it discovers that the atom naming pattern and the filter registration method aren't documented anywhere.

### After-Action Review

```text
Review scan:
1. New pattern? → ✅ Recoil atom naming uses `xxxAtom`, not documented
2. New pitfall? → ✅ Filter must be registered before app init, otherwise first render fails
3. Missing rule? → ✅ No standard procedure for filter registration
4. Outdated/obsolete rule? → No

Recording threshold — atom naming convention:
  Repeatable?         Yes, every new atom encounters this          → PASS
  Costly if missed?   No, inconsistent naming doesn't cause errors → FAIL
  Not obvious?        No, existing atoms clearly show the pattern  → FAIL
  Result: 1/3 met → Don't record (conventions learnable from code don't need docs)

Recording threshold — filter registration timing pitfall:
  Repeatable?         Yes, every new filter encounters this           → PASS
  Costly if missed?   Yes, first-render blank screen, 30+ min debug  → PASS
  Not obvious?        Yes, timing dependency not apparent from code   → PASS
  Result: 3/3 met → Record

Actions taken:
- Appended one bullet point to references/pitfalls.md about filter registration timing
- Added to sync trigger table: "New amis filter → references/pitfalls.md"
- Atom naming convention NOT recorded
```

### Why

- Only records pitfalls that "cost 30+ minutes if you don't know", not conventions "learnable from code"
- Rule files stay lean — every entry carries real value
- The threshold filtered out 1/3 of potential records, preventing bloat

---
## Example 8: Learn from Mistakes

### Scenario

Agent adds a new Controller but forgets to register the route in the menu config. User points out the page is invisible. Agent fixes it, then runs the learn-from-mistakes flow.

### Learn-from-Mistakes Flow

```text
Error analysis:
- Root cause: missing rule — workflows/add-controller.md has no "register menu" step
- Not outdated, not unfollowed — the rule simply didn't exist

Actions taken:
- Added step 4 to workflows/add-controller.md: "Register the route in the menu configuration"
- Added to completion checklist: "[ ] New route is visible in the menu"
```

### Why

- The same mistake won't happen twice
- Workflows become progressively more complete rather than staying at their initial version
- The Agent's "experience" is codified into reusable checklists

---
## Example 12: Bug Fix → References Update

### Scenario

Agent fixes a frontend bug in a modal dialog that contains Tabs and an inner data-loading service. The immediate bug is solved, but the real lesson is a non-obvious lifecycle pitfall: reopening the dialog only reloads the outer layer unless mount behavior and inner state reset are handled correctly.

### During the Fix

```text
Observed behavior:
- First open works
- Close and reopen only refreshes the outer API
- Inner tab content stays stale or never re-requests

Root cause:
- Dialog + Tabs + nested service chain created a lifecycle mismatch
- The bug was not obvious from reading one component in isolation
- The team had no written note about when to use mountOnEnter: false or when mixed React/embedded-render state must be reset
```

### Task Closure Review

```text
After-Action Review:
- New pattern? → No
- New pitfall? → ✅ Yes
- Missing rule? → ✅ Yes
- Outdated rule? → No

Recording Threshold:
- Repeatable?       Yes, dialogs, tabs, and nested loaders are common        → PASS
- Costly if missed? Yes, reproducing and isolating lifecycle bugs is slow     → PASS
- Not obvious?      Yes, the interaction spans multiple layers               → PASS

Result:
- 3/3 met → record it
```

### Actions Taken

```text
Documentation updates:
- Added the lifecycle pitfall to references/frontend-pitfalls.md
- Added the mixed-render exception/placement note to references/react-amis-hybrid.md
- Added a sync trigger row to workflows/update-rules.md:
  "Dialog / tabs / nested service lifecycle issue → update frontend-pitfalls.md,
   and update react-amis-hybrid.md when mixed rendering is involved"
- Added a completion reminder to workflows/fix-bug.md so future bug-fix tasks
  must re-check the same class of pitfall instead of relying on memory alone
- If the fix changed task routing, also update SKILL.md Common Tasks
```

### Why

- The task is not considered fully complete until the team decides whether the lesson is worth keeping
- The threshold prevents documenting every minor bug, but catches expensive framework/lifecycle gotchas
- Future agents can now find the pitfall before repeating the same debugging session

---
## Example 13: Recorded But Not Activated

### Scenario

Agent documents an expensive frontend lifecycle bug only in `references/frontend-pitfalls.md`. The note is correct, but the next similar task still misses it.

### Weak Outcome

```text
What happened:
- The pitfall was recorded in references/frontend-pitfalls.md
- No workflow checklist changed
- SKILL.md Common Tasks still routed "Fix bug" to generic files only
- The next bug-fix task never naturally read that reference

Result:
- Knowledge was stored
- Knowledge was not activated
- The team still repeated part of the debugging work
```

### Strong Outcome

```text
What changed:
- The pitfall stayed in references/frontend-pitfalls.md for the full explanation
- workflows/fix-bug.md gained a completion check pointing to update-rules.md
- SKILL.md Common Tasks for the relevant task now points to the pitfall reference

Result:
- Knowledge was stored in the right place
- The normal task path now surfaces the lesson
- Future agents are much less likely to miss it
```

### Why

- `references/` preserves lessons
- `workflows/` and routing make those lessons harder to skip
- High-cost pitfalls should be both documented and activated

---
## Example 14: Description Trigger Phrases — Silent Activation Failure

### Scenario

A project skill is properly structured with rules, workflows, and references, but the Agent never activates it. The user has to manually tell the Agent "read the skill" every time.

### Before (broken — skill never fires)

```yaml
---
name: my-api
description: API development helper
primary: true
---
```

5-word description. The Agent has no idea when to activate this skill. It scores 0 on the most heavily weighted check in skill quality audits. The skill exists but is functionally dead.

### After (reliable activation)

```yaml
---
name: my-api
description: >
  This skill should be used when the user asks to "add a new API endpoint",
  "write controller logic", "fix a backend bug", or "add a database migration".
  Activate when the task involves REST routes, request validation,
  service layer logic, or MyBatis mapper changes.
primary: true
---
```

### Why

- **Trigger phrases** (`"add a new API endpoint"`, `"fix a backend bug"`) tell the Agent exactly which user requests should activate this skill
- **Activation conditions** (REST routes, request validation, service layer) cover task contexts beyond the exact phrases
- **Third-person format** ("This skill should be used when…") matches the Agent's selection logic
- **≥ 20 words** ensures enough signal for reliable matching
- The difference between a working skill and a dead one is often a single frontmatter field

---
## Example 16: Rules Exist, But AAR Still Got Skipped

### Scenario

A downstream project already has:

- `workflows/update-rules.md`
- thin-shell `Auto-Triggers`
- task routing in `SKILL.md`

The agent finishes a UI task that changed behavior: interaction timing, overlay layering, host compatibility, or styling that affects the actual outcome. The code fix works, but no rule or reference update happens.

### What Went Wrong

```text
Observed failure:
- The project already had an After-Action Review workflow
- The entry files already mentioned Auto-Triggers
- The task still ended right after the code fix and verification

Root cause:
- The workflow text treated update-rules as something to "also do"
- "Behavior change" was interpreted too narrowly as business logic only
- UI / interaction / layering changes were misclassified as low-value styling cleanup

Result:
- The rule system existed
- The lesson was still not recorded
- The next similar task could repeat the same debugging work
```

### Stronger Upstream Fix

```text
Template changes:
- fix-bug.md now says behavior-changing tasks must run update-rules.md before closure
- "Behavior change" explicitly includes interaction changes, schema / renderer behavior changes,
  styling conventions that change outcomes, overlay / z-index / layering behavior, and host-compatibility changes
- update-rules.md explicitly lists UI convention / host compatibility /
  layering issues as valid sync-trigger categories
- thin-shell Auto-Triggers mention the same broader behavior-change scope
```

### Why

- The problem was not "missing workflow", but "workflow too easy to treat as optional"
- Making the exit path harder to skip is more effective than adding more scattered reminders
- Once the upstream template is fixed, future downstream skills inherit the stronger closure behavior by default

---
