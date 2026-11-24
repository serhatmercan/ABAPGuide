INTERFACE zif_zsm_<run>_stock_lock PUBLIC.
  "! Locks the stock of one material in one plant for the current user.
  METHODS lock
    IMPORTING material TYPE zsm_<run>_stock-material
              plant    TYPE zsm_<run>_stock-plant
    RAISING   zcx_zsm_<run>_locked.
  "! Releases the lock set by lock.
  METHODS unlock
    IMPORTING material TYPE zsm_<run>_stock-material
              plant    TYPE zsm_<run>_stock-plant.
ENDINTERFACE.
