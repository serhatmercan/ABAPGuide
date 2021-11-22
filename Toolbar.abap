* Exclude Button From Toolbar
DATA lt_ucomm TYPE TABLE OF sy-ucomm.

APPEND '&REFR'    TO lt_ucomm.
APPEND '&DEGISIM' TO lt_ucomm.

SET PF-STATUS 'ZSTAN' EXCLUDING lt_ucomm. 