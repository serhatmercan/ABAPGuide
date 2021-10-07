" BAPI Return Message
DATA lt_return TYPE bapiret2_t.

" Commit & Rollback
IF NOT line_exists( lt_return[ type = 'E' ] ).
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
ENDIF.