" TOP
DATA gt_bdctable TYPE TABLE OF bdcdata WITH EMPTY KEY.
DATA gt_messtab TYPE TABLE OF bdcmsgcoll WITH EMPTY KEY.

" FORM
CLEAR: gt_messtab.

PERFORM bdc_append USING 'SAPLMR1M' '6150' '' '' .
PERFORM bdc_append USING '' '' 'BDC_OKCODE' '/00' .
PERFORM bdc_append USING '' '' 'RBKP-BELNR' lv_belnr.
PERFORM bdc_append USING '' '' 'RBKP-GJAHR' lv_gjahr.

PERFORM bdc_append USING 'SAPLMR1M' '6000' '' ''.
PERFORM bdc_append USING '' '' 'BDC_OKCODE' '/EPPCH'.

CALL TRANSACTION 'MIR4' USING gt_bdctable UPDATE 'S' MODE 'E' MESSAGES INTO gt_messtab.

" PERFORM
FORM bdc_append USING program dynpro fieldname fieldvalue.
  DATA(ls_bdctable) = VALUE bdcdata(
    program  = COND #( WHEN fieldname IS INITIAL THEN program ELSE '' )
    dynpro   = COND #( WHEN fieldname IS INITIAL THEN dynpro ELSE '' )
    dynbegin = COND #( WHEN fieldname IS INITIAL THEN abap_true ELSE abap_false )
    fnam     = fieldname
    fval     = fieldvalue
  ).

  APPEND ls_bdctable TO gt_bdctable.
ENDFORM.