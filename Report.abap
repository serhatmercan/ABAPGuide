TABLES: mara.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
    PARAMETERS: p_matnr TYPE mara-matnr OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  PERFORM init.

START-OF-SELECTION.

FORM init.
    " Get Initial Data
ENDFORM.