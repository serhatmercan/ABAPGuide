# 14 — Function Modules & Batch Input (BDC)

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. BDC remains the practical fallback for mass loads into transactions that expose no API, and you will meet it in almost every long-lived SAP landscape. It is a last resort, not a first choice, and it is **not** part of the ABAP Cloud development model — see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

This chapter focuses on **Batch Data Communication (BDC/Batch Input)** — simulating user input into a classic dynpro transaction programmatically. It's still widely used for mass data loads into transactions that don't have a BAPI. (General function module usage/calls are covered in [09-Modularization](../09-Modularization/README.md).)

Standard data is changed through BAPIs or released APIs first ([Rule 7.9](../docs/ABAP-Development-Rules.md#79-write-only-to-your-own-tables-change-sap-standard-data-through-bapis-or-released-apis)); batch input is the fallback when neither exists. Like a BAPI call, it belongs in a small wrapper class that the rest of the code calls ([Rule 5.1](../docs/ABAP-Development-Rules.md#51-write-new-logic-in-classes-wrap-function-modules-and-bapis)).

## 📥 Batch Input — Simulating Screen Input

> 📝 **Contextual snippet** — `zcx_zsm_batch_input_error` is a placeholder exception class with T100 messages from `zsm_msg`. The screen numbers and function codes come from a recording in transaction `SHDB`; record the transaction in your own release before you rely on them. **[verify: the components of `BDCMSGCOLL`, e.g. `MSGTYP`]**

```abap
CLASS lcl_invoice_transaction DEFINITION FINAL.
  PUBLIC SECTION.
    " Opens an invoice in transaction MIR4 and switches it to change mode
    METHODS open_for_change
      IMPORTING invoice_id  TYPE rbkp-belnr
                fiscal_year TYPE rbkp-gjahr
      RAISING   zcx_zsm_batch_input_error.

  PRIVATE SECTION.
    " Show screens only when an error occurs
    CONSTANTS errors_only TYPE c LENGTH 1 VALUE 'E'.
    " Synchronous update, like COMMIT WORK AND WAIT
    CONSTANTS synchronous TYPE c LENGTH 1 VALUE 'S'.
ENDCLASS.


CLASS lcl_invoice_transaction IMPLEMENTATION.
  METHOD open_for_change.
    DATA bdc_lines TYPE STANDARD TABLE OF bdcdata WITH EMPTY KEY.
    DATA messages  TYPE STANDARD TABLE OF bdcmsgcoll WITH EMPTY KEY.

    " One line per screen start (dynbegin), one per field or function code
    bdc_lines = VALUE #( ( program = 'SAPLMR1M' dynpro = '6150' dynbegin = abap_true )
                         ( fnam = 'BDC_OKCODE' fval = '/00' )
                         ( fnam = 'RBKP-BELNR' fval = invoice_id )
                         ( fnam = 'RBKP-GJAHR' fval = fiscal_year )
                         ( program = 'SAPLMR1M' dynpro = '6000' dynbegin = abap_true )
                         ( fnam = 'BDC_OKCODE' fval = '/EPPCH' ) ).

    " The user's own authorization decides, as if they ran MIR4 themselves (Rule 8.9)
    TRY.
        CALL TRANSACTION 'MIR4' WITH AUTHORITY-CHECK
                                USING         bdc_lines
                                MODE          errors_only
                                UPDATE        synchronous
                                MESSAGES INTO messages.
        DATA(return_code) = sy-subrc.

      CATCH cx_sy_authorization_error INTO DATA(authorization_error).
        RAISE EXCEPTION TYPE zcx_zsm_batch_input_error
          MESSAGE e090(zsm_msg) WITH 'MIR4'
          EXPORTING previous = authorization_error.
    ENDTRY.

    " Error and abort messages count as failure even when sy-subrc is 0 (Rule 6.9)
    IF    return_code <> 0
       OR line_exists( messages[ msgtyp = 'E' ] )
       OR line_exists( messages[ msgtyp = 'A' ] ).
      RAISE EXCEPTION TYPE zcx_zsm_batch_input_error
        MESSAGE e091(zsm_msg) WITH invoice_id fiscal_year.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

The transaction owner calls the wrapper and decides what the user sees:

```abap
TRY.
    NEW lcl_invoice_transaction( )->open_for_change( invoice_id  = invoice_id
                                                     fiscal_year = fiscal_year ).
  CATCH zcx_zsm_batch_input_error INTO DATA(batch_input_error).
    MESSAGE batch_input_error TYPE 'S' DISPLAY LIKE 'E'.
ENDTRY.
```

> 💡 Recorder-generated and older programs fill the table through subroutines, one call per line. `VALUE` builds the same table in one statement and keeps the screen sequence readable ([Rule 3.4](../docs/ABAP-Development-Rules.md#34-build-structures-and-tables-with-value)).

> ⚠️ **State the authorization intent explicitly.** `CALL TRANSACTION` supports both `WITH AUTHORITY-CHECK` and `WITHOUT AUTHORITY-CHECK`. Use `WITH AUTHORITY-CHECK` for anything a user triggers — a BDC loader that drives a transaction on the user's behalf must not give them access they would not have interactively. Use `WITHOUT AUTHORITY-CHECK` only in a technical context where you have already performed the check yourself, and say so in a comment. Leaving both additions off is obsolete according to the ABAP Keyword Documentation ([Rule 8.9](../docs/ABAP-Development-Rules.md#89-call-transactions-with-authority-check)): the call then no longer states whether the user's authorization is checked.

### 📋 BDC Structure Reference

| Field | Purpose |
|---|---|
| `program` / `dynpro` | Identifies the screen (program name + screen number) — set only on the **first** entry of a screen block |
| `dynbegin` | `'X'` marks the start of a new screen block |
| `fnam` / `fval` | Field name and the value to enter into it — used for all subsequent entries within that screen block |
| `fnam = 'BDC_OKCODE'` | The function code the screen is left with, in `fval` |
| `fnam = 'BDC_CURSOR'` | Places the cursor on the screen element named in `fval` |

### 🕹️ `CALL TRANSACTION` Modes

| Mode | Behavior |
|---|---|
| `A` | All screens shown (foreground, for debugging BDC scripts) |
| `E` | Show screens only if an error occurs (semi-background) |
| `N` | No screens shown (fully background/silent) |
| `P` | No screens shown, but a breakpoint in the called transaction opens the debugger |

According to the ABAP Keyword Documentation, any other value behaves like `A`, and `A` is also the default when the addition is missing.

| Update | Behavior |
|---|---|
| `A` | Asynchronous update, like `COMMIT WORK` without `AND WAIT` (default) |
| `S` | Synchronous update, like `COMMIT WORK AND WAIT` |
| `L` | Local update, as if the called program had run `SET UPDATE TASK LOCAL` |

> 📝 `OPTIONS FROM` with a structure of type `CTU_PARAMS` covers both additions and offers more settings: `DISMODE` (mode), `UPMODE` (update), `DEFSIZE` (standard screen size), `RACOMMIT` (a `COMMIT WORK` does not end batch input processing) and others.

### 🔢 Result: `sy-subrc` and Messages

| `sy-subrc` | Meaning |
|---|---|
| `0` | The transaction was processed successfully |
| below `1000` | Error in the called transaction; its messages are in the `MESSAGES INTO` table |
| `1001` | Error in batch input processing |

A run can end with `sy-subrc` 0 and still have sent error messages, so check both, as the wrapper above does.

## 🔄 Batch Input and the SAP LUW

According to the ABAP Keyword Documentation, `CALL TRANSACTION` opens a new SAP LUW but not a new database LUW:

- The called transaction's own `COMMIT WORK` commits its work, and by default it also ends batch input processing (unless `RACOMMIT` is set through `OPTIONS FROM`).
- A database rollback in the called transaction can also roll back what the **calling** program had registered for the update. If the caller has pending registrations, its transaction owner commits them before the call ([Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work)).
- `UPDATE 'S'` makes the called transaction's update synchronous; it does not make the *calling* program's LUW someone else's responsibility — see [08 — SAP LUW](../08-Open-SQL/README.md#-sap-luw--transaction-ownership).

## 🗂️ Batch Input Sessions

`CALL TRANSACTION … USING` processes the screens immediately. A batch input session stores them instead; transaction `SM35` processes the session later and keeps a log for every transaction in it. Sessions suit large loads that someone has to monitor and restart. They are created with the function modules `BDC_OPEN_GROUP`, `BDC_INSERT` and `BDC_CLOSE_GROUP` **[verify: their parameters in `SE37`]**.

## ✅ Best Practices

- Prefer a **BAPI** ([15-BAPIs](../15-BAPIs/README.md)) over BDC whenever one exists for the target transaction — BDC is fragile (breaks on screen layout/customizing changes) and should be a last resort.
- Wrap each transaction in one class method that builds the screens, calls the transaction and turns `sy-subrc` and error messages into an exception — [Rules 5.1](../docs/ABAP-Development-Rules.md#51-write-new-logic-in-classes-wrap-function-modules-and-bapis) and [6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary).
- Always collect messages (`MESSAGES INTO messages`) and check them after `CALL TRANSACTION` — a batch input run can "succeed" at the transaction level while still reporting business errors.
- **Always state the authorization intent** (`WITH AUTHORITY-CHECK` / `WITHOUT AUTHORITY-CHECK`) rather than leaving it to the default.
- Use mode `'N'` for production mass-processing jobs; use `'A'`/`'E'` only during development/debugging.
- Let the caller own the transaction, and commit pending update registrations before the call — see [🔄 Batch Input and the SAP LUW](#-batch-input-and-the-sap-luw).

## ⚠️ Common Mistakes

- Hardcoding screen numbers/field names without verifying them against the actual transaction (they change across releases/support packages).
- Not checking `sy-subrc`/`messages` after `CALL TRANSACTION`, silently swallowing failed records in a mass upload.
- **Omitting the authorization addition**, so a loader can drive a transaction the user could not run interactively.
- Calling a transaction while the caller still has uncommitted update registrations, which a rollback in the called transaction can discard.
- Using BDC for high-volume, real-time processing — it's significantly slower than a direct BAPI/function module call.

## 🎤 Interview & Review Checkpoints

- Explain the difference between Batch Input (`CALL TRANSACTION` vs. the session method via `SM35`) and Direct Input.
- Know why BAPIs are generally preferred over BDC for new integrations.
- Explain what `WITH AUTHORITY-CHECK` adds to a `CALL TRANSACTION`, and when `WITHOUT AUTHORITY-CHECK` is defensible.
- Explain how `CALL TRANSACTION` relates to the caller's SAP LUW and database LUW.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SHDB | Record a BDC-compatible transaction script |
| SM35 | Manage batch input sessions |

## 🔗 Related Chapters

- [08-Open-SQL](../08-Open-SQL/README.md#-sap-luw--transaction-ownership) — SAP LUW and transaction ownership
- [09-Modularization](../09-Modularization/README.md) — calling function modules
- [15-BAPIs](../15-BAPIs/README.md) — the preferred interface for standard data
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — batch input outside ABAP Cloud
