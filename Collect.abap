" Collect - 1 
DATA: BEGIN OF ty_collect,
        key(10) TYPE c,
        num1(2) TYPE n,
        num2    TYPE i,
      END OF ty_collect.
DATA lt_table TYPE TABLE OF ty_collect.

DATA(ls_table) = VALUE ty_collect( key = 'First' num1 = '20' num2 = 30 ).
COLLECT ls_table INTO lt_table.

ls_table = VALUE #( key = 'First' num1 = '20' num2 = 15 ).
COLLECT ls_table INTO lt_table.

ls_table = VALUE #( key = 'Second' num1 = '20' num2 = 15 ).
COLLECT ls_table INTO lt_table.

" Collect - 2
DATA lt_data TYPE TABLE OF zsm_s_test.

LOOP AT it_lips INTO DATA(ls_lips).
  DATA(lt_data_line) = VALUE zsm_s_test( matnr = ls_lips-matnr item = 1 ).
  COLLECT lt_data_line INTO lt_data.
ENDLOOP.

" Collect - 3
DATA: BEGIN OF lt_sum OCCURS 0,
        zzplaka   TYPE lips-zzplaka,
        matnr     TYPE matnr,
        posnr     TYPE posnr,
        ntgew     TYPE vbfa-ntgew,
        brgew     TYPE vbfa-brgew,
        totalreel TYPE int4,
      END OF lt_sum. 
DATA lt_sum TYPE TABLE OF ty_sum.

LOOP AT lt_vbfa INTO DATA(ls_vbfa).
  DATA(lt_sum_line) = VALUE ty_sum(
    zzplaka   = ls_vbfa-zzplaka
    matnr     = ls_vbfa-matnr
    posnr     = COND #( WHEN ls_vbfa-uecha IS INITIAL THEN ls_vbfa-posnr ELSE ls_vbfa-uecha )
    ntgew     = ls_vbfa-ntgew
    brgew     = ls_vbfa-brgew
    totalreel = COND #( WHEN ls_vbfa-uecha IS INITIAL THEN 0 ELSE 1 )
  ).

  COLLECT lt_sum_line INTO lt_sum.
ENDLOOP.