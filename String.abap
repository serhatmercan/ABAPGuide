" Definition
DATA(lv_name) = 'Serhat' .

" Check Letter
lt_data-waers(1) EQ 'A' OR lt_data-waers(1) EQ 'T'.

" Concatenate
DATA(lv_full_name) = | My name is { lv_name }| && | , and surname is { 'Mercan' } | .

" Length
DATA: length TYPE i. 
length = strlen( lv_data ).

" Lower & Upper Case
DATA lv_line(10) VALUE 'serhat'.

TRANSLATE lv_line TO UPPER CASE.
TRANSLATE lv_line TO LOWER CASE.

" Replace
REPLACE ALL OCCURRENCES OF REGEX 'A' IN TABLE lt_data WITH 'aaaaa'.
REPLACE ALL OCCURRENCES OF '.' IN lt_data-value WITH space.
REPLACE ',' WITH '.' INTO lt_data.

" Search
SEARCH surname FOR 'Serhat   '.
SEARCH surname FOR 'Ser*'.
SEARCH surname FOR '*can'.
WRITE: / 'Searching for "Serhat    "',
       / 'sy-subrc:', sy-subrc, / 'sy-fdpos:', sy-fdpos.

" Single Quote
DATA line(20) TYPE c.
CONCATENATE 'You''' 'll be there.' INTO line.

" Split
SPLIT lv_data AT '.' INTO TABLE DATA(lt_data).