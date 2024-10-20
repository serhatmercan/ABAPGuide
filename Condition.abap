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

DATA(lv_status) = COND #( WHEN sy-datum LT lv_begin_date THEN 'EARLY'
                          WHEN sy-datum GT lv_end_date   THEN 'LATE'
                          ELSE 'OK' ).

DATA(lv_data) = COND #( WHEN lv_lgnum EQ lc_lgnum THEN lc_e1 
                        ELSE space ).

DATA(lv_status) = SWITCH char10( sy-msgty WHEN 'S' THEN 'SUCCESS'
                                          WHEN 'W' THEN 'OK'
                                          ELSE 'ERROR' ).

DATA(lv_status) = SWITCH #( sy-msgty WHEN 'S' THEN 'SUCCESS'
                                     ELSE 'ERROR' ).

" IF / ELSE
IF 'A' GT 'B'.

ELSEIF 'A' EQ 'B'.
    
ELSE.
    
ENDIF.