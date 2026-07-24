# 03 — Variables

## 📖 Introduction

This chapter is a reference for the most common variable, constant, and object declarations you will write in almost every ABAP program — from simple scalar variables to class instances, internal tables, and pointers.

## 🧮 Declaring Variables

```abap
" BAPI Return Message
DATA(lt_return) = VALUE bapiret2_t( ).

" Boolean
DATA(rv_result) = xsdbool( sy-subrc = 0 ).
DATA(lv_flag) = VALUE boolean( ).

" Constant
CONSTANTS lc_number LIKE bapi2080_nothdre-notif_no VALUE '%00000000001'.

" Class instance
DATA(lv_surname) = zsm_cl_test=>get_surname( EXPORTING iv_name          = 'SERHAT'
                                             CHANGING  cr_data          = 'X'
                                             IMPORTING et_select_option = DATA(lv_key) ).

" Clear
CLEAR lv_top.

" Classic (explicit type) declarations
DATA lv_character TYPE c LENGTH 120          VALUE 'S'.
DATA lv_decimal   TYPE n LENGTH 10           VALUE 1907.
DATA lv_integer   TYPE i.
DATA lv_integer   TYPE int4                  VALUE 1994.
DATA lv_mimetype  TYPE nte_mimetype          VALUE 'application/pdf'.
DATA lv_number    TYPE p LENGTH 8 DECIMALS 2 VALUE '17.75'.
DATA lv_string    TYPE string                VALUE 'Serhat Mercan'.

DATA(lt_returns) = VALUE bapiret2_tab( ).
DATA(lt_data)    = VALUE zsm_tt_value( ( ls_data ) ).
```

> ⚠️ Note: the second `DATA lv_integer TYPE int4` line above redeclares `lv_integer` and would cause a **duplicate declaration syntax error** in a real program — keep it in mind as a "common mistake" example rather than something to copy as-is.

## 🧵 `FORM` / `PERFORM` (Classical Subroutines)

Even though modern ABAP favors methods (see [09-Modularization](../09-Modularization/README.md)), `FORM`/`PERFORM` with `TABLES`/`USING` parameters is still found in many legacy programs:

```abap
DATA lt_header    LIKE TABLE OF bapi_order_header1    WITH HEADER LINE.
DATA lt_operation LIKE TABLE OF bapi_order_operation1 WITH HEADER LINE.
DATA lt_component LIKE TABLE OF bapi_order_component  WITH HEADER LINE.
DATA lv_data      TYPE int4.

PERFORM get_component TABLES lt_header
                             lt_operation
                             lt_component.
PERFORM use_data USING lv_data.

FORM get_component TABLES lt_header    STRUCTURE bapi_order_header1
                          lt_operation STRUCTURE bapi_order_operation1
                          lt_component STRUCTURE bapi_order_component.
ENDFORM.

FORM use_data USING pv_data.
ENDFORM.
```

## 📞 Calling Function Modules & Includes

```abap
" Function
CALL FUNCTION cl_cam_address_bcs=>create_internet_addres
  EXPORTING i_address_string = CONV #( gv_sender_email )
            iv_statu         = ls_entity-util+8(2)
            iv_task_code     = CONV mncod( ls_entity-util+10(4) )
  RECEIVING result           = gr_sender.

" Field Symbol
LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
ENDLOOP.

" Include
INCLUDE zsm_test_top.
INCLUDE zsm_test_frm.
```

## ✍️ Output & Pointers

```abap
START-OF-SELECTION.
  " Optional value (returns initial value instead of a short dump if not found)
  DATA(lv_key) = VALUE #( lt_data[ name = 'Key' ]-value OPTIONAL ).

  " Output
  WRITE 'Serhat'.
  WRITE / 'Serhat'.
  WRITE: 'Serhat', 'Mercan'.
  WRITE lv_kwmeng TO lv_kwemengx UNIT lv_vrkme.

  " Pointer (data reference)
  DATA(lv_value) = '12345'.
  DATA(lr_ref) = REF #( lv_value ).

  WRITE lr_ref->*.
```

## 📊 Declaration Styles at a Glance

| Style | Example | When to Use |
|---|---|---|
| Explicit `DATA` with `TYPE` | `DATA lv_x TYPE i.` | When the type must be visible/explicit, or declared before first use (top of routine) |
| Inline declaration | `DATA(lv_x) = 5.` | Modern ABAP (7.40+), when the type can be inferred, keeps declarations close to usage |
| `CONSTANTS` | `CONSTANTS lc_x TYPE i VALUE 5.` | Fixed values that never change during runtime |
| `FIELD-SYMBOL(<fs>)` | inline in `ASSIGN`/`LOOP` | Accessing data without copying it (performance) |

## ✅ Best Practices

- Prefer inline declarations (`DATA(...)`) close to first use for readability, but declare variables at the top of the method/form if reused across many statements.
- Use `CONSTANTS` (or better, custom data elements/domains) instead of "magic numbers"/hardcoded literals scattered through the code.
- Use `VALUE #( ... OPTIONAL )` instead of `READ TABLE` + `IF sy-subrc = 0` when you just need a safe default value.

## ⚠️ Common Mistakes

- Declaring the same variable name twice in the same scope (syntax error) — always check existing declarations before adding new ones.
- Using `TABLES` (classical, header-line based) parameters in new code — prefer standard internal tables with explicit work areas.
- Forgetting to `CLEAR` reused work areas between loop iterations when not using `LOOP ... INTO` (which implicitly clears).

## 🎤 Interview Tips

- Explain the difference between `DATA`, `CONSTANTS`, and `FIELD-SYMBOLS`.
- Be ready to discuss why modern ABAP favors inline declarations and `VALUE`/`CORRESPONDING` constructors over `MOVE`/explicit `DATA` + `APPEND`.
- Know what a data reference (`REF #( )`, `TYPE REF TO data`) is and how it differs from an object reference (`TYPE REF TO <class>`).

## 🔗 Related Chapters

- [07-Internal-Tables](../07-Internal-Tables/README.md) — field symbols and data references in depth
- [09-Modularization](../09-Modularization/README.md) — `FORM`/`PERFORM` vs. methods
- [10-Objects](../10-Objects/README.md) — object references
