" Export & Return
DATA(lv_surname) = zsm_cl_test=>get_surname( EXPORTING iv_name = 'SERHAT' CHANGING cr_data = 'X' IMPORTING et_select_option = DATA(lv_key) ).