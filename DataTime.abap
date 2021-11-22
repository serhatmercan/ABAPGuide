" Convert String To Date Format
DATA(lv_format_date) = ls_data-ersda+0(4) && ls_data-ersda+5(2) && ls_data-ersda+8(2).
DATA(lv_format_date) = | { lv_date+6(2) }| && | . { lv_date+4(2) } | && | . { lv_date+0(4) } |.

" Date Definition
DATA: lv_date TYPE d VALUE '20180715',
      lv_date LIKE sy-datum.

" Time Definition
DATA: lv_time TYPE t VALUE '145330',
      lv_time LIKE sy-uzeit.