"! Creates one standard sales order for one customer and one material.
CLASS zcl_zsm_x<run>_so_creator DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF request,
             order_type TYPE auart,
             sales_org  TYPE vkorg,
             distr_chan TYPE vtweg,
             division   TYPE spart,
             customer   TYPE kunnr,
             material   TYPE matnr,
             quantity   TYPE i,
           END OF request.

    METHODS constructor
      IMPORTING api TYPE REF TO zif_zsm_x<run>_so_api.

    METHODS create
      IMPORTING request       TYPE request
      RETURNING VALUE(result) TYPE bapivbeln-vbeln
      RAISING   zcx_zsm_x<run>_so_error.

  PRIVATE SECTION.
    CONSTANTS first_item TYPE posnr_va VALUE '000010'.
    CONSTANTS sold_to_party TYPE parvw VALUE 'AG'.

    DATA api TYPE REF TO zif_zsm_x<run>_so_api.
ENDCLASS.


CLASS zcl_zsm_x<run>_so_creator IMPLEMENTATION.
  METHOD constructor.
    me->api = api.
  ENDMETHOD.

  METHOD create.
    api->create_sales_order(
      EXPORTING header         = VALUE #( doc_type   = request-order_type
                                          sales_org  = request-sales_org
                                          distr_chan = request-distr_chan
                                          division   = request-division )
                items          = VALUE #( ( itm_number    = first_item
                                            material_long = request-material
                                            target_qty    = request-quantity ) )
                partners       = VALUE #( ( partn_role = sold_to_party
                                            partn_numb = request-customer ) )
      IMPORTING sales_document = result
                messages       = DATA(messages) ).

    " The BAPI does not raise exceptions; errors arrive only in the return table
    IF result IS INITIAL
       OR line_exists( messages[ type = 'E' ] )
       OR line_exists( messages[ type = 'A' ] ).
      RAISE EXCEPTION NEW zcx_zsm_x<run>_so_error( messages = messages ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
