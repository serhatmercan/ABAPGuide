# 15 — BAPIs

## 📖 Introduction

A **BAPI** (Business Application Programming Interface) is a standardized, RFC-enabled function module that provides a stable API for a SAP Business Object (e.g., creating a sales order, updating a material). Unlike direct table updates ([08-Open-SQL](../08-Open-SQL/README.md)), BAPIs enforce business logic, validations, and consistency checks — always prefer them over direct table manipulation when one is available.

## 📨 The `BAPIRET2` Return Structure

Every well-behaved BAPI returns messages in a table of type `BAPIRET2`, which you should always check before committing.

```abap
" BAPI Return Message
DATA(lt_return) = VALUE bapiret2_t( ).
```

| Field | Meaning |
|---|---|
| `type` | Message type: `S` (success), `I` (info), `W` (warning), `E` (error), `A` (abort), `X` (exception) |
| `id` | Message class |
| `number` | Message number |
| `message` | Fully formatted message text |

## ✅ Commit & Rollback

Write BAPIs **do not decide the transaction boundary**. They register their work and report the outcome in `RETURN`; the caller decides whether that work is committed or discarded. This is the same ownership rule described in [08 — SAP LUW & Transaction Ownership](../08-Open-SQL/README.md#-sap-luw--transaction-ownership), applied to the BAPI protocol.

```abap
DATA(lv_has_error) = xsdbool(    line_exists( lt_return[ type = 'E' ] )
                              OR line_exists( lt_return[ type = 'A' ] )
                              OR line_exists( lt_return[ type = 'X' ] ) ).

IF lv_has_error = abap_false.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING wait = abap_true.       " see the note on WAIT below
ELSE.
  CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
ENDIF.
```

> ⚠️ **Use `BAPI_TRANSACTION_COMMIT`, not a plain `COMMIT WORK`, after BAPI calls.** They are not interchangeable. `BAPI_TRANSACTION_COMMIT` is part of the BAPI protocol: it performs the commit *and* gives the underlying application the opportunity to complete its own processing correctly. A bare `COMMIT WORK` bypasses that step. Likewise use `BAPI_TRANSACTION_ROLLBACK` rather than a bare `ROLLBACK WORK`.

> 💡 **`wait = abap_true`** makes the commit wait for the synchronous part of update processing to finish. Set it when the *same* program must immediately re-read the document it just created or changed — otherwise the subsequent `SELECT` may find nothing. Leave it unset when you simply need the work committed and do not read it back, because waiting blocks the work process.

> ⚠️ **Never call `BAPI_TRANSACTION_COMMIT` from inside a reusable wrapper** that other code calls. The wrapper does not know what else the caller has pending in the same SAP LUW. Return the `BAPIRET2` table and let the transaction owner decide.

> ⚠️ **Warning:** Always check the return table for **any** message of type `E`, `A`, or `X` before committing — checking only for `E` can miss aborts/exceptions in some BAPIs. A safer, more defensive check:
> ```abap
> DATA(lv_has_error) = xsdbool(    line_exists( lt_return[ type = 'E' ] )
>                               OR line_exists( lt_return[ type = 'A' ] )
>                               OR line_exists( lt_return[ type = 'X' ] ) ).
> ```
> (see [18-Debugging](../18-Debugging/README.md#-message-statement-variants) for more on this pattern)

## 🧭 Typical BAPI Call Pattern

```abap
CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
  EXPORTING  order_header_in = ls_header
  IMPORTING  salesdocument   = lv_vbeln
  TABLES     order_items_in  = lt_items
             return          = lt_return.

DATA(lv_has_error) = xsdbool(    line_exists( lt_return[ type = 'E' ] )
                              OR line_exists( lt_return[ type = 'A' ] )
                              OR line_exists( lt_return[ type = 'X' ] ) ).

IF lv_has_error = abap_false.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING wait = abap_true.
ELSE.
  CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
ENDIF.
```

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. Many BAPIs remain the supported, released write interface on S/4HANA on-premise and are the correct choice today. Under ABAP Cloud you may only call APIs that SAP has explicitly *released* for cloud development — see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## ✅ Best Practices

- Prefer BAPIs over BDC ([14-Function-Modules](../14-Function-Modules/README.md)) and over direct table writes ([08-Open-SQL](../08-Open-SQL/README.md)) whenever a suitable one exists — BAPIs enforce the application's business rules and offer a more stable interface across releases.
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
- Calling `BAPI_TRANSACTION_COMMIT` once per document inside a tight loop — batch where the business logic allows.
- Assuming `BAPI_TRANSACTION_ROLLBACK` can undo work that was already committed. It cannot; it only discards the current, uncommitted LUW.

## 🎤 Interview & Review Checkpoints

- Explain why BAPIs generally don't perform their own `COMMIT WORK`, and why that's a deliberate design choice (LUW management belongs to the caller).
- Explain the difference between `BAPI_TRANSACTION_COMMIT` and a plain `COMMIT WORK`.
- Be able to describe the standard `BAPIRET2` structure and its `type` values.
- Compare BAPIs vs. direct table updates vs. BDC — pros/cons of each.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| BAPI | Business Object Repository / BAPI browser |
| SE37 | Function Builder — test/display a BAPI's signature |
| BD87 | Monitor IDocs generated from BAPI-based interfaces (if applicable) |

## 🔗 Related Chapters

- [08-Open-SQL](../08-Open-SQL/README.md#-sap-luw--transaction-ownership) — the general SAP LUW / transaction-ownership rule
- [09-Modularization](../09-Modularization/README.md)
- [14-Function-Modules](../14-Function-Modules/README.md)
- [18-Debugging](../18-Debugging/README.md)
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md)
