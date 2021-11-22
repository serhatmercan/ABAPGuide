" Condense: Delete Space
CONDENSE lv_data. 

" Pack: Delete Zero To Variable
PACK lv_number TO lv_number. 

" Shift: Delete Beginning Zeros
SHIFT gs_data-row LEFT DELETING LEADING '0'.

" Unpack: Add Zero
UNPACK lv_vbeln TO lv_vbeln.
