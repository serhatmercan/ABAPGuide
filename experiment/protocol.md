# Protocol

## Question

Does giving an AI coding assistant this guide's rule set change the quality,
cost and speed of the ABAP code it writes? Three conditions:

| Condition | Context file in the run folder |
|---|---|
| A | none |
| B | the full rule set (`conditions/B/CLAUDE.md`, identical `AGENTS.md`) |
| C | the compact rule file (`conditions/C/CLAUDE.md`, identical `AGENTS.md`) |

## Folder layout (outside any guide repository)

```
C:\ABAP-Experiment\
  claude-config\        dedicated Claude Code configuration directory for all runs
    settings.json        copy of kit\claude-config\settings.json
  kit\                  copy of this repository's experiment\ folder (conditions, tasks, acceptance, collect, rubric, protocol)
  runs\
    A\A1\ … A\A6\       one folder per run; no context file anywhere above them
    B\CLAUDE.md          condition B context (also AGENTS.md)
    B\B1\ … B\B6\
    C\CLAUDE.md          condition C context (also AGENTS.md)
    C\C1\ … C\C6\
    P\                   pilot: P\A\PA1, P\B\CLAUDE.md + P\B\PB1, P\C\CLAUDE.md + P\C\PC1
  eval\                 evaluation session folder: runs.csv, metrics.json, prompts\<run>.txt, results\<run>\ per run
  start_run.ps1         copy of kit\collect\start_run.ps1; starts every run (see How a run is started)
```

- Claude Code reads `CLAUDE.md` from the start folder and its parents, so a
  run started in `runs\B\B1` sees `runs\B\CLAUDE.md`; a run in `runs\A\A1`
  sees no project context file. Check before the first run that
  `C:\ABAP-Experiment` and `C:\` contain no `CLAUDE.md`.
- Each run gets its own folder, so each has its own transcript folder under
  `C:\ABAP-Experiment\claude-config\projects\` and its own (empty) auto-memory.
- `kit\` and `eval\` are siblings of `runs\`, never parents, so no run folder
  can see the kit, the tasks' metadata or the acceptance tests.
- `claude-config\` is a sibling as well, never inside a run folder; the
  installed Claude Code refuses a configuration directory that points into
  the folder it runs in.

## Dedicated configuration directory (all runs, pilot and full)

Every run session starts with the environment variable `CLAUDE_CONFIG_DIR`
set to `C:\ABAP-Experiment\claude-config`. The installed Claude Code version
(2.1.331) reads this variable: it moves the configuration home (the global
`.claude.json` with user-scope MCP servers, `settings.json`, the user memory
file `CLAUDE.md` and the `projects\` transcripts) to that directory, and it
keeps the login in a separate credential entry derived from the directory.
This was checked read only in the installed program, not by starting a
session; the pilot confirms it (see Pilot).

The directory contains:

- **No user-level `CLAUDE.md`.** A user-level `~\.claude\CLAUDE.md`, if you
  have one, is not loaded in any condition.
- **No hooks.** `settings.json` has no `hooks` key, and nothing else is
  copied from `~\.claude`, so user-level hooks, if any, do not run.
- **`settings.json`** from `kit\claude-config\settings.json`:
  - `allow`: the ADT tools a run needs (destinations, search, creatable types,
    validate, create, read, edit, check, activate, file URIs, document
    symbols, AFF specification, ATC start and result);
  - `deny`: the deny list the author uses for ABAP work
    (shell deletions, push, hard reset, `.env`, transports, generators,
    quick fixes, AI fixes, exemptions, object actions, business services),
    plus `mcp__adt__abap_unit_run_tests`;
  - `defaultMode`: `dontAsk`: a tool that is not allowed is refused without a
    prompt, so no run waits for a permission answer and the operator never
    decides a permission during a run. `start_run.ps1` also starts every run
    with `--permission-mode dontAsk` (listed by `claude --help` of 2.1.331;
    the script checks the help text before each run).
  - **Never press Shift+Tab in a run.** It cycles the permission mode.
    The pilot run PA1 left `dontAsk` before the prompt: its transcript
    records a plan-mode exit followed by `auto`, not which key or command
    caused it. The
    evaluation reads every `permission-mode` record of the transcript and
    reports a run as a protocol deviation if any record is not `dontAsk`
    (rubric V-1).
  - No token and no URL is in the file.
- **The ADT MCP server, registered once in user scope** of this directory.
  You do this yourself, once, before the pilot:
  1. `set CLAUDE_CONFIG_DIR=C:\ABAP-Experiment\claude-config` (cmd) or
     `$env:CLAUDE_CONFIG_DIR = "C:\ABAP-Experiment\claude-config"` (PowerShell);
  2. `claude` and log in (the login is separate from your normal one);
  3. `claude mcp add --scope user --transport http adt <ADT_MCP_URL> --header "<HEADER>"`
     (option names as shown by `claude mcp add --help` of the installed
     version: `-s, --scope <local|user|project>`, `-t, --transport`,
     `-H, --header`);
  4. log the ADT destinations on as for normal work, then check with
     `claude mcp list` that `adt` is connected.

No local-scope MCP registration and no `.claude\settings.local.json` is
needed in the run folders any more; all runs share the one configuration.

### Why runs may not execute unit tests

`mcp__adt__abap_unit_run_tests` is denied in the run configuration. Runs may
write their own tests (counted by R-C13) but not execute them; the
evaluation session runs the acceptance tests. The reason is safety: T1
implements a real call of `BAPI_SALESORDER_CREATEFROMDAT2`. A test written by
a run that does not replace the BAPI with a double, together with a commit
anywhere in the code under test, could create a real sales order when the
test runs. The same holds in a weaker form for T2 (a real mail sent with a
commit) and T4 (a real row changed outside the test double). The acceptance
tests use doubles only (checked with the reference runs, see Kit changes).

A denied call still appears in the transcript as a tool call, so
`collect_metrics.py` reports the attempts as `unit_test_runs`.

## The evaluation session

The evaluation session runs in `C:\ABAP-Experiment\eval\` **without**
`CLAUDE_CONFIG_DIR`, that is with your normal configuration, because it must
run the acceptance tests and ATC. It never runs with the run configuration.
Start it with `C:\ABAP-Experiment\kit\collect\eval_start.ps1`, which refuses
to start when `CLAUDE_CONFIG_DIR` is set (process, user or machine). Register
the ADT server for `eval\` as you do for your other folders. Each run's
outputs go to `eval\results\<run>\`.

## How a run is started

1. Open a new PowerShell window in `C:\ABAP-Experiment` (do not set
   `CLAUDE_CONFIG_DIR` yourself) and run `.\start_run.ps1 -RunId B3`
   (pilot IDs: `-RunId PB1`). The script:
   - sets `CLAUDE_CONFIG_DIR` to `C:\ABAP-Experiment\claude-config` for its
     own process and restores the previous value when it ends;
   - restores `claude-config\settings.json` from the kit if it differs, and
     says so on screen and in the `notes` column;
   - stops if the run folder is missing or not empty, if a transcript folder
     for the run exists, if `runs.csv` already has a start time for the run,
     or if a `CLAUDE.md`, `CLAUDE.local.md` or `.claude\CLAUDE.md` exists in
     the run folder or above it other than the condition's own file
     (identical to the kit's), or in `claude-config\`;
   - copies `eval\prompts\<run>.txt` into the run folder as `TASK.md`
     (byte-identical; the run folder must be empty before the copy);
   - writes condition, task, folder, model, `claude --version` and the start
     time into `eval\runs.csv` (every field quoted; never edit the file by
     hand);
   - starts `claude --model <model> --permission-mode dontAsk "Read TASK.md
     in this folder and carry out the task in it exactly."` in the run
     folder. The message is the positional `[prompt]` argument listed by
     `claude --help` of 2.1.331; the session stays interactive. It is the
     same for every run.
   `.\start_run.ps1 -RunId B3 -DryRun` does every check and the copy into a
   temporary folder, then stops without changing anything.
2. Paste nothing. The prompt file (`tasks/00-run-prompt-header.md`, the part
   after the rule line, with `{RUN}`, `{DEST}` and `{PACKAGE}` filled,
   followed by the "Spec text" section of the task file) reaches the
   assistant as `TASK.md`; the three prompts of a task differ only in the run
   ID. Never press Shift+Tab.

   **Task delivery (K20).** T1 (`A1`, `B1`, `C1`) was started with the prompt
   pasted as one message. T2 to T6 use `TASK.md` and the initial message in
   all three conditions, so each task is delivered the same way in every
   condition. `start_run.ps1` refuses T1 and pilot run IDs. Reading
   `TASK.md` is a file read inside the working directory, which `dontAsk`
   allows without an allow rule (Claude Code documentation, permission
   modes; settings unchanged). The evaluation counts that read as a non-MCP
   tool call and expects it under V-2 from T2 on; M-2 compares MCP tool
   calls only.
3. Do not answer questions or give hints. If the assistant asks a question,
   answer "Decide yourself." once and count it (metric R-C14).
4. The run ends when the assistant reports its object list, or after the
   5-activation-attempt cap, or after 60 minutes (record a timeout).
5. Type `/exit`. The script then asks for the end reason (menu: done, cap,
   timeout, other), the number of "Decide yourself." answers and optional
   notes, and writes them with the end time into `runs.csv`. Do not continue
   the session later.

The loaded context file is read from the transcript (`instructions`
attachment) during the evaluation; `/memory`, `/hooks` and `/mcp` checks
before the prompt are optional and need not be recorded.

PowerShell may refuse to run a script, depending on the execution policy of
the machine; check this before the first run (verify on your machine).

## Operator steps

- Create the folders, copy `kit\claude-config\settings.json` into
  `claude-config\`, and copy the context files (conditions B and C only).
- Log in and register the MCP server once in the run configuration.
- Start each run with `start_run.ps1`, paste the prompt, watch for
  questions, answer the end-of-run menu.
- After all runs of a batch: run
  `python -I kit\collect\collect_metrics.py eval\runs.csv --projects-dir C:\ABAP-Experiment\claude-config\projects --settings kit\claude-config\settings.json --json eval\metrics.json`,
  then start the evaluation session with `kit\collect\eval_start.ps1` and
  work through `collect\evaluation-prompt.md`, one run at a time.
- Delete the objects of each run from the deletion list in its `results.md`
  (ADT or SAP GUI), then confirm with a fresh search that `*ZSM_X<run>_*` is
  empty.

## Order and run IDs

- Run ID = condition letter + task number (`A1` … `C6`); pilot IDs `PA1`, `PB1`, `PC1`.
- Interleave conditions per task (A1, B1, C1, then A2, B2, C2 …) and rotate
  the starting condition per task (task 1: A-B-C, task 2: B-C-A, task 3:
  C-A-B …), so that time of day and system load do not line up with one
  condition.

## Pilot

Task T1 in all three conditions (`PA1`, `PB1`, `PC1`) before the full run.
The pilot checks:

- that the run configuration is the one intended: before pasting the prompt,
  run `/memory` (a local command) in each pilot session and record which
  memory files it lists: none in `PA1`, only `runs\P\B\CLAUDE.md` in `PB1`,
  only `runs\P\C\CLAUDE.md` in `PC1`, and never `~\.claude\CLAUDE.md`
  **[verify: that `/memory` lists the loaded files in the installed version]**;
  `/hooks` should list no hooks;
- that the transcripts land in `C:\ABAP-Experiment\claude-config\projects\`;
- that `collect_metrics.py` finds them with `--projects-dir` and reports
  plausible numbers;
- that the evaluation prompt works end to end and produces a deletion list;
- how long a run takes, to plan the 18 runs.

The BAPI structure fields and the activation of the acceptance tests were
already checked with the reference runs (see Kit changes).

Change the kit only after the pilot, record every change below, and do not
mix pilot results with the full run.

### Pilot outcome (2026-11-24) and its place in the results

The pilot ran PA1, PB1 and PC1 and was evaluated end to end (results in
`eval\results\PA1`, `PB1`, `PC1` and `eval\results\pilot-summary.md`). It
led to the changes K10-K19. The pilot results stay separate: they are never
added to the condition totals, and the full run repeats T1 (`A1`, `B1`, `C1`)
with the changed kit. PA1 ran in permission mode `auto` after a plan-mode
exit before the prompt, PC1 in `auto` from the start, PB1 in `dontAsk`
(rubric V-1).

## Known limits

- **Account-level settings.** The dedicated configuration directory removes
  your user-level `CLAUDE.md`, hooks and settings from all conditions.
  Settings that come with the account or the installation (managed or
  remote policy settings, if any) still apply, equally in all conditions.
- **One run per task and condition.** Model output varies between runs; 18
  runs show tendencies, not significant differences. Repeat runs per cell
  if the pilot shows large variation.
- **One model.** Results hold for the model used, not for assistants in general.
- **Specs fix the interfaces.** The acceptance tests need fixed public
  interfaces, so design rules about dependencies (Rule 5.4, Rule 8.17) cannot
  show an effect.
- **No test runs in the runs.** Runs cannot execute tests, so an assistant
  that would normally test its code and fix it cannot; this applies equally
  to all conditions.
- **Size of condition B.** About 137,000 characters (roughly 27,000–34,000
  tokens) in the context file; Claude Code may warn about a large memory file
  and it costs input tokens in every turn (measured by M-1).
- **Systems.** The two destinations are the on-premise development system and
  the SAP BTP ABAP environment used for the guide; results on other releases
  may differ. `S_CARRID` tests (T3) depend on the tester's own authorizations.
- **Tool behaviour.** A lock object created through the ADT MCP server can
  get an empty lock mode although its file says "exclusive"; the generated
  module then locks nothing. The T4 acceptance test uses a lock double and
  cannot see this; the evaluation reads the generated module instead (R-T4e).
- **The rubric scan is pattern-based.** It counts statements; it does not
  understand control flow (R-C5 checks only the next statement).
- **Order effects.** The same operator, the same day, the same system: the
  rotation reduces but does not remove them.
- **Task delivery differs between T1 and T2-T6.** T1 was pasted, T2-T6 are
  read from `TASK.md` (K20). Within a task all conditions get the same
  delivery, so condition comparisons per task are not affected; totals across
  tasks mix both forms (one extra `Read` call and a different first message
  from T2 on).
- **Account-level context.** Some context comes with the Claude account,
  not with the configuration directory, and reaches every run: the skills
  synced to the account (none about ABAP), the claude.ai connectors
  announced next to `adt`, and a session context with account details. It
  is the same in all conditions; in the pilot no run invoked a skill or
  called a connector (rubric V-2, V-3). It adds to the first-turn context
  of every condition equally, so M-4 differences between conditions remain
  the context file's cost.
- **Test status per method.** The unit test tool reports one overall
  status. `PASSED` means every method passed; skipped methods cannot be told
  apart from passed ones (only T3 can skip). On `FAILED` the details name the
  failing methods. The tool's documented input is a set of objects; a run of
  a single test method is not documented (checked read only), so T3 is
  reported as "passed or skipped" (verify in your system if a method-level
  run is needed).
- **Requests outside the transcript.** Claude Code can send model requests
  that the transcript does not record as assistant messages (PB1 and PC1:
  one request after the final answer, with the full conversation as cached
  input). M-1 therefore comes from Claude Code's own `cost-state` record;
  the transcript sum is reported beside it.

## Kit changes

Paths named `eval\…` are the local evaluation outputs of the experiment.
They are not published; their content is summarised in
`results/2026-11/README.md`.

Every change after the first version of the kit, with the reason.

### 2026-11-24 — before the pilot (reference runs)

The reference runs used run ID `REF`: a reference implementation per task
(`reference/T1`–`T6`), created with the acceptance test on the destination
the task names, activated, tested and read back.

| # | File | Change | Reason |
|---|---|---|---|
| K1 | `tasks/T1-sales-order-bapi.md`, `acceptance/T1` | The material goes to `MATERIAL_LONG`, not `MATERIAL`; the test checks `item-material_long` | In the on-premise system `BAPISDITM-MATERIAL` is an 18-character field (`MATNR18`) and `MATERIAL_LONG` the 40-character one (`MATNR40`); the request's `MATNR` fits only the long field. The other T1 fields (`DOC_TYPE`, `SALES_ORG`, `DISTR_CHAN`, `DIVISION`, `ITM_NUMBER`, `TARGET_QTY`, `PARTN_ROLE`, `PARTN_NUMB`) were confirmed. |
| K2 | `acceptance/T2` | `body_names_order_and_days` compares `*Please*hurry*`; `note_is_text_not_markup` accepts any named, decimal or hexadecimal character reference for `<` and `>` (PCRE, `#` escaped) | The first version expected `&lt;` and a literal space. `escape( … format = cl_abap_format=>e_xss_ml )` writes hexadecimal references (`&#x20;` for a space), which is valid HTML; the test failed a correct implementation. |
| K3 | `collect/evaluation-prompt.md`, `safety.md`, `protocol.md` | Search pattern `*ZSM_X<run>_*` instead of `*X<run>_*` | `*XREF_*` returned more than 50 SAP objects in each system; the old pattern would put SAP objects on a deletion list. All run objects (including the lock object `EZSM_X<run>_STOCK` and its generated modules) contain `ZSM_X<run>_`. |
| K4 | `protocol.md`, `claude-config/settings.json` | Dedicated configuration directory; unit test runs denied in runs; evaluation session in the normal configuration | Requested before the pilot (removes the user-level context and hooks; prevents test runs that could reach a real BAPI or mail). |
| K5 | `rubric.md`, `collect/evaluation-prompt.md` | New item R-T4e: the generated `ENQUEUE_EZSM_X<run>_STOCK` has a mode parameter with default `E` (SAP BTP: read the module) | The lock-mode trap of the tool (see Known limits) is invisible to the acceptance test. |
| K6 | `rubric.md` | R-C8 (`SELECT *`) is reported but not compared for T3 | T3's spec returns whole `SCARR` rows, so `SELECT *` there follows the spec. |
| K7 | `collect/collect_metrics.py` | The usage text names `--projects-dir` for the run configuration | Transcripts now land in the dedicated configuration directory. |
| K8 | `tasks/T4-stock-reservation-lock.md`, `acceptance/T4`, `rubric.md`, `collect/rubric_scan.py`, `collect/evaluation-prompt.md`, `reference/T4/variant-b` | Option (c): the spec is neutral on when the lock of a successful reservation is released ("lock the row while reserving; if the reservation fails, nothing stays locked"). The test asserts on success that the lock was requested for the right key (material and plant) before the row changed (the lock double reads the row at lock time), and on every failure path that nothing stays locked (the double counts held locks); it does not assert release timing on success. R-T4d reworded (4 test methods); new R-T4f, recorded only, not scored: unlock calls on the success path of `reserve` (scan heuristic, confirmed in the evaluation). | The old spec required release before `reserve` returns, which conflicts with Rule 7.12 (release after the commit or rollback). Re-run on SAP BTP with `REF`: variant A (releases inside `reserve`) PASSED; variant B (leaves the lock to the caller, `reference/T4/variant-b`) PASSED; a negative check without release on the failure path FAILED `too_little_stock_fails` and `missing_row_fails` as intended. Scan: variant A count 1, variant B count 0. |
| K9 | `collect/rubric_scan.py` | The T4 pattern for `sy-dbcnt`/`sy-subrc` is labelled "T4 supporting … (not a rubric item)" instead of "R-T4d" | Its label clashed with rubric item R-T4d. |

Not changed, checked by the reference runs:

- T3's `allow` method with `cl_aunit_auth_check_types_def=>authfield_values-fieldvalues` and `lower_value` from a string activated as written; the T3 test run reported PASSED (the tool's summary does not say whether a method was skipped).
- T6's `CONV zcl_…=>rate-rate( … )` activated as written.
- Every acceptance test uses doubles only: T1 an API double (the BAPI class is never instantiated), T2 sender and setup doubles, T3 the ABAP SQL test double for `SCARR` and the authorization test environment, T4 the ABAP SQL test double for the stock table and a lock double, T5 and T6 no dependency.

### 2026-11-24 — after the pilot (PA1, PB1, PC1)

Source: `eval\results\pilot-summary.md` and the three `results.md`.

| # | File | Change | Reason |
|---|---|---|---|
| K10 | `collect/start_run.ps1` (new; copied to `C:\ABAP-Experiment\start_run.ps1`), `collect/runs.csv.template`, `protocol.md` (How a run is started, What I do by hand — now Operator steps, Folder layout) | One script per run (`.\start_run.ps1 -RunId B3`): sets `CLAUDE_CONFIG_DIR` for its own process, restores `claude-config\settings.json` from the kit if it differs (and notes it), checks the context files in and above the run folder, writes model, version and start time to `runs.csv`, starts `claude --model … --permission-mode dontAsk`, and after exit writes end time, end reason (menu), questions answered and notes. Every CSV field is quoted, UTF-8 without byte order mark. The template has all eleven columns. | In the pilot, `runs.csv` was edited by hand: every row was one quoted field, `collect_metrics.py` stopped with a `TypeError`, start times were missing. |
| K11 | `eval\runs.csv` (outside the kit) | The three pilot rows rewritten with every field quoted (UTF-8 without byte order mark, LF); values unchanged, empty fields stay empty. Done with a Python equivalent of the writer in `start_run.ps1`, because PowerShell could not be run in the session that made the change; `.\start_run.ps1 -RepairOnly` rewrites the file the same way. | Same as K10. |
| K12 | `protocol.md`, `rubric.md` (V-1), `collect/collect_metrics.py`, `collect/evaluation-prompt.md` (step 0) | Runs start with `--permission-mode dontAsk` (option listed by `claude --help` of 2.1.331, checked read only). Never press Shift+Tab in a run. `collect_metrics.py` reports every `permission-mode` value; the evaluation reports a run as a deviation if any value is not `dontAsk`. | PA1 left `dontAsk` before the prompt (plan-mode exit, then `auto`); PC1 ran in `auto` from the start; only PB1 ran in `dontAsk`. |
| K13 | `rubric.md` (detection sources, R-T3c), `collect/evaluation-prompt.md` (step 4), `protocol.md` (Known limits) | Documented: an overall `PASSED` means every test method passed; skipped methods cannot be told apart (T3 only, reported as "passed or skipped"); on `FAILED` the details name the failing methods. | The tool reports one overall status per run. A single-method run is not in the tool's documented input (a set of objects by URI, name or file name; checked read only, not tried), so it is not used for T3. |
| K14 | `collect/collect_metrics.py`, `rubric.md` (M-1, M-4) | M-1 from Claude Code's own `cost-state` record (main model), with the transcript sum and the difference (`unrecorded_*`) beside it; other models listed separately; new M-4 `first_turn_context` (uncached + cache creation + cache read of the first assistant message) as the reported cost of the context file per turn. | The script's sums matched the transcript records exactly; the difference to `cost-state` in PB1 (input 506, cache creation 1,139, cache read 124,842, output 17) and PC1 (506, 989, 72,688, 20) is one model request after the final answer that the transcript does not record as an assistant message; its cache read equals the full conversation of the last turn. PA1 has no such request. |
| K15 | `collect/eval_start.ps1` (new), `collect/evaluation-prompt.md`, `protocol.md` (The evaluation session) | The evaluation starts with `eval_start.ps1`, which refuses to run when `CLAUDE_CONFIG_DIR` is set (process, user or machine). The evaluation prompt uses the layout `eval\results\<run>\` and `..\kit\`. | The run configuration's history showed a session in `eval\` at 14:12; the old prompt wrote to `eval\<run>\` and assumed a kit copy inside `eval\`. |
| K16 | `rubric.md`, `collect/rubric_scan.py`, `tasks/T1`, `T2`, `T4` (operator metadata) | R-C1 split into R-C1a (commits) and R-C1b (rollbacks); R-T1c counts commits, new R-T1d rollbacks. M-2 compares MCP tool calls (`ToolSearch` excluded), with total tool calls and `ToolSearch` calls beside it. | PA1's R-T1c of 2 was one commit and one rollback. Every run needs 2-3 `ToolSearch` calls to load the ADT tools. |
| K17 | `protocol.md` (Known limits), `rubric.md` (V-2, V-3) | Known limit: account-synced skills, claude.ai connectors and the session context reach every run, equally; the evaluation records tool calls outside the allowlist and skill calls. | Present in all three pilot runs; no skill invoked, no connector called. |
| K18 | `protocol.md` (Pilot outcome) | The pilot results stay separate and are never added to the condition totals; the full run repeats T1 (`A1`, `B1`, `C1`). | The kit changed after the pilot, and two of three pilot runs ran in the wrong permission mode. |
| K19 | `README.md` | File table lists `start_run.ps1` and `eval_start.ps1`; the pilot is recorded as done. | Keeps the overview current. |
| K20 | `collect/start_run.ps1` (and its copy `C:\ABAP-Experiment\start_run.ps1`), `protocol.md` | From T2 on, every run starts from a task file: after all checks pass (the empty-folder check runs before the copy), the script copies `eval\prompts\<run>.txt` into the run folder as `TASK.md` (byte-identical, hash-checked) and starts `claude --model … --permission-mode dontAsk` with the fixed initial message "Read TASK.md in this folder and carry out the task in it exactly." (positional `[prompt]`, checked in `claude --help`). T1 and pilot run IDs are refused. New `-DryRun`: every check and the copy into a temporary folder, then stop; nothing changed. `claude-config/settings.json` unchanged: the documentation says `dontAsk` allows file reads inside the working directories. | Removes the manual paste (one less operator step and no paste errors). T1 (`A1`, `B1`, `C1`) ran with the pasted prompt; T2-T6 use `TASK.md` in all three conditions, so each task stays consistent within itself. |

### 2026-11-24 — after part 1 of the full run (A1, B1, C1, A2, B2, C2)

Source: `eval\results\part1-summary.md`. Made after all six part-1 runs had
finished and before any evaluation of part 2.

| # | File | Change | Reason |
|---|---|---|---|
| K21 | `acceptance/T2/zcl_zsm_x_run_at_mail.clas.testclasses.abap` | `note_is_text_not_markup` asserts on the note only: the note's tags do not reach the body as tags (`<b>rush` and `rush</b>` not found in the lower-cased body), and the note appears with `<` and `>` escaped (any named, decimal or hexadecimal character reference; `/` plain or escaped). Nothing is asserted about markup the class adds to its own template. | The old test failed when `<b>` appeared anywhere in the body, so it also failed on markup the class itself puts into its HTML template (A2 `zcl_zsm_xa2_late_notice.clas.abap:66`, C2 `zcl_zsm_xc2_late_notice.clas.abap:73`; both escape the note). The spec only asks that the customer note appears as text. The change was made after part 1 and applies to all three T2 runs (A2, B2, C2): their shells were updated with the changed test and run again; both results are reported. |
| K22 | `collect/rubric_scan.py` | R-T2c matches `escape( … format = … )` with any format (for example `e_html_text` or `e_xss_ml`), not only `e_html*`. | A2 and C2 escape the note with `e_xss_ml`, which the old pattern did not match. The T2 scans of A2, B2 and C2 were re-run. |
| K23 | `rubric.md` (R-C12), `collect/evaluation-prompt.md` (step 5) | R-C12 counts ATC findings on the objects the spec requires only; findings on other objects a run creates are reported separately as "beyond the spec" and not compared. | B2 created a table outside the spec (`ZSM_T_XB2_DESK`); one ATC finding was on it. |
| K24 | `rubric.md` (R-T2d), `collect/evaluation-prompt.md` (step 7) | R-T2d is the number of address literals in `ZCL_ZSM_X<run>_MAIL_SETUP`; the scan's statement count is kept as a note. | A2 has 3 address literals in one `CONSTANTS` statement; the scan counted 1. |
| K25 | `eval\runs.csv` (outside the kit) | B2's `end_time` (the local time of the transcript's last record), `end_reason` `done` and `questions_answered` `0` filled in; written the way `start_run.ps1` writes the file (every field quoted, UTF-8 without byte order mark, LF). | The fields were empty after the run. |

### 2026-11-24 — after the full run (text fixes)

Source: `eval\results\part2-summary.md` and `part3-summary.md`. Made after
all 18 runs had been evaluated; no result changes, the evaluations already
reported the facts below.

| # | File | Change | Reason |
|---|---|---|---|
| K26 | `rubric.md` (R-T6b) | R-T6b names 8 test methods, not 6. | The T6 test include has 8 test methods in `ltc_acceptance`; all 8 passed in C6, A6 and B6. |
| K27 | `rubric.md` (R-T3a) | When the scan finds no hit, R-T3a is scored from the source: an `AUTHORITY-CHECK OBJECT` on a constant with the value `'S_CARRID'` counts as yes. | C3 checks `S_CARRID` through a constant (`zcl_zsm_xc3_carr_reader.clas.definitions.abap:14`, used at `….implementations.abap:3`); the scan pattern matches only the literal and reported no hit. |
| K28 | `rubric.md` (R-C9) | States what the scan checks: `CL_`/`IF_`/`CX_`/`XCO_` names and function modules in `CALL FUNCTION`; not built-in functions or statements. | B5 and A5 reference no such name, so R-C9 is 0 with nothing checked; C5's only checked reference is `CL_ABAP_FORMAT`. |

Outside the kit, in the same step: `eval\runs.csv` end fields of C4, B5,
C5, A5, C6, A6 and B6 (as K25) and the pilot notes corrected from the
transcripts; `eval\metrics.json` regenerated.
