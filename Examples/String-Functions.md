# String Functions

## 📖 Introduction

Common string manipulation patterns: concatenation with string templates, searching, case conversion, and pattern matching.

## 🧵 Concatenation

```abap
DATA(lv_first_name) = `Ada`.
DATA(lv_last_name)  = `Lovelace`.

" String templates, with && to concatenate two templates
DATA(lv_full_name) = |My name is { lv_first_name }| && | { lv_last_name }|.

" Building a URL from parts
DATA(lv_link) = |{ lv_base_url }main/{ iv_company_code },{ iv_business_area }|.

" Inserting a literal newline inside a string template
DATA(lv_two_lines) = |{ lv_first_name }{ cl_abap_char_utilities=>newline }{ lv_last_name }|.

" COND inside a string template to build a combined display value.
" Give COND an explicit type when the branches are literals - with # the type
" is taken from the first THEN operand, which is easy to get wrong.
DATA(lv_display) = COND string( WHEN ls_value-value IS INITIAL
                                THEN ls_fallback-value
                                ELSE |{ ls_value-value } / { ls_fallback-value }| ).

" Building a value from substring offsets
DATA(lv_ship_point) = |{ ls_storage_location-werks+0(2) }01|.
```

## 🔎 Checking a Single Character (Offset Access)

```abap
IF ls_data-waers+0(1) = 'A' OR ls_data-waers+0(1) = 'T'.
ENDIF.
```
`field+offset(length)` extracts a substring — `waers+0(1)` is the first character of `waers`.

## 🧹 CONDENSE

```abap
CONDENSE lv_full_name NO-GAPS.
```
`NO-GAPS` removes **all** spaces (not just leading/trailing) — useful when building a compact key from concatenated text fields.

## 🔍 Pattern Matching — `CP` (Contains Pattern)

```abap
IF lv_data CP 'P*'.
ENDIF.
```
`CP` supports simple wildcards and is **case-insensitive**:

| Symbol | Meaning |
|---|---|
| `*` | any character sequence (including none) |
| `+` | exactly one arbitrary character |
| `#` | escape character — `#*` matches a literal `*` |

Use `#` to escape when the search term itself may contain `*` or `+`. For a case-**sensitive** match, compare with `=` or use `find( )`.

## 📏 Length & Built-in String Functions

```abap
DATA(lv_length)   = strlen( lv_text ).
DATA(lv_upper)    = to_upper( lv_text ).
DATA(lv_lower)    = to_lower( lv_text ).
DATA(lv_trimmed)  = condense( lv_text ).
DATA(lv_part)     = substring( val = lv_text off = 0 len = 4 ).
DATA(lv_position) = find( val = lv_text sub = 'ABC' ).      " -1 if not found
DATA(lv_count)    = count( val = lv_text sub = 'A' ).
DATA(lv_replaced) = replace( val = lv_text sub = ',' with = '.' occ = 0 ).
DATA(lv_joined)   = concat_lines_of( table = lt_parts sep = `, ` ).
```

> 💡 The built-in functions are expressions: they return a value instead of modifying their argument in place, so they compose naturally inside string templates and other expressions. Prefer them over the older statement forms in new code.

## 🔠 Case Conversion

```abap
DATA lv_line TYPE c LENGTH 10 VALUE 'example'.

" Statement form - operates in place, on a character-like field
TRANSLATE lv_line TO UPPER CASE.

" Functional forms
DATA(lv_upper) = to_upper( lv_line ).
DATA(lv_lower) = to_lower( lv_line ).

" Inside a string template
DATA(lv_line_upper) = |{ lv_line CASE = (cl_abap_format=>c_upper) }|.
DATA(lv_line_lower) = |{ lv_line CASE = (cl_abap_format=>c_lower) }|.
```

## 🔎 FIND — Searching Text

```abap
" Find a substring and get its position
FIND 'Lovelace' IN lv_text
     MATCH OFFSET DATA(lv_offset)
     MATCH LENGTH DATA(lv_match_len).

IF sy-subrc = 0.
  DATA(lv_found) = lv_text+lv_offset(lv_match_len).
ENDIF.

" Case-insensitive search across every line of an internal table
FIND FIRST OCCURRENCE OF 'error' IN TABLE lt_log
     IGNORING CASE
     MATCH LINE DATA(lv_line_index).

" Functional form - returns the offset, or -1 when not found
DATA(lv_pos) = find( val = lv_text sub = 'Lovelace' ).
```

> **Lifecycle:** the older `SEARCH ... FOR` statement is `LEGACY / HISTORICAL REFERENCE` — it is documented as obsolete and superseded by `FIND`. You will meet it in existing code (it sets `sy-subrc` and `sy-fdpos`); write `FIND` in new code.

## ♻️ Replace

```abap
" Replace all occurrences of a literal in a single field
REPLACE ALL OCCURRENCES OF ',' IN lv_text WITH '.'.

" Across every line of an internal table of strings
REPLACE ALL OCCURRENCES OF 'old' IN TABLE lt_lines WITH 'new'.

" Functional form (occ = 0 means "all occurrences")
DATA(lv_clean) = replace( val = lv_text sub = ',' with = '.' occ = 0 ).

" Regular expressions - see the note below on PCRE
REPLACE ALL OCCURRENCES OF PCRE '\s+' IN lv_text WITH ` `.
```

> ⚠️ **VERSION-DEPENDENT:** newer releases provide the `PCRE` addition for regular expressions, and document the older `REGEX` addition as superseded. Check which is available on your target release before choosing. The obsolete short form `REPLACE f1 WITH f2 INTO g` also still appears in older code — recognise it, but write one of the forms above.

## ✅ Best Practices

- Prefer string templates (`|...|`) over `CONCATENATE`, and built-in functions over the older statement forms.
- Prefer `FIND` over `SEARCH`.
- Use `CONDENSE ... NO-GAPS` deliberately — it removes *all* spaces; plain `CONDENSE` trims and collapses runs of blanks.
- Use a regular expression only when a literal or `CP` pattern will not do — regex has a real cost over large tables.
- Escape `*` and `+` with `#` when a `CP` pattern may contain them as literals.

## ⚠️ Common Mistakes

- Confusing `CONDENSE` (trim and collapse) with `CONDENSE ... NO-GAPS` (remove every space).
- Assuming `CP` is case-sensitive. It is not — use `=` or `find( )` when case matters.
- Using an unescaped `*` or `+` in a `CP` pattern built from user input.
- Declaring a variable with the obsolete `DATA lv_x(10)` length syntax instead of `TYPE c LENGTH 10`.
- Reusing an inline-declared name (`DATA(lv_x)`) in a later snippet in the same program — each name may be declared only once.

## 🎤 Interview & Review Checkpoints

- Know the difference between `CONDENSE`, `SHIFT ... LEFT DELETING LEADING`, and `TRANSLATE`.
- Explain the difference between `CP` and `FIND`, including case sensitivity.
- Be able to explain `sy-fdpos`, and why `FIND ... MATCH OFFSET` is clearer.
- Explain when a built-in string function is preferable to the equivalent statement.

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md)
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md)
