" Import & Export (Standard)
IMPORT mem_likp FROM MEMORY ID 'MEM_LIKP'.
EXPORT mem_likp TO MEMORY ID 'MEM_LIKP'.

" Read Data From Memory (Custom)
DATA et_alv TYPE zsd_tt_0061. 

FREE MEMORY ID 'ZSD_P_0001'.

CLEAR et_alv[].  

SUBMIT zsd_p_0001
  WITH cb_epdk EQ cb_epdk
  WITH s_vkorg IN it_vkorg
  WITH p_ihrack EQ i_ihrack
  WITH p_export EQ 'X'
  AND RETURN.

IMPORT et_alv FROM MEMORY ID 'ZSD_P_0001'.

FREE MEMORY ID 'ZSD_P_0001'.

" Send Data To Memory (Custom)
EXPORT et_alv TO MEMORY ID 'ZSD_P_0001'.