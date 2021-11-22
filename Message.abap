" Custom
MESSAGE ID 'ZSM' TYPE 'E' NUMBER '001' RAISING error.
MESSAGE ID 'ZSM' TYPE 'S' NUMBER '000' WITH lv_value ' has been created !' RAISING error.

" System
MESSAGE ID sy-msgid 
    TYPE sy-msgty 
    NUMBER sy-msgno 
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
    RAISING conversion_failed RAISING enqueue_failed.