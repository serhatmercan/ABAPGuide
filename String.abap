" Definition
DATA(lv_name) = 'Serhat' .

" Check Letter
IF lt_data-waers+0(1) = 'A' OR lt_data-waers+0(1) = 'T'.
ENDIF.

" Concatenate
DATA(lv_full_name) = |My name is { lv_name }| && | , and surname is { lv_surname }| .
DATA(lv_link) = |{ lv_link }main/{ iv_company_code },{ iv_business_area }|.
DATA(lv_full_name) = |Serhat{ cl_abap_char_utilities=>newline }Mercan|.

" Condense
CONDENSE lv_full_name NO-GAPS.

" Contains
IF lv_data CP 'P*'.
ELSE.

" Length
DATA(lv_length) = strlen( lv_data ).

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

" Substring
DATA(lv_ltc_posid) = substring( val = <fs_incetive>-posid len = 3 off = strlen( <fs_incetive>-posid ) - 3 ). " Get Last 3 Characters

" Split
SPLIT lv_data AT '.' INTO TABLE DATA(lt_data).
SPLIT iv_slug AT '&&' INTO DATA(lv_material) DATA(lv_formkey) DATA(lv_filename) DATA(lv_maincolor) DATA(lv_subcolor).

" Translate
TRANSLATE <fs_MGTXT>-high  USING 'iİüÜöÖçÇşŞ'.