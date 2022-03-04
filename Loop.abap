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

" Loop w/ Group By
DATA lt_group_data TYPE TABLE OF spfli.

SELECT *
  FROM spfli
  INTO TABLE @DATA(lt_data).

LOOP AT lt_data INTO DATA(ls_data)
  GROUP BY ( carrier = ls_data-carrid city_from = ls_data-cityfrom ) ASCENDING
  ASSIGNING FIELD-SYMBOL(<fs_data>).

  CLEAR lt_group_data.

  LOOP AT GROUP <fs_data> ASSIGNING FIELD-SYMBOL(<fsg_data>).
    lt_group_data = VALUE #( BASE lt_group_data ( <fsg_data> ) ).
  ENDLOOP.

  cl_demo_output=>write( lt_group_data ).

ENDLOOP.

cl_demo_output=>display( ).

" While
WHILE sy-index LT 3.
    WRITE sy-index.
ENDWHILE. 