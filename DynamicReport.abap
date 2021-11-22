" Definition
PARAMETERS: p_table TYPE dd02l-tabname.
DATA gt_fieldcat TYPE lvc_t_fcat.

" Generate Dynamic ALV Fieldcat
CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = p_matnr
    CHANGING
      ct_fieldcat      = gt_fieldcat.


" Generate Dynamic ALV Table
FIELD-SYMBOLS <fs_table> TYPE STANDARD TABLE.
FIELD-SYMBOLS <fs_line>  TYPE any.

DATA gt_table    TYPE REF TO data.
DATA gt_line     TYPE REF TO data.

CALL METHOD cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog           = gt_fieldcat[]
    IMPORTING
      ep_table                  = gt_table
    EXCEPTIONS
      generate_subpool_dir_full = 1
      OTHERS                    = 2.
  
CHECK sy-subrc EQ 0.
ASSIGN gt_table->* TO <fs_table>.

CREATE DATA gt_line LIKE LINE OF <fs_table>.
ASSIGN gt_line->* TO <fs_line>.

" Get Dynamic ALV Table Data
SELECT * 
  UP TO 50 ROWS
  FROM (p_table)
  INTO CORRESPONDING FIELDS OF TABLE <fs_table>.

" Show Dynamic ALV
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_structure_name = p_table
    TABLES
      t_outtab         = <fs_table>.