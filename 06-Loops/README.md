# 06 — Loops

## 📖 Introduction

ABAP offers several looping constructs: `DO`, `WHILE`, and — most importantly for internal tables — `LOOP AT`, including powerful modern extensions like `GROUP BY`. This chapter also covers `COLLECT` (aggregating values into a table) and `RANGES`/`SELECT-OPTIONS`-style range tables, which are frequently used together with loops to filter data.

## 🔂 DO ... TIMES

```abap
DO 10 TIMES.
  SELECT SINGLE * FROM aufk
    INTO data(ls_aufk)
    WHERE aufnr = gt_data-aufnr.

  IF sy-subrc = 0.
    UPDATE aufk FROM ls_aufk.
    EXIT.
  ENDIF.
ENDDO.
```
> 🧠 `DO n TIMES` is commonly used for **retry logic** (as above) or generating a fixed number of iterations. Use `EXIT` to break out early once the condition is satisfied.

## 🔁 LOOP AT — the Workhorse

```abap
LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<fs_data>) WHERE value IS NOT INITIAL.
  AT NEW row.
  ENDAT.

  CASE <fs_data>-value.
    WHEN '03'.
      CLEAR <fs_data>.
  ENDCASE.
ENDLOOP.

" Loop with a range of indexes
LOOP AT lt_data REFERENCE INTO DATA(ls_data) FROM 1 TO ls_attribute-size.
  APPEND VALUE #( name = ls_data->name ) TO lt_tags.
  CLEAR ls_data->name.
ENDLOOP.
```

> ✅ **Tip:** Prefer `ASSIGNING FIELD-SYMBOL(<fs>)` or `REFERENCE INTO` over `INTO ls_data` when you plan to **modify** the current row — it avoids an extra `MODIFY` statement and is more performant since no copy is made.

## 🧮 LOOP ... GROUP BY

Modern ABAP allows grouping directly in a `LOOP`, replacing the classical "control break" (`AT NEW` / `AT END OF`) pattern for many use cases:

```abap
DATA(lt_group_data) = VALUE spfli_tab( ).

SELECT * FROM spfli
  INTO TABLE @DATA(lt_data).

LOOP AT lt_data INTO DATA(ls_data)
     GROUP BY ( carrier   = ls_data-carrid
                city_from = ls_data-cityfrom ) ASCENDING
     ASSIGNING FIELD-SYMBOL(<fs_data>).

  CLEAR lt_group_data.

  LOOP AT GROUP <fs_data> ASSIGNING FIELD-SYMBOL(<fsg_data>).
    lt_group_data = VALUE #( BASE lt_group_data
                             ( <fsg_data> ) ).
  ENDLOOP.

  cl_demo_output=>write( lt_group_data ).
ENDLOOP.

cl_demo_output=>display( ).
```

Counting members per group and building a display text is a very common reporting requirement:

```abap
" Counting per group with a nested LOOP ... TRANSPORTING NO FIELDS
LOOP AT lt_container_types INTO DATA(ls_container_type) GROUP BY ( container_type = ls_container_type-container_type ).
  CLEAR lv_container_type_count.

  LOOP AT lt_container_types TRANSPORTING NO FIELDS WHERE container_type = ls_container_type-container_type.
    lv_container_type_count += 1.
  ENDLOOP.

  READ TABLE lt_cont_type_txt INTO DATA(ls_cont_type_txt) WITH KEY domvalue_l = ls_container_type-container_type.
  IF sy-subrc = 0.
    ls_data-container_type_txt = |{ lv_container_type_count }*{ ls_cont_type_txt-ddtext },{ ls_data-container_type_txt }|.
  ENDIF.
ENDLOOP.

" Cleaner alternative using the built-in GROUP SIZE
DATA lt_parts TYPE TABLE OF string.

LOOP AT lt_container_types INTO DATA(ls_container_type)
     GROUP BY ( container_type = ls_container_type-container_type
                size           = GROUP SIZE )
     ASCENDING WITHOUT MEMBERS INTO DATA(ls_group).

  READ TABLE lt_cont_type_txt INTO DATA(ls_cont_type_txt) WITH KEY domvalue_l = ls_group-container_type.
  IF sy-subrc = 0.
    APPEND |{ ls_group-size }*{ ls_cont_type_txt-ddtext }| TO lt_parts.
  ENDIF.
ENDLOOP.

ls_data-container_type_txt = concat_lines_of( table = lt_parts
                                              sep   = `, ` ).
```

> 💡 `GROUP SIZE` (second example) directly returns the number of members in each group — no manual counting loop needed. Prefer it over the manual `TRANSPORTING NO FIELDS` counting pattern when available (7.40 SP08+).

## ➕ COLLECT — Aggregating Rows

`COLLECT` adds a row to a table, but if a row with the **same key fields** already exists, it **sums the numeric fields** instead of appending a duplicate.

```abap
DATA: BEGIN OF ty_collect,
        key  TYPE c LENGTH 10,
        num1 TYPE n LENGTH 2,
        num2 TYPE i,
      END OF ty_collect.
DATA lt_table TYPE TABLE OF ty_collect.

DATA(ls_table) = VALUE ty_collect( key  = 'First'
                                   num1 = '20'
                                   num2 = 30 ).
COLLECT ls_table INTO lt_table.

ls_table = VALUE #( key  = 'First'
                    num1 = '20'
                    num2 = 15 ).
COLLECT ls_table INTO lt_table. " num2 becomes 45 for key = 'First'

ls_table = VALUE #( key  = 'Second'
                    num1 = '20'
                    num2 = 15 ).
COLLECT ls_table INTO lt_table. " new row, key = 'Second'
```

A very common real-world pattern: summing delivery item quantities per material inside a loop.

```abap
DATA lt_data TYPE TABLE OF zsm_s_test.

LOOP AT it_lips INTO DATA(ls_lips).
  DATA(lt_data_line) = VALUE zsm_s_test( matnr = ls_lips-matnr
                                         item  = 1 ).
  COLLECT lt_data_line INTO lt_data.
ENDLOOP.
```

> ⚠️ **Warning:** `COLLECT` only sums fields that are **not part of the key**; all key fields must match exactly for rows to be merged. It also does not work well with tables that have a non-unique/sorted key of a certain kind — check the table's key definition first.

## 🎯 Range Tables (`RANGES` / `SELECT-OPTIONS`)

A range table (`sign`, `option`, `low`, `high`) is the classic way to build dynamic filter conditions for `WHERE ... IN`.

```abap
" Simple range table type
DATA lr_charg TYPE RANGE OF lqua-charg.

" Custom range types
TYPES: ty_tt_mncod TYPE RANGE OF qmsm-mncod,
       ty_tt_objnr TYPE RANGE OF qmsm-objnr.

DATA(lr_mncod) = VALUE ty_tt_mncod( sign = 'I' option = 'EQ' ( low = '1000' ) ( low = '1001' ) ( low = '1002' ) ).
DATA(lr_objnr) = VALUE ty_tt_objnr( FOR ls_jest IN lt_jest ( sign = 'I' option = 'EQ' low = ls_jest-objnr ) ).

" Appending to a range table
APPEND VALUE #( sign = 'I' option = 'EQ' low = iv_data high = iv_data ) TO lr_charg.

" Single-value declaration
lr_charg = VALUE #( ( sign = 'I' option = 'EQ' low = iv_data ) ).

" Multi-value declaration (common header + varying LOW)
lr_charg = VALUE #(  sign = 'I' option = 'EQ' ( low = iv_data1 ) ( low = iv_data2 ) ).

" Building a range from an internal table with FOR
DATA(lr_matnr) = VALUE range_t_matnr( FOR ls_data IN lt_data ( low = ls_data-matnr sign = 'I' option = 'EQ' )
                                                             ( low = ls_data-value sign = 'I' option = 'EQ' ) ).

" Building a range with SORT + removing duplicates
DATA lr_ref_key TYPE RANGE OF bkpf-awkey.

lr_ref_key  = VALUE #( FOR ls_alv IN ct_alv ( sign = 'I' option = 'EQ' low = ls_alv-vbeln_vf ) ).

SORT lr_ref_key ASCENDING BY low.
DELETE ADJACENT DUPLICATES FROM lr_ref_key COMPARING low.

" Building a range directly from a SELECT
SELECT 'I' AS sign,
       'EQ' AS option,
       aufnr AS low,
       @space AS high
  FROM zsm_t_aufnr
  INTO TABLE @lr_aufnr.
```

Use the resulting range table in a `WHERE` clause:

```abap
SELECT * FROM mara
  INTO TABLE @DATA(lt_mara)
  WHERE matnr IN @lr_matnr.
```

## ✅ Best Practices

- Always `SORT` + `DELETE ADJACENT DUPLICATES` a range table built via `FOR`/loop before using it in a `WHERE ... IN`, especially for large tables — duplicate ranges hurt SQL performance.
- Prefer `LOOP ... GROUP BY ... GROUP SIZE` over manual counting loops for readability and (usually) performance.
- Use `ASSIGNING`/`REFERENCE INTO` in loops that modify data; use `INTO` (a copy) only when you need a safe, independent copy.

## ⚠️ Common Mistakes

- Modifying the loop's work area when using `LOOP ... INTO` (a copy) and expecting the source table to change — it won't; you need `MODIFY` or `ASSIGNING`.
- Building range tables without `SIGN`/`OPTION`, causing a runtime error or unexpected filter behavior.
- Forgetting that `COLLECT` requires matching **all non-summed fields** exactly — a tiny difference (e.g., trailing space) creates a new row instead of aggregating.

## 🎤 Interview Tips

- Explain the difference between `LOOP ... INTO`, `LOOP ... ASSIGNING`, and `LOOP ... REFERENCE INTO`.
- Be ready to explain how `COLLECT` decides whether to sum or append a new row (key fields vs. numeric fields).
- Know the structure of a range table (`sign`, `option`, `low`, `high`) and common `option` values (`EQ`, `BT`, `CP`, `NE`).

## 🔗 Related Chapters

- [07-Internal-Tables](../07-Internal-Tables/README.md)
- [08-Open-SQL](../08-Open-SQL/README.md) — using range tables in `WHERE ... IN`
- [19-Performance](../19-Performance/README.md)
