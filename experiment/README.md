# Experiment — Do the ABAP Rules Change AI-Written Code?

> 📝 This folder holds a small, documented experiment, not a benchmark. It was run once, on 2026-11-24, with one model (`claude-opus-5-5`) in Claude Code `2.1.331`, as recorded by the run script. Results hold for that model, that tool version and these six tasks.

## 📖 Question

Does giving an AI coding assistant this guide's rule set change the quality, cost and speed of the ABAP code it writes?

## 🧪 Design

Three conditions, each given the same six tasks, one run per task and condition (18 runs), plus a three-run pilot on task T1.

| Condition | Context file in the run folder |
|---|---|
| A | none ([experiment/conditions/A](conditions/A/README.md)) |
| B | the full rule set, [docs/ABAP-Development-Rules.md](../docs/ABAP-Development-Rules.md) at commit `e916cdd` ([experiment/conditions/B](conditions/B/README.md)) |
| C | the compact rule file, one line per rule ([experiment/conditions/C/CLAUDE.md](conditions/C/CLAUDE.md), frozen as used) |

| Task | Subject | System and language version |
|---|---|---|
| [T1](tasks/T1-sales-order-bapi.md) | Sales order through a BAPI | on-premise, Standard ABAP |
| [T2](tasks/T2-late-order-mail.md) | Late-order mail | on-premise, Standard ABAP |
| [T3](tasks/T3-carrier-reader-authorization.md) | Carrier reader with authorization | on-premise, Standard ABAP |
| [T4](tasks/T4-stock-reservation-lock.md) | Stock reservation with a lock | SAP BTP ABAP environment, ABAP for Cloud Development |
| [T5](tasks/T5-order-json-cloud.md) | Order as JSON | SAP BTP ABAP environment, ABAP for Cloud Development |
| [T6](tasks/T6-rate-import-errors.md) | Exchange rate import errors | on-premise, Standard ABAP |

Each task file gives fixed interfaces and a spec; the run prompt header is [experiment/tasks/00-run-prompt-header.md](tasks/00-run-prompt-header.md). The assistant works through an MCP server for ADT, may create and activate objects but may not run unit tests, and gets no answer to questions beyond "Decide yourself." An evaluation session then runs the acceptance test of the task, ATC and a pattern scan.

What is measured is defined in [experiment/rubric.md](rubric.md): counts, yes/no items and numbers read from tools, nothing scored by judgement. The procedure, the run configuration and every kit change (K1–K28) with its reason are in [experiment/protocol.md](protocol.md); the safety rules in [experiment/safety.md](safety.md).

## 📁 Contents

| Path | Content |
|---|---|
| `tasks/` | Run prompt header and the six task specs |
| `acceptance/T1`–`T6` | Acceptance test per task: a shell class and its test include, with the run ID as a placeholder |
| `reference/T1`–`T6` | Reference implementations (run ID `REF`) that validated the acceptance tests |
| `conditions/` | The three conditions (A note, B pointer to a commit, C frozen file) |
| `claude-config/settings.json` | The run configuration: tool allowlist, deny list, `dontAsk` |
| `collect/` | Run and evaluation scripts, the evaluation prompt and the `runs.csv` header |
| `rubric.md`, `protocol.md`, `safety.md` | What is measured, how runs are made, what must never happen |
| `results/2026-11/` | The results of the 2026-11 runs and `metrics.csv` |

## 🔁 Reproduce on Your Own Sandbox

Use only a development or sandbox system of your own, never a customer system, and give the assistant only what it needs ([Rule 15.6](../docs/ABAP-Development-Rules.md#156-connect-an-assistant-only-to-your-own-sandbox-and-restrict-what-it-may-write)). Every object the runs create is a local test object with the run prefix `ZSM_X<run>_`; no task writes table rows, sends mail or calls a BAPI for real.

You need Claude Code, an MCP server for ADT that provides the tools named in `claude-config/settings.json`, Windows PowerShell 5.1 for the two `.ps1` scripts and Python 3.10 or later for the Python scripts.

1. **Lay out the folders** as in [experiment/protocol.md](protocol.md#folder-layout-outside-any-guide-repository): a root folder (the experiment used `C:\ABAP-Experiment`) with `claude-config\`, `kit\` (a copy of this folder), `runs\`, `eval\` and `start_run.ps1`, outside any repository. The scripts take the root as a parameter: `start_run.ps1 -Root <folder>` and `eval_start.ps1 -Root <folder>` (default `C:\ABAP-Experiment`); the Python scripts take their paths as arguments.
2. **Prepare the conditions.** Condition A gets nothing. Condition B: `git show e916cdd:docs/ABAP-Development-Rules.md` saved as `runs\B\CLAUDE.md` and `runs\B\AGENTS.md`. Condition C: `conditions/C/CLAUDE.md` saved as `runs\C\CLAUDE.md` and `runs\C\AGENTS.md`. To test the improved compact file instead, use `ai/AGENTS.md` and report it as a different condition.
3. **Set up the run configuration** once, as described in the protocol: `CLAUDE_CONFIG_DIR` pointing to `claude-config\`, `settings.json` from this folder, the MCP server registered in user scope.
4. **Write the prompts.** For each run, fill `{RUN}`, `{DEST}` and `{PACKAGE}` in the run prompt header and append the task's "Spec text"; save it as `eval\prompts\<run>.txt`.
5. **Run** in the order of the protocol ("Order and run IDs"): `.\start_run.ps1 -RunId B3`. The script checks the configuration, copies the prompt into the run folder as `TASK.md` and starts the session. It refuses T1 and pilot run IDs, because the 2026-11 T1 runs were started with the prompt pasted (K20); to repeat T1 the same way, start the session yourself with the same configuration and paste the prompt.
6. **Evaluate** each run with `collect\eval_start.ps1` and `collect\evaluation-prompt.md`, after `collect_metrics.py` has written `metrics.json`.
7. **Delete** every run's objects from the deletion list of its evaluation and confirm with a fresh search.

> ⚠️ **VERSION-DEPENDENT: Claude Code options and transcript records.** The scripts use `--permission-mode dontAsk`, the positional prompt argument and the transcript's `permission-mode` and `cost-state` records of Claude Code `2.1.331`. Check `claude --help` and the [Claude Code documentation](https://code.claude.com/docs/) for your version before a run.

## 📊 Results (2026-11)

Full tables, the pilot and every deviation: [experiment/results/2026-11/README.md](results/2026-11/README.md). Per condition, full run, 6 runs each:

| Item | A (no file) | B (full rules) | C (compact file) |
|---|---|---|---|
| Acceptance tests passed, before / after the T2 test fix K21 | 5 / 6 of 6 | 6 / 6 of 6 | 5 / 6 of 6 |
| Defects in the items a task targets | A1 commit and rollback in a reusable class; A2 three hard-coded mail addresses; A4 lock object whose generated modules lock nothing | none | C4 lock object whose generated modules lock nothing |
| Own unit test methods written | 0 | 20 | 30 |
| Failed activations | 0 | 2 | 1 |
| ATC findings, priority 1 / 2 / 3 | 0 / 0 / 1 | 0 / 0 / 1 | 0 / 0 / 1 |
| First-turn context, sum (tokens) | 252,682 | 581,524 | 280,596 |
| `cost_state_usd`, sum | 3.81 | 9.54 | 5.72 |
| Wall-clock, sum (s) | 503 | 795 | 883 |

Ratios of the sums: cost B/A 2.50, C/A 1.50, B/C 1.67; wall-clock B/A 1.58, C/A 1.76. The full rule set added about 54,800 tokens to the first turn of every run, the compact file about 4,600.

**Which compact file was measured.** Condition C is the frozen file in `conditions/C/CLAUDE.md`. Seven of its lines (7.22–7.26, 8.17, 8.18) are rule headings, because Chapter 20 had no line for those rules then, and its 10.1 line is a refactoring sentence instead of the rule's line (a build defect). The compact file published for use, [ai/AGENTS.md](../ai/AGENTS.md), differs from it in the lines for 7.12, 7.22, 7.24, 8.17, 8.18 and 10.1 and in a note that the file is generated; the results README lists both versions of each line. **`ai/AGENTS.md` has not been measured.** A future run with it will go into a new `experiment/results/<YYYY-MM>/` folder; the 2026-11 results stay as they are.

## ⚠️ Known Limits

- **One run per cell.** Model output varies between runs; 18 runs show tendencies, not significant differences.
- **One model, one tool version.** `claude-opus-5-5` in Claude Code `2.1.331`.
- **Specs fix the interfaces.** The acceptance tests need fixed public interfaces, so design rules about dependencies (Rule 5.4, Rule 8.17) cannot show an effect.
- **The acceptance tests use doubles.** They cannot see a lock object whose generated modules lock nothing; the evaluation reads the generated module instead (rubric R-T4e).
- **The T2 test changed after part 1 (K21).** The first version also failed on markup the class put into its own template; the fixed test was checked against a probe that leaves the note unescaped (fails) and one that escapes it (passes). Both results are reported.
- **Runs could not execute tests**, in every condition.
- **Task delivery differs between T1 (pasted) and T2–T6 (`TASK.md`)**; within a task all conditions got the same delivery.
- The protocol lists further limits (account-level context, systems, pattern-based scan, order effects).

## 🧾 Errata

The scripts are frozen as used in the 2026-11 runs; these known inaccuracies are not corrected in them:

| File | Text | Correction |
|---|---|---|
| `collect/start_run.ps1`, line 42 | "it was not executed when written" | The script started the 15 runs of T2–T6. |
| `collect/eval_start.ps1`, line 14 | "not executed when written" | The comment dates from when the script was written; it says nothing about later use. |
| `collect/fill_run.py`, line 7 | example output folder `eval\A1\acceptance` | The layout since K15 is `eval\results\<run>\acceptance`. |
| `protocol.md`, Operator steps | "Start each run with `start_run.ps1`, paste the prompt" | From T2 on nothing is pasted: the script copies `TASK.md` and starts the session with a fixed message (K20). |

## 🔗 Related

- [ai/AGENTS.md](../ai/AGENTS.md) — the compact rule file for use, generated from Chapter 20
- [20-Best-Practices](../20-Best-Practices/README.md) — one line per rule, the source of the compact file
- [30-Tools-AI-Assistance](../30-Tools-AI-Assistance/README.md) — AI assistants, MCP servers for ADT and their safety model
- [27-Lock-Objects](../27-Lock-Objects/README.md) — the empty lock mode that T4 tests
