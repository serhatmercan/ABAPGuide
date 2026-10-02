# 05 — Control Statements

> **Lifecycle:** `CURRENT / RECOMMENDED`. `IF`, `CASE`, `COND` and `SWITCH` are current; `CHECK` outside the start of a method is `CLASSIC BUT STILL RELEVANT`. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-classic-but-still-relevant).

## 📖 Introduction

Control statements decide which branch of logic gets executed. This chapter covers classical `IF`/`CASE` alongside the modern **functional operators** `COND` and `SWITCH`, which let you assign a value conditionally in a single expression.

## 🔀 CASE

> 📝 **Contextual snippet** — assumes a structure `order` and a structured constant `order_types` with the components `standard` and `returns`.

```abap
CASE order-order_type.
  WHEN order_types-standard.
  WHEN order_types-returns.
  WHEN OTHERS.
ENDCASE.
```

> 💡 Compare against named constants rather than literal codes — [Rule 4.1](../docs/ABAP-Development-Rules.md#41-replace-magic-literals-with-named-constants).

## 🚦 CHECK

What `CHECK <cond>` does when the condition is **false** depends on where it stands:

- **Inside a loop**, it ends the current loop pass; processing continues with the next pass.
- **Outside a loop**, it leaves the current processing block — a method, function module, subroutine or event block. Output parameters of a procedure are passed on as on a normal exit. The event block `LOAD-OF-PROGRAM` cannot be left with `CHECK`.

When the condition is true, `CHECK` does nothing.

> 📝 **Contextual snippet** — assumes the tables `items` and `messages`, and a method `process_item`.

```abap
" Current form: skip rows that already have an error
LOOP AT items INTO DATA(item).
  IF line_exists( messages[ item = item-posnr type = 'E' ] ).
    CONTINUE.
  ENDIF.

  process_item( item ).
ENDLOOP.
```

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. Existing code often writes the same loop with `CHECK`. Read it, but write the `IF … CONTINUE` form above — [Rule 3.17](../docs/ABAP-Development-Rules.md#317-use-check-only-as-an-input-check-at-the-start-of-a-method-prefer-if--return).

```abap
" Classic form: CHECK ends the loop pass when the condition is false
LOOP AT items INTO DATA(item).
  CHECK NOT line_exists( messages[ item = item-posnr type = 'E' ] ).

  process_item( item ).
ENDLOOP.
```

> ⚠️ **`CHECK` is not a general-purpose guard, and its polarity catches people out.** Because it exits when the condition is *false*, a statement such as `CHECK sy-subrc <> 0.` continues only on the **error** path and abandons the block on success — usually the exact opposite of the author's intent. Use `IF` when you want to branch. In new code, use `CHECK` at most as an input check at the start of a method, prefer `IF … RETURN` even there, and in loops use `IF` with `CONTINUE` ([Rule 3.17](../docs/ABAP-Development-Rules.md#317-use-check-only-as-an-input-check-at-the-start-of-a-method-prefer-if--return)).

## 🌿 IF / ELSE and the `COND` Operator

Classic `IF`/`ELSE` still has its place, but for **assigning a value** based on a condition, the functional `COND #( )` operator is more concise and avoids intermediate variables — [Rule 3.8](../docs/ABAP-Development-Rules.md#38-use-cond-or-switch-when-a-condition-only-selects-a-value):

> 📝 **Contextual snippet** — assumes the variables `warehouse` and `confirmation_number`, the constants `central_warehouse`, `relevant_indicator` and `severity_levels`, and a reference `defect` with the attribute `severity`.

```abap
DATA begin_date TYPE d VALUE '20200505'.
DATA end_date   TYPE d VALUE '20200515'.

" State the result type explicitly when the branches are literals
DATA(status) = COND char10( WHEN sy-datum < begin_date THEN 'EARLY'
                            WHEN sy-datum > end_date   THEN 'LATE'
                            ELSE                            'OK' ).

" '#' is fine when the type is clearly derivable from the operands
DATA(warehouse_indicator) = COND #( WHEN warehouse = central_warehouse
                                    THEN relevant_indicator
                                    ELSE space ).

" A Boolean from a condition needs no COND: use xsdbool (Rule 4.7)
DATA(is_in_range) = xsdbool( confirmation_number BETWEEN 50 AND 100 ).

DATA(message_type) = COND symsgty( WHEN defect->severity >= severity_levels-high   THEN 'E'
                                   WHEN defect->severity >= severity_levels-medium THEN 'W'
                                   ELSE                                                'I' ).
```

> ⚠️ **Know what `#` resolves to.** When the operand type cannot be derived from the position — as in an inline declaration — the ABAP documentation states that the type is taken from the operand after the **first `THEN`**. So `DATA(status) = COND #( ... THEN 'EARLY' ... ELSE 'OK' )` compiles, but `status` becomes `c LENGTH 5`, and a longer branch added later would be silently truncated. Write the type explicitly whenever the branches are literals.

## 🔁 SWITCH

`SWITCH` is the functional equivalent of `CASE`, useful for assigning a value based on a single variable's content:

```abap
DATA(status) = SWITCH char10( sy-msgty
                              WHEN 'S' THEN 'SUCCESS'
                              WHEN 'W' THEN 'WARNING'
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

- Use `COND`/`SWITCH` when the goal is to **compute a value** — they remove boilerplate `IF`/`ELSE` blocks that repeat the same assignment target — [Rule 3.8](../docs/ABAP-Development-Rules.md#38-use-cond-or-switch-when-a-condition-only-selects-a-value).
- Derive Booleans with `xsdbool( )`, not with `COND abap_bool( … THEN abap_true ELSE abap_false )` — [Rule 4.7](../docs/ABAP-Development-Rules.md#47-derive-a-boolean-from-a-condition-with-xsdbool).
- Use `CHECK` at most as an input check at the start of a method, and prefer `IF … RETURN` there; in loops use `IF … CONTINUE` — [Rule 3.17](../docs/ABAP-Development-Rules.md#317-use-check-only-as-an-input-check-at-the-start-of-a-method-prefer-if--return).
- Use `CASE`/`IF` when the goal is to **execute different logic**, not just assign a value.
- Always include an `ELSE`/`WHEN OTHERS` branch, especially in status mapping.
- **State the result type explicitly** (`COND char10( ... )`, `SWITCH string( ... )`) whenever the branches are literals — `#` will derive a type from the first `THEN`, and it may not be the one you want.

## ⚠️ Common Mistakes

- Using `COND`/`SWITCH` for complex multi-statement branches — they are expressions, not substitutes for full `IF` blocks.
- Relying on `#` and getting a narrower type than intended, so later branches are silently truncated.
- Forgetting that `COND` without an `ELSE` returns the type's **initial value** when nothing matches, hiding the "no match" case.
- Getting `CHECK`'s polarity backwards, so the block is abandoned on the success path.
- Using `CHECK` inside loops or anywhere other than the start of a method — use `IF ... CONTINUE` in loops and `IF ... RETURN` in methods ([Rule 3.17](../docs/ABAP-Development-Rules.md#317-use-check-only-as-an-input-check-at-the-start-of-a-method-prefer-if--return)).
- Comparing against literal codes such as order types in `CASE` or `COND` — use named constants.

## 🎤 Interview & Review Checkpoints

- Be ready to rewrite a nested `IF`/`ELSEIF` chain as a `COND` expression, and explain the trade-offs.
- Explain how `#` resolves for a constructor expression, and when you must give the type explicitly.
- Explain what happens when `CHECK` evaluates to false inside a `LOOP` vs. inside a method or event block.

## 🔗 Related Chapters

- [04-Operators](../04-Operators/README.md) — calculating the values that conditions test
- [06-Loops](../06-Loops/README.md) — `CONTINUE` and `EXIT` in loops
- [07-Internal-Tables](../07-Internal-Tables/README.md) — `COND` inside `VALUE`/`REDUCE` expressions
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — the lifecycle labels used in this chapter
