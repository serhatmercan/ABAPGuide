# 12 — Selection Screens, Screens & Popups

## 📖 Introduction

Selection screens gather report input from the user (`PARAMETERS`, `SELECT-OPTIONS`). Dynpros (`SCREEN`) provide fully custom, interactive screens (tabstrips, subscreens, PBO/PAI modules). This chapter also covers popup windows and screen field control.

## 🖥️ Selection Screen Elements

```abap
TABLES: mara, sscrfields, vbak.

DATA lt_values TYPE vrm_values.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS p_matnr TYPE mara-matnr OBLIGATORY.
  SELECT-OPTIONS s_vbeln FOR vbak-vbeln.

  SELECTION-SCREEN SKIP.

  PARAMETERS p_value AS CHECKBOX.
  SELECT-OPTIONS s_devcl FOR wa_tadir-devclass OBLIGATORY DEFAULT 'Z*' OPTION CP SIGN I.

  SELECTION-SCREEN SKIP.

  PARAMETERS p_rad1 RADIOBUTTON GROUP gr1 USER-COMMAND rad DEFAULT 'X'.
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
  SELECT-OPTIONS s_date FOR zrt270-datum DEFAULT sy-datum OBLIGATORY.

  SELECTION-SCREEN SKIP.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS p_rad1 RADIOBUTTON GROUP 00 USER-COMMAND radio DEFAULT 'X'.
    SELECTION-SCREEN COMMENT (10) TEXT-001.
    PARAMETERS p_rad2 RADIOBUTTON GROUP 00.
    SELECTION-SCREEN COMMENT (10) TEXT-002.
    PARAMETERS p_rad3 RADIOBUTTON GROUP 00.
    SELECTION-SCREEN COMMENT (10) TEXT-003.

    PARAMETERS p_cb AS CHECKBOX MODIF ID 003.
    SELECTION-SCREEN COMMENT (12) TEXT-004 MODIF ID 003.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN FUNCTION KEY 2.
```

| Element | Purpose |
|---|---|
| `PARAMETERS` | Single-value input field |
| `SELECT-OPTIONS` | Range input (low/high, multiple values) — generates a range table (see [06-Loops](../06-Loops/README.md#-range-tables-ranges--select-options)) |
| `RADIOBUTTON GROUP` | Mutually exclusive options |
| `AS CHECKBOX` | Boolean toggle |
| `AS LISTBOX` | Dropdown (values set at runtime via `VRM_SET_VALUES`) |
| `MODIF ID` | Groups fields so their screen attributes (visible/enabled) can be changed together in `LOOP AT SCREEN` |
| `MATCHCODE OBJECT` | Attaches an F4 search help to a parameter |

## 🎛️ Selection-Screen Events & Dynamic Behavior

```abap
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
  " Populate a listbox's values at runtime
  lt_values = VALUE #( ( key = '1' text = '3' )
                       ( key = '2' text = '2' )
                       ( key = '3' text = '3' ) ).

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING id     = 'P_NUMBER'
              values = lt_values.

  " Custom function-key icons/text on the selection screen toolbar
  sscrfields-functxt_01 = VALUE smp_dyntxt( icon_id   = '@J2@'
                                            text      = TEXT-u01
                                            icon_text = TEXT-u01
                                            quickinfo = TEXT-u01 ).
  sscrfields-functxt_02 = VALUE smp_dyntxt( icon_id   = '@0O@'
                                            text      = TEXT-u02
                                            icon_text = TEXT-u02
                                            quickinfo = TEXT-u02 ).

  " Hide/disable a group of fields dynamically
  LOOP AT SCREEN INTO DATA(ls_screen).
    IF ls_screen-group1 = 'GR1'.
      ls_screen-active    = 0.
      ls_screen-invisible = 1.
      MODIFY SCREEN FROM ls_screen.
    ENDIF.
  ENDLOOP.

  " Pre-fill a SELECT-OPTIONS default from the current user's settings
  SELECT SINGLE lgort FROM zsm_t_data
    WHERE username = @sy-uname
    INTO @DATA(lv_lgort).

  s_lgort = VALUE #( ( sign = 'I' option = 'EQ' low = lv_lgort ) ).
ENDFORM.
```

## 🪟 Custom Screens (Dynpros)

A dynpro has two processing blocks: **PBO** (Process Before Output, runs before the screen is displayed) and **PAI** (Process After Input, runs after the user acts).

```abap
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

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_0100'.

  PERFORM set_dropdown_sh.
  PERFORM set_screen_fields.
ENDMODULE.

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

FORM set_dropdown_sh.
  gv_id = 'GV_VALUE'.
  gt_values = VALUE vrm_values( ( key = '1' text = 'A' )
                                ( key = '2' text = 'B' )
                                ( key = '3' text = 'C' ) ).

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = gv_id
      values = gt_values.
ENDFORM.
```

### Screen Field Modules (PBO/PAI at Field Level)

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0102.

PROCESS AFTER INPUT.
  FIELD qmel-zznakliye MODULE check_zznakliye.
  FIELD qmel-zznakliye MODULE get_yukek_text ON INPUT.
  MODULE user_command_0102.

MODULE status_0102 OUTPUT.
  LOOP AT SCREEN INTO DATA(ls_screen).
    IF ls_screen-name IN ('QMEL-ZZURT_KOD', 'QMEL-ZZNAKLIYE') AND sy-tcode IN ('QM03', 'IW23').
      ls_screen-input = 0.
      MODIFY SCREEN FROM ls_screen.
    ENDIF.
  ENDLOOP.
ENDMODULE.
```
> 💡 `FIELD <field> MODULE <name> ON INPUT` runs a PAI module **only if the field's value has changed** — useful for expensive validations that shouldn't run on every PAI cycle.

## 🔔 Popups

```abap
" A screen displayed as a modal popup window
CALL SELECTION-SCREEN 601 STARTING AT 40 8.

SELECTION-SCREEN BEGIN OF SCREEN 601 AS WINDOW.
  SELECT-OPTIONS s_datum FOR zrt270-datum DEFAULT sy-datum OBLIGATORY.
  SELECT-OPTIONS s_skopf FOR zrt270-skopf.
  SELECTION-SCREEN SKIP.
  SELECT-OPTIONS s_uname FOR zrt270-uname.
SELECTION-SCREEN END OF SCREEN 601.

" Quick single-value input popup (ABAP Demo Kit helper class)
DATA(lv_client) = cl_demo_input=>request( ).

" Simple informational popup
CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
  EXPORTING textline1 = 'Hello'.
```

## ✅ Best Practices

- Use `MODIF ID` groups + `LOOP AT SCREEN` for dynamic show/hide logic instead of hardcoding field names repeatedly.
- Keep PBO modules lightweight (avoid DB calls where possible) — they run every time the screen is redrawn.
- Use `FIELD ... MODULE ... ON INPUT` to avoid re-running expensive checks when a field hasn't changed.
- Prefer `cl_demo_input=>request( )`/simple popups only for quick prototypes/tools; use proper selection screens or Fiori/UI5 apps for production tools.

## ⚠️ Common Mistakes

- Forgetting `OBLIGATORY` on mandatory selection fields, letting users submit incomplete input.
- Not clearing/resetting `sscrfields-ucomm` handling logic, causing function keys to trigger unwanted repeated actions.
- Overusing hardcoded literal screen/field names — makes maintenance and screen painter changes brittle.

## 🎤 Interview Tips

- Explain the PBO/PAI cycle and when each module type runs.
- Be ready to explain the difference between `PARAMETERS` and `SELECT-OPTIONS`, and what a `SELECT-OPTIONS` field expands to (a range table).
- Explain `MODIF ID` and `LOOP AT SCREEN` dynamic screen control.

## 🔗 Related Chapters

- [06-Loops](../06-Loops/README.md) — range tables produced by `SELECT-OPTIONS`
- [01-ABAP-Basics](../01-ABAP-Basics/README.md) — report event order
- [13-ALV](../13-ALV/README.md)
