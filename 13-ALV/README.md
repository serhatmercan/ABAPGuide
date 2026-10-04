# 13 — ALV (ABAP List Viewer)

## 📖 Introduction

ALV is the standard SAP grid control for displaying tabular data with sorting, filtering, totals, and export capabilities built in. There are three common ways to build an ALV report, from simplest to most flexible:

| Approach | Class/FM | Complexity | Flexibility | Lifecycle |
|---|---|---|---|---|
| **SALV** (simple API) | `cl_salv_table` | ⭐ Low | ⭐⭐ Medium | `CURRENT / RECOMMENDED` for display-oriented reports |
| **Function-module based** | `REUSE_ALV_GRID_DISPLAY` | ⭐⭐ Medium | ⭐⭐⭐ High (classic events) | `CLASSIC BUT STILL RELEVANT` — very widespread; not for new code |
| **OOP ALV Grid** | `cl_gui_alv_grid` | ⭐⭐⭐ High | ⭐⭐⭐⭐ Highest (full event handling, editable grids) | `CLASSIC BUT STILL RELEVANT` — still the only on-premise option for editable, event-rich grids |

> **All three are SAP GUI technologies** and are outside the ABAP Cloud development model, where the UI layer is Fiori/UI5 over OData. That does not make them obsolete — it makes them on-premise technologies. All three are kept in this chapter deliberately. Whether they are released for ABAP for Cloud Development is a separate question: `CL_GUI_ALV_GRID` and `CL_SALV_TABLE` are not in the documentation's list of released APIs. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-what-changes-under-abap-cloud).

The examples use text symbols for user-facing texts and the placeholder message class `zsm_msg` ([Rule 4.2](../docs/ABAP-Development-Rules.md#42-keep-user-facing-text-out-of-literals)). Text symbols passed to a parameter with a complete type are converted with `CONV #( )`, because that parameter expects its own length; a generic parameter (`TYPE any`) takes the text symbol as it is.

## 🟢 Option 1 — `cl_salv_table` (Simple ALV / SALV)

The quickest way to display a table, with a clean object-oriented API. Best for simple, read-mostly reports.

> 📝 Complete program; the text symbols `c01`–`c03` and `h01`–`h03` hold the column and header texts.

```abap
REPORT zsm_r_material_list.

CLASS lcl_alv DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS get_data.
    METHODS show_data.

  PRIVATE SECTION.
    TYPES: BEGIN OF material,
             matnr TYPE mara-matnr,
             mtart TYPE mara-mtart,
             matkl TYPE mara-matkl,
             meins TYPE mara-meins,
           END OF material.

    DATA materials TYPE STANDARD TABLE OF material WITH EMPTY KEY.
    DATA alv       TYPE REF TO cl_salv_table.

    METHODS set_column.
    METHODS set_display.
    METHODS set_header.
    METHODS set_toolbar.
ENDCLASS.


CLASS lcl_alv IMPLEMENTATION.
  METHOD get_data.
    " >>> Authorization check for the material types read here belongs here.
    SELECT matnr, mtart, matkl, meins
      FROM mara
      ORDER BY matnr
      INTO TABLE @materials
      UP TO 100 ROWS.
  ENDMETHOD.

  METHOD set_column.
    DATA(columns) = alv->get_columns( ).

    " get_column( ) raises CX_SALV_NOT_FOUND for an unknown column name
    TRY.
        columns->get_column( 'MEINS' )->set_visible( abap_false ).

        DATA(material_group_column) = columns->get_column( 'MATKL' ).
        material_group_column->set_short_text( CONV #( TEXT-c01 ) ).
        material_group_column->set_medium_text( CONV #( TEXT-c02 ) ).
        material_group_column->set_long_text( CONV #( TEXT-c03 ) ).

      CATCH cx_salv_not_found INTO DATA(not_found_error).
        MESSAGE not_found_error->get_text( ) TYPE 'S' DISPLAY LIKE 'W'.
    ENDTRY.

    columns->set_optimize( abap_true ).
  ENDMETHOD.

  METHOD set_display.
    DATA(display_settings) = alv->get_display_settings( ).

    display_settings->set_list_header( CONV #( TEXT-h01 ) ).
    display_settings->set_striped_pattern( abap_true ).
  ENDMETHOD.

  METHOD set_header.
    DATA(header) = NEW cl_salv_form_layout_grid( ).

    header->create_label( row    = 1
                          column = 1 )->set_text( TEXT-h02 ).
    header->create_flow( row    = 2
                         column = 1 )->create_text( text = TEXT-h03 ).

    alv->set_top_of_list( header ).
  ENDMETHOD.

  METHOD set_toolbar.
    DATA(functions) = alv->get_functions( ).

    functions->set_all( abap_true ).
    functions->set_sort_asc( abap_false ).
    functions->set_sort_desc( abap_false ).
  ENDMETHOD.

  METHOD show_data.
    " Everything that depends on alv must stay INSIDE the TRY - if factory( )
    " raises, alv is still initial and calling display( ) on it would dump.
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = alv
                                CHANGING  t_table      = materials ).

        set_column( ).
        set_display( ).
        set_header( ).
        set_toolbar( ).

        alv->display( ).

      CATCH cx_salv_msg INTO DATA(salv_error).
        MESSAGE salv_error->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.


START-OF-SELECTION.
  DATA(material_list) = NEW lcl_alv( ).
  material_list->get_data( ).
  material_list->show_data( ).
```

## 🟡 Option 2 — Function-Module Based ALV (`REUSE_ALV_GRID_DISPLAY`)

The classic function-module approach, still very common in existing systems, offering full control over field catalog, layout, sort, filter, and events via callback forms.

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. The function module calls its callbacks as subroutines by name, so a `REUSE_ALV_*` report keeps `FORM` routines alive; that is one reason new code uses SALV or `cl_gui_alv_grid`. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-classic-but-still-relevant).

> ⚠️ **SLIS and LVC are two different type families and they are not interchangeable.**
> `REUSE_ALV_*` uses the **SLIS** types (`slis_t_fieldcat_alv`, `slis_layout_alv`, `slis_t_sortinfo_alv`, …).
> `cl_gui_alv_grid` uses the **LVC** types (`lvc_t_fcat`, `lvc_s_layo`, `lvc_t_sort`, …).
> Mixing them is one of the most common compile errors in ALV code. This section uses SLIS throughout; [Option 3](#-option-3--oop-alv-grid-cl_gui_alv_grid--full-interactive-control) uses LVC throughout.

> 📝 Complete program apart from its placeholders: the structure `zsm_s_po_item` with `EBELN`, `EBELP`, `BSART`, `MATNR`, `MENGE`, `LINE_COLOR` (`CHAR4`) and `CELL_COLORS` (`SLIS_T_SPECIALCOL_ALV`), the message class `zsm_msg`, and the text symbols `t01`–`t03`. The callbacks are passed through the parameters `i_callback_pf_status_set`, `i_callback_top_of_page` and `i_callback_user_command`; further events go into `it_events`.

```abap
REPORT zsm_r_po_item_list.

DATA purchase_order_id    TYPE ekko-ebeln.
DATA purchase_order_items TYPE STANDARD TABLE OF zsm_s_po_item WITH EMPTY KEY.
DATA layout               TYPE slis_layout_alv.
DATA variant              TYPE disvariant.
DATA excluded_functions   TYPE slis_t_extab.
DATA field_catalog        TYPE slis_t_fieldcat_alv.
DATA filter_criteria      TYPE slis_t_filter_alv.
DATA list_header          TYPE slis_t_listheader.
DATA sort_criteria        TYPE slis_t_sortinfo_alv.
DATA f4_cancelled         TYPE char1.

SELECT-OPTIONS s_ebeln FOR purchase_order_id.
PARAMETERS p_variant TYPE disvariant-variant.

INITIALIZATION.
  variant-report = sy-repid.

  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
    CHANGING   cs_variant    = variant
    EXCEPTIONS wrong_input   = 1
               not_found     = 2
               program_error = 3
               OTHERS        = 4.
  IF sy-subrc = 0.
    p_variant = variant-variant.
  ENDIF.

" F4 help on the layout parameter - this event ONLY supplies a value.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_variant.
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING  is_variant    = variant
    IMPORTING  e_exit        = f4_cancelled
               es_variant    = variant
    EXCEPTIONS not_found     = 1
               program_error = 2
               OTHERS        = 3.
  IF sy-subrc = 0 AND f4_cancelled IS INITIAL.
    p_variant = variant-variant.
  ENDIF.

" Data retrieval and display belong in the main processing block,
" NOT in the F4 handler above.
START-OF-SELECTION.
  " >>> Authorization check for the purchasing documents belongs here.
  SELECT ekko~ebeln, ekpo~ebelp, ekko~bsart, ekpo~matnr, ekpo~menge
    FROM ekko
           INNER JOIN
             ekpo ON ekpo~ebeln = ekko~ebeln
    WHERE ekko~ebeln IN @s_ebeln
    ORDER BY ekko~ebeln, ekpo~ebelp
    INTO CORRESPONDING FIELDS OF TABLE @purchase_order_items
    UP TO 500 ROWS.

  IF purchase_order_items IS INITIAL.
    MESSAGE s030(zsm_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " Colours: the whole line for items without material, one cell otherwise
  LOOP AT purchase_order_items ASSIGNING FIELD-SYMBOL(<item>).
    IF <item>-matnr IS INITIAL.
      <item>-line_color = 'C610'.
    ELSE.
      APPEND VALUE #( fieldname = 'MENGE'
                      color     = VALUE #( col = 5 int = 0 inv = 0 ) ) TO <item>-cell_colors.
    ENDIF.
  ENDLOOP.

  " Generate a field catalog automatically from a DDIC structure
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING  i_program_name         = sy-repid
               i_structure_name       = 'ZSM_S_PO_ITEM'
               i_client_never_display = abap_true
    CHANGING   ct_fieldcat            = field_catalog
    EXCEPTIONS inconsistent_interface = 1
               program_error          = 2
               OTHERS                 = 3.
  IF sy-subrc <> 0.
    MESSAGE e031(zsm_msg).
  ENDIF.

  layout = VALUE #( zebra             = abap_true
                    colwidth_optimize = abap_true
                    info_fieldname    = 'LINE_COLOR'
                    coltab_fieldname  = 'CELL_COLORS' ).

  sort_criteria = VALUE #( ( spos = 1 fieldname = 'BSART' down = abap_true )
                           ( spos = 2 fieldname = 'MENGE' down = abap_true ) ).

  filter_criteria = VALUE #( ( fieldname = 'EBELP'
                               sign0     = 'I'
                               optio     = 'EQ'
                               valuf_int = '20' ) ).

  excluded_functions = VALUE #( ( fcode = '&INFO' ) ).

  variant-variant = p_variant.

  " Callbacks are subroutines of this program, called by name
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING  i_buffer_active          = abap_false
               i_callback_program       = sy-repid
               i_callback_pf_status_set = 'PF_STATUS_SET'
               i_callback_top_of_page   = 'TOP_OF_PAGE'
               i_callback_user_command  = 'USER_COMMAND'
               i_save                   = 'A'
               is_layout                = layout
               is_variant               = variant
               it_excluding             = excluded_functions
               it_fieldcat              = field_catalog
               it_filter                = filter_criteria
               it_sort                  = sort_criteria
    TABLES     t_outtab                 = purchase_order_items
    EXCEPTIONS program_error            = 1
               OTHERS                   = 2.
  IF sy-subrc <> 0.
    MESSAGE e032(zsm_msg).
  ENDIF.

FORM pf_status_set USING excluded TYPE slis_t_extab.
  " A copy of the standard status STANDARD_FULLSCREEN (program SAPLKKBL) [verify];
  " EXCLUDING hides the function codes the grid passes in
  SET PF-STATUS 'STANDARD_FULLSCREEN' EXCLUDING excluded.
ENDFORM.

FORM top_of_page.
  " CLEAR first - this callback runs once per page, so without it the
  " commentary table grows on every page.
  CLEAR list_header.

  APPEND VALUE #( typ  = 'H'
                  info = TEXT-t01 ) TO list_header.
  APPEND VALUE #( typ  = 'S'
                  key  = TEXT-t02
                  info = |{ sy-datum DATE = USER }| ) TO list_header.
  APPEND VALUE #( typ  = 'A'
                  key  = TEXT-t03
                  info = |{ lines( purchase_order_items ) }| ) TO list_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING it_list_commentary = list_header.
ENDFORM.

FORM user_command USING ucomm    TYPE sy-ucomm
                        selfield TYPE slis_selfield.
  " '&IC1' is the double-click or hotspot function code of the ALV [verify]
  IF ucomm = '&IC1' AND selfield-fieldname = 'EBELN'.
    MESSAGE s033(zsm_msg) WITH selfield-value.
  ENDIF.
ENDFORM.
```

## 🔵 Option 3 — OOP ALV Grid (`cl_gui_alv_grid`) — Full Interactive Control

This is the most powerful and flexible approach: a container-based grid with rich event handling (editable cells, hotspots, custom toolbar buttons, F4 help, drag & drop, etc.). Ideal for interactive dynpro-based tools.

The program below is the one whose header and global part [01-ABAP-Basics](../01-ABAP-Basics/README.md#-example--program-header--global-declarations) shows. Every handler it declares is implemented and registered; a handler that is declared but not registered is never called, and a declared method without an implementation does not compile.

> 📝 **Contextual snippet** — assumes screen 0100 with a custom control `GRID_AREA`, the GUI status `STATUS_0100` and the title `TITLE_0100`; the placeholder structure `zsm_s_delivery` with the `LIPS` fields `VBELN`, `POSNR`, `MATNR`, `PSTYV`, `LFIMG`, `VRKME` plus the control columns `BUTTON`, `ROW_COLOR` (`CHAR4`), `STATUS_ICON`, `TRAFFIC_LIGHT`, `SELECTED`, `DROPDOWN`, `CELL_COLORS` (`LVC_T_SCOL`) and `FIELD_STYLE` (`LVC_T_STYL`); the placeholder table `zsm_t_print`; the message class `zsm_msg`; and text symbols for all texts.

```abap
REPORT zsm_r_delivery_monitor.

CLASS lcl_main DEFINITION DEFERRED.

" Dynpro modules are not part of the class; they reach the instance
" only through this one global reference.
DATA main TYPE REF TO lcl_main.

CLASS lcl_main DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS start_of_selection.

    " Called from the PBO module of screen 0100
    METHODS show_alv.

  PRIVATE SECTION.
    DATA custom_container TYPE REF TO cl_gui_custom_container.
    DATA header_document  TYPE REF TO cl_dd_document.
    DATA grid             TYPE REF TO cl_gui_alv_grid.
    DATA splitter         TYPE REF TO cl_gui_splitter_container.
    DATA header_container TYPE REF TO cl_gui_container.
    DATA grid_container   TYPE REF TO cl_gui_container.
    DATA deliveries       TYPE STANDARD TABLE OF zsm_s_delivery WITH EMPTY KEY.

    METHODS get_data.
    METHODS create_grid.
    METHODS refresh_grid.

    METHODS build_dropdown           RETURNING VALUE(result) TYPE lvc_t_drop.
    METHODS build_field_catalog      RETURNING VALUE(result) TYPE lvc_t_fcat.
    METHODS build_filter             RETURNING VALUE(result) TYPE lvc_t_filt.
    METHODS build_layout             RETURNING VALUE(result) TYPE lvc_s_layo.
    METHODS build_sort               RETURNING VALUE(result) TYPE lvc_t_sort.
    METHODS build_toolbar_exclusions RETURNING VALUE(result) TYPE ui_functions.

    " Event handlers are instance methods, registered with SET HANDLER for this grid only.
    " Each one imports only the event parameters it uses.
    METHODS handle_after_user_command    FOR EVENT after_user_command    OF cl_gui_alv_grid IMPORTING e_ucomm.
    METHODS handle_button_click          FOR EVENT button_click          OF cl_gui_alv_grid IMPORTING es_col_id es_row_no.
    METHODS handle_context_menu_request  FOR EVENT context_menu_request  OF cl_gui_alv_grid IMPORTING e_object.
    METHODS handle_data_changed          FOR EVENT data_changed          OF cl_gui_alv_grid IMPORTING er_data_changed.
    METHODS handle_data_changed_finished FOR EVENT data_changed_finished OF cl_gui_alv_grid IMPORTING e_modified.
    METHODS handle_double_click          FOR EVENT double_click          OF cl_gui_alv_grid IMPORTING es_row_no.
    METHODS handle_hotspot_click         FOR EVENT hotspot_click         OF cl_gui_alv_grid IMPORTING e_column_id es_row_no.
    METHODS handle_menu_button           FOR EVENT menu_button           OF cl_gui_alv_grid IMPORTING e_object e_ucomm.
    METHODS handle_on_f1                 FOR EVENT onf1                  OF cl_gui_alv_grid IMPORTING e_fieldname er_event_data.
    METHODS handle_on_f4                 FOR EVENT onf4                  OF cl_gui_alv_grid IMPORTING es_row_no er_event_data e_display.
    METHODS handle_toolbar               FOR EVENT toolbar               OF cl_gui_alv_grid IMPORTING e_object.
    METHODS handle_top_of_page           FOR EVENT top_of_page           OF cl_gui_alv_grid IMPORTING e_dyndoc_id.
    METHODS handle_user_command          FOR EVENT user_command          OF cl_gui_alv_grid IMPORTING e_ucomm.
ENDCLASS.

INITIALIZATION.
  main = NEW #( ).

START-OF-SELECTION.
  main->start_of_selection( ).


CLASS lcl_main IMPLEMENTATION.
  METHOD start_of_selection.
    get_data( ).

    IF deliveries IS INITIAL.
      MESSAGE s040(zsm_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CALL SCREEN 0100.
  ENDMETHOD.

  METHOD show_alv.
    " PBO runs on every screen cycle: create the controls once, refresh afterwards
    IF grid IS BOUND.
      refresh_grid( ).
    ELSE.
      create_grid( ).
    ENDIF.
  ENDMETHOD.

  METHOD create_grid.
    custom_container = NEW #( container_name = 'GRID_AREA' ).

    " Upper row: header document; lower row: the grid
    splitter = NEW #( parent  = custom_container
                      rows    = 2
                      columns = 1 ).
    splitter->set_row_height( id     = 1
                              height = 15 ).
    header_container = splitter->get_container( row    = 1
                                                column = 1 ).
    grid_container   = splitter->get_container( row    = 2
                                                column = 1 ).

    " Alternative without a screen element: i_parent = cl_gui_container=>screen0.
    " Create the grid only once - a second NEW leaks the first instance.
    grid = NEW #( i_parent = grid_container ).

    SET HANDLER handle_after_user_command
                handle_button_click
                handle_context_menu_request
                handle_data_changed
                handle_data_changed_finished
                handle_double_click
                handle_hotspot_click
                handle_menu_button
                handle_on_f1
                handle_on_f4
                handle_toolbar
                handle_top_of_page
                handle_user_command FOR grid.

    grid->set_drop_down_table( it_drop_down = build_dropdown( ) ).

    DATA(field_catalog)   = build_field_catalog( ).
    DATA(sort_criteria)   = build_sort( ).
    DATA(filter_criteria) = build_filter( ).

    grid->set_table_for_first_display(
        EXPORTING  i_buffer_active               = space
                   is_layout                     = build_layout( )
                   it_toolbar_excluding          = build_toolbar_exclusions( )
                   i_save                        = 'U'   " A all | U user-specific | X standard only | space none
                   is_variant                    = VALUE disvariant( report = sy-repid )
                   i_default                     = abap_true
        CHANGING   it_sort                       = sort_criteria
                   it_filter                     = filter_criteria
                   it_outtab                     = deliveries
                   it_fieldcatalog               = field_catalog
        EXCEPTIONS invalid_parameter_combination = 1
                   program_error                 = 2
                   too_many_lines                = 3
                   OTHERS                        = 4 ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    " Which user actions raise data_changed for the editable cells
    grid->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_enter ).
    grid->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_modified ).

    " onf4 is raised only for registered fields
    grid->register_f4_for_fields( it_f4 = VALUE #( ( fieldname = 'PSTYV'
                                                     register  = abap_true ) ) ).

    grid->set_ready_for_input( i_ready_for_input = 1 ).
    grid->set_toolbar_interactive( ).

    " The grid's top_of_page fills a dynamic document in the header area
    header_document = NEW #( ).
    header_document->initialize_document( ).
    grid->list_processing_events( i_event_name = 'TOP_OF_PAGE'
                                  i_dyndoc_id  = header_document ).
  ENDMETHOD.

  METHOD refresh_grid.
    " Keep the scroll position and the selection
    grid->refresh_table_display( is_stable      = VALUE #( row = abap_true
                                                           col = abap_true )
                                 i_soft_refresh = abap_true ).
  ENDMETHOD.

  METHOD handle_toolbar.
    " Custom buttons; their function codes arrive in handle_user_command
    APPEND VALUE #( function  = 'SEL_ALL'
                    quickinfo = TEXT-101
                    text      = TEXT-101
                    icon      = icon_select_all ) TO e_object->mt_toolbar.
    APPEND VALUE #( function  = 'ADD_LINE'
                    quickinfo = TEXT-102
                    text      = TEXT-102
                    icon      = icon_insert_row ) TO e_object->mt_toolbar.
    " butn_type 2 = menu button (domain fixed value); its entries come from handle_menu_button
    APPEND VALUE #( function  = 'EXPORT'
                    text      = TEXT-103
                    butn_type = 2 ) TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD handle_menu_button.
    IF e_ucomm = 'EXPORT'.
      e_object->add_function( fcode = 'EXPORT_CSV'
                              text  = CONV #( TEXT-104 ) ).
    ENDIF.
  ENDMETHOD.

  METHOD handle_context_menu_request.
    " e_object is a CL_CTMENU; its function codes also arrive in handle_user_command
    e_object->add_separator( ).
    e_object->add_function( fcode = 'DELETE'
                            text  = CONV #( TEXT-105 ) ).
    e_object->add_function( fcode = 'DISPLAY'
                            text  = CONV #( TEXT-106 ) ).
  ENDMETHOD.

  METHOD handle_user_command.
    CASE e_ucomm.
      WHEN 'SEL_ALL'.
        LOOP AT deliveries REFERENCE INTO DATA(delivery).
          delivery->selected = abap_true.
        ENDLOOP.

      WHEN 'ADD_LINE'.
        APPEND INITIAL LINE TO deliveries.

      WHEN 'DELETE'.
        grid->get_selected_rows( IMPORTING et_index_rows = DATA(selected_rows) ).
        IF selected_rows IS INITIAL.
          MESSAGE s041(zsm_msg).
          RETURN.
        ENDIF.

        " >>> If the deletion is passed on to the database, the authorization check belongs here.

        " Delete by DESCENDING index. Deleting ascending shifts every later
        " index by one and removes the wrong rows on a multi-row selection.
        SORT selected_rows BY index DESCENDING.

        LOOP AT selected_rows INTO DATA(selected_row).
          DELETE deliveries INDEX selected_row-index.
        ENDLOOP.

      WHEN OTHERS.
        " EXPORT_CSV and DISPLAY are left out here
        RETURN.
    ENDCASE.

    refresh_grid( ).
  ENDMETHOD.

  METHOD handle_after_user_command.
    " Raised after the grid has processed a function code, standard ones included
    IF e_ucomm = cl_gui_alv_grid=>mc_fc_sort_asc OR e_ucomm = cl_gui_alv_grid=>mc_fc_sort_dsc.
      MESSAGE s042(zsm_msg).
    ENDIF.
  ENDMETHOD.

  METHOD handle_button_click.
    IF es_col_id-fieldname = 'BUTTON'.
      DATA(delivery) = VALUE #( deliveries[ es_row_no-row_id ] OPTIONAL ).
      MESSAGE s043(zsm_msg) WITH delivery-vbeln delivery-posnr.
    ENDIF.
  ENDMETHOD.

  METHOD handle_double_click.
    DATA(delivery) = VALUE #( deliveries[ es_row_no-row_id ] OPTIONAL ).
    MESSAGE s044(zsm_msg) WITH delivery-vbeln delivery-posnr delivery-matnr.
  ENDMETHOD.

  METHOD handle_hotspot_click.
    IF e_column_id-fieldname <> 'VBELN'.
      RETURN.
    ENDIF.

    DATA(delivery) = VALUE #( deliveries[ es_row_no-row_id ] OPTIONAL ).
    SET PARAMETER ID 'VL' FIELD delivery-vbeln.

    " Make the authorization decision explicit when navigating to a transaction
    TRY.
        CALL TRANSACTION 'VL03N' WITH AUTHORITY-CHECK AND SKIP FIRST SCREEN.
      CATCH cx_sy_authorization_error INTO DATA(authorization_error).
        MESSAGE authorization_error->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD handle_data_changed.
    " Check edited quantities before they reach the output table
    DATA quantity TYPE lips-lfimg.

    LOOP AT er_data_changed->mt_good_cells INTO DATA(cell) WHERE fieldname = 'LFIMG'.
      er_data_changed->get_cell_value( EXPORTING i_row_id    = cell-row_id
                                                 i_fieldname = cell-fieldname
                                       IMPORTING e_value     = quantity ).
      IF quantity < 0.
        er_data_changed->add_protocol_entry( i_msgid     = 'ZSM_MSG'
                                             i_msgty     = 'E'
                                             i_msgno     = '045'
                                             i_fieldname = cell-fieldname
                                             i_row_id    = cell-row_id ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD handle_data_changed_finished.
    IF e_modified = abap_false.
      RETURN.
    ENDIF.

    grid->get_current_cell( IMPORTING es_col_id = DATA(current_column)
                                      es_row_no = DATA(current_row) ).

    " es_col_id is a STRUCTURE (lvc_s_col) - compare its FIELDNAME component,
    " not the structure itself.
    IF current_column-fieldname = 'LFIMG'.
      " In ASSIGN, a table expression that finds no line sets sy-subrc to 4
      " instead of raising CX_SY_ITAB_LINE_NOT_FOUND.
      ASSIGN deliveries[ current_row-row_id ] TO FIELD-SYMBOL(<changed_row>).
      IF sy-subrc = 0.
        <changed_row>-row_color = 'C610'.
      ENDIF.
      refresh_grid( ).
    ENDIF.
  ENDMETHOD.

  METHOD handle_on_f1.
    " Field help texts come from the message class; other fields keep the standard F1 help
    CASE e_fieldname.
      WHEN 'VBELN'.
        MESSAGE i046(zsm_msg).
      WHEN 'MATNR'.
        MESSAGE i047(zsm_msg).
      WHEN OTHERS.
        RETURN.
    ENDCASE.

    er_event_data->m_event_handled = abap_true.
  ENDMETHOD.

  METHOD handle_on_f4.
    " This handler takes over the F4 help of the registered field
    er_event_data->m_event_handled = abap_true.

    IF e_display = abap_true.
      RETURN.
    ENDIF.

    SELECT pstyv
      FROM tvlp
      ORDER BY pstyv
      INTO TABLE @DATA(item_categories).

    DATA returned_values TYPE STANDARD TABLE OF ddshretval WITH EMPTY KEY.

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'PSTYV'
        value_org       = 'S'
      TABLES
        value_tab       = item_categories
        return_tab      = returned_values
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    IF sy-subrc <> 0 OR returned_values IS INITIAL.
      RETURN.
    ENDIF.

    " Simplified: writes into the output table and refreshes the grid. SAP's
    " ALV demo programs (BCALV_*) show how to return a value to a cell in edit mode
    ASSIGN deliveries[ es_row_no-row_id ] TO FIELD-SYMBOL(<delivery>).
    IF sy-subrc = 0.
      <delivery>-pstyv = returned_values[ 1 ]-fieldval.
      refresh_grid( ).
    ENDIF.
  ENDMETHOD.

  METHOD handle_top_of_page.
    e_dyndoc_id->add_text( text      = CONV #( TEXT-h01 )
                           sap_style = cl_dd_document=>heading ).

    e_dyndoc_id->new_line( ).

    e_dyndoc_id->add_text( text         = CONV #( TEXT-h02 )
                           sap_color    = cl_dd_document=>list_positive
                           sap_fontsize = cl_dd_document=>medium ).

    e_dyndoc_id->display_document( parent = header_container ).
  ENDMETHOD.

  METHOD get_data.
    " >>> Authorization check for the shipping points of the deliveries belongs here.
    SELECT vbeln, posnr, matnr, pstyv, lfimg, vrkme
      FROM lips
      ORDER BY vbeln, posnr
      INTO CORRESPONDING FIELDS OF TABLE @deliveries
      UP TO 20 ROWS.

    " Items without delivery quantity: yellow row, yellow light, highlighted delivery number
    LOOP AT deliveries REFERENCE INTO DATA(delivery) WHERE lfimg IS INITIAL.
      delivery->button        = icon_display.
      delivery->row_color     = 'C310'.   " row colour: C610 red | C310 yellow | C510 green
      delivery->status_icon   = icon_led_yellow.
      delivery->traffic_light = '2'.      " traffic light: 1 red | 2 yellow | 3 green
      APPEND VALUE #( fname     = 'VBELN'
                      color-col = '5'
                      color-int = '1'
                      color-inv = '1' ) TO delivery->cell_colors.
    ENDLOOP.
  ENDMETHOD.

  METHOD build_dropdown.
    " Values for the DROPDOWN column (drdn_hndl = 1) from a placeholder table
    SELECT print_option
      FROM zsm_t_print
      WHERE active = @abap_true
      INTO TABLE @DATA(print_options).

    result = VALUE #( FOR option IN print_options
                      ( handle = 1
                        value  = option-print_option ) ).
  ENDMETHOD.

  METHOD build_field_catalog.
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING  i_bypassing_buffer     = abap_true
                 i_structure_name       = 'ZSM_S_DELIVERY'
      CHANGING   ct_fieldcat            = result
      EXCEPTIONS inconsistent_interface = 1
                 program_error          = 2
                 OTHERS                 = 3.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT result REFERENCE INTO DATA(column).
      CASE column->fieldname.
        WHEN 'BUTTON'.
          column->icon      = abap_true.
          column->scrtext_s = TEXT-c01.
          column->style     = cl_gui_alv_grid=>mc_style_button.
        WHEN 'ROW_COLOR'.
          column->no_out = abap_true.
        WHEN 'SELECTED'.
          column->checkbox = abap_true.
          column->edit     = abap_true.
        WHEN 'DROPDOWN'.
          column->drdn_hndl = 1.
          column->edit      = abap_true.
        WHEN 'LFIMG'.
          column->do_sum  = abap_true.
          column->edit    = abap_true.
          column->no_zero = abap_true.
        WHEN 'PSTYV'.
          column->edit       = abap_true.
          column->f4availabl = abap_true.
        WHEN 'VBELN'.
          column->hotspot   = abap_true.
          column->key       = abap_true.
          column->ref_table = 'LIKP'.
          column->ref_field = 'VBELN'.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD build_filter.
    " Hide items without a material number
    result = VALUE #( ( fieldname = 'MATNR'
                        sign      = 'E'
                        option    = 'EQ'
                        low       = space ) ).
  ENDMETHOD.

  METHOD build_sort.
    result = VALUE #( ( spos = 1 fieldname = 'VBELN' up = abap_true )
                      ( spos = 2 fieldname = 'POSNR' up = abap_true ) ).
  ENDMETHOD.

  METHOD build_layout.
    " Settings actually used by THIS grid (editable, multi-select, coloured).
    result-ctab_fname = 'CELL_COLORS'.   " cell colour column, TYPE lvc_t_scol
    result-info_fname = 'ROW_COLOR'.     " row colour column
    result-stylefname = 'FIELD_STYLE'.   " per-cell style, TYPE lvc_t_styl
    result-excp_fname = 'TRAFFIC_LIGHT'. " traffic-light column
    result-excp_led   = abap_true.       " show an LED instead of a traffic light
    result-cwidth_opt = abap_true.       " optimise column width
    result-grid_title = TEXT-001.        " grid header
    result-smalltitle = abap_true.       " smaller header font
    result-sel_mode   = 'A'.             " multiple row selection
    result-zebra      = abap_true.       " alternating row shading

    " The options below are DELIBERATELY NOT SET here - each one contradicts
    " something this grid needs. Enable them only in a grid that does not:
    "   no_rowmark = abap_true   " removes the selection column - conflicts with sel_mode 'A'
    "   no_toolbar = abap_true   " hides the toolbar - conflicts with handle_toolbar
    "   no_headers = abap_true   " hides column headers
    "   no_hgridln = abap_true   " removes horizontal grid lines
    "   no_keyfix  = abap_true   " stops key columns being fixed on the left
    "   edit       = abap_true   " makes EVERY field editable; prefer per-field
    "                            " fieldcat-edit as build_field_catalog( ) does
  ENDMETHOD.

  METHOD build_toolbar_exclusions.
    result = VALUE #( ( cl_gui_alv_grid=>mc_fc_loc_copy_row )
                      ( cl_gui_alv_grid=>mc_fc_loc_delete_row )
                      ( cl_gui_alv_grid=>mc_fc_loc_insert_row )
                      ( cl_gui_alv_grid=>mc_fc_loc_cut )
                      ( cl_gui_alv_grid=>mc_fc_loc_paste )
                      ( cl_gui_alv_grid=>mc_fc_loc_undo )
                      ( cl_gui_alv_grid=>mc_fc_info ) ).
  ENDMETHOD.
ENDCLASS.


MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_0100'.
  main->show_alv( ).
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
```

**Flow logic of screen 0100 (SE51):**

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0100.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
```

> 💡 `cl_gui_docking_container` attaches the grid to an edge of the screen and needs no custom control in the Screen Painter; `cl_gui_custom_container`, as above, fills a custom control you place yourself.

> 💡 Larger existing reports often split this program into includes — global data, selection screen, local class, dynpro modules. The order of the parts stays the same.

> ⚠️ **`get_selected_rows` returns row indexes in the component `INDEX`.** The `ROW_ID` component belongs to the row-number structures (`es_row_no`, `et_row_no`) that the events and `get_current_cell` pass.

## 🎨 Field Catalog — Building It Manually

> 📝 **Contextual snippet** — the text symbols `f01`–`f04` hold the column texts. With `i_internal_tabname`, `REUSE_ALV_FIELDCATALOG_MERGE` derives the catalog from the program's own declaration of that table (`i_program_name`, `i_inclname`); its function module documentation in `SE37` names the supported declaration forms. A DDIC structure (`i_structure_name`), as in Option 2, avoids that dependency.

```abap
" TYPES declares a type; the internal table is then declared from it.
" (An older form, DATA BEGIN OF ... OCCURS 0, creates a table WITH A HEADER
"  LINE - see chapter 21.)
TYPES: BEGIN OF purchase_order_item,
         ebeln TYPE ekko-ebeln,   " note: '-' , not '~'. The tilde is the
         ebelp TYPE ekpo-ebelp,   " ABAP SQL component separator.
       END OF purchase_order_item.

DATA purchase_order_items TYPE STANDARD TABLE OF purchase_order_item WITH EMPTY KEY.
DATA lvc_field_catalog    TYPE lvc_t_fcat.
DATA slis_field_catalog   TYPE slis_t_fieldcat_alv.
DATA output_table_name    TYPE slis_tabname VALUE 'PURCHASE_ORDER_ITEMS'.

" Declare an LVC field catalog manually
lvc_field_catalog = VALUE #( ( col_pos   = 1
                               fieldname = 'EBELN'
                               coltext   = TEXT-f01
                               scrtext_m = TEXT-f01 ) ).

" Append ANOTHER ROW. Note the single set of parentheses: APPEND VALUE #( ( ... ) )
" would build a TABLE and try to append it as one row.
APPEND VALUE #( col_pos   = lines( lvc_field_catalog ) + 1
                fieldname = 'EBELP'
                coltext   = TEXT-f02
                scrtext_m = TEXT-f02 ) TO lvc_field_catalog.

" Declare an SLIS field catalog (function-module style) with various options
slis_field_catalog = VALUE #( ( col_pos   = 1
                                do_sum    = abap_true
                                edit      = abap_true
                                fieldname = 'EBELP'
                                hotspot   = abap_true
                                key       = abap_true
                                outputlen = 10
                                seltext_s = TEXT-f02
                                seltext_m = TEXT-f03
                                seltext_l = TEXT-f04 ) ).

" Adjust existing entries with a typed loop: emphasize colours a column
LOOP AT lvc_field_catalog REFERENCE INTO DATA(column) WHERE fieldname = 'EBELN'.
  column->key       = abap_true.
  column->emphasize = 'C510'.
ENDLOOP.

" Or generate the field catalog automatically from a DDIC structure/internal table
CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING i_program_name     = sy-repid
            i_internal_tabname = output_table_name
            i_inclname         = sy-repid
  CHANGING  ct_fieldcat        = slis_field_catalog.
```

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE` for the macros below. You will find exactly this pattern in existing ALV reports, and reading it is a real skill. New code adjusts the catalog with a typed loop or a small method, as above — macros bypass type checking and cannot be debugged line by line ([Rule 3.19](../docs/ABAP-Development-Rules.md#319-do-not-write-macros-use-methods-or-expressions)). See [09-Modularization](../09-Modularization/README.md#-macros-define--end-of-definition) and [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference).

> 📝 **Contextual snippet** — continues the snippet above; the text symbol `a01` holds the column text. `change_text` works on the SLIS catalog, because `seltext_s`, `reptext_ddic` and `ddictxt` are SLIS components; the others work on the LVC catalog.

```abap
DEFINE checkbox.
  MODIFY lvc_field_catalog FROM VALUE #( checkbox = abap_true ) TRANSPORTING checkbox WHERE fieldname = &1.
END-OF-DEFINITION.

DEFINE assign_key.
  MODIFY lvc_field_catalog FROM VALUE #( key = abap_true ) TRANSPORTING key WHERE fieldname = &1.
END-OF-DEFINITION.

DEFINE change_color.
  MODIFY lvc_field_catalog FROM VALUE #( emphasize = &2 ) TRANSPORTING emphasize WHERE fieldname = &1.
END-OF-DEFINITION.

DEFINE change_text.
  MODIFY slis_field_catalog FROM VALUE #( seltext_s    = &1
                                          seltext_m    = &1
                                          seltext_l    = &1
                                          reptext_ddic = &1
                                          ddictxt      = 'M' ) TRANSPORTING seltext_s seltext_m seltext_l reptext_ddic ddictxt WHERE fieldname = &2.
END-OF-DEFINITION.

DEFINE clear_key.
  MODIFY lvc_field_catalog FROM VALUE #( key = abap_false ) TRANSPORTING key WHERE fieldname = &1.
END-OF-DEFINITION.

DEFINE remove_output.
  MODIFY lvc_field_catalog FROM VALUE #( no_out = abap_true ) TRANSPORTING no_out WHERE fieldname = &1.
END-OF-DEFINITION.

" Example usage
change_color 'EBELP' 'C610'.
change_text TEXT-a01 'EBELP'.
clear_key 'EBELN'.
```

## 🎛️ Layout — LVC vs. SLIS

The two layout structures are **not interchangeable**: `lvc_s_layo` goes with `cl_gui_alv_grid`, `slis_layout_alv` goes with the `REUSE_ALV_*` function modules. Their component names differ too (`cwidth_opt` vs. `colwidth_optimize`, `ctab_fname` vs. `coltab_fieldname`).

```abap
" LVC layout - used with cl_gui_alv_grid
DATA lvc_layout TYPE lvc_s_layo.

lvc_layout = VALUE #( ctab_fname = 'CELL_COLORS'    " cell colour column
                      info_fname = 'ROW_COLOR'      " row colour column
                      excp_fname = 'TRAFFIC_LIGHT'  " traffic-light column
                      excp_led   = abap_true        " LED instead of traffic light
                      cwidth_opt = abap_true        " optimise column width
                      grid_title = TEXT-001         " grid header
                      smalltitle = abap_true        " smaller header font
                      sel_mode   = 'A'              " multiple row selection
                      zebra      = abap_true ).     " alternating row shading

" SLIS layout - used with REUSE_ALV_GRID_DISPLAY / REUSE_ALV_LIST_DISPLAY
DATA slis_layout TYPE slis_layout_alv.

slis_layout = VALUE #( box_fieldname     = 'SELKZ'
                       coltab_fieldname  = 'CELL_COLORS'
                       colwidth_optimize = abap_true ).
```

## 🧰 Toolbar Customization

```abap
" Exclude specific standard buttons from the grid toolbar.
" The excluding table is TYPE ui_functions (a table of ui_func), not a
" string table - it is passed to it_toolbar_excluding.
DATA excluded_functions TYPE ui_functions.

excluded_functions = VALUE #( ( cl_gui_alv_grid=>mc_fc_refresh )
                              ( cl_gui_alv_grid=>mc_fc_loc_delete_row )
                              ( cl_gui_alv_grid=>mc_fc_loc_insert_row ) ).
```

`REUSE_ALV_*` has no toolbar object: its buttons belong to the GUI status, so a function code is hidden with `SET PF-STATUS … EXCLUDING` in the `PF_STATUS_SET` callback, as in Option 2.

## ✅ Best Practices

- Use `cl_salv_table` for straightforward display-only reports — much less boilerplate than the classic function-module or OOP grid approaches.
- Use `cl_gui_alv_grid` when you need editable cells, custom toolbar buttons, hotspots, or fine-grained event handling.
- **Keep the SLIS and LVC type families apart.** `REUSE_ALV_*` takes `slis_*`; `cl_gui_alv_grid` takes `lvc_*`.
- Always generate the field catalog from the DDIC structure (`LVC_FIELDCATALOG_MERGE` / `REUSE_ALV_FIELDCATALOG_MERGE`) when possible, then tweak only the fields that need customization.
- Implement and register every event handler you declare; register F4 fields with `register_f4_for_fields` and set `m_event_handled` in handlers that take over F1 or F4.
- Use `refresh_table_display( is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) )` after modifying displayed data to keep scroll position and selection stable.
- **Delete selected rows in descending index order**, or the indexes shift under you.
- Keep the class `FINAL` and its attributes private; the dynpro modules reach it through one global reference — [Rules 5.2](../docs/ABAP-Development-Rules.md#52-make-classes-final-unless-they-are-designed-for-inheritance) and [5.6](../docs/ABAP-Development-Rules.md#56-keep-the-public-section-minimal).
- Write `UP TO n ROWS` after `INTO` — [Rule 7.1](../docs/ABAP-Development-Rules.md#71-write-strict-abap-sql-a-comma-separated-field-list--host-variables-into-after-the-query-clauses).
- Mark where an authorization check belongs instead of inventing an authorization object — [Rule 8.2](../docs/ABAP-Development-Rules.md#82-in-guide-examples-mark-where-the-check-belongs-never-invent-an-authorization-object).

## ⚠️ Common Mistakes

- Forgetting to register edit events (`register_edit_event`) before expecting `data_changed`/`data_changed_finished` events to fire on an editable grid.
- Declaring handler methods without implementing them (a syntax error) or without registering them (they never run).
- Mixing `lvc_*` and `slis_*` types between the two ALV families.
- **Registering a static handler with an instance reference** (`SET HANDLER main->static_method`) — this does not compile.
- **Deleting multiple selected rows by ascending index**, which removes the wrong rows after the first deletion.
- Reading `ROW_ID` from the result of `get_selected_rows` — its rows carry `INDEX`.
- Comparing a structure (`es_col_id`) to a literal instead of its `-fieldname` component.
- Calling `alv->display( )` outside the `TRY` that created the object — if the factory raised, the reference is initial.
- Setting contradictory layout options (`no_rowmark` together with `sel_mode = 'A'`, or `no_toolbar` in a grid that adds toolbar buttons).
- Not handling `sy-subrc` after `set_table_for_first_display`.
- Using color codes (`C310`, `C610`, …) without a documented legend.

## 🎤 Interview & Review Checkpoints

- Explain the difference between `cl_salv_table`, `REUSE_ALV_GRID_DISPLAY`, and `cl_gui_alv_grid`, and when to use each.
- Explain the difference between the LVC and SLIS type families and why they cannot be mixed.
- Be ready to explain how to make an ALV Grid cell editable and how to react to data changes (`data_changed` / `data_changed_finished`).
- Explain what a field catalog is and how `LVC_FIELDCATALOG_MERGE` helps generate one automatically.
- Explain why multi-row deletion must run in descending index order.
- Explain how the PBO module, the global reference and the local class work together in an OOP ALV report.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE38 / SE80 | Create/test ALV report programs |
| SE51 | Screen Painter — the dynpro and custom container that host the grid |
| SLG1 | Application log (for logging ALV data issues) |

## 🔗 Related Chapters

- [01-ABAP-Basics](../01-ABAP-Basics/README.md) — the program header and global part of the Option 3 report
- [07-Internal-Tables](../07-Internal-Tables/README.md) — the output tables behind the grid
- [10-Objects](../10-Objects/README.md) — events, `SET HANDLER` and local classes
- [11-Classical-Reports](../11-Classical-Reports/README.md) — dynamic field catalogs/tables
- [12-Selection-Screens](../12-Selection-Screens/README.md) — dynpros, value help and table controls
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — where the three ALV generations sit
