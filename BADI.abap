METHOD if_ex_me_process_po_cust~process_item.
 
    DATA: lo_header   TYPE REF TO if_purchase_order_mm,
          ls_header   TYPE mepoheader,
          ls_item     TYPE mepoitem,
          lt_item     TYPE purchase_order_items,
          ls_previous TYPE mepoitem.
 
    lo_header = im_item->get_header( ).
    ls_header = lo_header->get_data( ).
    ls_item   = im_item->get_data( ).
 
    im_item->get_previous_data( IMPORTING  ex_data = ls_previous
                                EXCEPTIONS no_data = 1 OTHERS = 2 ).
     
    IF ls_header-bsart EQ 'NB'.
      IF ls_previous IS INITIAL.
        ls_item-uebto = 8.
        ls_item-webre = 'X'.
        im_item->set_data( EXPORTING im_data = ls_item ).
      ENDIF.
    ENDIF.
    
ENDMETHOD.