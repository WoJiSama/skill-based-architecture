# Reference — Per-Tool Thin Shell Templates

Templates for each AI harness's required entry file. Each template below shows **only the tool-specific parts**. Combine each with the common thin-shell body in [thin-shells.md § Common Thin Shell Body](thin-shells.md#common-thin-shell-body).

Pre-built shells for the scaffolded harnesses ship under [`templates/shells/`](../templates/shells/); tools that read `AGENTS.md` can share that shell. Downstream projects should `cp -R` the tree rather than regenerate the files inline.

## AGENTS.md

`AGENTS.md` is the **universal entry** for AGENTS.md-based tools and a safe shared shell for tools that support root instruction files.

```md
# AGENTS.md

One-sentence project summary.

<!-- Paste common body here -->
<!-- Optional: add project-specific auto-triggers after the common ones -->
- Before pushing to production → run `workflows/preflight.md` (if exists)
```

## CLAUDE.md

```md
# CLAUDE.md

<!-- Paste common body here (routing + auto-triggers) -->
```

## CODEX.md

```md
# CODEX.md

<!-- Paste common body here -->
<!-- Compatibility mirror for harnesses that explicitly read CODEX.md. -->
```

## .cursor/rules/*.mdc

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

**Note:** Set `alwaysApply: true` so Cursor always sees the routing bootstrap, regardless of which files are open. Use the shorter opening line ("Formal rules live in `skills/`…") to stay within the `.mdc` size budget.

## .codex/instructions.md (optional)

Modern Codex CLI reads `AGENTS.md` as the canonical project instruction file. `.codex/instructions.md` is an optional secondary mirror — only add it if your specific harness or downstream tooling explicitly reads it. If you do, paste the common body just like the other shells.

## .windsurf/rules/*.md

```md
---
trigger: always
---

<!-- Paste common body here, with these adjustments: -->
<!-- 1. Opening line: "Formal rules live in `skills/`." (shorter form) -->
<!-- 2. Append at end: "Conflicts → formal docs in `skills/` win." -->
<!-- Note: Auto-Triggers section is optional for Windsurf -->
```

## GEMINI.md

Gemini CLI reads `GEMINI.md` at the repo root (configurable via `.gemini/settings.json`). It also scans parent directories and subdirectories for additional `GEMINI.md` files, concatenating all discovered context. Place the thin shell at the repo root.

```md
# GEMINI.md

<!-- Paste common body here (routing + auto-triggers) -->
```

`.gemini/` holds Gemini CLI configuration (`settings.json`, `.env`), not rule content. If you need Gemini to also read `AGENTS.md`, configure it in `.gemini/settings.json`:

```json
{
  "context": {
    "fileName": ["GEMINI.md", "AGENTS.md"]
  }
}
```

## Claude Code Native Skills

<!-- external-fact: verified=2026-04-28 source=https://code.claude.com/docs/en/skills -->

Claude Code has two relevant mechanisms:

- `CLAUDE.md` memory/instructions — required compatibility shell for this architecture.
- Native skills in `.claude/skills/<skill-name>/SKILL.md` — optional Claude-only registration surface.

Keep `CLAUDE.md` as the mandatory project entry. If you also create a native Claude project skill, make it a thin registration stub that points to `skills/<name>/SKILL.md`; do not duplicate rule bodies under `.claude/skills/`.

Current Claude Code same-name precedence is **enterprise > personal (`~/.claude/skills`) > project (`.claude/skills`)**. Plugin skills use a `plugin-name:skill-name` namespace. If a skill and `.claude/commands/` command share a name, the skill wins.

Implication: a project `.claude/skills/review` does not override a user's `~/.claude/skills/review`. Prefer project-specific names such as `<project>-review` or `<project>-workflow`, and rely on root `CLAUDE.md` + SessionStart hook to route project rules.

`.claude/` should contain settings, hooks, commands, and optional native skill stubs only. Place all rule/workflow bodies in `skills/<name>/`. If any instruction-like files exist in `.claude/`, follow the thin-shell principle:

```md
# .claude/CLAUDE.md (if used)

All rules and workflows live under `skills/`.
See root `CLAUDE.md` for entry point.
```

## Tool Compatibility Summary

<!-- external-fact: verified=2026-04-28 source=https://docs.cursor.com/en/context -->
<!-- external-fact: verified=2026-04-28 source=https://code.claude.com/docs/en/skills -->
<!-- external-fact: verified=2026-04-28 source=https://developers.openai.com/codex/guides/agents-md -->
<!-- external-fact: verified=2026-04-28 source=https://docs.windsurf.com/windsurf/cascade/memories -->
<!-- external-fact: verified=2026-04-28 source=https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md -->
<!-- external-fact: verified=2026-04-28 source=https://opencode.ai/docs/rules/ -->

| Tool | Discovery mechanism | Required entry | Must have routing bootstrap? |
|---|---|---|---|
| **Cursor** | Uses project skill registration under `.cursor/skills/` for this scaffold | `.cursor/skills/<name>/SKILL.md` | Yes |
| **Cursor rules** | `.cursor/rules/*.mdc` (`alwaysApply: true`) | `.cursor/rules/workflow.mdc` | Yes |
| **Claude Code** | Reads root `CLAUDE.md`; native skills scan `.claude/skills/` with enterprise > personal > project same-name precedence | `CLAUDE.md`; optional `.claude/skills/<project-name>/SKILL.md` stub | Yes |
| **Codex CLI** | Reads the `AGENTS.md` hierarchy; `AGENTS.override.md` can override project guidance | `AGENTS.md`; keep `CODEX.md` / `.codex/instructions.md` only as compatibility mirrors if your harness reads them | Yes |
| **Windsurf** | Reads workspace memories/rules such as `.windsurf/rules/`; can also infer memories from `AGENTS.md` | `.windsurf/rules/*.md` or shared `AGENTS.md` shell | Yes |
| **Gemini CLI** | Reads `GEMINI.md` at repo root (+ parent/child dirs) | `GEMINI.md` | Yes |
| **Copilot CLI** | Reads `AGENTS.md` | `AGENTS.md` (shared shell) | Yes |
| **OpenCode** | Reads `AGENTS.md` | `AGENTS.md` (shared shell) | Yes |
| **Other agents** | Reads `AGENTS.md` | `AGENTS.md` | Yes |

**All entries must contain a routing bootstrap** — natural-language-only instructions ("Scan skills/") get lost during context summarization in long conversations. In generated scaffolds, `routing.yaml` is the single source for route data; shells only preserve the lookup protocol.
