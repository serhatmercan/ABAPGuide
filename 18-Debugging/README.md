# 18 — Messages, Exceptions & Logging

> **Lifecycle:** `CURRENT / RECOMMENDED`. Messages from message classes, class-based exceptions and the application log are current. Classic exceptions are `CLASSIC BUT STILL RELEVANT` and labelled where they appear. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

Robust ABAP programs communicate clearly with users (`MESSAGE`), handle errors gracefully (`TRY`/`CATCH`), and keep a trace of what happened (application log / custom log tables). The design rules are in [section 6 of the rule set](../docs/ABAP-Development-Rules.md#6-error-handling); this chapter shows the statements and patterns. Interactive debugging is outside its scope (see the scope note at the end), although the folder keeps its historical name.

## 💬 MESSAGE Statement Variants

> 📝 **Contextual snippet** — `zsm_msg` is the placeholder message class; `first_value` and `second_value` are assumed. `MESSAGE` statements belong to the UI layer ([Rule 6.11](../docs/ABAP-Development-Rules.md#611-use-message-statements-only-in-the-ui-layer)).

```abap
" From a message class: translatable, with the placeholders &1 ... &4
MESSAGE i001(zsm_msg).
MESSAGE e003(zsm_msg) WITH first_value second_value.

" Same behaviour as type S, shown with the error icon
MESSAGE s004(zsm_msg) DISPLAY LIKE 'E'.

" Into a variable instead of displaying it; the sy-msg* fields are set as well.
" The variable is unused on purpose: the INTO form keeps the message findable (Rule 11.5)
MESSAGE e002(zsm_msg) INTO DATA(message_text) ##NEEDED.

" The message that the sy-msg* fields currently describe, e.g. after a function module call
MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
        INTO message_text.

" A text symbol works too, but has no message number to search for or to log
MESSAGE TEXT-001 TYPE 'W'.
```

> 💡 Keep user-facing texts in a message class (transaction `SE91`), not in literals — they can be translated and found again by number ([Rule 4.2](../docs/ABAP-Development-Rules.md#42-keep-user-facing-text-out-of-literals)). `DISPLAY LIKE` changes only the icon; the message keeps the behaviour of its own type.

> 📝 A program can name a default message class: after `REPORT zsm_r_order_overview MESSAGE-ID zsm_msg.`, a statement such as `MESSAGE i001.` needs no class in parentheses.

### 🔖 Message Types

According to the ABAP Keyword Documentation, the effect depends on where the message is sent:

| Type | In dialog processing | In a background job |
|---|---|---|
| `S` | Status bar of the next screen; processing continues | Written to the job log; processing continues |
| `I` | Dialog box; processing continues after confirmation | Job log; processing continues |
| `W` | Status bar; at PAI, processing stops until the user confirms. In reporting events such as `START-OF-SELECTION` it acts like `E` | Job log; processing continues |
| `E` | At PAI, the screen is shown again for correction with the message in the status bar. In `START-OF-SELECTION` the program ends | Job log; the job is terminated (unless the caller handles it as `error_message`) |
| `A` | Dialog box; the program ends with a database rollback | Job log; the job is terminated with a database rollback |
| `X` | Runtime error `MESSAGE_TYPE_X` | Runtime error |

In `PBO` and `INITIALIZATION` the documentation converts some types: `I` and `W` are shown like `S`, and `E` like `A`. A user setting can show `E`, `W` and `S` in a dialog box.

### Acting on a Return Table

> 📝 **Contextual snippet** — `documents`, `processed_documents`, `return_messages` and the method `process_document` are assumed.

```abap
" Inside a loop over the documents being processed
LOOP AT documents INTO DATA(document).
  process_document( EXPORTING document        = document
                    IMPORTING return_messages = DATA(document_messages) ).

  DATA(has_error) = xsdbool(    line_exists( document_messages[ type = 'E' ] )
                             OR line_exists( document_messages[ type = 'A' ] )
                             OR line_exists( document_messages[ type = 'X' ] ) ).

  APPEND LINES OF document_messages TO return_messages.

  IF has_error = abap_true.
    CONTINUE.               " skip this document, keep processing the rest
  ENDIF.

  APPEND document TO processed_documents.
ENDLOOP.
```

> ⚠️ `CONTINUE` is only valid **inside** a loop (`LOOP`, `DO`, `WHILE`). Outside one, use `RETURN` to leave the current processing block, or restructure the condition. The transaction decision itself belongs to the caller — see [08 — SAP LUW](../08-Open-SQL/README.md#-sap-luw--transaction-ownership).

> 📝 A mass run collects messages per document like this so that every failed record stays traceable. At the boundary of a single business operation, the messages become an exception instead ([Rule 6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary)).

### 📦 Collecting Messages

A small collector keeps the messages of a run in one `BAPIRET2` table, with message class, number and variables, so they can be translated, logged and searched. The collector owns the table instead of passing it around as a `CHANGING` parameter ([Rule 5.10](../docs/ABAP-Development-Rules.md#510-avoid-changing-parameters)).

> 📝 **Contextual snippet** — a local class of the program that runs the mass processing.

```abap
CLASS lcl_message_collector DEFINITION FINAL.
  PUBLIC SECTION.
    " Adds the message that the sy-msg* fields currently describe
    METHODS add_current_message.
    METHODS messages RETURNING VALUE(result) TYPE bapiret2_t.

  PRIVATE SECTION.
    DATA collected TYPE bapiret2_t.
ENDCLASS.


CLASS lcl_message_collector IMPLEMENTATION.
  METHOD add_current_message.
    " The text comes from the message class, in the logon language
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            INTO DATA(text).

    APPEND VALUE #( type       = sy-msgty
                    id         = sy-msgid
                    number     = sy-msgno
                    message    = text
                    message_v1 = sy-msgv1
                    message_v2 = sy-msgv2
                    message_v3 = sy-msgv3
                    message_v4 = sy-msgv4 ) TO collected.
  ENDMETHOD.

  METHOD messages.
    result = collected.
  ENDMETHOD.
ENDCLASS.
```

> 💡 Return messages as `BAPIRET2` lines with message class and number, not as a structure of your own with concatenated text. A concatenated sentence cannot be translated, and nobody can search for it.

### 🧲 Messages from a Called Function Module

A function module that sends a message with `MESSAGE` would end the caller's processing. The predefined exception `error_message` turns such a message into a return code instead:

> 📝 **Contextual snippet** — `ZSM_FM_CHECK_ORDER` is a placeholder function module; `order_id` and the collector from above are assumed.

```abap
CALL FUNCTION 'ZSM_FM_CHECK_ORDER'
  EXPORTING
    order_id      = order_id
  EXCEPTIONS
    error_message = 1
    OTHERS        = 2.
IF sy-subrc <> 0.
  " sy-msgid ... sy-msgv4 describe the message the function module sent
  collector->add_current_message( ).
ENDIF.
```

According to the ABAP Keyword Documentation:

- **`E` and `A` messages** raise `error_message` and fill the `sy-msg*` fields; an `A` message also triggers a `ROLLBACK WORK`. This includes messages from modules the function module calls in turn, within the same internal session.
- **`S`, `I` and `W` messages** are not sent (in background processing they are written to the log).
- **`X` messages** still end in a runtime error.

> 📝 Inside a function module or method with classic exceptions, `MESSAGE … RAISING exception` combines both mechanisms: if the caller handles the exception, no message is sent, and the `sy-msg*` fields describe it; otherwise the message is sent as usual.

## 🧯 Exception Handling

ABAP has two error-handling mechanisms. **Class-based exceptions** (`RAISE EXCEPTION`, `TRY`/`CATCH`) carry a real object with a message, a cause chain and typed attributes, and are the current mechanism ([Rule 6.1](../docs/ABAP-Development-Rules.md#61-use-class-based-exceptions-in-new-code)).

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` for **classic exceptions** (`EXCEPTIONS` in a function module interface, `RAISE`, `MESSAGE … RAISING`, mapped to `sy-subrc` at the call site). The ABAP Keyword Documentation says they should no longer be defined in new developments; they remain at every call of an existing function module, and RFC supports only them. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-classic-but-still-relevant).

> 📝 **Contextual snippet** — a UI-layer program; `dividend`, `divisor`, `result`, `number` and `character_input` are assumed.

```abap
" Class-based exception handling.
" CATCH clauses are evaluated TOP-DOWN, so the MOST SPECIFIC class must come
" first; the ABAP Keyword Documentation requires subclasses before superclasses.
TRY.
    result = dividend / divisor.           " may raise CX_SY_ZERODIVIDE
    number = CONV i( character_input ).    " may raise CX_SY_CONVERSION_NO_NUMBER

  CATCH cx_sy_zerodivide INTO DATA(zero_divide).
    " most specific first ...
    MESSAGE zero_divide->get_text( ) TYPE 'E'.

  CATCH cx_sy_arithmetic_error INTO DATA(arithmetic_error).
    " ... then its superclass
    MESSAGE arithmetic_error->get_text( ) TYPE 'E'.

  CATCH cx_sy_conversion_no_number INTO DATA(no_number).
    MESSAGE no_number->get_text( ) TYPE 'E'.

  CATCH cx_sy_conversion_error INTO DATA(conversion_error).
    " superclass of cx_sy_conversion_no_number - must come AFTER it
    MESSAGE conversion_error->get_text( ) TYPE 'E'.
ENDTRY.
```

**Raising your own exception** — from a class in your own hierarchy ([Rule 6.2](../docs/ABAP-Development-Rules.md#62-build-your-own-exception-hierarchy-below-zcx_zsm_)), in the category that matches what the caller can do ([Rule 6.3](../docs/ABAP-Development-Rules.md#63-choose-the-exception-category-by-what-the-caller-can-do)), with a T100 text ([Rules 6.4](../docs/ABAP-Development-Rules.md#64-take-exception-texts-from-a-message-class-through-the-t100-interfaces) and [6.5](../docs/ABAP-Development-Rules.md#65-raise-with-raise-exception-new-use-raise-exception-type--message-to-attach-a-t100-message)):

> 📝 **Contextual snippet** — `zcx_zsm_invalid_quantity` is a placeholder exception class with the constructor parameter `quantity` and T100 texts from `zsm_msg`; `quantity` and `quantity_text` are assumed.

```abap
" The class defines its own text
IF quantity <= 0.
  RAISE EXCEPTION NEW zcx_zsm_invalid_quantity( quantity = quantity ).
ENDIF.

" The caller chooses the message
IF quantity <= 0.
  RAISE EXCEPTION TYPE zcx_zsm_invalid_quantity
    MESSAGE e010(zsm_msg) WITH quantity.
ENDIF.

" Converting a technical exception keeps it as PREVIOUS (Rule 6.8)
TRY.
    quantity = CONV #( quantity_text ).
  CATCH cx_sy_conversion_error INTO DATA(conversion_failure).
    RAISE EXCEPTION NEW zcx_zsm_invalid_quantity( quantity = quantity
                                                  previous = conversion_failure ).
ENDTRY.
```

**Classic exceptions of a remote function module call** — handled once, at the boundary, and turned into a class-based exception ([Rule 6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary)):

> 📝 **Contextual snippet** — `ZSM_FM_READ_PERSONS` is a placeholder RFC-enabled function module; `zcx_zsm_remote_call_failed` is a placeholder exception class with the attribute `remote_text`; `destination`, `organization_id` and `persons` are assumed.

```abap
" For a REMOTE call, always handle system_failure and communication_failure.
DATA system_message        TYPE c LENGTH 255.
DATA communication_message TYPE c LENGTH 255.

CALL FUNCTION 'ZSM_FM_READ_PERSONS' DESTINATION destination
  EXPORTING  organization_id       = organization_id
  IMPORTING  persons               = persons
  EXCEPTIONS system_failure        = 1 MESSAGE system_message
             communication_failure = 2 MESSAGE communication_message
             OTHERS                = 3.

CASE sy-subrc.
  WHEN 0.
  WHEN 1.
    RAISE EXCEPTION TYPE zcx_zsm_remote_call_failed
      MESSAGE e031(zsm_msg) WITH destination
      EXPORTING remote_text = system_message.
  WHEN 2.
    RAISE EXCEPTION TYPE zcx_zsm_remote_call_failed
      MESSAGE e032(zsm_msg) WITH destination
      EXPORTING remote_text = communication_message.
  WHEN OTHERS.
    RAISE EXCEPTION TYPE zcx_zsm_remote_call_failed
      MESSAGE e033(zsm_msg) WITH destination.
ENDCASE.
```

> ⚠️ **Order `CATCH` clauses from most specific to most general.** `cx_sy_zerodivide` is a subclass of `cx_sy_arithmetic_error`; `cx_sy_conversion_no_number` and `cx_sy_conversion_overflow` are subclasses of `cx_sy_conversion_error`. Listing a superclass first makes every subclass handler below it dead code.

> ⚠️ **Do not reach for `CATCH cx_root` by default.** It catches programming errors as well as business ones, which turns a bug into a silently swallowed message. Catch the exceptions you can actually handle ([Rule 6.6](../docs/ABAP-Development-Rules.md#66-catch-specific-exceptions)). A `cx_root` catch is defensible only at an **outermost boundary** — a job step, an RFC entry point, a request handler — where its job is to *log the failure and re-raise or terminate cleanly*, never to continue as if nothing happened.
> ```abap
> " Boundary handler - logs and re-raises, does not swallow
> TRY.
>     run_job( ).
>   CATCH cx_root INTO DATA(unexpected_error).
>     log_failure( unexpected_error ).
>     RAISE EXCEPTION unexpected_error.
> ENDTRY.
> ```

> ⚠️ **Never leave a `CATCH` block empty.** Handle, convert or log the error ([Rule 6.7](../docs/ABAP-Development-Rules.md#67-never-leave-a-catch-block-empty)), and do not use exceptions for normal control flow ([Rule 6.10](../docs/ABAP-Development-Rules.md#610-do-not-use-exceptions-for-normal-control-flow)).

## 📔 Simple Custom Logging Table

> 📝 **Contextual snippet** — `zsm_t_log` is a placeholder table with the fields shown in the comment. Log what support needs, not more ([Rule 8.8](../docs/ABAP-Development-Rules.md#88-log-no-secrets-and-no-personal-data-beyond-what-the-purpose-needs)).

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
  INTO @DATA(log_entry).

" Collect (the caller decides when to write and commit)
DATA log_entries TYPE TABLE OF zsm_t_log.

APPEND VALUE #( username = sy-uname
                logdate  = sy-datum
                logtime  = sy-uzeit ) TO log_entries.
```

> ⚠️ `INTO CORRESPONDING FIELDS OF @DATA(...)` is not valid — according to the ABAP Keyword Documentation, `CORRESPONDING FIELDS OF` cannot be combined with an inline declaration. Either declare the target explicitly, or list the columns and use a plain `INTO @DATA(...)` as above.

### Application Log (BAL)

For anything beyond a private audit trail, prefer SAP's standard **Application Log** over a custom Z-table: you get a display UI (`SLG1`), retention and deletion handling, and a consistent API.

- **Log objects and sub-objects** are defined in transaction `SLG0`, and logs are displayed with `SLG1`.
- The classic API is the **`BAL_*` function module family** — `BAL_LOG_CREATE` to open a log handle (header `I_S_LOG`, handle `E_LOG_HANDLE`), `BAL_LOG_MSG_ADD` to add messages to it (`I_LOG_HANDLE`, `I_S_MSG`), and `BAL_DB_SAVE` to persist them (`I_T_LOG_HANDLE`).
- Newer releases also ship an **object-oriented API**, the `CL_BALI_*` classes (`CL_BALI_LOG` for the log itself, `CL_BALI_LOG_DB` for persistence, plus setter classes for messages, free text and exceptions). The list of released APIs in the ABAP Keyword Documentation shows `CL_BALI_LOG` and `CL_BALI_LOG_DB` as released for ABAP for Cloud Development. A log is created with `cl_bali_log=>create( )` or `create_with_header( )`, filled with `add_item( )` or `add_messages_from_bapirettab( )`, and saved with `cl_bali_log_db=>get_instance( )->save_log( log = … )`; the methods raise `CX_BALI_RUNTIME`.

> ⚠️ **VERSION-DEPENDENT: the `CL_BALI_*` API.** Whether it exists depends on the release; check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) and the released-objects list of your system.

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
>   INTO @DATA(feature_active).
>
> IF feature_active = abap_true.
>   " ...
> ENDIF.
> ```

> ⚠️ **`CHECK` is not a general-purpose guard.** `CHECK <cond>` leaves the current processing block when the condition is **false** (inside a loop, it skips to the next pass). A statement such as `CHECK sy-subrc <> 0 AND data IS NOT INITIAL.` therefore exits on the *success* path, which is almost never what the author intended. Use `CHECK` only as an input check at the start of a method, and `IF … RETURN` or `IF … CONTINUE` everywhere else ([Rule 3.17](../docs/ABAP-Development-Rules.md#317-use-check-only-as-an-input-check-at-the-start-of-a-method-prefer-if--return)).

## ✅ Best Practices

- **Catch the specific exceptions you can handle.** Order `CATCH` clauses most-specific first. Use a `cx_root` catch only at an outermost boundary, and make it log and re-raise — [Rule 6.6](../docs/ABAP-Development-Rules.md#66-catch-specific-exceptions).
- Raise class-based exceptions from your own hierarchy with T100 texts, and keep the cause as `previous` when converting — [Rules 6.2](../docs/ABAP-Development-Rules.md#62-build-your-own-exception-hierarchy-below-zcx_zsm_)–[6.5](../docs/ABAP-Development-Rules.md#65-raise-with-raise-exception-new-use-raise-exception-type--message-to-attach-a-t100-message) and [6.8](../docs/ABAP-Development-Rules.md#68-keep-the-cause-when-converting-an-exception-pass-it-as-previous).
- Turn `sy-subrc`, classic exceptions and return tables into exceptions once, at the boundary — [Rule 6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary).
- Send `MESSAGE` statements only from the UI layer — [Rule 6.11](../docs/ABAP-Development-Rules.md#611-use-message-statements-only-in-the-ui-layer).
- Collect and log **all** messages, not just the first error, when processing bulk data (mass BAPI calls, batch jobs).
- Use message classes (SE91) instead of hardcoded literal text for anything user-facing or translatable — [Rule 4.2](../docs/ABAP-Development-Rules.md#42-keep-user-facing-text-out-of-literals).
- Prefer the SAP Application Log (`SLG0`/`SLG1` and the `BAL_*` or `CL_BALI_*` API) over ad-hoc Z-tables for anything beyond the simplest debugging trace.
- Propagate a caught exception's text with `error->get_text( )` rather than inventing a new message.
- Drive environment-specific behaviour from Customizing, not from `sy-sysid` / `sy-mandt`.

## ⚠️ Common Mistakes

- Listing a superclass `CATCH` before its subclasses, making the subclass handlers unreachable.
- Reaching for `CATCH cx_root` as the default, which hides programming errors.
- Swallowing exceptions silently (`CATCH cx_root.` with an empty block) — always log or re-raise.
- Using `MESSAGE ... RAISING <exception>` without a corresponding `EXCEPTIONS` entry in the function's signature.
- Expecting a `W` message to appear in a dialog box, or to let `START-OF-SELECTION` continue — it appears in the status bar, and in reporting events it acts like `E`.
- Calling a function module that sends `E` messages without `error_message`, so its message ends the caller's processing.
- Using `CHECK` where `IF` is meant, and inverting the error branch.
- Using `CONTINUE` outside a loop.
- Branching on hardcoded system IDs or client numbers.

## 🎤 Interview & Review Checkpoints

- Explain the difference between classic (`EXCEPTIONS`) and class-based (`TRY`/`CATCH`/`RAISE EXCEPTION`) error handling.
- Explain why `CATCH` order matters and how to determine it from the exception hierarchy.
- Argue both sides of catching `cx_root`, and say where it belongs.
- Know how to propagate a caught exception's message text (`error->get_text( )`).
- Explain what `error_message` catches in a function module call, and what happens to `X` messages.
- Explain how you would log a mass-processing run so that every failed record is traceable afterwards.

## 🐞 Debugger — Scope Note

Interactive debugging, the checkpoint statements `BREAK-POINT`, `ASSERT` and `LOG-POINT`, and reading short dumps are covered in [23-Debugging-Troubleshooting](../23-Debugging-Troubleshooting/README.md).

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE91 | Maintain message classes |
| SLG0 | Define application log objects/sub-objects |
| SLG1 | Display application log |

## 🔗 Related Chapters

- [05-Control-Statements](../05-Control-Statements/README.md) — `CHECK`, `CONTINUE` and `RETURN`
- [15-BAPIs](../15-BAPIs/README.md) — `BAPIRET2` return handling
- [19-Performance](../19-Performance/README.md) — runtime analysis and memory
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — classic and class-based exceptions
- [23-Debugging-Troubleshooting](../23-Debugging-Troubleshooting/README.md) — the debugger, checkpoints and short dumps
