" Definition
APPEND INITIAL LINE TO lt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
<ls_data> = VALUE #( id = 'X' value = '1' ).

" Assign
DATA: lr_data TYPE REF TO data,
      lv_data TYPE string.

FIELD-SYMBOLS: <lt_node> TYPE STANDARD TABLE,
               <lv_id> TYPE any,  
               <ls_data> TYPE any.

ASSIGN cr_data->* TO <ls_data>.
ASSIGN COMPONENT lv_data OF STRUCTURE <ls_data> TO <lt_node>.

LOOP AT <lt_node> ASSIGNING FIELD-SYMBOL(<ls_node>).
  ASSIGN COMPONENT 'EXT_ID' OF STRUCTURE <ls_node> TO <lv_id>.
  IF sy-subrc EQ 0.
    DATA(lv_alpha_id) = |{ <lv_id> ALPHA = IN }|.
  ENDIF.
ENDLOOP.

" Loop 
LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
  APPEND INITIAL LINE TO lt_table ASSIGNING FIELD-SYMBOL(<ls_table>).
  <ls_table> = CORRESPONDING #( <ls_data> ).
  <ls_table>-key = 'X'.
ENDLOOP.