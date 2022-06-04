" Definition-1: Types & Table Type & Internal Table
TYPES: BEGIN OF ty_auart,
         vbeln TYPE vbak-vbeln,
         posnr TYPE vbrp-posnr,
         auart TYPE vbak-auart,
       END OF ty_auart,

tt_auart TYPE TABLE OF ty_auart WITH KEY vbeln.

DATA: gs_auart TYPE ty_auart,
      gt_auart TYPE tt_auart.

" Definition-2: Types & Internal Table
TYPES: BEGIN OF ty_mdps.
          INCLUDE TYPE mdps.
          TYPES: check TYPE xfeld,
        END OF ty_mdps.
 
DATA: lt_mdps TYPE TABLE OF ty_mdps,
      ls_mdps TYPE ty_mdps.

" Definition-3: Types & Internal Table
DATA: BEGIN OF ty_data OCCURS 0.
        INCLUDE TYPE zqmui_s_insplot.
        DATA: objnr TYPE qals-objnr,
      END OF ty_data.
 
DATA lt_data TYPE TABLE OF ty_data.

" Definition-3: Types & Internal Table w/ Performance
TYPES: BEGIN OF ty_charg,
         matnr LIKE marc-matnr,
         lgort TYPE mseg-lgort,
         charg TYPE mspr-charg,
         pspnr TYPE mspr-pspnr,
         post1 TYPE prps-post1,
       END OF ty_charg.

TYPES: tt_charg TYPE STANDARD TABLE OF ty_charg
                WITH KEY matnr lgort
                WITH NON-UNIQUE SORTED KEY matnr_lgort COMPONENTS matnr lgort.

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

" Append Value & Default Parameters w/ Table Type
DATA(lt_data) = VALUE tt_auart(  ( vbeln  = '1' posnr = '10' auart = 'X' )
                                 ( vbeln  = '2' posnr = '20' auart = 'Y' ) ).                        

" Append w/ Return Message
DATA et_return TYPE bapiret2_tab. 
et_return = VALUE #( ( type = 'E' id = 'ZPP_000_MC' number = 001 ) ). 

" Assign w/ Index
ASSIGN lt_itab[ 3 ] TO FIELD-SYMBOL(<fs_itab>). 

" Assign w/ Key
ASSIGN lt_itab[ ernam = 'SERHAT'
                ersda = '20801212' ] TO FIELD-SYMBOL(<fs_itab>).
                
" Calculation
DATA(lv_amount) = REDUCE i( INIT i TYPE labst FOR ls_mard IN lt_mard WHERE ( labst NE '' ) NEXT i = i + ls_mard-labst ).
DATA(lv_total) = REDUCE bstmg( INIT total TYPE bstmg
                               FOR ls_data IN lt_data
			                         WHERE ( mtart EQ 'A' AND werks EQ 'X' )
                               NEXT total = total + ls_data-total ).

" Corresponding w/ Mapping
lt_data = CORRESPONDING #( lo_data-values MAPPING matnr = material_no ).

" Delete w/ Condition
DELETE it_itab WHERE id EQ 'X' AND attribute EQ 'ABC'.

" Delete w/ Range Condition
DELETE it_itab WHERE id NOT IN ir_data.

" Filter
DATA(lt_filter_data) = FILTER #( it_itab IN tt_itab
                                         WHERE ernam EQ 'X' ).

" For
DATA(lt_mara) = VALUE tt_mara( FOR ls_itab IN it_itab WHERE ( ernam EQ 'SERHAT' ) ( matnr = ls_itab-matnr
                                                                                    ernam = ls_itab-ernam ) ). 

" For w/ Corresponding
DATA(lt_data) = VALUE #( FOR row IN lt_products ( matnr = row-matnr ) ).

" For w/ Groups                                                                                     
DATA(lt_mara) = VALUE tt_mara( FOR GROUPS grp OF ls_itab IN it_itab WHERE ( ernam EQ 'SERHAT' ) 
                                                                    GROUP BY ls_itab-ersda
                                                                    ( ersda = grp ) ) .

" Insert
INSERT VALUE #( id = '1' value= 'X' ) INTO TABLE lt_data.

" Line Index
DATA(lv_index) = line_index( gt_table[ vbeln = '0060000001'] ).

" Loop w/ Reference
LOOP AT lt_order REFERENCE INTO DATA(lr_order).
  CASE lr_order->property.
    WHEN 'OrderNo'.
      lr_order->property = 'ORDER_NO'.
  ENDCASE.
ENDLOOP.

" Loop w/ Group
LOOP AT lt_data INTO DATA(ls_data)
       GROUP BY  ( order_no   = ls_data-order_no
                   order_type = ls_data-order_type
                   size  = GROUP SIZE
                   index = GROUP INDEX )
        ASCENDING
        REFERENCE INTO DATA(ls_group).
ENDLOOP.

LOOP AT GROUP ls_group INTO DATA(ls_group_data).
ENDLOOP.

" Modify
MODIFY lt_data
  FROM VALUE #( notification_type = 'X' catalog_type = 'ABC' )
  TRANSPORTING notification_type catalog_type
  WHERE material_no IS INITIAL. 

" Update
UPDATE ls_data FROM lt_data.

" Reduce: Find Count To Duplicate Data
DATA(lv_lines) = REDUCE i( INIT x = 0 FOR wa_deger IN tt_deger
                           WHERE ( deger EQ 'R' ) NEXT x = x + 1 ).

" Reference 
DATA(lr_ref) = REF #( lt_itab[ ernam = 'SERHAT'
                               ersda = '20801212' ] ). 
WRITE lr_ref->matnr. 

" Read Table - I
READ TABLE it_key INTO ls_key WITH KEY name = 'X' INDEX 1 TRANSPORTING name.
IF sy-subrc EQ 0.
  DATA(lv_value) = ls_key-value.
ENDIF.

" Read Table - II
READ TABLE it_key ASSIGNING FIELD-SYMBOL(<fs_key>) WITH KEY name = 'X' INDEX 1 TRANSPORTING name.
IF sy-subrc EQ 0.
  <fs_key>-value = abap_true.
ENDIF.

" " Read Table - III
IF line_exists( gt_auart[ vbeln = itab-vbeln ] ).
  DATA(lv_auart)= gt_auart[ vbeln = itab-vbeln ]-auart.
ENDIF.

" Read Table - IV
ls_data = CORRESPONDING #( lt_data[ name = 'X' ] ).

" SORT & DELETE DUPLICATE DATA
SORT lt_data BY name.
DELETE ADJACENT DUPLICATES FROM lt_data COMPARING name.

" Table Records Count
DATA(lv_records_count) = lines( gt_table ).