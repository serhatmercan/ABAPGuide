# 03 — Variables

> **Lifecycle:** `CURRENT / RECOMMENDED`. Declarations, constants, method calls and references are current; subroutines and classical list output are labelled where they appear. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

This chapter is a reference for the most common variable, constant, and object declarations you will write in almost every ABAP program — from simple scalar variables to class instances, internal tables, and pointers.

Names in the examples follow [Rules 2.1–2.6](../docs/ABAP-Development-Rules.md#2-naming): descriptive names without type prefixes, and `zsm` placeholders for development objects.

## 🧮 Declaring Variables

> 📝 **Contextual snippet** — assumes a class `zcl_zsm_person` with a static method `get_surname` (`IMPORTING name`, `RETURNING VALUE(result)`), a table type `zsm_tt_value` and a matching structure `key_value`.

```abap
" BAPI Return Message
DATA(messages) = VALUE bapiret2_t( ).

" Boolean
DATA(was_found) = xsdbool( sy-subrc = 0 ).

" Constant (TYPE, not LIKE, when referring to a Dictionary field)
CONSTANTS default_notification TYPE bapi2080_nothdre-notif_no VALUE '000000000001'.

" Calling a static method with a returning value in an operand position
" (right-hand side of an assignment) - see the note below for its limits.
DATA(surname) = zcl_zsm_person=>get_surname( name = 'JANE DOE' ).

" Clear
CLEAR surname.

" Classic (explicit type) declarations
DATA remark          TYPE c LENGTH 120          VALUE 'S'.
DATA document_number TYPE n LENGTH 10           VALUE '0000004711'.
DATA counter         TYPE i                     VALUE 42.
DATA mime_type       TYPE w3conttype            VALUE 'application/pdf'.
DATA amount          TYPE p LENGTH 8 DECIMALS 2 VALUE '17.75'.
DATA description     TYPE string                VALUE 'Example text'.

DATA(return_messages) = VALUE bapiret2_tab( ).
DATA(key_values)      = VALUE zsm_tt_value( ( key_value ) ).
```

> ⚠️ **A functional method call has three limits.** According to the ABAP Keyword Documentation, actual parameters cannot be declared inline, the return value cannot be assigned with `RECEIVING`, and classic exceptions cannot be handled with `EXCEPTIONS`. Where you need one of these, use a standalone call:
> ```abap
> zcl_zsm_person=>split_name( EXPORTING name       = 'JANE DOE'
>                             IMPORTING first_name = DATA(first_name)
>                                       surname    = DATA(family_name) ).
> ```
> Also note that a literal such as `'X'` can never be bound to a `CHANGING` parameter — a changing parameter is written back to, so it needs a variable.

> 💡 A functional call may also bind `IMPORTING` and `CHANGING` parameters, but a method should return one value with `RETURNING` and not combine it with `EXPORTING` or `CHANGING` — [Rule 5.9](../docs/ABAP-Development-Rules.md#59-return-one-value-with-returning-instead-of-exporting).

> 💡 **`TYPE` rather than `LIKE`** when referring to a Dictionary field. `LIKE` referring to Dictionary objects is an obsolete form; `LIKE` referring to another *data object* in the same program is still valid.

> ⚠️ **Every variable may be declared once per scope.** Each block in this guide is meant to be independently pasteable, so watch for names you have already declared when combining snippets.

## 🧵 `FORM` / `PERFORM` (Classical Subroutines)

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE`. Subroutines are obsolete; they are technically allowed in ABAP for Cloud Development but not written in new code. They are everywhere in existing programs, so reading them is a required skill. Prefer methods for anything you write. See [09-Modularization](../09-Modularization/README.md) and [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference).

The example also shows two obsolete declarations that usually come with it: `LIKE` referring to a Dictionary structure, and `WITH HEADER LINE`.

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

> 📝 **Contextual snippet** — assumes the variables `sender_email`, `external_value` and `internal_value`, the table `key_values` from the first snippet, and the includes of a report `zsm_r_order_overview`.

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

> 💡 For the `ALPHA` conversion itself, the string template option `ALPHA = IN` / `ALPHA = OUT` needs no function module — see [02-Data-Types](../02-Data-Types/README.md#-type-conversions).

> ⚠️ `CALL FUNCTION` expects a **function module name** (a character value, usually a literal or a variable). Writing `CALL FUNCTION cl_some_class=>some_method` is a syntax error. Verify a class method's real signature in SE24 before calling it — see [09-Modularization](../09-Modularization/README.md) for more on choosing between methods and function modules.

## ✍️ Output & Pointers

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` for the `WRITE` list output, which exists only in Standard ABAP. `VALUE … OPTIONAL` and `REF #( )` are current.

> 📝 **Contextual snippet** — assumes the table `key_values` from the first snippet and the variables `order_quantity` and `sales_unit`.

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
| `FINAL(...)` *(VERSION-DEPENDENT)* | `FINAL(count) = 5.` | Inline declaration of a value that is never reassigned — [Rule 3.3](../docs/ABAP-Development-Rules.md#33-declare-values-that-are-never-reassigned-with-final) |
| `CONSTANTS` | `CONSTANTS max_count TYPE i VALUE 5.` | Fixed values that never change during runtime |
| `FIELD-SYMBOL(<line>)` | inline in `ASSIGN`/`LOOP` | Accessing data without copying it (performance) |

> ⚠️ **An inline declaration cannot carry a `TYPE` addition.** `DATA(count) TYPE i.` is a syntax error — the whole point of `DATA(...)` is that the type comes from the assignment. If you need to state the type, use the classic form: `DATA count TYPE i.`

## ✅ Best Practices

- Declare variables inline at first use — [Rule 3.1](../docs/ABAP-Development-Rules.md#31-declare-variables-inline-at-first-use) — and give the declaration an explicit type when the initial value would infer the wrong one — [Rule 3.2](../docs/ABAP-Development-Rules.md#32-give-an-inline-declaration-an-explicit-type-when-the-initial-value-would-infer-the-wrong-one). Where an up-front declaration is needed, write one statement per variable — [Rule 12.4](../docs/ABAP-Development-Rules.md#124-do-not-chain-up-front-declarations).
- Replace magic literals with named constants, declared in the class that owns the concept — [Rules 4.1](../docs/ABAP-Development-Rules.md#41-replace-magic-literals-with-named-constants) and [4.3](../docs/ABAP-Development-Rules.md#43-declare-constants-in-the-class-or-interface-that-owns-the-concept-grouped-by-topic).
- Use `VALUE #( ... OPTIONAL )` or `DEFAULT` instead of `READ TABLE` + `IF sy-subrc = 0` when a missing line is allowed — [Rule 3.13](../docs/ABAP-Development-Rules.md#313-read-with-a-table-expression-only-when-a-miss-is-handled).
- Type every `FORM`/method parameter. An untyped parameter accepts anything and defers all errors to runtime.

## ⚠️ Common Mistakes

- Declaring the same variable name twice in the same scope (syntax error) — always check existing declarations before adding new ones.
- Adding `TYPE` to an inline `DATA(...)` declaration.
- Calling a class method with `CALL FUNCTION`.
- Declaring an actual parameter inline, or using `RECEIVING` or `EXCEPTIONS`, in a functional method call — these need a standalone call.
- Using `TABLES` / header-line based parameters in new code — prefer standard internal tables with explicit work areas.
- Filling a reused work area field by field across loop iterations without `CLEAR` — fields not set in the current pass keep the previous values. `LOOP ... INTO` assigns the whole current line to the work area in each pass.

## 🎤 Interview & Review Checkpoints

- Explain the difference between `DATA`, `CONSTANTS`, and `FIELD-SYMBOLS`.
- Explain when `#` can be used for a constructor expression's type and when an explicit type is required.
- Be ready to discuss why modern ABAP favors inline declarations and `VALUE`/`CORRESPONDING` constructors over `MOVE`/explicit `DATA` + `APPEND`.
- Know what a data reference (`REF #( )`, `TYPE REF TO data`) is and how it differs from an object reference (`TYPE REF TO <class>`).

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md) — the types these declarations use
- [07-Internal-Tables](../07-Internal-Tables/README.md) — field symbols and data references in depth
- [09-Modularization](../09-Modularization/README.md) — `FORM`/`PERFORM` vs. methods
- [10-Objects](../10-Objects/README.md) — object references
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — the lifecycle labels used in this chapter
