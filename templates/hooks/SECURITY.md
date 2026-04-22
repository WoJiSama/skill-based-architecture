# Hook Injection — Trust Boundary

The SessionStart hook (`templates/hooks/session-start`) reads `skills/{{NAME}}/SKILL.md` and injects its contents into the agent's context at startup / `/clear` / `/compact`. Any other file wired into a hook (PreToolUse, UserPromptSubmit, Stop, etc.) follows the same model: **the file content becomes prompt on every trigger, verbatim, unreviewed**.

Three consequences:

1. **Never write external/untrusted content to a hook-injected file.** Web page contents, search results, third-party API responses, user-submitted strings, and anything fetched by the agent mid-session go in a *non-injected* file (e.g. `references/findings.md`, `references/gotchas.md`). They are read explicitly by the workflow when needed, never auto-injected.

2. **Treat `SKILL.md` and any hook-read file as code, not data.** A compromised `SKILL.md` can override every project rule silently on the next `/clear`. Same review rigor as committed source; same PR gate as CI config.

3. **Review hook changes with the same rigor as CI config.** A new hook widens the trust surface. A hook that reads `$(pwd)/*.md` reads whatever an attacker can drop into the working directory. Pin paths; don't glob.

**Concrete rule:** if a file is on any hook's read path, write only project-maintainer-authored content to it. Research, user input, web fetches, and LLM-generated summaries route elsewhere.

Origin: trust-boundary principle condensed from [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files).
