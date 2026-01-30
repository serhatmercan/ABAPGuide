DATA: BEGIN OF gt_data OCCURS 0,
        ebeln LIKE ekko~ebeln,
        ebelp LIKE ekpo~ebelp,  
      END OF gt_data.

DATA: gt_fieldcat      TYPE lvc_t_fcat,
      gt_field_catalog TYPE slis_t_fieldcat_alv,
      gv_tabname       TYPE slis_tabname DEFAULT 'GT_DATA'.

" Declare Fieldcat Manually
gt_fieldcat = VALUE #( ( col_pos = 1 coltext = 'Text' fieldname = 'SPMON' scrtext_m = abap_true ) ).

" Add Another Line
DATA(lv_lines) = lines( gt_fieldcat ) .
APPEND VALUE #(  ( col_pos = lv_lines + 1 coltext = 'Text' fieldname = 'SPMON' scrtext_m = abap_true ) ) TO gt_fieldcat.

" Declare Fieldcat with Various Options
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

" Add Checkbox
DEFINE checkbox.
  MODIFY gt_fieldcat FROM VALUE #( checkbox = abap_true ) TRANSPORTING checkbox WHERE fieldname = &1.  
END-OF-DEFINITION.

" Assign Key
DEFINE assign_key.
  MODIFY gt_fieldcat FROM VALUE #( key = abap_true ) TRANSPORTING key WHERE fieldname = &1.
END-OF-DEFINITION.

" Change Color
DEFINE change_color.
  MODIFY gt_fieldcat FROM VALUE #( emphasize = &2 ) TRANSPORTING emphasize WHERE fieldname = &1.
END-OF-DEFINITION.

" Change Text                              
DEFINE change_text.
  MODIFY gt_fieldcat FROM VALUE #(  seltext_s    = &1 
                                    seltext_m    = &1
                                    seltext_l    = &1
                                    reptext_ddic = &1  
                                    ddictxt      = 'M' ) TRANSPORTING seltext_s seltext_m seltext_l reptext_ddic ddictxt WHERE fieldname = &2.
END-OF-DEFINITION.

" Clear Key
DEFINE clear_key.
  MODIFY gt_fieldcat FROM VALUE #( key = abap_false ) TRANSPORTING key WHERE fieldname = &1.
END-OF-DEFINITION.

" Remove Output
DEFINE remove_output.
  MODIFY gt_fieldcat FROM VALUE #( no_out = abap_true ) TRANSPORTING no_out WHERE fieldname = &1.
END-OF-DEFINITION.    

" Example
change_color 'BUKRS' 'C610'.
change_text TEXT-a01 'BUKRS'.
clear_key 'BUKRS'.

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