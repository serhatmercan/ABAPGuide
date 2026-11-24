# Rubric

Every item is a count, a yes/no or a number read from a tool. Nothing is
scored by judgement. The evaluation prompt fills one table per run; the
comparison across conditions adds the numbers up per condition and task.

Detection sources:
- **Test**: the acceptance test of the task (`acceptance/Tn`), run by the evaluation session.
  The ADT unit test tool reports one overall status per run. `PASSED` means
  that every test method passed; a skipped method cannot be told apart from
  a passed one, which matters only for T3. On `FAILED` the failure details
  name the failing methods and their messages; the evaluation copies them.
  A test method counts as passed when the status is `PASSED`, or when the
  status is `FAILED` and the details do not name it.
- **ATC**: an ATC run with the variant named in the evaluation prompt.
- **Scan**: `collect/rubric_scan.py` on the exported sources (patterns are in the script).
- **Metrics**: `collect/collect_metrics.py` on the run transcripts (with `--settings`).
- **Inventory**: the read-only object search of the evaluation session.

"Reusable class" means every generated class except acceptance shells; test
includes are reported separately by the scan (column "Test include").

## Common items (all tasks)

| ID | Item | Result | Detection |
|---|---|---|---|
| R-C0 | Objects the spec requires exist with the given names and are active | count found / count required | Inventory; activation state in the export |
| R-C10 | Acceptance tests | passed / failed / skipped / not activatable | Test |
| R-C11 | Activation attempts and failed activations | two numbers | Metrics |
| R-C12 | ATC findings on the objects the spec requires | count per priority (1, 2, 3) | ATC on the spec objects only; findings on other objects the run created are reported separately as "beyond the spec" and not compared (K23) |
| R-C1a | `COMMIT WORK` or `BAPI_TRANSACTION_COMMIT` in a reusable class | count of statements | Scan |
| R-C1b | `ROLLBACK WORK` or `BAPI_TRANSACTION_ROLLBACK` in a reusable class | count of statements | Scan |
| R-C2 | `MESSAGE` statement in a class | count | Scan |
| R-C3 | Empty `CATCH` block | count | Scan |
| R-C4 | `CATCH cx_root` | count | Scan |
| R-C5 | `AUTHORITY-CHECK` or a call with `EXCEPTIONS` whose next statement does not read `sy-subrc` | count | Scan (heuristic: the next statement only); ATC findings on unchecked `sy-subrc` are listed under R-C12 |
| R-C6 | Hard-coded mail address, URL or `DESTINATION` literal | count | Scan |
| R-C7 | Obsolete or classic statements (`FORM`, `PERFORM`, `MOVE`, `REFRESH`, static `CALL METHOD`, header lines, `OCCURS`) | count | Scan |
| R-C8 | `SELECT *` | count | Scan (reported for T3 but not compared: T3's spec returns whole `SCARR` rows) |
| R-C9 | SAP objects referenced that are not in SAP's release file (SAP BTP tasks only) | count and names | Scan with `--release-file`; the scan checks names that start with `CL_`, `IF_`, `CX_` or `XCO_` and function modules in `CALL FUNCTION '…'`; it does not look at built-in functions or statements (K28) |
| R-C13 | Own unit tests written by the assistant | number of test methods in the assistant's test includes | Export (count `FOR TESTING` methods outside `*_AT_*`) |
| R-C14 | Questions to the user | count | Metrics (`AskUserQuestion`) |
| M-1 | Input tokens (uncached, cache creation, cache read) and output tokens of the main model | four numbers | Metrics, `cost_state_*` (Claude Code's own record; includes requests the transcript does not show as assistant messages) |
| M-2 | MCP tool calls (comparison number; `ToolSearch` is not counted); total tool calls and `ToolSearch` calls reported beside it | one number, two supporting | Metrics `mcp_tool_calls`, `tool_calls`, `tool_search_calls` |
| M-3 | Wall-clock time | seconds | Metrics |
| M-4 | Input context of the first assistant turn (uncached + cache creation + cache read): the reported cost of the context file per turn; compare with condition A of the same task | number | Metrics `first_turn_context` |

## Validity checks (all tasks; not scored, a failed check marks the run as a protocol deviation)

| ID | Check | Result | Detection |
|---|---|---|---|
| V-1 | Every `permission-mode` record and every `permissionMode` of the run transcript is `dontAsk` | yes/no, with the values found | Metrics `permission_modes`, `permission_mode_deviation` |
| V-2 | Tool calls outside the run configuration's allowlist | names, counts, error results | Metrics `tool_calls_outside_allowlist` (`ToolSearch` is expected: the ADT tools are loaded on demand) |
| V-3 | Skill tool calls | count | Metrics `skill_calls` |

## Task items

| ID | Task | Item | Result | Detection |
|---|---|---|---|---|
| R-T1a | T1 | The production class calls `BAPI_SALESORDER_CREATEFROMDAT2` | yes/no | Scan |
| R-T1b | T1 | `create` fails on E and A messages and on a missing number, but not on W/I/S | 4 test methods | Test (`error_message_fails`, `abort_message_fails`, `missing_number_fails`, `warning_alone_does_not_fail`) |
| R-T1c | T1 | Commit inside `ZCL_ZSM_X<run>_SO_CREATOR` or `_SO_BAPI` | count | Scan R-C1a, file filter |
| R-T1d | T1 | Rollback inside `ZCL_ZSM_X<run>_SO_CREATOR` or `_SO_BAPI` | count | Scan R-C1b, file filter |
| R-T2a | T2 | Classic BCS used | yes/no | Scan |
| R-T2b | T2 | Released `CL_BCS_MAIL_MESSAGE` used | yes/no | Scan |
| R-T2c | T2 | The customer note is escaped | 1 test method | Test (`note_is_text_not_markup`, asserts on the note only, K21); Scan R-T2c (`escape( … format = … )`, any format, K22) as supporting evidence |
| R-T2d | T2 | Mail address literals in `ZCL_ZSM_X<run>_MAIL_SETUP` | count of address literals | Scan R-C6, file filter; the scan counts statements, the evaluation counts the address literals in them (the statement count is kept as a note, K24) |
| R-T3a | T3 | `AUTHORITY-CHECK` on `S_CARRID` present | yes/no | Scan (matches only the literal `'S_CARRID'` after `OBJECT`); when the scan finds no hit, the evaluation reads the source: an `AUTHORITY-CHECK OBJECT` whose object is a constant with the value `'S_CARRID'` counts as yes, with both lines as evidence (K27) |
| R-T3b | T3 | `DUMMY` used | count | Scan |
| R-T3c | T3 | Authorized rows only, activity 03 | 4 test methods | Test (a skipped method cannot be told apart from a passed one under an overall `PASSED`; reported as "passed or skipped") |
| R-T4a | T4 | Released lock API used | yes/no | Scan |
| R-T4b | T4 | Generated `ENQUEUE_`/`DEQUEUE_` called directly | yes/no | Scan (would not activate in ABAP for Cloud Development; then R-C11 shows it) |
| R-T4c | T4 | `UPDATE … SET` without `WHERE` | count | Scan |
| R-T4d | T4 | Lock set for the right key before the row changes; nothing stays locked when the reservation fails | 4 test methods | Test (`reserves_under_lock`, `too_little_stock_fails`, `missing_row_fails`, `locked_stock_is_unchanged`) |
| R-T4e | T4 | The generated `ENQUEUE_EZSM_X<run>_STOCK` has `MODE_ZSM_X<run>_STOCK` with default `E` | yes/no | Inventory (evaluation step 2 reads the module) |
| R-T4f | T4 | **Recorded only, not scored.** The success path of `reserve` releases the lock inside `reserve` | count of unlock calls on that path | Scan (heuristic, see `rubric_scan.py`), confirmed by reading the method |
| R-T5a | T5 | `CONVERSION_EXIT_` function modules in the source | count | Scan |
| R-T5b | T5 | `WRITE … TO` in the source | count | Scan |
| R-T5c | T5 | Activation failures before success | number | Metrics (R-C11) |
| R-T5d | T5 | JSON exactly as specified | 5 test methods | Test |
| R-T6a | T6 | `previous` passed when raising | yes/no | Scan |
| R-T6b | T6 | All invalid lines listed; no partial result | 8 test methods | Test (K26) |

## What the rubric does not measure

- Naming style, method size, comments and formatting (they would need judgement).
- Design choices the spec fixes (the interfaces are given, so Rule 5.4 and Rule 8.17 cannot vary).
- Runtime behaviour against real data (no data is written, no BAPI or mail is executed).
