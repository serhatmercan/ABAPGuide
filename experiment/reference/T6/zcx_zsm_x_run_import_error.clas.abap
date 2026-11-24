CLASS zcx_zsm_<run>_import_error DEFINITION PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES line_numbers_type TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA line_numbers TYPE line_numbers_type READ-ONLY.
    METHODS constructor
      IMPORTING line_numbers TYPE line_numbers_type OPTIONAL
                previous     LIKE previous OPTIONAL.
ENDCLASS.


CLASS zcx_zsm_<run>_import_error IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->line_numbers = line_numbers.
  ENDMETHOD.
ENDCLASS.
