# String Functions

## 📖 Introduction

Common string manipulation patterns: concatenation with string templates, searching, case conversion, and pattern matching.

## 🧵 Concatenation

```abap
DATA(lv_name) = 'Serhat'.

" String templates with the concatenation operator (&&) for multi-line building
DATA(lv_full_name) = |My name is { lv_name }| && | , and surname is { lv_surname }|.
DATA(lv_link)      = |{ lv_link }main/{ iv_company_code },{ iv_business_area }|.

" Inserting a literal newline inside a string template
DATA(lv_full_name) = |Serhat{ cl_abap_char_utilities=>newline }Mercan|.

" COND inside a string template to build a "combined" display value
DATA(lv_value) = COND #( WHEN ls_value-value IS INITIAL THEN lx_value-value
                                                        ELSE |{ ls_value-value } / { lx_value-value }| ).

" Building a value from substring offsets
lv_ship_point = |{ ls_storage_location-werks+0(2) }01|.
```

## 🔎 Checking a Single Character (Offset Access)

```abap
IF lt_data-waers+0(1) = 'A' OR lt_data-waers+0(1) = 'T'.
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
`CP` supports simple wildcards (`*` = any characters, `+` = any single character) and is case-insensitive by default depending on `SET EXTENDED CHECK`/system settings — commonly used for prefix/suffix checks.

## 📏 Length

```abap
DATA(lv_length) = strlen( lv_data ).
```

## 🔠 Case Conversion

```abap
DATA lv_line(10) VALUE 'serhat'.

TRANSLATE lv_line TO UPPER CASE.
TRANSLATE lv_line TO LOWER CASE.

" Functional equivalents using string templates
DATA(lv_line_upper) = |{ lv_line CASE = (cl_abap_format=>c_upper) }|.
DATA(lv_line_lower) = |{ lv_line CASE = (cl_abap_format=>c_lower) }|.
```

## ♻️ Replace

```abap
" Regex-based replace across every line of an internal table
REPLACE ALL OCCURRENCES OF REGEX 'A' IN TABLE lt_data WITH 'aaaaa'.

" Replace all occurrences of a literal character in a single field
REPLACE ALL OCCURRENCES OF '.' IN lt_data-value WITH space.

" Replace only the first occurrence
REPLACE ',' WITH '.' INTO lt_data.
```

## 🔦 SEARCH

```abap
SEARCH surname FOR 'Serhat   '.
SEARCH surname FOR 'Ser*'.
SEARCH surname FOR '*can'.
WRITE: / 'Searching for "Serhat    "',
       / 'sy-subrc:', sy-subrc, / 'sy-fdpos:', sy-fdpos.
```
`sy-fdpos` after a successful `SEARCH` holds the **offset** where the match was found — useful when you need the position, not just whether it matched.

## ✅ Best Practices

- Prefer string templates (`|...|`) over `CONCATENATE` for readability in modern ABAP.
- Use `CONDENSE ... NO-GAPS` deliberately — it removes *all* spaces, which is not always what you want (use plain `CONDENSE` to just trim leading/trailing spaces).
- Use `REGEX` replace only when a simple literal/`CP` pattern isn't sufficient — regex has a performance cost for very large tables.

## ⚠️ Common Mistakes

- Confusing `CONDENSE` (trim) with `CONDENSE ... NO-GAPS` (remove all spaces) — pick the wrong one and either whitespace remains or words get glued together.
- Forgetting `TRANSLATE ... TO UPPER/LOWER CASE` only works on fixed-length `c`-type fields the way shown; for `string` type, the string-template `CASE =` approach or `to_upper( )`/`to_lower( )` functions are more idiomatic.
- Using `CP`/`SEARCH` wildcard patterns without escaping when the search term itself may contain `*`/`+`.

## 🎤 Interview Tips

- Know the difference between `CONDENSE`, `SHIFT ... LEFT DELETING LEADING`, and `TRANSLATE`.
- Be able to explain `sy-fdpos` after a `SEARCH` or `FIND` statement.

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md)
