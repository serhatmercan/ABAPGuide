# 18 — Debugging, Messages, Logging & Exceptions

## 📖 Introduction

Robust ABAP programs communicate clearly with users (`MESSAGE`), handle errors gracefully (`TRY`/`CATCH`), and keep a trace of what happened (application log / custom log tables). This chapter also covers a few small but useful debugging/system-check utilities.

## 💬 MESSAGE Statement Variants

```abap
" Build a BAPIRET2-style message from the current sy-msg* fields
DATA et_return TYPE bapiret2_t.
MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(es_message).
et_return = VALUE #( ( type = 'E' id = 'ZPP_000_MC' number = '001' message = es_message ) ).

" Checking for errors in a BAPIRET2-style return table
DATA(lv_has_error) = xsdbool(    line_exists( lt_return[ type = 'E' ] )
                              OR line_exists( lt_return[ type = 'A' ] )
                              OR line_exists( lt_return[ type = 'X' ] ) ).

IF lv_has_error = abap_true.
  " Rollback
  CONTINUE.
ELSE.
  " Commit & Work
ENDIF.

" Simple ad-hoc messages
MESSAGE 'Error Occurred!' TYPE 'E'.
MESSAGE 'The process has been completed successfully' TYPE 'I' DISPLAY LIKE 'S'.
MESSAGE TEXT-001 TYPE 'W'.
MESSAGE i001(zsm).
MESSAGE e002(zmp) INTO DATA(lv_message).
MESSAGE e003(zmp) WITH lv_value1 lv_value2 INTO DATA(lv_message). " &1 &2 placeholders
MESSAGE ID 'ZSM' TYPE 'E' NUMBER '001' RAISING error.
MESSAGE ID 'ZSM' TYPE 'S' NUMBER '000' WITH lv_value ' has been created!' RAISING error.

" Building a return message directly with a string template
et_return = VALUE #( ( type = 'E' message = |Error occurred: { lv_text }| ) ).

" Capturing a message into a variable instead of displaying it
DATA lv_message TYPE bapi_msg.

MESSAGE e018 INTO lv_message.
MESSAGE e019 WITH ls_request-kunnr INTO lv_message.

APPEND LINES OF lt_return TO et_return.
```

### 🔖 Message Types

| Type | Meaning | Typical Effect |
|---|---|---|
| `S` | Success | Shown in the status bar |
| `I` | Information | Shown as a popup (in dialog processing) |
| `W` | Warning | Shown as a popup, execution can usually continue |
| `E` | Error | Stops processing / requires user correction |
| `A` | Abort | Ends the current transaction |
| `X` | Exit / Exception | Short dump (used to signal a serious/unexpected error) |

### 📦 Reusable "Append Return Message" Helper

```abap
FORM append_return TABLES lt_messages STRUCTURE bapiret2
                   USING  VALUE($lv_message)
                          VALUE($lv_type).

  APPEND VALUE #( message = $lv_message
                  type    = $lv_type ) TO lt_messages.
ENDFORM.
```

### 🏷️ Message Classes

Message texts and numbers are maintained per **message class** (transaction `SE91`), so they can be translated and reused consistently:

```abap
" T-Code SE91, class ZSM, dynamic text placeholders &

REPORT zsm_report MESSAGE-ID zsm.

MESSAGE i001.
```

### 🖥️ Displaying a Collected Message Table

```abap
DATA it_messages TYPE bapiret2_t.

IF it_messages IS NOT INITIAL.
  cl_rmsl_message=>display( it_messages ).
ENDIF.
```

### ⚙️ Propagating System Messages into a BAPIRET2 Table

A very common integration pattern: convert whatever the last statement's `sy-msg*` fields hold into a `BAPIRET2` row, so all errors (system + custom) end up in one consistent return table.

```abap
DATA lv_message  TYPE string.
DATA lt_messages TYPE bapiret2_t.

MESSAGE e007(zsm_msg_001) INTO lv_message.
PERFORM add_system_messages_to_bapiret2 TABLES lt_messages
                                        USING  syst
                                               lv_message.

FORM add_system_messages_to_bapiret2 TABLES ct_messages TYPE bapiret2_t
                                     USING  is_syst     TYPE syst
                                            iv_message.

  DATA(ls_message) = VALUE bapiret2( id         = is_syst-msgid
                                     number     = is_syst-msgno
                                     type       = is_syst-msgty
                                     message_v1 = is_syst-msgv1
                                     message_v2 = is_syst-msgv2
                                     message_v3 = is_syst-msgv3
                                     message_v4 = is_syst-msgv4 ).

  ls_message-message = COND #( WHEN iv_message IS NOT INITIAL
                               THEN iv_message
                               ELSE ls_message-message ).

  APPEND ls_message TO ct_messages.
ENDFORM.
```

## 🧯 Exception Handling

```abap
" Classic (obsolete) exception declaration/usage — still seen in older FORM/FUNCTION code
EXCEPTIONS divided_by_zero.

RAISE divided_by_zero.

" Modern class-based exception handling
TRY.
    lv_open_specials *= -1.
    lv_production_amount = ceil( lv_amount ). " may raise CX_SY_ZERODIVIDE
    zcl_util=>set_media( iv_entity_name = 'Document' ).  " may raise /iwbep/cx_mgw_med_exception
  CATCH /iwbep/cx_mgw_med_exception.
  CATCH cx_sy_arithmetic_error INTO DATA(lv_arith_error).
  CATCH cx_sy_conversion_error INTO DATA(lv_conv_error).
  CATCH cx_sy_conversion_no_number INTO DATA(lv_no_conversion_no_number).
  CATCH cx_sy_conversion_overflow INTO DATA(lv_no_conversion_overflow).
  CATCH cx_sy_no_authority INTO DATA(lv_no_auth_error).
  CATCH cx_sy_itab_line_not_found INTO DATA(lv_line_not_found_error).
  CATCH cx_root INTO DATA(lv_root_error).
    MESSAGE 'Arithmetic error occurred while processing' TYPE 'E'.
    MESSAGE 'An unexpected error occurred while processing' TYPE 'E'.
    MESSAGE 'Internal table line not found error occurred while processing' TYPE 'E'.
ENDTRY.

" Exceptions raised by an RFC-enabled function module call
DATA(lv_exception_message) = VALUE /iwbep/mgw_bop_rfc_excep_text( ).

CALL FUNCTION 'ZSM_F_TEST'
  EXPORTING  iv_organization_id    = iv_organization_id
  IMPORTING  et_person             = et_table[]
  EXCEPTIONS system_failure        = 1000 MESSAGE lv_exception_message
             communication_failure = 1001 MESSAGE lv_exception_message
             OTHERS                = 1002.
```

> 💡 `CATCH cx_root` should always be the **last** `CATCH` clause — it's the base class of nearly all class-based exceptions, so listing it first would swallow more specific exceptions before they're handled properly.

## 📔 Simple Custom Logging Table

```abap
" TABLE ZSM_T_LOG
" mandt    mandt
" username uname
" logdate  erdat
" logtime  erzet

" Get Data
SELECT SINGLE *
  INTO CORRESPONDING FIELDS OF @DATA(ls_data)
  FROM zsm_t_log
  WHERE username = @sy-uname.

" Save Data
DATA lt_data TYPE TABLE OF zsm_t_log.

APPEND VALUE #( username = sy-uname
                logdate  = sy-datum
                logtime  = sy-uzeit ) TO lt_data.
```

> 📝 For anything beyond a simple audit trail, prefer SAP's standard **Application Log** (`cl_bal_logger`/transaction SLG1) over a custom Z-table — it gives you a UI, retention management, and consistent APIs for free.

## 🛠️ Small System/Environment Checks

```abap
" Check statement combining sy-subrc and a table emptiness check
CHECK sy-subrc <> 0 AND lt_data[] IS NOT INITIAL.

" Check system client
CASE sy-mandt.
  WHEN '100'.
  WHEN OTHERS.
ENDCASE.

" Check system ID
CASE sy-sysid.
  WHEN 'SED'.
  WHEN OTHERS.
ENDCASE.
```

## ✅ Best Practices

- Always provide a catch-all (`CATCH cx_root`) at the end of a `TRY`/`CATCH` block, in addition to specific exception classes, so unexpected errors don't crash the whole program.
- Collect and log **all** messages, not just the first error, when processing bulk data (mass BAPI calls, batch jobs).
- Use message classes (SE91) instead of hardcoded literal text for anything user-facing or translatable.
- Prefer the SAP Application Log (SLG1/`cl_bal_logger`) over ad-hoc Z-tables for anything beyond the simplest debugging trace.

## ⚠️ Common Mistakes

- Catching `cx_root` **before** more specific exception classes — unreachable code, since `cx_root` matches everything.
- Using `MESSAGE ... RAISING <exception>` without a corresponding `EXCEPTIONS` entry in the calling function's signature.
- Swallowing exceptions silently (`CATCH cx_root.` with an empty block) — always log or re-raise.

## 🎤 Interview Tips

- Explain the difference between classic (`EXCEPTIONS`) and class-based (`TRY`/`CATCH`/`RAISE EXCEPTION`) error handling.
- Be ready to explain why `cx_root` must be caught last.
- Know how to propagate a caught exception's message text (`lx_error->get_text( )`).

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE91 | Maintain message classes |
| SLG1 | Display application log |
| ST22 | Analyze short dumps |
| /h | Activate the ABAP Debugger from any screen |

## 🔗 Related Chapters

- [15-BAPIs](../15-BAPIs/README.md) — `BAPIRET2` return handling
- [19-Performance](../19-Performance/README.md)
