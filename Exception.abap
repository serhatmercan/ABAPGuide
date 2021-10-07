TRY.
    zcl_util=>set_media( EXPORTING iv_entity_name = 'Document' ).  
CATCH /iwbep/cx_mgw_med_exception.
ENDTRY.	