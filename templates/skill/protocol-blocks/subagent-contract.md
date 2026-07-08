# Subagent Contract
Every subagent dispatched via [`workflows/subagent-driven.md`](../workflows/subagent-driven.md) gets the five dispatch fields below plus one Return Status. Paste only the contract, not the main conversation history.
From a plan? Lift Task Breakdown directly: Files+Produces → Outputs, Files+Consumes → Inputs, other tasks' files → Forbidden Zones, Acceptance → Acceptance Criteria.

```markdown
## Goal
<!-- FIELD: one sentence, outcome-focused. E.g., "Extract the retry logic in api/client.ts into a reusable helper with identical behavior." -->

## Inputs
<!-- FIELD: exact file paths/artifacts the worker may read. Nothing implicit. -->

## Outputs
<!-- FIELD: exact file paths the worker must create or modify. -->

## Forbidden Zones
<!-- FIELD: files, directories, or side effects the worker must NOT touch. -->

## Acceptance Criteria
<!-- FIELD: literal checks the main agent will run in Phase 3 Stage A. -->

## Return Status
<!-- Worker ends with exactly ONE word: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED -->
```

Rules: no field may be empty; Goal is outcome-focused; Forbidden Zones default to deny; Acceptance Criteria must be executable commands or `git` checks; if the contract is wrong, the main agent rewrites and re-dispatches; a bare "done" with no Return Status is invalid.

| Status | Meaning | Controller response |
|---|---|---|
| `DONE` | All Acceptance Criteria pass, no reservations | Run Phase 3 Stage A + B, then merge |
| `DONE_WITH_CONCERNS` | Criteria pass, but a scoped risk remains | Read concern before merging; queue follow-up if non-trivial |
| `NEEDS_CONTEXT` | Inputs were insufficient to finish; worker names exactly what is missing | Do **not** patch inline — widen `Inputs`, re-dispatch |
| `BLOCKED` | An obstruction the worker cannot resolve (permission denied, tool unavailable, contract self-contradictory) | Resolve the blocker — surface to the user per the Interception Transparency Rule when you cannot — then re-dispatch |
