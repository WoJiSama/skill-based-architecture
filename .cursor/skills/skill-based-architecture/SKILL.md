---
name: skill-based-architecture
description: >
  This skill should be used when the user asks to "organize the project rules",
  "clean up scattered documentation", "把规则迁移到 skills 目录", "优化 skill 路由",
  "提高 description 命中率", or "减少薄壳重复维护".
  Activate when a SKILL.md is too large, rules are duplicated across agent entry
  files, task routing or trigger_examples miss natural user language, or
  templates / thin shells / validation scripts need drift-resistant maintenance.
primary: true
---

# skill-based-architecture (Cursor Registration Entry)

**This is the Cursor discovery entry.** Formal skill content lives at the repo root — read [SKILL.md](../../../SKILL.md) immediately, then follow its design principles and workflow routing.

<!-- SELF_ROUTING_BLOCK_START -->
## Quick Routing (survives context truncation)

Task routes live in `references/self-hosting-routing.yaml`.

For every new task:
1. Read `SKILL.md`.
2. Read `references/self-hosting-routing.yaml`.
3. Match by `labels`, `trigger_examples`, and task intent.
4. Read only that route's `required_reads`, then follow its `workflow`.
5. If no route matches, use the `other` route.
<!-- SELF_ROUTING_BLOCK_END -->

## Why this file exists

Cursor's `agent_skill` mechanism only scans `.cursor/skills/`. Without this registration entry, the formal skill at repo root is invisible to Cursor.

The `description` above **must stay identical** to the root [SKILL.md](../../../SKILL.md) `description` field. Drift between the two = Cursor uses one activation rule while other harnesses use another. `templates/skill/scripts/smoke-test.sh` automatically verifies they match.
