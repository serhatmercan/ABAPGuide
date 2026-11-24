# Evaluation prompt

Used in a separate Claude Code session in `C:\ABAP-Experiment\eval\`, started
with `C:\ABAP-Experiment\kit\collect\eval_start.ps1`. The script refuses to
start when `CLAUDE_CONFIG_DIR` is set: the evaluation runs in your normal
configuration, because the run configuration denies unit test runs.

Folder layout (siblings under `C:\ABAP-Experiment\`): the kit is `..\kit\`,
the run list is `runs.csv`, the metrics file is `metrics.json` (pilot:
`pilot-metrics.json`), and every output of run `{RUN}` goes to
`results\{RUN}\`. Paths below are relative to `eval\`.

Before the first run of a batch, the operator writes the metrics file once:

```
python -I ..\kit\collect\collect_metrics.py runs.csv --projects-dir C:\ABAP-Experiment\claude-config\projects --settings ..\kit\claude-config\settings.json --json metrics.json
```

Fill in `{RUN}`, `{TASK}`, `{DEST}`, `{PACKAGE}` and `{ATC_VARIANT}` per run;
one evaluation session can handle several runs one after the other.

ATC variant: `DEFAULT` on-premise (the system default variant checked no
object in an earlier probe, `DEFAULT` did), `ABAP_CLOUD_DEVELOPMENT_DEFAULT`
on SAP BTP.

---

You evaluate run {RUN} (task {TASK}) of an experiment. Do not change any
object the run created. Work through these steps in order and stop at the
first step that fails, recording why.

0. **Validity.** Read the entry of {RUN} in `metrics.json` and record:
   - V-1: every value in `permission_modes`. If any value is not `dontAsk`
     (`permission_mode_deviation` is true), report the run as a protocol
     deviation, with the values and their counts;
   - V-2: `tool_calls_outside_allowlist` (names, calls, error results;
     `ToolSearch` is expected);
   - V-3: `skill_calls`.
   Continue with step 1 in every case; a deviation is reported, not a stop.
1. **Inventory.** Search destination {DEST}, package {PACKAGE}, read only, for
   objects whose name contains `ZSM_X{RUN}_` (pattern `*ZSM_X{RUN}_*`). Write the list
   to `results\{RUN}\objects.md` with name and type.
2. **Export.** Read the active version of every source of every object in the
   list (all includes of classes, interfaces, table definitions) and write each
   to `results\{RUN}\src\` under its ADT file name. Do not edit anything.
   For task T4 only, also read the generated function module
   `ENQUEUE_EZSM_X{RUN}_STOCK` (active version) and record whether it has a
   parameter `MODE_ZSM_X{RUN}_STOCK` and its default value (rubric R-T4e).
3. **Acceptance test.** Run
   `python -I ..\kit\collect\fill_run.py ..\kit {TASK} {RUN} results\{RUN}\acceptance`.
   Create the shell class named in the task file in package {PACKAGE} on
   {DEST}, replace its source with the filled shell source and its test include
   with the filled test include, and activate it. Record the activation result.
   If activation fails because an object the spec requires is missing or has a
   different signature, record the message; this counts as "acceptance test
   not activatable", not as an evaluation error.
4. **Run the acceptance tests** of the shell class and record the overall
   status. The tool reports one status per run: `PASSED` means every test
   method passed (a skipped method cannot be told apart from a passed one;
   for T3 report the methods as "passed or skipped"). On `FAILED`, copy the
   failure details: they name each failing method and its message; every
   method of the include that they do not name counts as passed.
5. **ATC.** Start an ATC run with variant {ATC_VARIANT} on the objects the
   spec requires (task file, "Objects the spec requires"); never on the
   acceptance shell class. Record the number of findings per priority and each
   finding's check title, object and line; this is R-C12 (K23). If the run
   created other objects, run ATC on them separately and report their
   findings as "beyond the spec"; they are not compared.
6. **Rubric scan.** Run
   `python -I ..\kit\collect\rubric_scan.py results\{RUN}\src {TASK} --json results\{RUN}\rubric.json`
   (on SAP BTP add `--release-file ..\kit\collect\objectReleaseInfo_BTPLatest.json`).
   For task T4, read the method `reserve` of `ZCL_ZSM_X{RUN}_RESERVER` and
   confirm or correct the scan's count for R-T4f (unlock calls on the success
   path, including calls through a helper method); R-T4f is recorded, not
   scored.
7. **Results.** Write `results\{RUN}\results.md` with one table, one row per
   rubric item of `..\kit\rubric.md` for task {TASK}, the common items and the
   validity checks, columns: item, result (number or yes/no), evidence (file
   and line, test name, ATC finding or metric). M-1 comes from the
   `cost_state_*` fields, M-2 is `mcp_tool_calls` (with `tool_calls` and
   `tool_search_calls` beside it), M-4 is `first_turn_context`. For R-T2d,
   count the address literals in the statements the scan reports for
   `ZCL_ZSM_X{RUN}_MAIL_SETUP` and keep the statement count as a note (K24).
   Copy values; do not add judgements.
8. **Deletion list.** Search {DEST} again, read only, for `*ZSM_X{RUN}_*` and
   append the list of all objects found, including the acceptance shell class,
   to `results.md` under "To delete". Do not delete anything.
