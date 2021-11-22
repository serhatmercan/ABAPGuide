PROCESS BEFORE OUTPUT.
  MODULE status_0102.
 
PROCESS AFTER INPUT.
  FIELD qmel-zznakliye MODULE check_zznakliye.
  FIELD qmel-zznakliye MODULE get_yukek_text ON INPUT.
  MODULE user_command_0102. 
 
MODULE status_0102 OUTPUT.
  LOOP AT SCREEN .
    IF screen-name EQ 'QMEL-ZZURT_KOD' OR screen-name EQ 'QMEL-ZZNAKLIYE'.
        IF sy-tcode EQ 'QM03' OR sy-tcode EQ 'IW23'.
            screen-input = 0.
            MODIFY SCREEN.
        ENDIF.
    ENDIF.
  ENDLOOP.
ENDMODULE.     