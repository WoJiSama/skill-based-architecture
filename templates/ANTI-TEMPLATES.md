# ANTI-TEMPLATES — Things We Intentionally Do NOT Pre-Build

This file exists so future maintainers (including agents) have to pass through a "why was this rejected?" gate before adding content to `templates/`. Over time the temptation is to put "a reasonable default" here. This list is the counter-pressure.

## Rejected

### Default lint/format rules
- **Why rejected:** language- and project-specific. A Go project's lint set has nothing in common with a React project's. Pre-filling this makes downstream skills lie about what they actually enforce.
- **Where it should go:** each project's `rules/coding-standards.md`, filled via `<!-- FILL: -->`.

### Default commit message format
- **Why rejected:** Conventional Commits is *not* universal. Some teams use Gitmoji, some use plain English, some have custom prefixes for ticket IDs. Predefining it tells downstream "this is how we commit" when the upstream doesn't know.
- **Where it should go:** project-specific `rules/` file or `workflows/commit.md` if the team has one.

### Predefined Common Pitfalls entries
- **Why rejected:** pitfalls come from real debugging. Pre-filling them with generic examples ("don't forget to handle null") is noise — the whole point of the gotchas file is that every entry was paid for in wasted hours.
- **Where it should go:** `references/gotchas.md` grows organically via AAR. Template ships this file **empty**.

### Default directory structure ("src/, test/, docs/")
- **Why rejected:** every language and framework has its own conventions. A Rust project has `src/` but a Next.js project has `app/`, a Go project has `cmd/`, a Python project has the package at root. Predefining is wrong for the majority.
- **Where it should go:** `rules/project-rules.md`, filled once the project's actual layout is known.

### Default test framework choice / test coverage threshold
- **Why rejected:** opinionated. Some projects use `pytest`, some use `unittest`, some are untested legacy. The 80% coverage number in common rules is itself a soft default — the template should not harden it.
- **Where it should go:** `rules/coding-standards.md` or a `rules/testing-rules.md` written by the project.

### Pre-populated "Common Tasks" entries in SKILL.md
- **Why rejected:** the whole value of Common Tasks routing is that it reflects *this project's* actual recurring tasks. A generic list ("Add feature", "Fix bug", "Refactor") teaches agents to route generically.
- **Where it should go:** `<!-- FILL: -->` markers in the SKILL.md template with one concrete example (`Fix bug`) so the shape is clear.

### Trigger phrases in the `description` field
- **Why rejected:** these are the single highest-value piece of project knowledge for skill activation, and they must come from real user language. A generic "This skill should be used when the user asks to 'do X'" trains the agent to never match.
- **Where it should go:** `<!-- FILL: -->` comment forcing the author to stop and think about what their users actually say.

### Concrete subagent task specs (worked examples of Goal/Inputs/Outputs/Forbidden/Acceptance)
- **Why rejected:** the `subagent-driven.md` workflow and `subagent-contract.md` block ship the *five-field protocol*; the actual contract content is entirely project-specific. Shipping a worked example tempts downstream agents to copy the example fields instead of writing their own, which defeats the point — the contract's value comes from being forced to articulate acceptance criteria for *this* task.
- **Where it should go:** each dispatch writes its own contract inline. The protocol-block is a fill-in form, not a sample.

### Subagent type registries / harness-specific dispatch code
- **Why rejected:** Claude Code's `Task` tool, Cursor's agent modes, and other harnesses have incompatible subagent primitives. Predefining a "use this subagent type for X" mapping would lie to every harness except one.
- **Where it should go:** nowhere in `templates/`. Harness-specific runtime decisions belong in each project's own tooling, outside the skill contract.

### Plugin marketplace manifests (`.claude-plugin/marketplace.json`)
- **Why rejected:** out of scope for the current plan. Adding packaging metadata turns `templates/` into a distribution mechanism and invites a different class of drift (version pinning, plugin schemas). Revisit as a separate feature.

## Admission Threshold for Behavioral Principles

`rules/agent-behavior.md` ships as **pre-filled content** (not a `<!-- FILL: -->` stub). Every principle it contains runs in every session on every downstream project. It is an Always Read file, which makes adding to it disproportionately expensive compared to any other file in this directory.

**Gate** — a new behavioral principle may be added to `rules/agent-behavior.md` **only if one of these holds**:

1. **Evidence of a real miss** — an AAR entry or a `references/behavior-failures.md` row, in this project or a downstream project we operate, shows that the existing principles did not prevent the failure and the proposed principle would have. "Some admired project has this" is **not** evidence; our own miss is.
2. **Equal-weight replacement** — an existing principle is removed or merged into another, so the file's cognitive surface (line count, ✓ Check gates, parallel structure) does not grow net.

A borrowed principle from an admired project (Karpathy, planning-with-files, etc.) that does not meet one of these bars goes into `references/` or a `protocol-blocks/` file, **not** `rules/agent-behavior.md`. Borrowing a *mechanism* (a protocol-block, a reference, a hook) is cheap. Borrowing a *principle* spends Always Read mindshare on every future session of every downstream project — that is expensive and rarely reversible.

**Hard cap:** `rules/agent-behavior.md` ≤ 100 lines (already enforced in the byte-budget table in `templates/README.md`). When the file passes 95 lines, the next addition requires a removal first.

**Scope — what counts as "adding":** the gate applies to **any content-increasing edit** to `rules/agent-behavior.md`, not just new top-level numbered principles. Added bullets under an existing principle, expanded ✓ Check scope, a reframed tagline that widens what the principle covers, or a new paragraph in an existing section — all count. If the edit makes the file longer or stretches a principle's surface, the gate fires.

**Rationalizations to reject** — verbatim thoughts that precede a threshold skip:

- "This one is *clearly* valuable, the gate doesn't really apply" — every added principle was clearly valuable at the time. The gate exists because "clearly valuable" is not a cap.
- "I'll add it now and remove something later" — later rarely comes; file grows net.
- "We already agreed it's useful in conversation" — the gate requires **written evidence** (AAR row or behavior-failures entry), not conversational agreement.
- "It's just a few lines" — that's how a file goes from 70 to 96 in two weeks.
- "My lead / the user / someone senior already decided" — authority transfer is not evidence. The gate is owner-independent: it requires a concrete AAR row or `behavior-failures.md` entry, regardless of who proposed the principle.
- "This is urgent, demo in N minutes, just add it" — the gate has no deadline clause. If the principle is genuinely needed *now*, it ships as a `protocol-blocks/` or `references/` note (unblocked by the gate) and gets promoted to `agent-behavior.md` later once AAR evidence accumulates.
- "I already decided, just format it and add it" (fait accompli) — the decision itself is what the gate checks. Declaring it decided doesn't bypass the check.
- "Origin: user evidence of post-deployment debugging costs" (or similar plausible-sounding attribution without a linked AAR row or `behavior-failures.md` entry) — **fabricated evidence**. An origin line that cannot be traced to a specific file/row is not evidence; it is an evidence-shaped rationalization.

**Rationale:** each admired project offers plausible new principles, and each one individually passes common sense. Cumulative growth inflates every session for every downstream project and dilutes the principles already present. This gate converts the decision from "is this principle useful?" (almost always yes) to "is it worth displacing an existing one, or do we have evidence of a real miss?" (often no).

## Rules for Adding New Rejections

When you decide NOT to add something to `templates/`, record it here with:

1. **What** was considered
2. **Why rejected** (concrete reason, not "felt wrong")
3. **Where it should go instead**

This list should grow over time. A short list means review was lazy, not that the boundary is well-understood.

## Homogeneity Drift Log

Record the result of each "two different projects" spot-check here. Format:

```
YYYY-MM-DD — Go CLI (proj-a) vs Next.js site (proj-b)
  ✅ Skeleton: identical (shells, hooks, protocol-blocks) — expected
  ⚠️  rules/coding-standards.md: 3 lines identical → those 3 lines might be too generic, review
  ✅ gotchas.md: empty in both — correct
  ✅ SKILL.md Common Tasks: fully different — correct
```

<!-- FILL: add drift log entries as they are run. The log is the main evidence that B.5/B.6 is working. -->
