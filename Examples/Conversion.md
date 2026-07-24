# Conversion Patterns

## 📖 Introduction

A grab-bag of frequently needed conversion patterns beyond the core `ALPHA`/`CONV`/`CORRESPONDING` basics already covered in [02-Data-Types](../02-Data-Types/README.md).

## 🔢 ALPHA Conversion via a Data Element Constructor

```abap
DATA lv_no TYPE /scdl/dl_docno_int.

lv_in  = '12345'.
lv_out = '00000000000000000000000012345'.

DATA(lrd_in)  = NEW /scdl/dl_docno_int( CONV #( |{ lv_in ALPHA = IN }| ) ).
DATA(lrd_out) = NEW /scdl/dl_docno_int( CONV #( |{ lv_out ALPHA = OUT }| ) ).
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

" Merge ls_data's non-initial fields on top of ls_viqmel's existing values
ls_viqmel = CORRESPONDING #( BASE ( ls_viqmel ) ls_data ).
```

## ⏱️ Timestamp ↔ Date/Time Conversion

```abap
DATA lv_timestamp TYPE timestampl.
DATA lv_datum     TYPE datum.
DATA lv_time      TYPE tims.

CONVERT DATE sy-datum TIME sy-uzeit INTO TIME STAMP lv_timestamp TIME ZONE sy-zonlo.
CONVERT TIME STAMP lv_timestamp TIME ZONE sy-zonlo INTO DATE lv_datum TIME lv_time.
CONVERT TIME STAMP lv_timestamp TIME ZONE sy-zonlo INTO DATE DATA(lv_datum) TIME DATA(lv_time).
```
> 💡 This is the standard conversion used when a UI/Gateway layer sends an OData `Edm.DateTime`/`timestampl` value (e.g., `20240524131025.8750000`) that needs to become a plain `sy-datum`-style date on the ABAP side.

## 🔄 Explicit Type Conversion (`CONV`)

```abap
DATA(lv_data)  = CONV int4( ls_data-value ).
DATA(lv_posnr) = CONV zsm_e_posnr( '' ).
DATA(ls_data)  = CORRESPONDING zsm_t_data( ls_xdata ).
```

## 🧮 Float Conversion

```abap
CALL FUNCTION 'C14W_NUMBER_CHAR_CONVERSION'
  EXPORTING i_float = lv_float
  IMPORTING e_dec   = lv_data.
```

## 🧱 Class-Based Conversion Wrapper

```abap
check_appointment( EXPORTING iv_tc_no = CONV #( ls_vbak-driver_tc ) ).
```

## ✅ Best Practices

- Prefer `|{ value ALPHA = IN/OUT }|` (string template) over the classical `CONVERSION_EXIT_ALPHA_INPUT/OUTPUT` function module call for new code — same result, less overhead.
- Use `CORRESPONDING #( BASE ( ... ) ... )` instead of manual field-by-field `MOVE`/`IF NOT INITIAL` merging logic when combining two similar structures.
- Always specify `TIME ZONE` explicitly in `CONVERT ... TIME STAMP` statements — omitting it can silently use the wrong zone in multi-time-zone landscapes.

## ⚠️ Common Mistakes

- Applying `ALPHA = IN` twice (double-padding) or mixing `IN`/`OUT` directions inconsistently across a codebase.
- Forgetting `TIME ZONE` in timestamp conversions, causing off-by-hours bugs for internationally used systems.
- Using `CONV #( '' )` on a data element without checking whether an initial/empty value is actually valid for that domain.

## 🎤 Interview Tips

- Explain what the `ALPHA` conversion exit does and why SAP key fields (material number, document number) use it.
- Be ready to explain the difference between `CONV`, `CORRESPONDING`, and a conversion exit function module — when is each the right tool?

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md)
- [09-Modularization](../09-Modularization/README.md)
