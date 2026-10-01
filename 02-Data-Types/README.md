# 02 — Data Types

## 📖 Introduction

ABAP is a strongly typed language. Before you can store a value, you must declare its **type** — either an elementary type (`c`, `n`, `i`, `p`, `string`, ...) or a structured type (`TYPES ... BEGIN OF`). This chapter covers structures, common string cleanup, type conversions, and reading domain fixed values at runtime via RTTS.

## 🧱 Elementary Data Types Cheat Sheet

| Type | Description | Example |
|---|---|---|
| `c` | Fixed-length character | `DATA lv_char TYPE c LENGTH 10.` |
| `n` | Numeric text (digits only, leading zeros) | `DATA lv_num TYPE n LENGTH 4.` |
| `i` / `int4` | Integer | `DATA lv_int TYPE i.` |
| `p` | Packed decimal | `DATA lv_amt TYPE p LENGTH 8 DECIMALS 2.` |
| `string` | Variable-length character string | `DATA lv_str TYPE string.` |
| `d` / `datum` | Date (`YYYYMMDD`) | `DATA lv_date TYPE d.` |
| `t` / `tims` | Time (`HHMMSS`) | `DATA lv_time TYPE t.` |
| `xstring` | Variable-length byte string (binary) | `DATA lv_bin TYPE xstring.` |

## 🧩 Structures

A **structure** groups related fields together, similar to a `struct` in C or a record in other languages.

```abap
TYPES: BEGIN OF ty_viqmel,
         notif_no    TYPE char10,
         notif_type  TYPE char2,
         description TYPE char40,
       END OF ty_viqmel.

DATA ls_viqmel TYPE ty_viqmel.
```

> See [07-Internal-Tables](../07-Internal-Tables/README.md) for building tables of structures, and [08-Open-SQL](../08-Open-SQL/README.md) for reading DB tables directly into structures.

## 🧹 Cleaning Up String Data

Two very common statements when working with character data read from the database or user input:

```abap
" Condense: Delete Space
CONDENSE lv_data.

" Shift: Delete Beginning Zeros
SHIFT lv_data LEFT DELETING LEADING '0'.
```

| Statement | Purpose |
|---|---|
| `CONDENSE` | Removes leading blanks and collapses each run of internal blanks to a single blank. With `NO-GAPS`, removes **all** blanks |
| `SHIFT ... LEFT DELETING LEADING '0'` | Strips leading zeros — useful before comparing numeric-looking strings |

## 🔁 Type Conversions

ABAP performs a lot of *implicit* conversions, but it's important to know how to convert **explicitly**, especially between internal keys and their "human readable" (ALPHA) form.

```abap
" ALPHA IN: Add leading zeros (internal format)
DATA lv_vbeln TYPE char10.
lv_vbeln = |{ is_data-vbeln ALPHA = IN }|.

" ALPHA OUT: Remove leading zeros (external/display format)
lv_vbeln = |{ is_data-vbeln ALPHA = OUT }|.

" Explicit type conversion with CONV
DATA(lv_data)  = CONV int4( ls_data-value ).
DATA(ls_data)  = CORRESPONDING zsm_t_data( ls_xdata ).
```

Conversion exits (`CONVERSION_EXIT_*`) are the classical, function-module–based way of doing the same thing and are still widely used with material numbers, dates, and other domain-specific fields — see [09-Modularization](../09-Modularization/README.md#-conversion-exits).

## 📋 Reading Domain Fixed Values at Runtime (RTTS)

> **Lifecycle:** `CURRENT / RECOMMENDED`.

**RTTS** (Runtime Type Services) is the set of `CL_ABAP_*DESCR` classes that describe a type at runtime — including DDIC types looked up by name. A common use is reading the **fixed values of a data element's domain**, so that dropdowns, value checks or OData value help stay in sync with the DDIC instead of hard-coding the domain values in the program.

> 📝 **Contextual snippet** — `et_data` is assumed to be an exporting parameter of the surrounding method; the `TYPES` show its shape and the `DATA et_data` line stands in for that parameter. `ZFI_E_STATU` is a placeholder data element whose domain has fixed values.

```abap
TYPES: BEGIN OF ty_status,
         statu      TYPE zfi_e_statu,
         statu_text TYPE ddfixvalue-ddtext,
       END OF ty_status.
TYPES tt_status TYPE STANDARD TABLE OF ty_status WITH EMPTY KEY.

DATA et_data TYPE tt_status.

DATA(lt_fixed_values) = CAST cl_abap_elemdescr(
  cl_abap_typedescr=>describe_by_name( 'ZFI_E_STATU' ) )->get_ddic_fixed_values( ).

et_data = VALUE #( FOR ls_values IN lt_fixed_values
                   ( statu = ls_values-low statu_text = ls_values-ddtext ) ).
```

The compact form above assumes the name is known to be a valid elementary DDIC type. When the name comes from configuration or user input, use the robust variant:

```abap
DATA lo_type TYPE REF TO cl_abap_typedescr.

" describe_by_name signals an unknown name via a classic exception
cl_abap_typedescr=>describe_by_name(
  EXPORTING
    p_name         = 'ZFI_E_STATU'
  RECEIVING
    p_descr_ref    = lo_type
  EXCEPTIONS
    type_not_found = 1
    OTHERS         = 2 ).
IF sy-subrc <> 0.
  RETURN. " unknown type name - handle/log as appropriate
ENDIF.

" Only elementary types (data elements) have domain fixed values
IF lo_type->kind <> cl_abap_typedescr=>kind_elem.
  RETURN.
ENDIF.

" get_ddic_fixed_values has classic exceptions of its own
DATA lt_status_values TYPE ddfixvalues.

DATA(lo_elem) = CAST cl_abap_elemdescr( lo_type ).

lo_elem->get_ddic_fixed_values(
  RECEIVING
    p_fixed_values = lt_status_values
  EXCEPTIONS
    not_found      = 1
    no_ddic_type   = 2
    OTHERS         = 3 ).
IF sy-subrc <> 0.
  RETURN. " no DDIC fixed values available - handle/log as appropriate
ENDIF.

et_data = VALUE #( FOR ls_status IN lt_status_values
                   ( statu = ls_status-low statu_text = ls_status-ddtext ) ).
```

**Common mistakes / notes**

- **Unknown name → runtime error.** `describe_by_name` raises the classic exception `TYPE_NOT_FOUND` for a name that does not exist. In the compact form it is not handled, so it ends in a runtime error. Use the `EXCEPTIONS` variant shown above.
- **Non-elementary name → `CX_SY_MOVE_CAST_ERROR`.** If the name resolves to a structure, table type or class, the `CAST cl_abap_elemdescr( ... )` fails. Check `kind` first (as above) or catch the exception.
- **Elementary is not the same as DDIC.** A built-in type such as `i` passes the `kind` check but is not a DDIC type, so `get_ddic_fixed_values` raises `NO_DDIC_TYPE` (or `NOT_FOUND` when no fixed values can be read). In the compact form these are not handled either, so they again end in a runtime error.
- **Intervals are silently truncated.** A domain fixed value can be an interval (`option = 'BT'` with a `high` value). Mapping only `low` drops the upper bound without warning — map `high` as well, or handle `BT` rows explicitly, if the domain uses intervals.
- **Texts are language-dependent.** `ddtext` is returned in the logon language by default; `get_ddic_fixed_values` has an optional language parameter if you need a different one. Check the method signature in your system for the exact parameter details.

> **Lifecycle:** reading `DD07L`/`DD07T` directly with `SELECT`, or calling the function module `DD_DOMVALUES_GET`, is `LEGACY / HISTORICAL REFERENCE`. You will meet both in existing code; prefer RTTS in new code.

## ✅ Best Practices

- Prefer `string` for text of unknown/variable length; use fixed `c`/`n` types only when the length is business-defined (e.g., document number).
- Use `CORRESPONDING #( )` instead of field-by-field `MOVE` statements when converting between similar structures.
- Always double check decimal places (`DECIMALS`) for `p` type fields dealing with currency/quantity to avoid rounding bugs.

## ⚠️ Common Mistakes

- Comparing an ALPHA-converted key (with leading zeros) to a raw user-input value without converting both sides consistently.
- Using `c` type for numbers that need arithmetic — use `n` only for numeric-looking IDs, never for calculations.
- Forgetting `CONDENSE` before string comparisons/concatenations, leading to subtle whitespace bugs.

## 🎤 Interview Tips

- Be able to explain the difference between `c`, `n`, `string`, and when to use each.
- Know what `CORRESPONDING #( )` does and how it differs from `MOVE-CORRESPONDING`.
- Explain what the `ALPHA` conversion exit does and why it matters for SAP key fields (e.g., material number, document number).

## 🔗 Related Chapters

- [03-Variables](../03-Variables/README.md)
- [07-Internal-Tables](../07-Internal-Tables/README.md)
- [Examples/String-Functions.md](../Examples/String-Functions.md)
