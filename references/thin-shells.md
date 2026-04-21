# Reference — Thin Shells & Harness Templates


## .cursor/skills/\<name\>/SKILL.md Registration Entry Template

**Required for Cursor discovery.** Cursor's agent_skill mechanism only scans `.cursor/skills/`. If the formal skill lives at `skills/<name>/`, this registration entry is mandatory — without it the skill is invisible to Cursor.

```md
---
name: <project-name>
description: >
  This skill should be used when the user asks to "<trigger phrase 1>",
  "<trigger phrase 2>", or "<trigger phrase 3>".
  (Must match formal skill's description.)
---

# <Project Name> (Cursor Entry)

Formal skill content lives at `skills/<name>/SKILL.md`.
**Read that file immediately, then follow its Always Read list and Common Tasks routing.**

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| Add feature X | `rules/<domain>-rules.md` | `workflows/<task>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |
```

**Why inline routing?** In long conversations, Cursor summarizes earlier context. Instructions like "go read `skills/<name>/SKILL.md`" get truncated. The inline routing table is embedded directly and survives summary, ensuring the agent always knows which files to read for each task type.

## Common Thin Shell Body

All thin shells share the same core content. Copy this body into each entry file, then add the tool-specific header/frontmatter shown in the per-tool sections below.

```md
Formal docs live under `skills/`. Read `skills/*/SKILL.md` — default to `primary: true` skill; only switch when task clearly matches another skill's description.

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| Add feature X | `rules/<domain>-rules.md` | `workflows/<task>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |

## Auto-Triggers

- Before declaring any non-trivial task complete → run Task Closure Protocol (see `workflows/update-rules.md`)
- Skip only for: formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors
- When user asks to "record/save/remember" something → apply Recording Destination Guide: project-level knowledge goes to `skills/<name>/` docs, personal preferences go to agent memory
```

**Why inline routing instead of just "Scan skills/"?** The "Scan skills/*/SKILL.md" instruction is natural language that gets lost during context summarization. The inline routing table embeds the essential task→file mapping directly, so the agent retains actionable routing even after summary truncation.

**Why Auto-Triggers?** A skill knows *how* to do something; the project entry tells the Agent *when* to do it. Auto-Triggers encode event→action mappings so the Agent proactively runs workflows at the right moment without waiting for a prompt.

## Per-Tool Thin Shell Templates

Each template below shows **only the tool-specific parts**. Combine each with the common body above.

### AGENTS.md

`AGENTS.md` is the **universal entry** — all AI agents (Cursor, Claude Code, Codex, etc.) read it.

```md
# AGENTS.md

One-sentence project summary.

<!-- Paste common body here -->
<!-- Optional: add project-specific auto-triggers after the common ones -->
- Before pushing to production → run `workflows/preflight.md` (if exists)
```

### CLAUDE.md

```md
# CLAUDE.md

<!-- Paste common body here (routing + auto-triggers) -->
```

### CODEX.md

```md
# CODEX.md

<!-- Paste common body here -->
<!-- Note: Auto-Triggers section is optional for Codex -->
```

### .cursor/rules/*.mdc

```md
---
description: Compatibility shell — routes to formal skill.
globs: ["**/*"]
alwaysApply: true
---

<!-- Paste common body here, with these adjustments: -->
<!-- 1. Opening line: "Formal rules live in `skills/`." (shorter form) -->
<!-- 2. Append at end: "Conflicts → formal docs in `skills/` win." -->
```

**Note:** Set `alwaysApply: true` so Cursor always sees the routing table, regardless of which files are open. Use the shorter opening line ("Formal rules live in `skills/`…") to stay within the `.mdc` size budget.

### .codex/instructions.md

```md
<!-- No file header needed — Codex reads this file directly -->
<!-- Paste common body here (routing + auto-triggers) -->
```

### .windsurf/rules/*.md

```md
---
trigger: always
---

<!-- Paste common body here, with these adjustments: -->
<!-- 1. Opening line: "Formal rules live in `skills/`." (shorter form) -->
<!-- 2. Append at end: "Conflicts → formal docs in `skills/` win." -->
<!-- Note: Auto-Triggers section is optional for Windsurf -->
```

### GEMINI.md

Gemini CLI reads `GEMINI.md` at the repo root (configurable via `.gemini/settings.json`). It also scans parent directories and subdirectories for additional `GEMINI.md` files, concatenating all discovered context. Place the thin shell at the repo root.

```md
# GEMINI.md

<!-- Paste common body here (routing + auto-triggers) -->
```

### .gemini/ Directory Note

`.gemini/` holds Gemini CLI configuration (`settings.json`, `.env`), not rule content. Context files (`GEMINI.md`) live at the repo root. If you need Gemini to also read `AGENTS.md`, configure it in `.gemini/settings.json`:

```json
{
  "context": {
    "fileName": ["GEMINI.md", "AGENTS.md"]
  }
}
```

### .claude/ Directory Note

`.claude/` in Claude Code primarily holds `settings.json` (permissions) and `commands/` (custom slash commands), not rule content. Place all instructions in the root `CLAUDE.md` (thin shell pointing to the skill). If any instruction-like files exist in `.claude/`, follow the thin-shell principle:

```md
# .claude/CLAUDE.md (if used)

All rules and workflows live under `skills/`.
See root `CLAUDE.md` for entry point.
```

## Tool Compatibility Summary

| Tool | Discovery mechanism | Required entry | Must have inline routing? |
|---|---|---|---|
| **Cursor** | Scans `.cursor/skills/` only | `.cursor/skills/<name>/SKILL.md` | Yes |
| **Cursor rules** | `.cursor/rules/*.mdc` (`alwaysApply: true`) | `.cursor/rules/workflow.mdc` | Yes |
| **Claude Code** | Reads `CLAUDE.md` at repo root | `CLAUDE.md` | Yes |
| **Codex CLI** | Reads `AGENTS.md` + `.codex/instructions.md` | Both files | Yes |
| **Windsurf** | Reads `.windsurf/rules/` | `.windsurf/rules/*.md` | Yes |
| **Gemini CLI** | Reads `GEMINI.md` at repo root (+ parent/child dirs) | `GEMINI.md` | Yes |
| **Copilot CLI** | Reads `AGENTS.md` | `AGENTS.md` (shared shell) | Yes |
| **OpenCode** | Reads `AGENTS.md` | `AGENTS.md` (shared shell) | Yes |
| **Other agents** | Reads `AGENTS.md` | `AGENTS.md` | Yes |

**All entries must contain inline routing tables** — natural-language-only instructions ("Scan skills/") get lost during context summarization in long conversations.

Pre-built shells for every harness above ship under [`templates/shells/`](templates/shells/) — downstream projects should `cp -R` the tree rather than regenerate the files inline.

## SessionStart Hook (Optional)

Context compression (`/clear`, `/compact`) drops previously-loaded skill content from the active window. A `SessionStart` hook re-injects `SKILL.md` on each fresh session or compaction boundary, turning context loss into a self-healing event rather than a silent failure mode.

The upstream ships a ready-to-copy hook at [`templates/hooks/session-start`](templates/hooks/session-start) plus two config shims:

- [`templates/hooks/hooks.json`](templates/hooks/hooks.json) — Claude Code config (`startup|clear|compact` matcher)
- [`templates/hooks/hooks-cursor.json`](templates/hooks/hooks-cursor.json) — Cursor config (same script, different env var)

The script branches on `$CLAUDE_HARNESS` / `$SESSION_HARNESS` and emits the JSON shape each harness expects:

| Harness | JSON shape |
|---|---|
| Claude Code | `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":...}}` |
| Cursor | `{"additional_context": ...}` |
| Copilot CLI / Gemini / OpenCode | `{"additionalContext": ...}` |

**Recommended** for any harness that supports SessionStart hooks (Claude Code, Cursor). Context compression after `/clear` or `/compact` silently drops SKILL.md from context — the hook is the only defense against this. Skip only if your harness does not support SessionStart hooks or your sessions are consistently short enough that compression never triggers.
