" BAPI Return Message
DATA lt_return TYPE bapiret2_t.
DATA lt_return TYPE TABLE OF bapiret2.

" Boolean
DATA(rv_result) = xsdbool( sy-subrc = 0 ). 

" Constant
CONSTANTS lc_number LIKE bapi2080_nothdre-notif_no VALUE '%00000000001'.

" Clear
CLEAR lv_top.

" Definition
DATA: lv_mimetype TYPE nte_mimetype VALUE 'application/pdf'.

" Field Symbol
LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
ENDLOOP.

" Optional
DATA(lv_key) = VALUE #( lt_data[ name = 'Key' ]-value OPTIONAL ) .

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