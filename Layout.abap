" Definition
DATA gs_layout TYPE lvc_s_layo.

gs_layout-ctab_fname = 'CELLCOLOR'. " ALV Cell Color
gs_layout-cwidth_opt = abap_true.   " Column Width Optimization
gs_layout-edit       = abap_true.   " All Fields Are Editable
gs_layout-excp_fname = 'TLGHT'.     " Icon Field
gs_layout-excp_led   = abap_true.   " Displaying LED Insted Of Traffic Lamb
gs_layout-grid_title = text-001.    " ALV Header         
gs_layout-no_headers = abap_true.   " Close Column Header
gs_layout-no_hgridln = abap_true.   " Remove Row Line
gs_layout-no_keyfix  = abap_true.   " Fixed Key Fields         
gs_layout-no_rowmark = abap_true.   " Remove Selection Box
gs_layout-no_toolbar = abap_true.   " Close The Toolbar
gs_layout-info_fname = 'COLOR'.     " ALV Row Color                         
gs_layout-sel_mode   = 'A'.         " Selection Model & no_rowmark-> abap_false                        
gs_layout-smalltitle = abap_true.   " ALV Header Small Font
gs_layout-zebra      = abap_true.   " Different Color For Each Row