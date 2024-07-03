" SELECT SINGLE
SELECT SINGLE *
  INTO @DATA(ls_data)
  FROM mara.

" SELECT SINGLE TO DATA
SELECT SINGLE canpos~modul, canpos~modul_txt
  INTO (@<ls_candis>-modul, @<ls_candis>-modul_txt)
  FROM zhr_t_canpos AS canpos.

" SELECT ALL   
SELECT *
  INTO TABLE @DATA(lt_data)
  FROM vbrk.

" SELECT MAX
SELECT MAX( posnr )
  INTO @DATA(lv_posnr)
  FROM lips
  WHERE vbeln EQ @ip_vbeln.

" SELECT LEFT OUTER JOIN
SELECT SINGLE mara~matnr, makt~maktx
  INTO DATA(ls_material)
  FROM mara
  LEFT OUTER JOIN makt
    ON makt~matnr EQ makt~matnr
  WHERE matnr EQ @iv_matnr. 

" SELECT SINGLE MAX | AS | GROUP BY
SELECT SINGLE MAX( a~vbeln ) a~posnr 
  FROM vbap AS a
  INNER JOIN vbak AS b ON a~vbeln EQ b~vbeln 
  INTO (lv_vbeln, lv_posnr)
  WHERE a~abgru EQ space
    AND b~auart EQ 'ZKLF' 
  GROUP BY a~posnr.

" SELECT ALL FIELDS
SELECT mara~*,
       marc~prctr
  FROM marc
  INNER JOIN mara 
    ON mara~matnr EQ marc~matnr
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
SELECT COUNT(*) 
  FROM t001w 
  WHERE werks EQ @lv_werks.
IF sy-subrc NE 0.
ENDIF.

" SELECT w/ CONCATENATE TWO FIELDS w/ SPACE
SELECT SINGLE concat_with_space( first_name, last_name, 1 )
  FROM oigd
  WHERE perscode EQ @et_liste-stcno
  INTO @et_liste-drname.

" SELECT DISTINCT
SELECT DISTINCT charg
  FROM zsm_t_charg 
  INTO TABLE @DATA(lt_charg)
  WHERE matnr EQ @lv_matnr.

" SELECT EXIST
SELECT COUNT( * ) 
  FROM zsm_t_data 
  WHERE werks EQ iv_werks 
    AND EXISTS ( SELECT * 
                  FROM mara 
                  WHERE matnr EQ iv_matnr 
                    AND mtart EQ zsm_t_data~mtart ).

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

" SELECT w/ LIKE
DATA: lv_upper_vehicle_text_en(50),
      lv_upper_vehicle_text_tr(50),
      lv_vehicle TYPE oig_vhlnmr.

CONCATENATE '%' lv_vehicle '%' INTO lv_vehicle.
CONDENSE lv_vehicle.

REPLACE ALL OCCURRENCES OF '*' IN:
  lv_upper_vehicle_text_tr WITH '%',
  lv_upper_vehicle_text_en WITH '%',
  lv_vehicle WITH '%'.

SELECT oigv~vehicle,
       oigv~veh_type, 
       oigvt~veh_text,
       toigvt~veh_text AS veh_type_text
  FROM oigv
  LEFT OUTER JOIN oigvt ON oigvt~vehicle EQ oigv~vehicle
  LEFT OUTER JOIN toigvt ON toigvt~veh_type EQ oigv~veh_type
  WHERE oigv~vehicle LIKE @lv_vehicle
    AND oigvt~language EQ @sy-langu
    AND ( oigvt~veh_text LIKE @lv_upper_vehicle_text_tr OR
          oigvt~veh_text LIKE @lv_upper_vehicle_text_en )
    AND toigvt~language EQ @sy-langu
    INTO TABLE @DATA(lt_vehicles).

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

" INNER JOIN w/ Internal Table
SELECT rbukrs, gjahr, belnr
    FROM acdoca AS a
    INNER JOIN @lt_skb1 AS b ON b~saknr EQ a~racct
    WHERE rbukrs EQ @iv_bukrs
	  AND rldnr EQ '0L'
	  AND gjahr EQ @iv_gjahr
	  AND rbusa IN @ir_gsber
    INTO TABLE @DATA(lt_acdoca).

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

" ADD WHERE: BETWEEN
WHERE mara~mtart BETWEEN 'Z004' AND 'Z006'

" ADD WHERE: CUSTOM RANGE
WHERE vbfa~vbtyp_v IN ('C','L','K','I','H').

" ADD WHERE: CUSTOM LIKE
WHERE ( matnr LIKE 'J%' OR matnr LIKE 'T%' ).

" ADD WHERE: DYNAMICALLY
TYPES: BEGIN OF lty_select,
          where TYPE c LENGTH 50,
       END OF lty_select.

DATA lt_select TYPE TABLE OF lty_select.

APPEND INITIAL LINE TO lt_select INTO DATA(ls_select).
ls_select-where = 'matnr EQ ls_data-matnr'.

APPEND INITIAL LINE TO lt_select INTO ls_select.
ls_select-where = 'prdha EQ ls_data-prdha'.

SELECT SINGLE *
  INTO ls_001
  FROM zsm_t_001
  WHERE kunnr EQ @lv_kunnr
    AND (lt_select).

" CLIENT
DATA lv_client TYPE sy-mandt.

lv_client = '100'.

SELECT *
  FROM zsm_t_data 
  USING CLIENT @lv_client
  INTO TABLE @DATA(lt_data).

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
