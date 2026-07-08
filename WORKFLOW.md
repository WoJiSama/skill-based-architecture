# Migration Workflow

Step-by-step procedure for restructuring a long SKILL.md or scattered rules into Skill-based architecture.

## Quick Start

For small-to-medium projects, run the scaffold and fill in content. Skip the full 9-phase process.

### Which path should I take?

Answer these questions to decide:

1. **Is the total rule content > 150 lines across all files?** (Count SKILL.md + AGENTS.md + .cursor/rules/ + README rules sections combined, not just one file)
2. **Are rules duplicated across 2+ entry files?** (e.g., AGENTS.md and .cursor/rules/ overlap)
3. **Do you have recurring pitfalls that keep being rediscovered?** (same debugging lesson learned twice)

| Answers | Path |
|---------|------|
| All No | **Minimal single SKILL.md** — use the [minimal starter template](TEMPLATES-GUIDE.md#minimal-starter-template) |
| 1 Yes, others No | **Quick Start scaffold** below — run the script, fill TODOs |
| 2+ Yes | **Full 9-phase migration** — follow [`workflows/full-migration.md`](workflows/full-migration.md) |

If the project has only one small skill, no duplicated entry files, and no growing rule/reference sprawl yet, **do not force the full architecture immediately**. Start with a single well-written `SKILL.md` using the minimal starter template in [TEMPLATES-GUIDE.md](TEMPLATES-GUIDE.md), and upgrade only when one of the conditions above becomes true.

**Step 1 — Scaffold from pre-built templates.** Don't regenerate file bodies inline — the upstream ships byte-for-byte files under [`templates/`](templates/). Copy them into the target project and run a single `sed` pass.

```bash
# Assumes skill-based-architecture is cloned as a sibling, or $UPSTREAM points at it.
UPSTREAM="${UPSTREAM:-../skill-based-architecture}"
NAME="<name>"          # project identifier, kebab-case
SUMMARY="<one-line project summary>"

# 1) Copy skill tree: templates/skill/ → skills/$NAME/
mkdir -p "skills/$NAME"
cp -R "$UPSTREAM/templates/skill/." "skills/$NAME/"
mv "skills/$NAME/SKILL.md.template" "skills/$NAME/SKILL.md"

# 2) Copy entry shells to repo root (AGENTS.md, CLAUDE.md, CODEX.md, GEMINI.md, .cursor/)
cp -R "$UPSTREAM/templates/shells/." .

# 3) Cursor registration entry: materialize SKILL.md, then rename the {{NAME}} placeholder directory
mv ".cursor/skills/{{NAME}}/SKILL.md.template" ".cursor/skills/{{NAME}}/SKILL.md"
mv ".cursor/skills/{{NAME}}" ".cursor/skills/$NAME"

# 4) Substitute mechanical placeholders (macOS sed syntax; on Linux drop the '' after -i)
find "skills/$NAME" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor \
  -type f \( -name '*.md' -o -name '*.mdc' \) \
  -exec sed -i '' \
    -e "s/{{NAME}}/$NAME/g" \
    -e "s/{{SUMMARY}}/$SUMMARY/g" \
    {} +

# 5) Record the upstream baseline so future "update from upstream" is automatic
UPSTREAM_REF="$(git -C "$UPSTREAM" config --get remote.origin.url 2>/dev/null || printf '%s' "$UPSTREAM")"
UPSTREAM_SHA="$(git -C "$UPSTREAM" rev-parse HEAD 2>/dev/null || true)"
if [ -n "$UPSTREAM_SHA" ]; then
  printf 'upstream: %s\nsynced_sha: %s\nsynced_date: %s\n' \
    "$UPSTREAM_REF" "$UPSTREAM_SHA" "$(date +%F)" > "skills/$NAME/.upstream-sync"
fi

# 6) (Optional) install hooks — router restore, workflow-state hints, behavior gate
# mkdir -p .claude/hooks
# cp "$UPSTREAM/templates/hooks/session-start" .claude/hooks/session-start
# cp "$UPSTREAM/templates/hooks/workflow-state" .claude/hooks/workflow-state
# cp "$UPSTREAM/templates/hooks/agent-behavior-gate.sh" .claude/hooks/agent-behavior-gate.sh
# chmod +x .claude/hooks/session-start .claude/hooks/workflow-state .claude/hooks/agent-behavior-gate.sh
# test -f .claude/settings.json || cp "$UPSTREAM/templates/hooks/hooks.json" .claude/settings.json
# # If settings exists, merge the top-level "hooks" object instead.

# 7) Done — scaffold equivalent to completing Phases 3–7 in one pass
echo "✅ Scaffold created at skills/$NAME/"
echo "Next: ask the agent to profile the project, fill the remaining project-specific markers, and run smoke-test.sh for Phase 8."
echo "If this step fails partway through, run: rm -rf skills/$NAME .cursor/skills/$NAME && rerun this script."
```

**Why copy instead of generate?** Inline heredoc generation lost sections under pressure (Auto-Triggers dropped, routing tables mangled, description field left as trigger-phrase-less boilerplate). The `templates/` tree is the single source of truth — see [`templates/README.md`](templates/README.md) for byte budgets, placeholder conventions, and the "would two real projects disagree?" admission test. Template source files use `SKILL.md.template` so skill loaders do not treat them as real skills when this repo is installed; Quick Start renames them into real `SKILL.md` files after copying.

**Step 1.5 — Profile the project before filling content.** Follow `skills/$NAME/workflows/profile-project.md` (copied from `templates/skill/workflows/profile-project.md`) before writing project-specific `<!-- FILL: -->` content. Start with a user brainstorm gate: ask whether the user wants to brainstorm the target project's purpose, modules, common tasks, boundaries, and known pitfalls.

- If the user says yes / "没问题" / otherwise agrees: **do not read code yet**. First run the brainstorm, restate a short calibrated summary, and ask the user to correct or confirm it.
- Treat user feedback as **calibration input**, not verified fact. Use it to check whether your initial summary is aligned, then read local code/config to verify it.
- After the brainstorm feedback, inspect real evidence (README, build files, CI, entry points, configs, module layout, tests) and classify conclusions as `Confirmed from code/config`, `User-calibrated`, `Inferred`, or `Unknown`.
- Only then write project content into `rules/`, `workflows/`, `references/`, and `SKILL.md`. `rules/` and procedural `workflows/` must come from confirmed evidence, not brainstorm-only claims.
- If the user declines brainstorming or explicitly asks to skip it, proceed with code-first evidence scanning and mark unclear conclusions as `Unknown` instead of guessing.

**Step 2 — Fill content.** Two kinds of placeholders, two different mechanisms:

| Marker | How to fill |
|---|---|
| `{{NAME}}`, `{{SUMMARY}}` | Done by the `sed` pass in Step 1 |
| `<!-- FILL: … -->` | Requires judgment — you must read each marker and write real project content |

Agent-facing check for pending project-specific content:

```bash
grep -rn 'FILL:' "skills/$NAME" AGENTS.md CLAUDE.md CODEX.md GEMINI.md .cursor
```

Every hit is mandatory for the agent before shipping the skill. A user should not have to interpret these markers; they are migration work items.

Always Read lists, Common Tasks, and shell bootstraps are generated from `skills/$NAME/routing.yaml`. Edit that manifest, then run:

```bash
bash "skills/$NAME/scripts/sync-routing.sh" "$NAME"
```

Do not hand-edit generated Always Read / Common Tasks in `SKILL.md` or generated blocks in thin shells.

**Step 3 — Verify.** After all FILLs are resolved, run the automated smoke test:

```bash
# Fully automated — checks structure, routing, placeholders, line budgets, and description quality
bash "skills/$NAME/scripts/smoke-test.sh" "$NAME"

# Routing manifest drift check (also run by smoke-test when routing.yaml exists)
bash "skills/$NAME/scripts/sync-routing.sh" "$NAME" --check

# (Optional) Surface rules/ or references/ files with zero inbound links
(cd "skills/$NAME" && bash scripts/audit-orphans.sh)
```

`smoke-test.sh` covers everything: file existence, line count budgets, placeholder/FILL residue, description word count / trigger phrases / keyword-stuffing, routing-manifest drift, routing completeness (parses Common Tasks and verifies every referenced file exists), description consistency between SKILL.md and Cursor entry, shell bootstrap consistency, SessionStart-hook presence, broken markdown links, and content conformance (§9, when a `conformance.yaml` exists). Zero manual input needed.

For description-quality judgment (too narrow / weak or off-language trigger phrases) — re-read the `description` block aloud and check it uses the user's actual phrasing. `smoke-test.sh` now WARNs on the over-broad / keyword-stuffed case (> 12 quoted phrases), but no script substitutes for the rest of that judgment.

For complex migrations (large projects, heavily scattered rules), follow [`workflows/full-migration.md`](workflows/full-migration.md) for the Phase 1–9 process.

## If a Phase Crashes

Migration is a one-shot operation. If the shell exits mid-`sed`, `/compact` fires, or the laptop reboots, **don't** rerun from Phase 1 on a half-templated tree — placeholder residue and partial files will produce misleading phase passes.

```bash
rm -rf skills/$NAME .cursor/skills/$NAME
# then rerun the Quick Start scaffold from the top
```

Use `bash skills/$NAME/scripts/smoke-test.sh $NAME --phase N` to verify a specific phase before moving on (the full smoke test only passes after Phase 8). Phase 9 is a manual attestation: at least one row in `workflows/task-closure.md` § Rationalizations to Reject came from a real pressure test.

## Upgrading an Existing Downstream Project

When upstream releases new templates, hooks, scripts, or workflow improvements, do **not** re-migrate. Use the agent-led upstream refresh path documented at [`workflows/upgrade-downstream.md`](workflows/upgrade-downstream.md). The user just says "上游项目更新了,帮我更新一下" or "update from upstream", and the agent follows `skills/<name>/workflows/update-upstream.md`.
