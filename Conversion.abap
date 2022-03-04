" Convert Data IN & OUT
DATA lv_no TYPE /scdl/dl_docno_int.

lv_in  = '12345'.
lv_out = '00000000000000000000000012345'.

DATA(lrd_in)  = NEW /scdl/dl_docno_int( CONV #( |{ lv_in ALPHA = IN }| ) ).
DATA(lrd_out) = NEW /scdl/dl_docno_int( CONV #( |{ lv_out ALPHA = OUT }| ) ). 

" ALPHA IN
lv_vbeln = |{ is_data-vbeln ALPHA = IN }|.

" Append & Corresponding
lt_data[ sy-tabix ] = CORRESPONDING #( ls_sayim ).

" Base
e_viqmel = CORRESPONDING #( BASE ( e_viqmel ) ls_data ).

" Conversion w/ Data Type
DATA(lv_data) = CONV int4( ls_data-value ).

" Conversion Float => IMRC_READG -> ESECOMPAVG
CALL FUNCTION 'C14W_NUMBER_CHAR_CONVERSION'
    EXPORTING
        i_float = lv_float
    IMPORTING
        e_dec   = lv_data.

" Corresponding
lt_data = CORRESPONDING #( ls_deep-operations ).

" Corresponding w/ Mapping & Except
DATA(lt_mara) = CORRESPONDING tt_mara( lt_data MAPPING matnr = matnr ersda = ersda EXCEPT ernam ). 

" Function
CALL FUNCTION 'ZSM_F_FUNCTION'
    EXPORTING
        iv_matnr = CONV lv_vbeln( parameters[ name = 'VBELN' ]-value )
    IMPORTING
        ev_flag  = DATA(lv_flag).