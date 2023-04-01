*&--------------------------------------*
*&            Report 
*&--------------------------------------*
*& Created By    : Serhat MERCAN / Modül
*& Creation Date : 23.11.2021 
*& Definition    : … (…)
*& Company       : …
*&--------------------------------------*

CLASS lcl_main DEFINITION DEFERRED.

DATA go_main        TYPE REF TO lcl_main.
DATA gt_out         TYPE TABLE OF zsm_t_table.
DATA go_grid        TYPE REF TO cl_gui_alv_grid,
DATA go_container   TYPE REF TO cl_gui_custom_container.

DATA: go_document      TYPE REF TO cl_dd_document,
      go_splitter      TYPE REF TO cl_gui_splitter_container,
      go_subcontainer1 TYPE REF TO cl_gui_container,
      go_subcontainer2 TYPE REF TO cl_gui_container.

INITIALIZATION.
  CREATE OBJECT go_main.

START-OF-SELECTION.
  go_main->start_of_selection( ).

CLASS lcl_main DEFINITION.
    PUBLIC SECTION.
    CLASS-METHODS:
        start_of_selection,
        show_alv IMPORTING iv_container_name    TYPE char50
                           iv_structure_name    TYPE dd02l-tabname
                 CHANGING  co_container         TYPE REF TO cl_gui_custom_container
                           co_grid              TYPE REF TO cl_gui_alv_grid
                           ct_data              TYPE STANDARD TABLE,
*       After User Command
        handle_after_user_command       FOR EVENT after_user_command    OF cl_gui_alv_grid IMPORTING e_ucomm e_saved e_not_processed,                           
*       Before User Command
        handle_before_user_command      FOR EVENT before_user_command   OF cl_gui_alv_grid IMPORTING e_ucomm,
*       Control Button Click
        handle_button_click             FOR EVENT button_click          OF cl_gui_alv_grid IMPORTING es_col_id es_row_no,        
*       Context Menu Request
        handle_context_menu_request     FOR EVENT context_menu_request  OF cl_gui_alv_grid IMPORTING e_object,      
*       Controlling Data Changes When ALV Grid Is Editable
        handle_data_changed             FOR EVENT data_changed          OF cl_gui_alv_grid IMPORTING er_data_changed e_onf4 e_onf4_before e_onf4_after e_ucomm,
*       To Be Triggered After Data Changing Is Finished
        handle_data_changed_finished    FOR EVENT data_changed_finished OF cl_gui_alv_grid IMPORTING sender e_modified,
*       Double Click
        handle_double_click             FOR EVENT double_click          OF cl_gui_alv_grid IMPORTING e_row e_column es_row_no,     
*       Hotspot Click Control
        handle_hotspot_click            FOR EVENT hotspot_click         OF cl_gui_alv_grid IMPORTING e_row_id e_column_id es_row_no,
*       Insert Icons
        handle_insert_icons             FOR EVENT toolbar               OF cl_gui_alv_grid IMPORTING e_object,        
*       Control Menu Buttons        
        handle_menu_button              FOR EVENT menu_button           OF cl_gui_alv_grid IMPORTING e_object e_ucomm,
*       Control Button Clicks
        handle_on_f1                    FOR EVENT onf1                  OF cl_gui_alv_grid IMPORTING e_fieldname es_row_no  er_event_data,
*       Control Button Clicks
        handle_on_f4                    FOR EVENT onf4                  OF cl_gui_alv_grid IMPORTING e_fieldname e_fieldvalue es_row_no er_event_data et_bad_cells e_display,        
*       To Add New Functional Buttons To The ALV Toolbar
        handle_toolbar                  FOR EVENT toolbar               OF cl_gui_alv_grid IMPORTING sender e_object e_interactive,
*       To Add Content Top Of Page
        handle_top_of_page              FOR EVENT top_of_page           OF cl_gui_alv_grid IMPORTING e_dyndoc_id table_index,        
*       To Implement User Commands
        handle_user_command             FOR EVENT user_command          OF cl_gui_alv_grid IMPORTING e_ucomm.
  
    PRIVATE SECTION.
      CLASS-METHODS:
        get_data,
        show_data,
        set_dropdown     RETURNING VALUE(rt_dropdown)       TYPE lvc_t_drop,
        set_fieldcatalog IMPORTING VALUE(iv_structure_name) TYPE dd02l-tabname
                         RETURNING VALUE(rt_fielcat)        TYPE lvc_t_fcat,
        set_fiter        RETURNING VALUE(rt_filter)         TYPE lvc_t_filt,                 
        set_layout       RETURNING VALUE(rs_layout_alv)     TYPE lvc_s_layo,
        set_sort         RETURNING VALUE(rs_sort)           TYPE lvc_t_sort, 
        set_variant      RETURNING VALUE(rt_variant)        TYPE disvariant,       
        set_toolbar_ex   CHANGING  VALUE(ct_toolbar_ex)     TYPE ui_functions.
ENDCLASS.

CLASS lcl_main IMPLEMENTATION.
    METHOD start_of_selection.
        get_data( ).
        
        IF gt_out[] IS INITIAL.
          MESSAGE 'Kayıt Bulunamadı.' TYPE 'S' DISPLAY LIKE 'E'.
          LEAVE LIST-PROCESSING.
        ENDIF.

        show_data( ).
    ENDMETHOD.

    METHOD show_alv.
        DATA lt_dropdown    TYPE lvc_t_drop.
        DATA lt_fieldcat    TYPE lvc_t_fcat.
        DATA lt_filter      TYPE lvc_t_filt.
        DATA lt_sort        TYPE lvc_t_sort.
        DATA lt_toolbar_ex  TYPE ui_functions. 
        DATA ls_layout      TYPE lvc_s_layo.        
        DATA ls_variant     TYPE disvariant.         

        lt_dropdown = set_dropdown(  ).
        lt_fieldcat[] = set_fieldcatalog( iv_structure_name = iv_structure_name ).
        lt_filter[] = set_filter( ).
        lt_sort[] = set_sort( ).
        ls_layout = set_layout( ).        
        ls_variant = set_variant( ).

        IF co_container IS INITIAL .
            CREATE OBJECT co_container
              EXPORTING
                container_name = iv_container_name.
      
            IF co_grid IS INITIAL.
              " Screen w/ Container
              CREATE OBJECT co_grid
                EXPORTING
                  i_parent = co_container.
              
              " Screen w/out Container => Full Screen                  
              CREATE OBJECT co_grid
                  EXPORTING
                    i_parent = cl_gui_container=>screen0.
              
              " Optional
              " PERFORM set_f4.
              " PERFORM set_splitter.

              set_toolbar_ex(
                CHANGING
                  ct_toolbar_ex = lt_toolbar_ex ).
      
              CALL METHOD co_grid->set_drop_down_table
                  EXPORTING
                    it_drop_down = lt_dropdown.

              CALL METHOD co_grid->set_table_for_first_display
                EXPORTING
                  i_buffer_active               = space
                  is_layout                     = ls_layout
                  it_toolbar_excluding          = lt_toolbar_ex
                  i_save                        = 'U'               " A -> All | U -> User Spesific | X -> Standard | Space -> No Save Variant
                  is_variant                    = ls_variant
                  i_default                     = abap_true
                CHANGING
                  it_sort                       = lt_sort
                  it_filter                     = lt_filter
                  it_outtab                     = ct_data
                  it_fieldcatalog               = lt_fcat
                EXCEPTIONS
                  invalid_parameter_combination = 1
                  program_error                 = 2
                  too_many_lines                = 3
                  OTHERS                        = 4.
      
              IF sy-subrc NE 0.
                MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
              ENDIF.

              co_grid->register_edit_event( EXPORTING i_event_id = cl_gui_alv_grid=>mc_evt_enter ).
              co_grid->register_edit_event( EXPORTING i_event_id = cl_gui_alv_grid=>mc_evt_modified ).
              
              SET HANDLER go_main->handle_button_click          FOR co_grid.
              SET HANDLER go_main->handle_data_changed          FOR co_grid.
              SET HANDLER go_main->handle_data_changed_finished FOR co_grid.
              SET HANDLER go_main->handle_double_click          FOR co_grid.
              SET HANDLER go_main->handle_hotspot_click         FOR co_grid.
              SET HANDLER go_main->handle_on_f4                 FOR co_grid.
              SET HANDLER go_main->handle_toolbar               FOR co_grid.
              SET HANDLER go_main->handle_top_of_page           FOR co_grid.
              SET HANDLER go_main->handle_user_command          FOR co_grid.              

              CALL METHOD co_grid->set_ready_for_input
                EXPORTING
                  i_ready_for_input = 1.
      
              CALL METHOD co_grid->set_toolbar_interactive.
      
              CALL METHOD co_grid->register_edit_event
                EXPORTING
                  i_event_id = cl_gui_alv_grid=>mc_evt_modified.
      
            ELSE.
              CALL METHOD co_grid->refresh_table_display(
                  is_stable      = VALUE lvc_s_stbl( col = abap_true row = abap_true )
                  i_soft_refresh = abap_true ).
            ENDIF.
          ELSE.
            CALL METHOD co_grid->refresh_table_display(
                is_stable      = VALUE lvc_s_stbl( col = abap_true row = abap_true )
                i_soft_refresh = abap_true ).
          ENDIF.      
    ENDMETHOD.

    METHOD handle_after_user_command.
    ENDMETHOD.  

    METHOD handle_before_user_command.
    ENDMETHOD.

    METHOD handle_button_click.
      READ TABLE gt_out INTO DATA(ls_out) INDEX es_row_no-row_id.
      IF sy-subrc EQ 0.
        CASE es_col_id-fieldname.
          WHEN 'BUTTON'.
            MESSAGE es_col_id-fieldname TYPE 'I'.  
        ENDCASE.   
      ENDIF.  
    ENDMETHOD.

    METHOD handle_context_menu_request.
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
            CALL METHOD go_grid->get_current_cell
              IMPORTING
                es_col_id = DATA(lv_current_col_id)
                es_row_no = DATA(ls_current_row_no).
    
            CASE lv_current_col_id.
              WHEN 'LFIMG'.
                READ TABLE gt_out ASSIGNING FIELD-SYMBOL(<ls_out>) INDEX ls_current_row_no-row_id.
                IF sy-subrc EQ 0.
                  <ls_out>-color = 'C610'.
                ENDIF.
            ENDCASE.
    
            CALL METHOD go_grid->refresh_table_display(
                is_stable      = VALUE lvc_s_stbl( col = abap_true row = abap_true )
                i_soft_refresh = abap_true ).
        ENDCASE.
    ENDMETHOD.

    METHOD handle_double_click.
      READ TABLE gt_out INTO DATA(ls_out) INDEX e_row-index.
      IF sy-subrc EQ 0 
        WRITE e_column-fieldname.
      ENDIF.
    ENDMETHOD.

    METHOD handle_hotspot_click.
        READ TABLE gt_out REFERENCE INTO DATA(ls_out) INDEX es_row_no-row_id .
        IF sy-subrc EQ 0 AND e_column_id-fieldname EQ 'VBELN'.
          SET PARAMETER ID 'VL' FIELD ls_out->vbeln.
          CALL TRANSACTION 'VL03N'.
        ENDIF.        
    ENDMETHOD.

    METHOD handle_insert_icons.
    ENDMETHOD.  

    METHOD handle_menu_button.
    ENDMETHOD.

    METHOD handle_on_f1.
    ENDMETHOD.

    METHOD handle_on_f4.
      TYPES: BEGIN OF lty_value_tab,
           pstyv TYPE pstyv,
         END OF lty_value_tab.

      DATA: lt_return_tab TYPE TABLE OF ddshretval,
            lt_value_tab  TYPE TABLE OF lty_value_tab.

      lt_value_tab = VALUE #( ( pstyv = 'X' ) ( pstyv = 'Y' ) ( pstyv = 'Z' ) ).

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
        EXPORTING
          retfield     = 'PSTYV'
          window_title = 'PSTYV F4'
        TABLES
          value_tab    = lt_value_tab
          return_tab   = lt_return_tab.

      IF line_exists( lt_return_tab[ fieldname = 'F0001' ] ).
        IF line_exists( gt_out[ es_row_no-row_id ] ).
          gt_out[ es_row_no-row_id ]-pstyv = lt_return_tab[ fieldname = 'F0001' ]-fieldval.
          go_grid->refresh_table_display( ). 
        ENDIF.
      ENDIF.
    ENDMETHOD.

    METHOD handle_user_command.
        CASE e_ucomm.
          WHEN '100_SLA'.
            LOOP AT gt_out_0100 REFERENCE INTO DATA(ls_0100).
              ls_0100->chbox = abap_true.
            ENDLOOP.
          WHEN 'ADD_LINE'.
            DATA ls_cellstyle TYPE lvc_s_styl.
            DATA lv_out LIKE LINE OF gt_out_0100.  
            DATA(lv_records_count) = lines( gt_out_0100 ).          
            
            ls_cellstyle = VALUE #( fieldname = 'NAME'
                                    style     = cl_gui_alv_grid=>mc_style_enabled ).
                                    
            lv_out-id = lv_records_count + 1.     
            lv_out-fieldstyle = ls_cellstyle.    

            MODIFY gt_out_0100 FROM gs_data INDEX lv_records_count + 1.                          
        ENDCASE.

        go_grid->refresh_table_display( EXPORTING is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
    ENDMETHOD.

    METHOD handle_toolbar.
        CASE sender.
          WHEN go_grid.
              APPEND VALUE #( function  = '100_SLA'
                              quickinfo = text-101
                              text      = text-101
                              icon      = icon_select_all ) TO e_object->mt_toolbar.
              APPEND VALUE #( function  = 'ADD_LINE'
                              quickinfo = text-102
                              text      = text-102
                              icon      = icon_insert_row ) TO e_object->mt_toolbar.
        ENDCASE.
    ENDMETHOD.

    METHOD handle_top_of_page.
      go_document->add_text(
        EXPORTING
          text      = 'Header'
          sap_style = cl_dd_document=>heading 
      ).

      go_document->new_line( ).

      go_document->add_text(
        EXPORTING
          text         = 'Subheader'
          sap_color    = cl_dd_document=>list_positive
          sap_fontsize = cl_dd_document=>medium
      ).

      go_document->display_document(
        EXPORTING
          parent = go_subcontainer1 
      ).
    ENDMETHOD.

    METHOD get_data.
        SELECT * FROM lips
        INTO CORRESPONDING FIELDS OF TABLE gt_out
        UP TO 20 ROWS.

        LOOP AT gt_out REFERENCE INTO DATA(ls_out) WHERE pstyv EQ 'NLC'.             
            ls_out->button = 'C710'.
            ls_out->color = 'C710'. " Row Color: C610 -> Red | 'C310' -> Yellow | 'C510' -> Green 
            ls_out->statu = '@01@'.
            ls_out->tlght = '2'.    " Cell Color: 1-> Red 2-> Yellow 3-> Green
            APPEND VALUE #( fname = 'VBELN'
                            color-col = '5'
                            color-int = '1'
                            color-inv = '1' ) TO ls_out->cellcolor.
        ENDLOOP.
    ENDMETHOD.

    METHOD show_data.
        CALL SCREEN 0100.
    ENDMETHOD.

    METHOD set_dropdown.                    
      SELECT zzprint
        FROM zsm_t_print
        INTO TABLE @DATA(lt_table).

        LOOP AT lt_table INTO DATA(ls_data).
          APPEND INITIAL LINE TO rt_dropdown ASSIGNING FIELD-SYMBOL(<fs_dropdown>).
          <fs_dropdown>-handle = '1'.
          <fs_dropdown>-value  = ls_data-zzprint.          
        ENDLOOP.
    ENDMETHOD.

    METHOD set_fieldcatalog.
        CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
          EXPORTING
            i_bypassing_buffer = abap_true          
            i_structure_name   = iv_structure_name
          CHANGING
            ct_fieldcat        = rt_fielcat[].
    
        LOOP AT rt_fielcat REFERENCE INTO DATA(ls_fieldcat).
          CASE ls_fieldcat->fieldname.
            WHEN 'BUTTON'. 
              ls_fieldcat->icon       = abap_true.  
              ls_fieldcat->scrtext_s  = 'Button'.
              ls_fieldcat->scrtext_m  = 'Button'.
              ls_fieldcat->scrtext_l  = 'Button'.
              ls_fieldcat->style      = cl_gui_alv_grid=>mc_style_button.  
            WHEN 'COLOR'. " CHAR4          
              ls_fieldcat->no_out     = abap_true.
            WHEN 'CHBOX'.
              ls_fieldcat->checkbox   = abap_true. 
              ls_fieldcat->edit       = abap_true.
            WHEN 'DROPDOWN'.
              ls_fieldcat->drdn_hndl  = 1.
              ls_fieldcat->edit       = abap_true.
            WHEN 'LFIMG'.
              ls_fieldcat->do_sum     = abap_true.
              ls_fieldcat->edit       = abap_true.
              ls_fieldcat->no_zero    = abap_true.
            WHEN 'POSNR'.
              ls_fieldcat->emphasize  = 'C110'.  " 'C110' | 'C510' | 'C610'
            WHEN 'PSTYV'.
              ls_fieldcat->edit       = abap_true.  
              ls_fieldcat->f4availabl = abap_true.
            WHEN 'STATU'. " CHAR10
              ls_fieldcat->icon       = abap_true.
              ls_fieldcat->scrtext_s  = 'Statu'.
              ls_fieldcat->scrtext_m  = 'Statu'.
              ls_fieldcat->scrtext_l  = 'Statu'.                 
            WHEN 'TLGHT'.
              ls_fieldcat->scrtext_s  =
              ls_fieldcat->scrtext_m  =
              ls_fieldcat->scrtext_l  =
              ls_fieldcat->col_opt    = abap_true.
              ls_fieldcat->col_pos    = 99.            
              ls_fieldcat->coltext    = 'Statu'.            
              ls_fieldcat->outputlen  = 100.            
            WHEN 'VBELN'.
              ls_fieldcat->hotspot    = abap_true.
              ls_fieldcat->key        = abap_true.
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
        rs_layout_alv-excp_led   = abap_true.     " Displaying LED Insted Of Traffic Lamb
        rs_layout_alv-grid_title = text-001.      " ALV Header         
        rs_layout_alv-no_headers = abap_true.     " Close Column Header
        rs_layout_alv-no_hgridln = abap_true.     " Remove Row Line
        rs_layout_alv-no_keyfix  = abap_true.     " Fixed Key Fields         
        rs_layout_alv-no_rowmark = abap_true.     " Remove Selection Box
        rs_layout_alv-no_toolbar = abap_true.     " Close The Toolbar
        rs_layout_alv-info_fname = 'COLOR'.       " ALV Row Color                         
        rs_layout_alv-sel_mode   = 'A'.           " Selection Model & no_rowmark-> abap_false                        
        rs_layout_alv-smalltitle = abap_true.     " ALV Header Small Font
        rs_layout_alv-stylefname = 'FIELD_STYLE'. " Set Layout Style For Custom Row => TYPE LVC_T_STYL 
        rs_layout_alv-zebra      = abap_true.     " Different Color For Each Row            
    ENDMETHOD.

    METHOD set_sort.
        APPEND VALUE #( ( fieldname = 'VBELN' down = abap_true )
                        ( fieldname = 'POSNR' up = abap_true ) ) TO rt_sort.
    ENDMETHOD.

    METHOD set_toolbar_ex.
        APPEND : cl_gui_alv_grid=>mc_fc_loc_copy_row      TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_loc_delete_row    TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_loc_insert_row    TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_loc_move_row      TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_loc_copy          TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_loc_cut           TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_loc_paste         TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_loc_undo          TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_check             TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_info              TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_print_back        TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_print             TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_print_prev        TO ct_toolbar_ex,
                 cl_gui_alv_grid=>mc_fc_refresh           TO ct_toolbar_ex.
    ENDMETHOD.
    
    METHOD set_variant.
        rs_variant-username = sy-uname.  
        rs_variant-report   = sy-repid.             
    ENDMETHOD.
ENDCLASS. 

*&-----------------------------*
*&  Include ZSM_R_REPORT
*&-----------------------------*
*&-----------------------------*
*& Module  STATUS_0100  OUTPUT
*&-----------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS sy-dynnr.
  SET TITLEBAR sy-dynnr.

  CALL METHOD go_main->show_alv(
    EXPORTING
      iv_cont_name = 'CON100'
      iv_stru_name = 'ZSM_S_STRUCTURE'
    CHANGING
      co_cont      = go_container
      co_grid      = go_grid
      ct_data      = gt_out[] ).
ENDMODULE.
*&--------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&--------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE sy-ucomm.
    WHEN 'BACK' OR 'CANCEL' OR 'EXIT'.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.
*&--------------------------------------------*
*&      SET F4
*&--------------------------------------------*
FORM set_f4.
  DATA(lt_f4) = VALUE lvc_t_f4( ( fieldname = 'PSTYV' register = abap_true ) ).

  go_grid->register_f4_for_fields( it_f4 = lt_f4 ).
ENDFORM.
*&--------------------------------------------*
*&      SET SPLITTER
*&--------------------------------------------*
FORM set_splitter

  CREATE OBJECT go_grid
    EXPORTING
      i_parent = co_container.

  CREATE OBJECT go_splitter
    EXPORTING
      parent  = co_container
      rows    = 2
      columns = 1.

  go_splitter->get_container(
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_subcontainer1 ).

  go_splitter->get_container(
    EXPORTING
      row       = 2
      column    = 1
    RECEIVING
      container = go_subcontainer2 ).

  go_splitter->set_row_height(
    EXPORTING
      id     = 1
      height = 15 ).

  CREATE OBJECT go_document
    EXPORTING
      style = 'ALV_GRID'.

  CREATE OBJECT go_grid
    EXPORTING
      i_parent = go_subcontainer2.

  go_grid->list_processing_events(
    EXPORTING
      i_event_name = 'TOP_OF_PAGE'
      i_dyndoc_id  = go_document ).

ENDFORM.