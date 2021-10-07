LOOP AT lt_order REFERENCE INTO DATA(lr_order).
    CASE lr_order->property.
      WHEN 'OrderNo'.
        lr_order->property = 'ORDER_NO'.
    ENDCASE.
ENDLOOP.