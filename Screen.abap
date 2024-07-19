REPORT zsm_test.

CONTROLS go_tab TYPE tabstrip.

DATA: gt_values TYPE vrm_values,
      gv_flag   TYPE xfeld, 
      gv_id     TYPE vrm_id,
      gv_value  TYPE i.

START-OF-SELECTION.
  CALL SCREEN 0100.

*--------------------*
*     Module PBO     *
*--------------------*

PROCESS BEFORE OUTPUT.
  MODULE status_0100.

  CALL SUBSCREEN SUB1 INCLUDING sy-repid '0101'. 

*--------------------*
*     Module PAI     *
*--------------------*

PROCESS AFTER INPUT.
  MODULE user_command_0100.

  CALL SUBSCREEN SUB1.

*----------------------------*
*     STATUS_0100 OUTPUT     *
*----------------------------*

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_0100'.
  
  PERFORM set_dropdown_sh.
  PERFORM set_screen_fields.
ENDMODULE.

*---------------------------------*
*     USER_COMMAND_0100 INPUT     *
*---------------------------------*

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN '&BACK'.
      LEAVE TO SCREEN 0.
    WHEN '&DISABLE' OR '&ENABLE'.
      gv_flag = COND #( WHEN sy-ucomm = '&DISABLE' THEN abap_false ELSE abap_true ).
    WHEN '&TAB1'.
      go_tab-activetab = '&TAB1'.
    WHEN '&TAB2'.
      go_tab-activetab = '&TAB2'.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.

*------------------------------*
*     FORM SET_DROPDOWN_SH     *
*------------------------------*

FORM set_dropdown_sh .
  gv_id = 'GV_VALUE'.
  gt_values = VALUE vrm_values( ( key = '1' text = 'A' )
                                ( key = '2' text = 'B' )
                                ( key = '3' text = 'C' ) ).
  
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = gv_id
      values = gt_values.
ENDFORM.

*--------------------------------*
*     FORM SET_SCREEN_FIELDS     *
*--------------------------------*

FORM set_screen_fields.
  LOOP AT SCREEN INTO DATA(ls_screen).
    IF ls_screen-name = 'GV_VALUE'.
      ls_screen-active = 0.
      ls_screen-input = 0.
      ls_screen-invisible = 1.
      MODIFY SCREEN FROM ls_screen.
    ENDIF.
  
    IF ls_screen-group1 = abap_true.
      ls_screen-input = COND #( WHEN gv_flag = abap_true THEN 1 ELSE 2 ).
      MODIFY SCREEN FROM ls_screen.
    ENDIF.
  ENDLOOP.
ENDFORM.