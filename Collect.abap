" Collect - 1 
DATA: BEGIN OF ty_collect,
        key(10) TYPE c,
        num1(2) TYPE n,
        num2    TYPE i,
      END OF ty_collect.

DATA: lt_table LIKE STANDARD TABLE OF ty_collect,
      ls_table LIKE LINE OF lt_table.

ls_table-key = 'First'.
ls_table-num1 = '20'.
ls_table-num2 = '30'.

COLLECT ls_table INTO lt_table.

ls_table-key = 'First'.
ls_table-num1 = '20'.
ls_table-num2 = '15'.

COLLECT d_collect INTO lt_table.

ls_table-key = 'Second'.
ls_table-num1 = '20'.
ls_table-num2 = '15'.

COLLECT ls_table INTO lt_table.

" Collect - 2
TABLES lt_data STRUCTURE ZSM_S_TEST OPTIONAL. 

LOOP AT it_lips INTO DATA(ls_lips).
   lt_data-matnr = ls_lips-matnr.
   lt_data-item = 1.
   COLLECT lt_data.
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

LOOP AT lt_vbfa INTO DATA(ls_vbfa).
  CLEAR lt_sum.

  IF ls_vbfa-uecha IS INITIAL.
    lt_sum-posnr = ls_vbfa-posnr.
  ELSE.
    lt_sum-posnr     = ls_vbfa-uecha.
    lt_sum-totalreel = 1.
  ENDIF.

   lt_sum-zzplaka   = ls_vbfa-zzplaka.
   lt_sum-matnr     = ls_vbfa-matnr.
   lt_sum-ntgew     = ls_vbfa-ntgew.
   lt_sum-brgew     = ls_vbfa-brgew.
   
   COLLECT lt_sum.
ENDLOOP.