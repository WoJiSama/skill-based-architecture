# Simple Repo Demo

This fixture is a safe input for hosted previews or first-run evaluations of
Skill-Based Architecture. It is intentionally small, public, and fake: no
secrets, no private business rules, and no real customer data.

Use it when someone wants to see what the meta-skill does before cloning or
installing it locally.

## How To Try It

1. Open the hosted preview or a local agent session.
2. For hosted preview, open [`COPY-PASTE-INPUT.md`](COPY-PASTE-INPUT.md) and
   paste the whole file into the chat. This avoids clone/fetch commands that
   hosted environments may block.

For local agents that can read this checkout directly, this shorter prompt is
enough:

```text
Use skill-based-architecture to refactor this demo repo's scattered agent rules into a skills/demo-shop/ source of truth.

Use the files under:
https://github.com/WoJiSama/skill-based-architecture/tree/main/examples/simple-repo/repo

Show the proposed skills/demo-shop/ structure and rewrite AGENTS.md, CLAUDE.md, and .cursor/rules/frontend.mdc as thin shells.
```

The important input is [`repo/`](repo/), not this README page. If any agent
cannot read the folder link, paste the contents of these files into the chat
instead:

- [`repo/AGENTS.md`](repo/AGENTS.md)
- [`repo/CLAUDE.md`](repo/CLAUDE.md)
- [`repo/.cursor/rules/frontend.mdc`](repo/.cursor/rules/frontend.mdc)
- [`repo/README.md`](repo/README.md)

The agent should identify that the project has repeated guidance across
`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/frontend.mdc`, and `README.md`, then
propose or generate a routed `skills/demo-shop/` structure.

See [`EXPECTED-SHAPE.md`](EXPECTED-SHAPE.md) for the approximate result.

## Boundary

This fixture is for demo and evaluator use only. For a real private project,
install or clone Skill-Based Architecture locally so the customer's repository
and rules stay in their own environment.
