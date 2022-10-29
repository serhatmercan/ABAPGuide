REPORT zsm_test.

DATA: gt_values TYPE vrm_values,
      gv_flag   TYPE xfeld, 
      gv_id     TYPE vrm_id,
      gv_value  TYPE i.

CONTROLS go_tab TYPE TABSTRIP.

START-OF-SELECTION.

  CALL SCREEN 0100.

*&---------------------------------------------------------------------*
*& Module PBO
*&---------------------------------------------------------------------*

PROCESS BEFORE OUTPUT.
  MODULE status_0100.

  CALL SUBSCREEN SUB1 INCLUDING sy-repid '0101'. 

*&---------------------------------------------------------------------*
*& Module PAI
*&---------------------------------------------------------------------*

PROCESS AFTER INPUT.
  MODULE user_command_0100.

  CALL SUBSCREEN SUB1.

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_0100'.
  
  PERFORM set_dropdown_sh.
  PERFORM set_screen_fields.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN '&BACK'.
      LEAVE TO SCREEN 0.
    WHEN '&DISABLE' OR '&ENABLE'.
      gv_flag = COND #( WHEN sy-ucomm EQ '&DISABLE' THEN abap_false ELSE abap_true ).
    WHEN '&TAB1'.
      go_tab-activetab = '&TAB1'.
    WHEN '&TAB2'.
      go_tab-activetab = '&TAB2'.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Form set_dropdown_sh
*&---------------------------------------------------------------------*
FORM set_dropdown_sh .
    gv_id = 'GV_VALUE'.
    gt_values = VALUE #( ( key = '1' text = 'A' )
                         ( key = '2' text = 'B' )
                         ( key = '3' text = 'C' ) ).
  
    CALL FUNCTION 'VRM_SET_VALUES'
        EXPORTING
            id     = gv_id
            values = gt_values.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_screen_fields
*&---------------------------------------------------------------------*

FORM set_screen_fields.
    LOOP AT SCREEN.
      IF screen-name EQ 'GV_VALUE'.
        screen-active = 0.
        screen-input = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
  
      IF screen-group1 EQ abap_true.
        screen-input = COND #( WHEN gv_flag EQ abap_true THEN 1 ELSE 2 ).
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
ENDFORM.