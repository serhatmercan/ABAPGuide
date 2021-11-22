CONSTANTS: gc_program_name LIKE sy-repid VALUE 'ZSMERCAN'. 

TYPE-POOLS: slis, stms.

DATA:   gs_layout   TYPE lvc_s_layo,
        gs_print    TYPE slis_print_alv,
        gt_bseg     TYPE TABLE OF bseg,
        gt_table    TYPE TABLE OF ZSM_S_STRUCTURE,
        gt_fieldcat TYPE lvc_t_fcat,
        gt_sort     TYPE slis_t_sortinfo_alv WITH HEADER LINE,
        gv_tabname  TYPE slis_tabname,
        gv_repid    TYPE sy-repid,
        gv_title    TYPE lvc_title.

" Generate Fieldcat
CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING
    i_program_name     = gv_repid
    i_internal_tabname = gv_tabname
    i_inclname         = gv_repid
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

" Show ALV
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_buffer_active    = abap_false
    i_grid_title       = gv_title
    i_callback_program = gv_repid
    is_layout          = gs_layout
    is_print           = gs_print
    i_save             = 'A'
    it_fieldcat        = gt_fieldcat[]
    it_sort            = gt_sort[]
  TABLES
    t_outtab           = gt_bseg
  EXCEPTIONS
    program_error      = 1
    OTHERS             = 2.

CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      it_fieldcat        = gt_fieldcat[]
      is_layout          = gs_layout
      i_save             = 'X'
      i_callback_program = sy-repid
      it_events          = gt_event1
    TABLES
      t_outtab           = gt_bseg. 

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