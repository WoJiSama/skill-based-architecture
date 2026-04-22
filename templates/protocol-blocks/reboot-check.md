# Reboot Check — When You Feel Lost Mid-Task

Drop this block into any workflow where the agent might lose orientation partway through a long task — context compressed silently, a subagent returned, or "what was I doing?" crossed the agent's mind.

Session Discipline (in `SKILL.md`) covers re-orientation at the start of a **new** task. This block covers re-orientation **inside** an ongoing task.

**The 5 questions — answer them in writing before the next action:**

1. **Where am I?** — which phase, file, or subsystem is the current change touching? One sentence.
2. **Where am I going?** — the concrete success criterion for this task (per principle 4 of `rules/agent-behavior.md`). If you can't restate it, stop and re-read the request.
3. **What is the goal right now?** — the single next verifiable step, not the whole task.
4. **What have I learned so far?** — the 2–3 facts the current diff / scratchpad has established. If "nothing new" — the last few turns have been thrashing; apply principle 5 (three-strike stop).
5. **What have I already completed?** — which steps of the plan are truly done (with verification) vs. which are "started but unverified." Only verified steps count as done.

If any answer is "I don't know" or "I'd have to check" — **that is the next action**. Do not proceed with the original task until all five have concrete answers.

**Pair with:**
- `protocol-blocks/red-flags-stop.md` — red-flags catch discipline erosion (agent arguing itself out of protocol).
- `protocol-blocks/reboot-check.md` (this file) — catches situational disorientation (agent is following protocol but has lost the thread).

Origin: condensed from [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) 5-Question Reboot Test.
