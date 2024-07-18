" Macro - Definition
DEFINE printer.
  WRITE :/  'Hello', &1, &2.
END-OF-DEFINITION.

WRITE:/ 'Before Using Macro'.
printer 'ABAP' 'Macros'. 

" Macro - BAPI
DATA: ls_header_in  LIKE bapisdhd1,  " SD Document Header
      ls_header_inx LIKE bapisdhd1x. " SD Document Header Checkbox

DEFINE gx.
  &1-&2 = &3.
  &1x-&2 = abap_true.
END-OF-DEFINITION.

gx: ls_header_in doc_type  'ZI00',
    ls_header_in sales_org '1200'.

WRITE: ls_header_in-doc_type, ls_header_inx-doc_type.

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