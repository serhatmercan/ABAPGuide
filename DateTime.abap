" Convert String To Date Format
DATA(lv_format_date) = |{ ls_data-ersda+0(4) }{ ls_data-ersda+5(2) }{ ls_data-ersda+8(2) }|.
DATA(lv_format_date) = |{ lv_date+6(2) }.{ lv_date+4(2) }.{ lv_date+0(4) }|.

" Date Definition
DATA: lv_date TYPE d VALUE '20180715',
      lv_date LIKE sy-datum.
 
" Date Declaration
DATA lv_valid TYPE datuv_bi.
WRITE sy-datum TO lv_valid USING EDIT MASK '__.__.____'.

" Date Declaration - II
DATA  lv_date TYPE char10.
WRITE ls_data-date TO lv_date DD/MM/YYYY.

" Time Declaration
DATA(lv_uzeit) = |{ ls_data-value USING EDIT MASK '__:__:__' }|.

" Time Declaration - II
DATA  lv_mask_time TYPE char10.
WRITE ls_data-time USING EDIT MASK '__:__' TO lv_mask_time.

" Time Definition
DATA: lv_time TYPE t VALUE '145330',
      lv_time LIKE sy-uzeit.

" Format
DATA(lv_date_format1) = |{ lv_date DATE = ISO }|.   "YYYY-DD-MM 
DATA(lv_date_format2) = |{ lv_date DATE = User }|.  "MM.DD.YYYY      

" Format: Convert Value To Date
DATA: iv_value TYPE TEXT255,
      rv_date  TYPE DATUM.  

METHOD convert_value_to_date.
    IF iv_value IS INITIAL.
      rv_date = '00000000'.
    ELSEIF iv_value CA '.'.
      CALL FUNCTION 'KCD_EXCEL_DATE_CONVERT'
        EXPORTING
          excel_date = iv_value
        IMPORTING
          sap_date   = rv_date.
    ELSEIF iv_value CA '-'.
      rv_date = iv_value(4) && iv_value+5(2) && iv_value+8(2).
    ELSE.
      rv_date = iv_value.
    ENDIF.
ENDMETHOD.

" Function: Check Time 
DATA: lv_input  TYPE uareg, 
      lv_output TYPE ualend.

CALL FUNCTION 'CONVERT_TIME_INPUT'
  EXPORTING
    input                     = lv_input
  IMPORTING
    output                    = lv_output
  EXCEPTIONS
    plausibility_check_failed = 1
    wrong_format_in_input     = 2
    OTHERS                    = 3.
IF sy-subrc <> 0.
  lv_output = '000000'.
ENDIF.

" Subtract n Years From a Date
DATA lv_date TYPE datum.

CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
  EXPORTING
    date      = sy-datum
    days      = 0
    months    = 0
    signum    = '-'
    years     = 5
  IMPORTING
    calc_date = lv_date.