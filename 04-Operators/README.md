# 04 — Operators & Built-in Functions

> **Lifecycle:** `CURRENT / RECOMMENDED`. Arithmetic operators, the built-in numeric functions and the random number classes are current.

## 📖 Introduction

This chapter covers arithmetic operators and the built-in mathematical functions available in modern ABAP, which reduce the need to write helper subroutines for simple calculations.

## ➕ Arithmetic & Constant Declarations

| Operator | Calculation | Priority |
|---|---|---|
| `+`, `-` | Addition, subtraction | 1 (lowest) |
| `*`, `/` | Multiplication, division | 2 |
| `DIV` | Integer part of the division, with a positive remainder | 2 |
| `MOD` | Positive remainder of the division | 2 |
| `**` | Power; the calculation type becomes `decfloat34` or `f` | 3 (highest, evaluated right to left) |

Operators of the same priority are evaluated from left to right, except `**`. Division by zero raises a catchable exception, unless the dividend is also zero, in which case the result is zero.

```abap
" Name constants after their meaning; no lc_/gc_ prefix (Rule 2.1)
CONSTANTS tax_rate  TYPE p LENGTH 8 DECIMALS 1 VALUE '7.5'.
CONSTANTS max_items TYPE i                     VALUE 5.
```

> 💡 In real code, declare such constants in the class that owns the concept, grouped by topic — [Rules 4.1](../docs/ABAP-Development-Rules.md#41-replace-magic-literals-with-named-constants) and [4.3](../docs/ABAP-Development-Rules.md#43-declare-constants-in-the-class-or-interface-that-owns-the-concept-grouped-by-topic).

## 🧮 Built-in Math Functions

| Function | Description | Example | Result |
|---|---|---|---|
| `abs( )` | Absolute value | `abs( -3 )` | `3` |
| `ceil( )` | Rounds **up** to the nearest integer | `ceil( '7.15' )` | `8` |
| `floor( )` | Rounds **down** to the nearest integer | `floor( '7.95' )` | `7` |
| `trunc( )` | Integer part (negative for a negative argument) | `trunc( '-7.95' )` | `-7` |
| `frac( )` | Decimal places (negative for a negative argument) | `frac( '7.95' )` | `0.95` |
| `sign( )` | -1, 0 or 1 | `sign( -3 )` | `-1` |
| `round( )` | Rounds to `dec` decimal places or `prec` digits; `mode` takes a `cl_abap_math=>round_…` constant | `round( val = '7.155' dec = 2 )` | `7.16` |
| `MOD` | Positive remainder of integer division | `3600 MOD 60` | `0` |

```abap
" Absolute
DATA(absolute_value) = abs( -3 ).                   " => 3

" Ceil -> round up to integer
DATA(rounded_up) = ceil( '7.15' ).                  " => 8

" Floor -> round down to integer
DATA(rounded_down) = floor( '7.95' ).               " => 7

" Floor -> keep a fixed number of decimals (truncate to 2 decimals)
DATA exact_value     TYPE p LENGTH 8 DECIMALS 4 VALUE '7896.6579'.
DATA truncated_value TYPE p LENGTH 8 DECIMALS 2.

truncated_value = exact_value * 100.
truncated_value = floor( truncated_value ) / 100.   " => 7896.65

" Mod - check whether a value is an exact multiple of another
DATA duration_in_seconds TYPE int4 VALUE 3600.

IF duration_in_seconds MOD 60 = 0.                 " 3600 MOD 60 = 0 -> true
ENDIF.
```

> 🧠 **Tip:** `floor(value * 100) / 100` is a common trick to **truncate** (not round) to 2 decimal places, which is different from just declaring a `DECIMALS 2` field (which *rounds*). The `round` function states the intent directly: `round( val = exact_value dec = 2 mode = cl_abap_math=>round_down )` rounds towards zero. Its result type is `decfloat34`. Note that `floor` rounds towards the smaller value, so the two differ for negative numbers.

## 🎲 Random Numbers

ABAP provides the class `cl_abap_random` (or `cl_abap_random_int` for integers) to generate pseudo-random numbers — useful for test data generation:

> 📝 **Contextual snippet** — shows the call only. **[verify: the parameters of `cl_abap_random_int=>create` and the method `cl_abap_random=>seed` in your system]**

```abap
DATA(random_generator) = cl_abap_random_int=>create( seed = cl_abap_random=>seed( )
                                                     min  = 1
                                                     max  = 100 ).
DATA(random_number) = random_generator->get_next( ).
```

> ⚠️ **Not for anything secret, and not for unique keys.** The ABAP Keyword Documentation states that these classes use a pseudo-random number generator (Mersenne Twister): the sequence follows from the seed and can be predicted, and values can repeat. Never use them for passwords, tokens or one-time codes — [Rule 8.6](../docs/ABAP-Development-Rules.md#86-never-generate-passwords-tokens-or-one-time-codes-with-cl_abap_random). For a unique key, use a UUID, for example through the released class `cl_system_uuid`.

## ✅ Best Practices

- Use built-in functions (`abs`, `ceil`, `floor`, `trunc`, `round`) instead of manual arithmetic tricks — they are more readable and self-documenting.
- Be explicit about **rounding vs. truncation** — assigning to a `p` field with fewer `DECIMALS` rounds commercially, `trunc( )` and `round( … mode = cl_abap_math=>round_down )` truncate. Choose deliberately, especially for financial calculations.
- Use `EXACT` where a calculation must not round silently — [Rule 3.7](../docs/ABAP-Development-Rules.md#37-convert-types-inline-with-conv-use-exact-when-data-must-not-be-lost).
- Use `MOD` for divisibility checks instead of `/` and comparing to an integer cast.

## ⚠️ Common Mistakes

- Assuming `floor()` and rounding to N decimals with a `p` field behave the same way — they don't.
- Using literal string values like `'7.15'` inconsistently with numeric literals — ABAP will implicitly convert, but explicit `CONV` is clearer.
- Ignoring overflow in calculations with large packed numbers: an arithmetic expression does not set `sy-subrc`; an overflow raises the catchable exception `CX_SY_ARITHMETIC_OVERFLOW`, and an assignment to a too-small target raises `CX_SY_CONVERSION_OVERFLOW`.
- Using `cl_abap_random` for keys that must be unique or values that must be secret.

## 🎤 Interview & Review Checkpoints

- Know the difference between `ceil`, `floor`, `trunc`, `round`, and rounding via `DECIMALS`.
- Be able to explain how `MOD` works with negative numbers in ABAP: the remainder is never negative.

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md) — packed number (`p`) type and decimals
- [05-Control-Statements](../05-Control-Statements/README.md) — using calculated values in conditions
- [20-Best-Practices](../20-Best-Practices/README.md) — constants and the review checklist
