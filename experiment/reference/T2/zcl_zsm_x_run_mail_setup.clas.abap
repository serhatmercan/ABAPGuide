"! Reads the order desk addresses from the variant variable ZSM_<RUN>_ORDER_DESK
"! (TVARVC), which is maintained per system, so no address is in the code.
CLASS zcl_zsm_<run>_mail_setup DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_zsm_<run>_mail_setup.

  PRIVATE SECTION.
    CONSTANTS variable_name TYPE rvari_vnam VALUE 'ZSM_<RUN>_ORDER_DESK'.
ENDCLASS.


CLASS zcl_zsm_<run>_mail_setup IMPLEMENTATION.
  METHOD zif_zsm_<run>_mail_setup~order_desk_recipients.
    SELECT low FROM tvarvc
      WHERE name = @variable_name
        AND type = 'S'
      ORDER BY numb
      INTO TABLE @DATA(addresses).

    result = VALUE #( FOR address IN addresses ( condense( CONV string( address-low ) ) ) ).
  ENDMETHOD.
ENDCLASS.
