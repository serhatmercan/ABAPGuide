" ZSM_S_STRUCTURE
" CELL_COLOR TYPE slis_t_specialcol_alv
" LINE_COLOR TYPE char4
" SELKZ      TYPE char1

CONSTANTS gc_program_name TYPE sy-repid VALUE 'ZSMERCAN'.

TYPE-POOLS: slis, stms.

DATA: gs_layout          TYPE lvc_s_layo,
      gs_print           TYPE slis_print_alv,
      gs_variant         TYPE disvariant,      
      gt_bseg            TYPE TABLE OF bseg,
      gt_excluding       TYPE slis_t_extab,
      gt_events          TYPE slis_t_event,
      gt_fieldcat        TYPE lvc_t_fcat,
      gt_filter          TYPE slis_t_filter_alv, 
      gt_list_commentary TYPE slis_t_listheader,     
      gt_sort            TYPE slis_t_sortinfo_alv,
      gt_table           TYPE TABLE OF zsm_s_structure,
      gv_exit            TYPE char1,
      gv_tabname         TYPE slis_tabname,
      gv_title           TYPE lvc_title.

PARAMETERS p_variant TYPE disvariant-variant.

INITIALIZATION.
  gs_variant-report = sy-repid.

  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
    CHANGING
      cs_variant    = gs_variant
    EXCEPTIONS
      wrong_input   = 1
      not_found     = 2
      program_error = 3
      OTHERS        = 4.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_variant.
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      is_variant    = gs_variant
    IMPORTING
      e_exit        = gv_exit
      es_variant    = gs_variant
    EXCEPTIONS
      not_found     = 1
      program_error = 2
      OTHERS        = 3.
  IF sy-subrc = 0 AND gv_exit IS INITIAL.
    p_variant = gs_variant-variant.
  ENDIF.

" Generate Fieldcat
CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING
    i_program_name     = sy-repid
    i_internal_tabname = gv_tabname
    i_inclname         = sy-repid
  CHANGING
    ct_fieldcat        = gt_fieldcat[]. 

CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING
    i_program_name         = gc_program_name
    i_structure_name       = 'BSEG'
    i_client_never_display = abap_true
    i_inclname             = gc_program_name
  CHANGING
    ct_fieldcat            = gt_fieldcat[].

" Show ALV - I - REUSE ALV GRID DISPLAY
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_buffer_active         = abap_false
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
  TABLES
    t_outtab                = gt_bseg
  EXCEPTIONS
    program_error           = 1
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
  APPEND VALUE #( fieldname = 'EBELP' tabname = 'GT_BSEG' sign0 = 'I' optio = 'EQ' valuf_int = '20' ) TO gt_filter.
ENDFORM.

FORM set_events.
  APPEND VALUE #( name = slis_ev_top_of_page form = 'TOP_OF_PAGE' ) TO gt_events.
  APPEND VALUE #( name = slis_ev_end_of_list form = 'END_OF_LIST' ) TO gt_events.
  APPEND VALUE #( name = slis_ev_pf_status_set form = 'PF_STATUS_SET' ) TO gt_events.
ENDFORM.

FORM set_excluding.
  APPEND VALUE #( fcode = '&INFO' ) TO gt_excluding.
ENDFORM.

FORM set_sort.
  APPEND VALUE #( down = abap_true fieldname = 'BSART' spos = 1 tabname = 'GT_BSEG' ) TO gt_sort.
  APPEND VALUE #( down = abap_true fieldname = 'MENGE' spos = 2 tabname = 'GT_BSEG' ) TO gt_sort.
ENDFORM.

FORM set_variant.
  gs_variant-variant = p_variant.
ENDFORM.

FORM pf_status_set USING p_exttab TYPE slis_t_extab.
  SET PF-STATUS '0100'.
ENDFORM.

FORM top_of_page.
  APPEND VALUE #( typ = 'H' info = 'PO Report' ) TO gt_list_commentary.
  APPEND VALUE #( typ = 'S' key = 'Date' info = '27/11/2022' ) TO gt_list_commentary.
  APPEND VALUE #( typ = 'A' key = 'Report Count:' info = '100' ) TO gt_list_commentary.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = gt_list_commentary.
ENDFORM.

FORM user_command USING p_ucomm     TYPE sy-ucomm
                        ps_selfield TYPE slis_selfield.                        
  CASE p_ucomm.
    WHEN '&IC1'.
      CASE ps_selfield-fieldname.
        WHEN 'EBELN'.
          MESSAGE ps_selfield-value TYPE 'I'.
      ENDCASE.
    WHEN '&MSG'.
      MESSAGE 'Message' TYPE 'I'.
  ENDCASE.
ENDFORM.

" Show ALV - II - REUSE ALV GRID DISPLAY LVC    
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
  EXPORTING
    i_callback_pf_status_set = 'GUI'
    i_callback_program       = sy-repid    
    i_callback_user_command  = 'COMMAND'
    is_layout_lvc            = gs_layout
    it_fieldcat_lvc          = gt_fieldcat[]
  TABLES
    t_outtab                 = gt_table
  EXCEPTIONS
    program_error            = 1
    OTHERS                   = 2.