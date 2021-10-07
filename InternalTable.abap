" Definition: Types & Table Type & Internal Table
TYPES: BEGIN OF ty_auart,
         vbeln TYPE vbak-vbeln,
         posnr TYPE vbrp-posnr,
         auart TYPE vbak-auart,
       END OF ty_auart,

tt_auart TYPE TABLE OF ty_auart WITH KEY vbeln.

DATA gt_auart TYPE tt_auart.

" Append
APPEND INITIAL LINE TO lt_sales_items.
lt_sales_items[ sy-tabix ]-itm_number = lv_posnr + 10.
lt_sales_items[ sy-tabix ]-material   = zsd_iade_giris-matnr.

" Append Structure To Table
APPEND ls_data TO lt_data.

" Append Value
APPEND VALUE #( material = '123' ) TO lt_sales_items.

" Append Value & Default Parameters
lt_data = VALUE #(  refnumber = '1'
                    objectkey = 'X'
                    ( objecttype  = 'HEADER'
                      method      = 'CREATE' )
                    ( objecttype  = 'OPERATION'
                      method      = 'CREATE' ) ).

" Append w/ Return Message
DATA et_return TYPE bapiret2_tab. 
et_return = VALUE #( ( type = 'E' id = 'ZPP_000_MC' number = 001 ) ). 

" Assign w/ Index
ASSIGN lt_itab[ 3 ] TO FIELD-SYMBOL(<fs_itab>). 

" Assign w/ Key
ASSIGN lt_itab[ ernam = 'SERHAT'
                ersda = '20801212' ] TO FIELD-SYMBOL(<fs_itab>). 

" Corresponding w/ Mapping
lt_data = CORRESPONDING #( lo_data-values MAPPING matnr = material_no ).

" Delete w/ Condition
DELETE it_itab WHERE id EQ 'X' AND attribute EQ 'ABC'.

" Delete w/ Range Condition
DELETE it_itab WHERE id NOT IN ir_data.

" For
DATA(lt_mara) = VALUE tt_mara( FOR ls_itab IN it_itab WHERE ( ernam EQ 'SERHAT' ) ( matnr = ls_itab-matnr
                                                                                    ernam = ls_itab-ernam ) ). 

" For w/ Groups                                                                                     
DATA(lt_mara) = VALUE tt_mara( FOR GROUPS grp OF ls_itab IN it_itab WHERE ( ernam EQ 'SERHAT' ) 
                                                                    GROUP BY ls_itab-ersda
                                                                    ( ersda = grp ) ) .

" Insert
INSERT VALUE #( id = '1' value= 'X' ) INTO TABLE lt_data.

" Loop w/ Reference
LOOP AT lt_order REFERENCE INTO DATA(lr_order).
  CASE lr_order->property.
    WHEN 'OrderNo'.
      lr_order->property = 'ORDER_NO'.
  ENDCASE.
ENDLOOP.

" Modify
MODIFY lt_data
  FROM VALUE #( notification_type = 'X' catalog_type = 'ABC' )
  TRANSPORTING notification_type catalog_type
  WHERE material_no IS INITIAL. 

" Update
UPDATE ls_data FROM lt_data.

" Reference 
DATA(lr_ref) = REF #( lt_itab[ ernam = 'SERHAT'
                               ersda = '20801212' ] ). 
WRITE lr_ref->matnr. 

" Read Table
READ TABLE it_key INTO ls_key WITH KEY name = 'X' INDEX 1 TRANSPORTING name.
IF sy-subrc EQ 0.
  DATA(lv_value) = ls_key-value.
ENDIF.

IF line_exists( gt_auart[ vbeln = itab-vbeln ] ).
  DATA(lv_auart)= gt_auart[ vbeln = itab-vbeln ]-auart.
ENDIF.

" SORT & DELETE DUPLICATE DATA
SORT lt_data BY name.
DELETE ADJACENT DUPLICATES FROM lt_data COMPARING name.

" Table Records Count
DATA(lv_records_count) = lines( gt_table ). 