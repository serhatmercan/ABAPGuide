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

" SELECT SINGLE MAX | AS | GROUP BY
SELECT SINGLE MAX( a~vbeln ) a~posnr 
    FROM vbap AS a
    INNER JOIN vbak AS b ON a~vbeln EQ b~vbeln 
    INTO (lv_vbeln, lv_posnr)
    WHERE a~abgru EQ space
      AND b~auart EQ 'ZKLF' 
    GROUP BY a~posnr.

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

" SELECT COUNT
SELECT COUNT(*) FROM t001w WHERE werks EQ @lv_werks.
IF sy-subrc NE 0.
ENDIF.

" SELECT DISTINCT
SELECT DISTINCT charg
      FROM zsm_t_charg 
      INTO TABLE @DATA(lt_charg)
      WHERE matnr EQ @lv_matnr.

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

" SELECT SUM & GROUP & ORDER
SELECT mch1~vfdat AS vfdat,
       mch1~charg AS charg,
       SUM( mchb~clabs + mchb~cinsm ) AS clabs
    INTO CORRESPONDING FIELDS OF TABLE @lt_data
    FROM mcha
    INNER JOIN mchb
        ON mcha~charg EQ mchb~charg
    INNER JOIN marc
        ON marc~matnr EQ mcha~matnr
    INNER JOIN mch1
        ON mch1~charg EQ mcha~charg
        AND mch1~matnr EQ mcha~matnr
    WHERE mcha~matnr EQ @im_mt61d-matnr
        AND mcha~werks EQ @im_mt61d-werks
        AND mcha~lvorm EQ abap_false
        AND mchb~clabs NE abap_false
    GROUP BY mch1~vfdat, mch1~charg
    ORDER BY mch1~vfdat, mch1~charg.

" ORDER BY
ORDER BY PRIMARY KEY.

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

" ADD WHERE CUSTOM LIKE
WHERE ( matnr LIKE 'J%' OR matnr LIKE 'T%' ).

" LIMIT
SELECT * 
    UP TO 10 ROWS
    FROM mara
    INTO TABLE @DATA(lt_mara).

" APPEND
DATA: BEGIN OF lt_lgort OCCURS 0,
        lgort TYPE lgort_d,
      END OF lt_lgort.

SELECT lgort 
  FROM mchb
  INTO CORRESPONDING FIELDS OF TABLE lt_lgort
    WHERE matnr EQ lv_matnr
      AND werks EQ '1000'
      AND ( ( clabs GT 0 ) OR ( cinsm GT 0 ) OR ( cspem GT 0 ) ).

SELECT lgort 
  FROM mspr
  APPENDING CORRESPONDING FIELDS OF TABLE lt_lgort
    WHERE matnr EQ lv_matnr
      AND werks EQ '1000'
      AND ( ( prlab GT 0 ) OR ( prins GT 0 ) OR ( prspe GT 0 ) ).
