# 09 — Modularization

## 📖 Introduction

Modularization means splitting logic into reusable, testable units. ABAP offers several mechanisms: **function modules** (RFC-callable, package-based), **`FORM`/`PERFORM`** (classical subroutines, see [03-Variables](../03-Variables/README.md#-form--perform-classical-subroutines)), **macros** (`DEFINE`/`END-OF-DEFINITION`, textual/preprocessor-like), and — the modern, recommended approach — **classes and methods** (see [10-Objects](../10-Objects/README.md)).

## 🧩 Calling a Function Module

```abap
CALL FUNCTION cl_cam_address_bcs=>create_internet_addres
  EXPORTING i_address_string = CONV #( gv_sender_email )
            iv_statu         = ls_entity-util+8(2)
            iv_task_code     = CONV mncod( ls_entity-util+10(4) )
  RECEIVING result           = gr_sender.
```

### 🔁 Conversion Exits

Conversion exits (function modules named `CONVERSION_EXIT_<NAME>_INPUT/OUTPUT`) convert between the internal storage format and the human-readable display format of special data elements (material numbers, dates, WBS elements, units, etc.).

```abap
" Convert Date To String
DATA lv_tarih  TYPE datum.
DATA lv_string TYPE string.

CALL FUNCTION 'CONVERSION_EXIT_PDATE_OUTPUT'
  EXPORTING input  = lv_tarih
  IMPORTING output = lv_string.

" Convert Material Number (INPUT = display -> internal, OUTPUT = internal -> display)
CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
  EXPORTING  input        = ls_data-material
  IMPORTING  output       = ls_data-material
  EXCEPTIONS length_error = 1
             OTHERS       = 2.

CALL FUNCTION 'CONVERSION_EXIT_MATN1_OUTPUT'
  EXPORTING  input        = ls_data-material
  IMPORTING  output       = ls_data-material
  EXCEPTIONS length_error = 1
             OTHERS       = 2.

" Convert internal characteristic to characteristic name (ATINN -> ATNAM)
CALL FUNCTION 'CONVERSION_EXIT_ATINN_OUTPUT'
  EXPORTING input  = <measurement_document>-internal_characteristic
  IMPORTING output = <measurement_document>-internal_characteristic_text.

" Convert unit of measure to its display text
CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
  EXPORTING input    = ls_data-meins
            language = sy-langu
  IMPORTING output   = ls_data-meins.

" WBS element: internal (P4.24CV.02.001.40.MUH) <-> display (00001223)
DATA lv_posid LIKE prps-posid.

CALL FUNCTION 'CONVERSION_EXIT_ABPSP_INPUT'
  EXPORTING  input     = lv_posid
  IMPORTING  output    = lv_posid
  EXCEPTIONS not_found = 1
             OTHERS    = 2.

CALL FUNCTION 'CONVERSION_EXIT_ABPSP_OUTPUT'
  EXPORTING input  = lv_posid
  IMPORTING output = lv_posid.

" Generic ALPHA conversion exit (used for most numeric keys, e.g. document numbers)
CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
  EXPORTING input  = ls_data-data
  IMPORTING output = ls_data-data.
```

> 💡 **Modern alternative:** for the `ALPHA` conversion exit specifically, the string template operator `|{ value ALPHA = IN }|` / `|{ value ALPHA = OUT }|` (see [02-Data-Types](../02-Data-Types/README.md#-type-conversions)) achieves the same result without a function module call.

### 📐 Unit Conversions

```abap
DATA lv_amount       TYPE kwmeng.
DATA lv_gross_weight TYPE brgew_ap.
DATA lv_material     TYPE matnr.
DATA lv_net_weight   TYPE ntgew_ap.
DATA lv_unit_m3      TYPE meins    VALUE 'M3'.
DATA lv_unit_toa     TYPE meins    VALUE 'TOA'.

lv_gross_weight = lv_amount * 1000. " L

CALL FUNCTION 'MATERIAL_UNIT_CONVERSION'
  EXPORTING  input                = lv_gross_weight
             kzmeinh              = abap_true
             matnr                = lv_material
             meinh                = lv_unit_m3
             meins                = 'KG'
  IMPORTING  output               = lv_net_weight
  EXCEPTIONS conversion_not_found = 1
             input_invalid        = 2
             material_not_found   = 3
             meinh_not_found      = 4
             meins_missing        = 5
             no_meinh             = 6
             output_invalid       = 7
             overflow             = 8
             OTHERS               = 9.

CHECK sy-subrc <> 0.

MESSAGE ID sy-msgid
        TYPE sy-msgty
        NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

" Generic material unit conversion (any unit -> any unit for a given material)
CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
  EXPORTING  i_matnr              = p_matnr
             i_in_me              = p_meins
             i_out_me             = 'PAL'
             i_menge              = p_menge
  IMPORTING  e_menge              = lv_menge
  EXCEPTIONS error_in_application = 1
             error                = 2
             OTHERS               = 3.
```

### 🧰 Other Useful Standard Function Modules

```abap
" Extract a file extension from a MIME type (application/pdf -> pdf)
DATA lv_extension TYPE c LENGTH 1.
DATA lv_mime_type TYPE w3conttype.

CALL FUNCTION 'SDOK_FILE_NAME_EXTENSION_GET'
  EXPORTING mimetype  = lv_mime_type
  IMPORTING extension = lv_extension.

" Validate/convert a time value
CALL FUNCTION 'CONVERT_TIME_INPUT'
  EXPORTING  input                     = ls_data-value
             plausibility_check        = 'X'
  IMPORTING  output                    = ls_data-value
  EXCEPTIONS plausibility_check_failed = 1
             wrong_format_in_input     = 2
             OTHERS                    = 3.

" Get the last date of a given month (YYYYMM -> DD.MM.YYYY)
DATA lv_last_date_of_month TYPE sy-datum.
DATA lv_year_month         TYPE jva_prod_month.

CALL FUNCTION 'JVA_LAST_DATE_OF_MONTH'
  EXPORTING year_month         = lv_year_month
  IMPORTING last_date_of_month = lv_last_date_of_month.

" Get personnel number from user ID (HR)
DATA lv_personel_no TYPE persno.

CALL FUNCTION 'RP_GET_PERNR_FROM_USERID'
  EXPORTING  begda     = sy-datum
             endda     = sy-datum
             usrid     = sy-uname
             usrty     = '0001'
  IMPORTING  usr_pernr = lv_personel_no
  EXCEPTIONS retcd     = 1
             OTHERS    = 2.

" Get user address and lock status
DATA ls_address   TYPE bapiaddr3.
DATA ls_is_locked TYPE bapislockd.
DATA lt_return    TYPE TABLE OF bapiret2.
DATA lv_locked    TYPE xfeld.
DATA lv_username  TYPE bapibname-bapibname.

CALL FUNCTION 'BAPI_USER_GET_DETAIL'
  EXPORTING username = lv_username
  IMPORTING address  = ls_address
            islocked = ls_is_locked
  TABLES    return   = lt_return.

IF NOT line_exists( lt_return[ type = 'E' ] ).
  IF ls_is_locked-glob_lock = 'L' OR ls_is_locked-local_lock = 'L' OR ls_is_locked-no_user_pw = 'L' OR ls_is_locked-wrng_logon = 'L'.
    lv_locked = abap_true.
  ENDIF.
ENDIF.

" Progress indicator for long-running batch jobs
CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
  EXPORTING percentage = 10
            text       = '1 / 10 Equipment master data is reading.'.
```

### 📡 Calling a Function Module via RFC Destination

```abap
CONSTANTS lc_rfc_name TYPE tfdir-funcname VALUE 'ZSM_F_TEST'.
DATA lv_destination TYPE rfcdest.

CALL FUNCTION lc_rfc_name DESTINATION lv_destination
  EXPORTING iv_uname    = lv_uname
  IMPORTING ev_is_admin = lv_admin.
```

## 🧵 Macros (`DEFINE` / `END-OF-DEFINITION`)

Macros perform a **textual substitution** at compile time — no type checking of parameters, so they should be used sparingly in modern code (prefer methods).

```abap
" Simple macro
DEFINE printer.
  WRITE :/ 'Hello', &1, &2.
END-OF-DEFINITION.

WRITE / 'Before Using Macro'.
printer 'ABAP' 'Macros'.

" Macro used to fill a BAPI structure + its "X" (changed-flag) companion structure together
DATA ls_header_in  LIKE bapisdhd1.  " SD Document Header
DATA ls_header_inx LIKE bapisdhd1x. " SD Document Header Checkbox

DEFINE gx.
  &1-&2 = &3.
  &1x-&2 = abap_true.
END-OF-DEFINITION.

gx ls_header_in doc_type  'ZI00'.
gx ls_header_in sales_org '1200'.

WRITE: ls_header_in-doc_type, ls_header_inx-doc_type.

" Macro that both replaces a character and condenses the result
DEFINE conv_char.
  REPLACE ALL OCCURRENCES OF &1 IN &2 WITH &3.
  CONDENSE &2.
END-OF-DEFINITION.

conv_char 'Ş' <fs_data>-value 'S'.
```

## 📞 Calling Other Programs — SUBMIT & Screen Chaining

```abap
" Call a report, letting the user see/adjust its selection screen
SUBMIT zsm_r_test VIA SELECTION-SCREEN AND RETURN.

" Call a report, passing selection-screen parameters directly (no screen shown)
SUBMIT zsm_r_test
       AND RETURN
       WITH p_bukrs = ls_data-bukrs
       WITH p_gjahr = ls_data-gjahr
       WITH p_belnr = ls_data-belnr
       WITH rb_fat  = abap_true.

" Call a screen at a specific position on the current window
CALL SCREEN 0200 STARTING AT 50 10.

" Read another program's global internal table by name (advanced / debugging technique)
ASSIGN ('(SAPMV54A)XVBUV[]') TO FIELD-SYMBOL(<fs_xvbuv>).

IF <fs_xvbuv> IS ASSIGNED.
  DATA(lt_xvbuv) = <fs_xvbuv>.
ENDIF.
```
> ⚠️ Reading another program's globals via `ASSIGN ('(PROGRAM)FIELD')` is a powerful but fragile technique (tightly coupled to SAP-internal program structures, can break with support packages). Use it only when there is no supported API alternative, and document it clearly.

## 📊 Modularization Techniques Compared

| Technique | Reusable Across Programs? | Type-Checked? | RFC-Callable? | Recommended For |
|---|---|---|---|---|
| `FORM`/`PERFORM` | ❌ No (same program only) | ✅ Yes | ❌ No | Legacy code, quick local subroutines |
| Macro (`DEFINE`) | ❌ No (same program only) | ❌ No | ❌ No | Repetitive boilerplate within one program (use sparingly) |
| Function Module | ✅ Yes (function group) | ✅ Yes | ✅ Yes (if RFC-enabled) | Cross-program/cross-system reusable logic, BAPIs |
| Class/Method | ✅ Yes (if global class) | ✅ Yes | ✅ Yes (via RFC-enabled methods, S/4HANA) | All new development (modern, testable, OOP) |

## ✅ Best Practices

- Prefer **methods on classes** for new development; use function modules mainly when RFC-callability or compatibility with older APIs (BAPIs) is required.
- Avoid macros for anything beyond trivial, local repetitive code — they bypass type checking and are hard to debug.
- Always check `sy-subrc`/handle `EXCEPTIONS` after `CALL FUNCTION`.
- Use `SUBMIT ... AND RETURN` (not a plain `SUBMIT`) when you need control to come back to your program.

## ⚠️ Common Mistakes

- Forgetting the `OTHERS = n` catch-all exception in a `CALL FUNCTION ... EXCEPTIONS` list.
- Using a macro where a method would be clearer and safer — macros have no parameter type checking and are a common source of hard-to-find bugs.
- Not handling the `ALPHA`/conversion-exit direction correctly (`INPUT` vs. `OUTPUT`), leading to double-converted or wrongly-padded keys.

## 🎤 Interview Tips

- Explain the difference between a function module and a BAPI (a BAPI is a function module that is part of the official Business Object API, RFC-enabled, and follows strict naming/interface conventions).
- Be ready to explain why macros are discouraged in modern ABAP (Clean ABAP guidelines).
- Explain what a conversion exit is and give an example (`ALPHA`, `MATN1`).

## 🔗 Related Chapters

- [10-Objects](../10-Objects/README.md)
- [14-Function-Modules](../14-Function-Modules/README.md)
- [15-BAPIs](../15-BAPIs/README.md)
