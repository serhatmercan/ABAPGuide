# T6 — Exchange rate import with error handling

## Run metadata (operator only; not given to the assistant)

| Item | Value |
|---|---|
| Target system | On-premise (Standard ABAP) |
| Language version | Standard ABAP |
| Package | `$TMP` |
| Objects the spec requires | `ZCX_ZSM_X<run>_IMPORT_ERROR`, `ZCL_ZSM_X<run>_RATE_IMPORT` |
| Acceptance test | `acceptance/T6/` → shell class `ZCL_ZSM_X<run>_AT_IMP` |
| What the run must not do | Write table rows, use a transport |
| Rubric focus | R-C2 `MESSAGE` in a class, R-C3/R-C4 empty or `CX_ROOT` catches, R-C5 unevaluated `sy-subrc`, R-T6 items |

## Spec text (paste after the run prompt header)

Treasury uploads exchange rates as text lines. Build the parser that turns the
lines into rates or rejects the upload.

Create the exception class exactly as given (you may add ABAP Doc comments):

```abap
CLASS zcx_zsm_x<run>_import_error DEFINITION PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES line_numbers_type TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA line_numbers TYPE line_numbers_type READ-ONLY.
    METHODS constructor
      IMPORTING line_numbers TYPE line_numbers_type OPTIONAL
                previous     LIKE previous OPTIONAL.
ENDCLASS.
```

Create the class `ZCL_ZSM_X<run>_RATE_IMPORT` with exactly this public section:

```abap
  PUBLIC SECTION.
    TYPES: BEGIN OF rate,
             currency   TYPE c LENGTH 5,
             rate       TYPE p LENGTH 9 DECIMALS 5,
             valid_from TYPE d,
           END OF rate.
    TYPES rates TYPE STANDARD TABLE OF rate WITH EMPTY KEY.

    METHODS import
      IMPORTING lines         TYPE string_table
      RETURNING VALUE(result) TYPE rates
      RAISING   zcx_zsm_x<run>_import_error.
```

Each line has the form `CURRENCY;RATE;YYYYMMDD`, for example
`USD;1.08450;20260301`.

Behaviour of `import`:

- Empty lines and lines that contain only spaces are ignored.
- A line is invalid if it does not have exactly three fields, if the currency
  is empty or longer than 5 characters, if the rate is not a number or not
  greater than zero, or if the date is not a valid calendar date.
- If all non-empty lines are valid, `import` returns one rate per line, in the
  order of the lines.
- If at least one line is invalid, `import` returns nothing and raises
  `zcx_zsm_x<run>_import_error`. The exception lists the numbers of all invalid
  lines (the first line of `lines` is line 1). If a runtime conversion error
  occurred while reading an invalid line, the first such error is passed as
  the previous exception.

## Objects and names

All names with `<run>` replaced by the run ID. Every object goes to `$TMP` on
the on-premise destination.
