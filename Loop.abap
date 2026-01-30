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
LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<fs_data>) WHERE value IS NOT INITIAL.
  AT NEW row.        
  ENDAT.
  
  CASE <fs_data>-value.
    WHEN '03'.
      CLEAR <fs_data>.
  ENDCASE.
ENDLOOP.

" Loop w/ From-To 
LOOP AT lt_data REFERENCE INTO DATA(ls_data) FROM 1 TO ls_attribute-size.
  APPEND VALUE #( name = ls_data->name ) TO lt_tags.
  CLEAR ls_data->name.
ENDLOOP.

" Loop w/ Group By
DATA(lt_group_data) = VALUE spfli_tab( ).

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

" Loop w/ Group By & Parameters
TYPES: BEGIN OF ty_s_invoive,
        vbeln_vf TYPE vbeln_vf,
       END OF ty_s_invoive.

DATA: ls_invoice TYPE ty_s_invoive,
      lt_invoice TYPE TABLE OF ty_s_invoive.

LOOP AT gt_alv INTO DATA(ls_alv) GROUP BY ( vbeln_vf = ls_alv-vbeln_vf size = GROUP SIZE index = GROUP INDEX )
                                  ASCENDING WITHOUT MEMBERS
                                  REFERENCE INTO DATA(ls_group).                      
  ls_invoice-vbeln_vf = ls_group->vbeln_vf.
  APPEND ls_invoice TO lt_invoice.
ENDLOOP.

" While
WHILE sy-index LT 3.
    WRITE sy-index.
ENDWHILE.