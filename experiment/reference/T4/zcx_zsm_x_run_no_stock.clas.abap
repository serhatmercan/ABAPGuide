CLASS zcx_zsm_<run>_no_stock DEFINITION PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING previous LIKE previous OPTIONAL.
ENDCLASS.


CLASS zcx_zsm_<run>_no_stock IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
  ENDMETHOD.
ENDCLASS.
