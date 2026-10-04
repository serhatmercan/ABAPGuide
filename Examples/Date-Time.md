# Date & Time

> **Lifecycle:** `CURRENT / RECOMMENDED`. Older forms you will still meet are labelled where they appear. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

Date/time handling in ABAP mixes native types (`d`, `t`, `timestampl`), string-template formatting options, and helper classes/function modules. This chapter is a quick reference for the most common conversions.

## 🗓️ Date Formatting

```abap
DATA date TYPE d VALUE '20180715'.       " DATS is always YYYYMMDD internally

" Rearranging a DATS value (YYYYMMDD) into DD.MM.YYYY
DATA(display_date) = |{ date+6(2) }.{ date+4(2) }.{ date+0(4) }|.

" Parsing an ISO STRING (YYYY-MM-DD) into a DATS value.
" The offsets differ because the source has separators - always know which
" format you are slicing.
DATA iso_input TYPE string VALUE '2018-07-15'.
DATA(date_from_iso) = CONV d( |{ iso_input+0(4) }{ iso_input+5(2) }{ iso_input+8(2) }| ).

" Built-in DATE format options in string templates - prefer these
DATA(date_iso)  = |{ date DATE = ISO }|.   " YYYY-MM-DD
DATA(date_user) = |{ date DATE = USER }|.  " the user's logon date format
```

## 🧮 Date Calculations

> 📝 **Contextual snippet** — `date_from` and `date_to` are assumed.

```abap
" Current date. cl_abap_context_info is in the list of released APIs for ABAP
" for Cloud Development, and it is easier to substitute in a test than sy-datum.
DATA(today) = cl_abap_context_info=>get_system_date( ).

" DATS values are numeric internally, so plain arithmetic works for day offsets
DATA(yesterday)      = today - 1.
DATA(in_thirty_days) = today + 30.
DATA(days_between)   = date_to - date_from.

" Month/year offsets need calendar logic - use a function module for those
DATA two_years_ago TYPE d.

" DAYS, MONTHS and YEARS are all mandatory parameters
CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
  EXPORTING date      = today
            days      = 0
            months    = 0
            years     = 2
            signum    = '-'
  IMPORTING calc_date = two_years_ago.
```

> 📝 Confirm the signature and availability of any date function module in SE37 for your release. Avoid using industry-component helper classes (for example the Real Estate `CL_RECA_DATE`) as a general-purpose date API: they are component-specific, not released for general use, and may be unavailable in your system or under ABAP Cloud.

## 📐 Declarations & `WRITE ... TO` Formatting

```abap
" Basic date declarations
DATA delivery_date TYPE d VALUE '20180715'.
DATA posting_date  LIKE sy-datum.

" Format a date into a display field.
" Use a date format addition - NOT an edit mask. An edit mask is applied
" positionally to the raw YYYYMMDD content, so '__.__.____' against
" 20180715 produces '20.18.0715', not '15.07.2018'.
" The order of day and month and the separator come from the date format
" setting (user defaults or SET COUNTRY); DD/MM/YYYY and MM/DD/YYYY have the
" same effect and only choose the four-digit year.
DATA display_text TYPE c LENGTH 10.
WRITE delivery_date TO display_text DD/MM/YYYY.

" Correct word order is: WRITE source TO target [format].
```

## ⏱️ Time Formatting

```abap
DATA time TYPE t VALUE '145330'.

" String template with the built-in TIME format option
DATA(time_user) = |{ time TIME = USER }|.
DATA(time_iso)  = |{ time TIME = ISO }|.

" Manual HH:MM:SS from a TIMS value
DATA(time_text) = |{ time+0(2) }:{ time+2(2) }:{ time+4(2) }|.

" WRITE ... TO ... USING EDIT MASK - note TO comes BEFORE USING
DATA masked_time TYPE c LENGTH 10.
WRITE time TO masked_time USING EDIT MASK '__:__:__'.
```

> ⚠️ String templates support `DATE =`, `TIME =`, `ALPHA =`, `CASE =`, `NUMBER =` and similar format options. There is **no** `USING EDIT MASK` option inside a string template — that addition belongs to the `WRITE ... TO` statement only.

## 🌍 Time Zone

```abap
" The user's time zone (released, ABAP Cloud-safe)
" get_user_time_zone( ) raises CX_ABAP_CONTEXT_INFO_ERROR
TRY.
    DATA(user_time_zone) = cl_abap_context_info=>get_user_time_zone( ).
  CATCH cx_abap_context_info_error INTO DATA(context_error).
    " handle or convert the error (Rule 6.8)
ENDTRY.

" The classic system field for the user's time zone
DATA(time_zone) = sy-zonlo.
```

> 📝 Use a verified mechanism for time zones rather than guessing at a helper class. `CL_ABAP_CONTEXT_INFO` (released for ABAP for Cloud Development) and `sy-zonlo` are both well established; check SE24 before adopting anything else.

## 🔁 Converting a Free-Text Value to a Date

Useful when accepting dates from multiple upstream formats (Excel serial dates, ISO strings, or plain `YYYYMMDD`):

> 📝 **Contextual snippet** — `zcx_zsm_invalid_date_format` is a placeholder exception class. Despite its name, `KCD_EXCEL_DATE_CONVERT` converts a date string with separators, not an Excel serial number. Its optional parameter `DATE_FORMAT` sets the order of the parts; the default `'TMJ'` means day, month, year. A two-digit year above 50 becomes 19xx, any other 20xx.

```abap
CLASS lcl_date_parser DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS convert_value_to_date IMPORTING value         TYPE string
                                  RETURNING VALUE(result) TYPE d
                                  RAISING   zcx_zsm_invalid_date_format.
ENDCLASS.

CLASS lcl_date_parser IMPLEMENTATION.
  METHOD convert_value_to_date.
    " Excel's 1900 date system counts a 29 February 1900 that never
    " existed, so this day zero is right for every serial from 61 on
    CONSTANTS excel_day_zero TYPE d VALUE '18991230'.

    DATA(input) = condense( value ).

    IF input IS INITIAL.
      RETURN.                                   " initial date
    ENDIF.

    IF input CA '-'.
      " ISO string: YYYY-MM-DD
      result = |{ input+0(4) }{ input+5(2) }{ input+8(2) }|.

    ELSEIF input CA '.'.
      " Localised string DD.MM.YYYY or DD.MM.YY; the function module
      " also expands a two-digit year
      CALL FUNCTION 'KCD_EXCEL_DATE_CONVERT'
        EXPORTING excel_date  = input
                  date_format = 'TMJ'
        IMPORTING sap_date    = result.

    ELSEIF input CO '0123456789' AND strlen( input ) = 8.
      " Already YYYYMMDD
      result = input.

    ELSEIF input CO '0123456789'.
      " Purely numeric but not 8 digits: an Excel SERIAL date (a day count,
      " with no separators at all)
      result = excel_day_zero + CONV i( input ).

    ELSE.
      RAISE EXCEPTION TYPE zcx_zsm_invalid_date_format.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

> 🧠 `CA` ("contains any") tests whether a string contains any of the given characters; `CO` ("contains only") tests that it contains nothing else. Note that an Excel **serial** date is a plain day count with no separators — a value containing `.` is a localised `DD.MM.YYYY` string, not a serial. Getting those two branches the wrong way round is an easy and expensive mistake. Check the result for a valid calendar date before you use it.

## ✅ Validating a Time Value

> 📝 **Contextual snippet** — a UI-layer program; `zsm_msg` is the placeholder message class. `PLAUSIBILITY_CHECK` defaults to `'X'`.

```abap
DATA time_input  TYPE c LENGTH 8.
DATA time_output TYPE t.

CALL FUNCTION 'CONVERT_TIME_INPUT'
  EXPORTING  input                     = time_input
             plausibility_check        = abap_true
  IMPORTING  output                    = time_output
  EXCEPTIONS plausibility_check_failed = 1
             wrong_format_in_input     = 2
             OTHERS                    = 3.

IF sy-subrc <> 0.
  MESSAGE e012(zsm_msg) WITH time_input.
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

- [02-Data-Types](../02-Data-Types/README.md) — the types `d`, `t` and time stamps
- [09-Modularization](../09-Modularization/README.md) — conversion exits
- [Conversion.md](Conversion.md) — time stamp conversion
