REPORT zsm_test.

CLASS lcl_alv DEFINITION.

  PUBLIC SECTION.
    METHODS:
      get_data,
      set_column,
      set_toolbar,
      show_data.

  PROTECTED SECTION.

  PRIVATE SECTION.
    DATA: lt_data TYPE TABLE OF mara,
          lo_alv  TYPE REF TO cl_salv_table.

ENDCLASS.

CLASS lcl_alv IMPLEMENTATION.

  METHOD get_data.

    SELECT *
      INTO TABLE lt_data
      UP TO 100 ROWS
      FROM mara.

  ENDMETHOD.

  METHOD set_column.
    DATA(lo_columns) = lo_alv->get_columns( ).

    lo_columns->get_column( 'MANDT' )->set_visible( abap_false ).
    lo_columns->get_column( 'MATKL' )->set_short_text( 'AMG' ).
    lo_columns->get_column( 'MATKL' )->set_medium_text( 'Ana MG' ).
    lo_columns->get_column( 'MATKL' )->set_long_text( 'Ana Mal Grubu' ).
  ENDMETHOD.

  METHOD set_toolbar.
    DATA(lo_functions) = lo_alv->get_functions( ).

    lo_functions->set_all( abap_true ).
    lo_functions->set_sort_asc( abap_false ).
    lo_functions->set_sort_desc( abap_false ).
  ENDMETHOD.

  METHOD show_data.
    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_alv
          CHANGING
            t_table      = lt_data ).

      CATCH cx_salv_msg INTO DATA(lx_msg).
        cl_demo_output=>display( lx_msg ).
    ENDTRY.

    set_column( ).
    set_toolbar( ).

    lo_alv->display( ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.

  DATA(lo_x_alv) = NEW lcl_alv( ).

  lo_x_alv->get_data( ).
  lo_x_alv->show_data( ).