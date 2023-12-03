" Check Data Type
DATA: g_type        TYPE dd01v-datatype,
      g_string(10)  TYPE c VALUE 'Hello'.

CALL FUNCTION 'NUMERIC_CHECK'
  EXPORTING
    string_in = g_string
  IMPORTING
    htype     = g_type.

" Conversion Unit
CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
  EXPORTING
    input                = ls_data-meins
    language             = sy-langu
  IMPORTING
    output               = ls_data-meins.

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

" Convert Material Unit
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