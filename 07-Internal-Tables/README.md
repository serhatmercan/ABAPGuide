# 07 — Internal Tables & Field Symbols

## 📖 Introduction

Internal tables are ABAP's core in-memory data structure — comparable to arrays/lists in other languages, but with rich, SQL-like operations (`WHERE`, key access, aggregation). This chapter covers table type definitions, the modern `VALUE`/`REDUCE`/`FILTER`/`FOR` functional operators, and field symbols/data references for dynamic, low-overhead data access.

## 🧱 Defining Table Types

```abap
" Types & table type & internal table
TYPES:
  BEGIN OF document_item,
    vbeln TYPE vbak-vbeln,
    posnr TYPE vbrp-posnr,
    auart TYPE vbak-auart,
  END OF document_item,

  document_items TYPE TABLE OF document_item WITH KEY vbeln.

DATA item TYPE document_item.
DATA items TYPE document_items.

" Structure with INCLUDE - modern form: TYPES declares a TYPE, then DATA
" declares the table from it.
TYPES: BEGIN OF inspection_lot.
         INCLUDE TYPE zsm_s_insplot.
TYPES:   objnr TYPE qals-objnr,
       END OF inspection_lot.

DATA inspection_lots TYPE STANDARD TABLE OF inspection_lot WITH EMPTY KEY.

" LEGACY / HISTORICAL REFERENCE - the classical equivalent you will meet in
" older programs. DATA BEGIN OF ... OCCURS 0 declares a table WITH A HEADER
" LINE, where the table and its work area share one name. It is obsolete in
" ABAP Objects contexts and unavailable in ABAP Cloud - recognise it, don't
" write it.
"   DATA BEGIN OF inspection_lots OCCURS 0.
"           INCLUDE TYPE zsm_s_insplot.
"   DATA:   objnr TYPE qals-objnr,
"         END OF inspection_lots.

" Table type with a secondary sorted key for performance.
" The PRIMARY key here is the document number; the SECONDARY key gives fast
" access by material + storage location without re-sorting the table.
TYPES: BEGIN OF batch_stock,
         charg TYPE mspr-charg,
         matnr TYPE marc-matnr,
         lgort TYPE mseg-lgort,
         pspnr TYPE mspr-pspnr,
         post1 TYPE prps-post1,
       END OF batch_stock.

TYPES batch_stocks TYPE STANDARD TABLE OF batch_stock
                   WITH NON-UNIQUE KEY charg
                   WITH NON-UNIQUE SORTED KEY by_material_location COMPONENTS matnr lgort.
```

> 💡 A **secondary sorted/hashed key** (`WITH ... SORTED KEY name COMPONENTS ...`) lets you do fast `READ TABLE ... WITH KEY by_material_location COMPONENTS ...` lookups without re-sorting the primary table — critical for performance on large tables (see [19-Performance](../19-Performance/README.md)).

## ➕ Filling Tables — APPEND, INSERT, VALUE

```abap
" Append with a field symbol to avoid an extra MODIFY
APPEND INITIAL LINE TO sales_items ASSIGNING FIELD-SYMBOL(<sales_item>).
<sales_item>-itm_number = last_item_number + 10.
<sales_item>-material   = return_item-matnr.

" VALUE with a shared header value applied to every row
material_lines = VALUE #( lgort = '1000'
                          ( mtart = 'AAAA' )
                          ( mtart = 'BBBB' ) ).

" Append corresponding lines from a differently-typed table
DATA target_lines TYPE zsm_tt_order_item.
APPEND LINES OF CORRESPONDING zsm_tt_order_item( source_lines ) TO target_lines.

" Append a single corresponding structure
DATA(notification_items) = VALUE crmt_rfc_viqmsm_t( ( ) ).
APPEND CORRESPONDING #( notification_item ) TO notification_items.

" Append a full structure / a VALUE literal
APPEND target_line TO target_lines.
APPEND VALUE #( material = '123' ) TO sales_items.

" VALUE with default (shared) parameters applied to each row
order_methods = VALUE #( refnumber = '1'
                         objectkey = 'X'
                         method    = 'CREATE'
                         ( objecttype = 'HEADER' )
                         ( objecttype = 'OPERATION' ) ).

" VALUE with an explicit table type
DATA(documents) = VALUE document_items( ( vbeln  = '1' posnr = '10' auart = 'X' )
                                        ( vbeln  = '2' posnr = '20' auart = 'Y' ) ).

" Append additional rows while keeping the existing ones with BASE
documents[] = VALUE #( BASE documents[]
                       ( vbeln = '3' posnr = '10' auart = 'Z' ) ).

" Building a return-message table
DATA messages TYPE bapiret2_t.
messages = VALUE #( ( type = 'E' id = 'ZSM_MSG' number = '001' ) ).

" Building a table with nested corresponding tables
er_deep_entity = VALUE #( returned = abap_true
                          header   = CORRESPONDING #( entity-header[] )
                          items    = CORRESPONDING #( entity-items[] ) ).

" Insert a value into a specific position
INSERT VALUE #( id = '1' value = 'X' ) INTO TABLE key_values.

INSERT VALUE #( kunnr = ''
                name1 = '' ) INTO sub_customers INDEX 1.
```

## 🎯 Reading & Filtering — table expressions, FILTER, FOR

```abap
" Direct index access via a field symbol.
" ASSIGN is the ONE place a table expression sets sy-subrc instead of raising.
ASSIGN materials[ 3 ] TO FIELD-SYMBOL(<third_row>).
IF sy-subrc = 0.
  " <third_row> is usable
ENDIF.

" Direct key access
ASSIGN materials[ ernam = 'USER01'
                  ersda = '20240101' ] TO FIELD-SYMBOL(<material>).

" FOR: build a new table via projection, with a WHERE condition
DATA(created_materials) = VALUE material_table( FOR source_material IN source_materials WHERE ( ernam EQ 'USER01' )
                                                ( matnr = source_material-matnr ernam = source_material-ernam ) ).

" FOR with conditional logic (COND) per field
vehicles[] = VALUE #( FOR vehicle_entry IN vehicle_entries
                      ( matnr = vehicle_entry-matnr
                        vhart = vehicle_entry-vhart
                        ergew = COND #( WHEN vehicle_entry-vhart = '1003'
                                        THEN CONV ergew( vehicle_entry-veh_maxwgt - vehicle_entry-veh_unlwgt )
                                        ELSE vehicle_entry-ergew ) ) ).

" FOR + BASE + LET...IN: enrich existing rows with a helper lookup
licence_lines = VALUE #( BASE licence_lines
                             FOR billing_line IN billing_lines
                         LET licence = read_licence( licence_type   = billing_line-lictp
                                                     licence_number = billing_line-oih_licin_vf )
                         IN  ( VALUE #( BASE CORRESPONDING #( billing_line )
                                        vbeln_vf    = licence-vbeln_vf
                                        licence_ref = licence-licence_ref ) ) ).

" FOR w/ GROUPS: build one row per distinct group value
DATA(creation_dates) = VALUE material_table( FOR GROUPS creation_date OF source_material IN source_materials
                                             WHERE ( ernam EQ 'USER01' )
                                             GROUP BY source_material-ersda
                                             ( ersda = creation_date ) ).

" FOR w/ WHERE + CORRESPONDING projection using a range table
TYPES: BEGIN OF licence_master,
         licin TYPE oihl-licin,
         lictp TYPE oihl-lictp,
         lctxt TYPE oihl-lctxt,
       END OF licence_master.

DATA licence_masters   TYPE TABLE OF licence_master.
DATA selected_licences TYPE TABLE OF licence_master.

selected_licences = VALUE #( FOR licence_master_line IN licence_masters WHERE ( licin IN licence_number_range )
                             ( CORRESPONDING #( licence_master_line ) ) ).
```

> 🔗 For `VALUE ... FOR` mapping domain fixed values read via RTTS into a value/text table, see [02-Data-Types](../02-Data-Types/README.md#-reading-domain-fixed-values-at-runtime-rtts).

### FILTER — Building a Subset of a Table

`FILTER` returns a new table containing only the rows that match a condition. It has two variants, and one **prerequisite that is easy to miss**: the source table must have at least one **sorted or hashed key** (primary or secondary) covering the components used in the condition.

```abap
TYPES: BEGIN OF material_row,
         ernam TYPE mara-ernam,
         matnr TYPE mara-matnr,
         mtart TYPE mara-mtart,
       END OF material_row.

" The source table needs a sorted or hashed key for FILTER to work
TYPES material_rows TYPE STANDARD TABLE OF material_row
                    WITH EMPTY KEY
                    WITH NON-UNIQUE SORTED KEY by_ernam COMPONENTS ernam.

DATA materials TYPE material_rows.

" Variant 1 - basic: compare a component against a value.
" Note there are no parentheses around the WHERE condition.
DATA(created_by_user) = FILTER #( materials USING KEY by_ernam WHERE ernam = 'USER01' ).

" Variant 1 with an explicit key, and the inverted form
DATA(created_by_user_keyed) = FILTER #( materials USING KEY by_ernam WHERE ernam = 'USER01' ).
DATA(created_by_others)     = FILTER #( materials EXCEPT USING KEY by_ernam WHERE ernam = 'USER01' ).

" Variant 2 - filter table: keep the rows whose component appears in a
" second table. The right-hand side of WHERE refers to the FILTER TABLE,
" here via its table_line (a table of elementary values).
DATA wanted_users TYPE SORTED TABLE OF mara-ernam WITH UNIQUE KEY table_line.

wanted_users = VALUE #( ( 'USER01' ) ( 'USER02' ) ).

DATA(created_by_wanted) = FILTER #( materials IN wanted_users WHERE ernam = table_line ).
```

> ⚠️ **Two things to get right.**
> 1. **`IN` takes an internal table, not a type name.** `FILTER #( materials IN material_rows ... )` would be wrong — `material_rows` is a *type*. The filter table must be a real data object.
> 2. **The two variants have different `WHERE` forms.** The basic variant compares against a value (`WHERE ernam = 'USER01'`); the filter-table variant compares against a component of the filter table (`WHERE ernam = table_line`). You cannot mix them.
>
> `#` for the result type is fine in an inline declaration here — it is derived from the source table.

## Σ Calculations with REDUCE

`REDUCE` accumulates a single value by iterating over a table — a functional replacement for a `LOOP` + running total variable.

```abap
" Sum a quantity. The RESULT type must be wide enough for what you accumulate -
" reducing a QUAN(13,3) into TYPE i would silently truncate the decimals.
DATA(total_stock) = REDUCE labst( INIT sum TYPE labst
                                  FOR  stock IN stocks
                                  WHERE ( labst <> 0 )
                                  NEXT sum = sum + stock-labst ).

DATA(amount) = REDUCE bstmg( INIT total TYPE bstmg
                             FOR  order_line IN order_lines
                             WHERE ( mtart EQ 'ZSTD' AND werks EQ '1000' )
                             NEXT total = total + order_line-total ).

" Counting: give the result an explicit type rather than relying on #
DATA(day_count) = REDUCE i( INIT count = 0
                            FOR  day IN calendar-days
                            WHERE ( periodat BETWEEN first_date AND last_date )
                            NEXT count = count + 1 ).

" REDUCE building a formatted string, e.g. "12345 / 67890"
DATA(value_list) = REDUCE char100( INIT text TYPE char100
                                   FOR  entry IN entries
                                   NEXT text = COND char100( WHEN text IS INITIAL
                                                             THEN condense( |{ entry-value ALPHA = OUT }| )
                                                             ELSE condense(
                                                                      |{ text } / { entry-value ALPHA = OUT }| ) ) ).
```

## 🗺️ CORRESPONDING with MAPPING

```abap
" source is an object reference, so its attribute is reached with -> , not -
materials = CORRESPONDING #( source->values MAPPING matnr = material_no ).
```
`MAPPING target = source` lets you rename fields on the fly when the source and target structures use different field names.

## 🗑️ Deleting Rows

```abap
DELETE entries WHERE id = 'X' AND attribute = 'ABC'.

" Delete by date / time comparison
DELETE tasks WHERE erdat > sy-datum.

DELETE tasks WHERE erdat  = sy-datum
                  AND erzeit > sy-uzeit.

" Delete using a range table (NOT IN)
DELETE entries WHERE id NOT IN id_range.
```

## 🔎 line_index / line_exists — Position-Based Access

```abap
DATA(document_index) = line_index( documents[ vbeln = '0060000001'] ).

" Real example: reordering rows in a response table by moving one entry
IF et_entityset IS NOT INITIAL.
  DATA(bank_index) = line_index( et_entityset[ header = 'Bank' ] ).
  DATA(tax_index)  = line_index( et_entityset[ header = 'Tax' ] ).

  IF tax_index IS NOT INITIAL.
    DATA(tax_entry) = VALUE #( et_entityset[ header = 'Tax' ] OPTIONAL ).

    DELETE et_entityset INDEX tax_index.

    IF bank_index IS NOT INITIAL.
      INSERT tax_entry INTO et_entityset INDEX bank_index + 1.
    ELSE.
      INSERT tax_entry INTO et_entityset INDEX 1.
    ENDIF.
  ENDIF.
ENDIF.
```

## 🔄 LOOP with REFERENCE INTO and Grouping Strings

```abap
LOOP AT order_properties REFERENCE INTO DATA(property_ref).
  CASE property_ref->property.
    WHEN 'OrderNo'.
      property_ref->property = 'ORDER_NO'.
  ENDCASE.
ENDLOOP.

" Grouping rows and concatenating a text field per group
TYPES: BEGIN OF invoice_material,
         file_no   TYPE zsm_e_file_no,
         materials TYPE string,
       END OF invoice_material.

DATA invoice_materials TYPE TABLE OF invoice_material.

LOOP AT invoice_lines INTO DATA(invoice_line)
     GROUP BY ( file_no = invoice_line-file_no ) ASCENDING
     INTO DATA(file_group).

  APPEND VALUE #(
      file_no   = file_group-file_no
      materials = REDUCE string( INIT text = ``
                                 FOR member IN GROUP file_group
                                 NEXT text = COND string( WHEN text IS INITIAL
                                                          THEN member-material
                                                          ELSE |{ text }, { member-material }| ) ) )
      TO invoice_materials.
ENDLOOP.
```

## 🧷 Field Symbols & Data References

Field symbols (`FIELD-SYMBOLS`) and data references (`TYPE REF TO data`) allow **dynamic, generic** access to data whose type isn't known until runtime — essential for generic frameworks, BAdIs, and dynamic programming.

```abap
TYPES material_table TYPE STANDARD TABLE OF mara WITH EMPTY KEY.

DATA source_ref TYPE REF TO data.   " lr_ = reference, not lt_
DATA line_ref   TYPE REF TO data.
DATA field_name TYPE string.
DATA materials  TYPE material_table.

FIELD-SYMBOLS <source_table> TYPE STANDARD TABLE.
FIELD-SYMBOLS <node_table>   TYPE STANDARD TABLE.
FIELD-SYMBOLS <structure>    TYPE any.
FIELD-SYMBOLS <material>     LIKE LINE OF materials.

" Dereferencing a data reference into a field symbol
ASSIGN data_ref->* TO <structure>.
IF <structure> IS NOT ASSIGNED.
  RETURN.
ENDIF.

" Dynamic component access by name (generic structure handling).
" ALWAYS check sy-subrc - the component may not exist in this structure.
ASSIGN COMPONENT field_name OF STRUCTURE <structure> TO <node_table>.
IF sy-subrc <> 0.
  RETURN.
ENDIF.

LOOP AT <node_table> ASSIGNING FIELD-SYMBOL(<node>).
  ASSIGN COMPONENT 'EXT_ID' OF STRUCTURE <node> TO FIELD-SYMBOL(<external_id>).
  IF sy-subrc = 0.
    DATA(internal_id) = |{ <external_id> ALPHA = IN }|.
  ENDIF.

  ASSIGN COMPONENT 'NAME' OF STRUCTURE <node> TO FIELD-SYMBOL(<name>).
  IF sy-subrc = 0.
    <name> = 'USER01'.
  ENDIF.
ENDLOOP.

" Appending via a field symbol
APPEND INITIAL LINE TO materials ASSIGNING <material>.
<material>-matnr = '000000000000123456'.

" Insert at a specific index via a field symbol
INSERT INITIAL LINE INTO materials ASSIGNING <material> INDEX 2.
<material>-matnr = '000000000000123457'.

" Creating a new anonymous data object of the same type as a table's line
ASSIGN source_ref->* TO <source_table>.
IF sy-subrc = 0.
  CREATE DATA line_ref LIKE LINE OF <source_table>.
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

- **Expecting a table expression to set `sy-subrc`. It does not.** `itab[ key ]` raises `CX_SY_ITAB_LINE_NOT_FOUND` when there is no match. Use one of:
  - `line_exists( itab[ key = ... ] )` before accessing;
  - `VALUE #( itab[ key = ... ] OPTIONAL )` for an initial value, or `DEFAULT ...` for a fallback;
  - `TRY ... CATCH cx_sy_itab_line_not_found`;
  - `ASSIGN itab[ key = ... ] TO <fs>` — **the one construct where a table expression sets `sy-subrc`** instead of raising.
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
