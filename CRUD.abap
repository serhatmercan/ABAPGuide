" CUSTOM TABLE
DATA lt_data TYPE TABLE OF zsm_t_data.

" Append Data From Internal Table To Custom Table
APPEND LINES OF lt_data TO zsm_t_data.
COMMIT WORK AND WAIT.

" Delete Data From Internal Structure To Custom Table
DELETE zsm_t_data FROM ls_data.
COMMIT WORK AND WAIT.

" Delete Data From Internal Structure To Custom Table w/ Condition
DELETE FROM zsm_t_data WHERE name = 'Serhat'.
COMMIT WORK AND WAIT.

" Delete Data From Custom Tables w/ Condition
DELETE FROM zsm_t_data_01 WHERE name = 'Serhat'.
DELETE FROM zsm_t_data_02 WHERE name = 'Serhat'.

" Insert Data From Internal Table To Custom Table
INSERT zsm_t_data FROM TABLE lt_data.
COMMIT WORK AND WAIT.

" Insert Data From Internal Structure To Custom Table
INSERT zsm_t_data FROM ls_data.
COMMIT WORK AND WAIT.

" Modify Data From Internal Structure To Custom Table
MODIFY zsm_t_data FROM ls_data.
COMMIT WORK AND WAIT.

" Modify Data From Internal Table To Custom Table
CHECK lt_data[] IS NOT INITIAL.
MODIFY zsm_t_data FROM TABLE lt_data.
COMMIT WORK AND WAIT.

" Update Data From Internal Structure To Custom Table
UPDATE zsm_t_data FROM ls_data.
COMMIT WORK AND WAIT.

" Update Custom Table w/ Condition 
UPDATE zsm_t_data SET name = 'Serhat' WHERE vbeln = ls_data-vbeln AND posnr = ls_data-posnr.
COMMIT WORK AND WAIT.

" Update Custom Table w/ Multiple Custom Tables
UPDATE zsm_t_log SET  density       = is_ticket-density
                      volume_uom    = is_ticket-volume_uom
                      process       = '01'
                WHERE sns_number = is_ticket-sns_number.

" Update Data From Values To Custom Table
UPDATE zsm_t_data FROM @( VALUE #( customer      = iv_customer
                                   request_count = iv_request_count
                                   izonay_id     = lv_izonay_id ) ).
COMMIT WORK AND WAIT.

" INTERNAL TABLE

" Append Data From Internal Structure To Internal Table
APPEND ls_data TO lt_data.

" Delete Internal Table Data w/ Condition
DELETE lt_data WHERE value = ls_data-value.

" Delete Internal Table Data w/ Index
DELETE lt_data FROM 10.

" Modify Internal Table Data w/ Internal Structure
MODIFY lt_data FROM ls_data.

" Modify Internal Table Data w/ Multiple Internal Tables
MODIFY: zsm_t_data_01 FROM TABLE lt_data_01,
        zsm_t_data_02 FROM TABLE lt_data_02.

" Modify Internal Table Data w/ Values
MODIFY lt_data FROM VALUE #( order_no      = '1'
                             document_type = 'X' ) TRANSPORTING order_no document_type WHERE order_no IS INITIAL.

MODIFY lt_data FROM VALUE #( finish_date = sy-datum ) TRANSPORTING finish_date WHERE finish_date IS INITIAL.

" Move Corresponding From Custom Table To Internal Table
lt_data = CORRESPONDING #( zsm_t_data ).
