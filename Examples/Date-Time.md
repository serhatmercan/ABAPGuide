# Date & Time

## 📖 Introduction

Date/time handling in ABAP mixes native types (`d`, `t`, `timestampl`), string-template formatting options, and helper classes/function modules. This chapter is a quick reference for the most common conversions.

## 🗓️ Date Formatting

```abap
" Rearranging a raw YYYYMMDD-like string into YYYYMMDD explicitly (e.g., from a differently-formatted source field)
DATA(lv_format_date) = |{ ls_data-ersda+0(4) }{ ls_data-ersda+5(2) }{ ls_data-ersda+8(2) }|.

" Rearranging into DD.MM.YYYY from a YYYYMMDD-like value
DATA(lv_format_date) = |{ lv_date+6(2) }.{ lv_date+4(2) }.{ lv_date+0(4) }|.

" Built-in DATE format options in string templates
DATA(lv_date_format1) = |{ lv_date DATE = ISO }|.   " YYYY-MM-DD
DATA(lv_date_format2) = |{ lv_date DATE = USER }|.  " Format based on the user's logon settings
```

## 🧮 Date Calculations

```abap
DATA(lv_date)   = cl_abap_context_info=>get_system_date( ).
DATA(lv_result) = cl_reca_date=>add_to_date( id_date  = sy-datum
                                             id_years = -2 ).
WRITE: / 'Two years ago:', lv_result.
```

## 📐 Declarations & `WRITE ... TO` with Edit Masks

```abap
" Basic date declarations
DATA lv_date TYPE d VALUE '20180715'.
DATA lv_date LIKE sy-datum.

" Formatting a date with an edit mask into a display field
DATA lv_valid TYPE datuv_bi.
WRITE sy-datum TO lv_valid USING EDIT MASK '__.__.____'.

" Formatting with a built-in date format keyword
DATA lv_date TYPE char10.
WRITE ls_data-date TO lv_date DD/MM/YYYY.
```

## ⏱️ Time Formatting

```abap
" Time with a string template edit mask
DATA(lv_uzeit) = |{ ls_data-value USING EDIT MASK '__:__:__' }|.

" Time with WRITE ... USING EDIT MASK
DATA lv_mask_time TYPE char10.
WRITE ls_data-time USING EDIT MASK '__:__' TO lv_mask_time.

" Basic time declarations
DATA lv_time TYPE t VALUE '145330'.
DATA lv_time LIKE sy-uzeit.
```

## 🌍 Time Zone

```abap
DATA(lv_timezone) = cl_abap_tstmp=>get_system_timezone( ).
```

## 🔁 Converting a Free-Text Value to a Date

Useful when accepting dates from multiple upstream formats (Excel serial dates, ISO strings, or plain `YYYYMMDD`):

```abap
DATA iv_value TYPE text255.
DATA rv_date  TYPE datum.

METHOD convert_value_to_date.
  IF iv_value IS INITIAL.
    rv_date = '00000000'.
  ELSEIF iv_value CA '.'.
    CALL FUNCTION 'KCD_EXCEL_DATE_CONVERT'
      EXPORTING excel_date = iv_value
      IMPORTING sap_date   = rv_date.
  ELSEIF iv_value CA '-'.
    rv_date = iv_value(4) && iv_value+5(2) && iv_value+8(2).
  ELSE.
    rv_date = iv_value.
  ENDIF.
ENDMETHOD.
```
> 🧠 `CA` ("contains any") checks whether the string contains any of the given characters — here used to detect which date format style was likely provided (`.` → Excel serial, `-` → ISO string, else → assume raw `YYYYMMDD`).

## ✅ Validating a Time Value

```abap
DATA lv_input  TYPE uareg.
DATA lv_output TYPE ualend.

CALL FUNCTION 'CONVERT_TIME_INPUT'
  EXPORTING  input                     = lv_input
  IMPORTING  output                    = lv_output
  EXCEPTIONS plausibility_check_failed = 1
             wrong_format_in_input     = 2
             OTHERS                    = 3.
```

## ✅ Best Practices

- Prefer `|{ date DATE = ISO }|`/`|{ date DATE = USER }|` string-template formatting over manual substring rearrangement when possible — clearer intent, less error-prone.
- Always validate externally-sourced date strings (uploads, RFC input) before converting — a malformed string can silently produce a wrong date rather than an error.
- Use `cl_abap_context_info=>get_system_date( )`/`get_system_time( )` instead of `sy-datum`/`sy-uzeit` directly in unit-testable code, since they can be mocked more easily in some testing setups.

## ⚠️ Common Mistakes

- Manually slicing date strings (`+0(4)`, `+4(2)`, `+6(2)`) without validating the source format first — silently produces garbage if the input format differs from what's expected.
- Confusing `DATE = USER` (user-specific format, e.g., `MM/DD/YYYY` vs `DD.MM.YYYY` depending on logon settings) with a fixed format — don't rely on it for machine-to-machine interfaces; use `DATE = ISO` there instead.

## 🎤 Interview Tips

- Explain the difference between `DATE = ISO` and `DATE = USER` in string templates.
- Be ready to explain how to safely parse dates coming from an Excel upload vs. a REST/OData payload.

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md)
- [09-Modularization](../09-Modularization/README.md)
