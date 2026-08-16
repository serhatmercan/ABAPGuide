# Date & Time

## 📖 Introduction

Date/time handling in ABAP mixes native types (`d`, `t`, `timestampl`), string-template formatting options, and helper classes/function modules. This chapter is a quick reference for the most common conversions.

## 🗓️ Date Formatting

```abap
DATA lv_date TYPE d VALUE '20180715'.       " DATS is always YYYYMMDD internally

" Rearranging a DATS value (YYYYMMDD) into DD.MM.YYYY
DATA(lv_display_date) = |{ lv_date+6(2) }.{ lv_date+4(2) }.{ lv_date+0(4) }|.

" Parsing an ISO STRING (YYYY-MM-DD) into a DATS value.
" The offsets differ because the source has separators - always know which
" format you are slicing.
DATA lv_iso_input TYPE string VALUE '2018-07-15'.
DATA(lv_from_iso) = CONV d( |{ lv_iso_input+0(4) }{ lv_iso_input+5(2) }{ lv_iso_input+8(2) }| ).

" Built-in DATE format options in string templates - prefer these
DATA(lv_date_iso)  = |{ lv_date DATE = ISO }|.   " YYYY-MM-DD
DATA(lv_date_user) = |{ lv_date DATE = USER }|.  " the user's logon date format
```

## 🧮 Date Calculations

```abap
" Current date. cl_abap_context_info is the released, ABAP Cloud-safe way to
" read context information, and it is easier to substitute in a test than sy-datum.
DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

" DATS values are numeric internally, so plain arithmetic works for day offsets
DATA(lv_yesterday)    = lv_today - 1.
DATA(lv_in_thirty)    = lv_today + 30.
DATA(lv_days_between) = lv_date_to - lv_date_from.

" Month/year offsets need calendar logic - use a function module for those
DATA lv_two_years_ago TYPE d.

CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
  EXPORTING date      = lv_today
            years     = 2
            signum    = '-'
  IMPORTING calc_date = lv_two_years_ago.
```

> 📝 **NEEDS OFFICIAL VERIFICATION** — confirm the signature and availability of any date function module in SE37 for your release. Avoid using industry-component helper classes (for example the Real Estate `CL_RECA_DATE`) as a general-purpose date API: they are component-specific, not released for general use, and may be unavailable in your system or under ABAP Cloud.

## 📐 Declarations & `WRITE ... TO` Formatting

```abap
" Basic date declarations
DATA lv_date_a TYPE d VALUE '20180715'.
DATA lv_date_b LIKE sy-datum.

" Format a date into a display field.
" Use a DATE FORMAT keyword - NOT an edit mask. An edit mask is applied
" positionally to the raw YYYYMMDD content, so '__.__.____' against
" 20180715 produces '20.18.0715', not '15.07.2018'.
DATA lv_display TYPE c LENGTH 10.
WRITE lv_date_a TO lv_display DD/MM/YYYY.

" Correct word order is: WRITE source TO target [format].
```

## ⏱️ Time Formatting

```abap
DATA lv_time TYPE t VALUE '145330'.

" String template with the built-in TIME format option
DATA(lv_time_user) = |{ lv_time TIME = USER }|.
DATA(lv_time_iso)  = |{ lv_time TIME = ISO }|.

" Manual HH:MM:SS from a TIMS value
DATA(lv_time_text) = |{ lv_time+0(2) }:{ lv_time+2(2) }:{ lv_time+4(2) }|.

" WRITE ... TO ... USING EDIT MASK - note TO comes BEFORE USING
DATA lv_mask_time TYPE c LENGTH 10.
WRITE lv_time TO lv_mask_time USING EDIT MASK '__:__:__'.
```

> ⚠️ String templates support `DATE =`, `TIME =`, `ALPHA =`, `CASE =`, `NUMBER =` and similar format options. There is **no** `USING EDIT MASK` option inside a string template — that addition belongs to the `WRITE ... TO` statement only.

## 🌍 Time Zone

```abap
" The user's time zone (released, ABAP Cloud-safe)
DATA(lv_user_tzone) = cl_abap_context_info=>get_user_time_zone( ).

" The classic system field for the user's time zone
DATA(lv_zonlo) = sy-zonlo.
```

> 📝 Use a verified mechanism for time zones rather than guessing at a helper class. `CL_ABAP_CONTEXT_INFO` and `sy-zonlo` are both well established; check SE24 before adopting anything else.

## 🔁 Converting a Free-Text Value to a Date

Useful when accepting dates from multiple upstream formats (Excel serial dates, ISO strings, or plain `YYYYMMDD`):

```abap
CLASS lcl_date_parser DEFINITION.
  PUBLIC SECTION.
    METHODS convert_value_to_date IMPORTING iv_value       TYPE string
                                  RETURNING VALUE(rv_date) TYPE d.
ENDCLASS.

CLASS lcl_date_parser IMPLEMENTATION.
  METHOD convert_value_to_date.
    DATA(lv_input) = condense( iv_value ).

    IF lv_input IS INITIAL.
      RETURN.                                   " initial date
    ENDIF.

    IF lv_input CA '-'.
      " ISO string: YYYY-MM-DD
      rv_date = |{ lv_input+0(4) }{ lv_input+5(2) }{ lv_input+8(2) }|.

    ELSEIF lv_input CA '.'.
      " Localised string: DD.MM.YYYY
      rv_date = |{ lv_input+6(4) }{ lv_input+3(2) }{ lv_input+0(2) }|.

    ELSEIF lv_input CO '0123456789' AND strlen( lv_input ) = 8.
      " Already YYYYMMDD
      rv_date = lv_input.

    ELSEIF lv_input CO '0123456789'.
      " Purely numeric but not 8 digits: an Excel SERIAL date (a day count,
      " with no separators at all)
      CALL FUNCTION 'KCD_EXCEL_DATE_CONVERT'
        EXPORTING excel_date = lv_input
        IMPORTING sap_date   = rv_date.

    ELSE.
      RAISE EXCEPTION TYPE zcx_invalid_date_format.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

> 🧠 `CA` ("contains any") tests whether a string contains any of the given characters; `CO` ("contains only") tests that it contains nothing else. Note that an Excel **serial** date is a plain day count with no separators — a value containing `.` is a localised `DD.MM.YYYY` string, not a serial. Getting those two branches the wrong way round is an easy and expensive mistake.

## ✅ Validating a Time Value

```abap
DATA lv_time_input  TYPE c LENGTH 8.
DATA lv_time_output TYPE t.

CALL FUNCTION 'CONVERT_TIME_INPUT'
  EXPORTING  input                     = lv_time_input
             plausibility_check        = abap_true
  IMPORTING  output                    = lv_time_output
  EXCEPTIONS plausibility_check_failed = 1
             wrong_format_in_input     = 2
             OTHERS                    = 3.

IF sy-subrc <> 0.
  MESSAGE 'Invalid time value' TYPE 'E'.
ENDIF.
```

> 💡 Type the variables for what they actually hold (`TYPE t` for a time). Reaching for an unrelated industry-component data element because it happens to be the right length makes the code harder to read and ties it to a component you may not have.

## ✅ Best Practices

- Prefer `|{ date DATE = ISO }|` / `|{ date DATE = USER }|` string-template formatting over manual substring rearrangement — clearer intent, less error-prone.
- Use a `DATE`/`TIME` format keyword with `WRITE ... TO`, not an edit mask: an edit mask is applied positionally to the raw internal value.
- Always validate externally-sourced date strings (uploads, RFC input) before converting — a malformed string silently produces a wrong date rather than an error.
- Use `cl_abap_context_info=>get_system_date( )` / `get_user_time_zone( )` rather than the `sy-` fields in code you want to test, and because they are the released form for ABAP Cloud.
- Use plain arithmetic for day offsets; use a calendar function for month and year offsets.

## ⚠️ Common Mistakes

- Slicing a date string with offsets that belong to a **different** format — `+5(2)` and `+8(2)` are for `YYYY-MM-DD`, not for a `DATS` field.
- Using `USING EDIT MASK` on a date and expecting it to reorder the components. It does not; it only inserts separators positionally.
- Writing `WRITE src USING EDIT MASK m TO tgt` — the correct order is `WRITE src TO tgt USING EDIT MASK m`.
- Assuming a value containing `.` is an Excel serial date.
- Relying on `DATE = USER` for a machine-to-machine interface; use `DATE = ISO` there.

## 🎤 Interview & Review Checkpoints

- Explain the difference between `DATE = ISO` and `DATE = USER` in string templates.
- Explain why an edit mask cannot reorder a date's components.
- Be ready to explain how to safely parse dates coming from an Excel upload vs. a REST/OData payload.
- Explain why `cl_abap_context_info` is preferred over `sy-datum` in new code.

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md)
- [09-Modularization](../09-Modularization/README.md)
