"! Writes an order as JSON for the external shop system.
CLASS zcl_zsm_<run>_order_json DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF order,
             id         TYPE c LENGTH 10,
             customer   TYPE string,
             order_date TYPE d,
             amount     TYPE p LENGTH 15 DECIMALS 2,
             currency   TYPE c LENGTH 5,
           END OF order.

    METHODS to_json
      IMPORTING order         TYPE order
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    METHODS json_string
      IMPORTING value         TYPE string
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_zsm_<run>_order_json IMPLEMENTATION.
  METHOD to_json.
    DATA(id) = shift_left( val = condense( CONV string( order-id ) ) sub = `0` ).
    IF id = ``.
      id = `0`.
    ENDIF.

    DATA(order_date) = COND string( WHEN order-order_date IS INITIAL THEN `null`
                                    ELSE json_string( |{ order-order_date DATE = ISO }| ) ).

    result = |\{"id":{ json_string( id ) },| &&
             |"customer":{ json_string( order-customer ) },| &&
             |"orderDate":{ order_date },| &&
             |"amount":{ order-amount DECIMALS = 2 },| &&
             |"currency":{ json_string( condense( CONV string( order-currency ) ) ) }\}|.
  ENDMETHOD.

  METHOD json_string.
    result = |"{ escape( val = value format = cl_abap_format=>e_json_string ) }"|.
  ENDMETHOD.
ENDCLASS.
