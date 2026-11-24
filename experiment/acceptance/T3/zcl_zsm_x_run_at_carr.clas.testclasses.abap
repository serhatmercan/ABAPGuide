"! Acceptance test for task T3. SCARR is replaced by the ABAP SQL test double, and the
"! authorizations are restricted with the ABAP Unit authorization test environment.
"! The environment can only restrict the tester's real authorizations: tests that need
"! S_CARRID display authorization for AA, LH or UA are skipped where the tester lacks it.
CLASS ltc_acceptance DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.

    DATA controller TYPE REF TO if_aunit_auth_check_controller.
    DATA cut TYPE REF TO zcl_zsm_x<run>_carr_reader.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.

    METHODS allow
      IMPORTING carrier_ids   TYPE string_table
                activity      TYPE string DEFAULT `03`
      RETURNING VALUE(result) TYPE REF TO if_aunit_authority_objset.
    METHODS ids_of
      IMPORTING carriers      TYPE zcl_zsm_x<run>_carr_reader=>carriers
      RETURNING VALUE(result) TYPE string_table.

    METHODS returns_authorized_sorted FOR TESTING RAISING cx_static_check.
    METHODS no_authorization_no_rows FOR TESTING RAISING cx_static_check.
    METHODS range_restricts_rows FOR TESTING RAISING cx_static_check.
    METHODS change_is_not_display FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_acceptance IMPLEMENTATION.
  METHOD class_setup.
    sql_environment = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'SCARR' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_environment->clear_doubles( ).
    DATA(carriers) = VALUE zcl_zsm_x<run>_carr_reader=>carriers(
        ( carrid = 'UA' carrname = 'Test Airline UA' currcode = 'USD' )
        ( carrid = 'AA' carrname = 'Test Airline AA' currcode = 'USD' )
        ( carrid = 'LH' carrname = 'Test Airline LH' currcode = 'EUR' ) ).
    sql_environment->insert_test_data( i_data = carriers ).

    controller = cl_aunit_authority_check=>get_controller( ).
    cut = NEW #( ).
  ENDMETHOD.

  METHOD teardown.
    controller->reset( ).
  ENDMETHOD.

  METHOD allow.
    DATA carrier_values TYPE cl_aunit_auth_check_types_def=>authfield_values-fieldvalues.

    carrier_values = VALUE #( FOR id IN carrier_ids ( lower_value = id ) ).
    result = cl_aunit_authority_check=>create_auth_object_set(
        VALUE #( ( role_authorizations = VALUE #(
                     ( object         = 'S_CARRID'
                       authorizations = VALUE #(
                         ( VALUE #( ( fieldname = 'CARRID' fieldvalues = carrier_values )
                                    ( fieldname = 'ACTVT'  fieldvalues = VALUE #( ( lower_value = activity ) ) ) ) ) ) ) ) ) ) ).
  ENDMETHOD.

  METHOD ids_of.
    result = VALUE #( FOR carrier IN carriers ( CONV string( carrier-carrid ) ) ).
  ENDMETHOD.

  METHOD returns_authorized_sorted.
    controller->restrict_authorizations_to( allow( VALUE #( ( `LH` ) ( `AA` ) ) ) ).

    cl_abap_unit_assert=>assert_equals( act = ids_of( cut->read( VALUE #( ) ) )
                                        exp = VALUE string_table( ( `AA` ) ( `LH` ) ) ).
  ENDMETHOD.

  METHOD no_authorization_no_rows.
    controller->restrict_authorizations_to( cl_aunit_authority_check=>create_auth_object_set( ) ).

    cl_abap_unit_assert=>assert_initial( cut->read( VALUE #( ) ) ).
  ENDMETHOD.

  METHOD range_restricts_rows.
    controller->restrict_authorizations_to( allow( VALUE #( ( `AA` ) ( `LH` ) ( `UA` ) ) ) ).

    cl_abap_unit_assert=>assert_equals( act = ids_of( cut->read( VALUE #( ( sign = 'I' option = 'EQ' low = 'LH' ) ) ) )
                                        exp = VALUE string_table( ( `LH` ) ) ).
  ENDMETHOD.

  METHOD change_is_not_display.
    controller->restrict_authorizations_to( allow( carrier_ids = VALUE #( ( `AA` ) )
                                                   activity    = `02` ) ).

    cl_abap_unit_assert=>assert_initial( cut->read( VALUE #( ) ) ).
  ENDMETHOD.
ENDCLASS.
