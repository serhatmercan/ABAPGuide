# 08 — ABAP SQL (Open SQL)

> **Terminology note.** SAP's current umbrella term for this statement set is **ABAP SQL**. "Open SQL" is the historical name and is still what most existing documentation, code comments and colleagues use, so both appear in this guide. The folder name is kept as `08-Open-SQL` so existing links continue to work.
>
> **Lifecycle:** `CURRENT / RECOMMENDED`. Individual expressions and data sources are `VERSION-DEPENDENT` — each is flagged below.

## 📖 Introduction

ABAP SQL is ABAP's database-independent SQL dialect. This chapter covers CRUD statements against custom (Z) tables, transaction (LUW) ownership, and a comprehensive set of `SELECT` patterns — joins, aggregation, subqueries, dynamic SQL, and building range tables directly from a query.

## 🗃️ CRUD on Custom Tables

The statements below are an **independent cookbook** — a catalogue of forms, not a script to run in sequence. None of them commits; transaction control is a separate decision covered in [SAP LUW & Transaction Ownership](#-sap-luw--transaction-ownership) immediately after.

> ⚠️ All DML examples in this guide target **custom (Z) tables that you own**. Do not apply them to SAP standard application tables — that bypasses the application's business logic and validations. Use the supported API or business interface instead (see [15-BAPIs](../15-BAPIs/README.md)).

```abap
" Internal table used as the source/target for the examples below
DATA lt_data TYPE TABLE OF zsm_t_data.
DATA ls_data TYPE zsm_t_data.

" INSERT - from an internal table (bulk insert)
INSERT zsm_t_data FROM TABLE lt_data.

" INSERT - from a single structure
INSERT zsm_t_data FROM ls_data.

" MODIFY - insert or update, from a single structure
MODIFY zsm_t_data FROM ls_data.

" MODIFY - insert or update, from an internal table
IF lt_data IS NOT INITIAL.
  MODIFY zsm_t_data FROM TABLE lt_data.
ENDIF.

" UPDATE - from a single structure (matches on primary key)
UPDATE zsm_t_data FROM ls_data.

" UPDATE - with a WHERE condition, qualified by the full key
UPDATE zsm_t_data SET name = 'DEMO'
                  WHERE vbeln = ls_data-vbeln
                    AND posnr = ls_data-posnr.

" UPDATE - multiple fields
UPDATE zsm_t_log SET   density    = is_ticket-density
                       volume_uom = is_ticket-volume_uom
                       process    = '01'
                 WHERE sns_number = is_ticket-sns_number.

" UPDATE - directly from a constructed value, with no intermediate variable
UPDATE zsm_t_data FROM @( VALUE #( customer      = iv_customer
                                   request_count = iv_request_count
                                   approval_id   = lv_approval_id ) ).

" DELETE - by a full structure (matches on primary key)
DELETE zsm_t_data FROM ls_data.

" DELETE - with a WHERE condition
DELETE FROM zsm_t_data WHERE vbeln = ls_data-vbeln.

" DELETE - from an internal table of keys (bulk delete)
DELETE zsm_t_data FROM TABLE lt_data.
```

> ⚠️ **Qualify mass `UPDATE` and `DELETE` statements.** A `DELETE FROM ... WHERE` on a non-key, non-selective column can remove far more rows than intended, and there is no confirmation prompt. Filter by the key where possible, and know the expected row count before you run it. `sy-dbcnt` holds the number of rows actually changed — check it.

> 💡 **`UPDATE ... FROM @( VALUE #( ... ) )`** uses a *host expression* to build the work area inline. This is valid current ABAP SQL and avoids an intermediate variable. **VERSION-DEPENDENT** — host expressions require a sufficiently recent release; verify against the ABAP Keyword Documentation for your target system.

## 🔐 SAP LUW & Transaction Ownership

This is the single most important concept in this chapter, and the one most often taught incorrectly.

### The rule

**The transaction boundary belongs to the top-level caller** — the report, the job step, the OData/RAP request handler, the orchestrating application. A reusable unit (a method, a function module, a BAdI implementation, a helper class) **must not decide the caller's transaction boundary**.

`COMMIT WORK` does not commit "your" changes. It closes the **current SAP LUW** and commits *everything* pending in it, including work done by callers and by other components you know nothing about. A commit buried inside a reusable method is how half-written business documents are produced.

```abap
" ✅ Reusable unit: performs its DML, reports what happened, commits nothing.
METHOD save_entries.
  MODIFY zsm_t_data FROM TABLE it_entries.

  rv_updated = sy-dbcnt.          " report the outcome, let the caller decide
ENDMETHOD.
```

```abap
" ✅ Transaction owner: one place decides the outcome for the whole unit of work.
START-OF-SELECTION.
  DATA(lo_writer) = NEW zcl_data_writer( ).

  TRY.
      lo_writer->save_entries( it_entries = lt_entries ).
      lo_writer->save_log( it_log = lt_log ).

      COMMIT WORK.                " one commit, at the boundary that owns the work

    CATCH cx_root INTO DATA(lx_error).
      ROLLBACK WORK.              " discard the entire unit of work
      MESSAGE lx_error->get_text( ) TYPE 'E'.
  ENDTRY.
```

### The statements

| Statement | What it does | When to use it |
|---|---|---|
| `COMMIT WORK` | Ends the current SAP LUW. Registered update-task work is handed to the update process **asynchronously**; control returns immediately. | The normal case. |
| `COMMIT WORK AND WAIT` | As above, but **waits** until the synchronous part of update processing has finished before continuing. | Only when the *same* program must immediately re-read what it just wrote, or must know the update succeeded before proceeding. |
| `ROLLBACK WORK` | Discards all uncommitted work in the current SAP LUW. | Error handling at the transaction boundary. |

### Update task, briefly

Rather than writing to the database directly, an application can register work with `CALL FUNCTION '...' IN UPDATE TASK`. Nothing happens until `COMMIT WORK`, at which point the registered modules run as one bundled unit. `PERFORM ... ON COMMIT` registers a routine the same way. This is the classic SAP mechanism for making a business transaction atomic across many components.

> This guide does not name specific update function modules, because they are application-specific — you register the ones belonging to the object you are updating.

### Locking, briefly

Database locks alone are not sufficient for a dialog transaction that spans several screens: the database LUW ends at each screen change, but the *business* transaction does not. SAP therefore provides a separate **enqueue** mechanism. A lock object defined in the Data Dictionary generates a matching pair of `ENQUEUE_*` / `DEQUEUE_*` function modules for the object being protected.

The pattern is: acquire the lock before reading data you intend to change, release it after the commit or rollback, and handle the "already locked by another user" case as a business message rather than a dump. Lock objects and their generated function modules are specific to your data model, so no name is shown here.

### Common mistakes

- **Committing inside reusable code.** See above. This is the big one.
- **Using `AND WAIT` by default.** It blocks the work process until update processing finishes. It is correct occasionally, not routinely.
- **Committing inside a loop**, once per row. Batch the work and commit once at the boundary.
- **Assuming `ROLLBACK WORK` undoes everything.** It only discards the *current, uncommitted* LUW. Anything already committed is gone for good — which is why partial commits are so damaging.
- **Calling `COMMIT WORK` after BAPIs.** BAPIs have their own protocol — use `BAPI_TRANSACTION_COMMIT` / `BAPI_TRANSACTION_ROLLBACK`. See [15-BAPIs](../15-BAPIs/README.md#-commit--rollback).

## 🔍 SELECT — Single Row / All Rows

```abap
" SELECT SINGLE
" SELECT SINGLE - always qualify it; without a WHERE you get an ARBITRARY row
SELECT SINGLE matnr, mtart, meins
  FROM mara
  WHERE matnr = @iv_matnr
  INTO @DATA(ls_data).

" SELECT SINGLE into multiple target variables
SELECT SINGLE position~position_id,
              position~position_txt
  FROM zsm_t_position AS position
  WHERE position~position_id = @iv_position_id
  INTO ( @DATA(lv_position_id), @DATA(lv_position_txt) ).

" SELECT rows into an internal table
SELECT vbeln, fkart, netwr, waerk
  FROM vbrk
  WHERE fkdat IN @s_fkdat
  INTO TABLE @DATA(lt_data).

" SELECT MAX (aggregate, single value)
SELECT MAX( posnr ) AS max_posnr
  FROM lips
  WHERE vbeln = @p_vbeln
  INTO @DATA(lv_posnr).
```

> ⚠️ **Strict ABAP SQL clause order.** As soon as a statement uses `@` host-variable escaping (or a comma-separated field list), the strict syntax rules apply and **`INTO` must be the last clause** — after `FROM`, `WHERE`, `GROUP BY`, `ORDER BY` and `UP TO n ROWS`. Several older code bases put `INTO` directly after the field list; that form is only tolerated in the obsolete non-strict syntax.

## 🔗 Joins

```abap
" LEFT OUTER JOIN
SELECT SINGLE mara~matnr,
              makt~maktx
  FROM mara
         LEFT JOIN
           makt ON makt~matnr = mara~matnr
  WHERE mara~matnr = @iv_matnr
  INTO @DATA(ls_material).

" INNER JOIN with MAX + GROUP BY
" NOTE: SELECT SINGLE and GROUP BY are mutually exclusive - an aggregation over
" groups returns a result SET, so it goes INTO TABLE.
SELECT a~posnr,
       MAX( a~vbeln ) AS max_vbeln
  FROM vbap AS a
         INNER JOIN
           vbak AS b ON a~vbeln = b~vbeln
  WHERE a~abgru = @space
    AND b~auart = 'ZSTD'
  GROUP BY a~posnr
  INTO TABLE @DATA(lt_max_vbeln).

" Selecting all fields of one table plus specific fields of another (mara~*, marc~prctr)
SELECT mara~*,
       marc~prctr
  FROM marc
         INNER JOIN
           mara ON mara~matnr = marc~matnr
  WHERE marc~is_default = @abap_true
  INTO TABLE @DATA(lt_data).

" A classic multi-table join
" NOTE: no MANDT predicate - ABAP SQL handles the client implicitly. Naming the
" client column without CLIENT SPECIFIED / USING CLIENT is rejected.
SELECT vbrk~vbeln,
       vbrp~posnr,
       vbrp~matnr,
       mara~mtart
  FROM vbrk
         INNER JOIN
           vbrp ON vbrp~vbeln = vbrk~vbeln
             INNER JOIN
               mara ON mara~matnr = vbrp~matnr
  WHERE vbrk~vbeln IN @ir_vbeln
  INTO TABLE @DATA(lt_billing).

" Joining the database against an already-selected internal table
SELECT a~rbukrs, a~gjahr, a~belnr
  FROM acdoca AS a
         INNER JOIN
           @lt_skb1 AS b ON b~saknr = a~racct
  WHERE a~rbukrs  = @iv_bukrs
    AND a~rldnr   = '0L'
    AND a~gjahr   = @iv_gjahr
    AND a~rbusa  IN @ir_gsber
  INTO TABLE @DATA(lt_acdoca).
```

> ⚠️ **VERSION-DEPENDENT:** using an internal table as an ABAP SQL data source (`FROM @lt_itab AS alias`) was introduced in the 7.5x generation. Verify support on your target release before relying on it.

> 💡 **Client handling.** ABAP SQL restricts client-dependent access to the current client automatically. Do **not** add `mandt = @sy-mandt` to a `WHERE` clause and do not select `mandt` in a field list — both conflict with the implicit handling. Cross-client access requires the explicit `CLIENT SPECIFIED` / `USING CLIENT` addition and is rarely correct in application code.

## 🧮 Calculations, CASE, and Functions in SELECT

```abap
" CASE expression in the SELECT list
SELECT CASE WHEN strkorr <> @space THEN strkorr
            ELSE 'A'
       END                                      AS request_no
  FROM e070
  INTO TABLE @DATA(lt_requests).

" Arithmetic function in the SELECT list
SELECT brgew,
       ntgew,
       gewei,
       abs( brgew - ntgew ) AS diff
  FROM mara
  INTO TABLE @DATA(lt_mara).

" String concatenation function
SELECT SINGLE concat_with_space( first_name, last_name, 1 ) AS driver_name
  FROM oigd
  WHERE perscode = @iv_driver_id
  INTO @DATA(lv_driver_name).

" Date-difference function
SELECT v1~qmnum,
       v1~product_group,
       dats_days_between( @sy-datum, v1~ltrmn ) AS days_remaining
  FROM @lt_data AS v1
         LEFT OUTER JOIN
           zsm_i_characteristic_values AS v2 ON v2~atwrt = v1~product_group
  INTO TABLE @DATA(lt_data_cl).

" RIGHT() string function
SELECT DISTINCT dlv~parent_key,
                right( dlv~base_btd_id, 10 )    AS vbeln,
                right( dlv~base_btditem_id, 6 ) AS posnr
  FROM @lt_dlv_ref AS dlv
  INTO TABLE @DATA(lt_dlv_keys).
```

> ⚠️ **VERSION-DEPENDENT.** SQL expressions in the field list — `CASE`, arithmetic, `abs( )`, `concat_with_space( )`, `dats_days_between( )`, `right( )` — were introduced progressively across the 7.4x and 7.5x releases, not all at once. Check each function in the ABAP Keyword Documentation against your target release. Expressions in the field list generally need an `AS` alias.

## 🔢 COUNT, DISTINCT, GROUP BY, ORDER BY

```abap
" COUNT(*)
SELECT COUNT(*) FROM t001w
  WHERE werks = @lv_werks
  INTO @DATA(lv_count).
IF lv_count = 0.
ENDIF.

" Existence check pattern: SELECT SINGLE 1 (cheaper than COUNT for an existence test)
DATA(lt_document_categories) = VALUE rseloption( sign   = 'I'
                                                 option = 'EQ'
                                                 ( low = 'K' )
                                                 ( low = 'L' ) ).

SELECT SINGLE @abap_true AS exists_flag
  FROM ekko AS t1
         INNER JOIN
           ekpo AS t2 ON t2~ebeln = t1~ebeln
  WHERE t1~bstyp IN @lt_document_categories
    AND t1~kdatb <= @sy-datum
    AND t1~kdate >= @sy-datum
    AND t2~matnr  = @iv_material
    AND t2~loekz  = @space
  INTO @DATA(lv_hit).

DATA(lv_agreement_exists) = xsdbool( sy-subrc = 0 ).

" Same pattern against a single table
SELECT SINGLE @abap_true AS exists_flag
  FROM zsm_ct_0001
  WHERE dokod = @lv_dokod
  INTO @DATA(lv_doc_hit).

DATA(lv_doc_exists) = xsdbool( lv_doc_hit = abap_true ).

" COUNT DISTINCT with GROUP BY
TYPES: BEGIN OF lty_order_appointment,
         begin_time  TYPE zsm_t_appointment-begin_time,
         finish_time TYPE zsm_t_appointment-finish_time,
         order_count TYPE i,
       END OF lty_order_appointment.
DATA lt_order_appointments TYPE STANDARD TABLE OF lty_order_appointment WITH EMPTY KEY.

SELECT t1~begin_time,
       t1~finish_time,
       COUNT( DISTINCT t1~order_no ) AS order_count
  FROM zsm_t_appointment AS t1
         INNER JOIN
           vbak AS t2 ON  t2~vbeln = t1~order_no
                      AND t2~kunnr = @iv_customer
  WHERE t1~appt_date = @lv_date
    AND t1~is_closed = @abap_false
  GROUP BY t1~begin_time,
           t1~finish_time
  INTO TABLE @lt_order_appointments.

" DISTINCT
SELECT DISTINCT charg
  FROM zsm_t_charg
  WHERE matnr = @lv_matnr
  INTO TABLE @DATA(lt_charg).

" SUM + GROUP BY + ORDER BY
" NOTE: a batch number is unique only PER MATERIAL, so batch tables must always
" be joined on MATNR (+ WERKS for stock) as well as CHARG - see the warning below.
SELECT mch1~vfdat                     AS vfdat,
       mch1~charg                     AS charg,
       SUM( mchb~clabs + mchb~cinsm ) AS total_stock
  FROM mcha
         INNER JOIN
           mchb ON  mchb~matnr = mcha~matnr
                AND mchb~werks = mcha~werks
                AND mchb~charg = mcha~charg
             INNER JOIN
               mch1 ON  mch1~matnr = mcha~matnr
                    AND mch1~charg = mcha~charg
  WHERE mcha~matnr  = @iv_matnr
    AND mcha~werks  = @iv_werks
    AND mcha~lvorm  = @space
    AND mchb~clabs <> 0
  GROUP BY mch1~vfdat,
           mch1~charg
  ORDER BY mch1~vfdat,
           mch1~charg
  INTO TABLE @DATA(lt_batch_stock).

" Conditional SUM (pivot-like aggregation) with CASE inside SUM
SELECT a~partner,
       a~credit_sgmnt,
       a~credit_limit,
       SUM( CASE WHEN a~credit_sgmnt = @lc_credit_segment_domestic THEN b~amount ELSE 0 END ) AS sum_domestic_amount,
       SUM( CASE WHEN a~credit_sgmnt = @lc_credit_segment_overseas THEN b~amount ELSE 0 END ) AS sum_overseas_amount,
       b~currency
  FROM ukmbp_cms_sgm AS a
         LEFT OUTER JOIN
           ukm_item AS b ON  b~partner      = a~partner
                         AND b~credit_sgmnt = a~credit_sgmnt
  WHERE a~partner      IN @lr_customers
    AND a~credit_sgmnt IN (@lc_credit_segment_domestic, @lc_credit_segment_overseas)
  GROUP BY a~partner,
           a~credit_sgmnt,
           a~credit_limit,
           b~currency
  ORDER BY a~partner,
           a~credit_sgmnt
  INTO TABLE @DATA(lt_credit).

" SUM against an internal table used as a virtual source table (VERSION-DEPENDENT)
SELECT t1~file_no,
       SUM( t1~fkimg ) AS total_fkimg
  FROM @lt_invoice_sum AS t1
  GROUP BY t1~file_no
  INTO TABLE @DATA(lt_invoice_sum_amount).
```

## 🔤 LIKE, EXISTS / NOT EXISTS

```abap
" LIKE with wildcard characters (ABAP wildcard '*' converted to SQL '%')
" Build the pattern in a SEPARATE, long-enough variable - never concatenate
" wildcards into the short field that holds the original value.
DATA lv_vehicle         TYPE oig_vhlnmr.
DATA lv_vehicle_pattern TYPE string.
DATA lv_text_pattern    TYPE string.

lv_vehicle_pattern = |%{ lv_vehicle }%|.
lv_text_pattern    = replace( val  = iv_search_text
                              sub  = '*'
                              with = '%'
                              occ  = 0 ).

" Predicates on the OPTIONAL side of a LEFT OUTER JOIN belong in the ON clause.
SELECT oigv~vehicle,
       oigv~veh_type,
       oigvt~veh_text,
       toigvt~veh_text AS veh_type_text
  FROM oigv
         LEFT OUTER JOIN
           oigvt ON  oigvt~vehicle  = oigv~vehicle
                 AND oigvt~language = @sy-langu
             LEFT OUTER JOIN
               toigvt ON  toigvt~veh_type = oigv~veh_type
                      AND toigvt~language = @sy-langu
  WHERE oigv~vehicle LIKE @lv_vehicle_pattern
  INTO TABLE @DATA(lt_vehicles).

" EXISTS subquery
SELECT COUNT( * ) AS hits
  FROM zsm_t_data
  WHERE werks = @iv_werks
    AND EXISTS ( SELECT * FROM mara
                   WHERE matnr = @iv_matnr
                     AND mtart = zsm_t_data~mtart )
  INTO @DATA(lv_exist_count).

" NOT EXISTS subquery (anti-join)
SELECT DISTINCT vk~vbeln,
                vk~kunnr,
                oigd~drname
  FROM vbak AS vk
         INNER JOIN
           vbap AS vp ON vp~vbeln = vk~vbeln
             LEFT OUTER JOIN
               oigd ON oigd~perscode = vk~zz1_driverid_sdh
  WHERE     vk~vbeln IN @lr_vbeln
    AND     vp~matnr IN @lr_matnr
    AND NOT EXISTS ( SELECT vkorg FROM zsm_t_exclusion
                       WHERE vkorg = @lv_vkorg
                         AND kunnr = vk~kunnr )
    AND NOT EXISTS ( SELECT vgbel FROM lips
                       WHERE vgbel = vk~vbeln )
  INTO TABLE @DATA(lt_open_orders).
```

> ⚠️ **A `WHERE` predicate on the right-hand table silently turns a `LEFT OUTER JOIN` into an inner join.** When no matching text row exists, the outer join supplies `NULL` for `oigvt~language`; a `WHERE oigvt~language = @sy-langu` then filters that row out — so the vehicles you were specifically trying to keep disappear. Restrictions on the **optional** side of an outer join belong in the `ON` clause, as shown above. This is one of the most common wrong-results bugs in production ABAP, and it never raises an error.

> 💡 Do not select `mandt` in a subquery just to have a column — pick a real business column (or use `SELECT @abap_true`). See the client-handling note above.

## 🧩 UNION

```abap
" UNION ALL (keeps duplicates)
SELECT name1 FROM kna1
  WHERE loevm = @abap_false
UNION ALL
SELECT name1 FROM lfa1
  WHERE loevm = @abap_false
INTO TABLE @DATA(lt_names).

" UNION DISTINCT (removes duplicates)
SELECT name1 FROM kna1
  WHERE loevm = @abap_false
UNION DISTINCT
SELECT name1 FROM lfa1
  WHERE loevm = @abap_false
INTO TABLE @DATA(lt_names).
```

## 🐢 FOR ALL ENTRIES IN

`FOR ALL ENTRIES` is the classical way to "join" a driver internal table against the database when a real `JOIN`/subquery isn't possible or practical.

```abap
IF lt_itab IS NOT INITIAL.
  DATA(lt_driver) = lt_itab.

  " Prepare the driver table: no duplicates, no initial key values
  SORT lt_driver BY vbeln posnr.
  DELETE ADJACENT DUPLICATES FROM lt_driver COMPARING vbeln posnr.
  DELETE lt_driver WHERE posnr IS INITIAL.

  IF lt_driver IS NOT INITIAL.
    SELECT vbfa~vbeln,
           vbfa~posnn,
           vbfa~vbtyp_n
      FROM vbfa
      FOR ALL ENTRIES IN @lt_driver
      WHERE vbfa~vbeln = @lt_driver-vbeln
        AND vbfa~posnn = @lt_driver-posnr
      ORDER BY vbfa~vbeln, vbfa~posnn
      INTO TABLE @DATA(lt_vbfa).
  ENDIF.
ENDIF.
```

> ⚠️ **Critical `FOR ALL ENTRIES` rules:**
> 1. **Always check that the driver table is not initial** before the `SELECT`. If it is empty, `FOR ALL ENTRIES` behaves as if there were **no `WHERE` condition at all** and reads the entire database table.
> 2. **Sort and remove duplicates** from the driver table first — duplicate driver rows cause redundant database work.
> 3. **`FOR ALL ENTRIES` applies an implicit `DISTINCT`.** Duplicate rows are removed from the result set automatically. If two source rows are legitimately identical in the selected columns, one of them silently disappears — so always select enough key columns to keep the rows distinguishable. This is the rule most often discovered the hard way, via wrong totals.
> 4. **The driver column must be type-compatible** with the database column it is compared against.
> 5. The database interface **splits the driver table into packages**, issuing several statements. `UP TO n ROWS`, aggregate functions and `ORDER BY` therefore do not behave the way a single statement would — sort the result in ABAP if the ordering matters.
>
> **Do not use `ORDER BY PRIMARY KEY` here.** It requires the result set to contain the complete primary key of the table, which a projection like the one above does not. Use an explicit `ORDER BY` on the selected columns instead.

> 💡 Only join tables you actually read from. An earlier version of this example selected `vbak~auart` without joining `VBAK` — a syntax error. If you need header data as well, either add an explicit `INNER JOIN` (note that combining `JOIN` with `FOR ALL ENTRIES` has its own restrictions) or read it in a second statement.

## 🏗️ Building Range Tables from a SELECT

```abap
DATA lt_werks_range TYPE RANGE OF werks_d.

SELECT 'I'         AS sign,
       'EQ'        AS option,
       t001w~werks AS low
  FROM t001w
  INTO CORRESPONDING FIELDS OF TABLE @lt_werks_range.

DATA lr_tags TYPE RANGE OF zsm_e_tag.

SELECT FROM @ls_input-tag_names AS t1
  FIELDS 'I'     AS sign,
         'EQ'    AS option,
         t1~name AS low
  INTO CORRESPONDING FIELDS OF TABLE @lr_tags.

SELECT FROM zsm_ct_tag
  FIELDS tag_name,
         'Units'  AS property_name,
         unit     AS property_value
  WHERE werks     = @ls_input-plant
    AND tag_name IN @lr_tags
  INTO CORRESPONDING FIELDS OF TABLE @ls_proxy_response-get_tag_info_response-properties.
```

## 🧪 Dynamic SQL

```abap
DATA lv_fieldname TYPE fieldname.
DATA lv_table     TYPE tabname.
DATA lt_condition TYPE TABLE OF string.
DATA lr_values    TYPE RANGE OF char30.
DATA lr_result    TYPE REF TO data.

FIELD-SYMBOLS <lt_result> TYPE STANDARD TABLE.

" In a DYNAMIC condition the ABAP data object is named directly,
" WITHOUT the @ host-variable escape used in static ABAP SQL.
lt_condition = VALUE #( ( |{ lv_fieldname } IN lr_values| ) ).

" The target must be created dynamically too, because its type is not
" known until runtime.
CREATE DATA lr_result TYPE TABLE OF (lv_table).
ASSIGN lr_result->* TO <lt_result>.

SELECT DISTINCT (lv_fieldname)
  FROM (lv_table)
  WHERE (lt_condition)
  INTO CORRESPONDING FIELDS OF TABLE @<lt_result>.
```
> ⚠️ **Two separate risks, and you must address both.**
> 1. **Injection.** Dynamic table/field/condition tokens must come from trusted, validated sources — never build them from unvalidated user input.
> 2. **Authorization.** A dynamic `SELECT` performs **no** implicit authorization check. Verifying that a table exists in the Data Dictionary proves existence, not access rights. See [11-Classical-Reports](../11-Classical-Reports/README.md#-dynamic-reports--building-tables-and-field-catalogs-at-runtime) for the generic table-access authorization check.
>
> Dynamic `SELECT` over arbitrary Dictionary tables is also restricted in ABAP Cloud — see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 🧭 Other Frequently Used WHERE Patterns

```abap
" Host expression as a constant column in the SELECT list (VERSION-DEPENDENT)
SELECT SINGLE v1~qmnum,
              @iv_task_no AS task_no,
              v1~ernam
  FROM qmel AS v1
  WHERE v1~qmnum = @iv_qmnum
  INTO @DATA(ls_qmel).

" The fragments below are WHERE-clause forms, not complete statements.
" BETWEEN
"   WHERE mara~mtart BETWEEN 'ZSTD' AND 'ZFIN'
" Value list
"   WHERE vbfa~vbtyp_v IN ( 'C', 'L', 'K', 'I', 'H' )
" Multiple LIKE conditions
"   WHERE ( matnr LIKE 'J%' OR matnr LIKE 'T%' )
" Validity date range
"   WHERE begda <= @sy-datum AND endda >= @sy-datum
```

> 💡 **`ORDER BY PRIMARY KEY`** is only permitted when the result set contains the table's complete primary key — it is not a general-purpose "stable sort". For a projection, list the columns explicitly: `ORDER BY vbeln, posnr`.

## ✅ Best Practices

- Select only the fields you need — avoid `SELECT *` in production code, especially inside loops.
- Always qualify `SELECT SINGLE` with a `WHERE` on the full key. Without one you get an arbitrary row.
- Always check `IF lt_driver IS NOT INITIAL` before `FOR ALL ENTRIES`, and de-duplicate the driver table first.
- Use `SELECT SINGLE @abap_true ... INTO @DATA(...)` + `xsdbool( sy-subrc = 0 )` for existence checks instead of `COUNT(*)` when you don't need the exact count.
- Prefer joins and subqueries over `FOR ALL ENTRIES` when possible — they push more work to the database and avoid the pitfalls above.
- Put restrictions on the optional side of an outer join in the `ON` clause, not in `WHERE`.
- **Let the transaction owner commit.** Reusable code performs its DML and reports the outcome; the top-level caller decides between `COMMIT WORK` and `ROLLBACK WORK`. Reserve `AND WAIT` for the case where the same program must immediately re-read what it wrote.
- Check `sy-dbcnt` after a mass `UPDATE`/`DELETE` to confirm the number of rows actually affected.

## ⚠️ Common Mistakes

- Running `FOR ALL ENTRIES` with an **empty driver table** — silently selects everything.
- Forgetting the implicit `DISTINCT` that `FOR ALL ENTRIES` applies, and losing rows from the result.
- Filtering the optional side of a `LEFT OUTER JOIN` in the `WHERE` clause, turning it into an inner join.
- Placing `INTO` before `WHERE` / `UP TO n ROWS` in strict ABAP SQL syntax.
- Referring to the client column (`mandt`) explicitly instead of letting ABAP SQL handle it.
- Using `SELECT ... ENDSELECT` loops (row-by-row round trips) instead of a single `SELECT ... INTO TABLE`.
- **Committing inside reusable code**, taking a transaction decision that belongs to the caller.
- Building dynamic SQL fragments from screen/user input without validation *and* without an authorization check.

## 🎤 Interview & Review Checkpoints

- Explain the risks of `FOR ALL ENTRIES` and how to mitigate them — including the implicit `DISTINCT`.
- Compare `JOIN` vs. `FOR ALL ENTRIES` vs. nested `SELECT`s — when would you use each?
- Explain the SAP LUW: what `COMMIT WORK` actually closes, why `AND WAIT` is not the default, and who owns the transaction boundary.
- Show why a `WHERE` predicate on the right-hand table of a `LEFT OUTER JOIN` changes the result set.
- Explain the performance implications of `SELECT *` and of `INTO CORRESPONDING FIELDS`.

## 🔗 Related Chapters

- [06-Loops](../06-Loops/README.md) — range tables used in `WHERE ... IN`
- [07-Internal-Tables](../07-Internal-Tables/README.md)
- [15-BAPIs](../15-BAPIs/README.md) — transaction control for BAPI calls
- [19-Performance](../19-Performance/README.md)
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle context

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE11 | Data Dictionary (table/structure maintenance) |
| SE16N | Table data browser |
| ST05 | SQL Trace (analyze SELECT performance) |
| SE30 / SAT | Runtime analysis |
