" SELECT SINGLE
SELECT SINGLE *
  FROM mara
  INTO @DATA(ls_data)

" SELECT SINGLE TO DATA
SELECT SINGLE canpos~modul, canpos~modul_txt
  FROM zhr_t_canpos AS canpos
  INTO (@DATA(lv_modul), @DATA(lv_modul_txt)) .

" SELECT ALL   
SELECT * 
  FROM vbrk 
  INTO TABLE @DATA(lt_data).

" SELECT MAX
SELECT MAX(posnr) 
  FROM lips 
  INTO @DATA(lv_posnr) 
  WHERE vbeln EQ @p_vbeln.

" SELECT LEFT OUTER JOIN
SELECT SINGLE mara~matnr, makt~maktx 
  FROM mara 
  LEFT JOIN makt 
    ON makt~matnr EQ mara~matnr 
  WHERE mara~matnr EQ @iv_matnr
  INTO @DATA(ls_material).

" SELECT SINGLE MAX | AS | GROUP BY
SELECT SINGLE MAX(a~vbeln) AS vbeln, a~posnr 
  FROM vbap AS a 
  INNER JOIN vbak AS b ON a~vbeln EQ b~vbeln 
  WHERE a~abgru = space AND b~auart EQ 'ZKLF' 
  GROUP BY a~posnr
  INTO (@DATA(lv_vbeln), @DATA(lv_posnr)) .

" SELECT ALL FIELDS
SELECT mara~*, marc~prctr 
  FROM marc 
  INNER JOIN mara ON mara~matnr EQ marc~matnr 
  WHERE marc~is_default EQ @abap_true
  INTO TABLE @DATA(lt_data).

" SELECT CASE
SELECT CASE WHEN strkorr NE @space THEN strkorr
            ELSE 'A'
       END AS request_no
  FROM e070
  INTO TABLE @DATA(lt_requests).

" SELECT CALCULATION
SELECT brgew, ntgew, gewei, ABS( brgew - ntgew ) AS diff
  FROM mara
  INTO TABLE @DATA(lt_mara).

" SELECT COUNT
SELECT COUNT(*) 
  FROM t001w 
  WHERE werks EQ @lv_werks
  INTO @DATA(lv_count).
IF lv_count EQ 0.
ENDIF.

" SELECT COUNT w/ GROUP BY
TYPES: BEGIN OF lty_order_appointment,
          begin_time    TYPE ztprsd0036-begin_time,
          finisih_time  TYPE ztprsd0036-finisih_time,
          order_count   TYPE i,
        END OF lty_order_appointment.
DATA lt_order_appointments TYPE STANDARD TABLE OF lty_order_appointment WITH EMPTY KEY.

SELECT t1~begin_time,
       t1~finisih_time,
       COUNT( DISTINCT t1~order ) AS order_count
  FROM ztprsd0036 AS t1
  INNER JOIN vbak AS t2
    ON t2~vbeln EQ t1~order
   AND t2~kunnr EQ @iv_customer
  WHERE t1~date EQ @lv_date
    AND t1~xkapali EQ @abap_false
  GROUP BY t1~begin_time, t1~finisih_time
  INTO TABLE @lt_order_appointments.

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

" SELECT w/ DYNAMICALLY
DATA: lv_condition   TYPE string,
      lv_fieldname   TYPE fieldname,        
      lv_table       TYPE tabname,
      lv_field_range TYPE RANGE OF char30.

lv_condition = |{ lv_fieldname } IN @<ls_dyn_prm>-field_range |.

SELECT DISTINCT (lv_fieldname)
  FROM (lv_table)
  WHERE (lv_condition)
  INTO TABLE @lt_dynamic_table.

  " SELECT w/ PARAMETER
SELECT SINGLE v1~qmnum,
              @iv_task_no AS task_no,
              v1~ernam
  FROM qmel AS v1
  WHERE v1~qmnum EQ @iv_qmnum
  INTO @DATA(ls_qmel).

" SELECT EXIST
SELECT COUNT( * ) 
  FROM zsm_t_data 
  WHERE werks EQ @iv_werks 
    AND EXISTS ( SELECT * 
                  FROM mara 
                  WHERE matnr EQ @iv_matnr 
                    AND mtart EQ zsm_t_data~mtart )
  INTO @DATA(lv_exist_count).

" SELECT NOT EXISTS
SELECT DISTINCT vk~vbeln, vk~kunnr, oigd~drname
  FROM vbak AS vk
  INNER JOIN vbap AS vp
    ON vp~vbeln EQ vk~vbeln 
  LEFT OUTER JOIN oigd
    ON oigd~zdtckno EQ vk~zz1_drivertcno_sdh
  WHERE vk~vbeln IN @lr_vbeln
    AND vp~matnr IN @lr_matnr
    AND NOT EXISTS ( SELECT mandt
                      FROM zsd_t_007
                      WHERE vkorg EQ @lv_vkorg
                        AND kunnr EQ vk~kunnr )
    AND NOT EXISTS ( SELECT mandt
                      FROM lips
                      WHERE vgbel EQ vk~vbeln )
  INTO TABLE @DATA(lt_data).

" SELECT RIGHT
SELECT DISTINCT parent_key , right( dlv~base_btd_id, 10 ) AS vbeln, right( dlv~base_btditem_id, 6 ) AS posnr
  FROM @lt_dlv_ref as dlv
  INTO TABLE @gt_data.

" SELECT UNION ALL
SELECT name1
  FROM kna1
  WHERE loevm EQ @abap_false
UNION ALL
SELECT name1
  FROM lfa1
  WHERE loevm EQ @abap_false
INTO TABLE @DATA(lt_names). 

" SELECT UNION DISTINCT
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
  ORDER BY mch1~vfdat, mch1~charg
  INTO TABLE @DATA(lt_data).

" SELECT SUM & GROUP & ORDER II
SELECT  a~partner,
	      a~credit_sgmnt,
	      a~credit_limit,
	      SUM( CASE WHEN a~credit_sgmnt EQ @lc_credit_segment_domestic THEN b~amount ELSE 0 END ) AS sum_domestic_amount,
	      SUM( CASE WHEN a~credit_sgmnt EQ @lc_credit_segment_overseas THEN b~amount ELSE 0 END ) AS sum_overseas_amount,
	      b~currency
  FROM ukmbp_cms_sgm AS a
  LEFT OUTER JOIN ukm_item AS b
    ON b~partner EQ a~partner
   AND b~credit_sgmnt EQ a~credit_sgmnt
  WHERE a~partner IN @lr_customers
    AND a~credit_sgmnt IN (@lc_credit_segment_domestic, @lc_credit_segment_overseas)
  GROUP BY a~partner, a~credit_sgmnt, a~credit_limit, b~currency
	ORDER BY a~partner, a~credit_sgmnt
  INTO TABLE @DATA(lt_credit).

" SELECT SUM w/ Internal Table
SELECT t1~file_no,
       SUM( t1~fkimg ) AS total_fkimg
  FROM @lt_invoice_sum AS t1
  GROUP BY t1~file_no
  INTO TABLE @DATA(lt_invoice_sum_amount).

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
  FROM vbrk
  INNER JOIN vbrp ON vbrp~vbeln EQ vbrk~vbeln
  INNER JOIN mara ON mara~matnr EQ vbrp~matnr
  WHERE vbrk~mandt EQ @sy-mandt  
    AND vbrk~vbeln IN @ir_vbeln
  INTO TABLE @DATA(itab).

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
  DATA(lt_itabx) = lt_itab. " lt_itab[]

  SORT lt_itabx BY vbeln posnr.
  DELETE ADJACENT DUPLICATES FROM lt_itabx COMPARING vbeln posnr.
  DELETE lt_itabx WHERE posnr IS INITIAL.

  IF lt_itabx[] IS NOT INITIAL.
    SELECT vbfa~vbeln,
           vbfa~posnn,
           vbak~auart
      FROM vbfa
      FOR ALL ENTRIES IN @lt_itabx
      WHERE vbfa~vbeln EQ @lt_itabx-vbeln 
        AND vbfa~posnn EQ @lt_itabx-posnr
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_vbfa).
  ENDIF.
ENDIF.

" INTO RANGE TABLE 
DATA lt_werks_range TYPE RANGE OF werks_d.

SELECT 'I'  AS sign,
       'EQ' AS option,
        t001w~werks AS low
  FROM t001w
  INTO CORRESPONDING FIELDS OF TABLE @lt_werks_range.

" INTO RANGE TABLE II
DATA lr_tags TYPE RANGE OF zsm_e_tag.

SELECT FROM @ls_input-tag_names AS t1
  FIELDS 'I' AS sign, 'EQ' AS option, t1~name AS low
  INTO CORRESPONDING FIELDS OF TABLE @lr_tags.  

SELECT FROM zsm_ct_tag
  FIELDS tag_name, 'Units' AS property_name, unit AS property_value
  WHERE werks    EQ @ls_input-plant
    AND tag_name IN @lr_tags
  INTO CORRESPONDING FIELDS OF TABLE @ls_proxy_response-get_tag_info_response-properties.

" ADD WHERE: BETWEEN
WHERE mara~mtart BETWEEN 'Z004' AND 'Z006'

" ADD WHERE: CUSTOM RANGE
WHERE vbfa~vbtyp_v IN ('C','L','K','I','H').

" ADD WHERE: CUSTOM LIKE
WHERE ( matnr LIKE 'J%' OR matnr LIKE 'T%' ).

" ADD WHERE: DATE
WHERE begda LE @sy-datum
  AND endda GE @sy-datum

" ADD WHERE: DATE & TIME
WHERE ( begin_date GT @sy-datum OR ( begin_date EQ @sy-datum AND begin_time GE @sy-uzeit ) )

" ADD WHERE: DYNAMICALLY - I
TYPES: BEGIN OF lty_select,
          where TYPE c LENGTH 50,
       END OF lty_select.

DATA lt_select TYPE TABLE OF lty_select.

APPEND VALUE #( where = 'matnr = ls_data-matnr' ) TO lt_select.
APPEND VALUE #( where = 'prdha = ls_data-prdha' ) TO lt_select.
APPEND VALUE #( where = 'AND prmt = ''INTERNAL''' ) TO lt_select.

" ADD WHERE: DYNAMICALLY - II
IF lv_end_date IS INITIAL.
  APPEND VALUE #( where = '@lv_begin_date BETWEEN t1~begin_date' ) TO lt_select.
  APPEND VALUE #( where = 'AND t1~end_date' ) TO lt_select.
ELSE.
  APPEND VALUE #( where = 't1~begin_date GE @lv_begin_date' ) TO lt_select.
  APPEND VALUE #( where = 'AND t1~end_date LE @lv_end_date' ) TO lt_select.
ENDIF.

SELECT SINGLE *
  INTO ls_001
  FROM zsm_t_001
  WHERE kunnr EQ @lv_kunnr
    AND (lt_select).

" ADD WHERE: UPPER
WHERE upper( matnr ) IN @lr_materials.

" ADD WHERE: OR
WHERE ( t1~vehicle IN @lr_vehicle OR t2~veh_text IN @lr_vehicle_text )

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
  WHERE matnr EQ @lv_matnr
    AND werks EQ '1000'
    AND ( ( clabs GT 0 ) OR ( cinsm GT 0 ) OR ( cspem GT 0 ) )
  INTO CORRESPONDING FIELDS OF TABLE @lt_lgort.

SELECT lgort 
  FROM mspr
  WHERE matnr EQ @lv_matnr
    AND werks EQ '1000'
    AND ( ( prlab GT 0 ) OR ( prins GT 0 ) OR ( prspe GT 0 ) )
  APPENDING CORRESPONDING FIELDS OF TABLE lt_lgort.
