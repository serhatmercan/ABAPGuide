INTERFACE zif_zsm_<run>_mail_sender PUBLIC.
  "! Sends one HTML mail to all recipients.
  METHODS send
    IMPORTING recipients TYPE string_table
              subject    TYPE string
              html_body  TYPE string
    RAISING   zcx_zsm_<run>_mail_error.
ENDINTERFACE.
