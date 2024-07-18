" ZSM_S_STRUCTURE
" CELL_COLOR TYPE slis_t_specialcol_alv
" LINE_COLOR TYPE char4
" SELKZ      TYPE char1

" Definition
DATA: gs_layout_lvc  TYPE lvc_s_layo,
      gs_layout_slis TYPE slis_layout_alv,
      gt_table       TYPE TABLE OF zsm_s_structure.  

" LVC
gs_layout_lvc = VALUE #( 
  ctab_fname = 'CELLCOLOR' " ALV Cell Color
  cwidth_opt = abap_true   " Column Width Optimization
  edit       = abap_true   " All Fields Are Editable
  excp_fname = 'TLGHT'     " Icon Field
  excp_led   = abap_true   " Displaying LED Instead Of Traffic Lamb
  grid_title = text-001    " ALV Header         
  no_headers = abap_true   " Close Column Header
  no_hgridln = abap_true   " Remove Row Line
  no_keyfix  = abap_true   " Fixed Key Fields         
  no_rowmark = abap_true   " Remove Selection Box
  no_toolbar = abap_true   " Close The Toolbar
  info_fname = 'COLOR'     " ALV Row Color                         
  sel_mode   = 'A'         " Selection Model & no_rowmark-> abap_false                        
  smalltitle = abap_true   " ALV Header Small Font
  zebra      = abap_true   " Different Color For Each Row
).

" SLIS
gs_layout_slis = VALUE #( 
  box_fieldname     = 'SELKZ'
  edit              = abap_true
  coltab_fieldname  = 'CELL_COLOR'
  colwidth_optimize = abap_true
  info_fieldname    = 'LINE_COLOR'
  window_titlebar   = 'REUSE ALV Report'
  zebra             = abap_true
).