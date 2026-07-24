" Convert Date To String
DATA lv_tarih  TYPE datum.
DATA lv_string TYPE string.

CALL FUNCTION 'CONVERSION_EXIT_PDATE_OUTPUT'
  EXPORTING input  = lv_tarih
  IMPORTING output = lv_string.

" Convert Import Parameters
DATA(gr_sender) = cl_cam_address_bcs=>create_internet_address( CONV #( gv_sender_email ) ).

" Convert Internal Characteristic To Characteristic Name => Atinn -> Atnam
CALL FUNCTION 'CONVERSION_EXIT_ATINN_OUTPUT'
  EXPORTING  input        = <measurement_document>-internal_characteristic
  IMPORTING  output       = <measurement_document>-internal_characteristic_text

  " Convert Material Number
  call FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
  EXPORTING  input        = ls_data-material
  IMPORTING  output       = ls_data-material
  EXCEPTIONS length_error = 1
             OTHERS       = 2.

CALL FUNCTION 'CONVERSION_EXIT_MATN1_OUTPUT'
  EXPORTING  input        = ls_data-material
  IMPORTING  output       = ls_data-material
  EXCEPTIONS length_error = 1
             OTHERS       = 2.

" Convert Material Unit - I
DATA lv_amount       TYPE kwmeng.
DATA lv_gross_weight TYPE brgew_ap.
DATA lv_material     TYPE matnr.
DATA lv_net_weight   TYPE ntgew_ap.
DATA lv_unit_m3      TYPE meins    VALUE 'M3'.
DATA lv_unit_toa     TYPE meins    VALUE 'TOA'.

lv_gross_weight = lv_amount * 1000. " L

CALL FUNCTION 'MATERIAL_UNIT_CONVERSION'
  EXPORTING  input                = lv_gross_weight
             kzmeinh              = abap_true
             matnr                = lv_material
             meinh                = lv_unit_m3
             meins                = 'KG'
  IMPORTING  output               = lv_net_weight
  EXCEPTIONS conversion_not_found = 1
             input_invalid        = 2
             material_not_found   = 3
             meinh_not_found      = 4
             meins_missing        = 5
             no_meinh             = 6
             output_invalid       = 7
             overflow             = 8
             OTHERS               = 9.

lv_net_weight = lv_amount * 1000. " KG

CALL FUNCTION 'MATERIAL_UNIT_CONVERSION'
  EXPORTING  input                = lv_net_weight
             matnr                = lv_material
             meinh                = 'L'
             meins                = lv_unit_toa
  IMPORTING  output               = lv_gross_weight
  EXCEPTIONS conversion_not_found = 1
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
  EXPORTING  i_matnr              = p_matnr
             i_in_me              = p_meins
             i_out_me             = 'PAL'
             i_menge              = p_menge
  IMPORTING  e_menge              = lv_menge
  EXCEPTIONS error_in_application = 1
             error                = 2
             OTHERS               = 3.

" Convert File Extension From Mime Type (application/pdf -> pdf)      
DATA lv_extension TYPE c LENGTH 1.
DATA lv_mime_type TYPE w3conttype.

CALL FUNCTION 'SDOK_FILE_NAME_EXTENSION_GET'
  EXPORTING mimetype  = lv_mime_type
  IMPORTING extension = lv_extension.

" Convert Time
CALL FUNCTION 'CONVERT_TIME_INPUT'
  EXPORTING  input                     = ls_data-value
             plausibility_check        = 'X'
  IMPORTING  output                    = ls_data-value
  EXCEPTIONS plausibility_check_failed = 1
             wrong_format_in_input     = 2
             OTHERS                    = 3.

" Convert Type
CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
  EXPORTING input  = ls_data-data
  IMPORTING output = ls_data-data.

" Convert Unit
CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
  EXPORTING input    = ls_data-meins
            language = sy-langu
  IMPORTING output   = ls_data-meins.

" Convert WBS Element Number
DATA lv_posid LIKE prps-posid.

" P4.24CV.02.001.40.MUH -> 00001223
CALL FUNCTION 'CONVERSION_EXIT_ABPSP_INPUT'
  EXPORTING  input     = lv_posid
  IMPORTING  output    = lv_posid
  EXCEPTIONS not_found = 1
             OTHERS    = 2.

" 00001223 -> P4.24CV.02.001.40.MUH
CALL FUNCTION 'CONVERSION_EXIT_ABPSP_OUTPUT'
  EXPORTING input  = lv_posid
  IMPORTING output = lv_posid.

" Destination
CONSTANTS lc_rfc_name TYPE tfdir-funcname VALUE 'ZSM_F_TEST'.
DATA lv_destination        TYPE rfcdest CALL FUNCTION lc_rfc_name DESTINATION lv_destination EXPORTING iv_uname = lv_uname IMPORTING ev_is_admin = lv_admin.

" Get Last Date of Month
DATA lv_last_date_of_month TYPE sy-datum.                                                                                                                    " DD.MM.YYYY  => 31.03.2024
DATA lv_year_month         TYPE jva_prod_month.                                                                                                              " YYYYMM      => 202403

CALL FUNCTION 'JVA_LAST_DATE_OF_MONTH'
  EXPORTING year_month         = lv_year_month
  IMPORTING last_date_of_month = lv_last_date_of_month.

" Get Personel Number From User ID
DATA lv_personel_no TYPE persno.

CALL FUNCTION 'RP_GET_PERNR_FROM_USERID'
  EXPORTING  begda     = sy-datum
             endda     = sy-datum
             usrid     = sy-uname
             usrty     = '0001'
  IMPORTING  usr_pernr = lv_personel_no
  EXCEPTIONS retcd     = 1
             OTHERS    = 2.

" Get Personel Number From Personel Number
SELECT SINGLE ename FROM pa0001
  INTO data(lv_full_name)
  WHERE pernr  = gs_head-ernam
    AND begda <= sy-datum
    AND endda >= sy-datum.

" Get User Detail
DATA ls_address   TYPE bapiaddr3.
DATA ls_is_locked TYPE bapislockd.
DATA lt_return    TYPE TABLE OF bapiret2.
DATA lv_locked    TYPE xfeld.
DATA lv_username  TYPE bapibname-bapibname.

CALL FUNCTION 'BAPI_USER_GET_DETAIL'
  EXPORTING username = lv_username
  IMPORTING address  = ls_address
            islocked = ls_is_locked
  TABLES    return   = lt_return.

IF NOT line_exists( lt_return[ type = 'E' ] ).
  IF ls_is_locked-glob_lock = 'L' OR ls_is_locked-local_lock = 'L' OR ls_is_locked-no_user_pw = 'L' OR ls_is_locked-wrng_logon = 'L'.
    lv_locked = abap_true.
  ENDIF.
ENDIF.

" Indicator
CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
  EXPORTING percentage = 10
            text       = '1 / 10 Equipment master data is reading.'.

" Maintenance Table
CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
  EXPORTING action    = 'U'
            view_name = 'ZSM_TEST'.

" Next Working Day For a Day
DATA lv_date      LIKE sy-datum.
DATA lv_txnam_sdb LIKE tvko-txnam_sdb.
DATA lv_vbeln     LIKE vbak-vbeln.
DATA lv_vkokl     LIKE tvko-vkokl.
DATA lv_vkorg     LIKE vbak-vkorg.

SELECT SINGLE vkorg FROM vbak
  WHERE vbeln = @lv_vbeln
  INTO @lv_vkorg.

SELECT SINGLE txnam_sdb FROM tvko
  WHERE vkorg = @lv_vkorg
  INTO @lv_txnam_sdb.

lv_vkokl = lv_txnam_sdb.

CALL FUNCTION 'BKK_GET_NEXT_WORKDAY'
  EXPORTING  i_date         = lv_date
             i_calendar1    = lv_vkokl
  IMPORTING  e_workday      = lv_date
  EXCEPTIONS calendar_error = 1
             OTHERS         = 2.
IF sy-subrc <> 0.
ENDIF.

" Smartform
CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
  EXPORTING formname = 'ZSM_SF_001'
  IMPORTING fm_name  = lv_fm_name.

" SNRO
DATA lv_number_range TYPE n LENGTH 10.

CALL FUNCTION 'NUMBER_GET_NEXT'
  EXPORTING nr_range_nr = '1'
            object      = 'ZSM_NR_P25'
  IMPORTING number      = lv_number_range.
