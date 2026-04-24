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

<always-applicable>

**Always Read (every task, in addition to route-specific reads)**

- `skills/<name>/rules/project-rules.md`
- `skills/<name>/rules/coding-standards.md`
- `skills/<name>/rules/agent-behavior.md` — universal behavior defaults

**Route-before-routing check**: if the request contains vague improvement verbs ("refactor / clean up / optimize / make it better") **without** a concrete module/file or verifiable outcome → stop and ask for scope. See `skills/<name>/protocol-blocks/ambiguous-request-gate.md` if present.

</always-applicable>

<task-routing>

**Quick Routing (survives context truncation)**

| Task | Required reads | Workflow |
|------|---------------|----------|
| Fix bug | `rules/project-rules.md` + `rules/coding-standards.md` | `workflows/fix-bug.md` |
| Add feature X | `rules/<domain>-rules.md` | `workflows/<task>.md` |
| Other | `rules/project-rules.md` | Check `workflows/` for closest match |

</task-routing>

## Auto-Triggers

- **New task in same session** → re-read `skills/<name>/SKILL.md`, re-match routing, re-read all required files. "I already read it" is not valid — context compresses, routes differ.
- Before declaring any non-trivial task complete → run Task Closure Protocol (see `workflows/update-rules.md`)
- Skip only for: formatting-only, comment-only, dependency-version-only, or behavior-preserving refactors
- When user asks to "record/save/remember" something → project-level knowledge goes to `skills/<name>/` docs; personal preferences go to agent memory
```

**Why inline routing instead of just "Scan skills/"?** The "Scan skills/*/SKILL.md" instruction is natural language that gets lost during context summarization. The inline routing table embeds the essential task→file mapping directly, so the agent retains actionable routing even after summary truncation.

**Why Auto-Triggers?** A skill knows *how* to do something; the project entry tells the Agent *when* to do it. Auto-Triggers encode event→action mappings so the Agent proactively runs workflows at the right moment without waiting for a prompt.

## XML-Tag Injection

The thin shells above wrap two sections in literal XML-style tags: `<always-applicable>…</always-applicable>` and `<task-routing>…</task-routing>`. This is intentional and **load-bearing**.

### Why

Plain markdown headings (`## Always Read`, `## Quick Routing`) are navigation landmarks — useful for a human reader, but they carry no structural boundary at the token level. When a harness runs `/compact` or client-side summarization, the heading can be merged into a summary alongside adjacent prose, and the model loses the cue that "everything under this heading is a hard constraint."

XML-style tags survive that compression better for three reasons:

1. **Discrete boundary** — `<always-applicable>` and `</always-applicable>` bracket the content; a summarizer either keeps the tags (and therefore the block) or drops them (conspicuously removing the section). Markdown headings lack that atomic feel.
2. **Pattern recognition** — LLMs are trained on XML-wrapped system prompts and tool schemas, so they treat tag-bounded regions as higher-precedence constraint blocks than free prose.
3. **Separation of constraint types** — two tags, two roles: always-applicable content runs on *every* task; task-routing content fires *conditionally* on task match. Keeping them in separate blocks prevents the agent from treating the routing table as a universal rule or the Always Read list as optional.

The pattern is adopted from [OpenSpec](https://github.com/Fission-AI/OpenSpec)'s `<context>` / `<rules>` injection approach, adapted to our routing-table model.

### The two tags we standardize on

| Tag | Wraps | Runs on |
|---|---|---|
| `<always-applicable>` | Always Read list + universal gates (route-before-routing, session discipline) | **Every task**, no match required |
| `<task-routing>` | Task → Required reads → Workflow table | **Only the matched row**, task-dependent |

### Rules of use

- The tags are pseudo-XML literal text — not validated HTML. All harnesses in the compatibility table below preserve them as-is in the agent's context.
- **Do not nest** the two tags. They are siblings, not parent/child.
- **Do not reuse** the tag names for other purposes in the same file. The load-bearing role depends on the agent seeing them in exactly one context each.
- **Do not promote** content out of the tags without a replacement structural marker, or the compression-resistance benefit is lost.
- Tags take **no attributes** — just `<always-applicable>` and `</always-applicable>`.

### When NOT to use

- Thin shells under ~20 lines with a single routing line: tags add noise without protection.
- Skill files whose entire body is already short enough to fit under the 100-line SKILL.md budget *and* whose routing is under 5 rows: plain headings may be sufficient. Add tags when compression risk is real (long sessions, multi-skill repos, harness with aggressive summarization).
- A harness that strips `<` / `>` from model context — none of the harnesses in the compatibility table below do this, but test first if you add a new harness.

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

## Context Hygiene Playbook

Context-window management is a **user** skill, not only an agent skill. Skills and XML-tag injection raise the odds that the agent follows routing, but they cannot fix a session that has already drifted. Use this playbook to spot drift early and reset cleanly.

### When to `/clear` before a new task

The decision is cheaper than it feels: re-reading a few files costs seconds, but carrying stale context costs hours of wrong-direction work.

| Last task | New task | Action |
|---|---|---|
| Bug fix in `src/auth` | New feature in `src/auth` | **Keep** — file state, imports, related errors still relevant |
| Bug fix in `src/auth` | Unrelated refactor in `src/billing` | **/clear** — auth context is dead weight; will hallucinate imports |
| Planning/brainstorm (no edits) | First implementation pass | **Keep** — planning *is* the scaffold for the edits |
| Implementation pass done | Review/refinement of those edits | **Keep** — diff context is needed |
| Any finished task | Any unrelated task | **/clear** — old file reads and errors will bias the next task |

**Rule of thumb**: if the new task matches a **different row** in the Common Tasks routing table, `/clear`. Same row → keep.

### Diagnosing "is my skill actually loaded?"

This is two questions the user should separate:

1. **Did the client put the file into the context window?** — a *client* question, not a model question.
2. **Did the model actually follow what was in the file?** — a *model* question that only matters if #1 is yes.

The wrong diagnosis wastes hours. Check #1 first.

| Harness | How to inspect loaded memory files |
|---|---|
| Claude Code | `/context` — shows Memory files; look for `CLAUDE.md` in the list |
| Cursor | Agent side panel → Context inspector (or check which `.mdc` rules have `alwaysApply: true` applied) |
| Codex CLI | Check `.codex/` discovery output at session start |
| Gemini CLI | Run with `--debug`; `GEMINI.md` load status prints at startup |
| Other | Consult the harness's documentation for "context inspection" or "loaded rules" |

**If the shell file is missing from the loaded list**: discovery failure. Check case-sensitive filename, harness config (e.g. `.gemini/settings.json` `context.fileName`), then restart the session.

**If the shell file is loaded but the agent still ignores it**: compliance failure. Don't /clear immediately — it erases diagnostic value. First try:
1. *"Read `SKILL.md` and list the Common Tasks routes you see."* — forces the agent to show its routing view.
2. *"This task maps to `<route>`. Re-read the required files listed there, then proceed."* — steers without resetting.
3. If the skill relies on XML-tag injection, check whether the literal strings `<always-applicable>` / `<task-routing>` still appear in the context inspector — if summarization stripped them, the tags lost their load-bearing role and `/clear` + SessionStart hook reload is the only fix.

### Manual nudges when the agent routes wrong

Drop-in phrases for when the agent picks the wrong workflow, invents a file, or skips re-reading:

- **"Re-read `SKILL.md` and follow the route for `<task type>`."** — resets the router without a full /clear.
- **"Before continuing, confirm which Common Tasks row this maps to, and list the required reads."** — forces the agent to announce routing before acting.
- **"You read those files earlier. Context may have compressed — re-read `<file>` before this step."** — explicit permission for re-reads, matching the Session Discipline principle in `SKILL.md`.
- **"Stop. This is a `<Lite|Folder-light|Full>` scope — don't expand beyond it."** — when the agent starts adding structure you didn't ask for (see Progressive Rigor in `SKILL.md`).

### Long-session hygiene

For sessions longer than ~2 hours of active editing:

1. **Checkpoint every ~30 minutes** — ask the agent for a one-sentence summary of completed work. This gives you a clean `/clear` boundary when needed.
2. **Watch for routing blur** — if the agent cites file paths not in your routing table, proposes fixes that contradict known gotchas, or stops quoting `✓ Check:` sentences when closing tasks: context has compressed. Nudge with a re-read phrase; if two or more of these trigger, `/clear` is non-negotiable.
3. **After `/compact`** — the SessionStart hook re-injects `SKILL.md` (if installed), but inline edit state is lost. Remind the agent of current file state in one short message before the next edit.
4. **Before shipping a commit** — run the Task Closure Protocol. It catches drift accumulated across the session.
