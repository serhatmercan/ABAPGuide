# 11 — Classical Reports

## 📖 Introduction

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. `WRITE`-based list processing remains widespread for background jobs, spool output and quick internal tools, and the report event model underpins every classical program you will maintain. It is **not** part of the ABAP Cloud development model — see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

A **classical report** (list processing) uses `WRITE` statements and system-defined list events (`TOP-OF-PAGE`, `END-OF-PAGE`) instead of a GUI container like ALV Grid. While most new development uses ALV or Fiori/UI5, classical reports are still common for quick internal tools, background jobs, and simple audits — and the underlying **event model** (`INITIALIZATION` → `AT SELECTION-SCREEN` → `START-OF-SELECTION`) is foundational knowledge covered in [01-ABAP-Basics](../01-ABAP-Basics/README.md#-classical-report-event-flow). `END-OF-SELECTION` is obsolete; it was meant for programs linked to a logical database. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference).

The ABAP Keyword Documentation does not classify classic lists as obsolete, but it no longer intends them for direct use in production programs and points to ALV instead ([13-ALV](../13-ALV/README.md)).

The chapter also covers the tasks that classical reports typically carry out around the list: starting a report as a background job, and reading or writing files on the user's PC and on the application server.

## 🧾 Classical List Events

| Event | Purpose |
|---|---|
| `TOP-OF-PAGE` | Triggered when a new page of the basic list starts, before its first line is output |
| `END-OF-PAGE` | Triggered when the footer lines reserved with `REPORT ... LINE-COUNT n(m)` are reached; without reserved lines its output has no effect |
| `AT LINE-SELECTION` | Triggered when the user chooses a list line with a double-click or `F2` (function code `PICK`) |
| `TOP-OF-PAGE DURING LINE-SELECTION` | Header for a secondary (detail) list |

> 📝 **Contextual snippet** — part of an executable program; the text symbols `001` and `002` hold the list texts ([Rule 4.2](../docs/ABAP-Development-Rules.md#42-keep-user-facing-text-out-of-literals)).

```abap
TOP-OF-PAGE.
  WRITE: / TEXT-001, 40 sy-datum, 60 sy-uzeit.
  ULINE.

START-OF-SELECTION.
  " Strict ABAP SQL: INTO follows the other clauses, and UP TO n ROWS follows INTO
  SELECT matnr, mtart, ersda
    FROM mara
    INTO TABLE @DATA(materials)
    UP TO 50 ROWS.

  LOOP AT materials INTO DATA(material).
    WRITE: / material-matnr, material-mtart, material-ersda.
  ENDLOOP.

AT LINE-SELECTION.
  " Triggered on double-click; sy-lisel / GET CURSOR can retrieve the selected line.
  WRITE: / TEXT-002.
```

> ⚠️ **`UP TO n ROWS` goes after `INTO`.** When `INTO` is the last clause, the ABAP Keyword Documentation requires `UP TO`, `OFFSET` and the other ABAP-specific additions after it — [Rule 7.1](../docs/ABAP-Development-Rules.md#71-write-strict-abap-sql-a-comma-separated-field-list--host-variables-into-after-the-query-clauses).

## 🖨️ Dynamic Reports — Building Tables and Field Catalogs at Runtime

Sometimes the structure of the data to display isn't known at design time (e.g., a generic "show any table" utility report). ABAP allows creating an internal table dynamically from a field catalog:

> 📝 **Contextual snippet** — `zsm_msg` is the placeholder message class.

```abap
" Definition
PARAMETERS p_table TYPE dd02l-tabname.

DATA field_catalog TYPE lvc_t_fcat.
DATA table_ref     TYPE REF TO data.
DATA line_ref      TYPE REF TO data.

FIELD-SYMBOLS <rows> TYPE STANDARD TABLE.
FIELD-SYMBOLS <row>  TYPE any.

START-OF-SELECTION.

  " ------------------------------------------------------------------
  " 1. Validate that the requested object actually exists in the DDIC;
  "    the name becomes a dynamic token (Rule 8.4)
  " ------------------------------------------------------------------
  SELECT SINGLE @abap_true AS exists_flag
    FROM dd02l
    WHERE tabname  = @p_table
      AND as4local = 'A'
    INTO @DATA(table_exists).

  IF sy-subrc <> 0.
    MESSAGE e050(zsm_msg) WITH p_table.
  ENDIF.

  " ------------------------------------------------------------------
  " 2. Authorization check - MANDATORY for generic table access.
  "    VIEW_AUTHORITY_CHECK is the standard generic table/view
  "    authorization check used by SAP's own table maintenance.
  "    view_action 'S' = display.
  " ------------------------------------------------------------------
  CALL FUNCTION 'VIEW_AUTHORITY_CHECK'
    EXPORTING  view_action                    = 'S'
               view_name                      = p_table
    EXCEPTIONS invalid_action                 = 1
               no_authority                   = 2
               no_clientindependent_authority = 3
               table_not_found                = 4
               no_linedependent_authority     = 5
               OTHERS                         = 6.

  IF sy-subrc <> 0.
    MESSAGE e051(zsm_msg) WITH p_table.
  ENDIF.

  " ------------------------------------------------------------------
  " 3. Only now build the field catalog and read the data
  " ------------------------------------------------------------------
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING i_structure_name = p_table
    CHANGING  ct_fieldcat      = field_catalog.

  cl_alv_table_create=>create_dynamic_table(
      EXPORTING  it_fieldcatalog           = field_catalog
      IMPORTING  ep_table                  = table_ref
      EXCEPTIONS generate_subpool_dir_full = 1
                 OTHERS                    = 2 ).

  IF sy-subrc <> 0.
    MESSAGE e052(zsm_msg) WITH p_table.
  ENDIF.

  ASSIGN table_ref->* TO <rows>.

  CREATE DATA line_ref LIKE LINE OF <rows>.
  ASSIGN line_ref->* TO <row>.

  " A generic viewer shows every column, so SELECT * is intended here (Rule 7.7)
  SELECT *
    FROM (p_table)
    INTO TABLE @<rows>
    UP TO 100 ROWS.
```

> ⚠️ **A successful Dictionary lookup proves that the table exists — it proves nothing about whether this user may read it.** A dynamic `SELECT` performs **no** implicit authorization check, so a generic table viewer without one is a complete bypass of SAP's table authorization model: any table the program can name, it can read.
>
> `VIEW_AUTHORITY_CHECK` is the standard function module SAP uses for exactly this purpose (generic table/view access in extended table maintenance). Call it with the display activity before the dynamic `SELECT`, and treat a non-zero `sy-subrc` as a hard stop — never as a warning. **[verify: the full parameter list of `VIEW_AUTHORITY_CHECK` in `SE37` of your release before productive use]**

> 💡 This pattern (dynamic field catalog + `cl_alv_table_create=>create_dynamic_table`) is the classic basis for generic "table viewer" utilities and pairs naturally with [13-ALV](../13-ALV/README.md) to display the result.

> 📝 When the table name is all you have, `CREATE DATA table_ref TYPE STANDARD TABLE OF (p_table).` creates the internal table without a field catalog. To build a type from components at runtime, use RTTS, see [02-Data-Types](../02-Data-Types/README.md#-reading-domain-fixed-values-at-runtime-rtts).

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` — dynamic Dictionary access of this kind is restricted under ABAP Cloud. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## ⏱️ Running a Report as a Background Job

A report that runs for a long time, or that must run without a user session, is started as a background job. Three steps belong together:

1. `JOB_OPEN` creates the job and returns its number.
2. `SUBMIT ... VIA JOB ... NUMBER ...` adds the report as a job step. `VIA JOB` works only together with `AND RETURN`.
3. `JOB_CLOSE` completes the job and can release it for an immediate start.

> 📝 **Contextual snippet** — assumes a structure `document` with company code and fiscal year; `zsm_r_order_overview` and its parameters are the called report from [09-Modularization](../09-Modularization/README.md#-calling-other-programs--submit--screen-chaining). The function module parameters follow the example in the ABAP Keyword Documentation; **[verify: the signatures of `JOB_OPEN` and `JOB_CLOSE` in `SE37` of your release]**.

```abap
DATA job_count TYPE tbtcjob-jobcount.

DATA(job_name) = CONV tbtcjob-jobname( 'ZSM_ORDER_OVERVIEW' ).

CALL FUNCTION 'JOB_OPEN'
  EXPORTING
    jobname          = job_name
  IMPORTING
    jobcount         = job_count
  EXCEPTIONS
    cant_create_job  = 1
    invalid_job_data = 2
    jobname_missing  = 3
    OTHERS           = 4.
IF sy-subrc <> 0.
  MESSAGE e060(zsm_msg) WITH job_name.
ENDIF.

SUBMIT zsm_r_order_overview
       WITH p_bukrs = document-bukrs
       WITH p_gjahr = document-gjahr
       VIA JOB job_name NUMBER job_count
       AND RETURN.
IF sy-subrc <> 0.
  MESSAGE e061(zsm_msg) WITH job_name.
ENDIF.

CALL FUNCTION 'JOB_CLOSE'
  EXPORTING
    jobcount             = job_count
    jobname              = job_name
    strtimmed            = abap_true
  EXCEPTIONS
    cant_start_immediate = 1
    invalid_startdate    = 2
    jobname_missing      = 3
    job_close_failed     = 4
    job_nosteps          = 5
    job_notex            = 6
    lock_failed          = 7
    OTHERS               = 8.
IF sy-subrc <> 0.
  MESSAGE e062(zsm_msg) WITH job_name.
ENDIF.
```

> ⚠️ **`SUBMIT ... USER` runs the job step with another user's authorizations.** According to the ABAP Keyword Documentation, the user name is checked against the authorization object `S_BTCH_NAM`. Use the addition only when the job must run under a technical user, and never as a way around the caller's own authorizations.

> 💡 Monitor the job in transaction `SM37`. The job number from `JOB_OPEN`, not the name, tells two runs of the same job apart.

## 📁 Files on the User's PC (Presentation Server)

The methods of `cl_gui_frontend_services` show the file dialogs and transfer files between the user's PC and the program. They need SAP GUI, so they work only in dialog processing.

> 📝 **Contextual snippet** — part of an executable program; `zsm_s_upload_line` is a placeholder structure whose components match the columns of a tab-separated file, and `zsm_msg` is the placeholder message class. **[verify: the method signatures of `cl_gui_frontend_services` in `SE24` of your release]**

```abap
PARAMETERS p_file TYPE localfile OBLIGATORY.

DATA selected_files TYPE filetable.
DATA selected_count TYPE i.
DATA upload_lines   TYPE STANDARD TABLE OF zsm_s_upload_line WITH EMPTY KEY.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  cl_gui_frontend_services=>file_open_dialog(
    CHANGING   file_table = selected_files
               rc         = selected_count
    EXCEPTIONS OTHERS     = 1 ).
  " Take the file only when exactly one was selected
  IF sy-subrc = 0 AND selected_count = 1.
    p_file = selected_files[ 1 ]-filename.
  ENDIF.

START-OF-SELECTION.
  cl_gui_frontend_services=>gui_upload(
    EXPORTING  filename            = CONV string( p_file )
               filetype            = 'ASC'
               has_field_separator = abap_true
    CHANGING   data_tab            = upload_lines
    EXCEPTIONS OTHERS              = 1 ).
  IF sy-subrc <> 0.
    MESSAGE e070(zsm_msg) WITH p_file.
  ENDIF.
```

Downloading works the same way in reverse: `file_save_dialog` asks for the target path, and `gui_download` writes the table, with `write_field_separator` for tab-separated columns.

> ⚠️ **A background job has no SAP GUI.** `gui_upload` and `gui_download` fail there. Check with the function module `GUI_IS_AVAILABLE` first if the report can also run in the background, or use a file on the application server (next section).

> 📝 **Excel files.** A tab-separated text file, which Excel can save directly, is the most robust upload format. Function modules such as `ALSM_EXCEL_TO_INTERNAL_TABLE` and `TEXT_CONVERT_XLS_TO_SAP` work through the desktop installation of Excel **[verify]** and share the limits of OLE automation described in [10-Objects](../10-Objects/README.md#-legacy--interop-objects-ole-odata-model). For `.xlsx` content, use an API that is available and released in your system **[verify]**.

> 📝 Older programs use function modules such as `WS_FILENAME_GET`, `WS_UPLOAD`, `WS_DOWNLOAD` or `UPLOAD` for the same steps. New code uses `cl_gui_frontend_services`.

## 🗄️ Writing a File on the Application Server

Files on the application server are written with `OPEN DATASET`, `TRANSFER` and `CLOSE DATASET`. They are available to background jobs and to interfaces that pick files up from a directory; transaction `AL11` lists the directories and their files.

> 📝 **Contextual snippet** — assumes a table `orders` with the components `order_id` and `status`, and a `file_path` resolved from a logical file name ([Rule 8.7](../docs/ABAP-Development-Rules.md#87-resolve-and-validate-file-paths-through-logical-file-names)); `zsm_msg` is the placeholder message class.

```abap
DATA os_message TYPE string.

OPEN DATASET file_path FOR OUTPUT IN TEXT MODE ENCODING UTF-8
     MESSAGE os_message.
IF sy-subrc <> 0.
  MESSAGE e080(zsm_msg) WITH os_message.
ENDIF.

LOOP AT orders INTO DATA(order).
  DATA(file_line) = |{ order-order_id }\t{ order-status }|.
  TRANSFER file_line TO file_path.
ENDLOOP.

CLOSE DATASET file_path.
```

> ⚠️ **Stop when `OPEN DATASET` fails.** `sy-subrc` 8 means the operating system could not open the file, and the `MESSAGE` addition returns its reason. Writing on as if the file were open is a classic source of lost interface files.

> 📝 `OPEN DATASET` checks the authorization object `S_DATASET` itself and raises the catchable exception `CX_SY_FILE_AUTHORITY` when the user lacks it. Call the function module `AUTHORITY_CHECK_DATASET` beforehand to answer with a clear message instead.

> 💡 Write `ENCODING UTF-8` explicitly. The documentation treats `DEFAULT` as the same thing, but the explicit form tells the reader which encoding the receiving system has to expect.

## ✅ Best Practices

- Use classical `WRITE`-based reports only for simple, short-lived tools — prefer ALV ([13-ALV](../13-ALV/README.md)) for anything user-facing or long-term.
- Keep `TOP-OF-PAGE` logic lightweight; avoid database access there since it runs once per page, not once per report.
- Keep list texts in text symbols and messages in a message class — [Rule 4.2](../docs/ABAP-Development-Rules.md#42-keep-user-facing-text-out-of-literals).
- When building dynamic tables, always check `sy-subrc` after `cl_alv_table_create=>create_dynamic_table` before using the resulting field symbol.
- **Always authorization-check generic table access** with `VIEW_AUTHORITY_CHECK` before a dynamic `SELECT`, in addition to validating the name — [Rule 8.4](../docs/ABAP-Development-Rules.md#84-build-dynamic-sql-and-other-dynamic-tokens-only-from-validated-input).
- Start background work with `JOB_OPEN`, `SUBMIT ... VIA JOB ... AND RETURN` and `JOB_CLOSE`, and check `sy-subrc` after each step.
- Take application server paths from logical file names, never from user input or a literal — [Rule 8.7](../docs/ABAP-Development-Rules.md#87-resolve-and-validate-file-paths-through-logical-file-names).
- Use `cl_gui_frontend_services` for files on the user's PC, and only in dialog processing.

## ⚠️ Common Mistakes

- Forgetting `ULINE`/spacing conventions, making classical list output hard to read.
- Writing `UP TO n ROWS` before an `INTO` that ends the statement — the documentation requires it after `INTO`.
- Expecting `END-OF-PAGE` output without reserving footer lines with `LINE-COUNT`.
- Using dynamic tables / dynamic `SELECT (table)` with unvalidated user input — validate the name against the Dictionary first.
- **Validating existence and calling it security.** Existence and authorization are two different checks; a generic reader needs both.
- Calling `gui_upload` or `gui_download` in a report that also runs as a background job.
- Hard-coding a server path, or carrying on after `OPEN DATASET` returned a non-zero `sy-subrc`.

## 🎤 Interview & Review Checkpoints

- Explain the difference between a classical list (`WRITE`) and ALV, and when each is appropriate.
- Be ready to explain how to dynamically create an internal table at runtime and why this is useful for generic tools.
- Explain why a dynamic `SELECT` needs an explicit authorization check, and which check you would use.
- Explain how a program starts another report as a background job, and why `VIA JOB` needs `AND RETURN`.
- Explain the difference between presentation server and application server files, and which of them a background job can use.

## 🔗 Related Chapters

- [01-ABAP-Basics](../01-ABAP-Basics/README.md) — the report event flow
- [08-Open-SQL](../08-Open-SQL/README.md#-dynamic-sql) — dynamic SQL risks
- [09-Modularization](../09-Modularization/README.md) — `SUBMIT` with parameters
- [10-Objects](../10-Objects/README.md) — OLE automation and its limits
- [12-Selection-Screens](../12-Selection-Screens/README.md) — parameters and value help
- [13-ALV](../13-ALV/README.md) — the recommended list output
- [14-Function-Modules](../14-Function-Modules/README.md) — batch input for uploaded data
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle of list processing and `END-OF-SELECTION`
