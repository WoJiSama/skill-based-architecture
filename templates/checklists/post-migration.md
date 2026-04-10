# Post-Migration Checklist

Copy this file into your project and run through it after completing the migration.

## Structural Checks

- [ ] `skills/<name>/SKILL.md` exists and is ≤ 100 lines
- [ ] `.cursor/skills/<name>/SKILL.md` registration entry exists (required for Cursor discovery)
- [ ] `.cursor/skills/<name>/SKILL.md` description matches formal SKILL.md description **exactly**
- [ ] All important rules migrated out of old locations (no orphaned content)
- [ ] `.cursor/`, `.claude/`, `.codex/` contain only thin shells (no rule bodies)
- [ ] Every thin shell has an **inline routing table** (not just "go read SKILL.md"):
  - [ ] `AGENTS.md`
  - [ ] `CLAUDE.md`
  - [ ] `CODEX.md`
  - [ ] `GEMINI.md`
  - [ ] `.codex/instructions.md`
  - [ ] `.cursor/rules/workflow.mdc` (`alwaysApply: true`)
- [ ] Every thin shell includes Auto-Triggers + Red Flags — STOP sections
- [ ] Every thin shell includes the "multi-subtask / long run" routing row
- [ ] Thin shells are ≤ 60 lines each
- [ ] `README.md` is overview + navigation, not a rule manual
- [ ] All file references and cross-links are valid

## Activation Checks

- [ ] `description` field is ≥ 20 words with at least 2 quoted trigger phrases
- [ ] Common Tasks covers the project's 5–10 most common task types
- [ ] Common Tasks includes an "Other / unlisted task" fallback row
- [ ] Known Gotchas section exists (even if empty at initial migration — it will grow via AAR)

## Content Checks

- [ ] `grep -rn 'FILL:' skills/<name>/` returns no results (all placeholders filled)
- [ ] `grep -rn '{{' skills/<name>/ AGENTS.md CLAUDE.md CODEX.md GEMINI.md .codex .cursor` returns no results (all mechanical substitutions done)
- [ ] `references/gotchas.md` exists (can be empty at start)
- [ ] `workflows/update-rules.md` includes Rationalizations to Reject table
- [ ] `workflows/subagent-driven.md` exists with project-specific Forbidden Zones + Acceptance commands (if applicable)

## Hook Checks (if harness supports SessionStart)

- [ ] `.claude/hooks/session-start` exists and is executable
- [ ] Smoke test passes: `CLAUDE_HARNESS=claude bash .claude/hooks/session-start` exits 0 and outputs valid JSON
- [ ] `.claude/settings.json` registers the hook for `startup|clear|compact`

## Activation Smoke Test

- [ ] Give the agent a real task from the project's Common Tasks list
- [ ] Verify it reads the correct files (check which files it opened)
- [ ] Verify it follows the expected workflow
- [ ] On completion, verify it runs the Task Closure Protocol (30-second AAR scan)
