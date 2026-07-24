" Case
CASE sy-uname.
  WHEN 'X'.
  WHEN 'Y'.
  WHEN OTHERS.
ENDCASE.

" Check Data
CHECK NOT line_exists( et_return[ type = 'E' ] ).

" IF / ELSE Condition
DATA(lv_begin_date) = '20200505'.
DATA(lv_end_date)   = '20200515'.

DATA(lv_status) = COND #( WHEN sy-datum < lv_begin_date THEN 'EARLY'
                          WHEN sy-datum > lv_end_date   THEN 'LATE'
                          ELSE                               'OK' ).

DATA(lv_data) = COND #( WHEN lv_lgnum = lc_lgnum
                        THEN lc_e1
                        ELSE space ).

DATA(lv_check)      = COND #( WHEN lv_confirmation_no BETWEEN 50 AND 100 THEN abap_true ELSE abap_false ).
DATA(lv_confidence) = COND #( WHEN lv_confidence CS 'good' OR lv_confidence = 'uncertain'
                              THEN abap_true
                              ELSE abap_false ).

DATA(lv_refinery) = CONV char3( COND #( WHEN is_defect->refinery = '1000' THEN 'ONE'
                                        WHEN is_defect->refinery = '1100' THEN 'TWO'
                                        WHEN is_defect->refinery = '1200' THEN 'THR' ) ).

DATA(lv_status) = SWITCH char10( sy-msgty
                                 WHEN 'S' THEN 'SUCCESS'
                                 WHEN 'W' THEN 'OK'
                                 ELSE          'ERROR' ).

DATA(lv_status) = SWITCH #( sy-msgty WHEN 'S' THEN 'SUCCESS' ELSE 'ERROR' ).

" IF / ELSE
IF 'A' > 'B'.

ELSEIF 'A' = 'B'.

ELSE.

ENDIF.
