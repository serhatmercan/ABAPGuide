"! Reserves stock of one material in one plant under a lock. Does not commit:
"! the caller owns the transaction.
CLASS zcl_zsm_<run>_reserver DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING lock TYPE REF TO zif_zsm_<run>_stock_lock.

    METHODS reserve
      IMPORTING material TYPE zsm_<run>_stock-material
                plant    TYPE zsm_<run>_stock-plant
                quantity TYPE i
      RAISING   zcx_zsm_<run>_locked
                zcx_zsm_<run>_no_stock.

  PRIVATE SECTION.
    DATA lock TYPE REF TO zif_zsm_<run>_stock_lock.
ENDCLASS.


CLASS zcl_zsm_<run>_reserver IMPLEMENTATION.
  METHOD constructor.
    me->lock = lock.
  ENDMETHOD.

  METHOD reserve.
    lock->lock( material = material
                plant    = plant ).

    TRY.
        SELECT SINGLE available, reserved FROM zsm_<run>_stock
          WHERE material = @material
            AND plant    = @plant
          INTO @DATA(stock).
        IF sy-subrc <> 0 OR stock-available - stock-reserved < quantity.
          RAISE EXCEPTION NEW zcx_zsm_<run>_no_stock( ).
        ENDIF.

        UPDATE zsm_<run>_stock SET reserved = reserved + @quantity
          WHERE material = @material
            AND plant    = @plant.

      CLEANUP.
        lock->unlock( material = material
                      plant    = plant ).
    ENDTRY.

    lock->unlock( material = material
                  plant    = plant ).
  ENDMETHOD.
ENDCLASS.
