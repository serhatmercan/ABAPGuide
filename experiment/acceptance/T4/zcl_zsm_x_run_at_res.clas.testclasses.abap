"! Acceptance test for task T4. The stock table is replaced by the ABAP SQL test double,
"! and the lock by a double that records its calls; no real row and no real lock is used.
"! The test does not check when the lock of a successful reservation is released.
CLASS lth_lock DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_zsm_x<run>_stock_lock.

    DATA refuse TYPE abap_bool.
    DATA locks TYPE i READ-ONLY.
    DATA held TYPE i READ-ONLY.
    DATA locked_material TYPE zsm_x<run>_stock-material READ-ONLY.
    DATA locked_plant TYPE zsm_x<run>_stock-plant READ-ONLY.
    DATA reserved_when_locked TYPE i READ-ONLY.
ENDCLASS.


CLASS lth_lock IMPLEMENTATION.
  METHOD zif_zsm_x<run>_stock_lock~lock.
    IF refuse = abap_true.
      RAISE EXCEPTION NEW zcx_zsm_x<run>_locked( ).
    ENDIF.
    locks += 1.
    held += 1.
    locked_material = material.
    locked_plant = plant.
    " Reads the test double: shows whether the row was already changed when the lock was set
    SELECT SINGLE reserved FROM zsm_x<run>_stock
      WHERE material = @material
        AND plant    = @plant
      INTO @reserved_when_locked.
  ENDMETHOD.

  METHOD zif_zsm_x<run>_stock_lock~unlock.
    IF held > 0.
      held -= 1.
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_acceptance DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.

    DATA lock TYPE REF TO lth_lock.
    DATA cut TYPE REF TO zcl_zsm_x<run>_reserver.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS reserved_of
      IMPORTING material      TYPE zsm_x<run>_stock-material
      RETURNING VALUE(result) TYPE i.

    METHODS reserves_under_lock FOR TESTING RAISING cx_static_check.
    METHODS too_little_stock_fails FOR TESTING RAISING cx_static_check.
    METHODS missing_row_fails FOR TESTING RAISING cx_static_check.
    METHODS locked_stock_is_unchanged FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_acceptance IMPLEMENTATION.
  METHOD class_setup.
    sql_environment = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZSM_X<RUN>_STOCK' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    DATA stock TYPE STANDARD TABLE OF zsm_x<run>_stock WITH EMPTY KEY.

    sql_environment->clear_doubles( ).
    stock = VALUE #( ( material = 'M1' plant = 'P1' available = 10 reserved = 2 ) ).
    sql_environment->insert_test_data( i_data = stock ).

    lock = NEW #( ).
    cut = NEW #( lock ).
  ENDMETHOD.

  METHOD reserved_of.
    SELECT SINGLE reserved FROM zsm_x<run>_stock
      WHERE material = @material
        AND plant    = 'P1'
      INTO @result.
  ENDMETHOD.

  METHOD reserves_under_lock.
    cut->reserve( material = 'M1' plant = 'P1' quantity = 5 ).

    cl_abap_unit_assert=>assert_equals( act = reserved_of( 'M1' ) exp = 7 ).
    cl_abap_unit_assert=>assert_equals( act = lock->locks exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lock->locked_material exp = 'M1' ).
    cl_abap_unit_assert=>assert_equals( act = lock->locked_plant exp = 'P1' ).
    cl_abap_unit_assert=>assert_equals( act = lock->reserved_when_locked
                                        exp = 2
                                        msg = 'The lock must be set before the row is changed' ).
  ENDMETHOD.

  METHOD too_little_stock_fails.
    TRY.
        cut->reserve( material = 'M1' plant = 'P1' quantity = 9 ).
        cl_abap_unit_assert=>fail( msg = 'Reserving more than is free must fail' ).
      CATCH zcx_zsm_x<run>_no_stock.
        " expected
    ENDTRY.

    cl_abap_unit_assert=>assert_equals( act = reserved_of( 'M1' ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lock->held exp = 0 msg = 'Nothing may stay locked' ).
  ENDMETHOD.

  METHOD missing_row_fails.
    TRY.
        cut->reserve( material = 'M2' plant = 'P1' quantity = 1 ).
        cl_abap_unit_assert=>fail( msg = 'Reserving stock that does not exist must fail' ).
      CATCH zcx_zsm_x<run>_no_stock.
        " expected
    ENDTRY.

    cl_abap_unit_assert=>assert_equals( act = lock->held exp = 0 msg = 'Nothing may stay locked' ).
  ENDMETHOD.

  METHOD locked_stock_is_unchanged.
    lock->refuse = abap_true.

    TRY.
        cut->reserve( material = 'M1' plant = 'P1' quantity = 1 ).
        cl_abap_unit_assert=>fail( msg = 'A refused lock must stop the reservation' ).
      CATCH zcx_zsm_x<run>_locked.
        " expected
    ENDTRY.

    cl_abap_unit_assert=>assert_equals( act = reserved_of( 'M1' ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lock->held exp = 0 msg = 'Nothing may stay locked' ).
  ENDMETHOD.
ENDCLASS.
