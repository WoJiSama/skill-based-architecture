# References — Index

The root [`REFERENCE.md`](../REFERENCE.md) used to be a single 683-line document. It is now a stub; the material lives here, split by topic.

## Topic directory

| File | Covers | When to read |
|---|---|---|
| [layout.md](layout.md) | Recommended directory layout, `SKILL.md` template, project boundaries, multi-skill projects, Prompt/Context/Harness positioning | Starting a new skill or deciding where things belong |
| [thin-shells.md](thin-shells.md) | `.cursor` registration entry, common thin-shell body, per-tool shell templates (AGENTS/CLAUDE/CODEX/GEMINI), tool compatibility matrix, SessionStart hook | Wiring a skill into a new harness or debugging silent activation |
| [protocols.md](protocols.md) | Meta-workflow templates, Task Closure Protocol, recording threshold (2/3), recording destination guide, generalization rule, when references alone are not enough, skill activation verification | Designing self-evolution behavior or deciding where to record a new lesson |
| [conventions.md](conventions.md) | Common rule file sets by project type, decision guide, what to preserve vs remove, anti-patterns, troubleshooting, file size guidelines, naming conventions, optional CI validation | Migration decisions, size budgets, or diagnosing a broken skill |

## How these relate to the root `REFERENCE.md`

Root `REFERENCE.md` is a stub pointing here. Inbound links from `SKILL.md`, `WORKFLOW.md`, `TEMPLATES-GUIDE.md`, and the READMEs still resolve; new references should link to the topic file directly (e.g. `references/thin-shells.md#tool-compatibility-summary`).
