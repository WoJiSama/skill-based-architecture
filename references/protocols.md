# Reference — Protocols & Verification


## Meta-Workflow Templates

See [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md) for the full `update-rules.md` and `maintain-docs.md` templates that every project should include. These cover rule sync, after-action review, recording thresholds, rule deprecation, file health checks, and split/merge procedures.

## Task Closure Protocol

A task is NOT complete until these steps are done:

1. Main work done and verified
2. 30-second AAR scan (all "no" = stop here)
3. If any "yes" → apply recording threshold → apply generalization rule → record if it passes

No workflow may skip step 2. See [TEMPLATES-GUIDE.md § Task Closure Protocol](TEMPLATES-GUIDE.md#task-closure-protocol) for the full template.

### AAR Scan Questions

1. Did this task reveal a recurring pitfall?
2. Was the debugging or design cost high?
3. Would a future agent miss this by reading code alone?
4. Did an existing rule turn out to be inaccurate or obsolete?

Skip only for: formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors.

## Recording Threshold

Record only when at least 2 of these 3 are true:

1. **Repeatable** — likely to recur in future work
2. **Costly** — missing it wastes meaningful time or causes real regressions
3. **Not obvious from code** — a future reader would not infer it quickly from implementation alone

Typical high-value records:

- framework lifecycle gotchas
- registration timing pitfalls
- hidden routing dependencies
- non-obvious synchronization or state reset requirements

Skip recording:

- one-off workarounds
- style preferences
- facts already obvious from existing code
- content already well covered by official docs and not project-specific

## Where To Record

Use the lightest useful destination:

- Stable constraint or convention → `rules/`
- Pitfall, lifecycle gotcha, architecture note, source index → `references/`
- Ordered task step or completion check → `workflows/`
- Task routing or always-read set changed → `SKILL.md`
- Tool entry routing changed → thin shells (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/*.mdc`)

Prefer appending to an existing file over creating a new one. Create a new file only when the topic is distinct enough to stay readable on its own.

## Recording Destination Guide

When the user explicitly asks to "record this", "remember this", or "save this for later", the agent must decide where to store the knowledge. Many AI tools (Claude Code, Gemini CLI) have their own memory systems (e.g., `~/.claude/projects/.../memory/`) that auto-load each session. These compete with the skill's documentation structure.

**Decision test:** "Would a different agent or person working on this same project benefit from this knowledge?"

| Answer | Destination | Examples |
|---|---|---|
| **Yes** — project-level knowledge | `skills/<name>/references/`, `rules/`, or `workflows/` | Technical patterns, conventions, pitfalls, architecture notes |
| **No** — personal/user-level knowledge | Agent's own memory system (`~/.claude/.../memory/`, etc.) | Communication preferences, personal shortcuts, user-specific context |

**Default to skill docs.** In practice, most "record this" requests during development are technical and project-scoped. The agent's own memory should only be used for content that is truly personal and would not help another contributor.

Apply the same recording threshold and generalization rule as AAR-initiated recordings — the destination changes, but the quality bar does not.

## Generalization Rule

Records must be reusable knowledge, not project-specific narratives. Before writing, check: would this record make sense in a different project of the same type? If it mentions specific module names or business terms without an abstract explanation, rewrite it.

Pattern: `specific finding → abstract as general pattern → state consequence of not following it`

See [TEMPLATES-GUIDE.md § Generalization Rule](TEMPLATES-GUIDE.md#generalization-rule) for examples of good vs bad records.

## When References Alone Are Not Enough

Recording a pitfall in `references/` preserves it, but does **not** guarantee a future task will read it.

If a lesson is both:

- **costly** enough to repeatedly waste meaningful time, and
- **task-relevant** to a recurring workflow such as fixing bugs, adding pages, adding renderers, or wiring multi-step integrations

then do **not** leave it buried in `references/` only. Also surface it in at least one activation path:

- add or update a completion check in the relevant `workflows/*.md`
- update `SKILL.md` Common Tasks routing so the task points at the pitfall/reference file
- if the lesson is really a stable constraint, promote a concise summary into `rules/`

Rule of thumb:

- `references/` stores the explanation
- `workflows/` prevents omission at task closure
- `SKILL.md` and thin shells make the right file more likely to be read

If a future agent could still miss the lesson while following the normal task path, the knowledge is stored but not yet activated.

## Skill Activation Verification

Phase 8 checks structural correctness, but doesn't verify the skill actually activates at runtime. Use these additional checks after migration.

### Description Quality Check

| Check | Pass criteria |
|---|---|
| Length | ≥ 20 words |
| Trigger phrases | At least 2 quoted trigger phrases (e.g. "refactor project rules") |
| Format | Third-person: "This skill should be used when…" |
| Specificity | Mentions concrete conditions, not just category labels |

A description that fails these checks may silently never fire — the skill exists but the Agent never picks it up.

### Routing Coverage Check

Verify that `SKILL.md` Common Tasks covers the project's actual task distribution:

1. List the 5–10 most common task types in the project
2. For each, confirm Common Tasks has a matching entry with correct file routing
3. If a common task is missing, add it — uncovered tasks fall through to the generic "Other" route and may miss important rules/references

