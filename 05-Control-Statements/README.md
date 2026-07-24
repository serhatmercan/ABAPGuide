# 05 — Control Statements

## 📖 Introduction

Control statements decide which branch of logic gets executed. This chapter covers classical `IF`/`CASE` alongside the modern **functional operators** `COND` and `SWITCH`, which let you assign a value conditionally in a single expression.

## 🔀 CASE

```abap
CASE sy-uname.
  WHEN 'X'.
  WHEN 'Y'.
  WHEN OTHERS.
ENDCASE.
```

## 🚦 CHECK

`CHECK` immediately exits the current processing block (loop, form, event) if the condition is false — use with care, since it can make control flow harder to follow.

```abap
CHECK NOT line_exists( et_return[ type = 'E' ] ).
```

## 🌿 IF / ELSE and the `COND` Operator

Classic `IF`/`ELSE` still has its place, but for **assigning a value** based on a condition, the functional `COND #( )` operator is more concise and avoids intermediate variables:

```abap
DATA(lv_begin_date) = '20200505'.
DATA(lv_end_date)   = '20200515'.

DATA(lv_status) = COND #( WHEN sy-datum < lv_begin_date THEN 'EARLY'
                          WHEN sy-datum > lv_end_date   THEN 'LATE'
                          ELSE                               'OK' ).

DATA(lv_data) = COND #( WHEN lv_lgnum = lc_lgnum
                        THEN lc_e1
                        ELSE space ).

DATA(lv_check)      = COND #( WHEN lv_confirmation_no BETWEEN 50 AND 100 THEN abap_true ELSE abap_false ).
DATA(lv_confidence) = COND #( WHEN lv_confidence CS 'good' OR lv_confidence = 'uncertain'
                              THEN abap_true
                              ELSE abap_false ).

DATA(lv_refinery) = CONV char3( COND #( WHEN is_defect->refinery = '1000' THEN 'ONE'
                                        WHEN is_defect->refinery = '1100' THEN 'TWO'
                                        WHEN is_defect->refinery = '1200' THEN 'THR' ) ).
```

## 🔁 SWITCH

`SWITCH` is the functional equivalent of `CASE`, useful for assigning a value based on a single variable's content:

```abap
DATA(lv_status) = SWITCH char10( sy-msgty
                                 WHEN 'S' THEN 'SUCCESS'
                                 WHEN 'W' THEN 'OK'
                                 WHEN 'E' THEN 'ERROR'
                                 ELSE          'UNKNOWN' ).
```

## 📊 COND vs. SWITCH vs. IF/CASE

| Construct | Best For | Returns a Value? |
|---|---|---|
| `IF` / `ELSEIF` / `ELSE` | Multiple, unrelated conditions; executing statements | ❌ No |
| `CASE` | Branching on **one** variable's exact value; executing statements | ❌ No |
| `COND #( )` | Assigning a value based on one or more conditions | ✅ Yes |
| `SWITCH #( )` | Assigning a value based on **one** variable's value | ✅ Yes |

## ✅ Best Practices

- Use `COND`/`SWITCH` when the goal is to **compute a value** — it reduces boilerplate `IF`/`ELSE` blocks with repeated assignment targets.
- Use `CASE`/`IF` when the goal is to **execute different logic/statements**, not just assign a value.
- Always include an `ELSE`/`WHEN OTHERS` branch to handle unexpected values defensively, especially in `COND`/`SWITCH` used for status mapping.

## ⚠️ Common Mistakes

- Using `COND`/`SWITCH` for complex multi-statement branches — they are expressions, not substitutes for full `IF` blocks.
- Forgetting that `COND #( ... )` without an `ELSE` returns the type's **initial value** if no condition matches, which can silently hide a "no match" case.
- Overusing `CHECK` deep inside nested loops, making it hard to trace why a loop exited early — prefer explicit `IF ... CONTINUE`/`EXIT` in modern code.

## 🎤 Interview Tips

- Be ready to rewrite a nested `IF/ELSEIF` chain as a `COND #( )` expression, and explain the trade-offs.
- Explain what happens when `CHECK` evaluates to false inside a `LOOP` vs. inside a `FORM`/method.

## 🔗 Related Chapters

- [06-Loops](../06-Loops/README.md)
- [04-Operators](../04-Operators/README.md)
