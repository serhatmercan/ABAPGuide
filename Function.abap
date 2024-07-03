" Check Data Type
DATA: g_type        TYPE dd01v-datatype,
      g_string(10)  TYPE c VALUE 'Hello'.

CALL FUNCTION 'NUMERIC_CHECK'
  EXPORTING
    string_in = g_string
  IMPORTING
    htype     = g_type.

" Convert Batch Input Message To Bapiret Message
CALL FUNCTION 'CONVERT_BDCMSGCOLL_TO_BAPIRET2'
   TABLES
     imt_bdcmsgcoll = gt_messtab
     ext_return     = pt_return.

" Convert Currency Unit
DATA ls_exch_rate TYPE bapi1093_0.

CALL FUNCTION 'BAPI_EXCHANGERATE_GETDETAIL'
  EXPORTING
    rate_type  = 'M'
    from_curr  = ls_data-value
    to_currncy = 'TRY'
    date       = sy-datum 
  IMPORTING
    return     = ls_exch_rate.

" Convert Date
CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
  EXPORTING
    date_external = ls_data-value
  IMPORTING
    date_internal = ls_data-value.

" Convert Date To String
DATA: lv_tarih  TYPE datum, 
      lv_string TYPE string. 

CALL FUNCTION 'CONVERSION_EXIT_PDATE_OUTPUT'
   EXPORTING
      input  = lv_tarih
   IMPORTING
      output = lv_string. 

" Convert Import Parameters
CALL METHOD cl_cam_address_bcs=>create_internet_addres
  EXPORTING
    i_address_string = CONV #( gv_sender_email )
   RECEIVING
     result          = DATA(gr_sender).

" Convert Internal Characteristic To Characteristic Name => Atinn -> Atnam
CALL FUNCTION 'CONVERSION_EXIT_ATINN_OUTPUT'
  EXPORTING
    input  = <measurement_document>-internal_characteristic
  IMPORTING
    output = <measurement_document>-internal_characteristic_text

" Convert Material Number
CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
  EXPORTING
    input        = ls_data-material
  IMPORTING
    output       = ls_data-material
  EXCEPTIONS
    length_error = 1
    OTHERS       = 2. 

CALL FUNCTION 'CONVERSION_EXIT_MATN1_OUTPUT'
  EXPORTING
    input        = ls_data-material
  IMPORTING
    output       = ls_data-material
  EXCEPTIONS
    length_error = 1
    OTHERS       = 2. 

" Convert Material Unit - I
DATA: lv_amount       TYPE kwmeng,
      lv_gross_weight TYPE brgew_ap,
      lv_material     TYPE matnr,   
      lv_net_weight   TYPE ntgew_ap,   
      lv_unit_m3      TYPE meins,
      lv_unit_toa     TYPE meins.

lv_unit_m3 = 'M3'.
lv_unit_toa = 'TOA'.

lv_gross_weight = lv_amount * 1000. "L

CALL FUNCTION 'MATERIAL_UNIT_CONVERSION'
  EXPORTING
    input                = lv_gross_weight
    kzmeinh              = abap_true
    matnr                = lv_material
    meinh                = lv_unit_m3
    meins                = 'KG'
  IMPORTING
    output               = lv_net_weight
  EXCEPTIONS
    conversion_not_found = 1
    input_invalid        = 2
    material_not_found   = 3
    meinh_not_found      = 4
    meins_missing        = 5
    no_meinh             = 6
    output_invalid       = 7
    overflow             = 8
    OTHERS               = 9.

lv_net_weight = lv_amount * 1000. "KG

CALL FUNCTION 'MATERIAL_UNIT_CONVERSION'
  EXPORTING
    input                = lv_net_weight
    matnr                = lv_material
    meinh                = 'L'
    meins                = lv_unit_toa
  IMPORTING
    output               = lv_gross_weight
  EXCEPTIONS
    conversion_not_found = 1
    input_invalid        = 2
    material_not_found   = 3
    meinh_not_found      = 4
    meins_missing        = 5
    no_meinh             = 6
    output_invalid       = 7
    overflow             = 8
    OTHERS               = 9.

CHECK sy-subrc <> 0.

MESSAGE ID sy-msgid
        TYPE sy-msgty
        NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

" Convert Material Unit - II
CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
    EXPORTING
      i_matnr              = p_matnr
      i_in_me              = p_meins
      i_out_me             = 'PAL'
      i_menge              = p_menge
    IMPORTING
      e_menge              = lv_menge
    EXCEPTIONS
      error_in_application = 1
      error                = 2
      OTHERS               = 3.

" Convert Time
CALL FUNCTION 'CONVERT_TIME_INPUT'
  EXPORTING
    input                     = ls_data-value
    plausibility_check        = 'X'
  IMPORTING
    output                    = ls_data-value
  EXCEPTIONS
    plausibility_check_failed = 1
    wrong_format_in_input     = 2
    OTHERS                    = 3.

" Convert Type
CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
  EXPORTING
    input  = ls_data-data
  IMPORTING
    output = ls_data-data.

" Convert Unit
CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
  EXPORTING
    input    = ls_data-meins
    language = sy-langu
  IMPORTING
    output   = ls_data-meins.

" Convert WBS Element Number
DATA lv_posid LIKE prps-posid.

" P4.24CV.02.001.40.MUH -> 00001223
CALL FUNCTION 'CONVERSION_EXIT_ABPSP_INPUT'
  EXPORTING
    input     = lv_posid
  IMPORTING
    output    = lv_posid
  EXCEPTIONS
    not_found = 1
    OTHERS    = 2.

" 00001223 -> P4.24CV.02.001.40.MUH
CALL FUNCTION 'CONVERSION_EXIT_ABPSP_OUTPUT'
  EXPORTING
    input     = lv_posid
  IMPORTING
    output    = lv_posid.

" Destination
CONSTANTS lc_rfc_name TYPE tfdir-funcname VALUE 'ZSM_F_TEST'.
DATA lv_destination TYPE rfcdest

CALL FUNCTION lc_rfc_name
  DESTINATION
    lv_destination
  EXPORTING
    iv_uname    = lv_uname
  IMPORTING
    ev_is_admin = lv_admin.

" Get Last Date of Month
DATA: lv_last_date_of_month TYPE sy-datum,        " DD.MM.YYYY  => 31.03.2024
      lv_year_month         TYPE jva_prod_month.  " YYYYMM      => 202403

CALL FUNCTION 'JVA_LAST_DATE_OF_MONTH'
  EXPORTING
    year_month       = lv_year_month
  IMPORTING
  last_date_of_month = lv_last.

" Get Personel Number From User ID
DATA lv_personel_no TYPE persno.

CALL FUNCTION 'RP_GET_PERNR_FROM_USERID'
  EXPORTING
    begda = sy-datum
    endda = sy-datum
    usrid = sy-uname
    usrty = '0001'
  IMPORTING
    usr_pernr = lv_personel_no
  EXCEPTIONS
    retcd  = 1
    OTHERS = 2.

" Get Personel Number From Personel Number
SELECT SINGLE ename
  FROM pa0001
  INTO DATA(lv_full_name)
  WHERE pernr EQ gs_head-ernam
    AND begda LE sy-datum
    AND endda GE sy-datum.

" Get User Detail
DATA: ls_address    TYPE bapiaddr3,
      ls_is_locked  TYPE bapislockd,
      lt_return     TYPE TABLE OF bapiret2,
      lv_locked     TYPE xfeld, 
      lv_username   TYPE bapibname-bapibname.

CALL FUNCTION 'BAPI_USER_GET_DETAIL'
  EXPORTING
    username = lv_username
  IMPORTING
    address  = ls_address
    islocked = ls_is_locked
  TABLES
    return   = lt_return.

IF NOT line_exists( lt_return[ type = 'E' ] ).    
  IF ls_is_locked-glob_lock EQ 'L' OR ls_is_locked-local_lock EQ 'L' OR ls_is_locked-no_user_pw EQ 'L' OR ls_is_locked-wrng_logon EQ 'L'.
    lv_locked = abap_true.
  ENDIF.
ENDIF.

" Indicator
CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
  EXPORTING
    percentage = 10
    text       = '1 / 10 Ekipman ana verileri alınıyor.'. 

" Maintenance Table
CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
  EXPORTING
    action     = 'U'
    view_name  = 'ZSM_TEST'. 

" Next Working Day For a Day
DATA: lv_date      LIKE sy-datum,
      lv_txnam_sdb LIKE tvko-txnam_sdb,
      lv_vbeln     LIKE vbak-vbeln,
      lv_vkokl     LIKE tvko-vkokl,
      lv_vkorg     LIKE vbak-vkorg.

SELECT SINGLE vkorg   
  FROM vbak
  WHERE vbeln EQ @lv_vbeln
  INTO @lv_vkorg.

SELECT SINGLE txnam_sdb 
  FROM tvko
  WHERE vkorg EQ @lv_vkorg
  INTO @lv_txnam_sdb.

MOVE lv_txnam_sdb TO lv_vkokl.

CALL FUNCTION 'BKK_GET_NEXT_WORKDAY'
  EXPORTING
    i_date         = lv_date
    i_calendar1    = lv_vkokl
  IMPORTING
    e_workday      = lv_date
  EXCEPTIONS
    calendar_error = 1
    OTHERS         = 2.
IF sy-subrc <> 0.
ENDIF.

" Smartform
CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'

" SNRO
DATA lv_number_range(10) TYPE n.

CALL FUNCTION 'NUMBER_GET_NEXT'
  EXPORTING
   nr_range_nr = '1'
   object      = 'ZSM_NR_P25'
 IMPORTING
   number      = lv_number_range. 