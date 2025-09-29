" Definition
DATA lr_charg TYPE RANGE OF lqua-charg.

" Definition & Declaration
DATA(lr_material) = VALUE rseloption( sign = 'I' option = 'EQ' ( low = ls_data-material ) ).

" Append
APPEND VALUE #( sign = 'I' option = 'EQ' low = iv_data high = iv_data ) TO lr_charg.

" Declaration - Single
lr_charg = VALUE #( ( sign = 'I' option = 'EQ' low = iv_data ) ).

" Declaration - Multi
lr_charg = VALUE #(  sign = 'I' option = 'EQ' ( low = iv_data1 ) ( low = iv_data2 ) ).

DATA(lr_order) = VALUE range_t_aufnr( sign = 'I' option = 'EQ' ( low = |{ ls_data-order_no ALPHA = IN }| ) ).

DATA(lr_matnr) = VALUE range_t_matnr( FOR ls_data IN lt_data ( low = ls_data-matnr sign = 'I' option = 'EQ' )
                                                             ( low = ls_data-value sign = 'I' option = 'EQ' ) ).

" Declaration - For
DATA lr_ref_key TYPE RANGE OF bkpf-awkey,

lr_ref_key  = VALUE #( FOR ls_alv IN ct_alv ( sign = 'I' option = 'EQ' low = ls_alv-vbeln_vf ) ).

SORT lr_ref_key ASCENDING BY low.
DELETE ADJACENT DUPLICATES FROM lr_ref_key COMPARING low.

" Implementation w/ Query
SELECT 'I' AS sing, 
       'EQ' AS option, 
       aufnr AS low, 
       @space AS high
  FROM zsm_t_aufnr 
  INTO TABLE @lr_aufnr.

" Standard
DATA lr_material TYPE /accgo/cas_tt_material.
DATA lr_werks    TYPE /accgo/cak_tt_plant_range.

" Types
TYPES ty_tt_charg TYPE RANGE OF lqua-charg.