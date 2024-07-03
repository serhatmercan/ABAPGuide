" Convert Data IN & OUT
DATA lv_no TYPE /scdl/dl_docno_int.

lv_in  = '12345'.
lv_out = '00000000000000000000000012345'.

DATA(lrd_in)  = NEW /scdl/dl_docno_int( CONV #( |{ lv_in ALPHA = IN }| ) ).
DATA(lrd_out) = NEW /scdl/dl_docno_int( CONV #( |{ lv_out ALPHA = OUT }| ) ). 

" ALPHA IN: Add Zero To Initial
DATA lv_vbeln TYPE char10.

lv_vbeln = |{ is_data-vbeln ALPHA = IN }|.

" ALPHA OUT: Remove Zero From Initial
lv_vbeln = |{ is_data-vbeln ALPHA = OUT }|.

" Append & Corresponding
lt_data[ sy-tabix ] = CORRESPONDING #( ls_sayim ).

" Base
e_viqmel = CORRESPONDING #( BASE ( e_viqmel ) ls_data ).

" Conversiton Date Time / Time Stamp to Datum
" Convert Time Stamp (20240524131025.8750000 -> 20240524) 
" UI: new Date() 
" GW: YYYYMMDD

DATA: lv_timestamp TYPE timestampl, 
      lv_datum     TYPE datum,
      lv_time      TYPE tims.

CONVERT DATE sy-datum TIME sy-uzeit INTO TIME STAMP lv_timestamp TIME ZONE sy-zonlo.      
CONVERT TIME STAMP lv_timestamp TIME ZONE sy-zonlo INTO DATE lv_datum TIME lv_time.

" Conversion w/ Data Type
DATA(lv_data) = CONV int4( ls_data-value ).
DATA(ls_data) = CORRESPONDING zsm_t_data( ls_xdata ).

" Conversion Float => IMRC_READG -> ESECOMPAVG
CALL FUNCTION 'C14W_NUMBER_CHAR_CONVERSION'
    EXPORTING
        i_float = lv_float
    IMPORTING
        e_dec   = lv_data.

" Conversion: Class
check_appointment(
  EXPORTING         
    iv_tc_no       = CONV #( ls_vbak-driver_tc )
    iv_vkorg       = ls_appointment-vkorg     
  IMPORTING
    ev_return_code = lv_return_code ).

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