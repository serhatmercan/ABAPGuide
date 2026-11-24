INTERFACE zif_zsm_<run>_mail_setup PUBLIC.
  "! Mail addresses of the order desk.
  METHODS order_desk_recipients
    RETURNING VALUE(result) TYPE string_table.
ENDINTERFACE.
