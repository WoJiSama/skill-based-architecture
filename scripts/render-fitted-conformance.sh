#!/usr/bin/env bash
# Render current upstream checks for an already declared fitted owner set.
# Shared by first materialization and upgrades; stdout only, no target writes.
set -euo pipefail

if [[ $# -ne 1 || "$1" == -h || "$1" == --help ]]; then
  echo "Usage: bash scripts/render-fitted-conformance.sh <fitted-conformance.yaml>"
  [[ $# -eq 1 && ( "$1" == -h || "$1" == --help ) ]] && exit 0
  exit 2
fi

python3 - "$1" <<'PY'
import json
import re
import sys
from pathlib import Path

PERMISSION_ANCHOR = "Task scope does not automatically grant external write authority for databases, deployments, configuration, or shared systems; obtain explicit authorization before performing such writes."
PERMISSION_DECLARATION = "# Fitted external-write responsibility: adopted"


def scalar(value):
    value = value.strip()
    if value.startswith('"'):
        return json.loads(value)
    if value.startswith("'"):
        if not value.endswith("'"):
            raise ValueError("unterminated declaration scalar")
        return value[1:-1].replace("''", "'")
    return value


try:
    text = Path(sys.argv[1]).read_text(encoding="utf-8")
    if not text.startswith("# Fitted content contract:"):
        raise ValueError("not a materializer-fitted contract; review its ownership before selecting upstream checks")
    # This reads the materializer's declared-owner subset, not arbitrary YAML.
    # Reject unfamiliar declarations rather than infer adoption from disk: a
    # deleted required owner must remain required during an upgrade.
    owners = []
    current = None
    inside = False
    for line in text.splitlines():
        if line == "required_files:":
            if inside or owners:
                raise ValueError("duplicate required_files declaration")
            inside = True
            continue
        if not inside or not line.strip() or line.lstrip().startswith("#"):
            continue
        if not line.startswith(" "):
            inside = False
            continue
        if line.startswith("  - path: "):
            path = scalar(line[len("  - path: "):])
            if (not isinstance(path, str) or not re.fullmatch(r"[A-Za-z0-9_.\-/]+", path)
                    or path.startswith("/") or any(p in ("", ".", "..") for p in path.split("/"))):
                raise ValueError("unsafe or unsupported declared owner path")
            if any(owner["path"] == path for owner in owners):
                raise ValueError("duplicate declared owner: " + path)
            current = {"path": path, "reason": "Declared materialized owner."}
            owners.append(current)
        elif line.startswith("    reason: ") and current is not None:
            current["reason"] = scalar(line[len("    reason: "):])
            if not isinstance(current["reason"], str):
                raise ValueError("owner reason must be text")
        else:
            raise ValueError("unsupported required_files declaration; preserve it for manual review")
    selected = {owner["path"] for owner in owners}
    if not {"SKILL.md", "routing.yaml", "workflows/other.md"} <= selected:
        raise ValueError("fitted contract is missing its declared entry, routing, or fallback owner")
    # A custom project-rules assertion does not adopt external-write policy.
    # Older fitted manifests expressed this responsibility by its exact anchor.
    external_write = PERMISSION_DECLARATION in text.splitlines() or PERMISSION_ANCHOR in text
except (OSError, ValueError) as exc:
    print("FAIL: cannot refresh fitted conformance: " + str(exc), file=sys.stderr)
    raise SystemExit(2)

print("# Fitted content contract: only owners admitted by this evidence plan.")
if external_write:
    print(PERMISSION_DECLARATION)
print("required_files:")
for owner in owners:
    print("  - path: " + owner["path"])
    print("    reason: " + json.dumps(owner["reason"], ensure_ascii=False))
print("required_sections:")


def section(path, **checks):
    print("  - file: " + path)
    for kind, phrases in checks.items():
        print("    " + kind + ":")
        for phrase in phrases:
            print("      - " + json.dumps(phrase, ensure_ascii=False))


section("SKILL.md", must_contain=["## Common Tasks", "routing.yaml"])
if "workflows/task-execution.md" in selected:
    section("workflows/task-execution.md", must_contain=["Before Each Main Step"])
if "workflows/task-closure.md" in selected:
    section("workflows/task-closure.md", must_contain=["Completion Gate"])
if external_write:
    section("rules/project-rules.md", must_contain=[PERMISSION_ANCHOR])
if "workflows/define-requirement.md" in selected:
    section("workflows/define-requirement.md", must_contain=[
        "## Requirement Definition",
        "return `requirement-ready` without another confirmation turn",
        "current understanding, name the real risk/conflict, ask the minimum normative question, and stop",
        "does not produce an implementation Plan, Task Breakdown, code mutation, or proof command",
        "Create or update the smallest Governing Requirement only when the user explicitly requests a Requirement/PRD artifact",
        "A later Plan links this owner one way and cannot copy, narrow, resolve, or update it",
    ], must_not_contain=["Make one risk-sized change"])
if "workflows/plan-feature.md" in selected:
    section("workflows/plan-feature.md", must_contain_in_order=[
        "Consume a named `requirement-ready` source",
        "Project Goal, Done When, and material Boundaries into a Task Anchor",
        "Reach `implementation-ready` before deriving technical options",
        "return the implementation Plan",
        "Any durable implementation Plan is a separate one-way consumer",
        "never stores technical Plan content or lifecycle state in the Governing Requirement file",
    ], must_not_contain=["Make one risk-sized change"])
if "workflows/change-managed.md" in selected:
    section("workflows/change-managed.md", must_contain_in_order=[
        "`requirement-ready`", "Task Anchor", "`implementation-ready`",
        "derive the implementation Plan", "make one risk-sized change",
    ])
if "workflows/update-upstream.md" in selected:
    section("workflows/update-upstream.md", must_contain=[
        "local manifest is the project selection boundary",
        "render-fitted-conformance.sh",
        "preserving project-specific assertions",
    ], must_not_contain=["Conformance check — use upstream's manifest, not local"])
PY
