"! Acceptance test for task T1. Uses only the objects and behaviour given in the spec.
"! The API is replaced by a double, so no sales order is created.
CLASS lth_so_api DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_zsm_x<run>_so_api.

    DATA reported_number TYPE bapivbeln-vbeln.
    DATA reported_messages TYPE zif_zsm_x<run>_so_api=>messages.

    DATA received_header TYPE bapisdhd1 READ-ONLY.
    DATA received_items TYPE zif_zsm_x<run>_so_api=>items READ-ONLY.
    DATA received_partners TYPE zif_zsm_x<run>_so_api=>partners READ-ONLY.
    DATA calls TYPE i READ-ONLY.
ENDCLASS.


CLASS lth_so_api IMPLEMENTATION.
  METHOD zif_zsm_x<run>_so_api~create_sales_order.
    calls += 1.
    received_header = header.
    received_items = items.
    received_partners = partners.
    sales_document = reported_number.
    messages = reported_messages.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_acceptance DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA api TYPE REF TO lth_so_api.
    DATA cut TYPE REF TO zcl_zsm_x<run>_so_creator.

    METHODS setup.
    METHODS a_request
      RETURNING VALUE(result) TYPE zcl_zsm_x<run>_so_creator=>request.
    METHODS a_message
      IMPORTING !type         TYPE bapiret2-type
      RETURNING VALUE(result) TYPE bapiret2.

    METHODS returns_the_order_number FOR TESTING RAISING cx_static_check.
    METHODS passes_header FOR TESTING RAISING cx_static_check.
    METHODS passes_one_item FOR TESTING RAISING cx_static_check.
    METHODS passes_the_sold_to_party FOR TESTING RAISING cx_static_check.
    METHODS error_message_fails FOR TESTING.
    METHODS abort_message_fails FOR TESTING.
    METHODS warning_alone_does_not_fail FOR TESTING RAISING cx_static_check.
    METHODS missing_number_fails FOR TESTING.
ENDCLASS.


CLASS ltc_acceptance IMPLEMENTATION.
  METHOD setup.
    api = NEW #( ).
    cut = NEW #( api ).
  ENDMETHOD.

  METHOD a_request.
    result = VALUE #( order_type = 'TA'
                      sales_org  = '1000'
                      distr_chan = '10'
                      division   = '00'
                      customer   = '0000001000'
                      material   = 'M-01'
                      quantity   = 5 ).
  ENDMETHOD.

  METHOD a_message.
    result = VALUE #( type = type id = 'V1' number = '001' message = 'Test message' ).
  ENDMETHOD.

  METHOD returns_the_order_number.
    api->reported_number = '0000012345'.
    api->reported_messages = VALUE #( ( a_message( 'S' ) ) ).

    cl_abap_unit_assert=>assert_equals( act = cut->create( a_request( ) )
                                        exp = '0000012345' ).
    cl_abap_unit_assert=>assert_equals( act = api->calls
                                        exp = 1 ).
  ENDMETHOD.

  METHOD passes_header.
    api->reported_number = '0000012345'.

    cut->create( a_request( ) ).

    cl_abap_unit_assert=>assert_equals( act = api->received_header-doc_type   exp = 'TA' ).
    cl_abap_unit_assert=>assert_equals( act = api->received_header-sales_org  exp = '1000' ).
    cl_abap_unit_assert=>assert_equals( act = api->received_header-distr_chan exp = '10' ).
    cl_abap_unit_assert=>assert_equals( act = api->received_header-division   exp = '00' ).
  ENDMETHOD.

  METHOD passes_one_item.
    api->reported_number = '0000012345'.

    cut->create( a_request( ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( api->received_items ) exp = 1 ).
    DATA(item) = api->received_items[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = item-itm_number exp = '000010' ).
    cl_abap_unit_assert=>assert_equals( act = item-material_long exp = 'M-01' ).
    cl_abap_unit_assert=>assert_equals( act = item-target_qty exp = 5 ).
  ENDMETHOD.

  METHOD passes_the_sold_to_party.
    api->reported_number = '0000012345'.

    cut->create( a_request( ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( api->received_partners ) exp = 1 ).
    DATA(partner) = api->received_partners[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = partner-partn_role exp = 'AG' ).
    cl_abap_unit_assert=>assert_equals( act = partner-partn_numb exp = '0000001000' ).
  ENDMETHOD.

  METHOD error_message_fails.
    api->reported_number = '0000012345'.
    api->reported_messages = VALUE #( ( a_message( 'W' ) ) ( a_message( 'E' ) ) ).

    TRY.
        cut->create( a_request( ) ).
        cl_abap_unit_assert=>fail( msg = 'An E message must make the creation fail' ).
      CATCH zcx_zsm_x<run>_so_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->messages
                                            exp = api->reported_messages ).
    ENDTRY.
  ENDMETHOD.

  METHOD abort_message_fails.
    api->reported_messages = VALUE #( ( a_message( 'A' ) ) ).

    TRY.
        cut->create( a_request( ) ).
        cl_abap_unit_assert=>fail( msg = 'An A message must make the creation fail' ).
      CATCH zcx_zsm_x<run>_so_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->messages
                                            exp = api->reported_messages ).
    ENDTRY.
  ENDMETHOD.

  METHOD warning_alone_does_not_fail.
    api->reported_number = '0000012345'.
    api->reported_messages = VALUE #( ( a_message( 'W' ) ) ( a_message( 'I' ) ) ( a_message( 'S' ) ) ).

    cl_abap_unit_assert=>assert_equals( act = cut->create( a_request( ) )
                                        exp = '0000012345' ).
  ENDMETHOD.

  METHOD missing_number_fails.
    api->reported_messages = VALUE #( ( a_message( 'S' ) ) ).

    TRY.
        cut->create( a_request( ) ).
        cl_abap_unit_assert=>fail( msg = 'A missing order number must make the creation fail' ).
      CATCH zcx_zsm_x<run>_so_error.
        " expected
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
