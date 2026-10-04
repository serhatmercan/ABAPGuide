# Conversion Patterns

> **Lifecycle:** `CURRENT / RECOMMENDED`. Older forms you will still meet are labelled where they appear. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

A grab-bag of frequently needed conversion patterns beyond the core `ALPHA`/`CONV`/`CORRESPONDING` basics already covered in [02-Data-Types](../02-Data-Types/README.md).

## 🔢 ALPHA Conversion via a Data Element Constructor

> 📝 **Contextual snippet** — `zsm_e_document_id` is a placeholder character-like data element.

```abap
DATA external_value TYPE string VALUE '12345'.
DATA internal_value TYPE string VALUE '000000000000012345'.
DATA document_id    TYPE c LENGTH 10 VALUE '12345'.

" ALPHA = IN  : external/display form -> internal form (pads leading zeros).
" A string has no fixed length, so give one with WIDTH
DATA(padded_value) = |{ external_value ALPHA = IN WIDTH = 18 }|.     " 000000000000012345

" A fixed-length field is padded to its own length
DATA(padded_id) = |{ document_id ALPHA = IN }|.                        " 0000012345

" ALPHA = OUT : internal form -> external/display form (strips leading zeros)
DATA(stripped_value) = |{ internal_value ALPHA = OUT }|.

" NEW <type>( ) creates an anonymous DATA OBJECT and returns a reference to it
DATA(document_id_ref) = NEW zsm_e_document_id( padded_id ).
```

> ⚠️ **`ALPHA = IN` on a `string` adds no zeros by itself.** According to the ABAP Keyword Documentation, the result length is the `WIDTH` value, the length of a fixed-length target the template is assigned to, or otherwise the length of the operand. For the five-character string `'12345'` that is five characters, so nothing is padded.

## 🧩 CORRESPONDING with BASE

```abap
TYPES: BEGIN OF notification,
         notif_no    TYPE char10,
         notif_type  TYPE char2,
         description TYPE char40,
       END OF notification.

DATA notification_data TYPE notification.
DATA change_data       TYPE notification.

notification_data = VALUE notification( notif_no    = '0000001234'
                                        notif_type  = 'T1'
                                        description = 'Initial Notification' ).
change_data       = VALUE notification( notif_type  = 'T2'
                                        description = 'Updated Notification' ).

" BASE supplies the starting values; the source then overwrites EVERY
" identically-named component - including with initial values.
" Here notif_no is initial in change_data, so it is CLEARED in the result.
notification_data = CORRESPONDING #( BASE ( notification_data ) change_data ).
```

> ⚠️ **`CORRESPONDING #( BASE ( a ) b )` is not a "merge non-initial fields" operator.** It starts from `a` and then assigns *all* matching components from `b`, initial ones included. `BASE` is useful when the source structure has **fewer components** than the target — the extra target components keep their values. If you genuinely want "only overwrite where the source has a value", write that condition explicitly:
> ```abap
> IF change_data-notif_no IS NOT INITIAL.
>   notification_data-notif_no = change_data-notif_no.
> ENDIF.
> ```

## ⏱️ Timestamp ↔ Date/Time Conversion

```abap
DATA time_stamp TYPE timestampl.

" Date + time -> timestamp. A TIMESTAMPL target gets zero fractions of a second;
" an inline declaration here would be of type TIMESTAMP
CONVERT DATE sy-datum TIME sy-uzeit
        INTO TIME STAMP time_stamp TIME ZONE sy-zonlo.

" Timestamp -> date + time, with inline declaration of the targets
CONVERT TIME STAMP time_stamp TIME ZONE sy-zonlo
        INTO DATE DATA(date) TIME DATA(time).
```
> 💡 This is the standard conversion used when a UI/Gateway layer sends a `timestampl` value (for example `20240524131025.8750000`) that has to become a plain date on the ABAP side.

## 🔄 Explicit Type Conversion (`CONV`)

> 📝 **Contextual snippet** — `change_data` with a component `value`, `source`, the placeholder data element `zsm_e_posnr` and the placeholder structure `zsm_s_target` are assumed.

```abap
DATA(quantity)    = CONV int4( change_data-value ).
DATA(item_number) = CONV zsm_e_posnr( '000010' ).
DATA(target)      = CORRESPONDING zsm_s_target( source ).
```

## 🧱 `CONV` in a Parameter Position

> 📝 **Contextual snippet** — `validator` and `order` are assumed; `check_appointment` has a completely typed parameter `person_id`.

```abap
" CONV # works here because the target type comes from the parameter's type
validator->check_appointment( person_id = CONV #( order-person_id ) ).
```

## ✅ Best Practices

- Prefer `|{ value ALPHA = IN/OUT }|` (string template) over the classical `CONVERSION_EXIT_ALPHA_INPUT/OUTPUT` function module call in new code — give the length with `WIDTH` or a fixed-length operand, since a string is not padded by itself.
- Use `CORRESPONDING` to map structures instead of long field-by-field assignments — but read the `BASE` note above before assuming it merges.
- Always specify `TIME ZONE` explicitly in `CONVERT ... TIME STAMP` — omitting it silently uses the wrong zone in multi-time-zone landscapes.
- Use `CONV #( )` where the target type is derivable from the context (a parameter, a typed assignment) and an explicit `CONV <type>( )` where it is not.

## ⚠️ Common Mistakes

- Applying `ALPHA = IN` twice (double padding), or mixing `IN`/`OUT` directions inconsistently across a codebase.
- Expecting `ALPHA = IN` to pad a `string` without `WIDTH`.
- Expecting `CORRESPONDING #( BASE ( a ) b )` to skip initial source components. It does not.
- Forgetting `TIME ZONE` in timestamp conversions, causing off-by-hours bugs.
- Using `CONV #( '' )` on a data element without checking whether an initial value is valid for that domain.

## 🎤 Interview & Review Checkpoints

- Explain what the `ALPHA` conversion exit does and why SAP key fields (material number, document number) use it.
- Explain exactly what `CORRESPONDING #( BASE ( ... ) ... )` does to components that are initial in the source.
- Be ready to explain the difference between `CONV`, `CORRESPONDING`, and a conversion-exit function module — when is each the right tool?

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md) — `CONV`, `CORRESPONDING` and type conversions
- [09-Modularization](../09-Modularization/README.md) — conversion exits
- [Date-Time.md](Date-Time.md) — date and time formatting
