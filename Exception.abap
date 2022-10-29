" Definition
EXCEPTION divided_by_zero.

" Usage
RAISE divided_by_zero.

" System Excepiton - I
TRY.
    zcl_util=>set_media( EXPORTING iv_entity_name = 'Document' ).  
CATCH /iwbep/cx_mgw_med_exception.
ENDTRY.	

" System Excepiton - II
TRY.
    lv_amount = iv_amount.
    lv_production_amount = ceil( lv_amount ).
  CATCH cx_sy_zerodivide.
ENDTRY.

