# 11 — Classical Reports

## 📖 Introduction

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
  SELECT * FROM mara INTO TABLE @DATA(lt_mara) UP TO 50 ROWS.

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
DATA(gt_fieldcat) = VALUE lvc_t_fcat( ).

" Generate a field catalog dynamically from a DDIC table/structure name
CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
  EXPORTING i_structure_name = p_table
  CHANGING  ct_fieldcat      = gt_fieldcat.

" Generate a dynamic internal table matching that field catalog
FIELD-SYMBOLS <fs_table> TYPE STANDARD TABLE.
FIELD-SYMBOLS <fs_line>  TYPE any.

DATA(gt_table) = REF #( ).
DATA(gt_line)  = REF #( ).

cl_alv_table_create=>create_dynamic_table( EXPORTING  it_fieldcatalog           = gt_fieldcat
                                           IMPORTING  ep_table                  = gt_table
                                           EXCEPTIONS generate_subpool_dir_full = 1
                                                      OTHERS                    = 2 ).

CHECK sy-subrc = 0.
ASSIGN gt_table->* TO <fs_table>.

CREATE DATA gt_line LIKE LINE OF <fs_table>.
ASSIGN gt_line->* TO <fs_line>.

" The dynamically created table can now be filled, e.g., via a dynamic SELECT
SELECT *
  FROM (p_table)
  INTO TABLE <fs_table>
  UP TO 100 ROWS.
```

> 💡 This pattern (dynamic field catalog + `cl_alv_table_create=>create_dynamic_table`) is the classic basis for generic "table viewer" utilities and pairs naturally with [13-ALV](../13-ALV/README.md) to display the result.

## ✅ Best Practices

- Use classical `WRITE`-based reports only for simple, short-lived tools — prefer ALV ([13-ALV](../13-ALV/README.md)) for anything user-facing or long-term.
- Keep `TOP-OF-PAGE` logic lightweight; avoid database access there since it runs once per page, not once per report.
- When building dynamic tables, always check `sy-subrc` after `cl_alv_table_create=>create_dynamic_table` before using the resulting field symbol.

## ⚠️ Common Mistakes

- Forgetting `ULINE`/spacing conventions, making classical list output hard to read.
- Using dynamic tables/dynamic `SELECT (table)` with unvalidated user input — validate the table name against the data dictionary (e.g., `SELECT FROM dd02l`) before using it dynamically.

## 🎤 Interview Tips

- Explain the difference between a classical list (`WRITE`) and ALV, and when each is appropriate.
- Be ready to explain how to dynamically create an internal table at runtime and why this is useful for generic tools.

## 🔗 Related Chapters

- [01-ABAP-Basics](../01-ABAP-Basics/README.md)
- [12-Selection-Screens](../12-Selection-Screens/README.md)
- [13-ALV](../13-ALV/README.md)
