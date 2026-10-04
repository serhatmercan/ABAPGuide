# 14 — Function Modules & Batch Input (BDC)

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. BDC remains the practical fallback for mass loads into transactions that expose no API, and you will meet it in almost every long-lived SAP landscape. It is a last resort, not a first choice, and it is **not** part of the ABAP Cloud development model — see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

This chapter focuses on **Batch Data Communication (BDC/Batch Input)** — simulating user input into a classic dynpro transaction programmatically. It's still widely used for mass data loads into transactions that don't have a BAPI. (General function module usage/calls are covered in [09-Modularization](../09-Modularization/README.md).)

## 📥 Batch Input — Simulating Screen Input

```abap
" TOP
DATA bdc_lines TYPE TABLE OF bdcdata WITH EMPTY KEY.
DATA messages  TYPE TABLE OF bdcmsgcoll WITH EMPTY KEY.

" FORM
CLEAR messages.

PERFORM bdc_append
  USING 'SAPLMR1M'
        '6150'
        ''
        ''.
PERFORM bdc_append
  USING ''
        ''
        'BDC_OKCODE'
        '/00'.
PERFORM bdc_append
  USING ''
        ''
        'RBKP-BELNR'
        invoice_id.
PERFORM bdc_append
  USING ''
        ''
        'RBKP-GJAHR'
        fiscal_year.

PERFORM bdc_append
  USING 'SAPLMR1M'
        '6000'
        ''
        ''.
PERFORM bdc_append
  USING ''
        ''
        'BDC_OKCODE'
        '/EPPCH'.

" Make the authorization decision EXPLICIT.
" WITH AUTHORITY-CHECK raises CX_SY_AUTHORIZATION_ERROR when the user is not
" authorized for the called transaction.
TRY.
    CALL TRANSACTION 'MIR4' WITH AUTHORITY-CHECK
                            USING        bdc_lines
                            UPDATE       'S'
                            MODE         'E'
                            MESSAGES INTO messages.

  CATCH cx_sy_authorization_error INTO DATA(authorization_error).
    MESSAGE authorization_error->get_text( ) TYPE 'E'.
ENDTRY.

" PERFORM
FORM bdc_append
  USING program     TYPE bdcdata-program
        dynpro      TYPE bdcdata-dynpro
        field_name  TYPE bdcdata-fnam
        field_value TYPE bdcdata-fval.

  DATA(bdc_line) = VALUE bdcdata(
      program  = COND #( WHEN field_name IS INITIAL THEN program ELSE '' )
      dynpro   = COND #( WHEN field_name IS INITIAL THEN dynpro  ELSE '' )
      dynbegin = COND #( WHEN field_name IS INITIAL THEN 'X'     ELSE '' )
      fnam     = field_name
      fval     = field_value ).

  APPEND bdc_line TO bdc_lines.
ENDFORM.
```

> ⚠️ **State the authorization intent explicitly.** `CALL TRANSACTION` supports both `WITH AUTHORITY-CHECK` and `WITHOUT AUTHORITY-CHECK`. Use `WITH AUTHORITY-CHECK` for anything a user triggers — a BDC loader that drives a transaction on the user's behalf must not give them access they would not have interactively. Use `WITHOUT AUTHORITY-CHECK` only in a technical context where you have already performed the check yourself, and say so in a comment. Leaving both additions off is obsolete according to the ABAP Keyword Documentation ([Rule 8.9](../docs/ABAP-Development-Rules.md#89-call-transactions-with-authority-check)): the call then no longer states whether the user's authorization is checked.

### 📋 BDC Structure Reference

| Field | Purpose |
|---|---|
| `program` / `dynpro` | Identifies the screen (program name + screen number) — set only on the **first** entry of a screen block |
| `dynbegin` | `'X'` marks the start of a new screen block |
| `fnam` / `fval` | Field name and the value to enter into it — used for all subsequent entries within that screen block |

### 🕹️ `CALL TRANSACTION` Modes

| Mode | Behavior |
|---|---|
| `A` | All screens shown (foreground, for debugging BDC scripts) |
| `E` | Show screens only if an error occurs (semi-background) |
| `N` | No screens shown (fully background/silent) |

## ✅ Best Practices

- Prefer a **BAPI** ([15-BAPIs](../15-BAPIs/README.md)) over BDC whenever one exists for the target transaction — BDC is fragile (breaks on screen layout/customizing changes) and should be a last resort.
- Always collect messages (`MESSAGES INTO messages`) and check them after `CALL TRANSACTION` — a batch input run can "succeed" at the transaction level while still reporting business errors.
- **Always state the authorization intent** (`WITH AUTHORITY-CHECK` / `WITHOUT AUTHORITY-CHECK`) rather than leaving it to the default.
- Use mode `'N'` for production mass-processing jobs; use `'A'`/`'E'` only during development/debugging.
- Let the caller own the transaction. `UPDATE 'S'` makes the called transaction's update synchronous; it does not make the *calling* program's LUW someone else's responsibility — see [08 — SAP LUW](../08-Open-SQL/README.md#-sap-luw--transaction-ownership).

## ⚠️ Common Mistakes

- Hardcoding screen numbers/field names without verifying them against the actual transaction (they change across releases/support packages).
- Not checking `sy-subrc`/`messages` after `CALL TRANSACTION`, silently swallowing failed records in a mass upload.
- **Omitting the authorization addition**, so a loader can drive a transaction the user could not run interactively.
- Using BDC for high-volume, real-time processing — it's significantly slower than a direct BAPI/function module call.

## 🎤 Interview & Review Checkpoints

- Explain the difference between Batch Input (`CALL TRANSACTION` vs. the session method via `SM35`) and Direct Input.
- Know why BAPIs are generally preferred over BDC for new integrations.
- Explain what `WITH AUTHORITY-CHECK` adds to a `CALL TRANSACTION`, and when `WITHOUT AUTHORITY-CHECK` is defensible.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SHDB | Record a BDC-compatible transaction script |
| SM35 | Manage batch input sessions |

## 🔗 Related Chapters

- [09-Modularization](../09-Modularization/README.md)
- [15-BAPIs](../15-BAPIs/README.md)
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md)
