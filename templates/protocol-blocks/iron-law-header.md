# The Iron Law

> **NO TASK IS COMPLETE WITHOUT A TASK CLOSURE PROTOCOL SCAN.**

Drop this header at the top of any workflow that absolutely must run the Task Closure Protocol. It exists to make the requirement impossible to miss when the file is scanned quickly.

The Iron Law has three parts:

1. **Main work done and verified** — implementation complete, tests pass, manual repro clean
2. **30-second AAR scan** — run the checklist in `workflows/update-rules.md`
3. **Record if needed** — any "yes" answer → recording threshold → record to the right destination

**There is no fourth option.** A task that ships with steps 1–2 done but step 3 skipped is still incomplete even if the code works. The point of the protocol is to convert lessons into durable knowledge before they evaporate.

See also: `protocol-blocks/rationalizations-table.md`, `protocol-blocks/red-flags-stop.md`.
