" Definition
DATA(lv_name) = 'Serhat' .

" Concatenate
DATA(lv_full_name) = | My name is { lv_name }| && | , and surname is { 'Mercan' } | .

" Split
SPLIT lv_data AT '.' INTO TABLE DATA(lt_data).