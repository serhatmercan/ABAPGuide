"! Acceptance test for task T5. Compares the exact JSON text the spec defines.
CLASS ltc_acceptance DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_zsm_x<run>_order_json.

    METHODS setup.
    METHODS an_order
      RETURNING VALUE(result) TYPE zcl_zsm_x<run>_order_json=>order.

    METHODS matches_the_example FOR TESTING.
    METHODS id_of_zeros_is_zero FOR TESTING.
    METHODS initial_date_is_null FOR TESTING.
    METHODS negative_amount_two_decimals FOR TESTING.
    METHODS backslash_is_escaped FOR TESTING.
ENDCLASS.


CLASS ltc_acceptance IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD an_order.
    result = VALUE #( id         = '0000004711'
                      customer   = `ACME "Ltd"`
                      order_date = '20260315'
                      amount     = '1234.5'
                      currency   = 'EUR' ).
  ENDMETHOD.

  METHOD matches_the_example.
    cl_abap_unit_assert=>assert_equals(
      act = cut->to_json( an_order( ) )
      exp = `{"id":"4711","customer":"ACME \"Ltd\"","orderDate":"2026-03-15","amount":1234.50,"currency":"EUR"}` ).
  ENDMETHOD.

  METHOD id_of_zeros_is_zero.
    DATA(order) = an_order( ).
    order-id = '0000000000'.

    cl_abap_unit_assert=>assert_char_cp( act = cut->to_json( order )
                                         exp = `{"id":"0",*` ).
  ENDMETHOD.

  METHOD initial_date_is_null.
    DATA(order) = an_order( ).
    CLEAR order-order_date.

    cl_abap_unit_assert=>assert_char_cp( act = cut->to_json( order )
                                         exp = `*,"orderDate":null,*` ).
  ENDMETHOD.

  METHOD negative_amount_two_decimals.
    DATA(order) = an_order( ).
    order-amount = -5.

    cl_abap_unit_assert=>assert_char_cp( act = cut->to_json( order )
                                         exp = `*,"amount":-5.00,*` ).
  ENDMETHOD.

  METHOD backslash_is_escaped.
    DATA(order) = an_order( ).
    order-customer = `A\B`.

    cl_abap_unit_assert=>assert_char_cp( act = cut->to_json( order )
                                         exp = `*"customer":"A\\B",*` ).
  ENDMETHOD.
ENDCLASS.
