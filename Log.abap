" TABLE
MANDT	    MANDT
USERNAME	UNAME
LOGDATE	    ERDAT
LOGTIME	    ERZET

" Get Data
SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF es_data
    FROM zsm_t_log
    WHERE username EQ sy-uname.

" Save Data
DATA lt_data TYPE TABLE OF zsm_t_log.

APPEND VALUE #( username = sy-uname
                logdate  = sy-datum
                logtime  = sy-uzeit ) TO lt_data.

MODIFY zsm_t_log FROM TABLE lt_data.
COMMIT WORK AND WAIT.