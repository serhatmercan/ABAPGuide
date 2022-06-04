" Definition
DATA(lv_name) = 'Serhat' .

" Check Letter
lt_data-waers(1) EQ 'A' OR lt_data-waers(1) EQ 'T'.

" Concatenate
DATA(lv_full_name) = | My name is { lv_name }| && | , and surname is { 'Mercan' } | .

" Condense
CONDENSE lv_full_name NO-GAPS.

" Contains
IF lv_data CP 'P*'.
ELSE.

" Length
DATA: length TYPE i. 
length = strlen( lv_data ).

" Lower & Upper Case
DATA lv_line(10) VALUE 'serhat'.

TRANSLATE lv_line TO UPPER CASE.
TRANSLATE lv_line TO LOWER CASE.

DATA(lv_line_upper) = |{ lv_line CASE = (cl_abap_format=>c_upper) }|.
DATA(lv_line_lower) = |{ lv_line CASE = (cl_abap_format=>c_lower) }|.

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
SPLIT iv_slug AT '&&' INTO DATA(lv_material) DATA(lv_formkey) DATA(lv_filename) DATA(lv_maincolor) DATA(lv_subcolor).