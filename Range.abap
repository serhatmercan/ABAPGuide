" Range Definition
DATA: lr_charg TYPE RANGE OF lqua-charg,
      r_charg  LIKE LINE OF lr_charg.

r_lenum = VALUE #( sign = 'I' option = 'CP' low = i_lenum ).
APPEND r_lenum TO lr_lenum .