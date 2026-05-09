#!/usr/bin/env python3
"""Parse conformance.yaml for check-version-conformance.sh.

Emits one tab-delimited record per check, columns:
  KIND  FILE  PHRASE
where KIND in {CONTAINS, EXISTS}. PHRASE is empty for EXISTS records.

Schema (subset of YAML, no external deps required):

  required_sections:
    - file: <path>
      must_contain:
        - "phrase 1"
        - "phrase 2"

  required_files:
    - path: <path>

Paths are resolved relative to the skill root passed to the runner script.
"""
from __future__ import annotations

import sys
from pathlib import Path


def normalize(line: str) -> str:
    """Strip inline comments outside double-quoted regions, then rstrip."""
    out = []
    in_q = False
    for ch in line:
        if ch == '"':
            in_q = not in_q
            out.append(ch)
        elif ch == "#" and not in_q:
            break
        else:
            out.append(ch)
    return "".join(out).rstrip()


def parse(path: Path) -> list[tuple[str, str, str]]:
    raw = path.read_text(encoding="utf-8")
    lines: list[tuple[int, str]] = []  # (indent, body) for non-blank lines
    for ln in raw.splitlines():
        s = normalize(ln)
        if not s.strip():
            continue
        indent = len(s) - len(s.lstrip())
        lines.append((indent, s.strip()))

    records: list[tuple[str, str, str]] = []
    section: str | None = None
    item_indent: int | None = None
    must_contain_indent: int | None = None
    cur_file: str | None = None
    in_must_contain = False

    def flush_exists() -> None:
        if section == "required_files" and cur_file:
            records.append(("EXISTS", cur_file, ""))

    for indent, body in lines:
        if indent == 0 and body.endswith(":"):
            flush_exists()
            section = body[:-1].strip()
            item_indent = must_contain_indent = None
            cur_file = None
            in_must_contain = False
            continue

        if section not in ("required_sections", "required_files"):
            continue

        if (
            in_must_contain
            and must_contain_indent is not None
            and indent >= must_contain_indent
            and body.startswith("- ")
        ):
            phrase = body[2:].strip().strip('"').strip("'")
            if cur_file and phrase:
                records.append(("CONTAINS", cur_file, phrase))
            continue

        if body.startswith("- ") and (item_indent is None or indent <= item_indent):
            flush_exists()
            item_indent = indent
            must_contain_indent = None
            cur_file = None
            in_must_contain = False
            payload = body[2:].strip()
            if ":" in payload:
                k, _, v = payload.partition(":")
                k = k.strip()
                v = v.strip().strip('"').strip("'")
                if k in ("file", "path"):
                    cur_file = v
            continue

        if ":" in body:
            k, _, v = body.partition(":")
            k = k.strip()
            v = v.strip().strip('"').strip("'")
            if k in ("file", "path"):
                cur_file = v
                in_must_contain = False
            elif k == "must_contain":
                in_must_contain = True
                must_contain_indent = indent + 2
            continue

    flush_exists()
    return records


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: _parse_conformance.py <conformance.yaml>", file=sys.stderr)
        return 2
    path = Path(argv[1])
    if not path.is_file():
        print(f"not a file: {path}", file=sys.stderr)
        return 2
    for kind, file, phrase in parse(path):
        print(f"{kind}\t{file}\t{phrase}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
