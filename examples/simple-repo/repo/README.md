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
