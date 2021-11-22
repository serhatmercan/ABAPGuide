" Do
DO 10 TIMES.
    SELECT SINGLE * 
    FROM aufk
     INTO DATA(ls_aufk)
     WHERE aufnr EQ gt_data-aufnr.
  
    IF sy-subrc EQ 0.
       UPDATE aufk FROM ls_aufk.
       EXIT.
    ENDIF.
ENDDO. 

" Loop
LOOP AT lt_data WHERE value IS NOT INITIAL.
    AT NEW row.        
    ENDAT.
    
    CASE lt_data-value.
      WHEN '03'.
        CLEAR ls_data.
    ENDCASE.
ENDLOOP.

" While
WHILE sy-index LT 3.
    WRITE sy-index.
ENDWHILE. 