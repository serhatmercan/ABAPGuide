" Convert Import Parameters
CALL METHOD cl_cam_address_bcs=>create_internet_addres
  EXPORTING
    i_address_string = CONV #( gv_sender_email )
   RECEIVING
     result          = DATA(gr_sender).

