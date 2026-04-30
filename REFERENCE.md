# Reference

> **This file was split.** Previously a single 683-line document. Individual reference topics now live under [`references/`](references/) organized by subject.

## Start here

Look up what you need, not everything:

- **Laying out a new skill?** → [`references/layout.md`](references/layout.md)
- **Writing or debugging thin shells (AGENTS.md, CLAUDE.md, etc.)?** → [`references/thin-shells.md`](references/thin-shells.md)
- **Updating downstream task routing?** → edit `skills/<name>/routing.yaml`, then run `bash skills/<name>/scripts/sync-routing.sh <name> --check`
- **Updating this repo's self-hosting shell routes?** → edit [`references/self-hosting-routing.yaml`](references/self-hosting-routing.yaml), then run `bash scripts/sync-self-routing.sh` + `bash scripts/check-self-routing.sh`
- **Designing Task Closure Protocol, recording lessons, or activation verification?** → [`references/protocols.md`](references/protocols.md)
- **Picking rule file sets, navigating anti-patterns, troubleshooting, file size budgets?** → [`references/conventions.md`](references/conventions.md)

See [`references/README.md`](references/README.md) for the full topic map.

## Why this file still exists

Inbound links from `SKILL.md`, `WORKFLOW.md`, `TEMPLATES-GUIDE.md`, and the READMEs used `REFERENCE.md` as the canonical entry. Keeping this stub preserves those links while pointing readers to the new structure. New references should link to the topic file directly (e.g. `references/protocols.md#task-closure-protocol`).
