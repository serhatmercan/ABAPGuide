" TABLE
mandt mandt
username uname
logdate erdat
logtime erzet

" Get Data
select single *
  into corresponding fields of @DATA(ls_data)
  FROM zsm_t_log
  WHERE username = @sy-uname.

" Save Data
DATA lt_data TYPE TABLE OF zsm_t_log.

APPEND VALUE #( username = sy-uname
                logdate  = sy-datum
                logtime  = sy-uzeit ) TO lt_data.

MODIFY zsm_t_log FROM TABLE lt_data.
COMMIT WORK AND WAIT.
