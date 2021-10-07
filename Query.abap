" SELECT SINGLE
SELECT SINGLE *
    INTO @DATA(ls_data)
    FROM mara.

" SELECT ALL   
SELECT *
    INTO TABLE @DATA(lt_data)
    FROM vbrk.

" SELECT MAX
SELECT MAX( posnr )
    INTO @DATA(lv_posnr)
    FROM lips
    WHERE vbeln EQ @ip_vbeln.

" SELECT ALL FIELDS
SELECT MARA~*,
       marc~prctr
    FROM marc
    INNER JOIN mara ON mara~matnr EQ marc~matnr
    WHERE is_default EQ @abap_true
    INTO TABLE @DATA(lt_data). 

" SELECT CASE
SELECT CASE WHEN strkorr NE @space THEN strkorr
            ELSE 'A'
       END AS request_no
    FROM e070
    INTO TABLE @DATA(lt_request).

" SELECT CALCULATION
SELECT brgew, ntgew, gewei, ABS( brgew - ntgew ) AS diff
    FROM mara
    INTO TABLE @DATA(lt_mara).

" SELECT UNION ALL
SELECT name1
    FROM kna1
    WHERE loevm EQ @abap_false
  UNION ALL
SELECT name1
    FROM lfa1
    WHERE loevm EQ @abap_false
INTO TABLE @DATA(lt_names). 

" SELECT UNION ALL & DISTINCT
SELECT name1
    FROM kna1
    WHERE loevm EQ @abap_false
  UNION DISTINCT
SELECT name1
    FROM lfa1
    WHERE loevm EQ @abap_false
INTO TABLE @DATA(lt_names).

" INNER JOIN
SELECT *
    INTO CORRESPONDING FIELDS OF TABLE itab
    FROM vbrk
    INNER JOIN vbrp ON vbrp~vbeln EQ vbrk~vbeln
    INNER JOIN mara ON mara~matnr EQ vbrp~matnr
    WHERE vbrk~mandt EQ @sy-mandt  
      AND vbrk~vbeln IN @ir_vbeln.

" FOR ALL ENTRIES IN
IF lt_itab[] IS NOT INITIAL.
    SELECT  vbfa~vbeln,
            vbfa~posnn,
            vbak~auart
    FROM vbfa
    INTO TABLE @DATA(gt_auart)
    FOR ALL ENTRIES IN @lt_itab
    WHERE vbfa~vbeln EQ @lt_itab-vbeln 
      AND vbfa~posnn EQ @lt_itab-posnr.
ENDIF.

" INTO RANGE TABLE 
DATA lt_werks_range TYPE RANGE OF werks_d.

SELECT 'I'  AS sign,
       'EQ' AS option,
        t001w~werks AS low
  FROM t001w
  INTO CORRESPONDING FIELDS OF TABLE @lt_werks_range. 

" ADD WHERE CUSTOM RANGE
WHERE vbfa~vbtyp_v IN ('C','L','K','I','H').
