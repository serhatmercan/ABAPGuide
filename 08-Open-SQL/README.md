# 08 — Open SQL

## 📖 Introduction

Open SQL is ABAP's database-independent SQL dialect. This chapter covers basic CRUD statements against custom (Z) tables, and a comprehensive set of `SELECT` patterns — joins, aggregation, subqueries, dynamic SQL, and building range tables directly from a query.

## 🗃️ CRUD on Custom Tables

```abap
" Internal table used as the source/target for all examples below
DATA lt_data TYPE TABLE OF zsm_t_data.

" INSERT - from an internal table
APPEND LINES OF lt_data TO zsm_t_data.
COMMIT WORK AND WAIT.

" DELETE - by a full structure (matches on primary key)
DELETE zsm_t_data FROM ls_data.
COMMIT WORK AND WAIT.

" DELETE - with a WHERE condition
DELETE FROM zsm_t_data WHERE name = 'Serhat'.
COMMIT WORK AND WAIT.

" DELETE - from multiple custom tables
DELETE FROM zsm_t_data_01 WHERE name = 'Serhat'.
DELETE FROM zsm_t_data_02 WHERE name = 'Serhat'.

" INSERT - from an internal table (bulk insert)
INSERT zsm_t_data FROM TABLE lt_data.
COMMIT WORK AND WAIT.

" INSERT - from a single structure
INSERT zsm_t_data FROM ls_data.
COMMIT WORK AND WAIT.

" MODIFY - insert or update, from a single structure
MODIFY zsm_t_data FROM ls_data.
COMMIT WORK AND WAIT.

" MODIFY - insert or update, from an internal table
CHECK lt_data[] IS NOT INITIAL.
MODIFY zsm_t_data FROM TABLE lt_data.
COMMIT WORK AND WAIT.

" UPDATE - from a single structure
UPDATE zsm_t_data FROM ls_data.
COMMIT WORK AND WAIT.

" UPDATE - with a WHERE condition
UPDATE zsm_t_data SET name = 'Serhat' WHERE vbeln = ls_data-vbeln AND posnr = ls_data-posnr.
COMMIT WORK AND WAIT.

" UPDATE - multiple fields from another table's row
UPDATE zsm_t_log SET  density       = is_ticket-density
                      volume_uom    = is_ticket-volume_uom
                      process       = '01'
                WHERE sns_number = is_ticket-sns_number.

" UPDATE - directly from a constructed VALUE (no intermediate structure variable)
UPDATE zsm_t_data FROM @( VALUE #( customer      = iv_customer
                                   request_count = iv_request_count
                                   izonay_id     = lv_izonay_id ) ).
COMMIT WORK AND WAIT.
```

> ⚠️ **Warning:** `DELETE`/`UPDATE`/`INSERT`/`MODIFY` against the database are **not visible to other sessions** until `COMMIT WORK` — and should typically be followed by `COMMIT WORK AND WAIT` in RFC/BAPI-style processing so the caller can rely on the data being persisted. Never issue a `COMMIT WORK` inside a `LOOP` for performance reasons — batch it after the loop, or use `PERFORM ON COMMIT`.

## 🔍 SELECT — Single Row / All Rows

```abap
" SELECT SINGLE
SELECT SINGLE * FROM mara
  INTO @DATA(ls_data).

" SELECT SINGLE into multiple target variables
SELECT SINGLE canpos~modul,
              canpos~modul_txt
  FROM zhr_t_canpos AS canpos
  INTO ( @DATA(lv_modul), @DATA(lv_modul_txt) ).

" SELECT ALL rows into an internal table
SELECT * FROM vbrk
  INTO TABLE @DATA(lt_data).

" SELECT MAX (aggregate, single value)
SELECT max(posnr) FROM lips
  INTO @DATA(lv_posnr)
  WHERE vbeln = @p_vbeln.
```

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
SELECT SINGLE MAX(a~vbeln) AS vbeln,
              a~posnr
  FROM vbap AS a
         INNER JOIN
           vbak AS b ON a~vbeln = b~vbeln
  WHERE a~abgru = space AND b~auart = 'ZKLF'
  GROUP BY a~posnr
  INTO ( @DATA(lv_vbeln), @DATA(lv_posnr) ).

" Selecting all fields of one table plus specific fields of another (mara~*, marc~prctr)
SELECT mara~*,
       marc~prctr
  FROM marc
         INNER JOIN
           mara ON mara~matnr = marc~matnr
  WHERE marc~is_default = @abap_true
  INTO TABLE @DATA(lt_data).

" A classic multi-table join
SELECT *
  FROM vbrk
         INNER JOIN
           vbrp ON vbrp~vbeln = vbrk~vbeln
             INNER JOIN
               mara ON mara~matnr = vbrp~matnr
  WHERE vbrk~mandt  = @sy-mandt
    AND vbrk~vbeln IN @ir_vbeln
  INTO TABLE @DATA(itab).

" Joining the database against an already-selected internal table
SELECT rbukrs, gjahr, belnr
  FROM acdoca AS a
         INNER JOIN
           @lt_skb1 AS b ON b~saknr = a~racct
  WHERE rbukrs  = @iv_bukrs
    AND rldnr   = '0L'
    AND gjahr   = @iv_gjahr
    AND rbusa  IN @ir_gsber
  INTO TABLE @DATA(lt_acdoca).
```

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
SELECT SINGLE concat_with_space( first_name, last_name, 1 )
  FROM oigd
  WHERE perscode = @et_liste-stcno
  INTO @et_liste-drname.

" Date-difference function
SELECT v1~qmnum,
       v1~product_group,
       dats_days_between( @sy-datum, v1~ltrmn ) AS days_of_remain
  FROM @lt_data AS v1
         LEFT OUTER JOIN
           zpp_i_characteristic_values AS v2 ON v2~atwrt = v1~product_group
  INTO TABLE @DATA(lt_data_cl).

" RIGHT() string function
SELECT DISTINCT parent_key,
                right( dlv~base_btd_id, 10 )    AS vbeln,
                right( dlv~base_btditem_id, 6 ) AS posnr
  FROM @lt_dlv_ref AS dlv
  INTO TABLE @gt_data.
```

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

SELECT SINGLE 1
  FROM ekko AS t1
         INNER JOIN
           ekpo AS t2 ON t2~ebeln = t1~ebeln
  WHERE t1~bstyp IN @lt_document_categories
    AND t1~kdatb <= @sy-datum
    AND t1~kdate >= @sy-datum
    AND t2~matnr  = @iv_material
    AND t2~loekz  = ''
  INTO @DATA(lv_pa_exist_count).

DATA(lv_pa_exist) = xsdbool( sy-subrc = 0 ).

" COUNT DISTINCT with GROUP BY
TYPES: BEGIN OF lty_order_appointment,
         begin_time   TYPE ztprsd0036-begin_time,
         finisih_time TYPE ztprsd0036-finisih_time,
         order_count  TYPE i,
       END OF lty_order_appointment.
DATA lt_order_appointments TYPE STANDARD TABLE OF lty_order_appointment WITH EMPTY KEY.

SELECT t1~begin_time,
       t1~finisih_time,
       COUNT( DISTINCT t1~order ) AS order_count
  FROM ztprsd0036 AS t1
         INNER JOIN
           vbak AS t2 ON  t2~vbeln = t1~order
                      AND t2~kunnr = @iv_customer
  WHERE t1~date    = @lv_date
    AND t1~xkapali = @abap_false
  GROUP BY t1~begin_time,
           t1~finisih_time
  INTO TABLE @lt_order_appointments.

" DISTINCT
SELECT DISTINCT charg FROM zsm_t_charg
  INTO TABLE @DATA(lt_charg)
  WHERE matnr = @lv_matnr.

" SUM + GROUP BY + ORDER BY
SELECT mch1~vfdat                     AS vfdat,
       mch1~charg                     AS charg,
       SUM( mchb~clabs + mchb~cinsm ) AS clabs
  FROM mcha
         INNER JOIN
           mchb ON mcha~charg = mchb~charg
             INNER JOIN
               marc ON marc~matnr = mcha~matnr
                 INNER JOIN
                   mch1 ON  mch1~charg = mcha~charg
                        AND mch1~matnr = mcha~matnr
  WHERE mcha~matnr  = @im_mt61d-matnr
    AND mcha~werks  = @im_mt61d-werks
    AND mcha~lvorm  = abap_false
    AND mchb~clabs <> abap_false
  GROUP BY mch1~vfdat,
           mch1~charg
  ORDER BY mch1~vfdat,
           mch1~charg
  INTO TABLE @DATA(lt_data).

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

" SUM against an internal table used as a virtual source table
SELECT t1~file_no,
       SUM( t1~fkimg ) AS total_fkimg
  FROM @lt_invoice_sum AS t1
  GROUP BY t1~file_no
  INTO TABLE @DATA(lt_invoice_sum_amount).
```

## 🔤 LIKE, EXISTS / NOT EXISTS

```abap
" LIKE with wildcard characters (ABAP wildcard '*' converted to SQL '%')
DATA lv_upper_vehicle_text_en TYPE c LENGTH 50.
DATA lv_upper_vehicle_text_tr TYPE c LENGTH 50.
DATA lv_vehicle               TYPE oig_vhlnmr.

CONCATENATE '%' lv_vehicle '%' INTO lv_vehicle.
CONDENSE lv_vehicle.

REPLACE ALL OCCURRENCES OF '*' IN lv_upper_vehicle_text_tr WITH '%'.
REPLACE ALL OCCURRENCES OF '*' IN lv_upper_vehicle_text_en WITH '%'.
REPLACE ALL OCCURRENCES OF '*' IN lv_vehicle               WITH '%'.

SELECT oigv~vehicle,
       oigv~veh_type,
       oigvt~veh_text,
       toigvt~veh_text AS veh_type_text
  FROM oigv
         LEFT OUTER JOIN
           oigvt ON oigvt~vehicle = oigv~vehicle
             LEFT OUTER JOIN
               toigvt ON toigvt~veh_type = oigv~veh_type
  WHERE oigv~vehicle   LIKE @lv_vehicle
    AND oigvt~language    = @sy-langu
    AND (    oigvt~veh_text LIKE @lv_upper_vehicle_text_tr
          OR oigvt~veh_text LIKE @lv_upper_vehicle_text_en )
    AND toigvt~language = @sy-langu
  INTO TABLE @DATA(lt_vehicles).

" EXISTS subquery
SELECT COUNT( * ) FROM zsm_t_data
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
               oigd ON oigd~zdtckno = vk~zz1_drivertcno_sdh
  WHERE     vk~vbeln IN @lr_vbeln
    AND     vp~matnr IN @lr_matnr
    AND NOT EXISTS ( SELECT mandt FROM zsd_t_007
                       WHERE vkorg = @lv_vkorg
                         AND kunnr = vk~kunnr )
    AND NOT EXISTS ( SELECT mandt FROM lips
                       WHERE vgbel = vk~vbeln )
  INTO TABLE @DATA(lt_data).
```

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
IF lt_itab[] IS NOT INITIAL.
  DATA(lt_itabx) = lt_itab.

  SORT lt_itabx BY vbeln
                   posnr.
  DELETE ADJACENT DUPLICATES FROM lt_itabx COMPARING vbeln posnr.
  DELETE lt_itabx WHERE posnr IS INITIAL.

  IF lt_itabx[] IS NOT INITIAL.
    SELECT vbfa~vbeln,
           vbfa~posnn,
           vbak~auart
      FROM vbfa
      FOR ALL ENTRIES IN @lt_itabx
      WHERE vbfa~vbeln = @lt_itabx-vbeln
        AND vbfa~posnn = @lt_itabx-posnr
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_vbfa).
  ENDIF.
ENDIF.
```

> ⚠️ **Critical `FOR ALL ENTRIES` rules:**
> 1. **Always check the driver table is not initial** before the `SELECT` — if it's empty, `FOR ALL ENTRIES` behaves as if there were **no WHERE condition at all** and selects the entire database table!
> 2. **Sort and remove duplicates** from the driver table first — duplicate driver rows cause redundant, wasted DB work.
> 3. Any field used in `FOR ALL ENTRIES ... WHERE x = @driver-x` **must not be a key field with an initial value only** — filter those out too (`DELETE ... WHERE posnr IS INITIAL` above).

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
DATA lv_condition   TYPE string.
DATA lv_fieldname   TYPE fieldname.
DATA lv_table       TYPE tabname.
DATA lv_field_range TYPE RANGE OF char30.

lv_condition = |{ lv_fieldname } IN @<ls_dyn_prm>-field_range |.

SELECT DISTINCT (lv_fieldname)
  FROM (lv_table)
  WHERE (lv_condition)
  INTO TABLE @lt_dynamic_table.
```
> ⚠️ Dynamic table/field/condition names (`(lv_table)`) must come from **trusted, validated sources** — never build them directly from unvalidated user input, to avoid ABAP-equivalent SQL-injection-style risks.

## 🧭 Other Frequently Used WHERE Patterns

```abap
" Parameter as a constant column in the SELECT list
SELECT SINGLE v1~qmnum,
              @iv_task_no AS task_no,
              v1~ernam
  FROM qmel AS v1
  WHERE v1~qmnum = @iv_qmnum
  INTO @DATA(ls_qmel).

" BETWEEN
WHERE mara~mtart BETWEEN 'Z004' AND 'Z006'.

" Range list with IN ( ... )
WHERE vbfa~vbtyp_v IN ( 'C', 'L', 'K', 'I', 'H' ).

" Multiple LIKE conditions
WHERE ( matnr LIKE 'J%' OR matnr LIKE 'T%' ).

" Validity date range
WHERE begda LE @sy-datum
  AND endda GE @sy-datum.

" ORDER BY primary key (recommended for FOR ALL ENTRIES / stable pagination)
ORDER BY PRIMARY KEY.
```

## ✅ Best Practices

- Select only the fields you need — avoid `SELECT *` in production code, especially inside loops.
- Always check `IF lt_driver[] IS NOT INITIAL` before `FOR ALL ENTRIES` and de-duplicate the driver table first.
- Use `SELECT SINGLE 1 ... INTO @DATA(...)` + `xsdbool( sy-subrc = 0 )` for existence checks instead of `COUNT(*)` when you don't need the exact count.
- Prefer native Open SQL joins/subqueries over `FOR ALL ENTRIES` when possible — joins push more work to the database and avoid the pitfalls above.
- Always `COMMIT WORK AND WAIT` after DML statements that a subsequent step depends on (e.g., before returning from a BAPI wrapper).

## ⚠️ Common Mistakes

- Running `FOR ALL ENTRIES` with an **empty driver table** — silently selects everything.
- Using `SELECT ... ENDSELECT` loops (row-by-row DB round trips) instead of a single `SELECT ... INTO TABLE`.
- Missing `COMMIT WORK` after `INSERT`/`UPDATE`/`DELETE`, leaving changes locked in the current LUW only.
- Building dynamic SQL fragments directly from screen/user input without validation.

## 🎤 Interview Tips

- Explain the risks of `FOR ALL ENTRIES` and how to mitigate them.
- Compare `JOIN` vs. `FOR ALL ENTRIES` vs. nested `SELECT`s — when would you use each?
- Explain the ABAP LUW concept and why `COMMIT WORK` matters.
- Be ready to write a query using `GROUP BY`/`HAVING`-equivalent aggregation and explain performance implications of `SELECT *`.

## 🔗 Related Chapters

- [06-Loops](../06-Loops/README.md) — range tables used in `WHERE ... IN`
- [07-Internal-Tables](../07-Internal-Tables/README.md)
- [19-Performance](../19-Performance/README.md)

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE11 | Data Dictionary (table/structure maintenance) |
| SE16N | Table data browser |
| ST05 | SQL Trace (analyze SELECT performance) |
| SE30 / SAT | Runtime analysis |
