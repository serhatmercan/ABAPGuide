"! Composes the late-order mail for the order desk.
CLASS zcl_zsm_<run>_late_notice DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING sender TYPE REF TO zif_zsm_<run>_mail_sender
                setup  TYPE REF TO zif_zsm_<run>_mail_setup.

    METHODS notify
      IMPORTING order_id      TYPE string
                days_late     TYPE i
                customer_note TYPE string
      RAISING   zcx_zsm_<run>_mail_error.

  PRIVATE SECTION.
    DATA sender TYPE REF TO zif_zsm_<run>_mail_sender.
    DATA setup TYPE REF TO zif_zsm_<run>_mail_setup.

    METHODS html_body
      IMPORTING order_id      TYPE string
                days_late     TYPE i
                customer_note TYPE string
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_zsm_<run>_late_notice IMPLEMENTATION.
  METHOD constructor.
    me->sender = sender.
    me->setup = setup.
  ENDMETHOD.

  METHOD notify.
    IF days_late <= 0.
      RETURN.
    ENDIF.

    DATA(recipients) = setup->order_desk_recipients( ).
    IF recipients IS INITIAL.
      RAISE EXCEPTION NEW zcx_zsm_<run>_mail_error( ).
    ENDIF.

    sender->send( recipients = recipients
                  subject    = |Order { order_id } is { days_late } days late|
                  html_body  = html_body( order_id      = order_id
                                          days_late     = days_late
                                          customer_note = customer_note ) ).
  ENDMETHOD.

  METHOD html_body.
    " Every value is escaped: the note is typed by users and must stay text
    result = |<p>Order { escape( val = order_id format = cl_abap_format=>e_xss_ml ) }| &&
             | is { days_late } days late.</p>| &&
             |<p>Customer note: { escape( val = customer_note format = cl_abap_format=>e_xss_ml ) }</p>|.
  ENDMETHOD.
ENDCLASS.
