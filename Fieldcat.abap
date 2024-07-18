DATA: BEGIN OF gt_data OCCURS 0,
        ebeln LIKE ekko~ebeln,
        ebelp LIKE ekpo~ebelp,  
      END OF gt_data.

DATA: gt_fieldcat      TYPE lvc_t_fcat,
      gt_field_catalog TYPE slis_t_fieldcat_alv,
      gv_tabname       TYPE slis_tabname DEFAULT 'GT_DATA'.

gt_fieldcat = VALUE #(  ( col_pos = 1 coltext = 'Text' fieldname = 'SPMON' scrtext_m = 'X' ) ).

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

" Generate Fieldcat From Internal Table
CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING
    i_program_name     = sy-repid
    i_internal_tabname = gv_tabname
    i_inclname         = sy-repid
  CHANGING
    ct_fieldcat        = gt_field_catalog.

" Generate Fieldcat From Structure I
CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
   EXPORTING
     i_program_name         = sy-repid
     i_structure_name       = 'BSEG'
     i_client_never_display = abap_true
     i_inclname             = sy-repid
    CHANGING
      ct_fieldcat           = gt_field_catalog[].
      
" Generate Fieldcat From Structure II
CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZSM_S_STRUCTURE'
    CHANGING
      ct_fieldcat      = gt_fieldcat.      
      
DATA(lv_lines) = lines( gt_fieldcat ) .

APPEND VALUE #(  ( col_pos = lv_lines + 1 coltext = 'Text' fieldname = 'SPMON' scrtext_m = 'X' ) ) TO gt_fieldcat.
