" BAPI Return Message
DATA(lt_return) = VALUE bapiret2_t( ).

" Boolean
DATA(rv_result) = xsdbool( sy-subrc = 0 ). 
DATA(lv_flag) = VALUE boolean( ).

" Constant
CONSTANTS lc_number LIKE bapi2080_nothdre-notif_no VALUE '%00000000001'.

" Class
DATA(lv_surname) = zsm_cl_test=>get_surname( EXPORTING iv_name = 'SERHAT' 
                                              CHANGING cr_data = 'X' 
                                             IMPORTING et_select_option = DATA(lv_key) ).

" Clear
CLEAR lv_top.

" Definition
DATA lv_character TYPE c LENGTH 120 VALUE 'S'.
DATA lv_decimal   TYPE n LENGTH 10 VALUE 1907.
DATA lv_integer   TYPE i.
DATA lv_integer   TYPE int4 VALUE 1994.
DATA lv_mimetype  TYPE nte_mimetype VALUE 'application/pdf'.
DATA lv_number    TYPE p DECIMALS 2 VALUE '17.75'.
DATA lv_string    TYPE string VALUE 'Serhat Mercan'.

DATA(lt_returns) = VALUE bapiret2_tab( ).
DATA(lt_data)    = VALUE zsm_tt_value( ( ls_data ) ).

" Form & Perform
DATA: lt_header    LIKE TABLE OF bapi_order_header1    WITH HEADER LINE,
      lt_operation LIKE TABLE OF bapi_order_operation1 WITH HEADER LINE,
      lt_component LIKE TABLE OF bapi_order_component  WITH HEADER LINE,
      lv_data      TYPE int4. 

PERFORM get_component TABLES lt_header lt_operation lt_component.
PERFORM use_data USING lv_data. 

FORM get_component TABLES lt_header    STRUCTURE bapi_order_header1
                          lt_operation STRUCTURE bapi_order_operation1
                          lt_component STRUCTURE bapi_order_component.
ENDFORM.

FORM use_data USING pv_data.
ENDFORM.

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

" Include
INCLUDE zsm_test_top.
INCLUDE zsm_test_frm.

START-OF-SELECTION. 

" Optional
DATA(lv_key) = VALUE #( lt_data[ name = 'Key' ]-value OPTIONAL ) .

" Output
WRITE 'Serhat'.
WRITE / 'Serhat'.
WRITE: 'Serhat', 'Mercan'.

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
DATA: ls_vbak TYPE vbak,
      lt_vbak TYPE TABLE OF vbak.

" Xfeld
DATA(lv_error) = VALUE xfeld( ).

" Variable
DATA(lv_user) = 'SMERCAN'.