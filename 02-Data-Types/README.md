# 02 — Data Types

> **Lifecycle:** `CURRENT / RECOMMENDED`. Elementary types, structures, ranges tables and RTTS are current; the legacy ways of reading domain values are labelled where they appear. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

ABAP is a strongly typed language. Before you can store a value, you must declare its **type** — either an elementary type (`c`, `n`, `i`, `p`, `string`, ...) or a structured type (`TYPES ... BEGIN OF`). This chapter covers structures, ranges tables, common string cleanup, type conversions, and reading type information and domain fixed values at runtime via RTTS.

Names in the examples follow [Rules 2.1–2.6](../docs/ABAP-Development-Rules.md#2-naming): descriptive names without type prefixes, and `zsm` placeholders for development objects.

## 🧱 Elementary Data Types Cheat Sheet

| Type | Description | Example |
|---|---|---|
| `c` | Fixed-length character | `DATA text TYPE c LENGTH 10.` |
| `n` | Numeric text (digits only, leading zeros) | `DATA fiscal_year TYPE n LENGTH 4.` |
| `i` / `int4` | Integer | `DATA item_count TYPE i.` |
| `p` | Packed decimal | `DATA amount TYPE p LENGTH 8 DECIMALS 2.` |
| `string` | Variable-length character string | `DATA description TYPE string.` |
| `d` / `datum` | Date (`YYYYMMDD`) | `DATA posting_date TYPE d.` |
| `t` / `tims` | Time (`HHMMSS`) | `DATA posting_time TYPE t.` |
| `xstring` | Variable-length byte string (binary) | `DATA file_content TYPE xstring.` |

## 🧩 Structures

A **structure** groups related fields together, similar to a `struct` in C or a record in other languages.

```abap
TYPES: BEGIN OF notification_header,
         notification_id   TYPE char10,
         notification_type TYPE char2,
         description       TYPE char40,
       END OF notification_header.

DATA notification TYPE notification_header.
```

> See [07-Internal-Tables](../07-Internal-Tables/README.md) for building tables of structures, and [08-Open-SQL](../08-Open-SQL/README.md) for reading DB tables directly into structures.

## 🧹 Cleaning Up String Data

Two very common statements when working with character data read from the database or user input:

> 📝 **Contextual snippet** — `raw_value` is a character-like variable holding the value to clean up.

```abap
" Condense: Delete Space
CONDENSE raw_value.

" Shift: Delete Beginning Zeros
SHIFT raw_value LEFT DELETING LEADING '0'.
```

| Statement | Purpose |
|---|---|
| `CONDENSE` | Removes leading blanks and collapses each run of internal blanks to a single blank. With `NO-GAPS`, removes **all** blanks |
| `SHIFT ... LEFT DELETING LEADING '0'` | Strips leading zeros — useful before comparing numeric-looking strings |

> 💡 The built-in functions `condense( )` and `shift_left( )` do the same inside expressions — see [Examples/String-Functions.md](../Examples/String-Functions.md).

## 🔁 Type Conversions

ABAP performs a lot of *implicit* conversions, but it's important to know how to convert **explicitly**, especially between internal keys and their "human readable" (ALPHA) form.

> 📝 **Contextual snippet** — assumes a structure `document` with the component `vbeln`, a structure `entry` with the component `value`, and a structure `external_entry` whose components partly match the custom table `zsm_t_order`.

```abap
" ALPHA IN: Add leading zeros (internal format)
DATA document_number TYPE char10.
document_number = |{ document-vbeln ALPHA = IN }|.

" ALPHA OUT: Remove leading zeros (external/display format)
document_number = |{ document-vbeln ALPHA = OUT }|.

" Explicit type conversion with CONV
DATA(quantity) = CONV int4( entry-value ).

" Mapping between structures with CORRESPONDING
DATA(mapped_entry) = CORRESPONDING zsm_t_order( external_entry ).
```

- `CONV` converts inline; use `EXACT` when a value must not be rounded or truncated — [Rule 3.7](../docs/ABAP-Development-Rules.md#37-convert-types-inline-with-conv-use-exact-when-data-must-not-be-lost).
- `CORRESPONDING` starts from an initial target; add `BASE` when existing target values must survive — [Rule 3.5](../docs/ABAP-Development-Rules.md#35-map-structures-and-tables-with-corresponding-add-base-when-target-values-must-survive).

Conversion exits (`CONVERSION_EXIT_*`) are the classical, function-module–based way of doing the same thing and are still widely used with material numbers, dates, and other domain-specific fields — see [09-Modularization](../09-Modularization/README.md#-conversion-exits).

## 📋 Reading Domain Fixed Values at Runtime (RTTS)

> **Lifecycle:** `CURRENT / RECOMMENDED`.

**RTTS** (Runtime Type Services) is the set of `CL_ABAP_*DESCR` classes that describe a type at runtime — including DDIC types looked up by name. A common use is reading the **fixed values of a data element's domain**, so that dropdowns, value checks or OData value help stay in sync with the DDIC instead of hard-coding the domain values in the program.

> 📝 **Contextual snippet** — `result` is assumed to be the returning parameter of the surrounding method (`RETURNING VALUE(result) TYPE status_values`, Rule 5.9); the `TYPES` show its shape and the `DATA result` line stands in for that parameter. `ZSM_E_STATUS` is a placeholder data element whose domain has fixed values.

```abap
TYPES: BEGIN OF status_value,
         status      TYPE zsm_e_status,
         status_text TYPE ddfixvalue-ddtext,
       END OF status_value.
TYPES status_values TYPE STANDARD TABLE OF status_value WITH EMPTY KEY.

DATA result TYPE status_values.

DATA(fixed_values) = CAST cl_abap_elemdescr(
  cl_abap_typedescr=>describe_by_name( 'ZSM_E_STATUS' ) )->get_ddic_fixed_values( ).

result = VALUE #( FOR fixed_value IN fixed_values
                  ( status = fixed_value-low status_text = fixed_value-ddtext ) ).
```

The compact form above assumes the name is known to be a valid elementary DDIC type. When the name comes from configuration or user input, use the robust variant. It turns the classic exceptions into the method's own exceptions at this boundary ([Rule 6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary)).

> 📝 **Contextual snippet** — additionally assumes `type_name` holding the data element name, and an exception class `zcx_zsm_fixed_values_missing` with T100 texts in the message class `zsm_msg`.

```abap
DATA type_description TYPE REF TO cl_abap_typedescr.

" describe_by_name signals an unknown name via a classic exception
cl_abap_typedescr=>describe_by_name(
  EXPORTING
    p_name         = type_name
  RECEIVING
    p_descr_ref    = type_description
  EXCEPTIONS
    type_not_found = 1
    OTHERS         = 2 ).
IF sy-subrc <> 0.
  RAISE EXCEPTION TYPE zcx_zsm_fixed_values_missing
    MESSAGE e020(zsm_msg) WITH type_name.
ENDIF.

" Only elementary types (data elements) have domain fixed values
IF type_description->kind <> cl_abap_typedescr=>kind_elem.
  RAISE EXCEPTION TYPE zcx_zsm_fixed_values_missing
    MESSAGE e021(zsm_msg) WITH type_name.
ENDIF.

" get_ddic_fixed_values has classic exceptions of its own
DATA fixed_values TYPE ddfixvalues.

DATA(element_description) = CAST cl_abap_elemdescr( type_description ).

element_description->get_ddic_fixed_values(
  RECEIVING
    p_fixed_values = fixed_values
  EXCEPTIONS
    not_found      = 1
    no_ddic_type   = 2
    OTHERS         = 3 ).
IF sy-subrc <> 0.
  RAISE EXCEPTION TYPE zcx_zsm_fixed_values_missing
    MESSAGE e022(zsm_msg) WITH type_name.
ENDIF.

result = VALUE #( FOR fixed_value IN fixed_values
                  ( status = fixed_value-low status_text = fixed_value-ddtext ) ).
```

**Common mistakes / notes**

- **Unknown name → runtime error.** `describe_by_name` raises the classic exception `TYPE_NOT_FOUND` for a name that does not exist. In the compact form it is not handled, so it ends in a runtime error. Use the `EXCEPTIONS` variant shown above.
- **Returning nothing hides the problem.** An early `RETURN` on a failed lookup leaves the caller with an empty result and no reason. Raise an exception instead — [Rule 6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary).
- **Non-elementary name → `CX_SY_MOVE_CAST_ERROR`.** If the name resolves to a structure, table type or class, the `CAST cl_abap_elemdescr( ... )` fails. Check `kind` first (as above) or catch the exception.
- **Elementary is not the same as DDIC.** A built-in type such as `i` passes the `kind` check but is not a DDIC type, so `get_ddic_fixed_values` raises `NO_DDIC_TYPE` (or `NOT_FOUND` when no fixed values can be read). In the compact form these are not handled either, so they again end in a runtime error.
- **Intervals are silently truncated.** A domain fixed value can be an interval (`option = 'BT'` with a `high` value). Mapping only `low` drops the upper bound without warning — map `high` as well, or handle `BT` rows explicitly, if the domain uses intervals.
- **Texts are language-dependent.** `ddtext` is returned in the logon language by default; `get_ddic_fixed_values` has an optional language parameter if you need a different one. Check the method signature in your system for the exact parameter details.

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE`. Reading `DD07L`/`DD07T` directly with `SELECT`, or calling the function module `DD_DOMVALUES_GET`, is what you will meet in existing code; prefer RTTS in new code. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference).

### Other type information

The same entry points describe any type, not only data elements: `describe_by_name` takes a type name, and `describe_by_data` takes a data object. The result is an object of the matching type description class, such as `CL_ABAP_ELEMDESCR`, `CL_ABAP_STRUCTDESCR` or `CL_ABAP_TABLEDESCR`. Its attributes, for example `type_kind`, describe the type, and the classes for complex types lead to their parts — for example, the attribute `components` of `CL_ABAP_STRUCTDESCR` lists the components of a structure at runtime.

## 🎯 Ranges Tables

A **ranges table** stores a ranges condition: the same `sign` / `option` / `low` / `high` lines that a `SELECT-OPTIONS` field holds. `TYPE RANGE OF` derives such a table type from a data type. The result is a standard table with a standard key.

> 📝 **Contextual snippet** — `zsm_e_order_date` is a placeholder data element of type `d`.

```abap
TYPES order_date_range TYPE RANGE OF zsm_e_order_date.

DATA(order_dates) = VALUE order_date_range(
  ( sign = 'I' option = 'BT' low = '20260101' high = '20261231' ) ).
```

A ranges table can be used with `IN` in ABAP SQL `WHERE` conditions and in logical expressions. See [12-Selection-Screens](../12-Selection-Screens/README.md) for `SELECT-OPTIONS`.

## ✅ Best Practices

- Prefer `string` for text of unknown/variable length; use fixed `c`/`n` types only when the length is business-defined (e.g., document number).
- Use `CORRESPONDING #( )` instead of field-by-field assignments when converting between similar structures, and add `BASE` when target values must survive — [Rule 3.5](../docs/ABAP-Development-Rules.md#35-map-structures-and-tables-with-corresponding-add-base-when-target-values-must-survive).
- Give an inline declaration an explicit type when the initial value would infer the wrong one — [Rule 3.2](../docs/ABAP-Development-Rules.md#32-give-an-inline-declaration-an-explicit-type-when-the-initial-value-would-infer-the-wrong-one).
- Read domain fixed values through RTTS rather than hard-coding them in the program — [Rule 4.1](../docs/ABAP-Development-Rules.md#41-replace-magic-literals-with-named-constants).
- Always double check decimal places (`DECIMALS`) for `p` type fields dealing with currency/quantity to avoid rounding bugs.

## ⚠️ Common Mistakes

- Comparing an ALPHA-converted key (with leading zeros) to a raw user-input value without converting both sides consistently.
- Using `c` type for numbers that need arithmetic — use `n` only for numeric-looking IDs, never for calculations.
- Forgetting `CONDENSE` before string comparisons/concatenations, leading to subtle whitespace bugs.
- Declaring `DATA(text) = 'abc'.` and later assigning a longer value: the inline type is `c LENGTH 3`, so the value is truncated.

## 🎤 Interview & Review Checkpoints

- Be able to explain the difference between `c`, `n`, `string`, and when to use each.
- Know what `CORRESPONDING #( )` does and how it differs from `MOVE-CORRESPONDING`.
- Explain what the `ALPHA` conversion exit does and why it matters for SAP key fields (e.g., material number, document number).

## 🔗 Related Chapters

- [03-Variables](../03-Variables/README.md) — declarations and inline declarations
- [07-Internal-Tables](../07-Internal-Tables/README.md) — tables of structures and mapping fixed values with `VALUE ... FOR`
- [09-Modularization](../09-Modularization/README.md#-conversion-exits) — conversion exits
- [12-Selection-Screens](../12-Selection-Screens/README.md) — `SELECT-OPTIONS` and ranges tables
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — the lifecycle labels used in this chapter
- [Examples/String-Functions.md](../Examples/String-Functions.md) — string functions and their statement equivalents
