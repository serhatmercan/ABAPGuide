" Definition
EXCEPTION divided_by_zero.

" Usage
RAISE divided_by_zero.

" System Exception - I
TRY.
    zcl_util=>set_media( EXPORTING iv_entity_name = 'Document' ).  
CATCH /iwbep/cx_mgw_med_exception.
ENDTRY.	

" System Exception - II
TRY.
    lv_amount = iv_amount.
    lv_production_amount = ceil( lv_amount ).
  CATCH cx_sy_zerodivide.
ENDTRY.

" System Exception - III
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
