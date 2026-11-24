"""Static rubric checks on the ABAP sources of one run.

Usage:
    python -I rubric_scan.py <src_dir> <task> [--release-file objectReleaseInfo_BTPLatest.json] [--json out.json]

<src_dir> holds the sources the evaluation session exported from the system,
one file per include, named like ADT's file names (zcl_x.clas.abap,
zcl_x.clas.testclasses.abap, zif_x.intf.abap, zsm_x.tabl.ddic ...).
Acceptance test classes (*_at_*) are skipped. Test includes are scanned only
for the checks that say so.

Every check is a pattern on the source text; each finding names the file and
the line. The checks are deliberately simple and listed in rubric.md; the
evaluation reads the findings, it does not re-score them.
"""
import argparse
import json
import pathlib
import re
import sys

STATEMENT_END = re.compile(r"\.\s*(\"[^\n]*)?$")


def strip_comment(line: str) -> str:
    """Remove full-line comments (* in column 1) and trailing " comments outside literals."""
    if line.startswith("*"):
        return ""
    out, in_lit, quote = [], False, ""
    for ch in line:
        if in_lit:
            out.append(ch)
            if ch == quote:
                in_lit = False
            continue
        if ch in ("'", "`", "|"):
            in_lit, quote = True, ch
            out.append(ch)
            continue
        if ch == '"':
            break
        out.append(ch)
    return "".join(out)


def statements(text: str):
    """Yield (start_line, statement_text) with comments removed; chain colons are kept as text."""
    buf, start = [], None
    for number, raw in enumerate(text.splitlines(), 1):
        code = strip_comment(raw)
        if not code.strip():
            continue
        if start is None:
            start = number
        buf.append(code.strip())
        if code.rstrip().endswith("."):
            yield start, " ".join(buf)
            buf, start = [], None
    if buf:
        yield start, " ".join(buf)


COMMON = {
    "R-C1a commit in a reusable class": re.compile(
        r"^COMMIT\s+WORK\b|CALL\s+FUNCTION\s+'BAPI_TRANSACTION_COMMIT'", re.I),
    "R-C1b rollback in a reusable class": re.compile(
        r"^ROLLBACK\s+WORK\b|CALL\s+FUNCTION\s+'BAPI_TRANSACTION_ROLLBACK'", re.I),
    "R-C2 MESSAGE statement in a class": re.compile(r"^MESSAGE\b", re.I),
    "R-C4 CATCH of CX_ROOT": re.compile(r"^CATCH\b.*\bcx_root\b", re.I),
    "R-C6 hard-coded mail address, URL or destination": re.compile(
        r"['`|][^'`|]*[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}[^'`|]*['`|]|https?://|DESTINATION\s+'[^']+'", re.I),
    "R-C7 obsolete or classic statement": re.compile(
        r"^(FORM|PERFORM|MOVE|REFRESH|CALL\s+METHOD)\b|WITH\s+HEADER\s+LINE|\bOCCURS\b", re.I),
    "R-C8 SELECT *": re.compile(r"^SELECT\s+(SINGLE\s+)?\*|\bFIELDS\s+\*", re.I),
}

TASK = {
    "T1": {
        "R-T1a production class calls BAPI_SALESORDER_CREATEFROMDAT2": re.compile(
            r"CALL\s+FUNCTION\s+'BAPI_SALESORDER_CREATEFROMDAT2'", re.I),
    },
    "T2": {
        "R-T2a classic BCS used (CL_BCS / CL_DOCUMENT_BCS / SO_*_SEND_API1)": re.compile(
            r"\bcl_bcs\b|\bcl_document_bcs\b|SO_\w*SEND_API1", re.I),
        "R-T2b released mail API used (CL_BCS_MAIL_MESSAGE)": re.compile(r"\bcl_bcs_mail_message\b", re.I),
        # K22: any escape( ... format = ... ), e.g. cl_abap_format=>e_html_text or e_xss_ml
        "R-T2c escaping used (escape( ... format = any cl_abap_format=>e_* ))": re.compile(
            r"\bescape\s*\(.*\bformat\s*=", re.I),
    },
    "T3": {
        "R-T3a AUTHORITY-CHECK on S_CARRID": re.compile(r"AUTHORITY-CHECK\s+OBJECT\s+'S_CARRID'", re.I),
        "R-T3b DUMMY in an AUTHORITY-CHECK": re.compile(r"AUTHORITY-CHECK.*\bDUMMY\b", re.I),
    },
    "T4": {
        "R-T4a released lock API (CL_ABAP_LOCK_OBJECT_FACTORY)": re.compile(r"cl_abap_lock_object_factory", re.I),
        "R-T4b generated ENQUEUE_/DEQUEUE_ module called directly": re.compile(r"CALL\s+FUNCTION\s+'(EN|DE)QUEUE_", re.I),
        "R-T4c UPDATE without WHERE": re.compile(r"^UPDATE\s+\w+\s+SET\b(?!.*\bWHERE\b)", re.I),
        "T4 supporting: sy-dbcnt or sy-subrc read (not a rubric item)": re.compile(r"sy-dbcnt|sy-subrc", re.I),
    },
    "T5": {
        "R-T5a CONVERSION_EXIT_ function module": re.compile(r"CONVERSION_EXIT_", re.I),
        "R-T5b WRITE ... TO": re.compile(r"^WRITE\b.*\bTO\b", re.I),
    },
    "T6": {
        "R-T6a previous passed when raising": re.compile(r"RAISE\s+EXCEPTION.*\bprevious\s*=", re.I),
    },
}

SUBRC_TRIGGER = re.compile(r"^AUTHORITY-CHECK\b|\bEXCEPTIONS\b", re.I)

UNLOCK_CALL = re.compile(r"->\s*unlock\s*\(", re.I)
LEAVES = re.compile(r"^(RAISE|RETURN)\b", re.I)
BRANCH_END = re.compile(r"^(ELSE|ELSEIF|ENDTRY|ENDMETHOD|CATCH|CLEANUP)\b", re.I)


def success_path_unlocks(stmts):
    """R-T4f (recorded only): lines of unlock calls in METHOD reserve on the success path.

    Heuristic: an unlock call counts unless it stands in a CATCH or CLEANUP
    section, or a RAISE or RETURN follows it in the same IF branch. Unlock
    calls hidden in helper methods are not seen; the evaluation confirms the
    count by reading the method. Returns None if there is no METHOD reserve.
    """
    lines, in_reserve, handler = [], False, []
    for index, (line, stmt) in enumerate(stmts):
        if re.match(r"^METHOD\s+reserve\b", stmt, re.I):
            in_reserve, handler = True, []
            continue
        if not in_reserve:
            continue
        if re.match(r"^ENDMETHOD\b", stmt, re.I):
            break
        if re.match(r"^TRY\b", stmt, re.I):
            handler.append(False)
        elif re.match(r"^(CATCH|CLEANUP)\b", stmt, re.I) and handler:
            handler[-1] = True
        elif re.match(r"^ENDTRY\b", stmt, re.I) and handler:
            handler.pop()
        elif UNLOCK_CALL.search(stmt) and not any(handler):
            depth, failure = 0, False
            for _, nxt in stmts[index + 1:]:
                if re.match(r"^IF\b", nxt, re.I):
                    depth += 1
                elif re.match(r"^ENDIF\b", nxt, re.I):
                    if depth == 0:
                        break
                    depth -= 1
                elif depth == 0 and BRANCH_END.match(nxt):
                    break
                elif depth == 0 and LEAVES.match(nxt):
                    failure = True
                    break
            if not failure:
                lines.append(line)
    return lines if in_reserve else None


def scan(src: pathlib.Path, task: str, release_file: str | None):
    findings = []
    files = sorted(p for p in src.rglob("*") if p.is_file() and p.suffix in (".abap", ".ddic"))
    released = set()
    if release_file:
        data = json.loads(pathlib.Path(release_file).read_text(encoding="utf-8"))
        released = {o["tadirObjName"].upper() for o in data["objectReleaseInfo"] if o["state"] in ("released", "deprecated")}
        released |= {o.get("objectKey", "").upper() for o in data["objectReleaseInfo"] if o["state"] in ("released", "deprecated")}
    for path in files:
        name = path.name.lower()
        if "_at_" in name:
            continue
        is_test = ".testclasses." in name
        text = path.read_text(encoding="utf-8", errors="replace")
        stmts = list(statements(text))
        checks = dict(COMMON)
        checks.update(TASK.get(task.upper(), {}))
        for line, stmt in stmts:
            for label, pattern in checks.items():
                if pattern.search(stmt):
                    findings.append({"check": label, "file": path.name, "line": line,
                                     "test_include": is_test, "statement": stmt[:160]})
        # R-C3 empty CATCH: a CATCH followed directly by ENDTRY, CATCH or CLEANUP
        for (line, stmt), (_, nxt) in zip(stmts, stmts[1:]):
            if re.match(r"^CATCH\b", stmt, re.I) and re.match(r"^(ENDTRY|CATCH|CLEANUP)\b", nxt, re.I):
                findings.append({"check": "R-C3 empty CATCH block", "file": path.name, "line": line,
                                 "test_include": is_test, "statement": stmt[:160]})
        # R-C5 sy-subrc not evaluated in the next statement
        for (line, stmt), (_, nxt) in zip(stmts, stmts[1:]):
            if SUBRC_TRIGGER.search(stmt) and "sy-subrc" not in nxt.lower():
                findings.append({"check": "R-C5 sy-subrc not evaluated in the next statement", "file": path.name,
                                 "line": line, "test_include": is_test, "statement": stmt[:160]})
        # R-T4f success-path unlock calls in reserve (recorded only, not scored)
        if task.upper() == "T4" and name.endswith("_reserver.clas.abap"):
            unlock_lines = success_path_unlocks(stmts)
            if unlock_lines is not None:
                findings.append({"check": "R-T4f success-path unlock calls in reserve (recorded only)",
                                 "file": path.name, "line": unlock_lines[0] if unlock_lines else None,
                                 "test_include": False, "statement": f"count={len(unlock_lines)}"})
        # R-C9 SAP objects referenced that are not in the release file (cloud tasks)
        if released and not is_test:
            refs = set(re.findall(r"\b((?:cl|if|cx|xco)_\w+)", text, re.I))
            refs |= set(re.findall(r"CALL\s+FUNCTION\s+'(\w+)'", text, re.I))
            for ref in sorted({r.upper() for r in refs}):
                if ref.startswith(("ZCL_", "ZIF_", "ZCX_")) or ref.startswith("CL_ABAP_UNIT"):
                    continue
                if ref not in released:
                    findings.append({"check": "R-C9 SAP object not in the release file", "file": path.name,
                                     "line": None, "test_include": False, "statement": ref})
    return findings


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("src_dir")
    parser.add_argument("task")
    parser.add_argument("--release-file")
    parser.add_argument("--json")
    args = parser.parse_args()
    findings = scan(pathlib.Path(args.src_dir), args.task, args.release_file)
    print(f"| Check | File | Line | Test include | Statement |")
    print(f"|---|---|---|---|---|")
    for f in findings:
        print(f"| {f['check']} | {f['file']} | {f['line'] or ''} | {'yes' if f['test_include'] else ''} | `{f['statement'].replace('|', '/')}` |")
    if args.json:
        pathlib.Path(args.json).write_text(json.dumps(findings, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
