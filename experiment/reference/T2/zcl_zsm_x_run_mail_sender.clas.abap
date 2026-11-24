"! Sends HTML mails with the mail API. Does not commit: send_async starts at the
"! caller's COMMIT WORK, so the mail leaves only with the caller's transaction.
CLASS zcl_zsm_<run>_mail_sender DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_zsm_<run>_mail_sender.
ENDCLASS.


CLASS zcl_zsm_<run>_mail_sender IMPLEMENTATION.
  METHOD zif_zsm_<run>_mail_sender~send.
    TRY.
        DATA(message) = cl_bcs_mail_message=>create_instance( ).
        LOOP AT recipients INTO DATA(recipient).
          message->add_recipient( CONV #( recipient ) ).
        ENDLOOP.
        message->set_subject( CONV #( subject ) ).
        message->set_main( cl_bcs_mail_textpart=>create_text_html( html_body ) ).
        message->send_async( ).

      CATCH cx_bcs_mail INTO DATA(error).
        RAISE EXCEPTION NEW zcx_zsm_<run>_mail_error( previous = error ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
