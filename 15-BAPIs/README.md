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

BAPIs typically do **not** commit the database themselves — the caller is responsible for the transaction outcome:

```abap
IF NOT line_exists( lt_return[ type = 'E' ] ).
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING wait = abap_true.
ELSE.
  CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
ENDIF.
```

> ⚠️ **Warning:** Always check the return table for **any** message of type `E`, `A`, or `X` before committing — checking only for `E` can miss aborts/exceptions in some BAPIs. A safer, more defensive check:
> ```abap
> DATA(lv_has_error) = xsdbool(    line_exists( lt_return[ type = 'E' ] )
>                               OR line_exists( lt_return[ type = 'A' ] )
>                               OR line_exists( lt_return[ type = 'X' ] ) ).
> ```
> (see [18-Debugging](../18-Debugging/README.md#-checking-bapi-return-messages) for more on this pattern)

## 🧭 Typical BAPI Call Pattern

```abap
CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
  EXPORTING  order_header_in = ls_header
  IMPORTING  salesdocument   = lv_vbeln
  TABLES     order_items_in  = lt_items
             return          = lt_return.

IF NOT line_exists( lt_return[ type = 'E' ] ).
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING wait = abap_true.
ELSE.
  CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
ENDIF.
```

## ✅ Best Practices

- Always call `BAPI_TRANSACTION_COMMIT` with `wait = abap_true` when the caller needs to immediately re-read the just-created/changed data (e.g., a subsequent `SELECT` in the same LUW/RFC call).
- Never assume a BAPI committed automatically — always explicitly commit or roll back.
- Prefer BAPIs over BDC ([14-Function-Modules](../14-Function-Modules/README.md)) and direct table updates ([08-Open-SQL](../08-Open-SQL/README.md)) whenever a suitable one exists, since BAPIs enforce business rules and stay stable across releases.
- Log the full `return` table (not just the first error) for traceability — see [18-Debugging](../18-Debugging/README.md).

## ⚠️ Common Mistakes

- Checking only for `type = 'E'` and missing `'A'`/`'X'` messages, leading to a commit of a partially failed transaction.
- Forgetting to commit at all, silently discarding successful BAPI changes.
- Calling `BAPI_TRANSACTION_COMMIT` inside a tight loop for many documents — batch the commits where business logic allows, for performance.

## 🎤 Interview Tips

- Explain why BAPIs generally don't perform their own `COMMIT WORK`, and why that's a deliberate design choice (LUW management belongs to the caller).
- Be able to describe the standard `BAPIRET2` structure and its `type` values.
- Compare BAPIs vs. direct table updates vs. BDC — pros/cons of each.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| BAPI | Business Object Repository / BAPI browser |
| SE37 | Function Builder — test/display a BAPI's signature |
| BD87 | Monitor IDocs generated from BAPI-based interfaces (if applicable) |

## 🔗 Related Chapters

- [09-Modularization](../09-Modularization/README.md)
- [14-Function-Modules](../14-Function-Modules/README.md)
- [18-Debugging](../18-Debugging/README.md)
