"! Parses uploaded exchange rate lines of the form CURRENCY;RATE;YYYYMMDD.
CLASS zcl_zsm_<run>_rate_import DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF rate,
             currency   TYPE c LENGTH 5,
             rate       TYPE p LENGTH 9 DECIMALS 5,
             valid_from TYPE d,
           END OF rate.
    TYPES rates TYPE STANDARD TABLE OF rate WITH EMPTY KEY.

    METHODS import
      IMPORTING lines         TYPE string_table
      RETURNING VALUE(result) TYPE rates
      RAISING   zcx_zsm_<run>_import_error.

  PRIVATE SECTION.
    CONSTANTS separator TYPE string VALUE `;`.

    METHODS parse
      IMPORTING line  TYPE string
      EXPORTING rate  TYPE rate
                valid TYPE abap_bool
                cause TYPE REF TO cx_sy_conversion_error.
ENDCLASS.


CLASS zcl_zsm_<run>_rate_import IMPLEMENTATION.
  METHOD import.
    DATA invalid_lines TYPE zcx_zsm_<run>_import_error=>line_numbers_type.
    DATA first_cause TYPE REF TO cx_sy_conversion_error.

    LOOP AT lines INTO DATA(line).
      DATA(line_number) = sy-tabix.
      IF condense( line ) = ``.
        CONTINUE.
      ENDIF.

      parse( EXPORTING line  = line
             IMPORTING rate  = DATA(rate)
                       valid = DATA(valid)
                       cause = DATA(cause) ).
      IF valid = abap_true.
        APPEND rate TO result.
      ELSE.
        APPEND line_number TO invalid_lines.
        IF first_cause IS NOT BOUND.
          first_cause = cause.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF invalid_lines IS NOT INITIAL.
      CLEAR result.
      RAISE EXCEPTION NEW zcx_zsm_<run>_import_error( line_numbers = invalid_lines
                                                     previous     = first_cause ).
    ENDIF.
  ENDMETHOD.

  METHOD parse.
    CLEAR: rate, valid, cause.

    SPLIT line AT separator INTO TABLE DATA(fields).
    IF lines( fields ) <> 3.
      RETURN.
    ENDIF.

    DATA(currency) = condense( fields[ 1 ] ).
    IF currency IS INITIAL OR strlen( currency ) > 5.
      RETURN.
    ENDIF.

    DATA(date_text) = condense( fields[ 3 ] ).
    IF strlen( date_text ) <> 8 OR date_text CN '0123456789'.
      RETURN.
    ENDIF.
    DATA(date) = CONV d( date_text ).
    " An invalid date converts to day 0, so the round trip does not return it
    IF CONV d( CONV i( date ) ) <> date.
      RETURN.
    ENDIF.

    TRY.
        DATA(value) = CONV decfloat34( condense( fields[ 2 ] ) ).
        IF value <= 0.
          RETURN.
        ENDIF.
        rate = VALUE #( currency   = currency
                        rate       = EXACT #( value )
                        valid_from = date ).
      CATCH cx_sy_conversion_error INTO cause.
        RETURN.
    ENDTRY.

    valid = abap_true.
  ENDMETHOD.
ENDCLASS.
