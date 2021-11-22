TABLES: mara, sscrfields, vbak.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
    PARAMETERS: p_matnr TYPE mara-matnr OBLIGATORY.
    SELECT-OPTIONS: s_vbeln FOR vbak-vbeln.
    SELECTION-SCREEN SKIP.
    PARAMETERS: p_value AS CHECKBOX.
    SELECT-OPTIONS: s_devcl FOR wa_tadir-devclass OBLIGATORY DEFAULT 'Z*' OPTION CP SIGN I.
    SELECTION-SCREEN SKIP.
    PARAMETERS p_rad1 RADIOBUTTON GROUP gr1 DEFAULT 'X' USER-COMMAND rad.
    PARAMETERS p_rad2 RADIOBUTTON GROUP gr1.
    PARAMETERS p_rad3 RADIOBUTTON GROUP gr1.
    SELECTION-SCREEN SKIP.
    PARAMETERS p_count TYPE zsm_t_data-zzprint AS LISTBOX VISIBLE LENGTH 5 MODIF ID gr2 DEFAULT 1 OBLIGATORY.
    SELECT-OPTIONS s_mjahr FOR mseg-mjahr MODIF ID gr2.
    SELECT-OPTIONS s_lgort FOR mseg-lgort MODIF ID gr2.
    SELECTION-SCREEN SKIP.
    PARAMETERS: p_mail TYPE check.
    PARAMETERS: p_number TYPE i AS LISTBOX VISIBLE LENGTH 7 DEFAULT 3 OBLIGATORY.
    SELECT-OPTIONS: s_date FOR zrt270-datum DEFAULT sy-datum OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN FUNCTION KEY 2.

INITIALIZATION.
  PERFORM init.

AT SELECTION-SCREEN OUTPUT.
  PERFORM at_selection_screen_output.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_count.
  PERFORM at_selection_screen_on_value_request.

AT SELECTION-SCREEN.
  IF sy-ucomm EQ 'FC01'.
  ELSEIF sy-ucomm EQ 'FC02'.
  ENDIF. 

FORM init.
    " Set Select Option Value
    SELECT SINGLE lgort
      FROM zsm_t_data
      INTO DATA(lv_lgort)
      WHERE username EQ sy-uname.

    s_lgort-low  = lv_lgort.  
    
    APPEND s_lgort.

    " Set Listbox Value
    lt_values = VALUE #( ( key = '1' text = '3' )
                         ( key = '2' text = '2' )  
                         ( key = '3' text = '3' ) ).

    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id     = 'P_NUMBER'
        values = lt_values.

    " Set Toolbar Button
    DATA lv_icon LIKE smp_dyntxt.
    CLEAR lv_icon.
    lv_icon-icon_id       = '@J2@'.
    lv_icon-text          = text-u01.
    lv_icon-icon_text     = text-u01.
    lv_icon-quickinfo     = text-u01.
    sscrfields-functxt_01 = lv_icon.

    CLEAR lv_icon.
    lv_icon-icon_id       = '@0O@'.
    lv_icon-text          = text-u02.
    lv_icon-icon_text     = text-u02.
    lv_icon-quickinfo     = text-u02.
    sscrfields-functxt_02 = lv_icon. 
ENDFORM.

FORM at_selection_screen_output .
    IF p_rad1 = 'X'.
      LOOP AT SCREEN.
        IF screen-group1 EQ 'GR1'.
          screen-active    = 0.
          screen-invisible = 1.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.  
    ELSEIF p_rad2 = 'X'.
      LOOP AT SCREEN.
        IF screen-group1 EQ 'GR2'.
          screen-active    = 0.
          screen-invisible = 1.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
    ENDIF.
ENDFORM. 

FORM at_selection_screen_on_value_request.
  SELECT zzprint
    FROM zsm_t_data
    INTO TABLE @DATA(lt_data).

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ZZPRINT'
      value_org       = 'S'
    TABLES
      value_tab       = lt_data
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
ENDFORM.