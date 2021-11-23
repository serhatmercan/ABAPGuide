" Bapiret
DATA et_return TYPE TABLE OF bapiret2.
MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(es_message).
et_return = VALUE #( ( type = 'E' id = 'ZPP_000_MC' number = 001 message = es_message) ).

" Custom
MESSAGE ID 'ZSM' TYPE 'E' NUMBER '001' RAISING error.
MESSAGE ID 'ZSM' TYPE 'S' NUMBER '000' WITH lv_value ' has been created !' RAISING error.

" System
MESSAGE ID sy-msgid 
    TYPE sy-msgty 
    NUMBER sy-msgno 
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
    RAISING conversion_failed RAISING enqueue_failed.
