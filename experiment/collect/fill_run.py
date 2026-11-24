"""Copy the acceptance test sources of one task with the run ID filled in.

Usage:
    python -I fill_run.py <kit_dir> <task> <run_id> <out_dir>

Example:
    python -I fill_run.py C:\\ABAP-Experiment\\kit T1 A1 C:\\ABAP-Experiment\\eval\\A1\\acceptance

<task> is T1 ... T6; <run_id> is two or three letters and digits (A1, PB1).
"<run>" is replaced by the lower-case run ID, "<RUN>" by the upper-case one.
Output file names get the run ID in place of "_run_".
"""
import pathlib
import re
import sys


def main() -> int:
    if len(sys.argv) != 5:
        print(__doc__)
        return 2
    kit, task, run_id, out = sys.argv[1:]
    if not re.fullmatch(r"[A-Za-z0-9]{2,3}", run_id):
        print("run ID must be 2-3 letters or digits")
        return 2
    source = pathlib.Path(kit) / "acceptance" / task.upper()
    target = pathlib.Path(out)
    target.mkdir(parents=True, exist_ok=True)
    count = 0
    for path in sorted(source.glob("*.abap")):
        text = path.read_text(encoding="utf-8")
        text = text.replace("<run>", run_id.lower()).replace("<RUN>", run_id.upper())
        name = path.name.replace("_x_run_", "_x" + run_id.lower() + "_")
        (target / name).write_text(text, encoding="utf-8", newline="\n")
        count += 1
    print(f"{count} files written to {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
