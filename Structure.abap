" Assign
DATA(ls_notifheader) = VALUE bapi2080_nothdri( short_text = iv_short_text
                                               reportedby = sy-uname ).

" Assign & Clear                                               
ls_sales_header = VALUE #( doc_type = likp-lfart
                           pmnttrms = 'M000' ).

" Convert                           
ls_table = CORRESPONDING #( ls_data ).