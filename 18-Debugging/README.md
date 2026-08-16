# 18 — Debugging, Messages, Logging & Exceptions

## 📖 Introduction

Robust ABAP programs communicate clearly with users (`MESSAGE`), handle errors gracefully (`TRY`/`CATCH`), and keep a trace of what happened (application log / custom log tables). This chapter also covers a few small but useful debugging/system-check utilities.

## 💬 MESSAGE Statement Variants

```abap
DATA et_return TYPE bapiret2_t.
DATA lv_message TYPE bapi_msg.

" Build a BAPIRET2-style message from the current sy-msg* fields
MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
        INTO lv_message.

et_return = VALUE #( ( type = 'E' id = 'ZSM_MSG' number = '001' message = lv_message ) ).

" Simple ad-hoc messages
MESSAGE 'An error occurred' TYPE 'E'.
MESSAGE 'The process completed successfully' TYPE 'I' DISPLAY LIKE 'S'.
MESSAGE TEXT-001 TYPE 'W'.
MESSAGE i001(zsm_msg).

" Capturing a message into a variable instead of displaying it
MESSAGE e002(zsm_msg) INTO lv_message.
MESSAGE e003(zsm_msg) WITH lv_value1 lv_value2 INTO lv_message.  " &1 &2 placeholders

" Building a return message directly with a string template
APPEND VALUE #( type = 'E' message = |Error occurred: { lv_text }| ) TO et_return.

" Merging one return table into another
APPEND LINES OF lt_return TO et_return.
```

### Acting on a Return Table

```abap
" Inside a loop over the documents being processed
LOOP AT lt_documents INTO DATA(ls_document).
  process_document( EXPORTING is_document = ls_document
                    IMPORTING et_return   = DATA(lt_return) ).

  DATA(lv_has_error) = xsdbool(    line_exists( lt_return[ type = 'E' ] )
                                OR line_exists( lt_return[ type = 'A' ] )
                                OR line_exists( lt_return[ type = 'X' ] ) ).

  APPEND LINES OF lt_return TO et_return.

  IF lv_has_error = abap_true.
    CONTINUE.               " skip this document, keep processing the rest
  ENDIF.

  APPEND ls_document TO lt_processed.
ENDLOOP.
```

> ⚠️ `CONTINUE` is only valid **inside** a loop (`LOOP`, `DO`, `WHILE`). Outside one, use `RETURN` to leave the current processing block, or restructure the condition. The transaction decision itself belongs to the caller — see [08 — SAP LUW](../08-Open-SQL/README.md#-sap-luw--transaction-ownership).

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
" A method is the modern form. Identifiers are alphanumeric plus underscore -
" characters such as '$' are not valid in an ABAP name.
CLASS lcl_message_collector DEFINITION.
  PUBLIC SECTION.
    METHODS add IMPORTING iv_type    TYPE bapiret2-type
                          iv_message TYPE bapi_msg
                CHANGING  ct_return  TYPE bapiret2_t.
ENDCLASS.

CLASS lcl_message_collector IMPLEMENTATION.
  METHOD add.
    APPEND VALUE #( type    = iv_type
                    message = iv_message ) TO ct_return.
  ENDMETHOD.
ENDCLASS.
```

### 🏷️ Message Classes

Message texts and numbers are maintained per **message class** (transaction `SE91`), so they can be translated and reused consistently:

```abap
" Message class ZSM_MSG, maintained in SE91. '&' marks a text placeholder.
REPORT zsm_report MESSAGE-ID zsm_msg.

MESSAGE i001.
```

### ⚙️ Propagating System Messages into a BAPIRET2 Table

A very common integration pattern: convert whatever the last statement's `sy-msg*` fields hold into a `BAPIRET2` row, so system and custom errors end up in one consistent return table.

```abap
CLASS lcl_message_collector DEFINITION.
  PUBLIC SECTION.
    METHODS add_system_message IMPORTING is_syst    TYPE syst
                                         iv_message TYPE bapi_msg OPTIONAL
                               CHANGING  ct_return  TYPE bapiret2_t.
ENDCLASS.

CLASS lcl_message_collector IMPLEMENTATION.
  METHOD add_system_message.
    DATA(ls_message) = VALUE bapiret2( id         = is_syst-msgid
                                       number     = is_syst-msgno
                                       type       = is_syst-msgty
                                       message_v1 = is_syst-msgv1
                                       message_v2 = is_syst-msgv2
                                       message_v3 = is_syst-msgv3
                                       message_v4 = is_syst-msgv4 ).

    ls_message-message = COND bapi_msg( WHEN iv_message IS NOT INITIAL
                                        THEN iv_message
                                        ELSE ls_message-message ).

    APPEND ls_message TO ct_return.
  ENDMETHOD.
ENDCLASS.

" Usage
DATA lt_messages TYPE bapiret2_t.

MESSAGE e007(zsm_msg) INTO DATA(lv_text).

NEW lcl_message_collector( )->add_system_message(
    EXPORTING is_syst    = syst
              iv_message = CONV #( lv_text )
    CHANGING  ct_return  = lt_messages ).
```

## 🧯 Exception Handling

ABAP has two error-handling mechanisms. **Classic exceptions** (`RAISE`, `EXCEPTIONS` in a `CALL FUNCTION`) are declared in the function module's interface in SE37 and mapped to `sy-subrc` at the call site — they are obsolete for new code but ubiquitous in existing code. **Class-based exceptions** (`RAISE EXCEPTION TYPE`, `TRY`/`CATCH`) carry a real object with a message, a cause chain and typed attributes, and are the current mechanism.

```abap
" Class-based exception handling.
" CATCH clauses are evaluated TOP-DOWN, so the MOST SPECIFIC class must come
" first. A superclass listed before its subclass makes the subclass CATCH
" unreachable - the compiler and the extended check both flag this.
TRY.
    lv_result = lv_dividend / lv_divisor.        " may raise CX_SY_ZERODIVIDE
    lv_number = CONV i( lv_character_input ).    " may raise CX_SY_CONVERSION_NO_NUMBER

  CATCH cx_sy_zerodivide INTO DATA(lx_zerodivide).
    " most specific first ...
    MESSAGE lx_zerodivide->get_text( ) TYPE 'E'.

  CATCH cx_sy_arithmetic_error INTO DATA(lx_arithmetic).
    " ... then its superclass
    MESSAGE lx_arithmetic->get_text( ) TYPE 'E'.

  CATCH cx_sy_conversion_no_number INTO DATA(lx_no_number).
    MESSAGE lx_no_number->get_text( ) TYPE 'E'.

  CATCH cx_sy_conversion_error INTO DATA(lx_conversion).
    " superclass of cx_sy_conversion_no_number - must come AFTER it
    MESSAGE lx_conversion->get_text( ) TYPE 'E'.
ENDTRY.
```

```abap
" Raising your own exception
IF lv_quantity <= 0.
  RAISE EXCEPTION TYPE zcx_invalid_quantity
    EXPORTING iv_quantity = lv_quantity.
ENDIF.
```

```abap
" Classic exceptions from a function module call (LEGACY, but everywhere).
" For a REMOTE call, always handle system_failure and communication_failure.
DATA lv_system_msg TYPE string.
DATA lv_comm_msg   TYPE string.

CALL FUNCTION 'ZSM_F_TEST' DESTINATION lv_destination
  EXPORTING  iv_organization_id    = iv_organization_id
  IMPORTING  et_person             = et_person
  EXCEPTIONS system_failure        = 1 MESSAGE lv_system_msg
             communication_failure = 2 MESSAGE lv_comm_msg
             OTHERS                = 3.

CASE sy-subrc.
  WHEN 0.
  WHEN 1.       MESSAGE lv_system_msg TYPE 'E'.
  WHEN 2.       MESSAGE lv_comm_msg   TYPE 'E'.
  WHEN OTHERS.  MESSAGE 'Remote call failed' TYPE 'E'.
ENDCASE.
```

> ⚠️ **Order `CATCH` clauses from most specific to most general.** `cx_sy_zerodivide` is a subclass of `cx_sy_arithmetic_error`; `cx_sy_conversion_no_number` and `cx_sy_conversion_overflow` are subclasses of `cx_sy_conversion_error`. Listing a superclass first makes every subclass handler below it dead code.

> ⚠️ **Do not reach for `CATCH cx_root` by default.** It catches programming errors as well as business ones, which turns a bug into a silently swallowed message. Catch the exceptions you can actually handle. A `cx_root` catch is defensible only at an **outermost boundary** — a job step, an RFC entry point, a request handler — where its job is to *log the failure and re-raise or terminate cleanly*, never to continue as if nothing happened.
> ```abap
> " Boundary handler - logs and re-raises, does not swallow
> TRY.
>     run_job( ).
>   CATCH cx_root INTO DATA(lx_unexpected).
>     log_failure( lx_unexpected ).
>     RAISE EXCEPTION lx_unexpected.
> ENDTRY.
> ```

## 📔 Simple Custom Logging Table

```abap
" TABLE ZSM_T_LOG
"   mandt    mandt
"   username uname
"   logdate  erdat
"   logtime  erzet

" Read
SELECT SINGLE username, logdate, logtime
  FROM zsm_t_log
  WHERE username = @sy-uname
  INTO @DATA(ls_log).

" Collect (the caller decides when to write and commit)
DATA lt_log TYPE TABLE OF zsm_t_log.

APPEND VALUE #( username = sy-uname
                logdate  = sy-datum
                logtime  = sy-uzeit ) TO lt_log.
```

> ⚠️ `INTO CORRESPONDING FIELDS OF @DATA(...)` is not valid — an inline declaration has no type to derive from in that form. Either declare the target explicitly, or list the columns and use a plain `INTO @DATA(...)` as above.

### Application Log (BAL)

For anything beyond a private audit trail, prefer SAP's standard **Application Log** over a custom Z-table: you get a display UI (`SLG1`), retention and deletion handling, and a consistent API.

- **Log objects and sub-objects** are defined in transaction `SLG0`, and logs are displayed with `SLG1`.
- The classic API is the **`BAL_*` function module family** — `BAL_LOG_CREATE` to open a log handle, `BAL_LOG_MSG_ADD` to add messages to it, and `BAL_DB_SAVE` to persist them.
- Newer releases also ship an **object-oriented API**, the `CL_BALI_*` classes (`CL_BALI_LOG` for the log itself, `CL_BALI_LOG_DB` for persistence, plus setter classes for messages, free text and exceptions). It is released for ABAP Cloud development and calls the same underlying mechanism.

> 📝 **NEEDS OFFICIAL VERIFICATION** — confirm which of the two APIs is available and released on your target release before choosing one. Check the exact class and function module signatures in SE24/SE37 rather than copying a signature from any guide, including this one.

## 🛠️ System/Environment Checks — and Why to Avoid Them

```abap
" ⚠️ ANTI-PATTERN - do not branch business logic on the system ID or client.
CASE sy-sysid.
  WHEN 'DEV'.
    " ... development-only behaviour ...
  WHEN 'PRD'.
    " ... production-only behaviour ...
ENDCASE.
```

> ⚠️ **Hardcoding system IDs or client numbers to switch behaviour is a transport hazard.** The code that runs in production is then *not* the code you tested in development, and the difference is invisible in the transport. It also breaks the moment a system is copied, renamed, or an extra client is added.
>
> Drive environment-specific behaviour from **configuration** instead — a Customizing table, a `TVARVC` variant variable, or a feature switch — so the same code path runs everywhere and only the data differs:
> ```abap
> SELECT SINGLE is_active
>   FROM zsm_t_feature
>   WHERE feature = 'EXTENDED_CHECK'
>   INTO @DATA(lv_feature_active).
>
> IF lv_feature_active = abap_true.
>   " ...
> ENDIF.
> ```

> ⚠️ **`CHECK` is not a general-purpose guard.** `CHECK <cond>` leaves the entire current processing block when the condition is **false**. A statement such as `CHECK sy-subrc <> 0 AND lt_data IS NOT INITIAL.` therefore exits on the *success* path, which is almost never what the author intended. Use `IF` when you want to branch, and reserve `CHECK` for genuinely skipping the current loop pass.

## ✅ Best Practices

- **Catch the specific exceptions you can handle.** Order `CATCH` clauses most-specific first. Use a `cx_root` catch only at an outermost boundary, and make it log and re-raise.
- Collect and log **all** messages, not just the first error, when processing bulk data (mass BAPI calls, batch jobs).
- Use message classes (SE91) instead of hardcoded literal text for anything user-facing or translatable.
- Prefer the SAP Application Log (`SLG0`/`SLG1` and the `BAL_*` or `CL_BALI_*` API) over ad-hoc Z-tables for anything beyond the simplest debugging trace.
- Propagate a caught exception's text with `lx_error->get_text( )` rather than inventing a new message.
- Drive environment-specific behaviour from Customizing, not from `sy-sysid` / `sy-mandt`.

## ⚠️ Common Mistakes

- Listing a superclass `CATCH` before its subclasses, making the subclass handlers unreachable.
- Reaching for `CATCH cx_root` as the default, which hides programming errors.
- Swallowing exceptions silently (`CATCH cx_root.` with an empty block) — always log or re-raise.
- Using `MESSAGE ... RAISING <exception>` without a corresponding `EXCEPTIONS` entry in the function's signature.
- Using `CHECK` where `IF` is meant, and inverting the error branch.
- Using `CONTINUE` outside a loop.
- Branching on hardcoded system IDs or client numbers.

## 🎤 Interview & Review Checkpoints

- Explain the difference between classic (`EXCEPTIONS`) and class-based (`TRY`/`CATCH`/`RAISE EXCEPTION`) error handling.
- Explain why `CATCH` order matters and how to determine it from the exception hierarchy.
- Argue both sides of catching `cx_root`, and say where it belongs.
- Know how to propagate a caught exception's message text (`lx_error->get_text( )`).
- Explain how you would log a mass-processing run so that every failed record is traceable afterwards.

## 🐞 Debugger — Scope Note

This chapter deliberately focuses on **messages, exceptions and logging**. Interactive debugging (breakpoints, watchpoints, `BREAK-POINT`, `ASSERT`, checkpoint groups in `SAAB`, debugging background and update-task processing, and the layer-aware debugger in ADT) is not covered here.

> ⚠️ One point worth stating even so: **debugging in a production system is a controlled, audited activity.** Changing a variable's value in the debugger ("debug and replace") requires elevated authorization and is logged, because it bypasses every application check. Treat production debug authorization as a privileged permission, not a convenience.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE91 | Maintain message classes |
| SLG0 | Define application log objects/sub-objects |
| SLG1 | Display application log |
| SAAB | Maintain checkpoint groups (assertions, breakpoints, logging) |
| ST22 | Analyze short dumps |
| `/h` | OK-code (not a transaction) — activates the ABAP Debugger from any screen |

## 🔗 Related Chapters

- [15-BAPIs](../15-BAPIs/README.md) — `BAPIRET2` return handling
- [19-Performance](../19-Performance/README.md)
