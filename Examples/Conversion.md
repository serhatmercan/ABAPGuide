# Conversion Patterns

## 📖 Introduction

A grab-bag of frequently needed conversion patterns beyond the core `ALPHA`/`CONV`/`CORRESPONDING` basics already covered in [02-Data-Types](../02-Data-Types/README.md).

## 🔢 ALPHA Conversion via a Data Element Constructor

```abap
DATA lv_external TYPE string VALUE '12345'.
DATA lv_internal TYPE string VALUE '000000000000012345'.

" ALPHA = IN  : external/display form -> internal form (pads leading zeros)
DATA(lv_padded)   = |{ lv_external ALPHA = IN }|.

" ALPHA = OUT : internal form -> external/display form (strips leading zeros)
DATA(lv_stripped) = |{ lv_internal ALPHA = OUT }|.

" NEW <type>( ) creates an anonymous DATA OBJECT and returns a reference to it
DATA(lr_docno) = NEW /scdl/dl_docno_int( CONV #( lv_padded ) ).
```

## 🧩 CORRESPONDING with BASE

```abap
TYPES: BEGIN OF ty_viqmel,
         notif_no    TYPE char10,
         notif_type  TYPE char2,
         description TYPE char40,
       END OF ty_viqmel.

DATA ls_viqmel TYPE ty_viqmel.
DATA ls_data   TYPE ty_viqmel.

ls_viqmel = VALUE ty_viqmel( notif_no    = '0000001234'
                             notif_type  = 'M1'
                             description = 'Initial Notification' ).
ls_data   = VALUE ty_viqmel( notif_type  = 'M2'
                             description = 'Updated Notification' ).

" BASE supplies the starting values; the source then overwrites EVERY
" identically-named component - including with initial values.
" Here notif_no is initial in ls_data, so it is CLEARED in the result.
ls_viqmel = CORRESPONDING #( BASE ( ls_viqmel ) ls_data ).
```

> ⚠️ **`CORRESPONDING #( BASE ( a ) b )` is not a "merge non-initial fields" operator.** It starts from `a` and then assigns *all* matching components from `b`, initial ones included. `BASE` is useful when the source structure has **fewer components** than the target — the extra target components keep their values. If you genuinely want "only overwrite where the source has a value", write that condition explicitly:
> ```abap
> IF ls_data-notif_no IS NOT INITIAL.
>   ls_viqmel-notif_no = ls_data-notif_no.
> ENDIF.
> ```

## ⏱️ Timestamp ↔ Date/Time Conversion

```abap
DATA lv_timestamp TYPE timestampl.

" Date + time -> timestamp
CONVERT DATE sy-datum TIME sy-uzeit
        INTO TIME STAMP lv_timestamp TIME ZONE sy-zonlo.

" Timestamp -> date + time, with inline declaration of the targets
CONVERT TIME STAMP lv_timestamp TIME ZONE sy-zonlo
        INTO DATE DATA(lv_datum) TIME DATA(lv_time).
```
> 💡 This is the standard conversion used when a UI/Gateway layer sends a `timestampl` value (for example `20240524131025.8750000`) that has to become a plain date on the ABAP side.

## 🔄 Explicit Type Conversion (`CONV`)

```abap
DATA(lv_quantity) = CONV int4( ls_data-value ).
DATA(lv_posnr)    = CONV zsm_e_posnr( '000010' ).
DATA(ls_target)   = CORRESPONDING zsm_t_data( ls_source ).
```

## 🧱 `CONV` in a Parameter Position

```abap
" CONV # works here because the target type comes from the parameter's type
lo_validator->check_appointment( iv_person_id = CONV #( ls_order-person_id ) ).
```

## ✅ Best Practices

- Prefer `|{ value ALPHA = IN/OUT }|` (string template) over the classical `CONVERSION_EXIT_ALPHA_INPUT/OUTPUT` function module call in new code — same result, less overhead.
- Use `CORRESPONDING` to map structures instead of long field-by-field assignments — but read the `BASE` note above before assuming it merges.
- Always specify `TIME ZONE` explicitly in `CONVERT ... TIME STAMP` — omitting it silently uses the wrong zone in multi-time-zone landscapes.
- Use `CONV #( )` where the target type is derivable from the context (a parameter, a typed assignment) and an explicit `CONV <type>( )` where it is not.

## ⚠️ Common Mistakes

- Applying `ALPHA = IN` twice (double padding), or mixing `IN`/`OUT` directions inconsistently across a codebase.
- Expecting `CORRESPONDING #( BASE ( a ) b )` to skip initial source components. It does not.
- Forgetting `TIME ZONE` in timestamp conversions, causing off-by-hours bugs.
- Using `CONV #( '' )` on a data element without checking whether an initial value is valid for that domain.

## 🎤 Interview & Review Checkpoints

- Explain what the `ALPHA` conversion exit does and why SAP key fields (material number, document number) use it.
- Explain exactly what `CORRESPONDING #( BASE ( ... ) ... )` does to components that are initial in the source.
- Be ready to explain the difference between `CONV`, `CORRESPONDING`, and a conversion-exit function module — when is each the right tool?

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md)
- [09-Modularization](../09-Modularization/README.md)
