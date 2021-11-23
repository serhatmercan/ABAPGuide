" BAPI Return Message
DATA lt_return TYPE bapiret2_t.
DATA lt_return TYPE TABLE OF bapiret2.

" Boolean
DATA(rv_result) = xsdbool( sy-subrc = 0 ). 
DATA(lv_flag) = VALUE boolean( ).

" Constant
CONSTANTS lc_number LIKE bapi2080_nothdre-notif_no VALUE '%00000000001'.

" Clear
CLEAR lv_top.

" Definition
DATA lv_mimetype TYPE nte_mimetype VALUE 'application/pdf'.
DATA lv_value    TYPE c LENGTH 120.
DATA(lt_returns) = VALUE bapiret2_tab( ).

" Function
CALL METHOD cl_cam_address_bcs=>create_internet_addres
  EXPORTING
    i_address_string = CONV #( gv_sender_email )
    i_address_name   = CONV #( gv_sender_name )
   RECEIVING
     result          = DATA(gr_sender).

" Field Symbol
LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
ENDLOOP.

" Optional
DATA(lv_key) = VALUE #( lt_data[ name = 'Key' ]-value OPTIONAL ) .

" Perform
DATA: lt_header    LIKE TABLE OF bapi_order_header1    WITH HEADER LINE,
      lt_operation LIKE TABLE OF bapi_order_operation1 WITH HEADER LINE,
      lt_component LIKE TABLE OF bapi_order_component  WITH HEADER LINE. 

PERFORM get_component TABLES lt_header lt_operation lt_component. 

FORM get_component TABLES lt_header    STRUCTURE bapi_order_header1
                          lt_operation STRUCTURE bapi_order_operation1
                          lt_component STRUCTURE bapi_order_component.

ENDFORM.

" Pointer
DATA(lv_value) = '12345'.
DATA(lr_ref) = REF #( lv_value ) . 

WRITE lr_ref->*. 

" Pointer - Loop
LOOP AT gt_table REFERENCE INTO DATA(lr_table).
ENDLOOP. 

" Standard Table
DATA lt_lines TYPE STANDARD TABLE OF tline.

" Structure
DATA lv_str(30) VALUE 'ZSM_S_STRUCTURE'.

" Tables
TABLES: vbak .

" Xfeld
DATA(lv_error) = VALUE xfeld( ).

" Variable
DATA(lv_user) = 'SMERCAN'.