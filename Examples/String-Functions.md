# String Functions

## 📖 Introduction

Common string manipulation patterns: concatenation with string templates, searching, case conversion, and pattern matching.

## 🧵 Concatenation

```abap
DATA(first_name) = `Ada`.
DATA(last_name)  = `Lovelace`.

" String templates, with && to concatenate two templates
DATA(full_name) = |My name is { first_name }| && | { last_name }|.

" Building a URL from parts
DATA(link) = |{ base_url }main/{ company_code },{ business_area }|.

" Inserting a literal newline inside a string template
DATA(two_lines) = |{ first_name }{ cl_abap_char_utilities=>newline }{ last_name }|.

" COND inside a string template to build a combined display value.
" Give COND an explicit type when the branches are literals - with # the type
" is taken from the first THEN operand, which is easy to get wrong.
DATA(display_value) = COND string( WHEN primary-value IS INITIAL
                                   THEN fallback-value
                                   ELSE |{ primary-value } / { fallback-value }| ).

" Building a value from substring offsets
DATA(shipping_point) = |{ storage_location-werks+0(2) }01|.
```

## 🔎 Checking a Single Character (Offset Access)

```abap
IF payment-waers+0(1) = 'A' OR payment-waers+0(1) = 'T'.
ENDIF.
```
`field+offset(length)` extracts a substring — `waers+0(1)` is the first character of `waers`.

## 🧹 CONDENSE

```abap
CONDENSE full_name NO-GAPS.
```
`NO-GAPS` removes **all** spaces (not just leading/trailing) — useful when building a compact key from concatenated text fields.

## 🔍 Pattern Matching — `CP` (Contains Pattern)

```abap
IF text CP 'P*'.
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
DATA(text_length)   = strlen( text ).
DATA(upper_text)    = to_upper( text ).
DATA(lower_text)    = to_lower( text ).
DATA(trimmed_text)  = condense( text ).
DATA(first_part)    = substring( val = text off = 0 len = 4 ).
DATA(position)      = find( val = text sub = 'ABC' ).      " -1 if not found
DATA(count_a)       = count( val = text sub = 'A' ).
DATA(replaced_text) = replace( val = text sub = ',' with = '.' occ = 0 ).
DATA(joined_text)   = concat_lines_of( table = parts sep = `, ` ).
```

> 💡 The built-in functions are expressions: they return a value instead of modifying their argument in place, so they compose naturally inside string templates and other expressions. Prefer them over the older statement forms in new code.

## 🔠 Case Conversion

```abap
DATA word TYPE c LENGTH 10 VALUE 'example'.

" Statement form - operates in place, on a character-like field
TRANSLATE word TO UPPER CASE.

" Functional forms
DATA(upper_text) = to_upper( word ).
DATA(lower_text) = to_lower( word ).

" Inside a string template
DATA(word_upper) = |{ word CASE = (cl_abap_format=>c_upper) }|.
DATA(word_lower) = |{ word CASE = (cl_abap_format=>c_lower) }|.
```

## 🔎 FIND — Searching Text

```abap
" Find a substring and get its position
FIND 'Lovelace' IN text
     MATCH OFFSET DATA(match_offset)
     MATCH LENGTH DATA(match_length).

IF sy-subrc = 0.
  DATA(found_text) = text+match_offset(match_length).
ENDIF.

" Case-insensitive search across every word of an internal table
FIND FIRST OCCURRENCE OF 'error' IN TABLE log_lines
     IGNORING CASE
     MATCH LINE DATA(line_index).

" Functional form - returns the offset, or -1 when not found
DATA(position_of_name) = find( val = text sub = 'Lovelace' ).
```

> **Lifecycle:** the older `SEARCH ... FOR` statement is `LEGACY / HISTORICAL REFERENCE` — it is documented as obsolete and superseded by `FIND`. You will meet it in existing code (it sets `sy-subrc` and `sy-fdpos`); write `FIND` in new code.

## ♻️ Replace

```abap
" Replace all occurrences of a literal in a single field
REPLACE ALL OCCURRENCES OF ',' IN text WITH '.'.

" Across every word of an internal table of strings
REPLACE ALL OCCURRENCES OF 'old' IN TABLE text_lines WITH 'new'.

" Functional form (occ = 0 means "all occurrences")
DATA(clean_text) = replace( val = text sub = ',' with = '.' occ = 0 ).

" Regular expressions - see the note below on PCRE
REPLACE ALL OCCURRENCES OF PCRE '\s+' IN text WITH ` `.
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
- Declaring a variable with the parenthesised length `DATA text(10)` instead of `TYPE c LENGTH 10`. The parenthesised form is not obsolete, but the ABAP Keyword Documentation recommends `LENGTH` for legibility.
- Reusing an inline-declared name (`DATA(text)`) in a later snippet in the same program — each name may be declared only once.

## 🎤 Interview & Review Checkpoints

- Know the difference between `CONDENSE`, `SHIFT ... LEFT DELETING LEADING`, and `TRANSLATE`.
- Explain the difference between `CP` and `FIND`, including case sensitivity.
- Be able to explain `sy-fdpos`, and why `FIND ... MATCH OFFSET` is clearer.
- Explain when a built-in string function is preferable to the equivalent statement.

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md)
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md)
