" Assign
TYPES: tt_mara TYPE STANDARD TABLE OF mara.

DATA: lt_data TYPE REF TO data,
      lr_data TYPE REF TO data,
      lv_data TYPE string,
      lt_mara TYPE tt_mara.

FIELD-SYMBOLS: <lt_data> TYPE STANDARD TABLE,
               <lt_node> TYPE STANDARD TABLE,
               <lv_id> TYPE any,  
               <ls_data> TYPE any,
               <lfs_any_tab> TYPE ANY TABLE,
               <fs_mara> LIKE LINE OF lt_mara.            

ASSIGN cr_data->* TO <ls_data>.
ASSIGN COMPONENT lv_data OF STRUCTURE <ls_data> TO <lt_node>.

LOOP AT <lt_node> ASSIGNING FIELD-SYMBOL(<ls_node>).
  ASSIGN COMPONENT 'EXT_ID' OF STRUCTURE <ls_node> TO <lv_id>.
  IF sy-subrc EQ 0.
    DATA(lv_alpha_id) = |{ <lv_id> ALPHA = IN }|.
  ENDIF.
ENDLOOP.

" Append
APPEND INITIAL LINE TO lt_mara ASSIGNING FIELD-SYMBOL(<fs_mara>).
<fs_mara>-matnr = '123456'.
UNASSIGN <fs_mara>.

" Check & Remove
IF <ls_node> IS ASSIGNED.
  UNASSIGN <ls_node>.
ENDIF.

" Create
ASSIGN lt_data->* TO <lt_data>.
CREATE DATA lr_data LIKE LINE OF <lt_data>. 

" Definition
APPEND INITIAL LINE TO lt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
<ls_data> = VALUE #( id = 'X' value = '1' ).

" Insert
INSERT INITIAL LINE INTO lt_mara ASSIGNING <fs_mara> INDEX 2.
<fs_mara>-matnr = 'ABCDEF'.
UNASSIGN <fs_mara>.

" Loop 
LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
  APPEND INITIAL LINE TO lt_table ASSIGNING FIELD-SYMBOL(<ls_table>).
  <ls_table> = CORRESPONDING #( <ls_data> ).
  <ls_table>-key = 'X'.
ENDLOOP.