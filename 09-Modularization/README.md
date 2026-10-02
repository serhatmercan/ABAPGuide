# 09 — Modularization

> **Lifecycle:** `CURRENT / RECOMMENDED` for classes and methods; function modules and RFC are `CLASSIC BUT STILL RELEVANT`; subroutines and macros are `LEGACY / HISTORICAL REFERENCE`. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

Modularization means splitting logic into reusable, testable units. ABAP offers several mechanisms: **function modules** (RFC-callable, package-based), **`FORM`/`PERFORM`** (classical subroutines, see [03-Variables](../03-Variables/README.md#-form--perform-classical-subroutines)), **macros** (`DEFINE`/`END-OF-DEFINITION`, textual/preprocessor-like), and — the modern, recommended approach — **classes and methods** (see [10-Objects](../10-Objects/README.md)).

## 🧩 Calling a Function Module

> 📝 **Contextual snippet** — assumes the variables `external_value` and `internal_value`.

```abap
" A function module is called by NAME. Always handle its exceptions.
CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
  EXPORTING input  = external_value
  IMPORTING output = internal_value.
```

> ⚠️ `CALL FUNCTION` is for **function modules only**. A class method is called as `class=>method( ... )` or `object->method( ... )` — never with `CALL FUNCTION`. See [03-Variables](../03-Variables/README.md#-calling-methods-function-modules--includes) for the method-call forms.

### 🔁 Conversion Exits

Conversion exits (function modules named `CONVERSION_EXIT_<NAME>_INPUT/OUTPUT`) convert between the internal storage format and the human-readable display format of special data elements (material numbers, dates, WBS elements, units, etc.).

> 📝 **Contextual snippet** — assumes a structure `entry` with the components `material`, `meins` and `document_number`, and a field symbol `<measurement_document>`.

```abap
" Convert Date To String
DATA posting_date TYPE datum.
DATA date_text    TYPE string.

CALL FUNCTION 'CONVERSION_EXIT_PDATE_OUTPUT'
  EXPORTING input  = posting_date
  IMPORTING output = date_text.

" Convert Material Number (INPUT = display -> internal, OUTPUT = internal -> display)
CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
  EXPORTING  input        = entry-material
  IMPORTING  output       = entry-material
  EXCEPTIONS length_error = 1
             OTHERS       = 2.

CALL FUNCTION 'CONVERSION_EXIT_MATN1_OUTPUT'
  EXPORTING  input        = entry-material
  IMPORTING  output       = entry-material
  EXCEPTIONS length_error = 1
             OTHERS       = 2.

" Convert internal characteristic to characteristic name (ATINN -> ATNAM)
CALL FUNCTION 'CONVERSION_EXIT_ATINN_OUTPUT'
  EXPORTING input  = <measurement_document>-internal_characteristic
  IMPORTING output = <measurement_document>-internal_characteristic_text.

" Convert unit of measure to its display text
CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
  EXPORTING input    = entry-meins
            language = sy-langu
  IMPORTING output   = entry-meins.

" WBS element. The two formats are:
"   EXTERNAL / display  : the readable coded form, e.g. 'P-1000.01.01' (PRPS-POSID)
"   INTERNAL            : the numeric key, e.g. 00001223              (PRPS-PSPNR)
" INPUT  converts external -> internal
" OUTPUT converts internal -> external
DATA wbs_element TYPE prps-posid.   " external / display format
DATA wbs_key     TYPE prps-pspnr.   " internal numeric key

CALL FUNCTION 'CONVERSION_EXIT_ABPSP_INPUT'
  EXPORTING  input     = wbs_element
  IMPORTING  output    = wbs_key
  EXCEPTIONS not_found = 1
             OTHERS    = 2.

IF sy-subrc <> 0.
  " WBS element not found - handle as a business error
ENDIF.

CALL FUNCTION 'CONVERSION_EXIT_ABPSP_OUTPUT'
  EXPORTING input  = wbs_key
  IMPORTING output = wbs_element.

" Generic ALPHA conversion exit (used for most numeric keys, e.g. document numbers)
CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
  EXPORTING input  = entry-document_number
  IMPORTING output = entry-document_number.
```

> 💡 **Modern alternative:** for the `ALPHA` conversion exit specifically, the string template operator `|{ value ALPHA = IN }|` / `|{ value ALPHA = OUT }|` (see [02-Data-Types](../02-Data-Types/README.md#-type-conversions)) achieves the same result without a function module call.

### 📐 Unit Conversions

> 📝 **Contextual snippet** — assumes the selection-screen fields `p_matnr`, `p_meins` and `p_menge` (selection-screen names keep their short form) and a variable `converted_quantity`.

```abap
DATA material     TYPE matnr.
DATA weight_in_kg TYPE brgew_ap.
DATA volume_in_m3 TYPE ntgew_ap.
DATA unit_kg      TYPE meins VALUE 'KG'.
DATA unit_m3      TYPE meins VALUE 'M3'.

" Convert a weight in KG into a volume in M3 for the given material
CALL FUNCTION 'MATERIAL_UNIT_CONVERSION'
  EXPORTING  input                = weight_in_kg
             kzmeinh              = abap_true
             matnr                = material
             meinh                = unit_m3
             meins                = unit_kg
  IMPORTING  output               = volume_in_m3
  EXCEPTIONS conversion_not_found = 1
             input_invalid        = 2
             material_not_found   = 3
             meinh_not_found      = 4
             meins_missing        = 5
             no_meinh             = 6
             output_invalid       = 7
             overflow             = 8
             OTHERS               = 9.

" IF, not CHECK. CHECK leaves the whole processing block when its condition is
" FALSE - so "CHECK sy-subrc <> 0." would abort on SUCCESS, the exact opposite
" of what is intended here.
IF sy-subrc <> 0.
  MESSAGE e001(zsm_msg) WITH material unit_kg unit_m3.
ENDIF.

" Generic material unit conversion (any unit -> any unit for a given material)
CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
  EXPORTING  i_matnr              = p_matnr
             i_in_me              = p_meins
             i_out_me             = 'PAL'
             i_menge              = p_menge
  IMPORTING  e_menge              = converted_quantity
  EXCEPTIONS error_in_application = 1
             error                = 2
             OTHERS               = 3.
```

### 🧰 Other Useful Standard Function Modules

> 📝 **Contextual snippet** — assumes a structure `entry` with the component `value`, and the variables `step` and `total_steps`.

```abap
" Extract a file extension from a MIME type (application/pdf -> pdf).
" Size the receiving field for the LONGEST extension you expect - a
" CHAR1 target would silently truncate 'pdf' to 'p'.
DATA extension TYPE string.
DATA mime_type TYPE w3conttype.

CALL FUNCTION 'SDOK_FILE_NAME_EXTENSION_GET'
  EXPORTING mimetype  = mime_type
  IMPORTING extension = extension.

" Validate/convert a time value
CALL FUNCTION 'CONVERT_TIME_INPUT'
  EXPORTING  input                     = entry-value
             plausibility_check        = 'X'
  IMPORTING  output                    = entry-value
  EXCEPTIONS plausibility_check_failed = 1
             wrong_format_in_input     = 2
             OTHERS                    = 3.

" Get the last date of a given month (YYYYMM -> date of the month's last day)
DATA last_day   TYPE sy-datum.
DATA year_month TYPE jva_prod_month.

CALL FUNCTION 'JVA_LAST_DATE_OF_MONTH'
  EXPORTING year_month         = year_month
  IMPORTING last_date_of_month = last_day.

" Get personnel number from user ID (HR)
DATA personnel_number TYPE persno.

CALL FUNCTION 'RP_GET_PERNR_FROM_USERID'
  EXPORTING  begda     = sy-datum
             endda     = sy-datum
             usrid     = sy-uname
             usrty     = '0001'
  IMPORTING  usr_pernr = personnel_number
  EXCEPTIONS retcd     = 1
             OTHERS    = 2.

" Get user address and lock status
DATA address     TYPE bapiaddr3.
DATA lock_status TYPE bapislockd.
DATA messages    TYPE TABLE OF bapiret2.
DATA is_locked   TYPE abap_bool.
DATA user_name   TYPE bapibname-bapibname.

CALL FUNCTION 'BAPI_USER_GET_DETAIL'
  EXPORTING username = user_name
  IMPORTING address  = address
            islocked = lock_status
  TABLES    return   = messages.

" Derive the Boolean in one step (Rules 4.6, 4.7)
is_locked = xsdbool( NOT line_exists( messages[ type = 'E' ] )
                     AND (    lock_status-glob_lock  = 'L'
                           OR lock_status-local_lock = 'L'
                           OR lock_status-no_user_pw = 'L'
                           OR lock_status-wrng_logon = 'L' ) ).

" Progress indicator for long-running dialog programs
" (use a text symbol so the message can be translated)
CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
  EXPORTING percentage = 10
            text       = |{ TEXT-p01 } { step }/{ total_steps }|.
```

### 📡 Calling a Function Module via RFC Destination

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. RFC remains the backbone of system-to-system integration in on-premise landscapes. Under ABAP Cloud, outbound calls go through released APIs and communication scenarios instead.

> 📝 **Contextual snippet** — assumes a method `get_destination` that reads the destination from configuration ([Rule 8.5](../docs/ABAP-Development-Rules.md#85-never-hard-code-credentials-hosts-or-destinations)), and the variables `user_name` and `is_admin`. `ZSM_FM_CHECK_ADMIN` is a placeholder RFC-enabled function module.

```abap
CONSTANTS admin_check_function TYPE tfdir-funcname VALUE 'ZSM_FM_CHECK_ADMIN'.

" The destination is maintained in SM59 and should come from Customizing,
" not be hardcoded in the program.
DATA(destination) = get_destination( ).   " TYPE rfcdest

" A remote call can fail for reasons a local call cannot. ALWAYS handle
" system_failure and communication_failure - otherwise an unreachable or
" misconfigured destination produces a short dump.
CALL FUNCTION admin_check_function DESTINATION destination
  EXPORTING  user_name             = user_name
  IMPORTING  is_admin              = is_admin
  EXCEPTIONS system_failure        = 1 MESSAGE DATA(system_message)
             communication_failure = 2 MESSAGE DATA(communication_message)
             OTHERS                = 3.

CASE sy-subrc.
  WHEN 0.
    " success
  WHEN 1.
    MESSAGE system_message TYPE 'E'.
  WHEN 2.
    MESSAGE communication_message TYPE 'E'.
  WHEN OTHERS.
    " user-facing text belongs in the message class (Rule 4.2)
    MESSAGE e030(zsm_msg) WITH destination.
ENDCASE.
```

> ⚠️ **RFC destinations carry authorization implications.** A destination configured with stored credentials executes in the target system as *that* user, not as the caller — so the calling program becomes responsible for deciding who may trigger it. A trusted-RFC destination propagates the caller's identity instead, and requires the corresponding authorizations in the target system. Never assume the remote side re-checks what the local side allowed: authorization-check the *entry point* in your own program, and keep destination names in Customizing rather than hardcoded — [Rules 8.10](../docs/ABAP-Development-Rules.md#810-check-business-authorizations-at-every-rfc-entry-point) and [8.5](../docs/ABAP-Development-Rules.md#85-never-hard-code-credentials-hosts-or-destinations).

## 🧵 Macros (`DEFINE` / `END-OF-DEFINITION`)

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE`. Macros are not classified as obsolete, but new code does not use them: the ABAP Programming Guidelines allow them only in exceptional cases, and [Rule 3.19](../docs/ABAP-Development-Rules.md#319-do-not-write-macros-use-methods-or-expressions) excludes them. `DEFINE` is not allowed in ABAP for Cloud Development. They are kept here because they appear constantly in existing programs — particularly in ALV and BAPI-filling code — and reading them is a real skill.

Macros perform a **textual substitution** before compilation. There is no type checking of parameters, no signature, and no line-by-line debugging: the debugger steps over the whole macro as one statement. New code uses a method or an expression instead — [Rule 3.19](../docs/ABAP-Development-Rules.md#319-do-not-write-macros-use-methods-or-expressions).

> 📝 **Contextual snippet** — assumes the variables `order_type` and `sales_org` and a field symbol `<entry>` with the component `value`.

```abap
" Simple macro
DEFINE printer.
  WRITE :/ 'Hello', &1, &2.
END-OF-DEFINITION.

WRITE / 'Before Using Macro'.
printer 'ABAP' 'Macros'.

" Macro used to fill a BAPI structure + its "X" (changed-flag) companion structure together
DATA header_in  TYPE bapisdhd1.  " SD Document Header
DATA header_inx TYPE bapisdhd1x. " SD Document Header Checkbox

DEFINE gx.
  &1-&2 = &3.
  &1x-&2 = abap_true.
END-OF-DEFINITION.

gx header_in doc_type  order_type.
gx header_in sales_org sales_org.

WRITE: header_in-doc_type, header_inx-doc_type.

" Macro that both replaces a character and condenses the result
DEFINE conv_char.
  REPLACE ALL OCCURRENCES OF &1 IN &2 WITH &3.
  CONDENSE &2.
END-OF-DEFINITION.

conv_char '-' <entry>-value ' '.
```

The current way to fill a BAPI structure and its `X` structure, without a macro:

```abap
" ✅ VALUE fills both structures; the X structure flags the same fields
header_in  = VALUE #( doc_type = order_type sales_org = sales_org ).
header_inx = VALUE #( doc_type = abap_true  sales_org = abap_true ).
```

> 💡 The `gx` macro above is the classic idiom for filling a BAPI structure and its `...X` "changed flag" companion in one line — `&1x` works because the macro is expanded as text before compilation. It is genuinely compact, and genuinely untypeable. That trade-off is why macros persist in BAPI-heavy code; in new code, fill both structures with `VALUE` as shown — [Rule 3.19](../docs/ABAP-Development-Rules.md#319-do-not-write-macros-use-methods-or-expressions).
>
> Character-transliteration macros (replacing locale-specific characters) are common in localized systems but are encoding-dependent — verify the behaviour against your system's code page before relying on them.

## 📞 Calling Other Programs — SUBMIT & Screen Chaining

> 📝 **Contextual snippet** — assumes a structure `document`; the selection-screen parameters of the called report (`p_bukrs`, `rb_fat` …) keep the names that report defines ([Rule 2.4](../docs/ABAP-Development-Rules.md#24-keep-names-that-are-fixed-by-a-signature-you-do-not-own)).

```abap
" Call a report, letting the user see/adjust its selection screen
SUBMIT zsm_r_order_overview VIA SELECTION-SCREEN AND RETURN.

" Call a report, passing selection-screen parameters directly (no screen shown)
SUBMIT zsm_r_order_overview
       AND RETURN
       WITH p_bukrs = document-bukrs
       WITH p_gjahr = document-gjahr
       WITH p_belnr = document-belnr
       WITH rb_fat  = abap_true.

" Call a screen at a specific position on the current window
CALL SCREEN 0200 STARTING AT 50 10.

" Read another program's global internal table by name (advanced / debugging technique)
ASSIGN ('(SAPMV54A)XVBUV[]') TO FIELD-SYMBOL(<incompletion_log>).

IF sy-subrc = 0.
  DATA(incompletion_log) = <incompletion_log>.
ENDIF.
```
> ⚠️ Reading another program's globals via `ASSIGN ('(PROGRAM)FIELD')` is a powerful but fragile technique (tightly coupled to SAP-internal program structures, can break with support packages). The ABAP Keyword Documentation reserves the `(PROG)DOBJ` form for internal use. Use it only when there is no supported API alternative, and document it clearly.

## 📊 Modularization Techniques Compared

| Technique | Reusable Across Programs? | Type-Checked? | Directly Remote-Callable? | Lifecycle | Recommended For |
|---|---|---|---|---|---|
| `FORM`/`PERFORM` | ❌ No (same program only) | ⚠️ Only if parameters are typed | ❌ No | `LEGACY / HISTORICAL REFERENCE` | Reading existing code; not for new development |
| Macro (`DEFINE`) | ❌ No (same program only) | ❌ No | ❌ No | `LEGACY / HISTORICAL REFERENCE` | Reading existing code; not for new development (Rule 3.19) |
| Function Module | ✅ Yes (via its function group) | ✅ Yes | ✅ Yes, if the FM is RFC-enabled | `CLASSIC BUT STILL RELEVANT` | Remote-callable logic, BAPIs, compatibility with existing APIs |
| Class/Method | ✅ Yes (if a global class) | ✅ Yes | ❌ **Not directly** — see below | `CURRENT / RECOMMENDED` | All new development |

> ⚠️ **There is no such thing as an "RFC-enabled method".** Remote callability is a property of a *function module*, not of a method. To expose class logic to another system you wrap it — in an RFC-enabled function module, or behind a service model such as OData/RAP or a web service. Keep the logic in the class and let the wrapper be a thin adapter.

## ✅ Best Practices

- Prefer **methods on classes** for new development; use function modules mainly when remote callability or compatibility with existing APIs (BAPIs) is required, and keep them thin wrappers around a class — [Rule 5.1](../docs/ABAP-Development-Rules.md#51-write-new-logic-in-classes-wrap-function-modules-and-bapis).
- Do not write new macros; use methods or expressions — [Rule 3.19](../docs/ABAP-Development-Rules.md#319-do-not-write-macros-use-methods-or-expressions).
- Type every parameter, including `FORM ... USING` parameters in code you have to touch anyway.
- Always check `sy-subrc` / handle `EXCEPTIONS` after `CALL FUNCTION`, and turn them into exceptions at the boundary — [Rule 6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary) — and handle `system_failure` / `communication_failure` for remote calls.
- Use `SUBMIT ... AND RETURN` (not a plain `SUBMIT`) when you need control to come back to your program.
- Keep RFC destination names in Customizing, not in the code — [Rule 8.5](../docs/ABAP-Development-Rules.md#85-never-hard-code-credentials-hosts-or-destinations).
- Check business authorizations in every RFC-enabled function module — [Rule 8.10](../docs/ABAP-Development-Rules.md#810-check-business-authorizations-at-every-rfc-entry-point).

## ⚠️ Common Mistakes

- Calling a class method with `CALL FUNCTION`.
- Forgetting the `OTHERS = n` catch-all in a `CALL FUNCTION ... EXCEPTIONS` list.
- Omitting `system_failure` / `communication_failure` on a `DESTINATION` call, turning an unreachable system into a short dump.
- Using `CHECK` where `IF` is meant — outside a loop, `CHECK` leaves the whole processing block when its condition is false, which inverts an error-handling branch — [Rule 3.17](../docs/ABAP-Development-Rules.md#317-use-check-only-as-an-input-check-at-the-start-of-a-method-prefer-if--return).
- Using a macro where a method would be clearer and safer.
- Getting the conversion-exit direction wrong (`INPUT` = external→internal, `OUTPUT` = internal→external), leading to double-converted or wrongly-padded keys.

## 🎤 Interview & Review Checkpoints

- Explain the difference between a function module and a BAPI (a BAPI is a function module that belongs to the official Business Object API, is RFC-enabled, and follows strict naming and interface conventions).
- Explain how you would expose a class's logic to another system, and why "make the method RFC-enabled" is not an answer.
- Be ready to explain why macros are discouraged in modern ABAP.
- Explain what a conversion exit is and give an example (`ALPHA`, `MATN1`).
- Explain the difference between `CHECK` and `IF`, and where each belongs.

## 🔗 Related Chapters

- [03-Variables](../03-Variables/README.md#-form--perform-classical-subroutines) — `FORM`/`PERFORM` syntax in detail
- [02-Data-Types](../02-Data-Types/README.md#-type-conversions) — `ALPHA` formatting without a conversion exit
- [05-Control-Statements](../05-Control-Statements/README.md) — `CHECK` versus `IF`
- [10-Objects](../10-Objects/README.md) — classes and methods for new logic
- [14-Function-Modules](../14-Function-Modules/README.md) — batch input and `CALL TRANSACTION`
- [15-BAPIs](../15-BAPIs/README.md) — BAPI calls and their commit protocol
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — the lifecycle labels used in this chapter
