# 08 — ABAP SQL (Open SQL)

> **Terminology note.** SAP's current umbrella term for this statement set is **ABAP SQL**. "Open SQL" is the historical name and is still what most existing documentation, code comments and colleagues use, so both appear in this guide. The folder name is kept as `08-Open-SQL` so existing links continue to work.
>
> **Lifecycle:** `CURRENT / RECOMMENDED`. Individual expressions and data sources are `VERSION-DEPENDENT` — each is flagged below.

## 📖 Introduction

ABAP SQL is ABAP's database-independent SQL dialect. This chapter covers CRUD statements against custom (Z) tables, transaction (LUW) ownership, and a comprehensive set of `SELECT` patterns — joins, aggregation, subqueries, dynamic SQL, and building range tables directly from a query.

## 🗃️ CRUD on Custom Tables

The statements below are an **independent cookbook** — a catalogue of forms, not a script to run in sequence. None of them commits; transaction control is a separate decision covered in [SAP LUW & Transaction Ownership](#-sap-luw--transaction-ownership) immediately after.

> ⚠️ All DML examples in this guide target **custom (Z) tables that you own**. Do not apply them to SAP standard application tables — that bypasses the application's business logic and validations. Use the supported API or business interface instead (see [15-BAPIs](../15-BAPIs/README.md)).

> 📝 **Contextual snippet** — assumes a custom table `zsm_t_entry`, the variables `customer`, `request_count` and `approval_id`, and a structure `ticket`.

```abap
" Internal table used as the source/target for the examples below
DATA entries TYPE STANDARD TABLE OF zsm_t_entry WITH EMPTY KEY.
DATA entry   TYPE zsm_t_entry.

" INSERT - from an internal table (bulk insert)
INSERT zsm_t_entry FROM TABLE entries.

" INSERT - from a single structure
INSERT zsm_t_entry FROM entry.

" MODIFY - insert or update, from a single structure
MODIFY zsm_t_entry FROM entry.

" MODIFY - insert or update, from an internal table
IF entries IS NOT INITIAL.
  MODIFY zsm_t_entry FROM TABLE entries.
ENDIF.

" UPDATE - from a single structure (matches on primary key)
UPDATE zsm_t_entry FROM entry.

" UPDATE - with a WHERE condition, qualified by the full key
UPDATE zsm_t_entry SET name = 'DEMO'
                   WHERE vbeln = entry-vbeln
                     AND posnr = entry-posnr.

" UPDATE - multiple fields
UPDATE zsm_t_log SET   density    = ticket-density
                       volume_uom = ticket-volume_uom
                       process    = '01'
                 WHERE sns_number = ticket-sns_number.

" UPDATE - directly from a constructed value, with no intermediate variable
UPDATE zsm_t_entry FROM @( VALUE #( customer      = customer
                                    request_count = request_count
                                    approval_id   = approval_id ) ).

" DELETE - by a full structure (matches on primary key)
DELETE zsm_t_entry FROM entry.

" DELETE - with a WHERE condition
DELETE FROM zsm_t_entry WHERE vbeln = entry-vbeln.

" DELETE - from an internal table of keys (bulk delete)
DELETE zsm_t_entry FROM TABLE entries.
```

> ⚠️ **Qualify mass `UPDATE` and `DELETE` statements.** A `DELETE FROM ... WHERE` on a non-key, non-selective column can remove far more rows than intended, and there is no confirmation prompt. Filter by the key where possible, and know the expected row count before you run it. `sy-dbcnt` holds the number of rows actually changed — check it ([Rule 7.15](../docs/ABAP-Development-Rules.md#715-qualify-mass-update-and-delete-with-where-and-check-sy-dbcnt)).

> 💡 **`UPDATE ... FROM @( VALUE #( ... ) )`** uses a *host expression* to build the work area inline. This is valid current ABAP SQL and avoids an intermediate variable. **VERSION-DEPENDENT** — host expressions require a sufficiently recent release; verify against the ABAP Keyword Documentation for your target system.

## 🔐 SAP LUW & Transaction Ownership

This is the single most important concept in this chapter, and the one most often taught incorrectly.

### The rule

**The transaction boundary belongs to the top-level caller** ([Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work)) — the report, the job step, the OData/RAP request handler, the orchestrating application. A reusable unit (a method, a function module, a BAdI implementation, a helper class) **must not decide the caller's transaction boundary**.

`COMMIT WORK` does not commit "your" changes. It closes the **current SAP LUW** and commits *everything* pending in it, including work done by callers and by other components you know nothing about. A commit buried inside a reusable method is how half-written business documents are produced.

> 📝 **Contextual snippet** — `save_entries` is assumed to have `IMPORTING entries` and `RETURNING VALUE(result) TYPE i`; the report assumes the tables `entries` and `log_entries`.

```abap
" ✅ Reusable unit: performs its DML, reports what happened, commits nothing.
METHOD save_entries.
  MODIFY zsm_t_entry FROM TABLE entries.

  result = sy-dbcnt.          " report the outcome, let the caller decide
ENDMETHOD.
```

```abap
" ✅ Transaction owner: one place decides the outcome for the whole unit of work.
START-OF-SELECTION.
  DATA(writer) = NEW zcl_zsm_entry_writer( ).

  TRY.
      writer->save_entries( entries = entries ).
      writer->save_log( log_entries = log_entries ).

      COMMIT WORK.                " one commit, at the boundary that owns the work

    " cx_root only here, at the outermost boundary (Rule 6.6)
    CATCH cx_root INTO DATA(error).
      ROLLBACK WORK.              " discard the entire unit of work
      MESSAGE error->get_text( ) TYPE 'E'.
  ENDTRY.
```

### The statements

| Statement | What it does | When to use it |
|---|---|---|
| `COMMIT WORK` | Ends the current SAP LUW. Registered update-task work is handed to the update process **asynchronously**; control returns immediately. | The normal case. |
| `COMMIT WORK AND WAIT` | As above, but **waits** until the update work process has executed the high-priority update function modules; `sy-subrc` then tells whether the update succeeded. | Only when the *same* program must immediately re-read what it just wrote, or must know the update succeeded before proceeding — [Rule 7.14](../docs/ABAP-Development-Rules.md#714-use-commit-work-and-wait-only-when-the-next-step-depends-on-the-update). |
| `ROLLBACK WORK` | Discards all uncommitted work in the current SAP LUW. | Error handling at the transaction boundary. |

### Update task, briefly

Rather than writing to the database directly, an application can register work with `CALL FUNCTION '...' IN UPDATE TASK`. Nothing happens until `COMMIT WORK`, at which point the registered modules run as one bundled unit. `PERFORM ... ON COMMIT` registers a routine the same way. This is the classic SAP mechanism for making a business transaction atomic across many components.

> This guide does not name specific update function modules, because they are application-specific — you register the ones belonging to the object you are updating.

### Locking, briefly

Database locks alone are not sufficient for a dialog transaction that spans several screens: the database LUW ends at each screen change, but the *business* transaction does not. SAP therefore provides a separate **enqueue** mechanism. A lock object defined in the Data Dictionary generates a matching pair of `ENQUEUE_*` / `DEQUEUE_*` function modules for the object being protected.

The pattern is: acquire the lock before reading data you intend to change, release it after the commit or rollback, and handle the "already locked by another user" case as a business message rather than a dump. Lock objects and their generated function modules are specific to your data model, so no name is shown here — see [Rule 7.12](../docs/ABAP-Development-Rules.md#712-protect-business-transactions-with-enqueue-locks) for an example with a placeholder lock object.

### Common mistakes

- **Committing inside reusable code.** See above. This is the big one.
- **Using `AND WAIT` by default.** It blocks the work process until update processing finishes. It is correct occasionally, not routinely.
- **Committing inside a loop**, once per row. Batch the work and commit once at the boundary.
- **Assuming `ROLLBACK WORK` undoes everything.** It only discards the *current, uncommitted* LUW. Anything already committed is gone for good — which is why partial commits are so damaging.
- **Calling `COMMIT WORK` after BAPIs.** BAPIs have their own protocol — use `BAPI_TRANSACTION_COMMIT` / `BAPI_TRANSACTION_ROLLBACK`. See [15-BAPIs](../15-BAPIs/README.md#-commit--rollback).

## 🔍 SELECT — Single Row / All Rows

> 📝 **Contextual snippet** — assumes the variables `material` and `position_id`, the selection-screen fields `s_fkdat` and `p_vbeln` (selection-screen names keep their short form), and a custom table `zsm_t_position`.

```abap
" SELECT SINGLE
" SELECT SINGLE - always qualify it; without a WHERE you get an ARBITRARY row
SELECT SINGLE matnr, mtart, meins
  FROM mara
  WHERE matnr = @material
  INTO @DATA(material_header).

" SELECT SINGLE into multiple target variables
SELECT SINGLE position~position_id,
              position~position_txt
  FROM zsm_t_position AS position
  WHERE position~position_id = @position_id
  INTO ( @DATA(found_position_id), @DATA(position_text) ).

" SELECT rows into an internal table
SELECT vbeln, fkart, netwr, waerk
  FROM vbrk
  WHERE fkdat IN @s_fkdat
  INTO TABLE @DATA(billing_documents).

" SELECT MAX (aggregate, single value) - fine for reporting, but never derive
" a new key from it (see Writing Log Records below)
SELECT MAX( posnr ) AS max_posnr
  FROM lips
  WHERE vbeln = @p_vbeln
  INTO @DATA(max_item_number).
```

> ⚠️ **Strict ABAP SQL and clause order.** Escaping host variables with `@` and comma-separated field lists switch on the strict syntax check; host variables without `@` are obsolete. Writing `INTO` after the query clauses — `FROM`, `WHERE`, `GROUP BY`, `HAVING` and `ORDER BY` — is also part of the strict syntax. Only `UP TO n ROWS`, `OFFSET` and the other ABAP-specific additions follow `INTO`; when `INTO` is the last clause, the ABAP Keyword Documentation requires them there. This guide always writes this order — [Rule 7.1](../docs/ABAP-Development-Rules.md#71-write-strict-abap-sql-a-comma-separated-field-list--host-variables-into-after-the-query-clauses).

## 🔗 Joins

> 📝 **Contextual snippet** — assumes the variables `material`, `order_type`, `plant`, `company_code`, `fiscal_year` and `ledger`, the ranges `billing_document_range` and `business_area_range`, and an internal table `gl_accounts`.

```abap
" LEFT OUTER JOIN
SELECT SINGLE mara~matnr,
              makt~maktx
  FROM mara
         LEFT JOIN
           makt ON  makt~matnr = mara~matnr
                AND makt~spras = @sy-langu
  WHERE mara~matnr = @material
  INTO @DATA(material_text).

" INNER JOIN with MAX + GROUP BY
" NOTE: SELECT SINGLE and GROUP BY are mutually exclusive - an aggregation over
" groups returns a result SET, so it goes INTO TABLE.
SELECT a~posnr,
       MAX( a~vbeln ) AS max_vbeln
  FROM vbap AS a
         INNER JOIN
           vbak AS b ON a~vbeln = b~vbeln
  WHERE a~abgru = @space
    AND b~auart = @order_type
  GROUP BY a~posnr
  INTO TABLE @DATA(latest_orders).

" Selecting all fields of one table plus specific fields of another (mara~*, marc~prctr)
" Shows the syntax only; production code lists the fields it needs (Rule 7.7)
SELECT mara~*,
       marc~prctr
  FROM marc
         INNER JOIN
           mara ON mara~matnr = marc~matnr
  WHERE marc~werks = @plant
  INTO TABLE @DATA(materials_with_profit_center).

" A classic multi-table join
" NOTE: no MANDT predicate - ABAP SQL handles the client implicitly, and the
" client column is not specified in the WHERE condition.
SELECT vbrk~vbeln,
       vbrp~posnr,
       vbrp~matnr,
       mara~mtart
  FROM vbrk
         INNER JOIN
           vbrp ON vbrp~vbeln = vbrk~vbeln
             INNER JOIN
               mara ON mara~matnr = vbrp~matnr
  WHERE vbrk~vbeln IN @billing_document_range
  INTO TABLE @DATA(billing_items).

" Joining the database against an already-selected internal table
SELECT a~rbukrs, a~gjahr, a~belnr
  FROM acdoca AS a
         INNER JOIN
           @gl_accounts AS b ON b~saknr = a~racct
  WHERE a~rbukrs  = @company_code
    AND a~rldnr   = @ledger
    AND a~gjahr   = @fiscal_year
    AND a~rbusa  IN @business_area_range
  INTO TABLE @DATA(journal_entries).
```

> ⚠️ **VERSION-DEPENDENT: internal tables as data source (`FROM @itab AS alias`).** Not available in every release. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) for your target system.

> 💡 **Client handling.** ABAP SQL restricts client-dependent access to the current client automatically. Do **not** add `mandt = @sy-mandt` to a `WHERE` clause and do not select `mandt` in a field list — both conflict with the implicit handling. Cross-client access requires `USING CLIENT` or `USING [ALL] CLIENTS [IN]` and is rarely correct in application code; the older `CLIENT SPECIFIED` is obsolete — [Rule 7.8](../docs/ABAP-Development-Rules.md#78-let-abap-sql-handle-the-client).

> ⚠️ **VERSION-DEPENDENT: `WITH PRIVILEGED ACCESS`.** When ABAP SQL reads a CDS entity, that entity's CDS access control is applied implicitly. Writing `WITH PRIVILEGED ACCESS` directly after the data source (before `AS alias`), e.g. `FROM i_purchaseorderapi01 WITH PRIVILEGED ACCESS AS po`, switches it off for that source only. The program then owns the authorization check, and a comment at the statement must say why the restriction does not apply — [Rule 8.3](../docs/ABAP-Development-Rules.md#83-use-with-privileged-access-only-with-a-written-justification). For DDIC database tables and DDIC views the addition is currently ignored, because they have no CDS access control. See [CDSGuide — Bypassing Access Control](https://github.com/serhatmercan/CDSGuide/blob/master/09-Security/AccessControl.md#bypassing-access-control-with-privileged-access) for details.

## 🧮 Calculations, CASE, and Functions in SELECT

> 📝 **Contextual snippet** — assumes the variable `driver_id` and the internal tables `notifications` and `delivery_references`.

```abap
" CASE expression in the SELECT list
SELECT CASE WHEN strkorr <> @space THEN strkorr
            ELSE 'A'
       END                                      AS request_no
  FROM e070
  INTO TABLE @DATA(requests).

" Arithmetic function in the SELECT list
SELECT brgew,
       ntgew,
       gewei,
       abs( brgew - ntgew ) AS diff
  FROM mara
  INTO TABLE @DATA(weights).

" String concatenation function
SELECT SINGLE concat_with_space( first_name, last_name, 1 ) AS driver_name
  FROM oigd
  WHERE perscode = @driver_id
  INTO @DATA(driver_name).

" Date-difference function
SELECT v1~qmnum,
       v1~product_group,
       dats_days_between( @sy-datum, v1~ltrmn ) AS days_remaining
  FROM @notifications AS v1
         LEFT OUTER JOIN
           zsm_i_characteristic_values AS v2 ON v2~atwrt = v1~product_group
  INTO TABLE @DATA(notification_deadlines).

" RIGHT() string function
SELECT DISTINCT dlv~parent_key,
                right( dlv~base_btd_id, 10 )    AS vbeln,
                right( dlv~base_btditem_id, 6 ) AS posnr
  FROM @delivery_references AS dlv
  INTO TABLE @DATA(delivery_keys).
```

> ⚠️ **VERSION-DEPENDENT: SQL expressions in the field list.** `CASE`, arithmetic, `abs( )`, `concat_with_space( )`, `dats_days_between( )` and `right( )` did not all become available at the same time. Check each function in the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) against your target release. Expressions in the field list generally need an `AS` alias.

## 🔢 COUNT, DISTINCT, GROUP BY, ORDER BY

> 📝 **Contextual snippet** — assumes the variables it compares against (`plant`, `material`, `customer`, `appointment_date`, `document_code`), the constants `credit_segment_domestic` and `credit_segment_overseas`, a range `customer_range`, and an internal table `invoice_lines`.

```abap
" COUNT( * ) when you need the number - for an existence test, use the
" SELECT SINGLE @abap_true pattern below (Rule 7.6)
SELECT COUNT(*) FROM t001w
  WHERE werks = @plant
  INTO @DATA(plant_count).

" Existence check pattern: SELECT SINGLE @abap_true (cheaper than COUNT for an existence test)
DATA(document_categories) = VALUE rseloption( sign   = 'I'
                                              option = 'EQ'
                                              ( low = 'K' )
                                              ( low = 'L' ) ).

SELECT SINGLE @abap_true AS exists_flag
  FROM ekko AS t1
         INNER JOIN
           ekpo AS t2 ON t2~ebeln = t1~ebeln
  WHERE t1~bstyp IN @document_categories
    AND t1~kdatb <= @sy-datum
    AND t1~kdate >= @sy-datum
    AND t2~matnr  = @material
    AND t2~loekz  = @space
  INTO @DATA(agreement_hit).

DATA(agreement_exists) = xsdbool( sy-subrc = 0 ).

" Same pattern against a single table
SELECT SINGLE @abap_true AS exists_flag
  FROM zsm_t_document
  WHERE dokod = @document_code
  INTO @DATA(document_hit).

DATA(document_exists) = xsdbool( document_hit = abap_true ).

" COUNT DISTINCT with GROUP BY
TYPES: BEGIN OF order_appointment,
         begin_time  TYPE zsm_t_appointment-begin_time,
         finish_time TYPE zsm_t_appointment-finish_time,
         order_count TYPE i,
       END OF order_appointment.
DATA order_appointments TYPE STANDARD TABLE OF order_appointment WITH EMPTY KEY.

SELECT t1~begin_time,
       t1~finish_time,
       COUNT( DISTINCT t1~order_no ) AS order_count
  FROM zsm_t_appointment AS t1
         INNER JOIN
           vbak AS t2 ON  t2~vbeln = t1~order_no
                      AND t2~kunnr = @customer
  WHERE t1~appt_date = @appointment_date
    AND t1~is_closed = @abap_false
  GROUP BY t1~begin_time,
           t1~finish_time
  INTO TABLE @order_appointments.

" DISTINCT
SELECT DISTINCT charg
  FROM zsm_t_batch
  WHERE matnr = @material
  INTO TABLE @DATA(batches).

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
  WHERE mcha~matnr  = @material
    AND mcha~werks  = @plant
    AND mcha~lvorm  = @space
    AND mchb~clabs <> 0
  GROUP BY mch1~vfdat,
           mch1~charg
  ORDER BY mch1~vfdat,
           mch1~charg
  INTO TABLE @DATA(batch_stocks).

" Conditional SUM (pivot-like aggregation) with CASE inside SUM
SELECT a~partner,
       a~credit_sgmnt,
       a~credit_limit,
       SUM( CASE WHEN a~credit_sgmnt = @credit_segment_domestic THEN b~amount ELSE 0 END ) AS sum_domestic_amount,
       SUM( CASE WHEN a~credit_sgmnt = @credit_segment_overseas THEN b~amount ELSE 0 END ) AS sum_overseas_amount,
       b~currency
  FROM ukmbp_cms_sgm AS a
         LEFT OUTER JOIN
           ukm_item AS b ON  b~partner      = a~partner
                         AND b~credit_sgmnt = a~credit_sgmnt
  WHERE a~partner      IN @customer_range
    AND a~credit_sgmnt IN (@credit_segment_domestic, @credit_segment_overseas)
  GROUP BY a~partner,
           a~credit_sgmnt,
           a~credit_limit,
           b~currency
  ORDER BY a~partner,
           a~credit_sgmnt
  INTO TABLE @DATA(credit_exposure).

" SUM against an internal table used as a virtual source table (VERSION-DEPENDENT)
SELECT t1~file_no,
       SUM( t1~fkimg ) AS total_fkimg
  FROM @invoice_lines AS t1
  GROUP BY t1~file_no
  INTO TABLE @DATA(invoice_totals).
```

> 📝 **Contextual snippet** — `min_items` is assumed to be declared in the surrounding program. The CDS view is read without `WITH PRIVILEGED ACCESS`, so its CDS access control applies (see the note at the end of the Joins section).

```abap
" Purchase orders with more than min_items open, non-deleted items, largest first
SELECT FROM i_purchaseorderitemapi01
  FIELDS purchaseorder,
         COUNT( * ) AS item_count
  WHERE iscompletelydelivered          IS INITIAL
    AND purchasingdocumentdeletioncode IS INITIAL
  GROUP BY purchaseorder
  HAVING COUNT( * ) > @min_items
  ORDER BY item_count DESCENDING
  INTO TABLE @DATA(large_orders).
```

> 💡 **`WHERE` vs. `HAVING`, and the `GROUP BY` rules.**
>
> 1. `WHERE` filters rows *before* grouping; `HAVING` filters groups *after* aggregation. Conditions on individual rows — like the two `IS INITIAL` checks above — belong in `WHERE`; `HAVING` is for conditions on aggregates such as `COUNT( * )`.
> 2. Every non-aggregated column in the `SELECT` list must also appear in `GROUP BY` — here, `purchaseorder`.
> 3. `ORDER BY` can refer to a `SELECT`-list alias, as `ORDER BY item_count DESCENDING` does. The example repeats `COUNT( * )` in `HAVING` rather than relying on the alias there.
> 4. `COUNT( * )` counts rows; `COUNT( DISTINCT col )` counts the distinct values of `col`.

> ⚠️ **VERSION-DEPENDENT: `IS INITIAL` in `WHERE`.** `IS INITIAL` compares a column with the initial value of its type; it is not the same as `IS NULL`. This matters for columns from the right-hand side of a `LEFT OUTER JOIN`: when there is no matching row, the column is `NULL`, not initial, so `IS INITIAL` does not match it. Older code writes the same check as `= @abap_false` or `= @space`. Verify `IS INITIAL` in ABAP SQL against the ABAP Keyword Documentation for your target release.

> 💡 **Join only data sources you read from or filter on.** A join that contributes no column to the result and no condition only adds cost — and if the join target is not unique for the join condition, it can multiply rows and inflate aggregates such as `COUNT( * )`.

## 🔤 LIKE, EXISTS / NOT EXISTS

> 📝 **Contextual snippet** — assumes the variables `search_text`, `plant`, `material` and `sales_org`, the ranges `order_range` and `material_range`, a custom table `zsm_t_exclusion`, and a customer-defined append field `zz_driver_id` on `VBAK`.

```abap
" LIKE with wildcard characters (ABAP wildcard '*' converted to SQL '%')
" Build the pattern in a SEPARATE, long-enough variable - never concatenate
" wildcards into the short field that holds the original value.
DATA vehicle         TYPE oig_vhlnmr.
DATA vehicle_pattern TYPE string.
DATA text_pattern    TYPE string.

vehicle_pattern = |%{ vehicle }%|.
text_pattern    = replace( val  = search_text
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
  WHERE oigv~vehicle LIKE @vehicle_pattern
  INTO TABLE @DATA(vehicles).

" EXISTS subquery
SELECT COUNT( * ) AS hits
  FROM zsm_t_entry
  WHERE werks = @plant
    AND EXISTS ( SELECT * FROM mara
                   WHERE matnr = @material
                     AND mtart = zsm_t_entry~mtart )
  INTO @DATA(match_count).

" NOT EXISTS subquery (anti-join)
SELECT DISTINCT vk~vbeln,
                vk~kunnr,
                oigd~drname
  FROM vbak AS vk
         INNER JOIN
           vbap AS vp ON vp~vbeln = vk~vbeln
             LEFT OUTER JOIN
               oigd ON oigd~perscode = vk~zz_driver_id
  WHERE     vk~vbeln IN @order_range
    AND     vp~matnr IN @material_range
    AND NOT EXISTS ( SELECT vkorg FROM zsm_t_exclusion
                       WHERE vkorg = @sales_org
                         AND kunnr = vk~kunnr )
    AND NOT EXISTS ( SELECT vgbel FROM lips
                       WHERE vgbel = vk~vbeln )
  INTO TABLE @DATA(open_orders).
```

> ⚠️ **A `WHERE` predicate on the right-hand table silently turns a `LEFT OUTER JOIN` into an inner join.** When no matching text row exists, the outer join supplies `NULL` for `oigvt~language`; a `WHERE oigvt~language = @sy-langu` then filters that row out — so the vehicles you were specifically trying to keep disappear. Restrictions on the **optional** side of an outer join belong in the `ON` clause, as shown above — [Rule 7.13](../docs/ABAP-Development-Rules.md#713-restrict-the-optional-side-of-an-outer-join-in-the-on-condition-not-in-where). This is one of the most common wrong-results bugs in production ABAP, and it never raises an error.

> 💡 Do not select `mandt` in a subquery just to have a column — pick a real business column (or use `SELECT @abap_true`). See the client-handling note above.

## 🧩 UNION

```abap
" UNION ALL (keeps duplicates)
SELECT name1 FROM kna1
  WHERE loevm = @abap_false
UNION ALL
SELECT name1 FROM lfa1
  WHERE loevm = @abap_false
INTO TABLE @DATA(names).

" UNION DISTINCT (removes duplicates)
SELECT name1 FROM kna1
  WHERE loevm = @abap_false
UNION DISTINCT
SELECT name1 FROM lfa1
  WHERE loevm = @abap_false
INTO TABLE @DATA(distinct_names).
```

## 🐢 FOR ALL ENTRIES IN

`FOR ALL ENTRIES` is the classical way to "join" a driver internal table against the database when a real `JOIN`/subquery isn't possible or practical — [Rule 7.4](../docs/ABAP-Development-Rules.md#74-use-for-all-entries-only-with-a-non-empty-de-duplicated-driver-table).

> 📝 **Contextual snippet** — assumes an internal table `order_items` with the components `vbeln` and `posnr`.

```abap
IF order_items IS NOT INITIAL.
  DATA(driver_items) = order_items.

  " Prepare the driver table: no duplicates, no initial key values
  SORT driver_items BY vbeln posnr.
  DELETE ADJACENT DUPLICATES FROM driver_items COMPARING vbeln posnr.
  DELETE driver_items WHERE posnr IS INITIAL.

  IF driver_items IS NOT INITIAL.
    SELECT vbfa~vbeln,
           vbfa~posnn,
           vbfa~vbtyp_n
      FROM vbfa
      FOR ALL ENTRIES IN @driver_items
      WHERE vbfa~vbeln = @driver_items-vbeln
        AND vbfa~posnn = @driver_items-posnr
      INTO TABLE @DATA(document_flow).

    " ORDER BY is not possible here (see rule 5 below) - sort in ABAP
    SORT document_flow BY vbeln posnn.
  ENDIF.
ENDIF.
```

> ⚠️ **Critical `FOR ALL ENTRIES` rules:**
> 1. **Always check that the driver table is not initial** before the `SELECT`. If it is empty, `FOR ALL ENTRIES` behaves as if there were **no `WHERE` condition at all** and reads the entire database table.
> 2. **Sort and remove duplicates** from the driver table first — duplicate driver rows cause redundant database work.
> 3. **`FOR ALL ENTRIES` applies an implicit `DISTINCT`.** Duplicate rows are removed from the result set automatically. If two source rows are legitimately identical in the selected columns, one of them silently disappears — so always select enough key columns to keep the rows distinguishable. This is the rule most often discovered the hard way, via wrong totals.
> 4. **The driver column must be type-compatible** with the database column it is compared against.
> 5. **Restrictions on the other clauses.** According to the ABAP Keyword Documentation, `ORDER BY` can only be used as `ORDER BY PRIMARY KEY`, for a single table or view, and only when all primary key columns are in the result. Aggregate expressions other than `COUNT( * )` are not allowed, and `GROUP BY` has no effect. `UP TO`, `OFFSET` and `PACKAGE SIZE` apply only to the rows passed to ABAP after duplicates are removed. Sort the result in ABAP if the ordering matters, as above.

> 💡 Only join tables you actually read from. An earlier version of this example selected `vbak~auart` without joining `VBAK` — a syntax error. If you need header data as well, either add an explicit `INNER JOIN` (note that combining `JOIN` with `FOR ALL ENTRIES` has its own restrictions) or read it in a second statement.

## 🏗️ Building Range Tables from a SELECT

> 📝 **Contextual snippet** — assumes a structure `input` with the table component `tag_names` and the component `plant`, a custom table `zsm_t_tag`, and a proxy structure `proxy_response` whose component names are generated and kept ([Rule 2.4](../docs/ABAP-Development-Rules.md#24-keep-names-that-are-fixed-by-a-signature-you-do-not-own)).

> ⚠️ **VERSION-DEPENDENT: literals and internal tables in the SELECT.** Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) for your target release.

```abap
DATA plant_range TYPE RANGE OF werks_d.

SELECT 'I'         AS sign,
       'EQ'        AS option,
       t001w~werks AS low
  FROM t001w
  INTO CORRESPONDING FIELDS OF TABLE @plant_range.

DATA tag_range TYPE RANGE OF zsm_e_tag.

SELECT FROM @input-tag_names AS t1
  FIELDS 'I'     AS sign,
         'EQ'    AS option,
         t1~name AS low
  INTO CORRESPONDING FIELDS OF TABLE @tag_range.

SELECT FROM zsm_t_tag
  FIELDS tag_name,
         'Units'  AS property_name,
         unit     AS property_value
  WHERE werks     = @input-plant
    AND tag_name IN @tag_range
  INTO CORRESPONDING FIELDS OF TABLE @proxy_response-get_tag_info_response-properties.
```

## 🧪 Dynamic SQL

```abap
DATA field_name  TYPE fieldname.
DATA table_name  TYPE tabname.
DATA conditions  TYPE TABLE OF string.
DATA value_range TYPE RANGE OF char30.
DATA result_ref  TYPE REF TO data.

FIELD-SYMBOLS <result_table> TYPE STANDARD TABLE.

" In a DYNAMIC condition the ABAP data object is written with the same
" @ host-variable escape as in static ABAP SQL, as in the examples of the
" ABAP Keyword Documentation.
conditions = VALUE #( ( |{ field_name } IN @value_range| ) ).

" The target must be created dynamically too, because its type is not
" known until runtime.
CREATE DATA result_ref TYPE TABLE OF (table_name).
ASSIGN result_ref->* TO <result_table>.

SELECT DISTINCT (field_name)
  FROM (table_name)
  WHERE (conditions)
  INTO CORRESPONDING FIELDS OF TABLE @<result_table>.
```
> ⚠️ **Two separate risks, and you must address both.**
> 1. **Injection.** Dynamic table/field/condition tokens must come from trusted, validated sources — never build them from unvalidated user input. Check names with `cl_abap_dyn_prg` and keep values as host variables inside the token, as above — [Rule 8.4](../docs/ABAP-Development-Rules.md#84-build-dynamic-sql-and-other-dynamic-tokens-only-from-validated-input).
> 2. **Authorization.** A dynamic `SELECT` performs **no** implicit authorization check. Verifying that a table exists in the Data Dictionary proves existence, not access rights. See [11-Classical-Reports](../11-Classical-Reports/README.md#-dynamic-reports--building-tables-and-field-catalogs-at-runtime) for the generic table-access authorization check.
>
> Dynamic `SELECT` over arbitrary Dictionary tables is also restricted in ABAP Cloud — see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 🧭 Other Frequently Used WHERE Patterns

> 📝 **Contextual snippet** — assumes the variables `task_number`, `notification_number`, `first_type` and `last_type`.

```abap
" Host expression as a constant column in the SELECT list (VERSION-DEPENDENT)
SELECT SINGLE v1~qmnum,
              @task_number AS task_no,
              v1~ernam
  FROM qmel AS v1
  WHERE v1~qmnum = @notification_number
  INTO @DATA(notification).

" The fragments below are WHERE-clause forms, not complete statements.
" BETWEEN
"   WHERE mara~mtart BETWEEN @first_type AND @last_type
" Value list
"   WHERE vbfa~vbtyp_v IN ( 'C', 'L', 'K', 'I', 'H' )
" Multiple LIKE conditions
"   WHERE ( matnr LIKE 'J%' OR matnr LIKE 'T%' )
" Validity date range
"   WHERE begda <= @sy-datum AND endda >= @sy-datum
```

> 💡 **`ORDER BY PRIMARY KEY`** is only permitted when the result set contains the table's complete primary key — it is not a general-purpose "stable sort". For a projection, list the columns explicitly: `ORDER BY vbeln, posnr`.

## 🧾 Writing Log Records

A custom log table needs a unique key for each entry. Two patterns that look harmless cause most of the problems:

- **Reading the highest key and adding one.** Two sessions that run at the same time read the same maximum and write the same key; one insert fails or overwrites the other.
- **Committing inside the logging method.** The commit closes the caller's SAP LUW as well ([Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work)); with `AND WAIT` it also makes every log call wait for the update ([Rule 7.14](../docs/ABAP-Development-Rules.md#714-use-commit-work-and-wait-only-when-the-next-step-depends-on-the-update)).

> 📝 **Contextual snippet** — assumes a custom table `zsm_t_log` with the key field `log_id` and the field `message`, and a method `write_log` with the parameter `message`, declared with `RAISING cx_uuid_error`. The UUID call follows the example for `CL_SYSTEM_UUID` in the ABAP Keyword Documentation.

```abap
" ❌ race condition on the key, and a commit inside a reusable method
METHOD write_log.
  SELECT MAX( log_id ) FROM zsm_t_log INTO @DATA(last_log_id).
  DATA(log_entry) = VALUE zsm_t_log( log_id  = last_log_id + 1
                                     message = message ).
  INSERT zsm_t_log FROM @log_entry.
  COMMIT WORK AND WAIT.
ENDMETHOD.
```

```abap
" ✅ unique key without reading the table; the caller owns the transaction
METHOD write_log.
  " create_uuid_x16( ) raises CX_UUID_ERROR; write_log passes it to the caller
  DATA(log_entry) = VALUE zsm_t_log( log_id  = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( )
                                     message = message ).
  INSERT zsm_t_log FROM @log_entry.
ENDMETHOD.
```

Where the key must be a readable running number, draw it from a number range object instead of reading the table.

## ✅ Best Practices

- Write strict ABAP SQL with `@` host variables and `INTO` after the query clauses, followed only by `UP TO` / `OFFSET` — [Rule 7.1](../docs/ABAP-Development-Rules.md#71-write-strict-abap-sql-a-comma-separated-field-list--host-variables-into-after-the-query-clauses).
- Select only the fields you need — avoid `SELECT *` in production code, especially inside loops — [Rule 7.7](../docs/ABAP-Development-Rules.md#77-list-the-fields-you-need-instead-of-select-).
- Always qualify `SELECT SINGLE` with a `WHERE` on the full key. Without one you get an arbitrary row — [Rule 7.5](../docs/ABAP-Development-Rules.md#75-use-select-single-only-with-the-full-primary-key).
- Always check `IF driver_items IS NOT INITIAL` before `FOR ALL ENTRIES`, and de-duplicate the driver table first — [Rule 7.4](../docs/ABAP-Development-Rules.md#74-use-for-all-entries-only-with-a-non-empty-de-duplicated-driver-table).
- Use `SELECT SINGLE @abap_true ... INTO @DATA(...)` + `xsdbool( sy-subrc = 0 )` for existence checks instead of `COUNT(*)` when you don't need the exact count — [Rule 7.6](../docs/ABAP-Development-Rules.md#76-check-existence-with-select-single-abap_true).
- Prefer joins and subqueries over `FOR ALL ENTRIES` or a `SELECT` in a loop — [Rule 7.3](../docs/ABAP-Development-Rules.md#73-do-not-select-inside-a-loop).
- Put restrictions on the optional side of an outer join in the `ON` clause, not in `WHERE` — [Rule 7.13](../docs/ABAP-Development-Rules.md#713-restrict-the-optional-side-of-an-outer-join-in-the-on-condition-not-in-where).
- Let ABAP SQL handle the client — [Rule 7.8](../docs/ABAP-Development-Rules.md#78-let-abap-sql-handle-the-client) — and write only to your own tables — [Rule 7.9](../docs/ABAP-Development-Rules.md#79-write-only-to-your-own-tables-change-sap-standard-data-through-bapis-or-released-apis).
- **Let the transaction owner commit.** Reusable code performs its DML and reports the outcome; the top-level caller decides between `COMMIT WORK` and `ROLLBACK WORK`. Reserve `AND WAIT` for the case where the same program must immediately re-read what it wrote — [Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work) and [Rule 7.14](../docs/ABAP-Development-Rules.md#714-use-commit-work-and-wait-only-when-the-next-step-depends-on-the-update).
- Check `sy-dbcnt` after a mass `UPDATE`/`DELETE` to confirm the number of rows actually affected — [Rule 7.15](../docs/ABAP-Development-Rules.md#715-qualify-mass-update-and-delete-with-where-and-check-sy-dbcnt).
- Justify every `WITH PRIVILEGED ACCESS` in a comment, and validate every dynamic token — [Rule 8.3](../docs/ABAP-Development-Rules.md#83-use-with-privileged-access-only-with-a-written-justification) and [Rule 8.4](../docs/ABAP-Development-Rules.md#84-build-dynamic-sql-and-other-dynamic-tokens-only-from-validated-input).

## ⚠️ Common Mistakes

- Running `FOR ALL ENTRIES` with an **empty driver table** — silently selects everything.
- Forgetting the implicit `DISTINCT` that `FOR ALL ENTRIES` applies, and losing rows from the result.
- Filtering the optional side of a `LEFT OUTER JOIN` in the `WHERE` clause, turning it into an inner join.
- Placing `INTO` in different positions across a program — write it after the query clauses, followed only by `UP TO`, `OFFSET` and the other ABAP-specific additions.
- Adding `ORDER BY` with columns to a `FOR ALL ENTRIES` select — only `ORDER BY PRIMARY KEY` is possible there; sort in ABAP.
- Deriving a new key from `SELECT MAX( … ) + 1` — concurrent sessions get the same value.
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
- [07-Internal-Tables](../07-Internal-Tables/README.md) — internal tables as targets and as data sources
- [15-BAPIs](../15-BAPIs/README.md) — transaction control for BAPI calls
- [19-Performance](../19-Performance/README.md) — SQL trace and database access patterns
- [20-Best-Practices](../20-Best-Practices/README.md) — the data-access items of the review checklist
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle context

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE11 | Data Dictionary (table/structure maintenance) |
| SE16N | Table data browser |
| ST05 | SQL Trace (analyze SELECT performance) |
| SE30 / SAT | Runtime analysis |
