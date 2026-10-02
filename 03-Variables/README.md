# 03 — Variables

## 📖 Introduction

This chapter is a reference for the most common variable, constant, and object declarations you will write in almost every ABAP program — from simple scalar variables to class instances, internal tables, and pointers.

## 🧮 Declaring Variables

```abap
" BAPI Return Message
DATA(messages) = VALUE bapiret2_t( ).

" Boolean
DATA(was_found) = xsdbool( sy-subrc = 0 ).

" Constant (TYPE, not LIKE, when referring to a Dictionary field)
CONSTANTS default_notification TYPE bapi2080_nothdre-notif_no VALUE '000000000001'.

" Calling a static method with a returning value.
" In an operand position (right-hand side of an assignment) you may only
" supply INPUT parameters - see the note below.
DATA(surname) = zcl_zsm_person=>get_surname( name = 'USER01' ).

" Clear
CLEAR surname.

" Classic (explicit type) declarations
DATA remark          TYPE c LENGTH 120          VALUE 'S'.
DATA document_number TYPE n LENGTH 10           VALUE '0000001907'.
DATA counter         TYPE i                     VALUE 1994.
DATA mime_type       TYPE w3conttype            VALUE 'application/pdf'.
DATA amount          TYPE p LENGTH 8 DECIMALS 2 VALUE '17.75'.
DATA description     TYPE string                VALUE 'Example text'.

DATA(return_messages) = VALUE bapiret2_tab( ).
DATA(key_values)      = VALUE zsm_tt_value( ( key_value ) ).
```

> ⚠️ **A functional method call in an operand position takes input parameters only.** `DATA(x) = cl=>meth( ... )` cannot carry `IMPORTING` or `CHANGING` parameters — for those, use a standalone call:
> ```abap
> zcl_zsm_person=>get_surname( EXPORTING name    = 'USER01'
>                              IMPORTING surname = DATA(found_surname) ).
> ```
> Also note that a literal such as `'X'` can never be bound to a `CHANGING` parameter — a changing parameter is written back to, so it needs a variable.

> 💡 **`TYPE` rather than `LIKE`** when referring to a Dictionary field. `LIKE` referring to Dictionary objects is an obsolete form; `LIKE` referring to another *data object* in the same program is still valid.

> ⚠️ **Every variable may be declared once per scope.** Each block in this guide is meant to be independently pasteable, so watch for names you have already declared when combining snippets.

## 🧵 `FORM` / `PERFORM` (Classical Subroutines)

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE`. Procedural subroutines are obsolete for new code and are not available in ABAP Cloud — but they are everywhere in existing programs, so reading them is a required skill. Prefer methods for anything you write. See [09-Modularization](../09-Modularization/README.md) and [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

`FORM`/`PERFORM` with `TABLES`/`USING` parameters is still found in many long-lived programs:

```abap
DATA headers        LIKE TABLE OF bapi_order_header1    WITH HEADER LINE.
DATA operations     LIKE TABLE OF bapi_order_operation1 WITH HEADER LINE.
DATA components     LIKE TABLE OF bapi_order_component  WITH HEADER LINE.
DATA order_quantity TYPE int4.

PERFORM get_component TABLES headers
                             operations
                             components.
PERFORM use_data USING order_quantity.

FORM get_component TABLES order_headers    STRUCTURE bapi_order_header1
                          order_operations STRUCTURE bapi_order_operation1
                          order_components STRUCTURE bapi_order_component.
ENDFORM.

" Always TYPE a USING parameter - an untyped one accepts anything and
" defers every error to runtime.
FORM use_data USING quantity TYPE int4.
ENDFORM.
```

## 📞 Calling Methods, Function Modules & Includes

```abap
" Calling a STATIC METHOD that returns a value.
" Note: CALL FUNCTION is for function modules only - a class method is never
" called with CALL FUNCTION.
DATA(sender) = cl_cam_address_bcs=>create_internet_address(
                   i_address_string = CONV #( sender_email ) ).

" Calling a FUNCTION MODULE
CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
  EXPORTING input  = external_value
  IMPORTING output = internal_value.

" Field Symbol
LOOP AT key_values ASSIGNING FIELD-SYMBOL(<key_value>).
ENDLOOP.

" Include
INCLUDE zsm_r_order_overview_top.
INCLUDE zsm_r_order_overview_frm.
```

> ⚠️ `CALL FUNCTION` expects a **function module name** (a character value, usually a literal or a variable). Writing `CALL FUNCTION cl_some_class=>some_method` is a syntax error. Verify a class method's real signature in SE24 before calling it — see [09-Modularization](../09-Modularization/README.md) for more on choosing between methods and function modules.

## ✍️ Output & Pointers

```abap
START-OF-SELECTION.
  " Optional value (returns the initial value instead of raising if not found)
  DATA(found_value) = VALUE #( key_values[ name = 'Key' ]-value OPTIONAL ).

  " Output
  WRITE 'Hello'.
  WRITE / 'Hello'.
  WRITE: 'Hello', 'World'.

  " Quantity with its unit of measure
  DATA quantity_text TYPE c LENGTH 20.
  WRITE order_quantity TO quantity_text UNIT sales_unit.

  " Pointer (data reference)
  DATA(digits)     = '12345'.
  DATA(digits_ref) = REF #( digits ).

  WRITE digits_ref->*.
```

## 📊 Declaration Styles at a Glance

| Style | Example | When to Use |
|---|---|---|
| Explicit `DATA` with `TYPE` | `DATA count TYPE i.` | When the type must be visible/explicit, or declared before first use (top of routine) |
| Inline declaration | `DATA(count) = 5.` | Modern ABAP (7.40 generation onward), when the type can be inferred; keeps declarations close to usage |
| `CONSTANTS` | `CONSTANTS max_count TYPE i VALUE 5.` | Fixed values that never change during runtime |
| `FIELD-SYMBOL(<line>)` | inline in `ASSIGN`/`LOOP` | Accessing data without copying it (performance) |

> ⚠️ **An inline declaration cannot carry a `TYPE` addition.** `DATA(count) TYPE i.` is a syntax error — the whole point of `DATA(...)` is that the type comes from the assignment. If you need to state the type, use the classic form: `DATA count TYPE i.`

## ✅ Best Practices

- Prefer inline declarations (`DATA(...)`) close to first use for readability, but declare variables at the top of the method if they are reused across many statements.
- Use `CONSTANTS` (or better, custom data elements/domains) instead of "magic numbers"/hardcoded literals scattered through the code.
- Use `VALUE #( ... OPTIONAL )` instead of `READ TABLE` + `IF sy-subrc = 0` when you just need a safe default value.
- Type every `FORM`/method parameter. An untyped parameter accepts anything and defers all errors to runtime.

## ⚠️ Common Mistakes

- Declaring the same variable name twice in the same scope (syntax error) — always check existing declarations before adding new ones.
- Adding `TYPE` to an inline `DATA(...)` declaration.
- Calling a class method with `CALL FUNCTION`.
- Supplying `IMPORTING`/`CHANGING` parameters to a functional method call used in an operand position.
- Using `TABLES` / header-line based parameters in new code — prefer standard internal tables with explicit work areas.
- Forgetting to `CLEAR` reused work areas between loop iterations when not using `LOOP ... INTO` (which implicitly clears).

## 🎤 Interview & Review Checkpoints

- Explain the difference between `DATA`, `CONSTANTS`, and `FIELD-SYMBOLS`.
- Explain when `#` can be used for a constructor expression's type and when an explicit type is required.
- Be ready to discuss why modern ABAP favors inline declarations and `VALUE`/`CORRESPONDING` constructors over `MOVE`/explicit `DATA` + `APPEND`.
- Know what a data reference (`REF #( )`, `TYPE REF TO data`) is and how it differs from an object reference (`TYPE REF TO <class>`).

## 🔗 Related Chapters

- [07-Internal-Tables](../07-Internal-Tables/README.md) — field symbols and data references in depth
- [09-Modularization](../09-Modularization/README.md) — `FORM`/`PERFORM` vs. methods
- [10-Objects](../10-Objects/README.md) — object references
