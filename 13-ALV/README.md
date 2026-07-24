# 13 — ALV (ABAP List Viewer)

## 📖 Introduction

ALV is the standard SAP grid control for displaying tabular data with sorting, filtering, totals, and export capabilities built in. There are three common ways to build an ALV report, from simplest to most flexible:

| Approach | Class/FM | Complexity | Flexibility |
|---|---|---|---|
| **SALV** (simple API) | `cl_salv_table` | ⭐ Low | ⭐⭐ Medium |
| **Function-module based** | `REUSE_ALV_GRID_DISPLAY` | ⭐⭐ Medium | ⭐⭐⭐ High (classic events) |
| **OOP ALV Grid** | `cl_gui_alv_grid` | ⭐⭐⭐ High | ⭐⭐⭐⭐ Highest (full event handling, editable grids) |

## 🟢 Option 1 — `cl_salv_table` (Simple ALV / SALV)

The quickest way to display a table, with a clean object-oriented API. Best for simple, read-mostly reports.

```abap
REPORT zsm_tst.

CLASS lcl_alv DEFINITION.
  PUBLIC SECTION.
    METHODS get_data.
    METHODS set_column.
    METHODS set_display.
    METHODS set_header.
    METHODS set_toolbar.
    METHODS show_data.

  PRIVATE SECTION.
    DATA lt_data TYPE TABLE OF mara.
    DATA lo_alv  TYPE REF TO cl_salv_table.
ENDCLASS.


CLASS lcl_alv IMPLEMENTATION.
  METHOD get_data.
    SELECT * FROM mara INTO TABLE lt_data UP TO 100 ROWS.
  ENDMETHOD.

  METHOD set_column.
    DATA(lo_columns) = lo_alv->get_columns( ).

    lo_columns->get_column( 'MANDT' )->set_visible( abap_false ).
    lo_columns->get_column( 'MATKL' )->set_short_text( 'AMG' ).
    lo_columns->get_column( 'MATKL' )->set_medium_text( 'Ana MG' ).
    lo_columns->get_column( 'MATKL' )->set_long_text( 'Ana Mal Grubu' ).

    lo_columns->set_optimize( abap_true ).
  ENDMETHOD.

  METHOD set_display.
    DATA(lo_display) = lo_alv->get_display_settings( ).

    lo_display->set_list_header( 'SALV Report' ).
    lo_display->set_striped_pattern( abap_true ).
  ENDMETHOD.

  METHOD set_header.
    DATA(lo_header) = NEW cl_salv_form_layout_grid( ).

    lo_header->create_label( row    = 1
                             column = 1 )->set_text( 'Header' ).
    lo_header->create_flow( row    = 2
                            column = 1 )->create_text( text = 'Subheader' ).

    lo_alv->set_top_of_list( lo_header ).
  ENDMETHOD.

  METHOD set_toolbar.
    DATA(lo_functions) = lo_alv->get_functions( ).

    lo_functions->set_all( abap_true ).
    lo_functions->set_sort_asc( abap_false ).
    lo_functions->set_sort_desc( abap_false ).
  ENDMETHOD.

  METHOD show_data.
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                                CHANGING  t_table      = lt_data ).
      CATCH cx_salv_msg INTO DATA(lx_msg).
        cl_demo_output=>display( lx_msg ).
    ENDTRY.

    " ... call set_column( ), set_display( ), set_header( ), set_toolbar( ) here ...
    lo_alv->display( ).
  ENDMETHOD.
ENDCLASS.
```

## 🟡 Option 2 — Function-Module Based ALV (`REUSE_ALV_GRID_DISPLAY`)

The classic function-module approach, still very common in existing systems, offering full control over field catalog, layout, sort, filter, and events via callback forms.

```abap
CONSTANTS gc_program_name TYPE sy-repid VALUE 'ZSMERCAN'.

TYPE-POOLS: slis, stms.

DATA gs_layout          TYPE lvc_s_layo.
DATA gs_print           TYPE slis_print_alv.
DATA gs_variant         TYPE disvariant.
DATA gt_bseg            TYPE TABLE OF bseg.
DATA gt_excluding       TYPE slis_t_extab.
DATA gt_events          TYPE slis_t_event.
DATA gt_fieldcat        TYPE lvc_t_fcat.
DATA gt_filter          TYPE slis_t_filter_alv.
DATA gt_list_commentary TYPE slis_t_listheader.
DATA gt_sort            TYPE slis_t_sortinfo_alv.
DATA gt_table           TYPE TABLE OF zsm_s_structure.
DATA gv_exit            TYPE char1.
DATA gv_tabname         TYPE slis_tabname.
DATA gv_title           TYPE lvc_title.

PARAMETERS p_variant TYPE disvariant-variant.

INITIALIZATION.
  gs_variant-report = sy-repid.

  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
    CHANGING   cs_variant    = gs_variant
    EXCEPTIONS wrong_input   = 1
               not_found     = 2
               program_error = 3
               OTHERS        = 4.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_variant.
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING  is_variant    = gs_variant
    IMPORTING  e_exit        = gv_exit
               es_variant    = gs_variant
    EXCEPTIONS not_found     = 1
               program_error = 2
               OTHERS        = 3.
  IF sy-subrc = 0 AND gv_exit IS INITIAL.
    p_variant = gs_variant-variant.
  ENDIF.

  " Generate a field catalog automatically from the internal table's structure
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING i_program_name     = sy-repid
              i_internal_tabname = gv_tabname
              i_inclname         = sy-repid
    CHANGING  ct_fieldcat        = gt_fieldcat[].

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING i_program_name         = gc_program_name
              i_structure_name       = 'BSEG'
              i_client_never_display = abap_true
              i_inclname             = gc_program_name
    CHANGING  ct_fieldcat            = gt_fieldcat[].

  " Show the ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING  i_buffer_active         = abap_false
               i_callback_program      = sy-repid
               i_callback_top_of_page  = 'TOP_OF_PAGE'
               i_callback_user_command = 'USER_COMMAND'
               i_grid_title            = gv_title
               i_save                  = 'A'
               is_layout               = gs_layout
               is_print                = gs_print
               is_variant              = gs_variant
               it_excluding            = gt_excluding
               it_events               = gt_events
               it_fieldcat             = gt_fieldcat[]
               it_filter               = gt_filter
               it_sort                 = gt_sort
    TABLES     t_outtab                = gt_bseg
    EXCEPTIONS program_error           = 1
               OTHERS                  = 2.
  IF sy-subrc <> 0.
  ENDIF.

FORM set_color.
  LOOP AT gt_table ASSIGNING FIELD-SYMBOL(<fs_table>).
    IF <fs_table>-ebelp = '10'.
      <fs_table>-line_color = 'C301'.
    ELSE.
      APPEND INITIAL LINE TO <fs_table>-cell_color ASSIGNING FIELD-SYMBOL(<fs_cell_color>).
      <fs_cell_color>-fieldname = 'MATNR'.
      <fs_cell_color>-color-col = '3'.
      <fs_cell_color>-color-int = '1'.
      <fs_cell_color>-color-inv = '0'.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM set_filter.
  APPEND VALUE #( fieldname = 'EBELP'
                  tabname   = 'GT_BSEG'
                  sign0     = 'I'
                  optio     = 'EQ'
                  valuf_int = '20' ) TO gt_filter.
ENDFORM.

FORM set_events.
  APPEND VALUE #( name = slis_ev_top_of_page
                  form = 'TOP_OF_PAGE' ) TO gt_events.
  APPEND VALUE #( name = slis_ev_end_of_list
                  form = 'END_OF_LIST' ) TO gt_events.
  APPEND VALUE #( name = slis_ev_pf_status_set
                  form = 'PF_STATUS_SET' ) TO gt_events.
ENDFORM.

FORM set_excluding.
  APPEND VALUE #( fcode = '&INFO' ) TO gt_excluding.
ENDFORM.

FORM set_sort.
  APPEND VALUE #( down      = abap_true
                  fieldname = 'BSART'
                  spos      = 1
                  tabname   = 'GT_BSEG' ) TO gt_sort.
  APPEND VALUE #( down      = abap_true
                  fieldname = 'MENGE'
                  spos      = 2
                  tabname   = 'GT_BSEG' ) TO gt_sort.
ENDFORM.

FORM variant.
  gs_variant-variant = p_variant.
ENDFORM.

FORM pf_status_set USING p_exttab TYPE slis_t_extab.
  SET PF-STATUS '0100'.
ENDFORM.

FORM top_of_page.
  APPEND VALUE #( typ  = 'H'
                  info = 'PO Report' ) TO gt_list_commentary.
  APPEND VALUE #( typ  = 'S'
                  key  = 'Date'
                  info = '27/11/2022' ) TO gt_list_commentary.
  APPEND VALUE #( typ  = 'A'
                  key  = 'Report Count:'
                  info = '100' ) TO gt_list_commentary.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING it_list_commentary = gt_list_commentary.
ENDFORM.

FORM user_command USING p_ucomm     TYPE sy-ucomm
                        ps_selfield TYPE slis_selfield.
  " Handle custom toolbar function codes here (e.g., navigate on double-click)
ENDFORM.
```

## 🔵 Option 3 — OOP ALV Grid (`cl_gui_alv_grid`) — Full Interactive Control

This is the most powerful and flexible approach: a container-based grid with rich event handling (editable cells, hotspots, custom toolbar buttons, F4 help, drag & drop, etc.). Ideal for interactive dynpro-based tools.

```abap
CLASS lcl_main DEFINITION DEFERRED.

DATA go_container     TYPE REF TO cl_gui_custom_container.
DATA go_document      TYPE REF TO cl_dd_document.
DATA go_main          TYPE REF TO lcl_main.
DATA go_grid          TYPE REF TO cl_gui_alv_grid.
DATA go_splitter      TYPE REF TO cl_gui_splitter_container.
DATA go_subcontainer1 TYPE REF TO cl_gui_container.
DATA go_subcontainer2 TYPE REF TO cl_gui_container.
DATA gt_out           TYPE TABLE OF zsm_t_table.

INITIALIZATION.
  go_main = NEW #( ).

START-OF-SELECTION.
  go_main->start_of_selection( ).

CLASS lcl_main DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS start_of_selection.

    CLASS-METHODS show_alv IMPORTING iv_container_name TYPE char50
                                     iv_structure_name TYPE dd02l-tabname
                           CHANGING  co_container      TYPE REF TO cl_gui_custom_container
                                     co_grid           TYPE REF TO cl_gui_alv_grid
                                     ct_data           TYPE STANDARD TABLE.

    CLASS-METHODS handle_after_user_command       FOR EVENT after_user_command    OF cl_gui_alv_grid IMPORTING e_ucomm e_saved e_not_processed.
    CLASS-METHODS handle_before_user_command      FOR EVENT before_user_command   OF cl_gui_alv_grid IMPORTING e_ucomm.
    CLASS-METHODS handle_button_click             FOR EVENT button_click          OF cl_gui_alv_grid IMPORTING es_col_id es_row_no.
    CLASS-METHODS handle_context_menu_request     FOR EVENT context_menu_request  OF cl_gui_alv_grid IMPORTING e_object.
    CLASS-METHODS handle_data_changed             FOR EVENT data_changed          OF cl_gui_alv_grid IMPORTING er_data_changed e_onf4 e_onf4_before e_onf4_after e_ucomm.
    CLASS-METHODS handle_data_changed_finished    FOR EVENT data_changed_finished OF cl_gui_alv_grid IMPORTING sender e_modified.
    CLASS-METHODS handle_double_click             FOR EVENT double_click          OF cl_gui_alv_grid IMPORTING e_row e_column es_row_no.
    CLASS-METHODS handle_hotspot_click            FOR EVENT hotspot_click         OF cl_gui_alv_grid IMPORTING e_row_id e_column_id es_row_no.
    CLASS-METHODS handle_insert_icons             FOR EVENT toolbar               OF cl_gui_alv_grid IMPORTING e_object.
    CLASS-METHODS handle_menu_button              FOR EVENT menu_button           OF cl_gui_alv_grid IMPORTING e_object e_ucomm.
    CLASS-METHODS handle_on_f1                    FOR EVENT onf1                  OF cl_gui_alv_grid IMPORTING e_fieldname es_row_no  er_event_data.
    CLASS-METHODS handle_on_f4                    FOR EVENT onf4                  OF cl_gui_alv_grid IMPORTING e_fieldname e_fieldvalue es_row_no er_event_data et_bad_cells e_display.
    CLASS-METHODS handle_toolbar                  FOR EVENT toolbar               OF cl_gui_alv_grid IMPORTING sender e_object e_interactive.
    CLASS-METHODS handle_top_of_page               FOR EVENT top_of_page           OF cl_gui_alv_grid IMPORTING e_dyndoc_id table_index.
    CLASS-METHODS handle_user_command              FOR EVENT user_command          OF cl_gui_alv_grid IMPORTING e_ucomm.

  PRIVATE SECTION.
    CLASS-METHODS get_data.
    CLASS-METHODS show_data.
    CLASS-METHODS set_dropdown RETURNING VALUE(rt_dropdown) TYPE lvc_t_drop.

    CLASS-METHODS set_fieldcatalog IMPORTING VALUE(iv_structure_name) TYPE dd02l-tabname
                                   RETURNING VALUE(rt_fielcat)        TYPE lvc_t_fcat.

    CLASS-METHODS set_filter     RETURNING VALUE(rt_filter)     TYPE lvc_t_filt.
    CLASS-METHODS set_layout     RETURNING VALUE(rs_layout_alv) TYPE lvc_s_layo.
    CLASS-METHODS set_sort       RETURNING VALUE(rs_sort)       TYPE lvc_t_sort.
    CLASS-METHODS set_variant    RETURNING VALUE(rt_variant)    TYPE disvariant.
    CLASS-METHODS set_toolbar_ex CHANGING  VALUE(ct_toolbar_ex) TYPE ui_functions.
ENDCLASS.


CLASS lcl_main IMPLEMENTATION.
  METHOD start_of_selection.
    get_data( ).

    IF gt_out[] IS INITIAL.
      MESSAGE 'No Record.' TYPE 'S' DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.

    show_data( ).
  ENDMETHOD.

  METHOD show_alv.
    DATA lt_dropdown   TYPE lvc_t_drop.
    DATA lt_fieldcat   TYPE lvc_t_fcat.
    DATA lt_filter     TYPE lvc_t_filt.
    DATA lt_sort       TYPE lvc_t_sort.
    DATA lt_toolbar_ex TYPE ui_functions.
    DATA ls_layout     TYPE lvc_s_layo.
    DATA ls_variant    TYPE disvariant.

    lt_dropdown = set_dropdown( ).
    lt_fieldcat = set_fieldcatalog( iv_structure_name = iv_structure_name ).
    lt_filter   = set_filter( ).
    lt_sort     = set_sort( ).
    ls_layout   = set_layout( ).
    ls_variant  = set_variant( ).

    IF co_container IS INITIAL.
      co_container = NEW #( container_name = iv_container_name ).

      IF co_grid IS INITIAL.
        " Screen with a named custom container
        co_grid = NEW #( i_parent = co_container ).

        " Alternative: full-screen grid, no container needed
        co_grid = NEW #( i_parent = cl_gui_container=>screen0 ).

        set_toolbar_ex( CHANGING ct_toolbar_ex = lt_toolbar_ex ).

        co_grid->set_drop_down_table( it_drop_down = lt_dropdown ).

        co_grid->set_table_for_first_display(
            EXPORTING  i_buffer_active               = space
                       is_layout                     = ls_layout
                       it_toolbar_excluding          = lt_toolbar_ex
                       i_save                        = 'U'      " A -> All | U -> User Specific | X -> Standard | Space -> No Save Variant
                       is_variant                    = ls_variant
                       i_default                     = abap_true
            CHANGING   it_sort                       = lt_sort
                       it_filter                     = lt_filter
                       it_outtab                     = ct_data
                       it_fieldcatalog               = lt_fieldcat
            EXCEPTIONS invalid_parameter_combination = 1
                       program_error                 = 2
                       too_many_lines                = 3
                       OTHERS                        = 4 ).

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        co_grid->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_enter ).
        co_grid->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_modified ).

        SET HANDLER go_main->handle_button_click          FOR co_grid.
        SET HANDLER go_main->handle_data_changed          FOR co_grid.
        SET HANDLER go_main->handle_data_changed_finished FOR co_grid.
        SET HANDLER go_main->handle_double_click          FOR co_grid.
        SET HANDLER go_main->handle_hotspot_click         FOR co_grid.
        SET HANDLER go_main->handle_on_f4                 FOR co_grid.
        SET HANDLER go_main->handle_toolbar               FOR co_grid.
        SET HANDLER go_main->handle_top_of_page           FOR co_grid.
        SET HANDLER go_main->handle_user_command          FOR co_grid.

        co_grid->set_ready_for_input( i_ready_for_input = 1 ).
        co_grid->set_toolbar_interactive( ).
      ELSE.
        co_grid->refresh_table_display( is_stable      = VALUE lvc_s_stbl( col = abap_true
                                                                           row = abap_true )
                                        i_soft_refresh = abap_true ).
      ENDIF.
    ELSE.
      co_grid->refresh_table_display( is_stable      = VALUE lvc_s_stbl( col = abap_true
                                                                         row = abap_true )
                                      i_soft_refresh = abap_true ).
    ENDIF.
  ENDMETHOD.

  METHOD handle_after_user_command.
    go_grid->get_selected_rows( IMPORTING et_index_rows = DATA(lt_selected) ).

    IF lt_selected IS INITIAL.
      MESSAGE 'No rows selected.' TYPE 'I'.
      RETURN.
    ENDIF.

    LOOP AT lt_selected INTO DATA(ls_selected).
      READ TABLE gt_out INTO DATA(ls_data) INDEX ls_selected-row_id.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      CASE e_ucomm.
        WHEN 'DELETE'.
          DELETE gt_out INDEX ls_selected-row_id.
        WHEN 'EDIT'.
          ls_data-fieldname = 'New Value'.
          MODIFY gt_out FROM ls_data INDEX ls_selected-row_id.
        WHEN 'DISPLAY'.
          WRITE: / 'Selected Row:', ls_data.
        WHEN OTHERS.
          MESSAGE 'Unknown command' TYPE 'E'.
      ENDCASE.
    ENDLOOP.

    go_grid->refresh_table_display( ).
  ENDMETHOD.

  METHOD handle_before_user_command.
    go_grid->get_selected_rows( IMPORTING et_index_rows = DATA(lt_selected) ).

    IF lt_selected IS INITIAL.
      MESSAGE 'No rows selected. Please select at least one row.' TYPE 'I'.
      RETURN.
    ENDIF.

    CASE e_ucomm.
      WHEN 'DELETE'.
        AUTHORITY-CHECK OBJECT 'Z_DELETE_AUTH' ID 'ACTVT' FIELD '06'.
        IF sy-subrc <> 0.
          MESSAGE 'You do not have authorization to delete.' TYPE 'E'.
          RETURN.
        ENDIF.
      WHEN 'EDIT'.
      WHEN OTHERS.
    ENDCASE.
  ENDMETHOD.

  METHOD handle_button_click.
    READ TABLE gt_out INTO DATA(ls_out) INDEX es_row_no-row_id.
    IF sy-subrc = 0.
      CASE es_col_id-fieldname.
        WHEN 'BUTTON'.
          MESSAGE es_col_id-fieldname TYPE 'I'.
      ENDCASE.
    ENDIF.
  ENDMETHOD.

  METHOD handle_context_menu_request.
    DATA lt_menu TYPE TABLE OF cl_ctmenu=>ty_s_node.

    APPEND VALUE #( text    = 'Delete Row'
                    item_id = 'DELETE' ) TO lt_menu.
    APPEND VALUE #( text    = 'Edit Row'
                    item_id = 'EDIT' ) TO lt_menu.
    APPEND VALUE #( text    = 'Display Details'
                    item_id = 'DISPLAY' ) TO lt_menu.

    e_object->add_items( it_items = lt_menu ).
  ENDMETHOD.

  METHOD handle_data_changed.
    LOOP AT er_data_changed->mt_good_cells REFERENCE INTO DATA(ls_cell).
      CASE ls_cell->fieldname.
        WHEN 'CHBOX'.
          MESSAGE s001(zit_2020_07) WITH ls_cell->row_id.
          MESSAGE s001(zit_2020_07) WITH ls_cell->value.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD handle_data_changed_finished.
    CHECK e_modified IS NOT INITIAL.
    CASE sender.
      WHEN go_grid.
        go_grid->get_current_cell( IMPORTING es_col_id = DATA(lv_current_col_id)
                                             es_row_no = DATA(ls_current_row_no) ).

        CASE lv_current_col_id.
          WHEN 'LFIMG'.
            ASSIGN gt_out[ ls_current_row_no-row_id ] TO FIELD-SYMBOL(<ls_out>).
            IF sy-subrc = 0.
              <ls_out>-color = 'C610'.
            ENDIF.
        ENDCASE.

        go_grid->refresh_table_display( is_stable      = VALUE lvc_s_stbl( col = abap_true
                                                                           row = abap_true )
                                        i_soft_refresh = abap_true ).
    ENDCASE.
  ENDMETHOD.

  METHOD handle_hotspot_click.
    READ TABLE gt_out REFERENCE INTO DATA(ls_out) INDEX es_row_no-row_id.
    IF sy-subrc = 0 AND e_column_id-fieldname = 'VBELN'.
      SET PARAMETER ID 'VL' FIELD ls_out->vbeln.
      CALL TRANSACTION 'VL03N'.
    ENDIF.
  ENDMETHOD.

  METHOD handle_insert_icons.
    DATA lt_toolbar TYPE ui_functions.

    lt_toolbar = VALUE #(
        ( function = 'ADD_ROW'    icon = icon_add     text = 'Add Row'    quickinfo = 'Add a new row' )
        ( function = 'DELETE_ROW' icon = icon_delete  text = 'Delete Row' quickinfo = 'Delete the selected row' )
        ( function = 'REFRESH'    icon = icon_refresh text = 'Refresh'    quickinfo = 'Refresh the data' ) ).

    e_object->mt_toolbar = lt_toolbar.
  ENDMETHOD.

  METHOD handle_on_f1.
    CASE e_fieldname.
      WHEN 'VBELN'.
        MESSAGE 'Sales Order Number: Unique identifier for a sales document.' TYPE 'I'.
      WHEN 'MATNR'.
        MESSAGE 'Material Number: Unique identifier for a material.' TYPE 'I'.
      WHEN OTHERS.
        MESSAGE 'No help available for this field.' TYPE 'I'.
    ENDCASE.
  ENDMETHOD.

  METHOD handle_on_f4.
    TYPES: BEGIN OF lty_value_tab,
             pstyv TYPE pstyv,
           END OF lty_value_tab.

    DATA lt_return_tab TYPE TABLE OF ddshretval.
    DATA lt_value_tab  TYPE TABLE OF lty_value_tab.

    lt_value_tab = VALUE #( ( pstyv = 'X' )
                            ( pstyv = 'Y' )
                            ( pstyv = 'Z' ) ).

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING retfield     = 'PSTYV'
                window_title = 'PSTYV F4'
      TABLES    value_tab    = lt_value_tab
                return_tab   = lt_return_tab.

    IF line_exists( lt_return_tab[ fieldname = 'F0001' ] ).
      IF line_exists( gt_out[ es_row_no-row_id ] ).
        gt_out[ es_row_no-row_id ]-pstyv = lt_return_tab[ fieldname = 'F0001' ]-fieldval.
        go_grid->refresh_table_display( ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD handle_toolbar.
    CASE sender.
      WHEN go_grid.
        APPEND VALUE #( function  = '100_SLA'
                        quickinfo = TEXT-101
                        text      = TEXT-101
                        icon      = icon_select_all ) TO e_object->mt_toolbar.
        APPEND VALUE #( function  = 'ADD_LINE'
                        quickinfo = TEXT-102
                        text      = TEXT-102
                        icon      = icon_insert_row ) TO e_object->mt_toolbar.
    ENDCASE.
  ENDMETHOD.

  METHOD handle_top_of_page.
    go_document->add_text( text      = 'Header'
                           sap_style = cl_dd_document=>heading ).

    go_document->new_line( ).

    go_document->add_text( text         = 'Subheader'
                           sap_color    = cl_dd_document=>list_positive
                           sap_fontsize = cl_dd_document=>medium ).

    go_document->display_document( parent = go_subcontainer1 ).
  ENDMETHOD.

  METHOD get_data.
    SELECT * FROM lips
      INTO CORRESPONDING FIELDS OF TABLE gt_out
      UP TO 20 ROWS.

    LOOP AT gt_out REFERENCE INTO DATA(ls_out) WHERE pstyv = 'NLC'.
      ls_out->button = 'C710'.
      ls_out->color  = 'C710'. " Row Color: C610 -> Red | 'C310' -> Yellow | 'C510' -> Green
      ls_out->statu  = '@01@'.
      ls_out->tlght  = '2'.    " Cell Color: 1 -> Red 2 -> Yellow 3 -> Green
      APPEND VALUE #( fname     = 'VBELN'
                      color-col = '5'
                      color-int = '1'
                      color-inv = '1' ) TO ls_out->cellcolor.
    ENDLOOP.
  ENDMETHOD.

  METHOD show_data.
    CALL SCREEN 0100.
  ENDMETHOD.

  METHOD set_dropdown.
    SELECT zzprint FROM zsm_t_print
      INTO TABLE @DATA(lt_table).

    LOOP AT lt_table INTO DATA(ls_data).
      APPEND VALUE #( handle = '1'
                      value  = ls_data-zzprint ) TO rt_dropdown.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_fieldcatalog.
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING i_bypassing_buffer = abap_true
                i_structure_name   = iv_structure_name
      CHANGING  ct_fieldcat        = rt_fielcat[].

    LOOP AT rt_fielcat REFERENCE INTO DATA(ls_fieldcat).
      CASE ls_fieldcat->fieldname.
        WHEN 'BUTTON'.
          ls_fieldcat->icon      = abap_true.
          ls_fieldcat->scrtext_s = 'Button'.
          ls_fieldcat->style     = cl_gui_alv_grid=>mc_style_button.
        WHEN 'CHBOX'.
          ls_fieldcat->checkbox = abap_true.
          ls_fieldcat->edit     = abap_true.
        WHEN 'DROPDOWN'.
          ls_fieldcat->drdn_hndl = 1.
          ls_fieldcat->edit      = abap_true.
        WHEN 'LFIMG'.
          ls_fieldcat->do_sum  = abap_true.
          ls_fieldcat->edit    = abap_true.
          ls_fieldcat->no_zero = abap_true.
        WHEN 'PSTYV'.
          ls_fieldcat->edit       = abap_true.
          ls_fieldcat->f4availabl = abap_true.
        WHEN 'VBELN'.
          ls_fieldcat->hotspot   = abap_true.
          ls_fieldcat->key       = abap_true.
          ls_fieldcat->ref_table = 'VBAK'.
          ls_fieldcat->ref_field = 'VBELN'.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_filter.
    APPEND VALUE #( fieldname = 'PSTYV'
                    sign      = 'E'
                    option    = 'EQ'
                    low       = 'ZT89' ) TO rt_filter.
  ENDMETHOD.

  METHOD set_layout.
    rs_layout_alv-ctab_fname = 'CELLCOLOR'.   " ALV Cell Color
    rs_layout_alv-cwidth_opt = abap_true.     " Column Width Optimization
    rs_layout_alv-edit       = abap_true.     " All Fields Are Editable
    rs_layout_alv-excp_fname = 'TLGHT'.       " Icon Field
    rs_layout_alv-excp_led   = abap_true.     " Displaying LED Instead Of Traffic Light
    rs_layout_alv-grid_title = TEXT-001.      " ALV Header
    rs_layout_alv-no_headers = abap_true.     " Close Column Header
    rs_layout_alv-no_hgridln = abap_true.     " Remove Row Line
    rs_layout_alv-no_keyfix  = abap_true.     " Fixed Key Fields
    rs_layout_alv-no_rowmark = abap_true.     " Remove Selection Box
    rs_layout_alv-no_toolbar = abap_true.     " Close The Toolbar
    rs_layout_alv-info_fname = 'COLOR'.       " ALV Row Color
    rs_layout_alv-sel_mode   = 'A'.           " Selection mode ('A' -> no_rowmark = abap_false)
    rs_layout_alv-smalltitle = abap_true.     " ALV Header small font
    rs_layout_alv-stylefname = 'FIELD_STYLE'. " Per-cell style, TYPE lvc_t_styl
    rs_layout_alv-zebra      = abap_true.     " Alternating row colors
  ENDMETHOD.
ENDCLASS.
```

## 🎨 Field Catalog — Building It Manually

```abap
DATA: BEGIN OF gt_data OCCURS 0,
        ebeln LIKE ekko~ebeln,
        ebelp LIKE ekpo~ebelp,
      END OF gt_data.

DATA gt_fieldcat      TYPE lvc_t_fcat.
DATA gt_field_catalog TYPE slis_t_fieldcat_alv.
DATA gv_tabname       TYPE slis_tabname DEFAULT 'GT_DATA'.

" Declare field catalog manually
gt_fieldcat = VALUE #( ( col_pos = 1 coltext = 'Text' fieldname = 'SPMON' scrtext_m = abap_true ) ).

" Add another line
DATA(lv_lines) = lines( gt_fieldcat ).
APPEND VALUE #( ( col_pos = lv_lines + 1 coltext = 'Text' fieldname = 'SPMON' scrtext_m = abap_true ) ) TO gt_fieldcat.

" Declare field catalog (SLIS, function-module style) with various options
gt_field_catalog = VALUE #( ( col_pos   = 1
                              do_sum    = abap_true
                              edit      = abap_true
                              fieldname = 'SPMON'
                              hotspot   = abap_true
                              key       = abap_true
                              outputlen = 100
                              seltext_s = 'Small'
                              seltext_m = 'Medium'
                              seltext_l = 'Large' ) ).

" Reusable macros to tweak an existing field catalog entry
DEFINE checkbox.
  MODIFY gt_fieldcat FROM VALUE #( checkbox = abap_true ) TRANSPORTING checkbox WHERE fieldname = &1.
END-OF-DEFINITION.

DEFINE assign_key.
  MODIFY gt_fieldcat FROM VALUE #( key = abap_true ) TRANSPORTING key WHERE fieldname = &1.
END-OF-DEFINITION.

DEFINE change_color.
  MODIFY gt_fieldcat FROM VALUE #( emphasize = &2 ) TRANSPORTING emphasize WHERE fieldname = &1.
END-OF-DEFINITION.

DEFINE change_text.
  MODIFY gt_fieldcat FROM VALUE #( seltext_s    = &1
                                   seltext_m    = &1
                                   seltext_l    = &1
                                   reptext_ddic = &1
                                   ddictxt      = 'M' ) TRANSPORTING seltext_s seltext_m seltext_l reptext_ddic ddictxt WHERE fieldname = &2.
END-OF-DEFINITION.

DEFINE clear_key.
  MODIFY gt_fieldcat FROM VALUE #( key = abap_false ) TRANSPORTING key WHERE fieldname = &1.
END-OF-DEFINITION.

DEFINE remove_output.
  MODIFY gt_fieldcat FROM VALUE #( no_out = abap_true ) TRANSPORTING no_out WHERE fieldname = &1.
END-OF-DEFINITION.

" Example usage
change_color 'BUKRS' 'C610'.
change_text TEXT-a01 'BUKRS'.
clear_key 'BUKRS'.

" Or generate the field catalog automatically from a DDIC structure/internal table
CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING i_program_name     = sy-repid
            i_internal_tabname = gv_tabname
            i_inclname         = sy-repid
  CHANGING  ct_fieldcat        = gt_field_catalog.
```

## 🎛️ Layout — LVC vs. SLIS

```abap
" LVC layout (used with cl_gui_alv_grid and REUSE_ALV_GRID_DISPLAY)
DATA gs_layout_lvc TYPE lvc_s_layo.

gs_layout_lvc = VALUE #( ctab_fname = 'CELLCOLOR' " ALV cell color
                         cwidth_opt = abap_true   " Optimize column width
                         edit       = abap_true   " All fields editable
                         excp_fname = 'TLGHT'     " Icon/exception field
                         excp_led   = abap_true   " Show LED instead of traffic light
                         grid_title = TEXT-001    " ALV header
                         no_headers = abap_true   " Hide column headers
                         no_hgridln = abap_true   " Remove horizontal grid lines
                         no_keyfix  = abap_true   " Don't fix key columns
                         no_rowmark = abap_true   " Remove selection checkbox column
                         no_toolbar = abap_true   " Hide toolbar
                         info_fname = 'COLOR'     " ALV row color
                         sel_mode   = 'A'         " Selection mode
                         smalltitle = abap_true   " Smaller header font
                         zebra      = abap_true ). " Alternating row shading

" SLIS layout (used with REUSE_ALV_LIST_DISPLAY / classic list-based ALV)
DATA gs_layout_slis TYPE slis_layout_alv.

gs_layout_slis = VALUE #( box_fieldname     = 'SELKZ'
                          edit              = abap_true
                          coltab_fieldname  = 'CELL_COLOR'
                          colwidth_optimize = abap_true ).
```

## 🧰 Toolbar Customization

```abap
" Exclude specific standard buttons from the ALV toolbar
DATA(lt_ucomm) = VALUE string_table( ( '&REFR' ) ( '&DEGISIM' ) ).
```

## ✅ Best Practices

- Use `cl_salv_table` for straightforward display-only reports — much less boilerplate than the classic function-module or OOP grid approaches.
- Use `cl_gui_alv_grid` when you need editable cells, custom toolbar buttons, hotspots, or fine-grained event handling.
- Always generate the field catalog from the DDIC structure (`LVC_FIELDCATALOG_MERGE`/`REUSE_ALV_FIELDCATALOG_MERGE`) when possible, then tweak only the fields that need customization — don't build it 100% manually unless there's no underlying DDIC structure.
- Use `refresh_table_display( is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) )` after modifying displayed data to keep scroll position and selection stable.

## ⚠️ Common Mistakes

- Forgetting to register edit events (`register_edit_event`) before expecting `data_changed`/`data_changed_finished` events to fire on an editable grid.
- Not handling `sy-subrc` after `set_table_for_first_display`.
- Rebuilding the whole field catalog manually when `LVC_FIELDCATALOG_MERGE` could generate 90% of it automatically.
- Using color codes (`C310`, `C610`, etc.) without a documented legend — always comment what each color means (as in the examples above).

## 🎤 Interview Tips

- Explain the difference between `cl_salv_table`, `REUSE_ALV_GRID_DISPLAY`, and `cl_gui_alv_grid`, and when to use each.
- Be ready to explain how to make an ALV Grid cell editable and how to react to data changes (`data_changed`/`data_changed_finished` events).
- Explain what a field catalog is and how `LVC_FIELDCATALOG_MERGE` helps generate one automatically.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE38 / SE80 | Create/test ALV report programs |
| SLG1 | Application log (for logging ALV data issues) |

## 🔗 Related Chapters

- [11-Classical-Reports](../11-Classical-Reports/README.md) — dynamic field catalogs/tables
- [07-Internal-Tables](../07-Internal-Tables/README.md)
- [10-Objects](../10-Objects/README.md)
