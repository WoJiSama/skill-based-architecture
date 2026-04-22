# templates/ — Pre-Built Copy-Pasteable Content

This directory holds **ready-to-copy files** for downstream projects. WORKFLOW.md Quick Start copies this tree into the target project and runs a single `sed` pass to substitute placeholders. The goal: eliminate the "Agent generated the file inline and dropped half the sections" failure mode.

## Layout

```
templates/
├── skill/                    → becomes skills/{{NAME}}/
│   ├── SKILL.md
│   ├── rules/{project-rules,coding-standards,agent-behavior}.md
│   ├── workflows/{update-rules,fix-bug,maintain-docs,subagent-driven}.md
│   ├── workflows/invoke-skill.md.example  (copy-paste template for Pattern A composition; rename and adapt)
│   ├── references/{gotchas,behavior-failures}.md
│   └── scripts/              → automated verification (lives inside the skill)
│       ├── smoke-test.sh     (fully automated structural + routing checks)
│       └── test-trigger.sh   (description trigger rate testing)
├── shells/                   → becomes repo-root entry files
│   ├── AGENTS.md / CLAUDE.md / CODEX.md / GEMINI.md
│   ├── .codex/instructions.md
│   ├── .cursor/rules/workflow.mdc
│   └── .cursor/skills/{{NAME}}/SKILL.md
├── hooks/                    → optional SessionStart injection + mechanism-level gates
│   ├── session-start              (bash, per-harness JSON branching — re-inject SKILL.md)
│   ├── agent-behavior-gate.sh     (bash, PreToolUse — enforce Admission Threshold deterministically)
│   ├── hooks.json                 (Claude Code config — SessionStart + PreToolUse)
│   ├── hooks-cursor.json          (Cursor config — same as above, per-harness wiring)
│   ├── README.md                  (rollout / tuning / false-positive mitigations, per-hook)
│   └── SECURITY.md                (trust boundary: what may vs must not be written to hook-read files)
├── checklists/               → copyable verification checklists
│   └── post-migration.md     (run after Phase 8 to verify everything)
├── migration/                → meta-level migration helpers (not per-skill)
│   ├── resume.sh             (detect where a crashed migration left off)
│   └── README.md             (usage + relation to WORKFLOW.md § Resuming)
└── protocol-blocks/          → drop-in Task Closure reinforcement
    ├── rationalizations-table.md
    ├── red-flags-stop.md
    ├── iron-law-header.md
    ├── subagent-contract.md        (5-field worker task-prompt block)
    ├── reboot-check.md              (5-question mid-task re-orientation)
    └── ambiguous-request-gate.md   (pre-routing Principle 1 check for vague verbs)
```

> `migration/` is the odd one out: it is **not** copied into the downstream project. It runs alongside the upstream repo and is invoked from the target project root via `bash "$UPSTREAM/templates/migration/resume.sh"`. See `migration/README.md`.

## Placeholders

Two kinds — each with a different "fill" mechanism:

| Marker | Meaning | Filled by |
|---|---|---|
| `{{NAME}}`, `{{SUMMARY}}`, `{{TRIGGER_PHRASES}}` | Mechanical substitution | Single `sed` pass in Quick Start |
| `<!-- FILL: … -->` | Requires human/agent judgment | Must be replaced manually; `grep -r 'FILL:'` lists all pending |

**Audit after Quick Start:** run `grep -r 'FILL:' skills/{{NAME}} AGENTS.md CLAUDE.md CODEX.md GEMINI.md .codex .cursor` — every match is a required fill, not optional.

## Byte Budgets (hard limits — enforce in review)

| Path | Budget | Enforcement |
|---|---|---|
| `shells/*` | ≤ 60 lines | Thin shells must stay thin; > 60 = content leaking in. Must include an Always Read preamble + route-before-routing check for vague verbs (see `protocol-blocks/ambiguous-request-gate.md`) — the routing table alone is not sufficient |
| `skill/rules/project-rules.md`, `skill/rules/coding-standards.md` | ≤ 20 lines, ≥ 60% must be `<!-- FILL: -->` | Rule stubs are scaffolding, not content |
| `skill/rules/agent-behavior.md` | ≤ 100 lines, fully pre-filled | Universal coding defaults. Exception to the stub-only rule — ships as content. **Growth gated** by `ANTI-TEMPLATES.md § Admission Threshold` (convention-level, ~30% hostile-prompt block rate). For mechanism-level enforcement install `templates/hooks/agent-behavior-gate.sh` — blocks 100% of tested attack classes deterministically |
| `hooks/agent-behavior-gate.sh` | ≤ 150 lines | PreToolUse gate script. False-positive mitigations (shrinking/typo-tolerance paths) live in-script; see `hooks/README.md` |
| `hooks/README.md` | ≤ 150 lines | Per-hook rollout guidance; allowed larger because it documents optional installs + tuning |
| `skill/workflows/fix-bug.md` (and other task-specific) | ≤ 80 lines | Project-specific workflows stay lean |
| `skill/workflows/update-rules.md`, `maintain-docs.md`, `subagent-driven.md` | ≤ 250 lines | Protocol-heavy workflows allowed more room |
| `protocol-blocks/*` | ≤ 40 lines each | One idea per block |
| `skill/SKILL.md` | ≤ 60 lines | Same ≤ 100 line rule as downstream SKILL.md minus the filled content |
| `skill/references/gotchas.md` | ≤ 25 lines (seed) | MUST stay near-empty — content grows post-deployment |
| `skill/references/behavior-failures.md` | ≤ 25 lines (seed) | MUST stay near-empty — agent-behavior violations logged via AAR |
| `migration/*.sh` | ≤ 200 lines | Bridge scripts; past this, refactor into libraries |

Anything over budget needs either splitting or rejection. See `ANTI-TEMPLATES.md`.

## The "Would Two Real Projects Disagree?" Test

Before adding anything to this directory, answer:

> "A Go backend microservice and a React animation site both pull this template. Would they both agree on this content?"

- **Yes** → it's structural protocol; may go in `templates/`.
- **No / probably not** → it's project-specific; move to `<!-- FILL: -->` comment or `examples/` instead.

No exceptions. If this test is hand-waved, `templates/` slides into opinionated defaults and downstream projects start looking identical.

## Anti-Drift Checks

Run these when templates change:

1. **Byte budget CI** — a 5-line shell script that fails if any file exceeds its row in the budget table above.
2. **Placeholder audit** — `grep -r '{{' templates/` lists every placeholder; must match the `sed` substitution set in WORKFLOW.md Quick Start (no orphans).
3. **FILL audit** — `grep -r 'FILL:' templates/` must return nonzero lines for `rules/`, `references/gotchas.md`, and every shell (proof that downstream is forced to write content, not just copy).
4. **Homogeneity spot-check** — run Quick Start against two toy projects of very different types (Go CLI + Next.js site) and `diff -r` the output. Skeleton files should be near-identical; `rules/`, `gotchas.md`, `SKILL.md` Always Read + Common Tasks must **not** be identical. If they are, the template overreached.
