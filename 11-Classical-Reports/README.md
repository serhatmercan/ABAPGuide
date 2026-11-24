# 11 — Classical Reports

## 📖 Introduction

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. `WRITE`-based list processing remains widespread for background jobs, spool output and quick internal tools, and the report event model underpins every classical program you will maintain. It is **not** part of the ABAP Cloud development model — see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

A **classical report** (list processing) uses `WRITE` statements and system-defined list events (`TOP-OF-PAGE`, `END-OF-PAGE`) instead of a GUI container like ALV Grid. While most new development uses ALV or Fiori/UI5, classical reports are still common for quick internal tools, background jobs, and simple audits — and the underlying **event model** (`INITIALIZATION` → `AT SELECTION-SCREEN` → `START-OF-SELECTION`) is foundational knowledge covered in [01-ABAP-Basics](../01-ABAP-Basics/README.md#-classical-report-event-flow). `END-OF-SELECTION` is obsolete; it was meant for programs linked to a logical database. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference).

The ABAP Keyword Documentation does not classify classic lists as obsolete, but it no longer intends them for direct use in production programs and points to ALV instead ([13-ALV](../13-ALV/README.md)).

The chapter also covers the tasks that classical reports typically carry out around the list: starting a report as a background job, its cloud counterpart the application job, and reading or writing files on the user's PC and on the application server.

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
> `VIEW_AUTHORITY_CHECK` is the standard function module SAP uses for exactly this purpose (generic table/view access in extended table maintenance). Call it with the display activity before the dynamic `SELECT`, and treat a non-zero `sy-subrc` as a hard stop — never as a warning. Pass the activity explicitly: the parameter `view_action` defaults to `'U'`, not to display.

> 💡 This pattern (dynamic field catalog + `cl_alv_table_create=>create_dynamic_table`) is the classic basis for generic "table viewer" utilities and pairs naturally with [13-ALV](../13-ALV/README.md) to display the result.

> 📝 When the table name is all you have, `CREATE DATA table_ref TYPE STANDARD TABLE OF (p_table).` creates the internal table without a field catalog. To build a type from components at runtime, use RTTS, see [02-Data-Types](../02-Data-Types/README.md#-reading-domain-fixed-values-at-runtime-rtts).

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` — dynamic Dictionary access of this kind is restricted under ABAP Cloud. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## ⏱️ Running a Report as a Background Job

A report that runs for a long time, or that must run without a user session, is started as a background job. Three steps belong together:

1. `JOB_OPEN` creates the job and returns its number.
2. `SUBMIT ... VIA JOB ... NUMBER ...` adds the report as a job step. `VIA JOB` works only together with `AND RETURN`.
3. `JOB_CLOSE` completes the job and can release it for an immediate start.

> 📝 **Contextual snippet** — assumes a structure `document` with company code and fiscal year; `zsm_r_order_overview` and its parameters are the called report from [09-Modularization](../09-Modularization/README.md#-calling-other-programs--submit--screen-chaining). The function module parameters follow the example in the ABAP Keyword Documentation; `OTHERS` also catches the further exceptions of `JOB_CLOSE`, such as `INVALID_TARGET`.

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

### Application Jobs

> **Lifecycle:** `ABAP CLOUD / MODERN CONTEXT`. In ABAP for Cloud Development there is no report to submit, and SAP's release lists contain neither `JOB_OPEN` nor `JOB_CLOSE`. Background work runs as an **application job**: a class, described by a job catalog entry and a job template. SAP's lists for the SAP BTP ABAP environment, for SAP S/4HANA Cloud and for the private edition list the interfaces and the API below as released.

> ⚠️ **VERSION-DEPENDENT: application jobs in Standard ABAP.** The on-premise system used for this chapter has the interfaces `IF_APJ_DT_EXEC_OBJECT` and `IF_APJ_RT_EXEC_OBJECT`, the class `CL_APJ_RT_API`, and catalog entries and templates as object types in ADT; `IF_APJ_RT_RUN` was not found there. Check your release before you rely on them.

An application job has four parts:

| Part | What it holds | Created with |
|---|---|---|
| **Job class** | The logic. It implements `IF_APJ_DT_EXEC_OBJECT` (the parameters) and `IF_APJ_RT_EXEC_OBJECT` (the run) | ADT, as a normal class |
| **Job catalog entry** | Names the class and its parameters; the object type is `SAJC` | ADT **[verify: the ADT wizard for catalog entries]** |
| **Job template** | Default parameter values for one catalog entry; the object type is `SAJT`, and it requires the name of a catalog entry | ADT **[verify: the ADT wizard for templates]** |
| **The job itself** | One scheduled run or a series of runs, based on a template | The Fiori app for application jobs, or the class `CL_APJ_RT_API` **[verify: the name of the app in your system]** |

The two interfaces of the job class, as read in both systems used for this chapter:

| Interface | Method | Contract |
|---|---|---|
| `IF_APJ_DT_EXEC_OBJECT` | `GET_PARAMETERS` | Exports `ET_PARAMETER_DEF`, the parameter list (name of at most 8 characters, kind `P` for a single value or `S` for a range, data type, length, flags such as mandatory or changeable), and `ET_PARAMETER_VAL`, the default values as range lines. The interface's own documentation says that nothing checks the two tables for consistency. |
| `IF_APJ_RT_EXEC_OBJECT` | `EXECUTE` | Imports `IT_PARAMETERS`, the values chosen when the job was scheduled, and may raise `CX_APJ_RT_CONTENT`. |

In the SAP BTP ABAP environment, a third released interface, `IF_APJ_RT_RUN`, has an `EXECUTE` method without parameters; its short text says that it takes the job parameters from attributes of the class **[verify: how parameters are declared for `IF_APJ_RT_RUN`]**.

**Example J1 — a job class.** Target: Standard ABAP and ABAP for Cloud Development.

```abap
"! Application job class: removes stale records older than a retention period.
CLASS zcl_zsm_cleanup_job DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.

    CONSTANTS retention_parameter TYPE c LENGTH 8 VALUE 'P_DAYS'.
    CONSTANTS default_retention_days TYPE i VALUE 30.

    "! Last day that is still kept.
    "! @parameter today          | Date of the run
    "! @parameter retention_days | Number of days to keep
    "! @parameter result         | Records older than this date are stale
    METHODS cutoff_date
      IMPORTING today          TYPE d
                retention_days TYPE i
      RETURNING VALUE(result)  TYPE d.

    "! Retention in days from the job parameters, or the default.
    "! @parameter parameters | Parameter values passed by the job
    "! @parameter result     | Retention in days
    "! @raising cx_sy_conversion_no_number | The value is not a number
    METHODS retention_days
      IMPORTING parameters    TYPE if_apj_rt_exec_object=>tt_templ_val
      RETURNING VALUE(result) TYPE i
      RAISING   cx_sy_conversion_no_number.

  PRIVATE SECTION.
    METHODS remove_stale_records
      IMPORTING cutoff TYPE d.
ENDCLASS.


CLASS zcl_zsm_cleanup_job IMPLEMENTATION.
  METHOD if_apj_dt_exec_object~get_parameters.
    " The catalog entry and the template read the parameter list from here;
    " a title in param_text would belong in a text symbol (Rule 4.2)
    et_parameter_def = VALUE #( ( selname        = retention_parameter
                                  kind           = 'P'
                                  datatype       = 'I'
                                  length         = 5
                                  changeable_ind = abap_true
                                  mandatory_ind  = abap_true ) ).

    et_parameter_val = VALUE #( ( selname = retention_parameter
                                  kind    = 'P'
                                  sign    = 'I'
                                  option  = 'EQ'
                                  low     = |{ default_retention_days }| ) ).
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.
    TRY.
        DATA(days) = retention_days( it_parameters ).
      CATCH cx_sy_conversion_no_number INTO DATA(conversion_error).
        " Hand the error to the job framework; no work has been done yet
        RAISE EXCEPTION NEW cx_apj_rt_content( previous = conversion_error ).
    ENDTRY.

    remove_stale_records( cutoff_date( today          = cl_abap_context_info=>get_system_date( )
                                       retention_days = days ) ).
  ENDMETHOD.

  METHOD cutoff_date.
    result = today - retention_days.
  ENDMETHOD.

  METHOD retention_days.
    DATA(value) = VALUE #( parameters[ selname = retention_parameter ]-low OPTIONAL ).
    result = COND #( WHEN value IS INITIAL THEN default_retention_days
                     ELSE CONV i( condense( value ) ) ).
  ENDMETHOD.

  METHOD remove_stale_records.
    " Placeholder: delete or archive the custom Z records older than cutoff here
  ENDMETHOD.
ENDCLASS.
```

The logic sits in public methods, so a test needs neither a job nor a template:

```abap
CLASS ltc_cleanup_job DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_zsm_cleanup_job.

    METHODS setup.
    METHODS cutoff_is_today_minus_days FOR TESTING.
    METHODS default_without_parameter FOR TESTING RAISING cx_static_check.
    METHODS days_from_parameter FOR TESTING RAISING cx_static_check.
    METHODS text_is_rejected FOR TESTING.
ENDCLASS.


CLASS ltc_cleanup_job IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD cutoff_is_today_minus_days.
    cl_abap_unit_assert=>assert_equals( act = cut->cutoff_date( today          = '20260315'
                                                                retention_days = 30 )
                                        exp = CONV d( '20260213' ) ).
  ENDMETHOD.

  METHOD default_without_parameter.
    cl_abap_unit_assert=>assert_equals( act = cut->retention_days( VALUE #( ) )
                                        exp = zcl_zsm_cleanup_job=>default_retention_days ).
  ENDMETHOD.

  METHOD days_from_parameter.
    DATA(parameters) = VALUE if_apj_rt_exec_object=>tt_templ_val(
        ( selname = zcl_zsm_cleanup_job=>retention_parameter
          kind    = 'P'
          sign    = 'I'
          option  = 'EQ'
          low     = '90' ) ).

    cl_abap_unit_assert=>assert_equals( act = cut->retention_days( parameters )
                                        exp = 90 ).
  ENDMETHOD.

  METHOD text_is_rejected.
    DATA(parameters) = VALUE if_apj_rt_exec_object=>tt_templ_val(
        ( selname = zcl_zsm_cleanup_job=>retention_parameter
          kind    = 'P'
          sign    = 'I'
          option  = 'EQ'
          low     = 'many' ) ).

    TRY.
        cut->retention_days( parameters ).
        cl_abap_unit_assert=>fail( msg = 'A text value must not pass' ).
      CATCH cx_sy_conversion_no_number.
        " expected
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
```

> 📝 **Activation record.** J1 (`zcl_zsm_cleanup_job` with its test include) was activated in both ABAP language versions: Standard ABAP and ABAP for Cloud Development. Its test run passed in both versions. The active versions were read back and matched the source. No catalog entry and no template was created: the tool used for this guide does not support creating catalog entries, and a template needs one. No job was scheduled or run.

**Scheduling from code.** `CL_APJ_RT_API` schedules, reads and cancels application jobs. Its method `SCHEDULE_JOB` takes the template name, a job text, the start information and, optionally, periodicity, end condition and parameter values that override the template; it returns the job name and job count. `GET_JOB_STATUS` and `CANCEL_JOB` take those two values. Errors arrive as `CX_APJ_RT`.

> 📝 **Contextual snippet** — assumes a job template `ZSM_CLEANUP_TEMPLATE` for a catalog entry of `zcl_zsm_cleanup_job`, the text symbol `001` with the job text ([Rule 4.2](../docs/ABAP-Development-Rules.md#42-keep-user-facing-text-out-of-literals)), and an exception class `zcx_zsm_job_not_scheduled`. The parameter names follow the class definition and its documentation, read in the SAP BTP ABAP environment. Not run.

```abap
DATA job_name  TYPE cl_apj_rt_api=>ty_jobname.
DATA job_count TYPE cl_apj_rt_api=>ty_jobcount.

TRY.
    cl_apj_rt_api=>schedule_job(
      EXPORTING iv_job_template_name = 'ZSM_CLEANUP_TEMPLATE'
                iv_job_text          = TEXT-001
                is_start_info        = VALUE #( start_immediately = abap_true )
      IMPORTING ev_jobname           = job_name
                ev_jobcount          = job_count ).
  CATCH cx_apj_rt INTO DATA(scheduling_error).
    " The caller decides how to report it, for example in the application log
    RAISE EXCEPTION NEW zcx_zsm_job_not_scheduled( previous = scheduling_error ).
ENDTRY.
```

> ⚠️ **The job does not run in the session that schedules it.** According to the interface's own documentation, `EXECUTE` is called in batch with the parameters given at scheduling. It cannot rely on anything the scheduling code holds in memory; everything it needs comes from its parameters or from the database.

How the classic and the cloud way compare:

| Topic | Classic background job | Application job |
|---|---|---|
| Unit of work | A report and its selection screen | A class with the two interfaces |
| Parameters | Selection screen and variant | `GET_PARAMETERS`, catalog entry and template |
| Scheduling | `SM36`, or `JOB_OPEN`, `SUBMIT … VIA JOB`, `JOB_CLOSE` | The Fiori app, or `CL_APJ_RT_API=>SCHEDULE_JOB` |
| Monitoring | `SM37` | The Fiori app **[verify: whether `SM37` shows application jobs on-premise]** |
| Language version | Standard ABAP only | Both |

## 📁 Files on the User's PC (Presentation Server)

The methods of `cl_gui_frontend_services` show the file dialogs and transfer files between the user's PC and the program. They need SAP GUI, so they work only in dialog processing.

> 📝 **Contextual snippet** — part of an executable program; `zsm_s_upload_line` is a placeholder structure whose components match the columns of a tab-separated file, and `zsm_msg` is the placeholder message class.

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

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` for the function modules `GUI_UPLOAD` and `GUI_DOWNLOAD`, which much existing code calls directly. SAP's object classification lists them as classic APIs, like `cl_gui_frontend_services` itself, so neither is the older of the two in SAP's terms. New code uses the class's methods as shown: the file dialogs and the transfer then come from one class. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-classic-but-still-relevant).

> ⚠️ **A background job has no SAP GUI.** `gui_upload` and `gui_download` fail there. Check with the function module `GUI_IS_AVAILABLE` first if the report can also run in the background, or use a file on the application server (next section).

> 📝 **Excel files.** A tab-separated text file, which Excel can save directly, is the most robust upload format. `ALSM_EXCEL_TO_INTERNAL_TABLE` reads the file through OLE automation — its exception `UPLOAD_OLE` reports a failed OLE upload — and shares the limits described in [10-Objects](../10-Objects/README.md#-legacy--interop-objects-ole-odata-model). Check how any other Excel function module reads the file before you rely on it in a report that may run without SAP GUI.

Two further Excel function modules appear in many existing reports. Both were read in the on-premise system used for this chapter:

| Function module | Interface | How it reads the file |
|---|---|---|
| `TEXT_CONVERT_XLS_TO_SAP` | The raw file content (`I_TAB_RAW_DATA`), an optional header-line flag and separator; the result in the generic table `I_TAB_CONVERTED_DATA`; exception `CONVERSION_FAILED` | Through SAP GUI's Office integration (a custom container and an Office control) |
| `UPLOAD_XLS_FILE_2_ITAB` | A file name (`I_FILENAME`); the result in the generic table `E_ITAB`; exception `FILE_ERROR` | Through a custom container as well; its own comment limits it to flat sheets whose columns match the target table |

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` for `TEXT_CONVERT_XLS_TO_SAP`, `UPLOAD_XLS_FILE_2_ITAB` and `ALSM_EXCEL_TO_INTERNAL_TABLE` in existing code. SAP's lists neither release nor classify them, and all three need SAP GUI, so they fail in a background job. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

> **Lifecycle:** `ABAP CLOUD / MODERN CONTEXT` for `.xlsx` content. SAP releases the XCO XLSX API: `XCO_CP_XLSX=>document` returns a document factory with `empty( )` for a new workbook and `for_file_content( iv_file_content )` for an `xstring` that holds an existing one, followed by read and write access interfaces. It works on the file content, not on a file, so it runs without SAP GUI once the content is there. SAP's list for Standard ABAP marks it as released as well, and the on-premise system used for this chapter contained it; `VERSION-DEPENDENT` for your release. **[verify: the read and write calls of the XCO XLSX API in your release]**

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE` for the function modules `WS_FILENAME_GET`, `WS_UPLOAD`, `WS_DOWNLOAD` and `UPLOAD`, older function modules that programs used for the same steps. The methods of `cl_gui_frontend_services` supersede them. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference).

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

### Reading a File

A file is read with `OPEN DATASET … FOR INPUT`, then `READ DATASET` in a loop. According to the ABAP Keyword Documentation, in text mode each `READ DATASET` reads one line, up to the next end-of-line marker, and `sy-subrc` 4 means that a read was attempted after the end of the file. Reading a file that is not open raises a catchable exception (`CX_SY_FILE_OPEN_MODE`).

> 📝 **Contextual snippet** — assumes a `file_path` resolved from a logical file name ([Rule 8.7](../docs/ABAP-Development-Rules.md#87-resolve-and-validate-file-paths-through-logical-file-names)) and a table `file_lines` of strings; `zsm_msg` is the placeholder message class.

```abap
DATA os_message TYPE string.
DATA file_line  TYPE string.

OPEN DATASET file_path FOR INPUT IN TEXT MODE ENCODING UTF-8
     MESSAGE os_message.
IF sy-subrc <> 0.
  MESSAGE e081(zsm_msg) WITH os_message.
ENDIF.

DO.
  READ DATASET file_path INTO file_line.
  " sy-subrc 4: the end of the file was reached
  IF sy-subrc <> 0.
    EXIT.
  ENDIF.
  INSERT file_line INTO TABLE file_lines.
ENDDO.

CLOSE DATASET file_path.
```

### Moving a File Between the Application Server and the PC

Transactions `CG3Y` (download a file) and `CG3Z` (upload a file) copy a file between the application server and the user's PC. They are tools for administrators and support, not part of a program.

In code, two function modules appear for the same task, `ARCHIVFILE_SERVER_TO_CLIENT` and `ARCHIVFILE_CLIENT_TO_SERVER`. Read in the on-premise system used for this chapter, both take the source `PATH` and the `TARGETPATH`, raise `ERROR_FILE` and `NO_AUTHORIZATION`, check the file authorization with `AUTHORITY_CHECK_DATASET`, and validate the server path against the logical file name `ARCHIVLINK_SERVERPATH`, which belongs to ArchiveLink **[verify: whether `CG3Y` and `CG3Z` use these function modules]**.

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` for `ARCHIVFILE_SERVER_TO_CLIENT` and `ARCHIVFILE_CLIENT_TO_SERVER` in existing code. SAP's lists neither release nor classify them, and their path check is tied to an ArchiveLink logical file name, not to the logical file names of your own interface. New code combines the statements and the class of this chapter.

A program that hands a server file to the user reads it in binary mode and downloads the bytes:

> 📝 **Contextual snippet** — dialog processing only; `file_path` is resolved from a logical file name, `target_file` comes from `file_save_dialog`, and `zsm_msg` is the placeholder message class. The function module `GUI_DOWNLOAD` has the parameters `BIN_FILESIZE`, `FILENAME` and `FILETYPE`; the method is assumed to take the same names **[verify: the binary parameters of `cl_gui_frontend_services=>gui_download`, and whether `READ DATASET` fills an `xstring` with the whole file in one read in your release]**.

```abap
DATA os_message   TYPE string.
DATA file_content TYPE xstring.

OPEN DATASET file_path FOR INPUT IN BINARY MODE MESSAGE os_message.
IF sy-subrc <> 0.
  MESSAGE e081(zsm_msg) WITH os_message.
ENDIF.
READ DATASET file_path INTO file_content.
CLOSE DATASET file_path.

" The frontend services transfer binary content as a table of raw lines
DATA(binary_lines) = cl_bcs_convert=>xstring_to_solix( file_content ).

cl_gui_frontend_services=>gui_download(
  EXPORTING  bin_filesize = xstrlen( file_content )
             filename     = target_file
             filetype     = 'BIN'
  CHANGING   data_tab     = binary_lines
  EXCEPTIONS OTHERS       = 1 ).
IF sy-subrc <> 0.
  MESSAGE e082(zsm_msg) WITH target_file.
ENDIF.
```

## ✅ Best Practices

- Use classical `WRITE`-based reports only for simple, short-lived tools — prefer ALV ([13-ALV](../13-ALV/README.md)) for anything user-facing or long-term.
- Keep `TOP-OF-PAGE` logic lightweight; avoid database access there since it runs once per page, not once per report.
- Keep list texts in text symbols and messages in a message class — [Rule 4.2](../docs/ABAP-Development-Rules.md#42-keep-user-facing-text-out-of-literals).
- When building dynamic tables, always check `sy-subrc` after `cl_alv_table_create=>create_dynamic_table` before using the resulting field symbol.
- **Always authorization-check generic table access** with `VIEW_AUTHORITY_CHECK` before a dynamic `SELECT`, in addition to validating the name — [Rule 8.4](../docs/ABAP-Development-Rules.md#84-build-dynamic-sql-and-other-dynamic-tokens-only-from-validated-input).
- Start background work with `JOB_OPEN`, `SUBMIT ... VIA JOB ... AND RETURN` and `JOB_CLOSE`, and check `sy-subrc` after each step.
- In ABAP for Cloud Development, write background work as an application job class, and keep its logic in methods that a unit test can call without a job.
- Take application server paths from logical file names, never from user input or a literal — [Rule 8.7](../docs/ABAP-Development-Rules.md#87-resolve-and-validate-file-paths-through-logical-file-names).
- Use `cl_gui_frontend_services` for files on the user's PC, and only in dialog processing.
- Read server files line by line until `READ DATASET` returns `sy-subrc` 4, and always close the file.
- For `.xlsx` content, prefer the released XCO XLSX API over function modules that need SAP GUI.

## ⚠️ Common Mistakes

- Forgetting `ULINE`/spacing conventions, making classical list output hard to read.
- Writing `UP TO n ROWS` before an `INTO` that ends the statement — the documentation requires it after `INTO`.
- Expecting `END-OF-PAGE` output without reserving footer lines with `LINE-COUNT`.
- Using dynamic tables / dynamic `SELECT (table)` with unvalidated user input — validate the name against the Dictionary first.
- **Validating existence and calling it security.** Existence and authorization are two different checks; a generic reader needs both.
- Calling `gui_upload` or `gui_download` in a report that also runs as a background job.
- Hard-coding a server path, or carrying on after `OPEN DATASET` returned a non-zero `sy-subrc`.
- Reading Excel files with function modules that need SAP GUI in a report that also runs as a background job.
- Using the ArchiveLink transfer modules for an interface's own files, whose paths belong to a logical file name of their own.
- Letting the parameter definition and the default values of a job class drift apart; nothing checks them against each other.

## 🎤 Interview & Review Checkpoints

- Explain the difference between a classical list (`WRITE`) and ALV, and when each is appropriate.
- Be ready to explain how to dynamically create an internal table at runtime and why this is useful for generic tools.
- Explain why a dynamic `SELECT` needs an explicit authorization check, and which check you would use.
- Explain how a program starts another report as a background job, and why `VIA JOB` needs `AND RETURN`.
- Explain the difference between presentation server and application server files, and which of them a background job can use.
- Name the parts of an application job and the two interfaces a job class implements.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SM36 | Define a background job |
| SM37 | Monitor background jobs |
| AL11 | Display application server directories |
| CG3Y | Download a file from the application server to the PC |
| CG3Z | Upload a file from the PC to the application server |

## 🔗 Related Chapters

- [01-ABAP-Basics](../01-ABAP-Basics/README.md) — the report event flow
- [08-Open-SQL](../08-Open-SQL/README.md#-dynamic-sql) — dynamic SQL risks
- [09-Modularization](../09-Modularization/README.md) — `SUBMIT` with parameters
- [10-Objects](../10-Objects/README.md) — OLE automation and its limits
- [12-Selection-Screens](../12-Selection-Screens/README.md) — parameters and value help
- [13-ALV](../13-ALV/README.md) — the recommended list output
- [14-Function-Modules](../14-Function-Modules/README.md) — batch input for uploaded data
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle of list processing, `END-OF-SELECTION`, the older frontend function modules and application jobs
- [22-ABAP-Unit](../22-ABAP-Unit/README.md) — testing a job class without a job
- [24-Mail](../24-Mail/README.md) — sending the result of a background job by mail
- [26-Maintenance-Views](../26-Maintenance-Views/README.md) — authorization groups and the table maintenance that `VIEW_AUTHORITY_CHECK` belongs to
- [28-Adobe-Forms](../28-Adobe-Forms/README.md) — creating the PDF that a report stores as a file
- [34-Authorization-Checks](../34-Authorization-Checks/README.md) — `AUTHORITY-CHECK`, `S_TABU_NAM` and testing the check
