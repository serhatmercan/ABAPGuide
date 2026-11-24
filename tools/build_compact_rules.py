"""Build ai/AGENTS.md, the compact rule file, from Chapter 20 and the rules.

Every rule of sections 1-13 and 15 of docs/ABAP-Development-Rules.md gets one
line. The text is the rule's line in Chapter 20 (20-Best-Practices/README.md):
a bullet that ends with a single "[Rule n.m](...)" link, in a section before
the Scope Note, outside "Refactoring Legacy Code". When Chapter 20 has no line
for a rule, the rule's heading is used and the rule is named on stderr.

Usage (from any folder; Python 3.10 or later):
    python tools/build_compact_rules.py            write ai/AGENTS.md
    python tools/build_compact_rules.py --check    exit 1 if ai/AGENTS.md is not current
    python tools/build_compact_rules.py --stdout   print the file instead of writing it

Exit codes: 0 success, 1 --check found a difference, 2 input error
(for example two Chapter 20 lines for the same rule).
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
RULES = ROOT / "docs" / "ABAP-Development-Rules.md"
CHAPTER_20 = ROOT / "20-Best-Practices" / "README.md"
OUTPUT = ROOT / "ai" / "AGENTS.md"

SKIPPED_RULE_SECTIONS = {"0", "14"}  # purpose and status; deviations from Clean ABAP
SKIPPED_CHAPTER_SECTIONS = ("Refactoring Legacy Code",)  # worked example, cites rules it applies
LAST_CHAPTER_SECTION = "Scope Note"  # checklists and mistakes follow; they cite rules again

HEADER = (
    "# ABAP Development Rules — compact\n"
    "\n"
    "One line per rule. Cite rules by number (Rule 3.12). "
    "Apply them to new and changed ABAP code.\n"
    "\n"
    "Generated from `20-Best-Practices/README.md` and `docs/ABAP-Development-Rules.md` "
    "of ABAPGuide (https://github.com/serhatmercan/ABAPGuide) by "
    "`tools/build_compact_rules.py`; do not edit by hand. "
    "The rules document holds the binding text and the reasons.\n"
)

LINE = re.compile(r"^- (?P<text>.+?) — \[Rule (?P<num>\d+\.\d+)\]\([^)]*\)\.?$")


def chapter_lines(text: str) -> dict[str, str]:
    """Return rule number -> Chapter 20 line text; fail on duplicates."""
    lines: dict[str, str] = {}
    section = ""
    for raw in text.splitlines():
        heading = re.match(r"^## \S+ (.*)$", raw)
        if heading:
            section = heading.group(1).strip()
            if section == LAST_CHAPTER_SECTION:
                break
            continue
        if section in SKIPPED_CHAPTER_SECTIONS:
            continue
        match = LINE.match(raw)
        if not match:
            continue
        num = match.group("num")
        if num in lines:
            raise SystemExit(f"error: Chapter 20 has two lines for Rule {num}")
        lines[num] = match.group("text").strip()
    return lines


def build() -> tuple[str, list[str]]:
    rules = RULES.read_text(encoding="utf-8")
    short = chapter_lines(CHAPTER_20.read_text(encoding="utf-8"))
    out = [HEADER]
    missing: list[str] = []
    section = None
    for raw in rules.splitlines():
        sec = re.match(r"^## (\d+) (.*)$", raw)
        if sec:
            section = sec.group(1)
            if section not in SKIPPED_RULE_SECTIONS:
                out.append(f"\n## {section} {sec.group(2).strip()}\n")
            continue
        rule = re.match(r"^### (\d+\.\d+) (.*)$", raw)
        if rule and section not in SKIPPED_RULE_SECTIONS:
            num = rule.group(1)
            if num not in short:
                missing.append(num)
            out.append(f"- {num} {short.get(num, rule.group(2).strip())}\n")
    return "".join(out), missing


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--check", action="store_true", help="exit 1 if ai/AGENTS.md is not current")
    group.add_argument("--stdout", action="store_true", help="print instead of writing ai/AGENTS.md")
    args = parser.parse_args()

    text, missing = build()
    if missing:
        print("No Chapter 20 line, rule heading used: " + ", ".join(missing), file=sys.stderr)
    data = text.encode("utf-8")
    if args.stdout:
        sys.stdout.buffer.write(data)
        return 0
    if args.check:
        if OUTPUT.exists() and OUTPUT.read_bytes() == data:
            print("ai/AGENTS.md is current.")
            return 0
        print("ai/AGENTS.md is not current; run python tools/build_compact_rules.py", file=sys.stderr)
        return 1
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(data)
    print(f"Wrote {OUTPUT.relative_to(ROOT).as_posix()} ({len(data)} bytes).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
