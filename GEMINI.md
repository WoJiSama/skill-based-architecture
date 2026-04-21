# GEMINI.md

This repo is the **skill-based-architecture** meta-skill itself. Formal docs live at the repo root (self-hosting layout). Read [SKILL.md](SKILL.md) first — it is the router.

## Quick Routing (survives context truncation)

| Task | Required reads | Workflow |
|------|---------------|----------|
| Migrate a downstream project's rules to skill-based architecture | `SKILL.md` + `WORKFLOW.md` | Follow `WORKFLOW.md` Quick Start + 9 phases |
| Edit or extend `templates/` | `SKILL.md` + `templates/README.md` + `templates/ANTI-TEMPLATES.md` | "结构可复用,内容禁止预制" |
| Add or revise a skill design principle in `SKILL.md` | `SKILL.md` + `references/layout.md` | ≤ 100 lines; every principle needs `✓ Check:` |
| Fix a bug in scripts or templates | `SKILL.md` + `templates/skill/scripts/smoke-test.sh` | Run smoke-test before and after |
| Other | `SKILL.md` | Scan `WORKFLOW.md` for closest phase |

## Auto-Triggers

- **New task in same session** → re-read `SKILL.md`, re-match the route above, re-read all required files.
- Before declaring any non-trivial task complete → run Task Closure Protocol (`templates/skill/workflows/update-rules.md`)

## Red Flags — STOP

- "Just this once I'll skip the AAR" → stop.
- "Let me pre-fill a gotchas example so the template feels complete" → stop.
