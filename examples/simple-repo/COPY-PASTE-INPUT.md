# Copy-Paste Input For Hosted Preview

Copy everything inside the block below into the hosted preview chat. This
avoids asking the hosted agent to clone this repository or inspect a GitHub
folder URL.

````text
Use skill-based-architecture to refactor these scattered agent rules into a skills/demo-shop/ source of truth.

Use only the files pasted below as the target project context. Do not clone, fetch, or inspect the GitHub repository.

Show the proposed skills/demo-shop/ structure and rewrite AGENTS.md, CLAUDE.md, and .cursor/rules/frontend.mdc as thin shells.

--- AGENTS.md ---
# AGENTS.md

Demo Shop is a tiny cart widget used for documentation examples. Keep changes
small and easy to inspect.

## Project Rules

- Treat `src/cart.js` as the source of truth for cart totals.
- Keep all prices in cents internally. Only format dollars at display edges.
- Do not add dependencies unless the task explicitly requires one.
- Run `npm run check` before reporting completion.
- If behavior changes, include a short note about what user-visible path
  changed.

## Coding Standards

- Use plain JavaScript modules.
- Prefer small pure functions over shared mutable state.
- Name exported functions with verbs, such as `calculateSubtotal`.
- Avoid rounding until the final display step.

## Workflows

### Fix a bug

1. Reproduce the bug with the smallest cart input.
2. Identify whether the issue is subtotal math, discount math, or rendering.
3. Patch the smallest function that owns the behavior.
4. Run `npm run check`.
5. Report root cause, changed file, and validation.

### Update cart pricing

1. Confirm whether the change affects cents, display formatting, or discounts.
2. Update `src/cart.js`.
3. Add or adjust an example in the file's demo block.
4. Run `npm run check`.

## Known Gotchas

- Discount math must happen after subtotal calculation, not per item.
- Rendering stale subtotals is easy if callers cache formatted strings.
- Floating point dollars caused a previous rounding mismatch; keep cents until
  `formatMoney`.

--- CLAUDE.md ---
# CLAUDE.md

Use these rules when working in Demo Shop.

## Always Follow

- Preserve the cart math contract: item price and quantity produce subtotal in
  cents.
- Do not rewrite the project into React, TypeScript, or a framework.
- Prefer editing `src/cart.js`; this fixture intentionally has no build system.
- Run `npm test` before final response.

## Bug Fix Flow

1. Start with the failing cart example.
2. Explain which invariant failed.
3. Make the smallest code change.
4. Verify with `npm test`.

## Frontend Notes

- UI examples should call `formatMoney` instead of formatting dollars inline.
- If adding a display helper, keep raw cents available for later calculations.

## Watch Outs

- `AGENTS.md` says to run `npm run check`; this file says `npm test`. They are
  currently equivalent, but this duplication is exactly what the migration
  should remove.
- Do not store formatted dollar strings in state.

--- .cursor/rules/frontend.mdc ---
---
description: Demo Shop frontend guidance.
alwaysApply: false
---

# Frontend Rules

- Use `summarizeCart` for cart display data; do not duplicate subtotal math in
  UI components.
- Keep raw cent values available for calculations and analytics.
- Format display values only with `formatMoney`.
- Show subtotal and total together when a discount is active.

## Add UI Component Flow

1. Confirm the component needs cart data.
2. Use `summarizeCart` for derived values.
3. Keep component state in raw cents, not formatted strings.
4. Test a discounted and non-discounted cart.

## Pitfalls

- If a component stores `"$12.99"` in state, later discount math has to parse a
  display string and can drift.
- Cursor-only frontend rules drift from `AGENTS.md` and `CLAUDE.md`; this should
  become `skills/demo-shop/rules/frontend-rules.md`.

--- README.md ---
# Demo Shop

Tiny fake shopping cart used as a Skill-Based Architecture demo input.

```bash
npm test
```

## Agent Notes

These notes are intentionally mixed into the user README to demonstrate why
project guidance should be moved into a skill.

- Cart totals use cents, never floating point dollars.
- Bug fixes should start from a reproducible cart example.
- Keep helper functions small and pure.
- Cursor rules contain UI-specific notes that should not live only in Cursor.

For a real project, these notes would move into `skills/demo-shop/`.
````
