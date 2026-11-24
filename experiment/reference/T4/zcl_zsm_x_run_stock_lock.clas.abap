"! Locks stock rows with the lock object EZSM_<RUN>_STOCK through the released lock API.
CLASS zcl_zsm_<run>_stock_lock DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_zsm_<run>_stock_lock.

  PRIVATE SECTION.
    CONSTANTS lock_object_name TYPE if_abap_lock_object=>tv_name VALUE 'EZSM_<RUN>_STOCK'.

    METHODS lock_parameters
      IMPORTING material      TYPE REF TO data
                plant         TYPE REF TO data
      RETURNING VALUE(result) TYPE if_abap_lock_object=>tt_parameter.
ENDCLASS.


CLASS zcl_zsm_<run>_stock_lock IMPLEMENTATION.
  METHOD zif_zsm_<run>_stock_lock~lock.
    TRY.
        cl_abap_lock_object_factory=>get_instance( lock_object_name )->enqueue(
            it_parameter = lock_parameters( material = REF #( material )
                                            plant    = REF #( plant ) ) ).

      CATCH cx_abap_foreign_lock cx_abap_lock_failure INTO DATA(lock_error).
        RAISE EXCEPTION NEW zcx_zsm_<run>_locked( previous = lock_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_zsm_<run>_stock_lock~unlock.
    TRY.
        cl_abap_lock_object_factory=>get_instance( lock_object_name )->dequeue(
            it_parameter = lock_parameters( material = REF #( material )
                                            plant    = REF #( plant ) ) ).

      CATCH cx_abap_lock_failure.
        " A lock that cannot be released ends with the SAP LUW at the latest
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD lock_parameters.
    result = VALUE #( ( name = 'MATERIAL' value = material )
                      ( name = 'PLANT'    value = plant ) ).
  ENDMETHOD.
ENDCLASS.
