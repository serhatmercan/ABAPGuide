"! Acceptance test for task T2. Sender and setup are doubles, so no mail is sent.
CLASS lth_sender DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_zsm_x<run>_mail_sender.

    DATA fail TYPE abap_bool.
    DATA calls TYPE i READ-ONLY.
    DATA sent_recipients TYPE string_table READ-ONLY.
    DATA sent_subject TYPE string READ-ONLY.
    DATA sent_body TYPE string READ-ONLY.
ENDCLASS.


CLASS lth_sender IMPLEMENTATION.
  METHOD zif_zsm_x<run>_mail_sender~send.
    calls += 1.
    IF fail = abap_true.
      RAISE EXCEPTION NEW zcx_zsm_x<run>_mail_error( ).
    ENDIF.
    sent_recipients = recipients.
    sent_subject = subject.
    sent_body = html_body.
  ENDMETHOD.
ENDCLASS.


CLASS lth_setup DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_zsm_x<run>_mail_setup.

    DATA recipients TYPE string_table.
ENDCLASS.


CLASS lth_setup IMPLEMENTATION.
  METHOD zif_zsm_x<run>_mail_setup~order_desk_recipients.
    result = recipients.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_acceptance DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA sender TYPE REF TO lth_sender.
    DATA mail_setup TYPE REF TO lth_setup.
    DATA cut TYPE REF TO zcl_zsm_x<run>_late_notice.

    METHODS setup.
    METHODS sends_to_the_order_desk FOR TESTING RAISING cx_static_check.
    METHODS subject_names_order_and_days FOR TESTING RAISING cx_static_check.
    METHODS body_names_order_and_days FOR TESTING RAISING cx_static_check.
    METHODS note_is_text_not_markup FOR TESTING RAISING cx_static_check.
    METHODS no_mail_when_not_late FOR TESTING RAISING cx_static_check.
    METHODS no_recipients_fails FOR TESTING.
    METHODS sender_error_reaches_caller FOR TESTING.
ENDCLASS.


CLASS ltc_acceptance IMPLEMENTATION.
  METHOD setup.
    sender = NEW #( ).
    mail_setup = NEW #( ).
    mail_setup->recipients = VALUE #( ( `desk1@example.com` ) ( `desk2@example.com` ) ).
    cut = NEW #( sender = sender
                 setup  = mail_setup ).
  ENDMETHOD.

  METHOD sends_to_the_order_desk.
    cut->notify( order_id = `4711` days_late = 3 customer_note = `Please hurry` ).

    cl_abap_unit_assert=>assert_equals( act = sender->calls exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = sender->sent_recipients
                                        exp = mail_setup->recipients ).
  ENDMETHOD.

  METHOD subject_names_order_and_days.
    cut->notify( order_id = `4711` days_late = 3 customer_note = `Please hurry` ).

    cl_abap_unit_assert=>assert_equals( act = sender->sent_subject
                                        exp = `Order 4711 is 3 days late` ).
  ENDMETHOD.

  METHOD body_names_order_and_days.
    cut->notify( order_id = `4711` days_late = 3 customer_note = `Please hurry` ).

    cl_abap_unit_assert=>assert_char_cp( act = sender->sent_body exp = `*4711*` ).
    cl_abap_unit_assert=>assert_char_cp( act = sender->sent_body exp = `*3*` ).
    " Escaping may also write a space as a character reference, so only the words are compared
    cl_abap_unit_assert=>assert_char_cp( act = sender->sent_body exp = `*Please*hurry*` ).
  ENDMETHOD.

  METHOD note_is_text_not_markup.
    cut->notify( order_id = `4711` days_late = 3 customer_note = `<b>Rush</b> & "now"` ).

    " Only the note is checked (K21): markup the class adds to its own template is not
    " asserted. The note's tags must not reach the body as tags, and the note must appear
    " with < and > escaped. Any valid escaping counts: a named, decimal or hexadecimal
    " character reference; "/" may stay as it is or be escaped as well.
    " ABAP runs PCRE in extended mode, so # is escaped
    DATA(body) = to_lower( sender->sent_body ).
    cl_abap_unit_assert=>assert_equals( act = find( val = body sub = `<b>rush` )
                                        exp = -1
                                        msg = 'The note''s opening tag must not appear as markup' ).
    cl_abap_unit_assert=>assert_equals( act = find( val = body sub = `rush</b>` )
                                        exp = -1
                                        msg = 'The note''s closing tag must not appear as markup' ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( find( val  = body
                           pcre = `(&lt;|&\#x0*3c;|&\#0*60;)b(&gt;|&\#x0*3e;|&\#0*62;)rush`
                               && `(&lt;|&\#x0*3c;|&\#0*60;)(/|&sol;|&\#x0*2f;|&\#0*47;)b(&gt;|&\#x0*3e;|&\#0*62;)` ) >= 0 )
      msg = 'The note must appear as escaped text' ).
  ENDMETHOD.

  METHOD no_mail_when_not_late.
    cut->notify( order_id = `4711` days_late = 0 customer_note = `` ).
    cut->notify( order_id = `4712` days_late = -2 customer_note = `` ).

    cl_abap_unit_assert=>assert_equals( act = sender->calls exp = 0 ).
  ENDMETHOD.

  METHOD no_recipients_fails.
    CLEAR mail_setup->recipients.

    TRY.
        cut->notify( order_id = `4711` days_late = 3 customer_note = `` ).
        cl_abap_unit_assert=>fail( msg = 'Without recipients the notice must fail' ).
      CATCH zcx_zsm_x<run>_mail_error.
        cl_abap_unit_assert=>assert_equals( act = sender->calls exp = 0 ).
    ENDTRY.
  ENDMETHOD.

  METHOD sender_error_reaches_caller.
    sender->fail = abap_true.

    TRY.
        cut->notify( order_id = `4711` days_late = 3 customer_note = `` ).
        cl_abap_unit_assert=>fail( msg = 'A sender error must reach the caller' ).
      CATCH zcx_zsm_x<run>_mail_error.
        " expected
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
