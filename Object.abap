" Definition
DATA: lo_model		 TYPE REF TO /IWBEP/IF_MGW_ODATA_MODEL
      lo_property    TYPE REF TO /iwbep/if_mgw_odata_property,
      lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.

" Check Object
IF lo_entity_type IS BOUND.
    RETURN.
ENDIF. 

" Get Data      
lo_entity_type = model->get_entity_type( iv_entity_name = 'POMedia' ).

" Set Data
lo_model->get_entity_type( iv_entity_name = 'Key' )->get_property( iv_property_name = 'ABC' )->set_name( 'X' ).