" CUSTOM TABLE

" Append Data From Internal Table To Custom Table
APPEND LINES OF lt_data TO zsm_t_data.
COMMIT WORK AND WAIT.

" Delete Data From Internal Structure To Custom Table
DELETE zsm_t_data FROM ls_data.
COMMIT WORK AND WAIT.

" Delete Data From Internal Structure To Custom Table w/ Condition
DELETE FROM zsm_t_data WHERE name EQ 'Serhat'.
COMMIT WORK AND WAIT.

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
MODIFY zsm_t_data FROM TABLE lt_data.
COMMIT WORK AND WAIT.

" Update Data From Internal Structure To Custom Table
UPDATE zsm_t_data FROM ls_data.
COMMIT WORK AND WAIT.

" Update Custom Table w/ Condition 
UPDATE zsm_t_data SET name EQ 'Serhat' WHERE vbeln EQ ls_data-vbeln AND posnr EQ ls_data-posnr.
COMMIT WORK AND WAIT.

" INTERNAL TABLE

" Append Data From Internal Structure To Internal Table
APPEND ls_data TO lt_data.  

" Delete Internal Table Data w/ Condition
DELETE lt_data WHERE value EQ ls_data-value.

" Delete Internal Table Data w/ Index
DELETE lt_data FROM 10.

" Modify Internal Table Data w/ Internal Structure
MODIFY lt_data FROM ls_data.

" Modify Internal Table Data w/ Values
MODIFY lt_data FROM VALUE #( order_no = '1' document_type = 'X' ) TRANSPORTING order_no document_type WHERE order_no IS INITIAL.

" Move Corresponding From Custom Table To Internal Table
MOVE-CORRESPONDING zsm_t_data TO lt_data. 