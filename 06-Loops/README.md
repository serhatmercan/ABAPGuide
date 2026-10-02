# 06 — Loops

## 📖 Introduction

ABAP offers several looping constructs: `DO`, `WHILE`, and — most importantly for internal tables — `LOOP AT`, including powerful modern extensions like `GROUP BY`. This chapter also covers `COLLECT` (aggregating values into a table) and `RANGES`/`SELECT-OPTIONS`-style range tables, which are frequently used together with loops to filter data.

## 🔂 DO ... TIMES

`DO n TIMES` runs a block a fixed number of times. Its two classic uses are generating a fixed number of iterations and **bounded retry** — attempting an operation that may fail for a transient reason, and giving up after `n` attempts.

```abap
" Bounded retry: attempt an operation that may fail transiently.
" resource->try_reserve( ) is a placeholder for whatever operation
" you are retrying (a lock attempt, a queue slot, an external call).
CONSTANTS max_attempts TYPE i VALUE 3.

DATA(is_reserved) = abap_false.

DO max_attempts TIMES.
  is_reserved = resource->try_reserve( resource_key = resource_key ).

  IF is_reserved = abap_true.
    EXIT.                                   " success — stop retrying
  ENDIF.

  WAIT UP TO 1 SECONDS.                     " back off before the next attempt
ENDDO.

IF is_reserved = abap_false.
  " all attempts exhausted — handle as a business error, do not continue silently
ENDIF.
```

> 🧠 **Retry pattern notes.** Always bound the number of attempts (`max_attempts`), always `EXIT` on success, and always handle the "all attempts failed" case explicitly. `sy-index` holds the current iteration number inside `DO`, which is useful for logging the attempt count.

> ⚠️ **Do not use a retry loop to write directly to SAP standard application tables.** Directly updating SAP standard application tables with `UPDATE` / `MODIFY` / `DELETE` bypasses the application's business logic, validations and status handling, and should not be presented as a normal extension technique. Prefer the supported API or business interface appropriate to the target object — see [15-BAPIs](../15-BAPIs/README.md). Direct DML in this guide is always shown against **custom (Z) tables** you own.

## 🔁 LOOP AT — the Workhorse

```abap
LOOP AT entries ASSIGNING FIELD-SYMBOL(<entry>) WHERE value IS NOT INITIAL.
  CASE <entry>-value.
    WHEN '03'.
      CLEAR <entry>.
  ENDCASE.
ENDLOOP.

" Loop with a range of indexes
LOOP AT entries REFERENCE INTO DATA(entry_ref) FROM 1 TO attribute-size.
  APPEND VALUE #( name = entry_ref->name ) TO tags.
  CLEAR entry_ref->name.
ENDLOOP.
```

> ✅ **Tip:** Prefer `ASSIGNING FIELD-SYMBOL(<line>)` or `REFERENCE INTO` over `INTO line` when you plan to **modify** the current row — it avoids an extra `MODIFY` statement and is more performant since no copy is made.

### Control Breaks (`AT NEW` / `AT END OF`)

`AT ... ENDAT` blocks detect *control breaks* — the point where the value of a leading group of fields changes.

```abap
" Classic control-break processing.
" Prerequisites: the table must be SORTED by the control field, and the
" LOOP must use INTO a work area.
SORT orders BY plant order_no.

LOOP AT orders INTO DATA(order).
  AT NEW plant.
    WRITE: / 'Plant:', order-plant.
  ENDAT.

  WRITE: / order-order_no, order-quantity.

  AT END OF plant.
    WRITE: / 'Subtotal for plant', order-plant.
  ENDAT.
ENDLOOP.
```

> ⚠️ **Two prerequisites that are easy to miss.**
> 1. The table must be **sorted by the control field** (and by every field to its left in the structure). `AT NEW f` triggers whenever `f` *or any field before it* changes — on an unsorted table you get spurious breaks.
> 2. **Do not combine `AT` with a restricting `WHERE` condition** on the same `LOOP`. The ABAP documentation states that no restricting condition should be specified, because rows filtered out by `WHERE` can suppress the group break entirely and produce unexpected results (the extended syntax check flags this). Filter the table *before* the loop instead.
>
> Note that `ASSIGNING` / `REFERENCE INTO` **are** permitted with `AT`; the documented caveat is only that the referenced row is not modified when entering and leaving the `AT`-`ENDAT` structure.

> 💡 **Modern alternative:** `LOOP ... GROUP BY` (next section) replaces most control-break code and does not depend on the table being pre-sorted. Both remain in use — control breaks are `CLASSIC BUT STILL RELEVANT` and you will meet them constantly in existing reports; `GROUP BY` is the `CURRENT / RECOMMENDED` choice for new code.

## 🧮 LOOP ... GROUP BY

Modern ABAP allows grouping directly in a `LOOP`, replacing the classical "control break" (`AT NEW` / `AT END OF`) pattern for many use cases:

```abap
DATA(group_members) = VALUE spfli_tab( ).

SELECT * FROM spfli
  INTO TABLE @DATA(flights).

LOOP AT flights INTO DATA(flight)
     GROUP BY ( carrier   = flight-carrid
                city_from = flight-cityfrom ) ASCENDING
     ASSIGNING FIELD-SYMBOL(<flight_group>).

  CLEAR group_members.

  LOOP AT GROUP <flight_group> ASSIGNING FIELD-SYMBOL(<member>).
    group_members = VALUE #( BASE group_members
                             ( <member> ) ).
  ENDLOOP.

  cl_demo_output=>write( group_members ).
ENDLOOP.

cl_demo_output=>display( ).
```

Counting members per group and building a display text is a very common reporting requirement:

```abap
" Counting per group with a nested LOOP ... TRANSPORTING NO FIELDS
LOOP AT containers INTO DATA(container) GROUP BY ( container_type = container-container_type ).
  CLEAR container_count.

  LOOP AT containers TRANSPORTING NO FIELDS WHERE container_type = container-container_type.
    container_count += 1.
  ENDLOOP.

  READ TABLE container_type_texts INTO DATA(container_type_text) WITH KEY domvalue_l = container-container_type.
  IF sy-subrc = 0.
    summary-container_types_text = |{ container_count }*{ container_type_text-ddtext },{ summary-container_types_text }|.
  ENDIF.
ENDLOOP.

" Cleaner alternative using the built-in GROUP SIZE
DATA parts TYPE TABLE OF string.

LOOP AT containers INTO DATA(container)
     GROUP BY ( container_type = container-container_type
                size           = GROUP SIZE )
     ASCENDING WITHOUT MEMBERS INTO DATA(container_group).

  READ TABLE container_type_texts INTO DATA(container_type_text) WITH KEY domvalue_l = container_group-container_type.
  IF sy-subrc = 0.
    APPEND |{ container_group-size }*{ container_type_text-ddtext }| TO parts.
  ENDIF.
ENDLOOP.

summary-container_types_text = concat_lines_of( table = parts
                                                sep   = `, ` ).
```

> 💡 `GROUP SIZE` (second example) directly returns the number of members in each group — no manual counting loop needed. Prefer it over the manual `TRANSPORTING NO FIELDS` counting pattern.
>
> **VERSION-DEPENDENT:** `LOOP ... GROUP BY` and `GROUP SIZE` were introduced in the ABAP 7.40 generation. Confirm the exact minimum release/SP for your target system in the ABAP Keyword Documentation before relying on them.

## ➕ COLLECT — Aggregating Rows

`COLLECT` adds a row to a table, but if a row whose **non-numeric components** all match already exists, it **adds the numeric components** to that row instead of appending a duplicate.

```abap
" TYPES defines a type; DATA defines a data object. TYPE TABLE OF needs a type.
TYPES: BEGIN OF counter_line,
         key   TYPE c LENGTH 10,   " character-like -> part of the key
         group TYPE n LENGTH 2,    " numeric TEXT (n) is character-like -> ALSO part of the key
         count TYPE i,             " numeric (i) -> summed
       END OF counter_line.

DATA counters TYPE TABLE OF counter_line.

DATA(counter) = VALUE counter_line( key   = 'First'
                                    group = '20'
                                    count = 30 ).
COLLECT counter INTO counters.

counter = VALUE #( key   = 'First'
                   group = '20'
                   count = 15 ).
COLLECT counter INTO counters. " same key + group -> count becomes 45

counter = VALUE #( key   = 'Second'
                   group = '20'
                   count = 15 ).
COLLECT counter INTO counters. " new row, key = 'Second'
```

A very common real-world pattern: summing delivery item quantities per material inside a loop.

```abap
DATA material_counts TYPE TABLE OF zsm_s_material_count.

LOOP AT delivery_items INTO DATA(delivery_item).
  DATA(material_count) = VALUE zsm_s_material_count( matnr = delivery_item-matnr
                                                     item  = 1 ).
  COLLECT material_count INTO material_counts.
ENDLOOP.
```

> ⚠️ **How `COLLECT` decides.** The key is formed from **all character-like (non-numeric) components**; only genuinely numeric components (`i`, `p`, `f`, `decfloat`) are added up. A `TYPE n` component looks numeric but is character-like, so it becomes part of the key rather than being summed — a frequent surprise. All key components must match **exactly** (a trailing space creates a new row).
>
> `COLLECT` is intended for standard tables with a default key, and for sorted/hashed tables with a **unique** key. Check the table's key definition before using it. **NEEDS OFFICIAL VERIFICATION** for the precise list of permitted table categories in your target release — see the ABAP Keyword Documentation for `COLLECT`.

## 🎯 Range Tables (`RANGES` / `SELECT-OPTIONS`)

A range table (`sign`, `option`, `low`, `high`) is the classic way to build dynamic filter conditions for `WHERE ... IN`.

```abap
" Simple range table type
DATA batch_range TYPE RANGE OF lqua-charg.

" Custom range types
TYPES: activity_code_range TYPE RANGE OF qmsm-mncod,
       object_number_range TYPE RANGE OF qmsm-objnr.

DATA(activity_codes) = VALUE activity_code_range( sign = 'I' option = 'EQ' ( low = '1000' ) ( low = '1001' ) ( low = '1002' ) ).
DATA(object_numbers) = VALUE object_number_range( FOR object_status IN object_statuses ( sign = 'I' option = 'EQ' low = object_status-objnr ) ).

" Appending to a range table
APPEND VALUE #( sign = 'I' option = 'EQ' low = batch high = batch ) TO batch_range.

" Single-value declaration
batch_range = VALUE #( ( sign = 'I' option = 'EQ' low = batch ) ).

" Multi-value declaration (common header + varying LOW)
batch_range = VALUE #(  sign = 'I' option = 'EQ' ( low = first_batch ) ( low = second_batch ) ).

" Building a range from an internal table with FOR
DATA(material_range) = VALUE range_t_matnr( FOR material IN materials ( low = material-matnr sign = 'I' option = 'EQ' )
                                                                       ( low = material-value sign = 'I' option = 'EQ' ) ).

" Building a range with SORT + removing duplicates
DATA reference_keys TYPE RANGE OF bkpf-awkey.

reference_keys = VALUE #( FOR alv_line IN alv_lines ( sign = 'I' option = 'EQ' low = alv_line-vbeln_vf ) ).

SORT reference_keys ASCENDING BY low.
DELETE ADJACENT DUPLICATES FROM reference_keys COMPARING low.

" Building a range directly from a SELECT
DATA order_range TYPE RANGE OF aufk-aufnr.

SELECT 'I'   AS sign,
       'EQ'  AS option,
       aufnr AS low
  FROM zsm_t_aufnr
  INTO CORRESPONDING FIELDS OF TABLE @order_range.
```

> ⚠️ **VERSION-DEPENDENT.** Literals in the SELECT list and internal tables as ABAP SQL data sources were introduced progressively across the 7.4x/7.5x releases. Check the ABAP Keyword Documentation for your target release before relying on them. `INTO CORRESPONDING FIELDS OF TABLE` is used here because the range structure has a `high` component that the SELECT list does not supply.

Use the resulting range table in a `WHERE` clause:

```abap
SELECT matnr, mtart, meins
  FROM mara
  WHERE matnr IN @material_range
  INTO TABLE @DATA(material_rows).
```

## ✅ Best Practices

- Always `SORT` + `DELETE ADJACENT DUPLICATES` a range table built via `FOR`/loop before using it in a `WHERE ... IN`, especially for large tables — duplicate ranges hurt SQL performance.
- Prefer `LOOP ... GROUP BY ... GROUP SIZE` over manual counting loops for readability and (usually) performance.
- Use `ASSIGNING`/`REFERENCE INTO` in loops that modify data; use `INTO` (a copy) only when you need a safe, independent copy.

## ⚠️ Common Mistakes

- Modifying the loop's work area when using `LOOP ... INTO` (a copy) and expecting the source table to change — it won't; you need `MODIFY` or `ASSIGNING`.
- Building range tables without `SIGN`/`OPTION`. This does **not** raise a runtime error — the row is simply not interpreted as you intended, so the filter silently returns the wrong rows. Always set both.
- Combining `AT ... ENDAT` with a `WHERE` condition on the same `LOOP`, or forgetting to `SORT` by the control field first.
- Forgetting that `COLLECT` treats every character-like component (including `TYPE n`) as part of the key — a tiny difference (e.g., a trailing space) creates a new row instead of aggregating.

## 🎤 Interview Tips

- Explain the difference between `LOOP ... INTO`, `LOOP ... ASSIGNING`, and `LOOP ... REFERENCE INTO`.
- Be ready to explain how `COLLECT` decides whether to sum or append a new row (key fields vs. numeric fields).
- Know the structure of a range table (`sign`, `option`, `low`, `high`) and common `option` values (`EQ`, `BT`, `CP`, `NE`).

## 🔗 Related Chapters

- [07-Internal-Tables](../07-Internal-Tables/README.md)
- [08-Open-SQL](../08-Open-SQL/README.md) — using range tables in `WHERE ... IN`
- [19-Performance](../19-Performance/README.md)
