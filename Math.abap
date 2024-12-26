" Definition
CONSTANTS lv_value TYPE p DECIMALS 1 VALUE '7.5'.
CONSTANTS lv_value TYPE i VALUE 5.

" Absolute
DATA(lv_absolute) = abs( -3 ).                      " => 3

" Ceil -> Up Integer Number
DATA(lv_ceil) = ceil( '7.15' ).                     " => 8

" Floor -> Down Integer Number
DATA(lv_floor) = floor( '7.95' ).                   " => 7   

" Floor -> Constant 2 Decimal
DATA: lv_value  TYPE p DECIMALS 4 VALUE '7896.6579',
      lv_result TYPE p DECIMALS 2.

lv_result = lv_value * 100.
lv_result = floor( lv_result ) / 100.               " => 7896.65

" Random
DATA(lv_seed) = sy-timlo.
DATA(lo_random) = cl_abap_random_int=>create( EXPORTING seed = lv_seed min = 1 max = 9999 ).
DATA(lv_random) = lo_random->get_next( ).

" Round
DATA(lv_round) = round( val = '5678.656' dec = 2 ). " => 5678.66