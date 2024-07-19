TABLES: mara, sscrfields, vbak.

DATA lt_values TYPE vrm_values.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
  PARAMETERS p_matnr TYPE mara-matnr OBLIGATORY.
  SELECT-OPTIONS s_vbeln FOR vbak-vbeln.

  SELECTION-SCREEN SKIP.

  PARAMETERS p_value AS CHECKBOX.
  SELECT-OPTIONS s_devcl FOR wa_tadir-devclass OBLIGATORY DEFAULT 'Z*' OPTION CP SIGN I.

  SELECTION-SCREEN SKIP.

  PARAMETERS p_rad1 RADIOBUTTON GROUP gr1 DEFAULT 'X' USER-COMMAND rad.
  PARAMETERS p_rad2 RADIOBUTTON GROUP gr1.
  PARAMETERS p_rad3 RADIOBUTTON GROUP gr1.

  SELECTION-SCREEN SKIP.

  PARAMETERS p_count TYPE zsm_t_data-zzprint AS LISTBOX VISIBLE LENGTH 5 MODIF ID gr2 DEFAULT 1 OBLIGATORY.
  SELECT-OPTIONS s_mjahr FOR mseg-mjahr MODIF ID gr2.
  SELECT-OPTIONS s_lgort FOR mseg-lgort MODIF ID gr2.

  SELECTION-SCREEN SKIP.

  PARAMETERS p_id TYPE zsm_d_id MATCHCODE OBJECT zsm_sh_id.
  PARAMETERS p_mail TYPE check.
  PARAMETERS p_number TYPE i AS LISTBOX VISIBLE LENGTH 7 DEFAULT 3 OBLIGATORY.
  SELECT-OPTIONS: s_date FOR zrt270-datum DEFAULT sy-datum OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN FUNCTION KEY 2.

INITIALIZATION.
  PERFORM init.

AT SELECTION-SCREEN OUTPUT.
  PERFORM at_selection_screen_output.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_module.
  PERFORM at_selection_screen_on_value_request.

AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'FC01'.
    WHEN 'FC02'.
  ENDCASE.

END-OF-SELECTION.

FORM init.
  lt_values = VALUE #( ( key = '1' text = '3' )
                       ( key = '2' text = '2' )  
                       ( key = '3' text = '3' ) ).

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_NUMBER'
      values = lt_values.

  sscrfields-functxt_01 = VALUE smp_dyntxt( icon_id = '@J2@' text = text-u01 icon_text = text-u01 quickinfo = text-u01 ).
  sscrfields-functxt_02 = VALUE smp_dyntxt( icon_id = '@0O@' text = text-u02 icon_text = text-u02 quickinfo = text-u02 ).

  LOOP AT SCREEN INTO DATA(ls_screen).
    IF ls_screen-group1 EQ 'GR1'.
      ls_screen-active    = 0.
      ls_screen-invisible = 1.
      MODIFY SCREEN FROM ls_screen.
    ENDIF.
  ENDLOOP.

  SELECT SINGLE lgort
    FROM zsm_t_data
    WHERE username EQ @sy-uname
    INTO @DATA(lv_lgort).

  s_lgort = VALUE #( ( sign = 'I' option = 'EQ' low = lv_lgort ) ).
ENDFORM.

FORM at_selection_screen_output.
  LOOP AT SCREEN INTO DATA(ls_screen).
    IF p_rad1 EQ abap_true AND ls_screen-group1 EQ 'GR1'.
      ls_screen-active = 0.
      ls_screen-invisible = 1.
    ELSEIF p_rad2 EQ abap_true AND ls_screen-group1 EQ 'GR2'.
      ls_screen-active = 0.
      ls_screen-invisible = 1.
    ENDIF.

    MODIFY SCREEN FROM ls_screen.
  ENDLOOP.
ENDFORM.

FORM at_selection_screen_on_value_request.
  SELECT modul, modul_txt
    FROM zhr_001_t_module
    INTO TABLE @DATA(lt_modules).

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'P_MODULE'
      retfield        = 'MODUL'
      value_org       = 'S'
    TABLES
      value_tab       = lt_modules
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
ENDFORM.