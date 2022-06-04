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

" Add System Messages To Bapiret2
DATA: lv_message  TYPE string,
      lt_messages TYPE BAPIRET2_T.

MESSAGE e007(zsm_msg_001) INTO lv_message.
PERFORM add_system_messages_to_bapiret2 TABLES lt_messages
                                        USING syst
                                              lv_message.

FORM add_system_messages_to_bapiret2 TABLES ct_messages TYPE bapiret2_t
                                     USING is_syst TYPE syst
                                           iv_message.

DATA(ls_message) = VALUE bapiret2( id         = is_syst-msgid 
                                   number     = is_syst-msgno             
                                   type       = is_syst-msgty
                                   message_v1 = is_syst-msgv1
                                   message_v2 = is_syst-msgv2
                                   message_v3 = is_syst-msgv3
                                   message_v4 = is_syst-msgv4
                                   ).

ls_message-message = COND #( WHEN iv_message IS NOT INITIAL THEN iv_message 
                                                            ELSE |{ is_syst-msgv1 }| && space && | { is_syst-msgv2  } | && space && | { is_syst-msgv3  } | && space && | { is_syst-msgv4  } | ).     

APPEND ls_message TO ct_messages[].

ENDFORM.