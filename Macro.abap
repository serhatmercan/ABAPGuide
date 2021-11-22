" Macro - Definition
DEFINE printer.
  WRITE :/  'Hello', &1, &2.
END-OF-DEFINITION.

WRITE:/ 'Before Using Macro'.
printer 'ABAP' 'Macros'. 

" Macro - Changing
DEFINE conv_char.
  REPLACE ALL OCCURRENCES OF &1 IN &2 WITH &3.
  CONDENSE &2.
END-OF-DEFINITION. 

conv_char 'Ş' <fs_data>-value 'S'.

" Macro - Operator
DATA lv_result TYPE i.

DEFINE operation.
  lv_result = &1 &2 &3.
END-OF-DEFINITION.

operation 4 + 3.  " lv_result = 7
operation 2 ** 7. " lv_result = 128

WRITE lv_result.