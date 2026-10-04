# 12 — Selection Screens, Screens & Popups

## 📖 Introduction

Selection screens gather report input from the user (`PARAMETERS`, `SELECT-OPTIONS`). Dynpros (`SCREEN`) provide fully custom, interactive screens (tabstrips, subscreens, table controls, PBO/PAI modules). This chapter also covers value help, popup windows and screen field control.

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. Selection screens and dynpros are the standard on-premise report and dialog UI and remain in active use. They are **not** part of the ABAP Cloud development model, where the UI layer is Fiori/UI5 over OData. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 🖥️ Selection Screen Elements

> 📝 **Contextual snippet** — part of an executable program; `zsm_t_print_job`, `zsm_t_document`, the data element `zsm_e_document_id` and the search help `zsm_sh_document_id` are placeholders, and text symbols hold the block title and the comments.

```abap
" TABLES only for the interface work area SSCRFIELDS (toolbar function keys);
" SELECT-OPTIONS ... FOR refers to ordinary DATA objects
TABLES sscrfields.

DATA sales_order_id   TYPE vbak-vbeln.
DATA package_name     TYPE tadir-devclass.
DATA fiscal_year      TYPE mseg-mjahr.
DATA storage_location TYPE mseg-lgort.
DATA creation_date    TYPE zsm_t_document-erdat.
DATA listbox_values   TYPE vrm_values.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS p_matnr TYPE mara-matnr OBLIGATORY.
  SELECT-OPTIONS s_vbeln FOR sales_order_id.

  SELECTION-SCREEN SKIP.

  PARAMETERS p_value AS CHECKBOX.
  SELECT-OPTIONS s_devcl FOR package_name OBLIGATORY DEFAULT 'Z*' OPTION CP SIGN I.

  SELECTION-SCREEN SKIP.

  " Radio button group. Group names are identifiers (max 4 characters),
  " not numeric literals - 'g1', not '00'.
  PARAMETERS p_rad1 RADIOBUTTON GROUP g1 USER-COMMAND rad DEFAULT 'X'.
  PARAMETERS p_rad2 RADIOBUTTON GROUP g1.
  PARAMETERS p_rad3 RADIOBUTTON GROUP g1.

  SELECTION-SCREEN SKIP.

  " MODIF ID groups fields so LOOP AT SCREEN can address them together.
  " The name must match what you compare against screen-group1 later.
  PARAMETERS p_count TYPE zsm_t_print_job-print_count AS LISTBOX VISIBLE LENGTH 5
                     MODIF ID gr2 DEFAULT 1 OBLIGATORY.
  SELECT-OPTIONS s_mjahr FOR fiscal_year MODIF ID gr2.
  SELECT-OPTIONS s_lgort FOR storage_location MODIF ID gr2.

  SELECTION-SCREEN SKIP.

  PARAMETERS p_id     TYPE zsm_e_document_id MATCHCODE OBJECT zsm_sh_document_id.
  PARAMETERS p_mail   AS CHECKBOX.
  PARAMETERS p_number TYPE i AS LISTBOX VISIBLE LENGTH 7 DEFAULT 3 OBLIGATORY.
  SELECT-OPTIONS s_date FOR creation_date DEFAULT sy-datum OBLIGATORY.

  SELECTION-SCREEN SKIP.

  " Elements arranged on one line; FOR FIELD ties each comment to its field
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS p_optn1 RADIOBUTTON GROUP g2 USER-COMMAND radio DEFAULT 'X'.
    SELECTION-SCREEN COMMENT (10) TEXT-002 FOR FIELD p_optn1.
    PARAMETERS p_optn2 RADIOBUTTON GROUP g2.
    SELECTION-SCREEN COMMENT (10) TEXT-003 FOR FIELD p_optn2.
    PARAMETERS p_optn3 RADIOBUTTON GROUP g2.
    SELECTION-SCREEN COMMENT (10) TEXT-004 FOR FIELD p_optn3.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS p_cb AS CHECKBOX MODIF ID gr3.
    SELECTION-SCREEN COMMENT (12) TEXT-005 FOR FIELD p_cb.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN FUNCTION KEY 2.
```

> ⚠️ **Every parameter and select-option name must be unique in the program.** Two `PARAMETERS p_rad1` declarations — even in different blocks — are a duplicate declaration. `SELECT-OPTIONS ... FOR` needs a data object that is already declared; a `DATA` work area or component is enough, no `TABLES` statement required.

| Element | Purpose |
|---|---|
| `PARAMETERS` | Single-value input field |
| `SELECT-OPTIONS` | Range input (low/high, multiple values) — generates a selection table with header line (see [06-Loops](../06-Loops/README.md#-range-tables-ranges--select-options)) |
| `RADIOBUTTON GROUP` | Mutually exclusive options |
| `AS CHECKBOX` | Boolean toggle |
| `AS LISTBOX` | Dropdown (values set at runtime via `VRM_SET_VALUES`) |
| `MODIF ID` | Groups fields so their screen attributes (visible/enabled) can be changed together in `LOOP AT SCREEN` |
| `MATCHCODE OBJECT` | Attaches a Dictionary search help to a parameter; the name is historical, the addition is not obsolete |
| `COMMENT ... FOR FIELD` | Ties a text to a field: F1 and F4 on the text act on the field, and the text follows the field's modification group |

## 🎛️ Selection-Screen Events & Dynamic Behavior

The event blocks stay short and call methods of a local class; subroutines are obsolete ([Rule 3.16](../docs/ABAP-Development-Rules.md#316-do-not-write-statements-the-abap-keyword-documentation-classifies-as-obsolete)).

> 📝 **Contextual snippet** — continues the snippet above; `zsm_t_user_default` is a placeholder table with the user's default storage location, and the text symbols `u01`, `u02` and `v01`–`v03` hold the button and listbox texts.

```abap
CLASS lcl_selection_screen DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS initialize.
    METHODS adjust_fields.
ENDCLASS.


CLASS lcl_selection_screen IMPLEMENTATION.
  METHOD initialize.
    " Populate a listbox's values at runtime
    listbox_values = VALUE #( ( key = '1' text = TEXT-v01 )
                              ( key = '2' text = TEXT-v02 )
                              ( key = '3' text = TEXT-v03 ) ).

    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING id     = 'P_NUMBER'
                values = listbox_values.

    " Custom function-key icons/text on the selection screen toolbar
    sscrfields-functxt_01 = VALUE smp_dyntxt( icon_id   = '@J2@'
                                              text      = TEXT-u01
                                              icon_text = TEXT-u01
                                              quickinfo = TEXT-u01 ).
    sscrfields-functxt_02 = VALUE smp_dyntxt( icon_id   = '@0O@'
                                              text      = TEXT-u02
                                              icon_text = TEXT-u02
                                              quickinfo = TEXT-u02 ).

    " Pre-fill a SELECT-OPTIONS default from the current user's settings.
    " The selection table has a header line, so [] addresses the table body.
    SELECT SINGLE lgort
      FROM zsm_t_user_default
      WHERE username = @sy-uname
      INTO @DATA(default_storage_location).

    IF sy-subrc = 0.
      s_lgort[] = VALUE #( ( sign = 'I' option = 'EQ' low = default_storage_location ) ).
    ENDIF.
  ENDMETHOD.

  METHOD adjust_fields.
    " Show the GR2 fields only while the first radio button is selected.
    " screen-group1 holds the MODIF ID in upper case: 'GR2', not 'gr2'.
    LOOP AT SCREEN INTO DATA(screen_field).
      IF screen_field-group1 = 'GR2' AND p_rad1 <> abap_true.
        screen_field-active    = 0.
        screen_field-invisible = 1.
        MODIFY SCREEN FROM screen_field.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


DATA selection_screen TYPE REF TO lcl_selection_screen.

" Runs ONCE, before the selection screen is built.
" Good for: default values, listbox contents, toolbar texts.
" NOT for screen modification - see AT SELECTION-SCREEN OUTPUT below.
INITIALIZATION.
  selection_screen = NEW #( ).
  selection_screen->initialize( ).

" Runs on EVERY screen display (the selection screen's PBO).
" This is the ONLY place where LOOP AT SCREEN / MODIFY SCREEN takes effect.
AT SELECTION-SCREEN OUTPUT.
  selection_screen->adjust_fields( ).

" Field-level validation: an error message here reopens only this field
AT SELECTION-SCREEN ON p_matnr.

" Toolbar function keys arrive in sscrfields-ucomm, not in sy-ucomm
AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
    WHEN 'FC02'.
  ENDCASE.

START-OF-SELECTION.
```

> ⚠️ **`LOOP AT SCREEN` / `MODIFY SCREEN` only take effect in `AT SELECTION-SCREEN OUTPUT`.** The screen attributes are reset to their static values at the start of every PBO, so a change made in `INITIALIZATION` or in PAI runs without error and changes nothing. This is one of the most frequently reported "my dynamic screen logic doesn't work" problems.

> 📝 Write `LOOP AT SCREEN INTO …` and `MODIFY SCREEN FROM …` with your own work area. The short form without `INTO` / `FROM` works on the built-in structure `screen` and is obsolete.

## 🔍 Value Help

### From an Internal Table

When the values exist only at runtime, `AT SELECTION-SCREEN ON VALUE-REQUEST` builds them and hands them to the function module `F4IF_INT_TABLE_VALUE_REQUEST`, which shows the list and writes the chosen value into the screen field.

> 📝 **Contextual snippet** — part of an executable program; the text symbols `f01` and `f02` hold the descriptions. **[verify: the parameters of `F4IF_INT_TABLE_VALUE_REQUEST` in `SE37` of your release]**

```abap
TYPES: BEGIN OF file_format,
         format      TYPE c LENGTH 3,
         description TYPE c LENGTH 40,
       END OF file_format.

DATA file_formats TYPE STANDARD TABLE OF file_format WITH EMPTY KEY.

PARAMETERS p_format TYPE c LENGTH 3.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_format.
  file_formats = VALUE #( ( format = 'CSV' description = TEXT-f01 )
                          ( format = 'TXT' description = TEXT-f02 ) ).

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'FORMAT'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'P_FORMAT'
      value_org       = 'S'
    TABLES
      value_tab       = file_formats
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
```

### From a Dictionary Search Help

When the same value help is needed on several screens, define it once in the ABAP Dictionary as an elementary search help (transaction `SE11`) and attach it with `MATCHCODE OBJECT`, as `p_id` does above. Its definition names:

- **the selection method** — the table or view that supplies the values, and optionally a text table for language-dependent texts;
- **the dialog type** — whether the hit list appears at once or only after the user has restricted the values;
- **the parameters** — which of them take a value from the screen (import), which return the chosen value (export), and where each appears in the hit list and in the restriction dialog;
- **optionally a search help exit** — a function module that adjusts the values or the dialog.

The ABAP Keyword Documentation does not describe these settings; they are part of the ABAP Dictionary documentation for your release **[verify]**.

## 🪟 Custom Screens (Dynpros)

A dynpro has two processing blocks: **PBO** (Process Before Output, runs before the screen is displayed) and **PAI** (Process After Input, runs after the user acts).

> ⚠️ **The flow logic and the ABAP source are two different objects.** `PROCESS BEFORE OUTPUT` / `PROCESS AFTER INPUT` live in the screen's **flow logic**, maintained in the Screen Painter (SE51 / the Screen tab in SE80). They cannot be pasted into a `REPORT` source. The `MODULE ... ENDMODULE` blocks they call **do** live in the ABAP source. The two listings below are shown separately for exactly that reason.

**Flow logic — maintained in SE51, not in the ABAP source:**

```abap
* --- Screen 0100, Flow Logic tab ---
PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  CALL SUBSCREEN sub1 INCLUDING sy-repid '0101'.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
  CALL SUBSCREEN sub1.
```

**ABAP source — the program that owns the screen:**

> 📝 The screen elements are assumed: a tabstrip `MAIN_TABS` with the tabs `TAB1` and `TAB2`, a dropdown field `SELECTED_VALUE`, and input fields in the modification group `EDT`. The text symbols `d01`–`d03` hold the dropdown texts.

```abap
REPORT zsm_r_tabstrip_screen.

CONTROLS main_tabs TYPE TABSTRIP.

DATA dropdown_values TYPE vrm_values.
DATA fields_enabled  TYPE abap_bool VALUE abap_true.
DATA selected_value  TYPE i.

START-OF-SELECTION.
  CALL SCREEN 0100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_0100'.

  dropdown_values = VALUE #( ( key = '1' text = TEXT-d01 )
                             ( key = '2' text = TEXT-d02 )
                             ( key = '3' text = TEXT-d03 ) ).

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'SELECTED_VALUE'
      values = dropdown_values.

  " The input fields of group EDT follow the DISABLE / ENABLE buttons
  LOOP AT SCREEN INTO DATA(screen_field).
    IF screen_field-group1 = 'EDT'.
      screen_field-input = COND #( WHEN fields_enabled = abap_true THEN 1 ELSE 0 ).
      MODIFY SCREEN FROM screen_field.
    ENDIF.
  ENDLOOP.
ENDMODULE.

MODULE user_command_0100 INPUT.
  " Function codes beginning with '&' are used by SAP standard functions [verify] -
  " use plain names for your own commands.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.
    WHEN 'DISABLE' OR 'ENABLE'.
      fields_enabled = xsdbool( sy-ucomm = 'ENABLE' ).
    WHEN 'TAB1'.
      main_tabs-activetab = 'TAB1'.
    WHEN 'TAB2'.
      main_tabs-activetab = 'TAB2'.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.
```

### Screen Field Modules (PBO/PAI at Field Level)

> 📝 Assumes the customer append fields `zz_carrier` and `zz_product_code` on `QMEL`, placed on a screen of your own program.

**Flow logic (SE51):**

```abap
* --- Screen 0102, Flow Logic tab ---
PROCESS BEFORE OUTPUT.
  MODULE status_0102.

PROCESS AFTER INPUT.
  FIELD qmel-zz_carrier MODULE check_carrier.
  FIELD qmel-zz_carrier MODULE get_carrier_text ON REQUEST.
  MODULE user_command_0102.
```

**ABAP source:**

```abap
MODULE status_0102 OUTPUT.
  " Make the custom fields display-only in the display transactions.
  " NOTE: 'x IN ( a, b )' is ABAP SQL syntax and is NOT valid in an ABAP IF.
  " Use an OR chain, or a range table for longer lists.
  LOOP AT SCREEN INTO DATA(screen_field).
    IF ( screen_field-name = 'QMEL-ZZ_PRODUCT_CODE' OR
         screen_field-name = 'QMEL-ZZ_CARRIER' )
   AND ( sy-tcode = 'QM03' OR sy-tcode = 'IW23' ).
      screen_field-input = 0.
      MODIFY SCREEN FROM screen_field.
    ENDIF.
  ENDLOOP.
ENDMODULE.
```

> 💡 `FIELD <field> MODULE <name> ON REQUEST` runs a PAI module **only if the user entered a value in the field since PBO** — useful for expensive work that shouldn't repeat on every PAI cycle. `ON INPUT` is different: it runs the module whenever the field is not initial, changed or not.

> 💡 For a longer list of values, build a range table once and keep the `IN` form:
> ```abap
> DATA(display_tcodes) = VALUE rseloption( sign = 'I' option = 'EQ'
>                                          ( low = 'QM03' ) ( low = 'IW23' ) ).
> IF sy-tcode IN display_tcodes.
> ```

### Table Controls

A table control shows the lines of an internal table on a dynpro. The flow logic loops over the table in PBO and PAI; the ABAP side declares the control and writes changed lines back.

**Flow logic (SE51):**

```abap
* --- Screen 0200, Flow Logic tab ---
PROCESS BEFORE OUTPUT.
  LOOP AT order_items INTO order_item
       CURSOR items_control-top_line
       WITH CONTROL items_control.
  ENDLOOP.

PROCESS AFTER INPUT.
  LOOP AT order_items.
    CHAIN.
      FIELD order_item-quantity.
      FIELD order_item-unit.
      MODULE update_item ON CHAIN-REQUEST.
    ENDCHAIN.
  ENDLOOP.
```

**ABAP source:**

> 📝 **Contextual snippet** — `zsm_s_order_item` is a placeholder structure with the components `quantity` and `unit`; the table control `ITEMS_CONTROL` on screen 0200 shows the fields `ORDER_ITEM-QUANTITY` and `ORDER_ITEM-UNIT`.

```abap
CONTROLS items_control TYPE TABLEVIEW USING SCREEN 0200.

DATA order_items TYPE STANDARD TABLE OF zsm_s_order_item WITH EMPTY KEY.
DATA order_item  TYPE zsm_s_order_item.

MODULE update_item INPUT.
  " current_line is the table line of the row being processed
  MODIFY order_items FROM order_item INDEX items_control-current_line.
ENDMODULE.
```

> 💡 `ON CHAIN-REQUEST` calls the module when the user changed at least one field of the chain, and an error message in it reopens all fields of the chain for input. For an editable list in new SAP GUI development, consider the editable ALV grid in [13-ALV](../13-ALV/README.md) instead.

## 🔔 Popups

> 📝 **Contextual snippet** — continues the first snippet (`creation_date`); `zsm_t_document` is a placeholder table and the text symbol `p01` holds the popup text.

```abap
DATA document_type TYPE zsm_t_document-doc_type.
DATA created_by    TYPE zsm_t_document-ernam.

" A stand-alone selection screen displayed as a modal popup window.
" Declare it once, then call it where you need it.
SELECTION-SCREEN BEGIN OF SCREEN 601 AS WINDOW.
  SELECT-OPTIONS s_datum FOR creation_date DEFAULT sy-datum OBLIGATORY.
  SELECT-OPTIONS s_dtype FOR document_type.
  SELECTION-SCREEN SKIP.
  SELECT-OPTIONS s_uname FOR created_by.
SELECTION-SCREEN END OF SCREEN 601.

START-OF-SELECTION.
  CALL SELECTION-SCREEN 601 STARTING AT 40 8.
  IF sy-subrc <> 0.
    RETURN.                        " user cancelled the popup
  ENDIF.

  " Simple informational popup
  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
    EXPORTING textline1 = TEXT-p01.
```

### Confirmation Popup

> 📝 **Contextual snippet** — the text symbols `p02` and `p03` hold the title and the question. **[verify: the parameters and answer values of `POPUP_TO_CONFIRM` in `SE37` of your release]**

```abap
DATA answer TYPE c LENGTH 1.

CALL FUNCTION 'POPUP_TO_CONFIRM'
  EXPORTING
    titlebar              = TEXT-p02
    text_question         = TEXT-p03
    display_cancel_button = abap_true
  IMPORTING
    answer                = answer
  EXCEPTIONS
    text_not_found        = 1
    OTHERS                = 2.

" '1' = first button (yes), '2' = second button (no), 'A' = cancel
IF sy-subrc <> 0 OR answer <> '1'.
  RETURN.
ENDIF.
```

> 📝 Older programs use `POPUP_CONTINUE_YES_NO`, `POPUP_TO_CONFIRM_STEP` or `POPUP_TO_CONFIRM_DATA_LOSS`, which answer with language-dependent codes such as `'J'` and `'N'` **[verify]**. Compare the answer with the codes the function module documents, never with a translated word.

### Other Popup Function Modules

You will meet these in existing code. Check the signature and, for new code, the release status in `SE37` before using one **[verify]**.

| Function module | Shows |
|---|---|
| `POPUP_GET_VALUES` | Input fields for Dictionary fields, filled by the user |
| `POPUP_TO_DECIDE_LIST` | A list of options to choose one or, with marking, several |
| `POPUP_WITH_TABLE` | A table of text lines |
| `C14Z_MESSAGES_SHOW_AS_POPUP` | One or more messages with their types |

## ✅ Best Practices

- Use `MODIF ID` groups + `LOOP AT SCREEN` for dynamic show/hide logic instead of hardcoding field names repeatedly, and make sure the group name matches on both sides.
- Put screen modification in `AT SELECTION-SCREEN OUTPUT`, never in `INITIALIZATION`.
- Keep the event blocks short and put the logic in a local class — [Rule 3.16](../docs/ABAP-Development-Rules.md#316-do-not-write-statements-the-abap-keyword-documentation-classifies-as-obsolete) and [Rule 5.1](../docs/ABAP-Development-Rules.md#51-write-new-logic-in-classes-wrap-function-modules-and-bapis).
- Declare `SELECT-OPTIONS ... FOR` with `DATA` work areas; keep `TABLES` for interface work areas such as `SSCRFIELDS`.
- Keep PBO modules lightweight (avoid DB calls where possible) — they run every time the screen is redrawn.
- Use `FIELD ... MODULE ... ON REQUEST` (or `ON CHAIN-REQUEST`) to avoid re-running expensive checks when a field hasn't changed.
- Validate individual fields in `AT SELECTION-SCREEN ON <field>` so the error is reported against the right input.
- Evaluate toolbar function keys through `sscrfields-ucomm`.
- Define a Dictionary search help when the same value help is needed on several screens.
- Keep list and popup texts in text symbols — [Rule 4.2](../docs/ABAP-Development-Rules.md#42-keep-user-facing-text-out-of-literals).
- Keep flow logic (SE51) and ABAP source mentally separate — they are edited in different places.

## ⚠️ Common Mistakes

- **Putting `LOOP AT SCREEN` in `INITIALIZATION`**, where it silently does nothing.
- **Pasting `PROCESS BEFORE OUTPUT` / `PROCESS AFTER INPUT` into the ABAP source.** They belong to the screen's flow logic.
- **Using ABAP SQL's `IN ( a, b )` value list in an ABAP `IF`.** Use `OR`, or a range table.
- **Reading `ON INPUT` as "changed".** It means "not initial"; `ON REQUEST` means "entered since PBO".
- Assigning to a select-option without `[]` — the name alone addresses the header line, not the table.
- Declaring the same `PARAMETERS`/`SELECT-OPTIONS` name twice.
- Using a numeric literal as a `RADIOBUTTON GROUP` or `MODIF ID` name instead of an identifier.
- Forgetting `OBLIGATORY` on mandatory selection fields, letting users submit incomplete input.
- Overusing hardcoded literal screen/field names — makes maintenance and Screen Painter changes brittle.
- Comparing a popup answer with a translated word instead of the documented answer code.

## 🎤 Interview & Review Checkpoints

- Explain the PBO/PAI cycle and when each module type runs.
- Explain where `LOOP AT SCREEN` has an effect and why `INITIALIZATION` is too early.
- Be ready to explain the difference between `PARAMETERS` and `SELECT-OPTIONS`, and what a `SELECT-OPTIONS` field expands to (a selection table with header line).
- Explain `MODIF ID` and `LOOP AT SCREEN` dynamic screen control.
- Explain the difference between `ON INPUT`, `ON REQUEST` and `ON CHAIN-REQUEST`.
- Explain how a table control writes changed rows back (`current_line`).
- Explain which parts of a dynpro live in the Screen Painter and which in the ABAP source.

## 🔗 Related Chapters

- [01-ABAP-Basics](../01-ABAP-Basics/README.md) — report event order
- [06-Loops](../06-Loops/README.md) — range tables produced by `SELECT-OPTIONS`
- [10-Objects](../10-Objects/README.md) — local classes for the screen logic
- [11-Classical-Reports](../11-Classical-Reports/README.md) — value help for file paths
- [13-ALV](../13-ALV/README.md) — editable lists as an alternative to table controls
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle of selection screens and dynpros
