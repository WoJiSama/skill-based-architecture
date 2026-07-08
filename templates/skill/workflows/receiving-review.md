# Receiving Code Review Workflow

> Verifying and acting on review feedback is **main-agent judgment** (evaluating a critique, deciding to accept or push back) — it is on the Negative list, not delegable. The only delegable slice is mechanical re-verification (run the reviewer's repro, grep for usage); for that, see [`subagent-driven.md` § Mode 1](subagent-driven.md#mode-1-direct-auxiliary-delegation).

Use this when you receive review feedback — from the user, a `code-reviewer` subagent, or a PR/MR review — and must act on it.

## Core stance: actions, not agreement

Review feedback is a technical claim to be **verified**, not a social cue to **affirm**. Do not open with "You're absolutely right!", "Great point!", or "Thanks for catching that." If a point is correct, the response is the fix — not the praise. If you catch yourself about to type agreement before verifying, stop.

## The pattern (every item)

1. **Read** — read the full review first; do not act on item 1 before seeing items 2–N.
2. **Understand** — restate each item in your own words. Unclear? Clarify *before* implementing — do not start partial work on a guess.
3. **Verify** — check the claim against the actual code. A reviewer (human or agent) can be wrong, stale, or missing context. Reproduce the asserted bug / read the cited lines before accepting.
4. **Evaluate** — is the change correct **and** warranted? Run a YAGNI check: grep for real usage before "implementing it properly" for a case that never occurs.
5. **Respond** — acknowledge correct items factually (one line, no gratitude ritual); for items you'll push back on, say why, with evidence.
6. **Implement** — make the verified changes, then re-verify with fresh evidence (see [`task-closure.md`](task-closure.md) § Fresh verification evidence) before claiming done.

## When to push back (not every item is right)

Push back, with evidence, when the feedback:

- **breaks functionality** — the suggested change fails a real case the current code handles;
- **rests on missing context** — the reviewer did not see a constraint that makes the current code correct;
- **violates YAGNI** — it asks you to build for a case that does not occur (prove it with a usage grep);
- **conflicts with a decision the user already made** — surface the conflict; do not silently override either side.

Push back by **correcting, not defending**: state the evidence, skip the apology, do not argue tone. If you are the one who is wrong, fix it and move on — no defensiveness in either direction.

## Calibrate skepticism to source

- **Trusted partner (the user, a known reviewer)** — feedback usually carries context you lack; default to verify-then-apply.
- **External / automated reviewer** — higher false-positive rate; verify harder before acting, and reject confidently when wrong.

## Red Flags — STOP

- You typed "You're absolutely right" / "Great point" / "Thanks" → delete it; verify and fix instead.
- You started implementing item 1 before reading items 2–N → re-read the whole review first.
- You accepted a claim without opening the code it refers to → verify before acting.
- You implemented a "do it properly" suggestion without checking the case ever occurs → run the YAGNI grep.
- You're defending tone or apologizing instead of stating evidence → correct, don't perform.

## Completion Checklist

- [ ] Whole review read before acting on any single item
- [ ] Each accepted item verified against actual code, not taken on assertion
- [ ] No sycophantic acknowledgements ("you're right", "great point", "thanks")
- [ ] Items pushed back on cite concrete evidence (failing case, missing context, usage grep)
- [ ] YAGNI-checked any "implement it properly" request
- [ ] Changes re-verified with fresh evidence before claiming done
- [ ] Task Closure Protocol run if the changes altered behavior

<!-- OPTIONAL: project-specific review surfaces — e.g. how PR/MR inline replies are posted (gh api / glab), required reviewers, CI that must re-pass after review changes. -->
