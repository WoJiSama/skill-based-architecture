# Executable Skill Architecture

Use this reference when a project skill must operate external systems, not only
describe project rules. The default scaffold stays rule-oriented; this is an
upgrade path for operation-heavy skills.

Executable is an execution-mode axis, not a full shape replacement. Decide it
separately from structure tier (Single-file / Folder-light / Full) and domain
topology (Single-skill / Multi-skill candidate).

## Degrees of Freedom

Before promoting a skill toward executable shape, ask: what is the most fragile
step, and how much freedom can the agent safely have?

| Freedom | Signal | Skill shape |
|---|---|---|
| High | Many valid approaches; judgment-heavy work; no fixed output contract | Pure reference or workflow prose |
| Medium | A preferred command or check exists, but parameters vary by task | Workflow prose plus inline shell or a small validator |
| Low | Fragile sequence; fixed format/API; side effects; repeated exact logic | Script/CLI-first; consider this executable shape |

Low freedom is only a pressure signal. It does not override the "at least two
pressures" gate below; do not promote a skill just because a script would look
tidy.

## When To Use

Adopt the executable shape only when at least two pressures are present:

- The skill calls external APIs, CLIs, databases, cloud services, or remote
  platforms as part of normal user tasks.
- The skill needs deterministic scripts because agents would otherwise rewrite
  fragile shell or HTTP logic repeatedly.
- Tasks have side effects such as deploys, writes, status transitions, or remote
  configuration updates.
- Callers need stable output contracts that hide raw API response shapes.
- Users need local, non-committed configuration such as API keys, base URLs,
  product codes, auth headers, or runtime paths.

If the project mostly records coding conventions, review rules, or recurring
procedures, stay with the normal `rules/`, `workflows/`, and `references/`
layout.

## Recommended Shape

```text
skills/<name>/
├── SKILL.md
├── conf/
│   └── .defaults/
├── scripts/
├── tools/
├── capability/
├── workflows/
├── references/
└── rules/
```

Responsibilities:

| Layer | Owns | Avoids |
|---|---|---|
| `scripts/` | How to execute: auth, HTTP, CLI wrappers, config loading, parsing | Business routing and user-facing prose |
| `tools/` | One atomic external operation: method/path/params/return/error/idempotency | Business triggers, fallback policy, multi-step flow |
| `capability/` | One domain business ability with a stable output contract | Cross-domain orchestration, user-environment side effects |
| `workflows/` | Full user intent, multi-step flow, confirmations, side effects | Repeating capability internals inline |
| `conf/.defaults/` | Copyable user-local config templates | Real secrets or project-owned runtime instances |

Dependency direction should stay one-way:

```text
workflows -> capability -> tools -> scripts
```

`scripts/` may also be called directly by workflows when the script is pure
execution infrastructure, such as project introspection or runtime argument
assembly.

## Contracts

Executable skills need contracts earlier than rule-only skills:

- Every `tool` declares idempotency and the exact input shape.
- Every `capability` declares a stable output contract; callers do not depend on
  raw tool fields.
- Every non-idempotent workflow has a confirmation point immediately before the
  side effect.
- Every local config value has a source order and a safe missing-value behavior.
- Every large or noisy external response defaults to a compact, decision-ready
  result: summary; precise path/line/symbol or equivalent identifiers; only the
  most important relationships; explicit truncation state; and a detail or
  cursor mechanism. This is a semantic contract, not a mandatory serialization.
- A bounded or Top-N result is a candidate view, never proof of completeness.
  Callers request more only when the current decision, key relationship, or
  semantic boundary remains unresolved.
- A tool may suggest a next query, but the suggestion is non-authoritative: the
  workflow's decision gap and stop evidence determine whether more work occurs.

## What Not To Promote

Do not create an executable skill because the structure looks more complete.
Do not add `tools/`, `capability/`, `scripts/`, or `conf/` to the default
template. Two ordinary projects should be able to adopt the base scaffold
without inheriting operation-specific directories they do not use.

Promote this shape only from project evidence gathered by
`workflows/profile-project.md`: external execution surface, side effects,
stable output contracts, local configuration, or repeated script logic.

## Validation

Minimum validation for executable skills:

- Structural checks still pass: routing sync, link checks, orphan checks.
- Contract checks cover index-to-file consistency and registered error codes.
- Script tests cover pure parsing/config logic.
- Golden tests cover CLI output that other workflows depend on.
- Scenario tests cover high-risk user intent routes when route correctness
  matters more than file shape.
