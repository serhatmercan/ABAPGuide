# 04 — Operators & Built-in Functions

## 📖 Introduction

This chapter covers arithmetic operators and the built-in mathematical functions available in modern ABAP, which reduce the need to write helper subroutines for simple calculations.

## ➕ Arithmetic & Constant Declarations

```abap
" Constants use the lc_ (local) / gc_ (global) prefix, not lv_
CONSTANTS lc_tax_rate  TYPE p LENGTH 8 DECIMALS 1 VALUE '7.5'.
CONSTANTS lc_max_items TYPE i                     VALUE 5.
```

## 🧮 Built-in Math Functions

| Function | Description | Example | Result |
|---|---|---|---|
| `abs( )` | Absolute value | `abs( -3 )` | `3` |
| `ceil( )` | Rounds **up** to the nearest integer | `ceil( '7.15' )` | `8` |
| `floor( )` | Rounds **down** to the nearest integer | `floor( '7.95' )` | `7` |
| `MOD` | Remainder of integer division | `3600 MOD 60` | `0` |

```abap
" Absolute
DATA(lv_absolute) = abs( -3 ).                      " => 3

" Ceil -> round up to integer
DATA(lv_ceil) = ceil( '7.15' ).                     " => 8

" Floor -> round down to integer
DATA(lv_floor) = floor( '7.95' ).                   " => 7

" Floor -> keep a fixed number of decimals (truncate to 2 decimals)
DATA lv_value  TYPE p LENGTH 8 DECIMALS 4 VALUE '7896.6579'.
DATA lv_result TYPE p LENGTH 8 DECIMALS 2.

lv_result = lv_value * 100.
lv_result = floor( lv_result ) / 100.               " => 7896.65

" Mod - check whether a value is an exact multiple of another
DATA lv_seconds TYPE int4 VALUE 3600.

IF lv_seconds MOD 60 = 0.                          " 3600 MOD 60 = 0 -> true
ENDIF.
```

> 🧠 **Tip:** `floor(value * 100) / 100` is a common trick to **truncate** (not round) to 2 decimal places, which is different from just declaring a `DECIMALS 2` field (which *rounds*).

## 🎲 Random Numbers

ABAP provides the class `cl_abap_random` (or `cl_abap_random_int` for integers) to generate random numbers — useful for test data generation or unique temporary keys:

```abap
DATA(lo_random) = cl_abap_random_int=>create( seed = cl_abap_random=>seed( )
                                              min  = 1
                                              max  = 100 ).
DATA(lv_random_number) = lo_random->get_next( ).
```

## ✅ Best Practices

- Use built-in functions (`abs`, `ceil`, `floor`, `trunc`) instead of manual arithmetic tricks — they are more readable and self-documenting.
- Be explicit about **rounding vs. truncation** — `DECIMALS` on a `p` field rounds, `floor()`/`trunc()` truncates. Choose deliberately, especially for financial calculations.
- Use `MOD` for divisibility checks instead of `/` and comparing to an integer cast.

## ⚠️ Common Mistakes

- Assuming `floor()` and rounding to N decimals with a `p` field behave the same way — they don't.
- Using literal string values like `'7.15'` inconsistently with numeric literals — ABAP will implicitly convert, but explicit `CONV` is clearer.
- Ignoring `sy-subrc`/overflow exceptions in more complex calculations (e.g., with `CEIL`/`FLOOR` on very large packed numbers).

## 🎤 Interview Tips

- Know the difference between `ceil`, `floor`, `trunc`, and rounding via `DECIMALS`.
- Be able to explain how `MOD` works with negative numbers in ABAP.

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md) — packed number (`p`) type and decimals
- [05-Control-Statements](../05-Control-Statements/README.md) — using calculated values in conditions
