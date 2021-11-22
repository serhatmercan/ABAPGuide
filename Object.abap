" Definition
DATA: lo_data        TYPE ole2_object,
      lo_model		 TYPE REF TO /IWBEP/IF_MGW_ODATA_MODEL
      lo_property    TYPE REF TO /iwbep/if_mgw_odata_property,
      lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.

" Check Object
IF lo_entity_type IS BOUND.
    RETURN.
ENDIF. 

" Call Object
CALL METHOD OF lo_data 'Add' = lo_data.
IF sy-subrc <> 0.
    MESSAGE TEXT-001 TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
ENDIF.

" Create Object
CREATE OBJECT lo_data 'EXCEL.APPLICATION'.

" Get Data      
lo_entity_type = model->get_entity_type( iv_entity_name = 'POMedia' ).

" Get Property
GET PROPERTY OF lo_data 'ActiveSheet' = lo_value.

" Set Data
lo_model->get_entity_type( iv_entity_name = 'Key' )->get_property( iv_property_name = 'ABC' )->set_name( 'X' ).

" Set Property
SET PROPERTY OF lo_data 'Visible' = 0.

