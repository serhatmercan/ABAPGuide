" ZSM_S_STRUCTURE
" CELL_COLOR TYPE slis_t_specialcol_alv
" LINE_COLOR TYPE char4
" SELKZ      TYPE char1

CONSTANTS: gc_program_name LIKE sy-repid VALUE 'ZSMERCAN'.

TYPE-POOLS: slis, stms.

DATA: gs_layout          TYPE lvc_s_layo,
      gs_variant         TYPE DISVARIANT,
      gs_print           TYPE slis_print_alv,
      gt_bseg            TYPE TABLE OF bseg,
      gt_events          TYPE slis_t_event,
      gt_excluding       TYPE SLIS_T_EXTAB,
      gt_fieldcat        TYPE lvc_t_fcat,
      gt_filter          TYPE SLIS_T_FILTER_ALV, 
      gt_list_commentary TYPE slis_t_listheader,     
      gt_sort            TYPE slis_t_sortinfo_alv WITH HEADER LINE,
      gt_table           TYPE TABLE OF zsm_s_structure,
      gv_exit            TYPE char1,
      gv_tabname         TYPE slis_tabname,
      gv_title           TYPE lvc_title.

PARAMETERS p_vrnt TYPE disvariant-variant.

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

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vrnt.
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
  IF sy-subrc EQ 0 AND gv_exit IS INITIAL.
    p_vrnt = gs_variant-variant.
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
      ct_fieldcat           = gt_fieldcat[].

" Show ALV - I - REUSE ALVE GRID DISPLAY
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_buffer_active         = abap_false
    i_callback_program      = sy-repid
    i_callback_top_of_page  = 'TOP_OF_PAGE'
    i_callback_user_command = 'USER_COMMAND'
    i_grid_title            = gv_title
    i_save                  = '' || 'A' || 'U' || 'X'
    is_layout               = gs_layout
    is_print                = gs_print
    is_variant              = gs_variant
    it_events               = gt_events
    it_excluding            = gt_excluding    
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

FORM SET_COLOR.
  LOOP AT gt_table ASSIGNING FIELD-SYMBOL(<fs_table>).
    IF <fs_table>-ebelp EQ '10'.
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

FORM SET_FILTER.
  APPEND INITIAL LINE TO gt_filter ASSIGNING FIELD-SYMBOL(<fs_filter>).
  <fs_filter>-fieldname = 'EBELP'.
  <fs_filter>-tabname = 'GT_BSEG'.
  <fs_filter>-sign0 = 'I'.
  <fs_filter>-optio = 'EQ'.    
  <fs_filter>-valuf_int = '20'.
ENDFORM.

FORM SET_EVENTS.
  APPEND INITIAL LINE TO gt_events ASSIGNING FIELD-SYMBOL(<fs_event>).
  <fs_event>-name = slis_ev_top_of_page.
  <fs_event>-form = 'TOP_OF_PAGE'.

  APPEND INITIAL LINE TO gt_events ASSIGNING <fs_event>.
  <fs_event>-name = slis_ev_end_of_list.
  <fs_event>-form = 'END_OF_LIST'.

  APPEND INITIAL LINE TO gt_events ASSIGNING <fs_event>.
  <fs_event>-name = slis_ev_pf_status_set.
  <fs_event>-form = 'PF_STATUS_SET'.
ENDFORM.

FORM SET_EXCLUDING.
  APPEND INITIAL LINE TO gt_excluding ASSIGNING FIELD-SYMBOL(<fs_excluding>).
  <fs_excluding>-fcode = '&INFO'.
ENDFORM.

FORM SET_SORT.
  APPEND INITIAL LINE TO gt_sort ASSIGNING FIELD-SYMBOL(<fs_sort>).
  <fs_sort>-down = abap_true.
  <fs_sort>-fieldname = 'BSART'.
  <fs_sort>-spos = 1.
  <fs_sort>-tabname = 'GT_BSEG'.

  APPEND INITIAL LINE TO gt_sort ASSIGNING <fs_sort>.
  <fs_sort>-down = abap_true.
  <fs_sort>-fieldname = 'MENGE'.
  <fs_sort>-spos = 2.
  <fs_sort>-tabname = 'GT_BSEG'.
ENDFORM.

FORM SET_VARIANT.
  gs_variant-variant = '/SMERCAN'.
  gs_variant-variant = p_vrnt.
ENDFORM.

FORM PF_STATUS_SET USING p_exttab TYPE slis_t_extab.
  SET PF-STATUS '0100'.
ENDFORM.

FORM TOP_OF_PAGE.
  APPEND INITIAL LINE TO gt_list_commentary ASSIGNING FIELD-SYMBOL(<fs_commentary>).
  <fs_commentary>-typ = 'H'.
  <fs_commentary>-info = 'PO Report'.

  APPEND INITIAL LINE TO gt_list_commentary ASSIGNING <fs_commentary>.
  <fs_commentary>-typ = 'S'.
  <fs_commentary>-key = 'Date'.
  <fs_commentary>-info = '27/11/2022'.

  APPEND INITIAL LINE TO gt_list_commentary ASSIGNING <fs_commentary>.
  <fs_commentary>-typ = 'A'.
  <fs_commentary>-key = 'Report Count:'.
  <fs_commentary>-info = '100'.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = gt_list_commentary.
ENDFORM.

FORM user_command USING p_ucomm     TYPE sy-ucomm
                        ps_selfield TYPE slis_selfield.                        
  READ TABLE gt_table INTO DATA(ls_table) WHERE selkz EQ abap_true.
                        
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

" Show ALV - II - REUSE ALVE GRID DISPLAY LVC    
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'GUI'
      i_callback_user_command  = 'COMMAND'
      is_layout_lvc            = gs_layout
      it_fieldcat_lvc          = gt_fieldcat[]
    TABLES
      t_outtab                 = gt_table[]
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.