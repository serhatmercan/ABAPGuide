"! Acceptance test for task T6. Uses only the behaviour given in the spec.
CLASS ltc_acceptance DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_zsm_x<run>_rate_import.

    METHODS setup.
    METHODS invalid_lines_of
      IMPORTING lines         TYPE string_table
      RETURNING VALUE(result) TYPE zcx_zsm_x<run>_import_error=>line_numbers_type.

    METHODS reads_valid_lines FOR TESTING RAISING cx_static_check.
    METHODS ignores_blank_lines FOR TESTING RAISING cx_static_check.
    METHODS lists_all_invalid_lines FOR TESTING.
    METHODS rejects_text_as_rate FOR TESTING.
    METHODS rejects_rate_not_positive FOR TESTING.
    METHODS rejects_invalid_date FOR TESTING.
    METHODS rejects_long_currency FOR TESTING.
    METHODS cause_is_conversion_error FOR TESTING.
ENDCLASS.


CLASS ltc_acceptance IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD invalid_lines_of.
    TRY.
        cut->import( lines ).
        cl_abap_unit_assert=>fail( msg = 'Invalid lines must make the import fail' ).
      CATCH zcx_zsm_x<run>_import_error INTO DATA(error).
        result = error->line_numbers.
    ENDTRY.
  ENDMETHOD.

  METHOD reads_valid_lines.
    DATA(rates) = cut->import( VALUE #( ( `USD;1.08450;20260301` )
                                        ( `JPY;161.2;20260302` ) ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( rates ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = rates[ 1 ]-currency   exp = 'USD' ).
    cl_abap_unit_assert=>assert_equals( act = rates[ 1 ]-rate       exp = CONV zcl_zsm_x<run>_rate_import=>rate-rate( '1.0845' ) ).
    cl_abap_unit_assert=>assert_equals( act = rates[ 1 ]-valid_from exp = CONV d( '20260301' ) ).
    cl_abap_unit_assert=>assert_equals( act = rates[ 2 ]-currency   exp = 'JPY' ).
    cl_abap_unit_assert=>assert_equals( act = rates[ 2 ]-rate       exp = CONV zcl_zsm_x<run>_rate_import=>rate-rate( '161.2' ) ).
  ENDMETHOD.

  METHOD ignores_blank_lines.
    DATA(rates) = cut->import( VALUE #( ( `` )
                                        ( `USD;1.1;20260301` )
                                        ( `   ` ) ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( rates ) exp = 1 ).
  ENDMETHOD.

  METHOD lists_all_invalid_lines.
    cl_abap_unit_assert=>assert_equals(
      act = invalid_lines_of( VALUE #( ( `USD;1.1;20260301` )
                                       ( `EUR;abc;20260301` )
                                       ( `JPY;161.2;20260302` )
                                       ( `GBP;0.85` ) ) )
      exp = VALUE zcx_zsm_x<run>_import_error=>line_numbers_type( ( 2 ) ( 4 ) ) ).
  ENDMETHOD.

  METHOD rejects_text_as_rate.
    cl_abap_unit_assert=>assert_equals( act = invalid_lines_of( VALUE #( ( `EUR;abc;20260301` ) ) )
                                        exp = VALUE zcx_zsm_x<run>_import_error=>line_numbers_type( ( 1 ) ) ).
  ENDMETHOD.

  METHOD rejects_rate_not_positive.
    cl_abap_unit_assert=>assert_equals( act = invalid_lines_of( VALUE #( ( `USD;0;20260301` )
                                                                         ( `USD;-1.5;20260301` ) ) )
                                        exp = VALUE zcx_zsm_x<run>_import_error=>line_numbers_type( ( 1 ) ( 2 ) ) ).
  ENDMETHOD.

  METHOD rejects_invalid_date.
    cl_abap_unit_assert=>assert_equals( act = invalid_lines_of( VALUE #( ( `USD;1.1;20260231` )
                                                                         ( `USD;1.1;2026-03-01` ) ) )
                                        exp = VALUE zcx_zsm_x<run>_import_error=>line_numbers_type( ( 1 ) ( 2 ) ) ).
  ENDMETHOD.

  METHOD rejects_long_currency.
    cl_abap_unit_assert=>assert_equals( act = invalid_lines_of( VALUE #( ( `EUROXX;1.1;20260301` ) ) )
                                        exp = VALUE zcx_zsm_x<run>_import_error=>line_numbers_type( ( 1 ) ) ).
  ENDMETHOD.

  METHOD cause_is_conversion_error.
    " The spec passes a runtime conversion error on, if one occurred; code that
    " validates without conversion may leave previous initial.
    TRY.
        cut->import( VALUE #( ( `EUR;abc;20260301` ) ) ).
        cl_abap_unit_assert=>fail( msg = 'Invalid lines must make the import fail' ).
      CATCH zcx_zsm_x<run>_import_error INTO DATA(error).
        IF error->previous IS BOUND.
          cl_abap_unit_assert=>assert_true( act = xsdbool( error->previous IS INSTANCE OF cx_sy_conversion_error )
                                            msg = 'A passed-on cause must be the conversion error' ).
        ENDIF.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
