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
