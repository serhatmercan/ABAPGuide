" Definition
DATA lr_charg TYPE RANGE OF lqua-charg.

APPEND VALUE #( sign = 'I' option = 'EQ' low = iv_data high = iv_data ) TO lr_charg.

DATA(lr_matnr) = VALUE range_t_matnr( FOR ls_data IN lt_data ( low = ls_data-matnr sign = 'I' option = 'EQ' )
                                                             ( low = ls_data-value sign = 'I' option = 'EQ' ) ).