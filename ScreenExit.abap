PROCESS BEFORE OUTPUT.
  MODULE status_0102.

PROCESS AFTER INPUT.
  FIELD qmel-zznakliye MODULE check_zznakliye.
  FIELD qmel-zznakliye MODULE get_yukek_text ON INPUT.
  MODULE user_command_0102.

MODULE status_0102 OUTPUT.
  LOOP AT SCREEN INTO DATA(ls_screen).
    IF ls_screen-name IN ('QMEL-ZZURT_KOD', 'QMEL-ZZNAKLIYE') AND sy-tcode IN ('QM03', 'IW23').
      ls_screen-input = 0.
      MODIFY SCREEN FROM ls_screen.
    ENDIF.
  ENDLOOP.
ENDMODULE.
