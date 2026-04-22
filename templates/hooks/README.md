# hooks/ — Harness Integration Points

Two hooks ship here. Both are **opt-in**. Copy the relevant JSON into your harness's config directory and they activate.

| Hook | Script | Fires on | Purpose |
|---|---|---|---|
| SessionStart | `session-start` | startup / `/clear` / `/compact` | Re-inject `skills/{{NAME}}/SKILL.md` into context so routing survives context summarization |
| PreToolUse (optional) | `agent-behavior-gate.sh` | every Write/Edit | Mechanism-level enforcement of the Admission Threshold for `rules/agent-behavior.md` |

See `SECURITY.md` for the trust boundary around hook-injected files.

## When to install agent-behavior-gate.sh

The Admission Threshold in `templates/ANTI-TEMPLATES.md` is a convention gate — Agents reading it will usually respect it, but tested against 10 adversarial prompts it only blocks ~30% on Sonnet and ~11% on Haiku (see that file's `§ Gate Effectiveness` section for data).

This hook turns the gate into a mechanism:

| Scenario | Gate without hook | Gate with hook |
|---|---|---|
| Solo maintainer, Sonnet/Opus, reviews every diff | adequate | overkill |
| Team repo, any committer, any model | 70% bypass rate | 100% blocked |
| Downstream using Haiku-class models | 89% bypass rate | 100% blocked |
| Automated pipeline, no human review | unsafe | safe |

**Recommendation:** solo experimental repos — skip; team or product repos — install.

## How agent-behavior-gate.sh reduces false positives

The gate tries hard not to block legitimate maintenance. Three paths bypass evidence requirements:

1. **Shrinking edits always pass** — any edit with negative line-delta (deletion, merging principles, trimming bullets) never touches the evidence check. This is intentional: the gate wants you to be able to reduce the file back to cap without friction.
2. **Typo/style fixes pass** — same line count AND char-delta within ±20 (configurable via `AGENT_BEHAVIOR_GATE_TYPO_TOLERANCE`). Covers misspellings, punctuation, small rewordings.
3. **Override env var** — `AGENT_BEHAVIOR_GATE_OVERRIDE=1` bypasses all checks and logs to stderr. Use for legitimate maintenance the hook misidentifies.

What still triggers the gate:

- Adding a new principle (multi-line growth)
- Adding a bullet to an existing principle (+1 line)
- Appending a meaningful clause to an existing bullet (same line, +20+ chars — catches the "just a few words" attack)
- Expanding a ✓ Check sentence significantly

## Install — Claude Code

```bash
# Either copy the hooks config standalone…
cp templates/hooks/hooks.json .claude/hooks.json

# …or merge the two "hooks" arrays into your existing .claude/settings.json.
# Both approaches work — settings.json takes precedence if both exist.

# ensure jq is available (parsing tool call JSON)
which jq || brew install jq  # or: apt-get install jq
```

**Schema check:** Claude Code CLI v2.1+ requires the **nested** hooks format (`"hooks": [{"type":"command","command":"..."}]`) inside each matcher object — **not** a flat `"command": "..."` field on the matcher. Both files in this directory use the nested format. If your hooks fire but never block, verify the schema (confirm via `claude --print --verbose --output-format=stream-json --include-hook-events ...`: the `hook_started` events should pair with block/denial results).

## Install — Cursor

```bash
cp templates/hooks/hooks-cursor.json .cursor/hooks.json
```

Cursor's PreToolUse hook format may differ from Claude Code's. If the gate doesn't fire in Cursor, fall back to convention-level enforcement or wire the script via Cursor's equivalent trigger.

## Install — other harnesses

The script is harness-agnostic: it reads a Claude-Code-compatible JSON on stdin, writes reasons to stderr, and exits 0/2. Harnesses with a different hook contract will need an adapter.

## Rollout strategy for repos currently over cap

If your `rules/agent-behavior.md` is already over the 100-line `HARD_CAP`, activating the hook will immediately block any growing edit. Two rollout options:

1. **Shrink first, then activate** — refactor the file down to ≤ 100 lines before copying `hooks.json` into place. Shrinking edits pass regardless.
2. **Activate in WARN mode** — set `AGENT_BEHAVIOR_GATE_WARN=1` in the session environment. The hook reports every would-block reason to stderr but exits 0. Use this for a transition period while shrinking.

## Tuning

All thresholds are env-var overridable. Typical tunings:

| Variable | Default | When to change |
|---|---|---|
| `AGENT_BEHAVIOR_GATE_HARD_CAP` | 100 | Raise to 150 if your project legitimately needs more principles and you've documented why |
| `AGENT_BEHAVIOR_GATE_TYPO_TOLERANCE` | 20 | Raise to 40 if your team makes larger copy-edits frequently (accepts some smuggling risk) |
| `AGENT_BEHAVIOR_GATE_PATH` | `templates/skill/rules/agent-behavior.md` | Point at a different file if your skill uses a non-standard layout |
| `AGENT_BEHAVIOR_GATE_EVIDENCE` | `templates/skill/references/behavior-failures.md` | Same — adjust for custom layout |

## Measured effectiveness (2026-04)

### Hook firing and blocking, by runtime

Tested empirically on this repo with the nested schema shown above:

| Runtime | Hook fires | Block (exit 2 + stderr) honored |
|---|---|---|
| **Interactive Claude Code CLI session** | ✅ yes | ✅ **yes — Edit rejected, stderr shown to user** |
| `claude --print` subprocess (headless) | ✅ yes (visible in `--debug hooks`) | ❌ no — `--print` auto-approves for pipeline use |
| Agent SDK subagent (Task/Agent tool, `isolation: worktree`) | ❌ no | — |

**Implication:** the hook provides meaningful protection **only for interactive user edits**. Automated pipelines (`--print`) and agent-dispatched edits (Task/Agent SDK) bypass the hook regardless of schema. For those surfaces, use git-level guards (CODEOWNERS + CI) described in `templates/ANTI-TEMPLATES.md § Gate Effectiveness`.

### Hook script logic (validated via dry-run pipe)

Tested independently of any Claude Code runtime by piping simulated tool-input JSON to the script:

| Test | Expected | Result |
|---|---|---|
| Non-gated file | allow silently | ✅ |
| Shrinking edit (Δlines < 0) | allow | ✅ |
| Typo fix (same line, Δchars ≤ 20) | allow | ✅ |
| Same-line +40 chars (M-attack) | block | ✅ |
| New principle (+5 lines) | block | ✅ |
| `AGENT_BEHAVIOR_GATE_OVERRIDE=1` | allow with ack to stderr | ✅ |
| `AGENT_BEHAVIOR_GATE_WARN=1` | print reasons but allow | ✅ |

Script logic passes 7/7. Correctness is not the limitation — **runtime coverage is**.

### Convention-gate-only measurements (2026-04)

For comparison: the `ANTI-TEMPLATES.md § Admission Threshold` text (convention level, hook inactive) was tested against 10 adversarial prompts via subagents. Aggregate pass rate: Haiku ~11%, Sonnet ~30%. See that file's `§ Gate Effectiveness` for the per-attack breakdown.

Hook + convention combined: interactive-session edits 100% blocked on both models (hook); agent-delegated edits 11–30% blocked (convention only, depending on model).
