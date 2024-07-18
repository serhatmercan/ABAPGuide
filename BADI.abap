METHOD if_ex_me_process_po_cust~process_item.

  DATA: lo_header   TYPE REF TO if_purchase_order_mm,
        ls_header   TYPE mepoheader,
        ls_item     TYPE mepoitem,
        ls_previous TYPE mepoitem.

  lo_header = im_item->get_header( ).
  ls_header = lo_header->get_data( ).
  ls_item = im_item->get_data( ).

  TRY.
      im_item->get_previous_data( IMPORTING ex_data = ls_previous ).
    CATCH cx_sy_itab_line_not_found.
      CLEAR ls_previous.
  ENDTRY.

  IF ls_header-bsart = 'NB' AND ls_previous IS INITIAL.
    ls_item-uebto = 8.
    ls_item-webre = 'X'.
    im_item->set_data( EXPORTING im_data = ls_item ).
  ENDIF.
  
ENDMETHOD.