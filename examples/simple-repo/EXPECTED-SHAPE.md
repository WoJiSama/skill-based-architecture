# Expected Shape

A good migration does not need to match this file byte-for-byte. It should
preserve the same structure and intent.

## Target Skill

```text
skills/demo-shop/
├── SKILL.md
├── rules/
│   ├── project-rules.md
│   ├── coding-standards.md
│   └── frontend-rules.md
├── workflows/
│   ├── add-ui-component.md
│   ├── fix-bug.md
│   └── update-cart-pricing.md
└── references/
    └── gotchas.md
```

## What Should Move

- Stable project constraints from `AGENTS.md` and `CLAUDE.md` move to
  `rules/project-rules.md`.
- JavaScript style, validation, and naming conventions move to
  `rules/coding-standards.md`.
- UI state and rendering rules from `.cursor/rules/frontend.mdc` move to
  `rules/frontend-rules.md`.
- Ordered procedures such as bug fixing, adding UI components, and changing cart
  pricing move to `workflows/`.
- Costly pitfalls such as rounding drift and stale subtotal rendering move to
  `references/gotchas.md`.

## Entry Files After Migration

`AGENTS.md`, `CLAUDE.md`, and `.cursor/rules/frontend.mdc` should become thin
shells. They should route the agent to `skills/demo-shop/SKILL.md` and
`skills/demo-shop/routing.yaml` instead of duplicating rule bodies.

## What Not To Do

- Do not keep full copies of the same rule in multiple entry files.
- Do not create separate skills for `fix-bug`, `add-component`, or `cart`.
  Those are workflows and domains inside one small project skill.
- Do not add secrets, real endpoints, or customer-specific data to the demo.
