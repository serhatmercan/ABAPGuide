" Convert Data IN & OUT
DATA lv_no TYPE /scdl/dl_docno_int.

lv_in  = '12345'.
lv_out = '00000000000000000000000012345'.

DATA(lrd_in)  = NEW /scdl/dl_docno_int( CONV #( |{ lv_in ALPHA = IN }| ) ).
DATA(lrd_out) = NEW /scdl/dl_docno_int( CONV #( |{ lv_out ALPHA = OUT }| ) ). 

" ALPHA IN
lv_vbeln = |{ is_data-vbeln ALPHA = IN }|.

" Corresponding
lt_data = CORRESPONDING #( ls_deep-operations ).

" Corresponding w/ Mapping & Except
DATA(lt_mara) = CORRESPONDING tt_mara( lt_data MAPPING matnr = matnr ersda = ersda EXCEPT ernam ). 

" Append & Corresponding
lt_data[ sy-tabix ] = CORRESPONDING #( ls_sayim ).