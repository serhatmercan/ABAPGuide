" Definition
EXCEPTION divided_by_zero.

" Usage
RAISE divided_by_zero.

" System Exception
TRY.
  lv_open_specials = lv_open_specials * -1.
  lv_production_amount = ceil( lv_amount ). " cx_sy_zerodivide
  zcl_util=>set_media( EXPORTING iv_entity_name = 'Document' ).  " /iwbep/cx_mgw_med_exception
  CATCH /iwbep/cx_mgw_med_exception. 
  CATCH cx_sy_arithmetic_error INTO DATA(lv_arith_error). 
    MESSAGE 'Arithmetic error occurred while processing' TYPE 'E'.
  CATCH cx_sy_conversion_error INTO DATA(lv_conv_error).
    MESSAGE 'Conversion error occurred while processing' TYPE 'E'.  
  CATCH cx_sy_no_authority INTO DATA(lv_no_auth_error).
    MESSAGE 'No authority error occurred while processing' TYPE 'E'.
  CATCH cx_sy_itab_line_not_found INTO DATA(lv_line_not_found_error).
    MESSAGE 'Internal table line not found error occurred while processing' TYPE 'E'.
  CATCH /iwbep/cx_mgw_med_exception. 
  CATCH cx_root INTO DATA(lv_root_error).
    MESSAGE 'An unexpected error occurred while processing' TYPE 'E'.
ENDTRY.

" System Exception - II
DATA lv_exception_message TYPE /iwbep/mgw_bop_rfc_excep_text.

CALL FUNCTION 'ZSM_F_TEST' 
  EXPORTING
    iv_organization_id    = iv_organization_id
  IMPORTING
    et_person             = et_table[]
  EXCEPTIONS
    system_failure        = 1000 message lv_exception_message
    communication_failure = 1001 message lv_exception_message
    others                = 1002.

" System Exception - III (Function)
CALL FUNCTION 'IM_LINE_ITEM_EXPAND'
  EXPORTING
    i_afabe    = '01'
  TABLES
    t_covp_ext = lt_covp_ext
    t_posbr    = lt_co_objects
  EXCEPTIONS
    OTHERS     = 99.
