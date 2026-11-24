INTERFACE zif_zsm_x<run>_so_api PUBLIC.
  TYPES items    TYPE STANDARD TABLE OF bapisditm WITH EMPTY KEY.
  TYPES partners TYPE STANDARD TABLE OF bapiparnr WITH EMPTY KEY.
  TYPES messages TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY.

  "! Creates a sales order in the system and returns the result as the system reports it.
  METHODS create_sales_order
    IMPORTING header         TYPE bapisdhd1
              items          TYPE items
              partners       TYPE partners
    EXPORTING sales_document TYPE bapivbeln-vbeln
              messages       TYPE messages.
ENDINTERFACE.
