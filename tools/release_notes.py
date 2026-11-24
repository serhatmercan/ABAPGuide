"""Write release notes for a range of commits, grouped by Conventional Commit scope.

Groups, in this order:
  Rules           docs(rules), fix(rules)
  Chapters        docs(chNN), fix(chNN), one sub-list per chapter folder
  AI assistants   docs(ai), feat(tools), fix(tools)
  Experiment      docs(experiment), feat(experiment), fix(experiment)
  Repository      docs(readme), docs(claude), docs(examples), fix(examples),
                  chore(...), and Conventional Commits without a scope
  Other           subjects that are not Conventional Commits

The notes also list the rule headings of docs/ABAP-Development-Rules.md that
were added, changed or removed in the range, and the rule lines of
ai/AGENTS.md that changed, so users of a copied ai/AGENTS.md see whether to
copy it again.

Usage (from the repository; Python 3.10 or later, standard library only):
    python tools/release_notes.py [--from REV] [--to REV] [--title TEXT] [--out FILE]

--to defaults to HEAD. --from defaults to the latest tag reachable from the
parent of --to; without such a tag the notes cover every commit reachable
from --to, including the first one. --from is exclusive, as in git's
FROM..TO.
"""
from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
RULES = "docs/ABAP-Development-Rules.md"
AGENTS = "ai/AGENTS.md"
SUBJECT = re.compile(r"^(?P<type>[a-z]+)(?:\((?P<scope>[^)]*)\))?!?: (?P<text>.+)$")
GROUPS = ("Rules", "Chapters", "AI assistants", "Experiment", "Repository", "Other")


def git(*args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True,
                            encoding="utf-8", check=False)
    if check and result.returncode != 0:
        raise SystemExit(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout if result.returncode == 0 else ""


def default_from(to: str) -> str | None:
    tag = git("describe", "--tags", "--abbrev=0", f"{to}^", check=False).strip()
    return tag or None


def commits(frm: str | None, to: str) -> list[tuple[str, str]]:
    rng = f"{frm}..{to}" if frm else to
    out = git("log", "--reverse", "--format=%h%x1f%s", rng)
    return [tuple(line.split("\x1f", 1)) for line in out.splitlines() if line]


def group_of(subject: str) -> tuple[str, str | None]:
    m = SUBJECT.match(subject)
    if not m:
        return "Other", None
    kind, scope = m.group("type"), (m.group("scope") or "")
    if scope == "rules":
        return "Rules", None
    chapter = re.fullmatch(r"ch(\d{2})", scope)
    if chapter:
        return "Chapters", chapter.group(1)
    if scope in ("ai", "tools"):
        return "AI assistants", None
    if scope == "experiment":
        return "Experiment", None
    return "Repository", None


def file_at(rev: str | None, path: str) -> str | None:
    if rev is None:
        return None
    out = subprocess.run(["git", "show", f"{rev}:{path}"], cwd=ROOT, capture_output=True,
                         text=True, encoding="utf-8", check=False)
    return out.stdout if out.returncode == 0 else None


def rule_headings(text: str | None) -> dict[str, str]:
    if not text:
        return {}
    return {m.group(1): m.group(2).strip() for m in re.finditer(r"^### (\d+\.\d+) (.*)$", text, re.M)}


def agents_lines(text: str | None) -> dict[str, str]:
    if not text:
        return {}
    return {m.group(1): m.group(2).strip() for m in re.finditer(r"^- (\d+\.\d+) (.*)$", text, re.M)}


def number_key(num: str) -> tuple[int, int]:
    major, minor = num.split(".")
    return int(major), int(minor)


def compare(old: dict[str, str], new: dict[str, str]) -> tuple[list[str], list[str], list[str]]:
    added = sorted(set(new) - set(old), key=number_key)
    removed = sorted(set(old) - set(new), key=number_key)
    changed = sorted((n for n in set(old) & set(new) if old[n] != new[n]), key=number_key)
    return added, changed, removed


def chapter_names(to: str) -> dict[str, str]:
    names = {}
    for name in git("ls-tree", "--name-only", to).splitlines():
        m = re.match(r"^(\d{2})-", name)
        if m:
            names[m.group(1)] = name
    return names


def build(frm: str | None, to: str, title: str | None) -> str:
    items = commits(frm, to)
    to_label = git("describe", "--tags", "--always", to).strip()
    frm_label = frm if frm else "the first commit"
    lines = [f"# {title or 'Release notes'}", "",
             f"Commits from {frm_label} to {to_label}: {len(items)}."
             + ("" if frm else " There is no earlier tag, so this covers the whole history."), ""]

    # rule set and compact file
    old_rules, new_rules = rule_headings(file_at(frm, RULES)), rule_headings(file_at(to, RULES))
    added, changed, removed = compare(old_rules, new_rules)
    lines += ["## Rule set", ""]
    if frm is None:
        lines.append(f"- `{RULES}` has {len(new_rules)} rules in this release.")
    else:
        if not (added or changed or removed):
            lines.append("- No rule heading added, changed or removed.")
        lines += [f"- Added: Rule {n} — {new_rules[n]}" for n in added]
        lines += [f"- Heading changed: Rule {n} — {new_rules[n]}" for n in changed]
        lines += [f"- Removed heading: Rule {n} — {old_rules[n]}" for n in removed]
    old_agents_text, new_agents_text = file_at(frm, AGENTS), file_at(to, AGENTS)
    old_agents, new_agents = agents_lines(old_agents_text), agents_lines(new_agents_text)
    if new_agents_text is None:
        lines.append(f"- `{AGENTS}` does not exist in this release.")
    elif old_agents_text is None:
        lines.append(f"- `{AGENTS}` is new in this release ({len(new_agents)} rule lines).")
    else:
        a_added, a_changed, a_removed = compare(old_agents, new_agents)
        if not (a_added or a_changed or a_removed):
            lines.append(f"- `{AGENTS}`: no rule line changed; a copied file is still current.")
        else:
            lines.append(f"- `{AGENTS}` changed; copy it again. Changed rule lines:")
            lines += [f"  - added {n}: {new_agents[n]}" for n in a_added]
            lines += [f"  - changed {n}: {new_agents[n]}" for n in a_changed]
            lines += [f"  - removed {n}" for n in a_removed]
    lines.append("")

    # commits by group
    grouped: dict[str, list] = {g: [] for g in GROUPS}
    for sha, subject in items:
        group, chapter = group_of(subject)
        grouped[group].append((chapter, sha, subject))
    names = chapter_names(to)
    for group in GROUPS:
        entries = grouped[group]
        if not entries:
            continue
        lines += [f"## {group} ({len(entries)})", ""]
        if group == "Chapters":
            for chapter in sorted({c for c, _, _ in entries}):
                sub = [(s, t) for c, s, t in entries if c == chapter]
                lines.append(f"- **{names.get(chapter, 'Chapter ' + chapter)}** ({len(sub)})")
                lines += [f"  - {t} ({s})" for s, t in sub]
        else:
            lines += [f"- {t} ({s})" for _, s, t in entries]
        lines.append("")
    return "\n".join(lines).rstrip("\n") + "\n"


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--from", dest="frm", help="exclusive start (tag or commit); default: latest tag")
    parser.add_argument("--to", default="HEAD", help="end (tag or commit); default HEAD")
    parser.add_argument("--title", help="heading of the notes, for example the tag name")
    parser.add_argument("--out", type=pathlib.Path, help="write to this file instead of stdout")
    args = parser.parse_args()
    frm = args.frm if args.frm else default_from(args.to)
    notes = build(frm, args.to, args.title)
    if args.out:
        args.out.write_bytes(notes.encode("utf-8"))
    else:
        sys.stdout.write(notes)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
