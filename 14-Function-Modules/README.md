# 14 — Function Modules & Batch Input (BDC)

## 📖 Introduction

This chapter focuses on **Batch Data Communication (BDC/Batch Input)** — simulating user input into a classic dynpro transaction programmatically. It's still widely used for mass data loads into transactions that don't have a BAPI. (General function module usage/calls are covered in [09-Modularization](../09-Modularization/README.md).)

## 📥 Batch Input — Simulating Screen Input

```abap
" TOP
DATA gt_bdctable TYPE TABLE OF bdcdata WITH EMPTY KEY.
DATA gt_messtab  TYPE TABLE OF bdcmsgcoll WITH EMPTY KEY.

" FORM
CLEAR gt_messtab.

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
        lv_belnr.
PERFORM bdc_append
  USING ''
        ''
        'RBKP-GJAHR'
        lv_gjahr.

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

CALL TRANSACTION 'MIR4' USING gt_bdctable UPDATE 'S' MODE 'E' MESSAGES INTO gt_messtab.

" PERFORM
FORM bdc_append
  USING program
        dynpro
        fieldname
        fieldvalue.

  DATA(ls_bdctable) = VALUE bdcdata( program  = COND #( WHEN fieldname IS INITIAL THEN program ELSE '' )
                                     dynpro   = COND #( WHEN fieldname IS INITIAL THEN dynpro  ELSE '' )
                                     dynbegin = COND #( WHEN fieldname IS INITIAL THEN 'X'      ELSE '' )
                                     fnam     = fieldname
                                     fval     = fieldvalue ).

  APPEND ls_bdctable TO gt_bdctable.
ENDFORM.
```

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
- Always collect messages (`MESSAGES INTO gt_messtab`) and check them after `CALL TRANSACTION` — a batch input session can "succeed" at the transaction level while still reporting business errors.
- Use mode `'N'` for production mass-processing jobs; use `'A'`/`'E'` only during development/debugging.

## ⚠️ Common Mistakes

- Hardcoding screen numbers/field names without verifying them against the actual transaction (they change across releases/support packages).
- Not checking `sy-subrc`/`gt_messtab` after `CALL TRANSACTION`, silently swallowing failed records in a mass upload.
- Using BDC for high-volume, real-time processing — it's significantly slower than a direct BAPI/function module call.

## 🎤 Interview Tips

- Explain the difference between Batch Input (`CALL TRANSACTION`/session method) and Direct Input.
- Know why BAPIs are generally preferred over BDC for new integrations.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SHDB | Record a BDC-compatible transaction script |
| SM35 | Manage batch input sessions |

## 🔗 Related Chapters

- [09-Modularization](../09-Modularization/README.md)
- [15-BAPIs](../15-BAPIs/README.md)
