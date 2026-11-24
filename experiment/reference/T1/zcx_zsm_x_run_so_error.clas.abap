CLASS zcx_zsm_x<run>_so_error DEFINITION PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    DATA messages TYPE zif_zsm_x<run>_so_api=>messages READ-ONLY.
    METHODS constructor
      IMPORTING messages LIKE messages OPTIONAL
                previous LIKE previous OPTIONAL.
ENDCLASS.


CLASS zcx_zsm_x<run>_so_error IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->messages = messages.
  ENDMETHOD.
ENDCLASS.
