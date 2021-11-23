" Absolute
DATA lv_sayi TYPE p.

lv_sayi = abs( -3 ).

WRITE: / 'Absolute Value: ', lv_sayi.

" Ceil -> Up Integer Number
ceil( '7.15' ). " => 8

" Definition
CONSTANTS lv_value TYPE p DECIMALS 1 VALUE '7.5'.
CONSTANTS lv_value TYPE i VALUE 5.

" Floor -> Down Integer Number
floor( '7.95' ). " => 7   

" Round
DATA(lv_round) = round( val = '5678.656' dec = 2 ).