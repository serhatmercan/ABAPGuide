" Screen
CALL SELECTION-SCREEN 601 STARTING AT 40 8. 

SELECTION-SCREEN  BEGIN OF SCREEN 601 AS WINDOW.
SELECT-OPTIONS: s_datum FOR zrt270-datum DEFAULT sy-datum OBLIGATORY.
SELECT-OPTIONS: s_skopf FOR zrt270-skopf.
SELECTION-SCREEN SKIP.
SELECT-OPTIONS: s_uname FOR zrt270-uname.
SELECTION-SCREEN END OF SCREEN 601.

" Get Import Parameter
DATA(lv_client) = cl_demo_input=>request( ).

" Show
CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
  EXPORTING
    textline1 = 'Hello'.

" Show Internal Table
SELECT * FROM mara INTO TABLE @DATA(lt_data) UP TO 10 ROWS.

cl_demo_output=>display( lt_data ).