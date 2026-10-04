# 15 — BAPIs

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. Many BAPIs remain the supported, released write interface on S/4HANA on-premise and are the correct choice today. Under ABAP Cloud you may only call APIs that SAP has explicitly *released* for cloud development — see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

A **BAPI** (Business Application Programming Interface) is a standardized, RFC-enabled function module that provides a stable API for a SAP Business Object (e.g., creating a sales order, updating a material). Unlike direct table updates ([08-Open-SQL](../08-Open-SQL/README.md)), BAPIs enforce business logic, validations, and consistency checks — always prefer them over direct table manipulation when one is available ([Rule 7.9](../docs/ABAP-Development-Rules.md#79-write-only-to-your-own-tables-change-sap-standard-data-through-bapis-or-released-apis)).

According to the ABAP Keyword Documentation, BAPIs are defined in the Business Object Repository, implemented as remote-enabled function modules named `BAPI_<object>_<method>`, and must not start a user dialog. Transaction `BAPI` is the BAPI Explorer.

## 📨 The `BAPIRET2` Return Structure

Most BAPIs return their messages in a table with the line type `BAPIRET2`, which you check before anything is committed. Older BAPIs use other return structures; the signature in `SE37` shows which one. **[verify: the components of `BAPIRET2`, the table type `BAPIRET2_T` and the fixed values of `BAPIRET2-TYPE`]**

```abap
DATA return_messages TYPE bapiret2_t.
```

| Field | Meaning |
|---|---|
| `type` | Message type: `S` (success), `I` (info), `W` (warning), `E` (error), `A` (abort), `X` (exception) |
| `id` | Message class |
| `number` | Message number |
| `message` | Fully formatted message text |
| `message_v1` … `message_v4` | The message variables |

An error is any line of type `E`, `A` or `X`. One `LOOP … WHERE` finds the first of them:

```abap
LOOP AT return_messages INTO DATA(error) WHERE type CA 'EAX'.
  " The first error or abort is enough to stop
  EXIT.
ENDLOOP.
DATA(has_error) = xsdbool( sy-subrc = 0 ).
```

> ⚠️ **Check for `E`, `A` and `X`, not only `E`.** Checking only for `E` can miss aborts and exceptions that some BAPIs report.

## 🧭 Typical BAPI Call Pattern

The BAPI is called in one wrapper method ([Rule 5.1](../docs/ABAP-Development-Rules.md#51-write-new-logic-in-classes-wrap-function-modules-and-bapis)). The wrapper evaluates the return table and turns an error into an exception ([Rule 6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary)); it never commits.

> 📝 **Contextual snippet** — `zcx_zsm_bapi_error` is a placeholder exception class that implements `IF_T100_DYN_MSG`, so it can carry the BAPI's own message ([Rule 6.5](../docs/ABAP-Development-Rules.md#65-raise-with-raise-exception-new-use-raise-exception-type--message-to-attach-a-t100-message)). A real order needs more data than shown, for example schedule lines. **[verify: the parameters of `BAPI_SALESORDER_CREATEFROMDAT2` and the structures `BAPISDHD1`, `BAPISDITM` and `BAPIPARNR`]**

```abap
CLASS lcl_sales_order_api DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES order_items    TYPE STANDARD TABLE OF bapisditm WITH EMPTY KEY.
    TYPES order_partners TYPE STANDARD TABLE OF bapiparnr WITH EMPTY KEY.

    " Creates the order; the transaction owner commits or rolls back (Rules 7.10, 7.11)
    METHODS create
      IMPORTING header        TYPE bapisdhd1
                items         TYPE order_items
                partners      TYPE order_partners
      RETURNING VALUE(result) TYPE vbeln_va
      RAISING   zcx_zsm_bapi_error.
ENDCLASS.


CLASS lcl_sales_order_api IMPLEMENTATION.
  METHOD create.
    DATA return_messages TYPE bapiret2_t.

    " TABLES parameters need variables; importing parameters are read-only
    DATA(item_lines)    = items.
    DATA(partner_lines) = partners.

    CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
      EXPORTING
        order_header_in = header
      IMPORTING
        salesdocument   = result
      TABLES
        order_items_in  = item_lines
        order_partners  = partner_lines
        return          = return_messages.

    LOOP AT return_messages INTO DATA(error) WHERE type CA 'EAX'.
      RAISE EXCEPTION TYPE zcx_zsm_bapi_error
        MESSAGE ID error-id TYPE 'E' NUMBER error-number
        WITH error-message_v1 error-message_v2 error-message_v3 error-message_v4.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
```

## ✅ Commit & Rollback

Write BAPIs **do not decide the transaction boundary**. They register their work and report the outcome in `RETURN`; the caller decides whether that work is committed or discarded. This is the same ownership rule described in [08 — SAP LUW & Transaction Ownership](../08-Open-SQL/README.md#-sap-luw--transaction-ownership), applied to the BAPI protocol — [Rules 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work) and [7.11](../docs/ABAP-Development-Rules.md#711-close-bapi-calls-with-bapi_transaction_commit-or-bapi_transaction_rollback).

> 📝 **Contextual snippet** — the transaction owner, for example a report; `sales_order_api`, `order_header`, `order_items` and `order_partners` are assumed.

```abap
TRY.
    DATA(order_id) = sales_order_api->create( header   = order_header
                                              items    = order_items
                                              partners = order_partners ).

    " WAIT only because the next step reads the new order (Rule 7.14)
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.

  CATCH zcx_zsm_bapi_error INTO DATA(bapi_error).
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    MESSAGE bapi_error TYPE 'S' DISPLAY LIKE 'E'.
ENDTRY.
```

> ⚠️ **Use `BAPI_TRANSACTION_COMMIT`, not a plain `COMMIT WORK`, after BAPI calls.** The BAPI protocol ends with `BAPI_TRANSACTION_COMMIT` or `BAPI_TRANSACTION_ROLLBACK`, and the transaction owner calls them ([Rule 7.11](../docs/ABAP-Development-Rules.md#711-close-bapi-calls-with-bapi_transaction_commit-or-bapi_transaction_rollback)). **[verify: what `BAPI_TRANSACTION_COMMIT` does besides `COMMIT WORK`, in its source code]**

> 💡 **`wait = abap_true`** is meant for the case where the *same* program must immediately re-read the document it just created or changed; otherwise leave it unset, because waiting costs time ([Rule 7.14](../docs/ABAP-Development-Rules.md#714-use-commit-work-and-wait-only-when-the-next-step-depends-on-the-update)). **[verify: that `wait` makes `BAPI_TRANSACTION_COMMIT` execute `COMMIT WORK AND WAIT`]**

> ⚠️ **Never call `BAPI_TRANSACTION_COMMIT` from inside a reusable wrapper** that other code calls. The wrapper does not know what else the caller has pending in the same SAP LUW. Raise an exception, or return the `BAPIRET2` table, and let the transaction owner decide.

## ✅ Best Practices

- Prefer BAPIs over BDC ([14-Function-Modules](../14-Function-Modules/README.md)) and over direct table writes ([08-Open-SQL](../08-Open-SQL/README.md)) whenever a suitable one exists — BAPIs enforce the application's business rules and offer a more stable interface across releases.
- Call each BAPI in one wrapper method that turns the return table into an exception — [Rules 5.1](../docs/ABAP-Development-Rules.md#51-write-new-logic-in-classes-wrap-function-modules-and-bapis) and [6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary).
- Check the `RETURN` table for `E`, `A` **and** `X` before committing.
- Use `BAPI_TRANSACTION_COMMIT` / `BAPI_TRANSACTION_ROLLBACK`, not bare `COMMIT WORK` / `ROLLBACK WORK`.
- Set `wait = abap_true` only when the same program must immediately re-read the data it just wrote.
- Decide the transaction outcome at the **top-level caller**, not inside a reusable wrapper.
- Log the full `return` table (not just the first error) for traceability — see [18-Debugging](../18-Debugging/README.md).

## ⚠️ Common Mistakes

- Checking only for `type = 'E'` and missing `'A'`/`'X'` messages, leading to a commit of a partially failed transaction.
- Forgetting to commit at all, silently discarding successful BAPI changes.
- Using a plain `COMMIT WORK` after a BAPI instead of `BAPI_TRANSACTION_COMMIT`.
- Committing inside a reusable wrapper, so the caller loses control of its own transaction.
- Passing the return code or the return table on to every caller instead of turning it into an exception at the wrapper.
- Calling `BAPI_TRANSACTION_COMMIT` once per document inside a tight loop — batch where the business logic allows.
- Assuming `BAPI_TRANSACTION_ROLLBACK` can undo work that was already committed. It cannot; it only discards the current, uncommitted LUW.

## 🎤 Interview & Review Checkpoints

- Explain why BAPIs generally don't perform their own `COMMIT WORK`, and why that's a deliberate design choice (LUW management belongs to the caller).
- Explain the difference between `BAPI_TRANSACTION_COMMIT` and a plain `COMMIT WORK`.
- Be able to describe the standard `BAPIRET2` structure and its `type` values.
- Explain what a BAPI wrapper does and what it leaves to the transaction owner.
- Compare BAPIs vs. direct table updates vs. BDC — pros/cons of each.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| BAPI | BAPI Explorer (Business Object Repository) |
| SE37 | Function Builder — test/display a BAPI's signature |
| BD87 | Monitor IDocs generated from BAPI-based interfaces (if applicable) |

## 🔗 Related Chapters

- [08-Open-SQL](../08-Open-SQL/README.md#-sap-luw--transaction-ownership) — the general SAP LUW / transaction-ownership rule
- [09-Modularization](../09-Modularization/README.md) — calling function modules
- [14-Function-Modules](../14-Function-Modules/README.md) — batch input when no BAPI exists
- [18-Debugging](../18-Debugging/README.md) — exceptions and logging
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — released APIs under ABAP Cloud
