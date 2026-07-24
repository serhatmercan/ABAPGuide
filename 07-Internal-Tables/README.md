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

" Nested structure with INCLUDE (classical, header-line style, 0-based OCCURS)
DATA  BEGIN OF ty_data OCCURS 0.
        INCLUDE TYPE zqmui_s_insplot.
DATA:   objnr TYPE qals-objnr,
      END OF ty_data.

DATA lt_data TYPE TABLE OF ty_data.

" Table type with a secondary sorted key for performance
TYPES: BEGIN OF ty_charg,
         matnr LIKE marc-matnr,
         lgort TYPE mseg-lgort,
         charg TYPE mspr-charg,
         pspnr TYPE mspr-pspnr,
         post1 TYPE prps-post1,
       END OF ty_charg.

TYPES tt_charg TYPE STANDARD TABLE OF ty_charg
               WITH KEY matnr lgort
               WITH NON-UNIQUE SORTED KEY matnr_lgort COMPONENTS matnr lgort.
```

> 💡 A **secondary sorted/hashed key** (`WITH ... SORTED KEY name COMPONENTS ...`) lets you do fast `READ TABLE ... WITH KEY matnr_lgort COMPONENTS ...` lookups without re-sorting the primary table — critical for performance on large tables (see [19-Performance](../19-Performance/README.md)).

## ➕ Filling Tables — APPEND, INSERT, VALUE

```abap
" Append with a field symbol to avoid an extra MODIFY
APPEND INITIAL LINE TO lt_sales_items ASSIGNING FIELD-SYMBOL(<fs_sales_item>).
<fs_sales_item>-itm_number = lv_posnr + 10.
<fs_sales_item>-material   = zsd_iade_giris-matnr.

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
et_return = VALUE #( ( type = 'E' id = 'ZPP_000_MC' number = 001 ) ).

" Building a table with nested corresponding tables
er_deep_entity = VALUE #( returned = abap_true
                          header   = CORRESPONDING #( ls_entity-header[] )
                          items    = CORRESPONDING #( ls_entity-items[] ) ).

" Insert a value into a specific position
INSERT VALUE #( id = '1' value= 'X' ) INTO TABLE lt_data.

INSERT VALUE #( kunnr = ''
                name1 = '' ) INTO et_altmusteriset INDEX 1.
```

## 🎯 Reading & Filtering — table expressions, FILTER, FOR

```abap
" Direct index access via a field symbol
ASSIGN lt_itab[ 3 ] TO FIELD-SYMBOL(<fs_itab>).

" Direct key access
ASSIGN lt_itab[ ernam = 'SERHAT'
                ersda = '20801212' ] TO FIELD-SYMBOL(<fs_itab>).

" FILTER: build a new table containing only matching rows
DATA(lt_filter_data) = FILTER #( it_itab IN tt_itab WHERE ( ernam = 'X' ) ).

" FOR: build a new table via projection, with a WHERE condition
DATA(lt_mara) = VALUE tt_mara( FOR ls_itab IN it_itab WHERE ( ernam EQ 'SERHAT' )
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
DATA(lt_mara) = VALUE tt_mara( FOR GROUPS grp OF ls_itab IN it_itab WHERE ( ernam EQ 'SERHAT' ) GROUP BY ls_itab-ersda
                               ( ersda = grp ) ).

" FOR w/ WHERE + CORRESPONDING projection using a range table
TYPES: BEGIN OF ty_licence,
         licin TYPE oihl-licin,
         lictp TYPE oihl-lictp,
         lctxt TYPE oihl-lctxt,
       END OF ty_licence.

DATA lt_licence_md  TYPE TABLE OF ty_licence.
DATA lt_licence_mdx TYPE TABLE OF ty_licence.

lt_licence_mdx = VALUE #( FOR ls_licence_md IN lt_licence_md WHERE ( licin IN ir_adk_lic_numbers )
                          ( CORRESPONDING #( ls_licence_md ) ) ).
```

## Σ Calculations with REDUCE

`REDUCE` accumulates a single value by iterating over a table — a functional replacement for a `LOOP` + running total variable.

```abap
DATA(lv_amount) = REDUCE i( INIT i      TYPE labst
                            FOR ls_mard IN lt_mard
                            WHERE ( labst <> '' )
                            NEXT i = i + ls_mard-labst ).

DATA(lv_amount) = REDUCE bstmg( INIT lv_total TYPE bstmg
                                FOR  ls_data IN lt_data
                             WHERE ( mtart EQ 'A' AND werks EQ 'X' )
                                NEXT lv_total = lv_total + ls_data-total ).

DATA(lv_day) = REDUCE #( INIT lv_days = 0
                         FOR ls_days IN is_tcurr-days
                         WHERE ( periodat BETWEEN gv_first_date AND gv_last_date )
                         NEXT lv_days = lv_days + 1 ).

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
lt_data = CORRESPONDING #( lo_data-values MAPPING matnr = material_no ).
```
`MAPPING target = source` lets you rename fields on the fly when the source and target structures use different field names.

## 🗑️ Deleting Rows

```abap
DELETE it_itab WHERE id = 'X' AND attribute = 'ABC'.

DELETE lt_qmsm WHERE peter > sy-datum.

DELETE lt_qmsm WHERE     peter = sy-datum
                     AND petur > sy-uzeit.

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

LOOP AT lt_invoice_sum INTO DATA(ls_invoice_sum) GROUP BY ( file_no = ls_invoice_sum-file_no ) ASCENDING INTO DATA(ls_invoice_sum_group).
  APPEND VALUE #(
      file_no   = ls_invoice_sum_group-file_no
      materials = REDUCE string( INIT lv_string = ``
                                  FOR ls_invoice_sum_group_row IN GROUP ls_invoice_sum_group
                                 NEXT lv_string = COND #( WHEN lv_string IS INITIAL
                                                          THEN ls_invoice_sum_group_row-material
                                                          ELSE |{ lv_string }, { ls_invoice_sum_group_row-material }| ) ) )
         TO lt_invoice_materials.
```

## 🧷 Field Symbols & Data References

Field symbols (`FIELD-SYMBOLS`) and data references (`TYPE REF TO data`) allow **dynamic, generic** access to data whose type isn't known until runtime — essential for generic frameworks, BAdIs, and dynamic programming.

```abap
TYPES tt_mara TYPE STANDARD TABLE OF mara.

DATA lt_data TYPE REF TO data.
DATA lr_data TYPE REF TO data.
DATA lv_data TYPE string.
DATA lt_mara TYPE tt_mara.

FIELD-SYMBOLS <lt_data>     TYPE STANDARD TABLE.
FIELD-SYMBOLS <lt_node>     TYPE STANDARD TABLE.
FIELD-SYMBOLS <lv_id>       TYPE any.
FIELD-SYMBOLS <ls_data>     TYPE any.
FIELD-SYMBOLS <lfs_any_tab> TYPE ANY TABLE.
FIELD-SYMBOLS <lv_line>     TYPE REF TO data.
FIELD-SYMBOLS <fs_mara>     LIKE LINE OF lt_mara.

" Dereferencing a data reference into a field symbol
ASSIGN cr_data->* TO <ls_data>.

" Dynamic component access by name (generic structure handling)
ASSIGN COMPONENT lv_data OF STRUCTURE <ls_data> TO <lt_node>.

LOOP AT <lt_node> ASSIGNING FIELD-SYMBOL(<ls_node>).
  ASSIGN COMPONENT 'EXT_ID' OF STRUCTURE <ls_node> TO <lv_id>.
  IF sy-subrc = 0.
    DATA(lv_alpha_id) = |{ <lv_id> ALPHA = IN }|.
  ENDIF.
ENDLOOP.

LOOP AT <lt_node> ASSIGNING FIELD-SYMBOL(<ls_node>).
  ASSIGN COMPONENT 'NAME' OF STRUCTURE <ls_node> TO FIELD-SYMBOL(<fs_name>).
  IF sy-subrc = 0.
    <fs_name> = 'SMERCAN'.
  ENDIF.
ENDLOOP.

" Appending via a field symbol
APPEND INITIAL LINE TO lt_mara ASSIGNING FIELD-SYMBOL(<fs_mara>).
<fs_mara>-matnr = '123456'.
UNASSIGN <fs_mara>.

" Always check IS ASSIGNED before dereferencing, and UNASSIGN when done
IF <ls_node> IS ASSIGNED.
  UNASSIGN <ls_node>.
ENDIF.

" Creating a new anonymous data object of the same type as a table's line
ASSIGN lt_data->* TO <lt_data>.
CREATE DATA lr_data LIKE LINE OF <lt_data>.

" Insert at a specific index via a field symbol
INSERT INITIAL LINE INTO lt_mara ASSIGNING <fs_mara> INDEX 2.
<fs_mara>-matnr = 'ABCDEF'.
UNASSIGN <fs_mara>.
```

## ✅ Best Practices

- Add a **secondary sorted/hashed key** to large internal tables that are read frequently by non-primary-key fields.
- Prefer `FIELD-SYMBOLS`/`REFERENCE INTO` over `INTO` (copy) when looping over large tables or when modifying rows in place — avoids unnecessary data copies.
- Use `VALUE`, `FILTER`, `FOR`, and `REDUCE` to replace multi-line procedural loops with single, declarative expressions where it improves readability.
- Always check `sy-subrc` (or use `line_exists( )`/`OPTIONAL`) after table expression access — direct `itab[ key ]` access raises an exception (`cx_sy_itab_line_not_found`) if not found.

## ⚠️ Common Mistakes

- Using `lt_itab[ key ]` directly without a safety net (`OPTIONAL`, `line_exists`, or `TRY...CATCH`) → runtime dump when the key doesn't exist.
- Forgetting `UNASSIGN` (or letting the field symbol go out of scope) leads to stale references pointing at deleted memory in long-running loops.
- Using `ASSIGN COMPONENT ... OF STRUCTURE` with a hardcoded field name when the structure is generic — always check `sy-subrc` since the component might not exist for every structure variant.

## 🎤 Interview Tips

- Explain the difference between a **field symbol** and a **data reference**, and when each is appropriate.
- Be ready to explain what `FILTER`, `REDUCE`, and `FOR` do, and how they compare to writing an equivalent `LOOP`.
- Know why `COLLECT`/secondary keys/`BINARY SEARCH` matter for internal table performance (see [19-Performance](../19-Performance/README.md)).

## 🔗 Related Chapters

- [06-Loops](../06-Loops/README.md)
- [08-Open-SQL](../08-Open-SQL/README.md)
- [19-Performance](../19-Performance/README.md)
