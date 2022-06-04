" Call Previous Screen's Data  
ASSIGN ('(SAPMV50A)XLIPS[]') TO FIELD-SYMBOL(<fs_xlips>).

IF <fs_xlips> IS NOT INITIAL.
  DATA lt_xlips TYPE TABLE OF lips.

  lt_xlips = <fs_xlips>.
ENDIF.

" Call Program
SUBMIT zsm_r_test VIA SELECTION-SCREEN AND RETURN.

" Call Program w/ Parameters
SUBMIT zsm_r_test
AND RETURN
WITH p_bukrs EQ ls_data-bukrs
WITH p_gjahr EQ ls_data-gjahr
WITH p_belnr EQ ls_data-belnr
WITH rb_fat  EQ abap_true.

" Call Screen w/ Location
CALL SCREEN 0200 STARTING AT 50 10. 

" Call T-Code
CALL TRANSACTION 'ZSM_TCODE' AND SKIP FIRST SCREEN.

" Call T-Code => MM03
SET PARAMETER ID 'MAT' FIELD ls_data-matnr.
SET PARAMETER ID 'WRK' FIELD ls_data-werks.
SET PARAMETER ID 'MXX' FIELD 'D'.

CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN. 