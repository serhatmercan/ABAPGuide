" Check Statu
CHECK sy-subrc NE 0 AND lt_data[] IS NOT INITIAL.

" Check System ID
CASE sy-sysid.
    WHEN 'SED'.      
    WHEN OTHERS.
ENDCASE.

" Wait
WAIT UP TO 1 SECONDS.