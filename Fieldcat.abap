DATA: gt_fieldcat TYPE lvc_t_fcat.

gt_fieldcat = VALUE #(  ( col_pos = 1 coltext = 'Text' fieldname = 'SPMON' scrtext_m = 'X' ) ).

" Generate Fieldcat From Structure
CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZSM_S_STRUCTURE'
    CHANGING
      ct_fieldcat      = gt_fieldcat.

DATA(lv_lines) = lines( gt_fieldcat ) .

APPEND VALUE #(  ( col_pos = lv_lines + 1 coltext = 'Text' fieldname = 'SPMON' scrtext_m = 'X' ) ) TO gt_fieldcat.
