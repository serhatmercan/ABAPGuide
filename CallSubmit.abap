" Call Previous Screen's Data  
ASSIGN ('(SAPMV50A)XLIPS[]') TO FIELD-SYMBOL(<fs_xlips>).

IF <fs_xlips> IS ASSIGNED.
  DATA(lt_xlips) = <fs_xlips>.
ENDIF.

" Call Program
SUBMIT zsm_r_test VIA SELECTION-SCREEN AND RETURN.

" Call Program w/ Parameters
SUBMIT zsm_r_test
  AND RETURN
  WITH p_bukrs = ls_data-bukrs
  WITH p_gjahr = ls_data-gjahr
  WITH p_belnr = ls_data-belnr
  WITH rb_fat  = abap_true.

" Call Screen w/ Location
CALL SCREEN 0200 STARTING AT 50 10. 

" Call T-Code
CALL TRANSACTION 'ZSM_TCODE' AND SKIP FIRST SCREEN.

" Call T-Code => MM03
SET PARAMETER ID 'MAT' FIELD ls_data-matnr.
SET PARAMETER ID 'WRK' FIELD ls_data-werks.
SET PARAMETER ID 'MXX' FIELD 'D'.

CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN. 