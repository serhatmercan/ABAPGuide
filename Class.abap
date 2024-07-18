" GLOBAL CLASS "
" Definition
START-OF-SELECTION.
  DATA(lo_class) = NEW zsm_cl_test( ).
  DATA(lv_sum) TYPE int4.
  DATA(lv_result) TYPE int4.

  " Instance Method        
  lo_class->sum_two_numbers(
    EXPORTING
      iv_first_number = 10
      iv_second_number = 20
    IMPORTING
      ev_sum = lv_sum
  ).

  " Static Method
  zsm_cl_test=>multipy_two_numbers(
    EXPORTING
      iv_first_number = 10
      iv_second_number = 20
    IMPORTING
      ev_result = lv_result
  ).

" LOCAL CLASS "                               
CLASS lcl_class DEFINITION.
  PUBLIC SECTION.
    DATA lv_public TYPE i.
    
    METHODS data_declaration.

  PROTECTED SECTION.
    DATA lv_protected TYPE i.

  PRIVATE SECTION.
    DATA lv_private TYPE i.
ENDCLASS.

CLASS lcl_class IMPLEMENTATION.
  METHOD data_declaration.
    lv_public = 1.
    lv_protected = 2.
    lv_private = 3.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_sub DEFINITION INHERITING FROM lcl_class.
  PUBLIC SECTION.
    METHODS data_redeclaration.

  PROTECTED SECTION.
  
  PRIVATE SECTION.
ENDCLASS.
  
CLASS lcl_sub IMPLEMENTATION.
  METHOD data_redeclaration.
    lv_public = 10.
    lv_protected = 20.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  DATA(lo_local_class) = NEW lcl_class( ).  

  lo_local_class->data_declaration( ).
  lo_local_class->lv_public.