#!/usr/bin/env bash
# footprint.sh — Static per-task read-cost report (the "speed dashboard", Tier 1).
#
# Measures, in LINES, what a task actually reads (Always Read + the route's
# required_reads + workflow) vs reading every skill doc. Pure static analysis from
# routing.yaml + file sizes — runs nothing, costs nothing per task. Run it whenever;
# diff the numbers before/after a change to catch the per-task floor creeping up.
#
# Scope (be honest about what this proves):
#   - Measures the ROUTING / footprint dimension only: "read the route" vs "read all
#     skill docs". It does NOT measure skill-vs-no-skill (that needs a with/without
#     demo) nor discipline quality (that needs pressure-testing).
#   - Lines are a proxy for token/attention cost — good for "is it trending up?",
#     not for exact accounting.
#
# Usage: bash scripts/footprint.sh [skill-name|skill-root]
set -uo pipefail
TARGET="${1:-}"
if [[ -n "$TARGET" && -f "$TARGET/SKILL.md" ]]; then ROOT="$TARGET"
elif [[ -n "$TARGET" && -f "$TARGET/SKILL.md.template" ]]; then ROOT="$TARGET"
elif [[ -n "$TARGET" && -f "skills/$TARGET/SKILL.md" ]]; then ROOT="skills/$TARGET"
elif [[ -f "SKILL.md" && -f "routing.yaml" ]]; then ROOT="."
elif [[ -f "SKILL.md.template" && -f "routing.yaml" ]]; then ROOT="."
else echo "Usage: bash footprint.sh [skill-name|skill-root]" >&2; exit 2; fi

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys, glob

root = Path(sys.argv[1]).resolve()
manifest = root / "routing.yaml"
if not manifest.exists():
    raise SystemExit(f"no routing.yaml at {root}")
template = root.name == "skill" and root.parent.name == "templates"
skill_md = root / ("SKILL.md.template" if template else "SKILL.md")

def nlines(p):
    try: return len(Path(p).read_text().splitlines())
    except Exception: return 0

def clean(v):
    v = v.strip()
    if (v[:1] == '"' and v[-1:] == '"') or (v[:1] == "'" and v[-1:] == "'"):
        return v[1:-1]
    return v

# --- minimal routing.yaml parse: always_read + tasks (id / required_reads / workflow) ---
always, tasks, cur, sec, top = [], [], None, None, None
for raw in manifest.read_text().splitlines():
    s = raw.strip()
    if not s or s.startswith("#"):
        continue
    if s == "always_read:": top, cur, sec = "ar", None, None; continue
    if s == "tasks:": top, sec = "t", None; continue
    if top == "ar" and raw.startswith("  - "): always.append(clean(s[2:])); continue
    if raw.startswith("  - id:"):
        cur = {"id": clean(raw.split(":", 1)[1]), "required_reads": [], "workflow": ""}
        tasks.append(cur); sec = None; continue
    if cur is None:
        continue
    if raw.startswith("    required_reads:"): sec = "rr"; continue
    if raw.startswith("    trigger_examples:") or raw.startswith("    labels:"): sec = None; continue
    if sec == "rr" and raw.startswith("      - "): cur["required_reads"].append(clean(s[2:])); continue
    if raw.startswith("    ") and ":" in s:
        k, v = s.split(":", 1)
        if k.strip() == "workflow": cur["workflow"] = clean(v)
        sec = None

def resolve(item):
    item = item.split("#", 1)[0].strip()
    if not item or "FILL" in item or "<!--" in item or item.startswith("task-relevant"):
        return []
    if "*" in item:
        return [Path(p).resolve() for p in glob.glob(str(root / item))]
    p = root / item
    return [p.resolve()] if p.exists() else []

always_set = set()
for a in always:
    always_set |= set(resolve(a))
always_total = sum(nlines(f) for f in always_set)
skill_n = nlines(skill_md)

# read-everything baseline = all .md under every content tier + workflows/ + SKILL.md
content = set()
for d in ("rules", "workflows", "references", "architecture", "gotchas", "conventions"):
    dd = root / d
    if dd.exists():
        for f in dd.rglob("*.md"):
            content.add(f.resolve())
content.add(skill_md.resolve())
total = sum(nlines(f) for f in content)

def route_cost(t):
    rr = set()
    for item in t["required_reads"]:
        rr |= set(resolve(item))
    wf = set(resolve(t["workflow"])) if t["workflow"].startswith("workflows/") else set()
    read = always_set | rr | wf
    return sum(nlines(f) for f in read), len(read)

print(f"Skill footprint — {root.name}  (lines read; ROUTING/footprint dimension only)")
print("-" * 66)
print(f"  router  SKILL.md (read 1x/session)        : {skill_n:>6}")
print(f"  floor   Always Read (every task, {len(always_set)} files) : {always_total:>6}   <- watch this across changes")
for f in sorted(always_set):
    print(f"            - {f.relative_to(root)} ({nlines(f)})")
print(f"  baseline read-everything (all {len(content)} docs)     : {total:>6}")
print()
print("  per-task read cost = Always Read + route required_reads + workflow")
print(f"  {'route':<24}{'lines':>7}{'% of all':>10}{'files':>7}")
costs = []
for t in tasks:
    cost, nfiles = route_cost(t)
    costs.append(cost)
    pct = (100 * cost / total) if total else 0
    print(f"  {t['id']:<24}{cost:>7}{pct:>9.0f}%{nfiles:>7}")
print()
if costs and total:
    med = sorted(costs)[len(costs) // 2]
    print(f"=> median task reads {med} lines vs {total} for read-everything "
          f"({100 - 100 * med / total:.0f}% less).")
    print(f"   first task / post-compaction also pays the router (+{skill_n}).")
PY
