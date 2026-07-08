# Simple Repo Demo

This fixture is a safe input for hosted previews or first-run evaluations of
Skill-Based Architecture. It is intentionally small, public, and fake: no
secrets, no private business rules, and no real customer data.

Use it when someone wants to see what the meta-skill does before cloning or
installing it locally.

## How To Try It

1. Open the hosted preview or a local agent session.
2. Provide the files under [`repo/`](repo/) as the target project context.
3. Ask:

```text
Use skill-based-architecture to refactor these scattered agent rules into a skills/demo-shop/ source of truth.
```

The agent should identify that the project has repeated guidance across
`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/frontend.mdc`, and `README.md`, then
propose or generate a routed `skills/demo-shop/` structure.

See [`EXPECTED-SHAPE.md`](EXPECTED-SHAPE.md) for the approximate result.

## Boundary

This fixture is for demo and evaluator use only. For a real private project,
install or clone Skill-Based Architecture locally so the customer's repository
and rules stay in their own environment.
