" TOP
DATA BEGIN OF gt_bdctable OCCURS 0. 
     INCLUDE STRUCTURE bdcdata.
DATA END OF gt_bdctable.

DATA BEGIN OF gt_messtab OCCURS 0.
     INCLUDE STRUCTURE bdcmsgcoll.
DATA END OF gt_messtab. 

" FORM
CLEAR: gt_messtab, gt_messtab[].

PERFORM bdc_append USING 'SAPLMR1M' '6150' '' '' .
PERFORM bdc_append USING '' '' 'BDC_OKCODE' '/00' .
PERFORM bdc_append USING '' '' 'RBKP-BELNR' lv_belnr.
PERFORM bdc_append USING '' '' 'RBKP-GJAHR' lv_gjahr.

PERFORM bdc_append USING 'SAPLMR1M' '6000' '' ''.
PERFORM bdc_append USING '' '' 'BDC_OKCODE' '/EPPCH'.

CALL TRANSACTION 'MIR4' USING gt_bdctable UPDATE 'S' MODE 'E'  MESSAGES INTO gt_messtab. 

" PERFORM
FORM bdc_append USING program dynpro fname fvalue.
  CLEAR gt_bdctable.

  IF fname EQ space.
    gt_bdctable-program  = program.
    gt_bdctable-dynpro   = dynpro.
    gt_bdctable-dynbegin = abap_true.
  ELSE.
    gt_bdctable-fnam     = fname.
    gt_bdctable-fval     = fvalue.
  ENDIF.

  APPEND gt_bdctable.
ENDFORM.   