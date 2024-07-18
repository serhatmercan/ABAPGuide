" Definition
DATA lr_charg TYPE RANGE OF lqua-charg.

APPEND VALUE #( sign = 'I' option = 'EQ' low = iv_data high = iv_data ) TO lr_charg.

DATA(lr_order) = VALUE range_t_aufnr( sign = 'I' option = 'EQ' ( low = |{ ls_data-order_no ALPHA = IN }| ) ).

DATA(lr_matnr) = VALUE range_t_matnr( FOR ls_data IN lt_data ( low = ls_data-matnr sign = 'I' option = 'EQ' )
                                                             ( low = ls_data-value sign = 'I' option = 'EQ' ) ).

" Implementation w/ Query
SELECT 'I' AS sing, 
       'EQ' AS option, 
       aufnr AS low, 
       @space AS high
  FROM zsm_t_aufnr 
  INTO TABLE @lr_aufnr.

" Standard
DATA lr_material TYPE /accgo/cas_tt_material.
DATA lr_werks TYPE /accgo/cak_tt_plant_range.