# 07 — Internal Tables & Field Symbols

## 📖 Introduction

Internal tables are ABAP's core in-memory data structure — comparable to arrays/lists in other languages, but with rich, SQL-like operations (`WHERE`, key access, aggregation). This chapter covers table type definitions, the modern `VALUE`/`REDUCE`/`FILTER`/`FOR` functional operators, and field symbols/data references for dynamic, low-overhead data access.

## 🧱 Defining Table Types

```abap
" Types & table type & internal table
TYPES:
  BEGIN OF ty_auart,
    vbeln TYPE vbak-vbeln,
    posnr TYPE vbrp-posnr,
    auart TYPE vbak-auart,
  END OF ty_auart,

  tt_auart TYPE TABLE OF ty_auart WITH KEY vbeln.

DATA gs_auart TYPE ty_auart.
DATA gt_auart TYPE tt_auart.

" Structure with INCLUDE - modern form: TYPES declares a TYPE, then DATA
" declares the table from it.
TYPES: BEGIN OF ty_data.
         INCLUDE TYPE zsm_s_insplot.
TYPES:   objnr TYPE qals-objnr,
       END OF ty_data.

DATA lt_data TYPE STANDARD TABLE OF ty_data WITH EMPTY KEY.

" LEGACY / HISTORICAL REFERENCE - the classical equivalent you will meet in
" older programs. DATA BEGIN OF ... OCCURS 0 declares a table WITH A HEADER
" LINE, where the table and its work area share one name. It is obsolete in
" ABAP Objects contexts and unavailable in ABAP Cloud - recognise it, don't
" write it.
"   DATA BEGIN OF gt_data OCCURS 0.
"           INCLUDE TYPE zsm_s_insplot.
"   DATA:   objnr TYPE qals-objnr,
"         END OF gt_data.

" Table type with a secondary sorted key for performance.
" The PRIMARY key here is the document number; the SECONDARY key gives fast
" access by material + storage location without re-sorting the table.
TYPES: BEGIN OF ty_charg,
         charg TYPE mspr-charg,
         matnr TYPE marc-matnr,
         lgort TYPE mseg-lgort,
         pspnr TYPE mspr-pspnr,
         post1 TYPE prps-post1,
       END OF ty_charg.

TYPES tt_charg TYPE STANDARD TABLE OF ty_charg
               WITH NON-UNIQUE KEY charg
               WITH NON-UNIQUE SORTED KEY matnr_lgort COMPONENTS matnr lgort.
```

> 💡 A **secondary sorted/hashed key** (`WITH ... SORTED KEY name COMPONENTS ...`) lets you do fast `READ TABLE ... WITH KEY matnr_lgort COMPONENTS ...` lookups without re-sorting the primary table — critical for performance on large tables (see [19-Performance](../19-Performance/README.md)).

## ➕ Filling Tables — APPEND, INSERT, VALUE

```abap
" Append with a field symbol to avoid an extra MODIFY
APPEND INITIAL LINE TO lt_sales_items ASSIGNING FIELD-SYMBOL(<fs_sales_item>).
<fs_sales_item>-itm_number = lv_posnr + 10.
<fs_sales_item>-material   = ls_return_item-matnr.

" VALUE with a shared header value applied to every row
lt_data = VALUE #( lgort = '1000'
                   ( mtart = 'AAAA' )
                   ( mtart = 'BBBB' ) ).

" Append corresponding lines from a differently-typed table
DATA lt_data TYPE zsm_tt_0001.
APPEND LINES OF CORRESPONDING zsm_tt_0001( lt_itab ) TO lt_data.

" Append a single corresponding structure
DATA(lt_qmsm) = VALUE crmt_rfc_viqmsm_t( ( ) ).
APPEND CORRESPONDING #( ls_qmsm ) TO lt_qmsm.

" Append a full structure / a VALUE literal
APPEND ls_data TO lt_data.
APPEND VALUE #( material = '123' ) TO lt_sales_items.

" VALUE with default (shared) parameters applied to each row
lt_data = VALUE #( refnumber = '1'
                   objectkey = 'X'
                   method    = 'CREATE'
                   ( objecttype = 'HEADER' )
                   ( objecttype = 'OPERATION' ) ).

" VALUE with an explicit table type
DATA(lt_data) = VALUE tt_auart( ( vbeln  = '1' posnr = '10' auart = 'X' )
                                ( vbeln  = '2' posnr = '20' auart = 'Y' ) ).

" Append additional rows while keeping the existing ones with BASE
lt_data[] = VALUE #( BASE lt_data[]
                     ( vbeln = '3' posnr = '10' auart = 'Z' ) ).

" Building a return-message table
DATA et_return TYPE bapiret2_t.
et_return = VALUE #( ( type = 'E' id = 'ZSM_MSG' number = '001' ) ).

" Building a table with nested corresponding tables
er_deep_entity = VALUE #( returned = abap_true
                          header   = CORRESPONDING #( ls_entity-header[] )
                          items    = CORRESPONDING #( ls_entity-items[] ) ).

" Insert a value into a specific position
INSERT VALUE #( id = '1' value = 'X' ) INTO TABLE lt_data.

INSERT VALUE #( kunnr = ''
                name1 = '' ) INTO et_altmusteriset INDEX 1.
```

## 🎯 Reading & Filtering — table expressions, FILTER, FOR

```abap
" Direct index access via a field symbol.
" ASSIGN is the ONE place a table expression sets sy-subrc instead of raising.
ASSIGN lt_itab[ 3 ] TO FIELD-SYMBOL(<fs_row>).
IF sy-subrc = 0.
  " <fs_row> is usable
ENDIF.

" Direct key access
ASSIGN lt_itab[ ernam = 'USER01'
                ersda = '20240101' ] TO FIELD-SYMBOL(<fs_by_key>).

" FOR: build a new table via projection, with a WHERE condition
DATA(lt_mara) = VALUE tt_mara( FOR ls_itab IN it_itab WHERE ( ernam EQ 'USER01' )
                               ( matnr = ls_itab-matnr ernam = ls_itab-ernam ) ).

" FOR with conditional logic (COND) per field
lt_data[] = VALUE #( FOR ls_list IN lt_list
                     ( matnr = ls_list-matnr
                       vhart = ls_list-vhart
                       ergew = COND #( WHEN ls_list-vhart = '1003'
                                       THEN CONV ergew( ls_list-veh_maxwgt - ls_list-veh_unlwgt )
                                       ELSE ls_list-ergew ) ) ).

" FOR + BASE + LET...IN: enrich existing rows with a helper lookup
lt_data = VALUE #( BASE lt_data
                       FOR ls_itab IN it_itab
                   LET ls_licence = _read_licence( iv_lictp = ls_itab-lictp
                                                   iv_licin = ls_itab-oih_licin_vf )
                   IN  ( VALUE #( BASE CORRESPONDING #( ls_itab )
                                  vbeln_vf = ls_licence-vbeln_vf
                                  zadklno  = ls_licence-zadklno ) ) ).

" FOR w/ GROUPS: build one row per distinct group value
DATA(lt_created_on) = VALUE tt_mara( FOR GROUPS grp OF ls_itab IN it_itab
                                     WHERE ( ernam EQ 'USER01' )
                                     GROUP BY ls_itab-ersda
                                     ( ersda = grp ) ).

" FOR w/ WHERE + CORRESPONDING projection using a range table
TYPES: BEGIN OF ty_licence,
         licin TYPE oihl-licin,
         lictp TYPE oihl-lictp,
         lctxt TYPE oihl-lctxt,
       END OF ty_licence.

DATA lt_licence_md  TYPE TABLE OF ty_licence.
DATA lt_licence_mdx TYPE TABLE OF ty_licence.

lt_licence_mdx = VALUE #( FOR ls_licence_md IN lt_licence_md WHERE ( licin IN ir_licence_numbers )
                          ( CORRESPONDING #( ls_licence_md ) ) ).
```

### FILTER — Building a Subset of a Table

`FILTER` returns a new table containing only the rows that match a condition. It has two variants, and one **prerequisite that is easy to miss**: the source table must have at least one **sorted or hashed key** (primary or secondary) covering the components used in the condition.

```abap
TYPES: BEGIN OF ty_row,
         ernam TYPE mara-ernam,
         matnr TYPE mara-matnr,
         mtart TYPE mara-mtart,
       END OF ty_row.

" The source table needs a sorted or hashed key for FILTER to work
TYPES tt_row TYPE STANDARD TABLE OF ty_row
             WITH EMPTY KEY
             WITH NON-UNIQUE SORTED KEY by_ernam COMPONENTS ernam.

DATA it_itab TYPE tt_row.

" Variant 1 - basic: compare a component against a value.
" Note there are no parentheses around the WHERE condition.
DATA(lt_by_value) = FILTER #( it_itab WHERE ernam = 'USER01' ).

" Variant 1 with an explicit key, and the inverted form
DATA(lt_keyed)  = FILTER #( it_itab USING KEY by_ernam WHERE ernam = 'USER01' ).
DATA(lt_except) = FILTER #( it_itab EXCEPT WHERE ernam = 'USER01' ).

" Variant 2 - filter table: keep the rows whose component appears in a
" second table. The right-hand side of WHERE refers to the FILTER TABLE,
" here via its table_line (a table of elementary values).
DATA lt_wanted_users TYPE SORTED TABLE OF mara-ernam WITH UNIQUE KEY table_line.

lt_wanted_users = VALUE #( ( 'USER01' ) ( 'USER02' ) ).

DATA(lt_by_table) = FILTER #( it_itab IN lt_wanted_users WHERE ernam = table_line ).
```

> ⚠️ **Two things to get right.**
> 1. **`IN` takes an internal table, not a type name.** `FILTER #( it_itab IN tt_row ... )` would be wrong — `tt_row` is a *type*. The filter table must be a real data object.
> 2. **The two variants have different `WHERE` forms.** The basic variant compares against a value (`WHERE ernam = 'USER01'`); the filter-table variant compares against a component of the filter table (`WHERE ernam = table_line`). You cannot mix them.
>
> `#` for the result type is fine in an inline declaration here — it is derived from the source table.

## Σ Calculations with REDUCE

`REDUCE` accumulates a single value by iterating over a table — a functional replacement for a `LOOP` + running total variable.

```abap
" Sum a quantity. The RESULT type must be wide enough for what you accumulate -
" reducing a QUAN(13,3) into TYPE i would silently truncate the decimals.
DATA(lv_total_stock) = REDUCE labst( INIT lv_sum   TYPE labst
                                     FOR  ls_mard IN lt_mard
                                     WHERE ( labst <> 0 )
                                     NEXT lv_sum   = lv_sum + ls_mard-labst ).

DATA(lv_amount) = REDUCE bstmg( INIT lv_total TYPE bstmg
                                FOR  ls_data  IN lt_data
                                WHERE ( mtart EQ 'ZSTD' AND werks EQ '1000' )
                                NEXT lv_total = lv_total + ls_data-total ).

" Counting: give the result an explicit type rather than relying on #
DATA(lv_days) = REDUCE i( INIT lv_count = 0
                          FOR  ls_day  IN is_tcurr-days
                          WHERE ( periodat BETWEEN gv_first_date AND gv_last_date )
                          NEXT lv_count = lv_count + 1 ).

" REDUCE building a formatted string, e.g. "12345 / 67890"
DATA(gv_value) = REDUCE char100( INIT lv_value TYPE char100
                                 FOR  ls_data  IN lt_data
                                 NEXT lv_value = COND char100( WHEN lv_value IS INITIAL
                                                               THEN condense( |{ ls_data-value ALPHA = OUT }| )
                                                               ELSE condense(
                                                                        |{ lv_value } / { ls_data-value ALPHA = OUT }| ) ) ).
```

## 🗺️ CORRESPONDING with MAPPING

```abap
" lo_data is an object reference, so its attribute is reached with -> , not -
lt_data = CORRESPONDING #( lo_data->values MAPPING matnr = material_no ).
```
`MAPPING target = source` lets you rename fields on the fly when the source and target structures use different field names.

## 🗑️ Deleting Rows

```abap
DELETE it_itab WHERE id = 'X' AND attribute = 'ABC'.

" Delete by date / time comparison
DELETE lt_tasks WHERE erdat > sy-datum.

DELETE lt_tasks WHERE erdat  = sy-datum
                  AND erzeit > sy-uzeit.

" Delete using a range table (NOT IN)
DELETE it_itab WHERE id NOT IN ir_data.
```

## 🔎 line_index / line_exists — Position-Based Access

```abap
DATA(lv_index) = line_index( gt_table[ vbeln = '0060000001'] ).

" Real example: reordering rows in a response table by moving one entry
IF et_entityset IS NOT INITIAL.
  DATA(lv_index_bank) = line_index( et_entityset[ header = 'Bank' ] ).
  DATA(lv_index_tax)  = line_index( et_entityset[ header = 'Tax' ] ).

  IF lv_index_tax IS NOT INITIAL.
    DATA(ls_tax) = VALUE #( et_entityset[ header = 'Tax' ] OPTIONAL ).

    DELETE et_entityset INDEX lv_index_tax.

    IF lv_index_bank IS NOT INITIAL.
      INSERT ls_tax INTO et_entityset INDEX lv_index_bank + 1.
    ELSE.
      INSERT ls_tax INTO et_entityset INDEX 1.
    ENDIF.
  ENDIF.
ENDIF.
```

## 🔄 LOOP with REFERENCE INTO and Grouping Strings

```abap
LOOP AT lt_order REFERENCE INTO DATA(lr_order).
  CASE lr_order->property.
    WHEN 'OrderNo'.
      lr_order->property = 'ORDER_NO'.
  ENDCASE.
ENDLOOP.

" Grouping rows and concatenating a text field per group
TYPES: BEGIN OF lty_invoice_material,
         file_no   TYPE zsm_e_file_no,
         materials TYPE string,
       END OF lty_invoice_material.

DATA lt_invoice_materials TYPE TABLE OF lty_invoice_material.

LOOP AT lt_invoice_sum INTO DATA(ls_invoice_sum)
     GROUP BY ( file_no = ls_invoice_sum-file_no ) ASCENDING
     INTO DATA(ls_invoice_sum_group).

  APPEND VALUE #(
      file_no   = ls_invoice_sum_group-file_no
      materials = REDUCE string( INIT lv_string = ``
                                  FOR ls_group_row IN GROUP ls_invoice_sum_group
                                 NEXT lv_string = COND string( WHEN lv_string IS INITIAL
                                                               THEN ls_group_row-material
                                                               ELSE |{ lv_string }, { ls_group_row-material }| ) ) )
      TO lt_invoice_materials.
ENDLOOP.
```

## 🧷 Field Symbols & Data References

Field symbols (`FIELD-SYMBOLS`) and data references (`TYPE REF TO data`) allow **dynamic, generic** access to data whose type isn't known until runtime — essential for generic frameworks, BAdIs, and dynamic programming.

```abap
TYPES tt_mara TYPE STANDARD TABLE OF mara WITH EMPTY KEY.

DATA lr_source     TYPE REF TO data.   " lr_ = reference, not lt_
DATA lr_line       TYPE REF TO data.
DATA lv_field_name TYPE string.
DATA lt_mara       TYPE tt_mara.

FIELD-SYMBOLS <lt_source> TYPE STANDARD TABLE.
FIELD-SYMBOLS <lt_node>   TYPE STANDARD TABLE.
FIELD-SYMBOLS <ls_data>   TYPE any.
FIELD-SYMBOLS <fs_mara>   LIKE LINE OF lt_mara.

" Dereferencing a data reference into a field symbol
ASSIGN cr_data->* TO <ls_data>.
IF <ls_data> IS NOT ASSIGNED.
  RETURN.
ENDIF.

" Dynamic component access by name (generic structure handling).
" ALWAYS check sy-subrc - the component may not exist in this structure.
ASSIGN COMPONENT lv_field_name OF STRUCTURE <ls_data> TO <lt_node>.
IF sy-subrc <> 0.
  RETURN.
ENDIF.

LOOP AT <lt_node> ASSIGNING FIELD-SYMBOL(<ls_node>).
  ASSIGN COMPONENT 'EXT_ID' OF STRUCTURE <ls_node> TO FIELD-SYMBOL(<lv_id>).
  IF sy-subrc = 0.
    DATA(lv_alpha_id) = |{ <lv_id> ALPHA = IN }|.
  ENDIF.

  ASSIGN COMPONENT 'NAME' OF STRUCTURE <ls_node> TO FIELD-SYMBOL(<lv_name>).
  IF sy-subrc = 0.
    <lv_name> = 'USER01'.
  ENDIF.
ENDLOOP.

" Appending via a field symbol
APPEND INITIAL LINE TO lt_mara ASSIGNING <fs_mara>.
<fs_mara>-matnr = '000000000000123456'.

" Insert at a specific index via a field symbol
INSERT INITIAL LINE INTO lt_mara ASSIGNING <fs_mara> INDEX 2.
<fs_mara>-matnr = '000000000000123457'.

" Creating a new anonymous data object of the same type as a table's line
ASSIGN lr_source->* TO <lt_source>.
IF sy-subrc = 0.
  CREATE DATA lr_line LIKE LINE OF <lt_source>.
ENDIF.
```

> 💡 **`UNASSIGN` is rarely necessary.** A field symbol becomes invalid when it goes out of scope. Use `UNASSIGN` when you deliberately want a later `IS ASSIGNED` check to be false — for example when reusing one field symbol across several passes. ABAP field symbols are not C pointers: you cannot end up dereferencing freed memory. The real risk is a *stale* assignment — a field symbol still pointing at a row of a table you have since modified.

## ✅ Best Practices

- Add a **secondary sorted/hashed key** to large internal tables that are read frequently by non-primary-key fields.
- Prefer `FIELD-SYMBOLS`/`REFERENCE INTO` over `INTO` (copy) when looping over large tables or when modifying rows in place — avoids unnecessary data copies.
- Use `VALUE`, `FILTER`, `FOR`, and `REDUCE` to replace multi-line procedural loops with single, declarative expressions where it improves readability.
- Give `REDUCE` a result type wide enough for what it accumulates.
- Always check `sy-subrc` after `ASSIGN` and after `ASSIGN COMPONENT`.

## ⚠️ Common Mistakes

- **Expecting a table expression to set `sy-subrc`. It does not.** `lt_itab[ key ]` raises `CX_SY_ITAB_LINE_NOT_FOUND` when there is no match. Use one of:
  - `line_exists( lt_itab[ key = ... ] )` before accessing;
  - `VALUE #( lt_itab[ key = ... ] OPTIONAL )` for an initial value, or `DEFAULT ...` for a fallback;
  - `TRY ... CATCH cx_sy_itab_line_not_found`;
  - `ASSIGN lt_itab[ key = ... ] TO <fs>` — **the one construct where a table expression sets `sy-subrc`** instead of raising.
- Reducing a packed/quantity field into an integer result and losing the decimals.
- Using `ASSIGN COMPONENT ... OF STRUCTURE` with a hardcoded field name against a generic structure without checking `sy-subrc`.
- Confusing `-` (structure component) with `->` (dereferencing an object or data reference).

## 🎤 Interview & Review Checkpoints

- Explain the difference between a **field symbol** and a **data reference**, and when each is appropriate.
- Explain what happens when a table expression finds no row — and name the one statement where `sy-subrc` is set instead.
- Be ready to explain what `FILTER`, `REDUCE`, and `FOR` do, and how they compare to writing an equivalent `LOOP`.
- Explain the prerequisite `FILTER` places on the source table.
- Know why `COLLECT` and secondary keys matter for internal table performance (see [19-Performance](../19-Performance/README.md)).

## 🔗 Related Chapters

- [06-Loops](../06-Loops/README.md)
- [08-Open-SQL](../08-Open-SQL/README.md)
- [19-Performance](../19-Performance/README.md)
