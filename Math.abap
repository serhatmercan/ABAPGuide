" Absolute
DATA lv_sayi TYPE p.

lv_sayi = abs( -3 ).

WRITE: / 'Absolute Value: ', lv_sayi.

" Definition
CONSTANTS lv_value TYPE p DECIMALS 1 VALUE '7.5'.
CONSTANTS lv_value TYPE i VALUE 5.

" Round
DATA(lv_round) = round( val = '5678.656' dec = 2 ).