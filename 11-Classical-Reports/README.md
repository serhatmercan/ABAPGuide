# 11 — Classical Reports

## 📖 Introduction

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. `WRITE`-based list processing remains widespread for background jobs, spool output and quick internal tools, and the report event model underpins every classical program you will maintain. It is **not** part of the ABAP Cloud development model — see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

A **classical report** (list processing) uses `WRITE` statements and system-defined list events (`TOP-OF-PAGE`, `END-OF-PAGE`) instead of a GUI container like ALV Grid. While most new development uses ALV or Fiori/UI5, classical reports are still common for quick internal tools, background jobs, and simple audits — and the underlying **event model** (`INITIALIZATION` → `START-OF-SELECTION` → `END-OF-SELECTION`) is foundational knowledge covered in [01-ABAP-Basics](../01-ABAP-Basics/README.md).

## 🧾 Classical List Events

| Event | Purpose |
|---|---|
| `TOP-OF-PAGE` | Triggered automatically at the top of each new page of a classical list |
| `END-OF-PAGE` | Triggered at the bottom of each page (e.g., for page footers) |
| `AT LINE-SELECTION` | Triggered when the user double-clicks a line in the list (basic list interactivity) |
| `TOP-OF-PAGE DURING LINE-SELECTION` | Header for a secondary (detail) list |

```abap
TOP-OF-PAGE.
  WRITE: / 'My Classical Report', 40 sy-datum, 60 sy-uzeit.
  ULINE.

START-OF-SELECTION.
  " Strict ABAP SQL: UP TO n ROWS comes before INTO, and INTO comes last
  SELECT matnr, mtart, ersda
    FROM mara
    UP TO 50 ROWS
    INTO TABLE @DATA(lt_mara).

  LOOP AT lt_mara INTO DATA(ls_mara).
    WRITE: / ls_mara-matnr, ls_mara-mtart, ls_mara-ersda.
  ENDLOOP.

AT LINE-SELECTION.
  " Triggered on double-click; sy-lisel / GET CURSOR can retrieve the selected line.
  WRITE: / 'You selected a row.'.
```

## 🖨️ Dynamic Reports — Building Tables and Field Catalogs at Runtime

Sometimes the structure of the data to display isn't known at design time (e.g., a generic "show any table" utility report). ABAP allows creating an internal table dynamically from a field catalog:

```abap
" Definition
PARAMETERS p_table TYPE dd02l-tabname.

DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gr_table    TYPE REF TO data.
DATA gr_line     TYPE REF TO data.

FIELD-SYMBOLS <fs_table> TYPE STANDARD TABLE.
FIELD-SYMBOLS <fs_line>  TYPE any.

START-OF-SELECTION.

  " ------------------------------------------------------------------
  " 1. Validate that the requested object actually exists in the DDIC
  " ------------------------------------------------------------------
  SELECT SINGLE @abap_true AS exists_flag
    FROM dd02l
    WHERE tabname  = @p_table
      AND as4local = 'A'
    INTO @DATA(lv_exists).

  IF sy-subrc <> 0.
    MESSAGE 'Table or view does not exist' TYPE 'E'.
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
    MESSAGE 'You are not authorized to display this table' TYPE 'E'.
  ENDIF.

  " ------------------------------------------------------------------
  " 3. Only now build the field catalog and read the data
  " ------------------------------------------------------------------
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING i_structure_name = p_table
    CHANGING  ct_fieldcat      = gt_fieldcat.

  cl_alv_table_create=>create_dynamic_table(
      EXPORTING  it_fieldcatalog           = gt_fieldcat
      IMPORTING  ep_table                  = gr_table
      EXCEPTIONS generate_subpool_dir_full = 1
                 OTHERS                    = 2 ).

  IF sy-subrc <> 0.
    MESSAGE 'Could not create the dynamic table' TYPE 'E'.
  ENDIF.

  ASSIGN gr_table->* TO <fs_table>.

  CREATE DATA gr_line LIKE LINE OF <fs_table>.
  ASSIGN gr_line->* TO <fs_line>.

  SELECT *
    FROM (p_table)
    UP TO 100 ROWS
    INTO TABLE <fs_table>.
```

> ⚠️ **A successful Dictionary lookup proves that the table exists — it proves nothing about whether this user may read it.** A dynamic `SELECT` performs **no** implicit authorization check, so a generic table viewer without one is a complete bypass of SAP's table authorization model: any table the program can name, it can read.
>
> `VIEW_AUTHORITY_CHECK` is the standard function module SAP uses for exactly this purpose (generic table/view access in extended table maintenance). Call it with the display activity before the dynamic `SELECT`, and treat a non-zero `sy-subrc` as a hard stop — never as a warning. **NEEDS OFFICIAL VERIFICATION** of the full parameter list against `SE37` in your target release before productive use.

> 💡 This pattern (dynamic field catalog + `cl_alv_table_create=>create_dynamic_table`) is the classic basis for generic "table viewer" utilities and pairs naturally with [13-ALV](../13-ALV/README.md) to display the result.
>
> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` — dynamic Dictionary access of this kind is restricted under ABAP Cloud. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## ✅ Best Practices

- Use classical `WRITE`-based reports only for simple, short-lived tools — prefer ALV ([13-ALV](../13-ALV/README.md)) for anything user-facing or long-term.
- Keep `TOP-OF-PAGE` logic lightweight; avoid database access there since it runs once per page, not once per report.
- When building dynamic tables, always check `sy-subrc` after `cl_alv_table_create=>create_dynamic_table` before using the resulting field symbol.
- **Always authorization-check generic table access** with `VIEW_AUTHORITY_CHECK` before a dynamic `SELECT`, in addition to validating the name.

## ⚠️ Common Mistakes

- Forgetting `ULINE`/spacing conventions, making classical list output hard to read.
- Using dynamic tables / dynamic `SELECT (table)` with unvalidated user input — validate the name against the Dictionary first.
- **Validating existence and calling it security.** Existence and authorization are two different checks; a generic reader needs both.

## 🎤 Interview & Review Checkpoints

- Explain the difference between a classical list (`WRITE`) and ALV, and when each is appropriate.
- Be ready to explain how to dynamically create an internal table at runtime and why this is useful for generic tools.
- Explain why a dynamic `SELECT` needs an explicit authorization check, and which check you would use.

## 🔗 Related Chapters

- [01-ABAP-Basics](../01-ABAP-Basics/README.md)
- [08-Open-SQL](../08-Open-SQL/README.md#-dynamic-sql) — dynamic SQL risks
- [12-Selection-Screens](../12-Selection-Screens/README.md)
- [13-ALV](../13-ALV/README.md)
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md)
