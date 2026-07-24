" Bapiret
DATA et_return TYPE bapiret2_t.
MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(es_message).
et_return = VALUE #( ( type = 'E' id = 'ZPP_000_MC' number = '001' message = es_message ) ).

" Check
DATA(lv_has_error) = xsdbool(    line_exists( lt_return[ type = 'E' ] )
                              OR line_exists( lt_return[ type = 'A' ] )
                              OR line_exists( lt_return[ type = 'X' ] ) ).

IF lv_has_error = abap_true.
  " Rollback
  CONTINUE.
ELSE.
  " Commit & Work
ENDIF.

" Custom
" TODO: check spelling: Occured (typo) -> Occurred (ABAP cleaner)
MESSAGE 'Error Occured !' TYPE 'E'.
MESSAGE 'The process has been completed successfully' TYPE 'I' DISPLAY LIKE 'S'.
MESSAGE TEXT-001 TYPE 'W'.
MESSAGE i001(zsm).
MESSAGE e002(zmp) INTO DATA(lv_message).
MESSAGE e003(zmp) WITH lv_value1 lv_value2 INTO DATA(lv_message). " &1 &2 Parameters
MESSAGE ID 'ZSM' TYPE 'E' NUMBER '001' RAISING error.
MESSAGE ID 'ZSM' TYPE 'S' NUMBER '000' WITH lv_value ' has been created !' RAISING error.

" Default
et_return = VALUE #( ( type = 'E' message = |Error occurred: { lv_text }| ) ).

" Message
DATA lv_message TYPE bapi_msg.

MESSAGE e018 INTO lv_message.
MESSAGE e019 WITH ls_request-kunnr INTO lv_message.

APPEND LINES OF lt_return TO et_return.

" Form
FORM append_return TABLES lt_messages        STRUCTURE bapiret2
                   USING  VALUE($lv_message)
                          VALUE($lv_type).

  APPEND VALUE #( message = $lv_message
                  type    = $lv_type ) TO lt_messages.
ENDFORM.

" Message Class
t-Code se91
Class zsm
Dynamic &

" Message Class w/ Report
REPORT zsm_report MESSAGE-ID zsm.

MESSAGE i001.

" Show
DATA it_messages TYPE bapiret2_t.

IF it_messages IS NOT INITIAL.
  cl_rmsl_message=>display( it_messages ).
ENDIF.

" System
MESSAGE ID sy-msgid
    TYPE sy-msgty
    NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
    raising conversion_failed RAISING enqueue_failed.

" Add System Messages To Bapiret2
DATA lv_message  TYPE string.
DATA lt_messages TYPE bapiret2_t.

MESSAGE e007(zsm_msg_001) INTO lv_message.
PERFORM add_system_messages_to_bapiret2 TABLES lt_messages
                                        USING  syst
                                               lv_message.

FORM add_system_messages_to_bapiret2 TABLES ct_messages TYPE bapiret2_t
                                     USING  is_syst     TYPE syst
                                            iv_message.

  DATA(ls_message) = VALUE bapiret2( id         = is_syst-msgid
                                     number     = is_syst-msgno
                                     type       = is_syst-msgty
                                     message_v1 = is_syst-msgv1
                                     message_v2 = is_syst-msgv2
                                     message_v3 = is_syst-msgv3
                                     message_v4 = is_syst-msgv4 ).

  ls_message-message = COND #( WHEN iv_message IS NOT INITIAL
                               THEN iv_message
                               ELSE |{ is_syst-msgv1 }{ space } { is_syst-msgv2  } { space } { is_syst-msgv3  } { space } { is_syst-msgv4  } | ).

  APPEND ls_message TO ct_messages.
ENDFORM.

" Add System Messages To Bapiret2 II
DATA lt_messages TYPE bapiret2_t.

me->add_message_tab( CHANGING ct_messages = lt_messages ).

" | [<-->] CT_MESSAGES TYPE BAPIRET2_T
METHOD add_message_tab.
  DATA ls_message TYPE bapiret2.

  CALL FUNCTION 'FS_BAPI_BAPIRET2_FILL'
    EXPORTING type   = sy-msgty
              cl     = sy-msgid
              number = sy-msgno
              par1   = sy-msgv1
              par2   = sy-msgv2
              par3   = sy-msgv3
              par4   = sy-msgv4
    IMPORTING return = ls_message.

  COLLECT ls_message INTO ct_messages.
ENDMETHOD.
