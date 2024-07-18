" Definition
CONSTANTS lv_value TYPE p DECIMALS 1 VALUE '7.5'.
CONSTANTS lv_value TYPE i VALUE 5.

" Absolute
DATA(lv_absolute) = abs( -3 ).                      " => 3

" Ceil -> Up Integer Number
DATA(lv_ceil) = ceil( '7.15' ).                     " => 8

" Floor -> Down Integer Number
DATA(lv_floor) = floor( '7.95' ).                   " => 7   

" Round
DATA(lv_round) = round( val = '5678.656' dec = 2 ). " => 5678.66