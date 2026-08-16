# 13 — ALV (ABAP List Viewer)

## 📖 Introduction

ALV is the standard SAP grid control for displaying tabular data with sorting, filtering, totals, and export capabilities built in. There are three common ways to build an ALV report, from simplest to most flexible:

| Approach | Class/FM | Complexity | Flexibility | Lifecycle |
|---|---|---|---|---|
| **SALV** (simple API) | `cl_salv_table` | ⭐ Low | ⭐⭐ Medium | `CURRENT / RECOMMENDED` for display-oriented reports |
| **Function-module based** | `REUSE_ALV_GRID_DISPLAY` | ⭐⭐ Medium | ⭐⭐⭐ High (classic events) | `CLASSIC BUT STILL RELEVANT` — very widespread; not for new code |
| **OOP ALV Grid** | `cl_gui_alv_grid` | ⭐⭐⭐ High | ⭐⭐⭐⭐ Highest (full event handling, editable grids) | `CLASSIC BUT STILL RELEVANT` — still the only on-premise option for editable, event-rich grids |

> **All three are SAP GUI technologies** and are outside the ABAP Cloud development model, where the UI layer is Fiori/UI5 over OData. That does not make them obsolete — it makes them on-premise technologies. All three are kept in this chapter deliberately. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

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
    SELECT * FROM mara UP TO 100 ROWS INTO TABLE @lt_data.
  ENDMETHOD.

  METHOD set_column.
    DATA(lo_columns) = lo_alv->get_columns( ).

    " get_column( ) raises CX_SALV_NOT_FOUND for an unknown column name
    TRY.
        lo_columns->get_column( 'MANDT' )->set_visible( abap_false ).

        DATA(lo_matkl) = lo_columns->get_column( 'MATKL' ).
        lo_matkl->set_short_text( 'MatGrp' ).
        lo_matkl->set_medium_text( 'Material Grp' ).
        lo_matkl->set_long_text( 'Material Group' ).

      CATCH cx_salv_not_found INTO DATA(lx_not_found).
        MESSAGE lx_not_found->get_text( ) TYPE 'S' DISPLAY LIKE 'W'.
    ENDTRY.

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
    " Everything that depends on lo_alv must stay INSIDE the TRY - if factory( )
    " raises, lo_alv is still initial and calling display( ) on it would dump.
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                                CHANGING  t_table      = lt_data ).

        set_column( ).
        set_display( ).
        set_header( ).
        set_toolbar( ).

        lo_alv->display( ).

      CATCH cx_salv_msg INTO DATA(lx_msg).
        MESSAGE lx_msg->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
```

## 🟡 Option 2 — Function-Module Based ALV (`REUSE_ALV_GRID_DISPLAY`)

The classic function-module approach, still very common in existing systems, offering full control over field catalog, layout, sort, filter, and events via callback forms.

> ⚠️ **SLIS and LVC are two different type families and they are not interchangeable.**
> `REUSE_ALV_*` uses the **SLIS** types (`slis_t_fieldcat_alv`, `slis_layout_alv`, `slis_t_sortinfo_alv`, …).
> `cl_gui_alv_grid` uses the **LVC** types (`lvc_t_fcat`, `lvc_s_layo`, `lvc_t_sort`, …).
> Mixing them is one of the most common compile errors in ALV code. This section uses SLIS throughout; [Option 3](#-option-3--oop-alv-grid-cl_gui_alv_grid--full-interactive-control) uses LVC throughout.

```abap
DATA gs_layout          TYPE slis_layout_alv.
DATA gs_print           TYPE slis_print_alv.
DATA gs_variant         TYPE disvariant.
DATA gt_bseg            TYPE TABLE OF bseg.
DATA gt_excluding       TYPE slis_t_extab.
DATA gt_events          TYPE slis_t_event.
DATA gt_fieldcat        TYPE slis_t_fieldcat_alv.
DATA gt_filter          TYPE slis_t_filter_alv.
DATA gt_list_commentary TYPE slis_t_listheader.
DATA gt_sort            TYPE slis_t_sortinfo_alv.
DATA gv_exit            TYPE char1.
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

" F4 help on the layout parameter - this event ONLY supplies a value.
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

" Data retrieval and display belong in the main processing block,
" NOT in the F4 handler above.
START-OF-SELECTION.
  PERFORM get_data.

END-OF-SELECTION.
  " Generate a field catalog automatically from a DDIC structure
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING  i_program_name         = sy-repid
               i_structure_name       = 'BSEG'
               i_client_never_display = abap_true
               i_inclname             = sy-repid
    CHANGING   ct_fieldcat            = gt_fieldcat
    EXCEPTIONS inconsistent_interface = 1
               program_error          = 2
               OTHERS                 = 3.

  IF sy-subrc <> 0.
    MESSAGE 'Could not build the field catalog' TYPE 'E'.
  ENDIF.

  PERFORM set_sort.
  PERFORM set_filter.
  PERFORM set_events.
  PERFORM set_excluding.

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
               it_fieldcat             = gt_fieldcat
               it_filter               = gt_filter
               it_sort                 = gt_sort
    TABLES     t_outtab                = gt_bseg
    EXCEPTIONS program_error           = 1
               OTHERS                  = 2.

  IF sy-subrc <> 0.
    MESSAGE 'ALV display failed' TYPE 'E'.
  ENDIF.

FORM set_color.
  LOOP AT gt_out ASSIGNING FIELD-SYMBOL(<fs_table>).
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
  " CLEAR first - this callback runs once per page, so without it the
  " commentary table grows on every page.
  CLEAR gt_list_commentary.

  APPEND VALUE #( typ  = 'H'
                  info = 'PO Report' ) TO gt_list_commentary.
  APPEND VALUE #( typ  = 'S'
                  key  = 'Date'
                  info = |{ sy-datum DATE = USER }| ) TO gt_list_commentary.
  APPEND VALUE #( typ  = 'A'
                  key  = 'Row count:'
                  info = |{ lines( gt_bseg ) }| ) TO gt_list_commentary.

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

" Event handlers are declared as INSTANCE methods (METHODS, not CLASS-METHODS)
" so they can be registered with SET HANDLER go_main->... FOR co_grid.
" A static handler would have to be registered as SET HANDLER lcl_main=>... .
CLASS lcl_main DEFINITION.
  PUBLIC SECTION.
    METHODS start_of_selection.

    METHODS show_alv IMPORTING iv_container_name TYPE char50
                               iv_structure_name TYPE dd02l-tabname
                     CHANGING  co_container      TYPE REF TO cl_gui_custom_container
                               co_grid           TYPE REF TO cl_gui_alv_grid
                               ct_data           TYPE STANDARD TABLE.

    METHODS handle_after_user_command    FOR EVENT after_user_command    OF cl_gui_alv_grid IMPORTING e_ucomm e_saved e_not_processed.
    METHODS handle_button_click          FOR EVENT button_click          OF cl_gui_alv_grid IMPORTING es_col_id es_row_no.
    METHODS handle_context_menu_request  FOR EVENT context_menu_request  OF cl_gui_alv_grid IMPORTING e_object.
    METHODS handle_data_changed          FOR EVENT data_changed          OF cl_gui_alv_grid IMPORTING er_data_changed e_onf4 e_onf4_before e_onf4_after e_ucomm.
    METHODS handle_data_changed_finished FOR EVENT data_changed_finished OF cl_gui_alv_grid IMPORTING sender e_modified.
    METHODS handle_double_click          FOR EVENT double_click          OF cl_gui_alv_grid IMPORTING e_row e_column es_row_no.
    METHODS handle_hotspot_click         FOR EVENT hotspot_click         OF cl_gui_alv_grid IMPORTING e_row_id e_column_id es_row_no.
    METHODS handle_menu_button           FOR EVENT menu_button           OF cl_gui_alv_grid IMPORTING e_object e_ucomm.
    METHODS handle_on_f1                 FOR EVENT onf1                  OF cl_gui_alv_grid IMPORTING e_fieldname es_row_no er_event_data.
    METHODS handle_on_f4                 FOR EVENT onf4                  OF cl_gui_alv_grid IMPORTING e_fieldname e_fieldvalue es_row_no er_event_data et_bad_cells e_display.
    METHODS handle_toolbar               FOR EVENT toolbar               OF cl_gui_alv_grid IMPORTING sender e_object e_interactive.
    METHODS handle_top_of_page           FOR EVENT top_of_page           OF cl_gui_alv_grid IMPORTING e_dyndoc_id table_index.
    METHODS handle_user_command          FOR EVENT user_command          OF cl_gui_alv_grid IMPORTING e_ucomm.

  PRIVATE SECTION.
    METHODS get_data.
    METHODS show_data.
    METHODS set_dropdown RETURNING VALUE(rt_dropdown) TYPE lvc_t_drop.

    METHODS set_fieldcatalog IMPORTING VALUE(iv_structure_name) TYPE dd02l-tabname
                             RETURNING VALUE(rt_fieldcat)       TYPE lvc_t_fcat.

    METHODS set_filter     RETURNING VALUE(rt_filter)     TYPE lvc_t_filt.
    METHODS set_layout     RETURNING VALUE(rs_layout_alv) TYPE lvc_s_layo.
    METHODS set_sort       RETURNING VALUE(rt_sort)       TYPE lvc_t_sort.
    METHODS set_variant    RETURNING VALUE(rs_variant)    TYPE disvariant.
    METHODS set_toolbar_ex CHANGING  VALUE(ct_toolbar_ex) TYPE ui_functions.
ENDCLASS.


CLASS lcl_main IMPLEMENTATION.
  METHOD start_of_selection.
    get_data( ).

    IF gt_out IS INITIAL.
      MESSAGE 'No records found.' TYPE 'S' DISPLAY LIKE 'E'.
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

        " Alternative (choose ONE): full-screen grid, no container needed.
        " Creating the grid twice would leak the first instance.
        " co_grid = NEW #( i_parent = cl_gui_container=>screen0 ).

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

    CASE e_ucomm.
      WHEN 'DELETE'.
        " Authorization is checked HERE, at the point that actually performs
        " the action - before_user_command cannot cancel the command.
        AUTHORITY-CHECK OBJECT 'ZSM_ALV'
                        ID 'ACTVT' FIELD '06'.       " 06 = delete
        IF sy-subrc <> 0.
          MESSAGE 'You are not authorized to delete rows.' TYPE 'E'.
        ENDIF.

        " Delete by DESCENDING index. Deleting ascending shifts every later
        " index by one and removes the wrong rows on a multi-row selection.
        SORT lt_selected BY row_id DESCENDING.

        LOOP AT lt_selected INTO DATA(ls_selected).
          DELETE gt_out INDEX ls_selected-row_id.
        ENDLOOP.

      WHEN 'EDIT'.
        LOOP AT lt_selected INTO ls_selected.
          READ TABLE gt_out ASSIGNING FIELD-SYMBOL(<ls_edit>) INDEX ls_selected-row_id.
          IF sy-subrc = 0.
            <ls_edit>-pstyv = 'ZTAN'.
          ENDIF.
        ENDLOOP.

      WHEN OTHERS.
        MESSAGE 'Unknown command' TYPE 'I'.
        RETURN.
    ENDCASE.

    go_grid->refresh_table_display( ).
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
    " e_object is a CL_CTMENU. Build the menu with its documented API:
    " add_function( ) / add_separator( ) / add_submenu( ).
    e_object->add_function( fcode = 'DELETE'
                            text  = 'Delete Row' ).
    e_object->add_function( fcode = 'EDIT'
                            text  = 'Edit Row' ).
    e_object->add_separator( ).
    e_object->add_function( fcode = 'DISPLAY'
                            text  = 'Display Details' ).
  ENDMETHOD.

  METHOD handle_data_changed.
    LOOP AT er_data_changed->mt_good_cells REFERENCE INTO DATA(lr_cell).
      CASE lr_cell->fieldname.
        WHEN 'CHBOX'.
          MESSAGE s001(zsm_msg) WITH lr_cell->row_id lr_cell->value.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD handle_data_changed_finished.
    CHECK e_modified IS NOT INITIAL.

    IF sender <> go_grid.
      RETURN.
    ENDIF.

    go_grid->get_current_cell( IMPORTING es_col_id = DATA(ls_current_col_id)
                                         es_row_no = DATA(ls_current_row_no) ).

    " es_col_id is a STRUCTURE (lvc_s_col) - compare its FIELDNAME component,
    " not the structure itself.
    CASE ls_current_col_id-fieldname.
      WHEN 'LFIMG'.
        " ASSIGN is the one place where a table expression sets sy-subrc
        " instead of raising CX_SY_ITAB_LINE_NOT_FOUND.
        ASSIGN gt_out[ ls_current_row_no-row_id ] TO FIELD-SYMBOL(<ls_out>).
        IF sy-subrc = 0.
          <ls_out>-color = 'C610'.
        ENDIF.
    ENDCASE.

    go_grid->refresh_table_display( is_stable      = VALUE lvc_s_stbl( col = abap_true
                                                                       row = abap_true )
                                    i_soft_refresh = abap_true ).
  ENDMETHOD.

  METHOD handle_hotspot_click.
    READ TABLE gt_out REFERENCE INTO DATA(lr_out) INDEX es_row_no-row_id.
    IF sy-subrc = 0 AND e_column_id-fieldname = 'VBELN'.
      SET PARAMETER ID 'VL' FIELD lr_out->vbeln.

      " Make the authorization decision explicit when navigating to a transaction
      TRY.
          CALL TRANSACTION 'VL03N' WITH AUTHORITY-CHECK AND SKIP FIRST SCREEN.
        CATCH cx_sy_authorization_error INTO DATA(lx_auth).
          MESSAGE lx_auth->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
      ENDTRY.
    ENDIF.
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

    lt_value_tab = VALUE #( ( pstyv = 'ZTAN' )
                            ( pstyv = 'ZTAX' )
                            ( pstyv = 'ZTAD' ) ).

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
    CHECK sender = go_grid.

    APPEND VALUE #( function  = 'SEL_ALL'
                    quickinfo = TEXT-101
                    text      = TEXT-101
                    icon      = icon_select_all ) TO e_object->mt_toolbar.
    APPEND VALUE #( function  = 'ADD_LINE'
                    quickinfo = TEXT-102
                    text      = TEXT-102
                    icon      = icon_insert_row ) TO e_object->mt_toolbar.
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
    " gt_out is TYPE TABLE OF zsm_t_table, a custom structure that carries both
    " the business fields and the ALV control columns (BUTTON, COLOR, STATU,
    " TLGHT, CELLCOLOR). Select only the columns you actually display.
    SELECT vbeln, posnr, matnr, pstyv, lfimg, vrkme
      FROM lips
      UP TO 20 ROWS
      INTO CORRESPONDING FIELDS OF TABLE @gt_out.

    LOOP AT gt_out REFERENCE INTO DATA(lr_out) WHERE pstyv = 'ZTAN'.
      lr_out->button = 'C710'.
      lr_out->color  = 'C710'. " Row color:  C610 red | C310 yellow | C510 green
      lr_out->statu  = '@01@'.
      lr_out->tlght  = '2'.    " Traffic light: 1 red | 2 yellow | 3 green
      APPEND VALUE #( fname     = 'VBELN'
                      color-col = '5'
                      color-int = '1'
                      color-inv = '1' ) TO lr_out->cellcolor.
    ENDLOOP.
  ENDMETHOD.

  METHOD show_data.
    CALL SCREEN 0100.
  ENDMETHOD.

  METHOD set_dropdown.
    SELECT print_option
      FROM zsm_t_print
      WHERE active = @abap_true
      INTO TABLE @DATA(lt_options).

    LOOP AT lt_options INTO DATA(ls_option).
      APPEND VALUE #( handle = '1'
                      value  = ls_option-print_option ) TO rt_dropdown.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_fieldcatalog.
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING i_bypassing_buffer = abap_true
                i_structure_name   = iv_structure_name
      CHANGING  ct_fieldcat        = rt_fieldcat.

    LOOP AT rt_fieldcat REFERENCE INTO DATA(lr_fieldcat).
      CASE lr_fieldcat->fieldname.
        WHEN 'BUTTON'.
          lr_fieldcat->icon      = abap_true.
          lr_fieldcat->scrtext_s = 'Button'.
          lr_fieldcat->style     = cl_gui_alv_grid=>mc_style_button.
        WHEN 'CHBOX'.
          lr_fieldcat->checkbox = abap_true.
          lr_fieldcat->edit     = abap_true.
        WHEN 'DROPDOWN'.
          lr_fieldcat->drdn_hndl = 1.
          lr_fieldcat->edit      = abap_true.
        WHEN 'LFIMG'.
          lr_fieldcat->do_sum  = abap_true.
          lr_fieldcat->edit    = abap_true.
          lr_fieldcat->no_zero = abap_true.
        WHEN 'PSTYV'.
          lr_fieldcat->edit       = abap_true.
          lr_fieldcat->f4availabl = abap_true.
        WHEN 'VBELN'.
          lr_fieldcat->hotspot   = abap_true.
          lr_fieldcat->key       = abap_true.
          lr_fieldcat->ref_table = 'VBAK'.
          lr_fieldcat->ref_field = 'VBELN'.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_filter.
    APPEND VALUE #( fieldname = 'PSTYV'
                    sign      = 'E'
                    option    = 'EQ'
                    low       = 'ZTAD' ) TO rt_filter.
  ENDMETHOD.

  METHOD set_layout.
    " Settings actually used by THIS grid (editable, multi-select, coloured).
    rs_layout_alv-ctab_fname = 'CELLCOLOR'.   " cell colour column, TYPE lvc_t_scol
    rs_layout_alv-info_fname = 'COLOR'.       " row colour column
    rs_layout_alv-stylefname = 'FIELD_STYLE'. " per-cell style, TYPE lvc_t_styl
    rs_layout_alv-excp_fname = 'TLGHT'.       " traffic-light column
    rs_layout_alv-excp_led   = abap_true.     " show an LED instead of a traffic light
    rs_layout_alv-cwidth_opt = abap_true.     " optimise column width
    rs_layout_alv-grid_title = TEXT-001.      " grid header
    rs_layout_alv-smalltitle = abap_true.     " smaller header font
    rs_layout_alv-sel_mode   = 'A'.           " multiple row selection
    rs_layout_alv-zebra      = abap_true.     " alternating row shading

    " The options below are DELIBERATELY NOT SET here - each one contradicts
    " something this grid needs. Enable them only in a grid that does not:
    "   no_rowmark = abap_true   " removes the selection column - conflicts with sel_mode 'A'
    "   no_toolbar = abap_true   " hides the toolbar - conflicts with handle_toolbar
    "   no_headers = abap_true   " hides column headers
    "   no_hgridln = abap_true   " removes horizontal grid lines
    "   no_keyfix  = abap_true   " stops key columns being fixed on the left
    "   edit       = abap_true   " makes EVERY field editable; prefer per-field
    "                            " fieldcat-edit as set_fieldcatalog( ) does
  ENDMETHOD.
ENDCLASS.
```

## 🎨 Field Catalog — Building It Manually

```abap
" TYPES declares a type; the internal table is then declared from it.
" (An older form, DATA BEGIN OF ... OCCURS 0, creates a table WITH A HEADER
"  LINE - see the lifecycle note below.)
TYPES: BEGIN OF ty_data,
         ebeln TYPE ekko-ebeln,   " note: '-' , not '~'. The tilde is the
         ebelp TYPE ekpo-ebelp,   " ABAP SQL component separator.
       END OF ty_data.

DATA gt_data          TYPE STANDARD TABLE OF ty_data WITH EMPTY KEY.
DATA gt_fieldcat      TYPE lvc_t_fcat.
DATA gt_field_catalog TYPE slis_t_fieldcat_alv.
DATA gv_tabname       TYPE slis_tabname VALUE 'GT_DATA'.

" Declare an LVC field catalog manually
gt_fieldcat = VALUE #( ( col_pos   = 1
                         fieldname = 'EBELN'
                         coltext   = 'PO Number'
                         scrtext_m = 'PO Number' ) ).

" Append ANOTHER ROW. Note the single set of parentheses: APPEND VALUE #( ( ... ) )
" would build a TABLE and try to append it as one row.
APPEND VALUE #( col_pos   = lines( gt_fieldcat ) + 1
                fieldname = 'EBELP'
                coltext   = 'Item'
                scrtext_m = 'Item' ) TO gt_fieldcat.

" Declare an SLIS field catalog (function-module style) with various options
gt_field_catalog = VALUE #( ( col_pos   = 1
                              do_sum    = abap_true
                              edit      = abap_true
                              fieldname = 'EBELP'
                              hotspot   = abap_true
                              key       = abap_true
                              outputlen = 10
                              seltext_s = 'Item'
                              seltext_m = 'PO Item'
                              seltext_l = 'Purchase Order Item' ) ).

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
change_text TEXT-A01 'BUKRS'.
clear_key 'BUKRS'.

" Or generate the field catalog automatically from a DDIC structure/internal table
CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING i_program_name     = sy-repid
            i_internal_tabname = gv_tabname
            i_inclname         = sy-repid
  CHANGING  ct_fieldcat        = gt_field_catalog.
```

> **Lifecycle:** the macros above are `LEGACY / HISTORICAL REFERENCE`. They are shown because you will find exactly this pattern in existing ALV reports, and reading it is a real skill. For new code prefer a small private method per adjustment — macros bypass type checking and cannot be debugged line by line. See [09-Modularization](../09-Modularization/README.md#-macros-define--end-of-definition).

## 🎛️ Layout — LVC vs. SLIS

The two layout structures are **not interchangeable**: `lvc_s_layo` goes with `cl_gui_alv_grid`, `slis_layout_alv` goes with the `REUSE_ALV_*` function modules. Their component names differ too (`cwidth_opt` vs. `colwidth_optimize`, `ctab_fname` vs. `coltab_fieldname`).

```abap
" LVC layout - used with cl_gui_alv_grid
DATA gs_layout_lvc TYPE lvc_s_layo.

gs_layout_lvc = VALUE #( ctab_fname = 'CELLCOLOR'  " cell colour column
                         info_fname = 'COLOR'      " row colour column
                         excp_fname = 'TLGHT'      " traffic-light column
                         excp_led   = abap_true    " LED instead of traffic light
                         cwidth_opt = abap_true    " optimise column width
                         grid_title = TEXT-001     " grid header
                         smalltitle = abap_true    " smaller header font
                         sel_mode   = 'A'          " multiple row selection
                         zebra      = abap_true ). " alternating row shading

" SLIS layout - used with REUSE_ALV_GRID_DISPLAY / REUSE_ALV_LIST_DISPLAY
DATA gs_layout_slis TYPE slis_layout_alv.

gs_layout_slis = VALUE #( box_fieldname     = 'SELKZ'
                          coltab_fieldname  = 'CELL_COLOR'
                          colwidth_optimize = abap_true ).
```

## 🧰 Toolbar Customization

```abap
" Exclude specific standard buttons from the grid toolbar.
" The excluding table is TYPE ui_functions (a table of ui_func), not a
" string table - it is passed to it_toolbar_excluding.
DATA lt_toolbar_ex TYPE ui_functions.

lt_toolbar_ex = VALUE #( ( cl_gui_alv_grid=>mc_fc_refresh )
                         ( cl_gui_alv_grid=>mc_fc_loc_delete_row )
                         ( cl_gui_alv_grid=>mc_fc_loc_insert_row ) ).
```

## ✅ Best Practices

- Use `cl_salv_table` for straightforward display-only reports — much less boilerplate than the classic function-module or OOP grid approaches.
- Use `cl_gui_alv_grid` when you need editable cells, custom toolbar buttons, hotspots, or fine-grained event handling.
- **Keep the SLIS and LVC type families apart.** `REUSE_ALV_*` takes `slis_*`; `cl_gui_alv_grid` takes `lvc_*`.
- Always generate the field catalog from the DDIC structure (`LVC_FIELDCATALOG_MERGE` / `REUSE_ALV_FIELDCATALOG_MERGE`) when possible, then tweak only the fields that need customization.
- Use `refresh_table_display( is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) )` after modifying displayed data to keep scroll position and selection stable.
- **Delete selected rows in descending index order**, or the indexes shift under you.
- Register event handlers consistently: instance handlers with `SET HANDLER obj->handler`, static handlers with `SET HANDLER class=>handler`.

## ⚠️ Common Mistakes

- Forgetting to register edit events (`register_edit_event`) before expecting `data_changed`/`data_changed_finished` events to fire on an editable grid.
- Mixing `lvc_*` and `slis_*` types between the two ALV families.
- **Registering a static handler with an instance reference** (`SET HANDLER go_main->static_method`) — this does not compile.
- **Deleting multiple selected rows by ascending index**, which removes the wrong rows after the first deletion.
- Comparing a structure (`es_col_id`) to a literal instead of its `-fieldname` component.
- Calling `lo_alv->display( )` outside the `TRY` that created the object — if the factory raised, the reference is initial.
- Setting contradictory layout options (`no_rowmark` together with `sel_mode = 'A'`, or `no_toolbar` in a grid that adds toolbar buttons).
- Not handling `sy-subrc` after `set_table_for_first_display`.
- Using color codes (`C310`, `C610`, …) without a documented legend.

## 🎤 Interview & Review Checkpoints

- Explain the difference between `cl_salv_table`, `REUSE_ALV_GRID_DISPLAY`, and `cl_gui_alv_grid`, and when to use each.
- Explain the difference between the LVC and SLIS type families and why they cannot be mixed.
- Be ready to explain how to make an ALV Grid cell editable and how to react to data changes (`data_changed` / `data_changed_finished`).
- Explain what a field catalog is and how `LVC_FIELDCATALOG_MERGE` helps generate one automatically.
- Explain why multi-row deletion must run in descending index order.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE38 / SE80 | Create/test ALV report programs |
| SE51 | Screen Painter — the dynpro and custom container that host the grid |
| SLG1 | Application log (for logging ALV data issues) |

## 🔗 Related Chapters

- [11-Classical-Reports](../11-Classical-Reports/README.md) — dynamic field catalogs/tables
- [07-Internal-Tables](../07-Internal-Tables/README.md)
- [10-Objects](../10-Objects/README.md)
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — where the three ALV generations sit
