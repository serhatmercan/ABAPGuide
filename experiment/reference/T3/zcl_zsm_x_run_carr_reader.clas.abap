"! Reads airlines and keeps only those the current user may display.
CLASS zcl_zsm_<run>_carr_reader DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES carrier_ids TYPE RANGE OF s_carr_id.
    TYPES carriers    TYPE STANDARD TABLE OF scarr WITH EMPTY KEY.

    METHODS read
      IMPORTING carrier_ids   TYPE carrier_ids
      RETURNING VALUE(result) TYPE carriers.

  PRIVATE SECTION.
    CONSTANTS display TYPE activ_auth VALUE '03'.

    METHODS may_display
      IMPORTING carrier_id    TYPE s_carr_id
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_zsm_<run>_carr_reader IMPLEMENTATION.
  METHOD read.
    SELECT * FROM scarr
      WHERE carrid IN @carrier_ids
      ORDER BY carrid
      INTO TABLE @DATA(candidates).

    LOOP AT candidates INTO DATA(carrier).
      IF may_display( carrier-carrid ).
        APPEND carrier TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD may_display.
    AUTHORITY-CHECK OBJECT 'S_CARRID'
      ID 'CARRID' FIELD carrier_id
      ID 'ACTVT'  FIELD display.
    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.
ENDCLASS.
