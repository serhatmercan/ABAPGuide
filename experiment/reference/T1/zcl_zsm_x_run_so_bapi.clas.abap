"! Creates sales orders with BAPI_SALESORDER_CREATEFROMDAT2. Does not commit:
"! the caller owns the SAP LUW and calls BAPI_TRANSACTION_COMMIT or _ROLLBACK.
CLASS zcl_zsm_x<run>_so_bapi DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_zsm_x<run>_so_api.
ENDCLASS.


CLASS zcl_zsm_x<run>_so_bapi IMPLEMENTATION.
  METHOD zif_zsm_x<run>_so_api~create_sales_order.
    DATA item_table TYPE STANDARD TABLE OF bapisditm.
    DATA partner_table TYPE STANDARD TABLE OF bapiparnr.
    DATA return_table TYPE STANDARD TABLE OF bapiret2.

    CLEAR: sales_document, messages.
    item_table = items.
    partner_table = partners.

    CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
      EXPORTING order_header_in = header
      IMPORTING salesdocument   = sales_document
      TABLES    return          = return_table
                order_items_in  = item_table
                order_partners  = partner_table.

    messages = return_table.
  ENDMETHOD.
ENDCLASS.
