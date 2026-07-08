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
