# Subagent Contract (drop-in block)

Every subagent dispatched via [`workflows/subagent-driven.md`](../skill/workflows/subagent-driven.md) must receive a contract with exactly these five fields. Paste this block as the worker's task prompt — no main-conversation history.

```markdown
## Goal
<!-- FILL: one sentence, outcome-focused. E.g., "Extract the retry logic in api/client.ts into a reusable helper with identical behavior." -->

## Inputs
<!-- FILL: exact file paths or artifacts the worker may read. Nothing implicit. -->
- path/to/file-a
- path/to/file-b

## Outputs
<!-- FILL: exact file paths the worker must create or modify. -->
- path/to/new-helper.ts
- path/to/file-a (modified to use new helper)

## Forbidden Zones
<!-- FILL: files, directories, or side effects the worker must NOT touch. Default to "everything not in Outputs" if unsure. -->
- tests/** (except tests covering the modified files)
- package.json / lockfiles
- any unrelated modules

## Acceptance Criteria
<!-- FILL: literal, mechanically verifiable checks the main agent will run in Phase 3 Stage A. "Looks clean" is not acceptable. -->
- [ ] `<test command>` passes
- [ ] `<lint command>` passes
- [ ] `git diff --stat` shows only files listed in Outputs
- [ ] New helper has no callers other than file-a
```

**Rules of the contract:**

1. No field may be empty. Missing field = contract is invalid, do not dispatch.
2. Goal is outcome-focused, not procedure-focused. Do not micromanage steps.
3. Forbidden Zones default to deny: if you're unsure, list it.
4. Acceptance Criteria must be executable commands or `git` checks, not prose.
5. The worker never mutates this contract. If the contract is wrong, the main agent rewrites it and re-dispatches.
