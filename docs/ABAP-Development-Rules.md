# ABAP Development Rules

> 📝 **Status:** adopted; 4 statements still to be verified, marked **[verify]**.

## 0 Purpose and Status

### 0.1 Treat this document as the team rule set for ABAP code

These rules build on SAP's [Clean ABAP style guide](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md) and turn it into numbered, citable team rules, so reviews argue about one shared text instead of personal taste.

Facts about the language — what a statement does, whether it is obsolete, what a release supports — come from the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm). When a rule and the documentation disagree on a fact, the documentation wins and the rule gets fixed.

### 0.2 Apply the rules to new and modified code in every ABAP-side guide

A shared rule set keeps code consistent when readers move between guides. The rules apply to:

- ABAPGuide
- GWGuide
- ABAP-Cookbook
- ABAP code in CDSGuide and CDS-Cookbook
- RAPGuide and HANAGuide, once they exist

Existing code is not rewritten just to comply. It is aligned when it is next changed, or in the planned pass for each guide.

> 📝 These rules govern *how* code is written. They do not widen a guide's scope. ABAPGuide still leaves out RAP, CDS, AMDP and ABAP Cloud beyond [Chapter 21](../21-Classic-vs-Modern-ABAP/README.md#-scope-boundary), even though some sections here mention those topics.

### 0.3 Record every deviation from Clean ABAP in section 14

An undocumented deviation looks like a mistake. A documented one is a decision a reviewer can find. Whenever a rule here contradicts Clean ABAP, section 14 names the rule and gives the reason.

### 0.4 Cite rules by number

Rule numbers stay stable, so a citation stays valid after the document grows.

- In reviews, CLAUDE.md files and commit bodies, write `ABAP Development Rules 3.12` or short `Rule 3.12`.
- In Markdown, link to the heading anchor, for example `docs/ABAP-Development-Rules.md#312-check-existence-with-line_exists`.
- A rule that is withdrawn keeps its number and is marked *Withdrawn*. Its number is never reused.

### 0.5 Read rule examples as contextual snippets

Rule examples are kept to the minimum that shows the point.

> 📝 **Contextual snippet** — unless a rule says otherwise, every example assumes the declarations it refers to (`orders`, `order`, `items` and so on) exist with suitable types. It also assumes Standard ABAP as the target (see [1.4](#14-state-the-target-language-version-when-it-matters)).

---

## 1 Language Version

> **Lifecycle:** `ABAP CLOUD / MODERN CONTEXT`. ABAP language versions decide which statements and which APIs a development object may use. For the on-premise vs cloud split, see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-what-changes-under-abap-cloud).

### 1.1 Know the language version of every object you change

The ABAP language version is a property of every ABAP program, and of other repository objects that carry it. It decides which language elements and which repository objects the code may use. The syntax check enforces it, so the same source can be valid in one object and rejected in another.

The ABAP Keyword Documentation lists three current versions:

- **Standard ABAP:** the unrestricted language for classic ABAP.
- **ABAP for Cloud Development:** the restricted version for ABAP Cloud. It allows only a small set of language elements and restricted access to repository objects, applies the strictest ABAP SQL check mode and enforces client isolation.
- **ABAP for Key Users:** a restricted version for key-user enhancements. It is outside the scope of these rules.

### 1.2 When targeting ABAP for Cloud Development, use only released APIs

That language version only accepts SAP objects that are released for cloud development. Code that uses unreleased objects does not compile there, and on premise it gives up the stability contract that a release brings.

An object usable in a restricted language version is released with a release contract, in general the C1 contract. Its release state is either *Released* or *Deprecated*. Check that state before you design around an object. A deprecated object names its successor where one exists. For an object that is not released, look for the documented successor.

> 📝 **Target:** ABAP for Cloud Development.

```abap
" ✅ released CDS view as the data source
SELECT product, producttype
  FROM i_product
  WHERE product IN @product_range
  INTO TABLE @DATA(products).

" ❌ direct read of a standard table, which is not to be released
SELECT matnr, mtart
  FROM mara
  WHERE matnr IN @product_range
  INTO TABLE @DATA(products).
```

In SAP's list of released objects, `I_PRODUCT` is released, and `MARA` is classified as not to be released, with `I_PRODUCT` among its successors. `I_Product` has the fields `Product` and `ProductType` used above.

### 1.3 In Standard ABAP, prefer a released API over an unreleased one when both exist

A released API has a stability contract and keeps a later move to ABAP for Cloud Development open. An unreleased one can change in any upgrade.

This is a team rule, not a Clean ABAP statement. Where no released API exists, Standard ABAP may use the classic one. [Chapter 21](../21-Classic-vs-Modern-ABAP/README.md) explains why that is normal on premise.

### 1.4 State the target language version when it matters

A reader needs to know whether an example compiles in a cloud object before copying it.

- Put `> 📝 **Target:** ABAP for Cloud Development.` or `> 📝 **Target:** Standard ABAP.` directly above any example whose validity depends on the language version.
- An example without a target line is Standard ABAP.
- Examples that are valid in both versions need no target line.

### 1.5 Never call code cloud-ready unless it was checked

"Cloud-ready" is a factual claim. Make it only after the object compiled under ABAP for Cloud Development, or after ATC with the released check variant `ABAP_CLOUD_READINESS` passed, and say which of the two you did.

---

## 2 Naming

### 2.1 Use descriptive snake_case names without type or scope prefixes

The name should tell the reader what a thing means. The type is already visible to the compiler and the IDE, and prefixes go stale when a variable's scope or type changes.

Clean ABAP recommends avoiding encodings such as Hungarian notation and prefixes, using descriptive names, and using snake_case.

```abap
" ✅
DATA open_orders TYPE zsm_tt_order.
METHODS cancel_order IMPORTING order_id TYPE zsm_e_order_id.

" ❌
DATA gt_orders TYPE zsm_tt_order.
METHODS cancel IMPORTING iv_id TYPE zsm_e_order_id.
```

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. Prefixes such as `lv_`, `lt_` and `iv_` are everywhere in existing code, so readers must still be able to read them. They are not used in new code. See [20-Best-Practices](../20-Best-Practices/README.md).

### 2.2 Use plural nouns for tables, nouns for classes and verbs for methods

The grammar of a name signals its role, so a call reads like a sentence: `validator->check( orders )`.

Clean ABAP recommends nouns for classes and verbs for methods, and plural names. Boolean variables and methods read as questions, for example `is_blocked` or `has_open_items`.

```abap
" ✅
DATA(blocked_customers) = customer_repository->read_blocked( ).
IF order_validator->is_valid( order ) = abap_true.

" ❌
DATA(customer_tab) = customer_handler->blocked( ).
IF order_validation->validity( order ) = abap_true.
```

### 2.3 Avoid abbreviations and noise words; abbreviate the same way everywhere when length forces it

Abbreviations and filler words such as `data`, `info` and `object` make names longer without making them clearer.

ABAP's name-length limits sometimes force abbreviations. Clean ABAP recommends avoiding them, and using the same abbreviation everywhere when they are unavoidable.

```abap
" ✅
DATA(delivery_date) = order-requested_delivery_date.

" ❌
DATA(dlv_dt_info) = order-requested_delivery_date.
```

### 2.4 Keep names that are fixed by a signature you do not own

Renaming is impossible, or it breaks the contract, when the name comes from somebody else's interface. Examples:

- SEGW-generated methods and types
- BAPI and function module parameters
- inherited methods
- interface methods

Only the names you introduce yourself follow 2.1.

```abap
" ✅ the redefinition keeps the generated names; local names follow 2.1
METHOD orderset_get_entityset.
  DATA(open_orders) = order_repository->read_open( ).
  et_entityset = CORRESPONDING #( open_orders ).
ENDMETHOD.
```

### 2.5 In legacy code, keep naming consistent within a development object

A class, function group or program that mixes two naming styles is harder to read than one that sticks to either.

- New development objects follow 2.1 in full.
- A change inside an existing development object that uses prefixes throughout keeps that object's style. This includes new methods added to it.
- When the object is refactored as a whole, rename all of it to 2.1 at once.

In its section on refactoring legacy code, Clean ABAP advises against mixing styles within the same development object. It also notes that in legacy projects its prefix rule may be better left aside.

This exception is for projects that adopt these rules. The guides' own examples do not use it: they are migrated to 2.1 in full in each guide's planned pass.

### 2.6 Name development objects by the object naming table

A fixed infix per object type tells the reader what kind of object a name refers to, even outside the IDE.

`zsm` is the placeholder namespace used in the guides. Real projects substitute their own.

| Object type | Pattern | Example |
|---|---|---|
| Class | `zcl_zsm_` | `zcl_zsm_order_validator` |
| Interface | `zif_zsm_` | `zif_zsm_order_repository` |
| Exception class | `zcx_zsm_` | `zcx_zsm_order_not_found` |
| Message class | `zsm_msg` | `zsm_msg` |
| Function module | `zsm_fm_` | `zsm_fm_read_orders` |
| Database table | `zsm_t_` | `zsm_t_order` |
| Structure | `zsm_s_` | `zsm_s_order` |
| Table type | `zsm_tt_` | `zsm_tt_order` |
| Data element | `zsm_e_` | `zsm_e_order_id` |
| CDS view | `ZSM_I_` | `ZSM_I_Order` |
| CDS projection view | `ZSM_C_` | `ZSM_C_Order` |
| CDS table function | `ZSM_F_` | `ZSM_F_OrderAging` |
| Report | `zsm_r_` | `zsm_r_order_overview` |
| Lock object | `EZSM_` | `EZSM_ORDER` |
| Local class | `lcl_` | `lcl_main` |
| Local interface | `lif_` | `lif_order_source` |
| Local test class | `ltc_` | `ltc_release` |
| Local test helper | `lth_` | `lth_order_builder` |

> 📝 Lock object names must start with `E`, so the lock object row puts `E` in front of the namespace instead of using a lower-case infix.

> 📝 Local types live inside one program, so they carry a short type prefix without the namespace. These prefixes are common SAP practice, and Clean ABAP itself names local test classes `ltc_` and test helpers `lth_`. Section 14 records this as a deviation.

Guides that still use other prefixes are aligned in their planned pass.

---

## 3 Modern Syntax

> **Lifecycle:** `CURRENT / RECOMMENDED`. Expression syntax from the 7.40 generation onward is the default for new on-premise code. Individual additions arrived at different times. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

> ⚠️ **VERSION-DEPENDENT: constructor expressions and their additions.** Not every expression or addition below exists in every release. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) for your target before relying on one.

### 3.1 Declare variables inline at first use

An inline declaration puts the type where the value comes from and keeps the variable's scope visibly small. Clean ABAP recommends inline declarations over up-front declarations.

```abap
" ✅
SELECT order_id, status
  FROM zsm_t_order
  WHERE customer_id = @customer_id
  INTO TABLE @DATA(orders).

" ❌
DATA lt_orders TYPE STANDARD TABLE OF zsm_t_order.
SELECT * FROM zsm_t_order INTO TABLE lt_orders WHERE customer_id = customer_id.
```

### 3.2 Give an inline declaration an explicit type when the initial value would infer the wrong one

The type of an inline variable comes from the right-hand side. A text literal produces a `c` field exactly as long as the literal, which silently truncates longer values assigned later.

```abap
" ✅
DATA(message_text) = `Order released`.
DATA(total) = CONV zsm_e_amount( 0 ).

" ❌ message_text becomes c LENGTH 14; total becomes type i
DATA(message_text) = 'Order released'.
DATA(total) = 0.
```

### 3.3 Declare values that are never reassigned with FINAL

`FINAL( )` documents that a value does not change, and the compiler enforces it.

> ⚠️ **VERSION-DEPENDENT: `FINAL` inline declarations.** Available only in newer releases. Where it is missing, use `DATA( )`. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm).

```abap
" ✅
FINAL(today) = cl_abap_context_info=>get_system_date( ).
```

### 3.4 Build structures and tables with VALUE

A single `VALUE` expression shows the whole content at once and needs no helper work area.

```abap
" ✅
DATA(items) = VALUE zsm_tt_item( ( item_no = 10 quantity = 2 )
                                 ( item_no = 20 quantity = 5 ) ).

" ❌
DATA item  TYPE zsm_s_item.
DATA items TYPE zsm_tt_item.
item-item_no  = 10.
item-quantity = 2.
APPEND item TO items.
item-item_no  = 20.
item-quantity = 5.
APPEND item TO items.
```

Use `BASE` to add lines to a table that already has content. Without it, `VALUE` builds a new table and the old lines are lost.

### 3.5 Map structures and tables with CORRESPONDING; add BASE when target values must survive

`CORRESPONDING` states the mapping in one expression. Without `BASE`, it starts from an initial target, so fields that the source does not fill are cleared. `MOVE-CORRESPONDING` behaves differently: it leaves unmatched target fields unchanged.

```abap
" ✅ target already holds values that must be kept
target = CORRESPONDING #( BASE ( target ) source MAPPING customer_id = kunnr ).

" ❌ in that situation: every target field not in source is reset
target = CORRESPONDING #( source MAPPING customer_id = kunnr ).
```

### 3.6 Create objects with NEW

`NEW` creates and assigns in one expression and works inline. Clean ABAP recommends `NEW` over `CREATE OBJECT`.

```abap
" ✅
DATA(validator) = NEW zcl_zsm_order_validator( order ).

" ❌
DATA validator TYPE REF TO zcl_zsm_order_validator.
CREATE OBJECT validator EXPORTING order = order.
```

### 3.7 Convert types inline with CONV; use EXACT when data must not be lost

`CONV` removes helper variables that exist only to change a type. `EXACT` raises an exception instead of silently rounding or truncating. Examples are `cx_sy_conversion_rounding` for a calculation that would round, and a subclass of `cx_sy_conversion_error` for an invalid value.

```abap
" ✅
DATA(page_count) = pager->count_pages( CONV i( total_lines ) ).

" ❌
DATA lv_lines TYPE i.
lv_lines = total_lines.
DATA(page_count) = pager->count_pages( lv_lines ).
```

### 3.8 Use COND or SWITCH when a condition only selects a value

The expression makes clear that every branch produces a value for the same target. Keep `IF` and `CASE` for branches that do work.

- `COND` handles arbitrary conditions.
- `SWITCH` compares one operand for equality.

This is a team rule. Clean ABAP does not prescribe it in a rule of its own.

```abap
" ✅
DATA(fee) = COND zsm_e_amount( WHEN order-express = abap_true THEN express_fee
                               ELSE standard_fee ).

" ❌
DATA fee TYPE zsm_e_amount.
IF order-express = abap_true.
  fee = express_fee.
ELSE.
  fee = standard_fee.
ENDIF.
```

### 3.9 Use REDUCE to aggregate into one result; switch to LOOP when the logic grows

`REDUCE` states the start value, the iteration and the step together. Once the step needs several statements or side effects, a `LOOP` is easier to read and to debug. This is a team rule.

```abap
" ✅
DATA(total) = REDUCE zsm_e_amount( INIT sum = CONV zsm_e_amount( 0 )
                                   FOR item IN items
                                   NEXT sum = sum + item-amount ).
```

### 3.10 Use FILTER only with a suitable table key; otherwise use VALUE with FOR … WHERE

`FILTER` is efficient because it works through a table key, and it only compiles when a suitable key exists. The requirement is described in [07-Internal-Tables](../07-Internal-Tables/README.md#filter--building-a-subset-of-a-table). Without such a key, `VALUE … FOR … WHERE` does the same job.

In the basic form, `FILTER` uses the primary key when `USING KEY` is omitted. A table whose primary key is neither sorted nor hashed must therefore name a secondary key. The `WHERE` condition depends on the key:

- **Hashed key:** each key component is compared with `=`.
- **Sorted key:** an initial part of the key is covered, and any comparison operator is allowed.

```abap
" ✅ orders has a sorted secondary key by_status on status
DATA(open_orders) = FILTER #( orders USING KEY by_status WHERE status = status_open ).

" ✅ no suitable key
DATA(open_orders) = VALUE zsm_tt_order( FOR order IN orders
                                        WHERE ( status = status_open )
                                        ( order ) ).
```

### 3.11 Assemble text with string templates

A template shows the final text in reading order, and formatting options replace conversion code. Clean ABAP recommends `|` for assembling text and backticks for string literals.

```abap
" ✅
DATA(log_text) = |Order { order_id ALPHA = OUT } released by { user_name }|.

" ❌
CONCATENATE 'Order' order_id 'released by' user_name INTO log_text SEPARATED BY space.
```

> 💡 Text a user reads in their logon language belongs in a message class or text symbols, not in a template literal. See [4.2](#42-keep-user-facing-text-out-of-literals).

### 3.12 Check existence with line_exists

`line_exists` states the intent directly and needs no `sy-subrc`. Clean ABAP recommends `line_exists` over `READ TABLE` and `LOOP AT` for this purpose.

```abap
" ✅
IF line_exists( orders[ order_id = order_id ] ).
  ...
ENDIF.

" ❌
READ TABLE orders TRANSPORTING NO FIELDS WITH KEY order_id = order_id.
IF sy-subrc = 0.
  ...
ENDIF.
```

### 3.13 Read with a table expression only when a miss is handled

If no line matches, a table expression raises `cx_sy_itab_line_not_found`. When nothing catches it, missing data becomes a short dump. You have three ways to handle a miss:

- add `OPTIONAL`, which gives an initial result;
- add `DEFAULT`, which gives a fallback value;
- catch the exception where a miss is an error.

```abap
" ✅ a missing customer is allowed
DATA(customer) = VALUE #( customers[ customer_id = order-customer_id ] OPTIONAL ).

" ✅ fall back to a known value
DATA(setting) = VALUE #( plant_settings[ plant = plant ] DEFAULT default_setting ).

" ❌ a missing customer dumps
DATA(customer) = customers[ customer_id = order-customer_id ].
```

> 📝 `ASSIGN itab[ … ] TO <line>` does not raise the exception. It sets `sy-subrc` instead, so check `sy-subrc` after it.

### 3.14 Read a line once, not once per component

Each table expression is a separate table read. Repeating one costs time and hides the fact that the same line is meant. Clean ABAP recommends avoiding unnecessary table reads.

```abap
" ✅
DATA(customer) = VALUE #( customers[ customer_id = customer_id ] OPTIONAL ).
DATA(address_line) = |{ customer-name }, { customer-city }|.

" ❌
DATA(address_line) = |{ customers[ customer_id = customer_id ]-name }, | &&
                     |{ customers[ customer_id = customer_id ]-city }|.
```

### 3.15 Call methods functionally

A functional call can be used inside expressions and reads like a function. Clean ABAP recommends functional calls over `CALL METHOD`. Where possible, it also recommends dropping `RECEIVING`, dropping the `EXPORTING` keyword, and dropping the parameter name in single-parameter calls.

```abap
" ✅
DATA(is_valid) = validator->is_valid( order ).

" ❌
CALL METHOD validator->is_valid
  EXPORTING
    order  = order
  RECEIVING
    result = is_valid.
```

### 3.16 Do not write statements the ABAP Keyword Documentation classifies as obsolete

Obsolete statements remain only for compatibility. They have better replacements, and many of them are not available in restricted language versions. Clean ABAP also recommends avoiding obsolete language elements.

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE`. The constructs below may appear in examples only with this label and paired with the replacement. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference).

| Obsolete construct (typical examples) | Write instead |
|---|---|
| `MOVE a TO b` | `b = a` |
| `REFRESH itab` | `CLEAR itab` |
| Tables with header lines (`WITH HEADER LINE`, `OCCURS`) | A table type plus a separate work area or field symbol |
| Subroutines (`FORM` / `PERFORM`) | Methods |
| Host variables in ABAP SQL without the `@` escape | `@variable` with the strict syntax |

> 📝 The length in parentheses (`DATA text(10) TYPE c`) is **not** classified as obsolete. The ABAP Keyword Documentation recommends `LENGTH` for legibility, so write `DATA text TYPE c LENGTH 10`. Only length specifications for the fixed-length types `d`, `f`, `i` and `t` are listed as obsolete.

This table lists typical cases only. For the full list, see the obsolete language elements section of the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm), and do not label a construct obsolete unless the documentation does.

### 3.17 Use CHECK only as an input check at the start of a method; prefer IF … RETURN

`CHECK` behaves differently depending on where it stands. Inside a loop, it ends only the current loop pass. Outside a loop, it leaves the whole processing block. A reader has to know which case applies, and the keyword does not say what happens when the condition is false.

Clean ABAP records that there is no consensus on `CHECK` versus `RETURN` at the start of a method, and finds the long form easier to understand. It also advises against `CHECK` anywhere other than the initialization section of a method. In loops, it recommends `IF` with `CONTINUE`, because `CONTINUE` can only mean the loop.

> 📝 The ABAP Programming Guidelines allow `CHECK` at the start of a procedure. The keyword documentation for `CHECK` in loops recommends using `CHECK` inside loops only. Clean ABAP notes that its loop rule contradicts this. This is a style choice, not a fact about the language, so this rule follows Clean ABAP.

Before returning early, consider whether returning nothing is the right result. Clean ABAP points out that a method should usually fill its result or raise an exception (6.1).

```abap
" ✅
METHOD read_open_orders.
  IF customer_ids IS INITIAL.
    RETURN.
  ENDIF.
  ...
ENDMETHOD.

LOOP AT orders INTO DATA(order).
  IF order-status <> status_open.
    CONTINUE.
  ENDIF.
  ...
ENDLOOP.

" ❌ ends only the current loop pass; readers expect it to leave the method
LOOP AT orders INTO DATA(order).
  CHECK order-status = status_open.
  ...
ENDLOOP.
```

### 3.18 Check references with IS BOUND and field symbols with IS ASSIGNED where they can be empty

Access through an empty reference or field symbol ends the program. The ABAP Keyword Documentation describes these cases:

- Dereferencing a data reference that contains the null reference raises the uncatchable exception `DATREF_NOT_ASSIGNED`.
- Accessing an attribute through an object reference that contains the null reference raises the uncatchable exception `OBJECTS_OBJREF_NOT_ASSIGNED`.
- Calling an instance method through such a reference raises the catchable exception `CX_SY_REF_IS_INITIAL`.
- A field symbol must have a memory area assigned before it is used as an operand; otherwise an exception is raised.

`IS BOUND` is true only if a reference can be dereferenced or points to an object. It therefore also detects a data reference to a table line that has since been deleted. `IS ASSIGNED` is true if a memory area is assigned to the field symbol. After `ASSIGN`, check `sy-subrc` instead (see the note in 3.13).

Check only where the reference or field symbol can actually be empty, for example a lazily created object or a reference passed in as optional. A dependency stored by the constructor (5.4, 5.12) needs no check at every use. This is a team rule.

```abap
" ✅ the cache is created on first use
IF order_cache IS NOT BOUND.
  order_cache = NEW zcl_zsm_order_cache( ).
ENDIF.

IF order_ref IS BOUND.
  DATA(order) = order_ref->*.
ENDIF.

" ❌ if order_ref is initial, the dereference raises an uncatchable exception
DATA(order) = order_ref->*.
```

### 3.19 Do not write macros; use methods or expressions

A macro has no context of its own and cannot be executed step by step in the ABAP Debugger. Errors in larger macros are therefore very hard to analyze.

The ABAP Programming Guidelines allow macros only in exceptional cases, and recommend methods or expressions instead. Many typical macros only fill internal tables, and a `VALUE` expression (3.4) replaces them. The guidelines also say that no new macros should be defined in type pools or in the table `TRMAC`. Macros are not classified as obsolete.

This rule is stricter than the guidelines: new code contains no macros. Existing macros are replaced when the code around them is changed (0.2). Clean ABAP has no section on macros. This is a team rule.

```abap
" ✅
DATA(items) = VALUE zsm_tt_item( ( item_no = 10 quantity = 2 )
                                 ( item_no = 20 quantity = 5 ) ).

" ❌
DEFINE add_item.
  APPEND VALUE #( item_no = &1 quantity = &2 ) TO items.
END-OF-DEFINITION.
add_item 10 2.
add_item 20 5.
```

---

## 4 Constants, Enumerations and Booleans

### 4.1 Replace magic literals with named constants

A named constant tells the reader what a value means, and it changes in one place. Clean ABAP recommends constants instead of magic numbers, and descriptive names for constants as well.

Literals whose meaning is obvious from the code may stay, for example `0`, `1`, an empty string or test data.

```abap
" ✅
IF order-fee_type = zcl_zsm_order_fees=>fee_type-express.

" ❌
IF order-fee_type = 'EXP'.
```

### 4.2 Keep user-facing text out of literals

A literal is not translated. Text that a user reads belongs in a message class (`zsm_msg`) or in text symbols, so it follows the logon language.

```abap
" ✅
MESSAGE e001(zsm_msg) WITH order_id.

" ❌
MESSAGE |Order { order_id } not found| TYPE 'E'.
```

### 4.3 Declare constants in the class or interface that owns the concept, grouped by topic

Constants placed next to the logic that uses them are found where they are needed. A structured constant groups related values under one name.

Avoid two patterns:

- a global "all constants" include;
- an interface that holds only constants and is implemented just to reach them without qualification.

Clean ABAP puts native `ENUM` types first (see 4.4). For enumeration patterns written by hand, its enumerations sub-page prefers classes to interfaces. If neither is used, it recommends at least grouping the constants, as in the example below.

```abap
" ✅
CLASS zcl_zsm_order_fees DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF fee_type,
        express  TYPE zsm_e_fee_type VALUE 'EXP',
        standard TYPE zsm_e_fee_type VALUE 'STD',
      END OF fee_type.
ENDCLASS.

" ❌
CONSTANTS gc_exp TYPE c LENGTH 3 VALUE 'EXP'.  " in a shared include
```

### 4.4 Use enumeration types for a closed set of values

The compiler then accepts only the declared values, and invalid states cannot be assigned. Clean ABAP recommends `ENUM` over constants interfaces.

> ⚠️ **VERSION-DEPENDENT: enumeration types (`BEGIN OF ENUM`).** Not available in older releases. Where they are missing, use grouped constants as in 4.3. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm).

```abap
" ✅
TYPES:
  BEGIN OF ENUM order_status,
    created,
    released,
    completed,
  END OF ENUM order_status.

DATA status TYPE order_status.
status = released.

" ❌
DATA status TYPE c LENGTH 1.
status = 'R'.
```

### 4.5 Give an enumeration a base type and explicit values only when the value is stored or exchanged

Without a base type, the internal values are an implementation detail. A database field or an interface needs stable values, and a base type with explicit `VALUE` additions provides them.

The ABAP Keyword Documentation sets these rules:

- The base type is a flat elementary type of at most 16 bytes. Without `BASE TYPE`, it is `i`.
- `VALUE` is given for all values or for none, and exactly one value is `VALUE IS INITIAL`.
- `CONV base_type( … )` returns the stored value, and `CONV enum_type( … )` converts a valid stored value back.

```abap
" ✅
TYPES:
  BEGIN OF ENUM order_status BASE TYPE zsm_e_status_code,
    undefined VALUE IS INITIAL,
    created   VALUE 'C',
    released  VALUE 'R',
  END OF ENUM order_status.

order_row-status_code = CONV zsm_e_status_code( status ).
```

### 4.6 Type Booleans as abap_bool and compare with abap_true and abap_false

`abap_bool` with `abap_true` and `abap_false` is the shared Boolean convention in ABAP. Comparing against these constants says "this is a Boolean". Comparing with `'X'`, `space` or `IS INITIAL` hides that.

Clean ABAP recommends `abap_bool` for Booleans and `abap_true` / `abap_false` for comparisons.

For database fields and other Dictionary types, use the released data element `abap_boolean`. The data elements `boole_d` and `xfeld` are deprecated in the released-API list, with `abap_boolean` named as their successor.

```abap
" ✅
DATA is_blocked TYPE abap_bool.
IF is_blocked = abap_true.
  ...
ENDIF.

" ❌
DATA lv_blocked TYPE c LENGTH 1.
IF lv_blocked = 'X'.
  ...
ENDIF.
IF lv_blocked IS NOT INITIAL.
  ...
ENDIF.
```

### 4.7 Derive a Boolean from a condition with xsdbool

`xsdbool` turns a logical expression into `abap_true` or `abap_false` in one line. Clean ABAP recommends `xsdbool` for setting Boolean variables.

Do not use `boolc` for this. It returns a `string`, which compares unreliably with `abap_false`.

```abap
" ✅
DATA(is_overdue) = xsdbool( invoice-due_date < today AND invoice-paid = abap_false ).

" ❌
IF invoice-due_date < today AND invoice-paid = abap_false.
  is_overdue = abap_true.
ELSE.
  is_overdue = abap_false.
ENDIF.
```

### 4.8 Do not model more than two states with Booleans

Two flags allow four combinations, some of which are invalid, and adding a third state means adding another flag. Clean ABAP advises using Booleans with care. An enumeration (4.4) states the real set of values.

```abap
" ✅
DATA status TYPE order_status.

" ❌ is_released = abap_false and is_completed = abap_true is possible
DATA is_released  TYPE abap_bool.
DATA is_completed TYPE abap_bool.
```

---

## 5 Classes and Methods

> **Lifecycle:** `CURRENT / RECOMMENDED`. ABAP Objects is the default for new code. Function modules and reports are still needed as entry points. See [10-Objects](../10-Objects/README.md) and [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

### 5.1 Write new logic in classes; wrap function modules and BAPIs

Classes give you encapsulation, interfaces and test seams that function groups cannot offer. A wrapper keeps the procedural call protocol in one place instead of in every caller.

Clean ABAP recommends object orientation over procedural programming. Where a procedural object is unavoidable, it recommends that the object do little more than call a class. Unavoidable cases include:

- an RFC-enabled function module
- an update function module
- the report behind a transaction

```abap
" ✅ callers use one typed method; the BAPI protocol stays inside the wrapper
DATA(order_id) = sales_order_api->create( order ).

" ❌ every caller repeats the BAPI call and its RETURN handling
CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
  EXPORTING
    order_header_in = header
  IMPORTING
    salesdocument   = order_id
  TABLES
    return          = messages
    order_items_in  = items.
```

### 5.2 Make classes FINAL unless they are designed for inheritance

A class that is open for subclassing makes a promise about its protected members and its behaviour, and that promise has to be kept. `FINAL` states that no such promise exists. Clean ABAP recommends `FINAL` for classes not designed for inheritance.

Test doubles then come from interfaces (5.4), not from subclasses.

```abap
" ✅
CLASS zcl_zsm_order_validator DEFINITION PUBLIC FINAL CREATE PUBLIC.

" ❌ open for inheritance by accident
CLASS zcl_zsm_order_validator DEFINITION PUBLIC CREATE PUBLIC.
```

### 5.3 Prefer instance methods to static methods

A static method cannot be replaced by a test double and cannot be reached through an interface. Its callers are therefore welded to the implementation.

Clean ABAP recommends objects over static classes and instance methods over static ones. It accepts plain, stateless type utilities as the exception. Static factory methods that return an instance are also fine.

```abap
" ✅
DATA(fee) = fee_calculator->calculate( order ).

" ❌
DATA(fee) = zcl_zsm_fee_calculator=>calculate( order ).
```

### 5.4 Depend on interfaces and receive dependencies through the constructor

When a class receives its collaborators as interface references, tests can hand in doubles and production can swap implementations without changing the class.

Clean ABAP recommends that public instance methods belong to an interface. In its testing section, it recommends passing dependencies to the constructor rather than through setters.

```abap
" ✅
CLASS zcl_zsm_order_service DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_zsm_order_service.
    METHODS constructor
      IMPORTING repository TYPE REF TO zif_zsm_order_repository.
  PRIVATE SECTION.
    DATA repository TYPE REF TO zif_zsm_order_repository.
ENDCLASS.

" ❌ the dependency is created inside and cannot be replaced
METHOD zif_zsm_order_service~release.
  DATA(repository) = NEW zcl_zsm_order_db_repository( ).
  ...
ENDMETHOD.
```

### 5.5 Prefer composition to inheritance

Small objects combined through references can be understood, reused and changed one at a time. An inheritance hierarchy ties all its levels together. Clean ABAP recommends composition over inheritance.

```abap
" ✅ the service uses a notifier
DATA notifier TYPE REF TO zif_zsm_notifier.

" ❌ the service inherits from a notifier only to reuse its methods
CLASS zcl_zsm_order_service DEFINITION PUBLIC INHERITING FROM zcl_zsm_notifier.
```

### 5.6 Keep the public section minimal

Every public member is part of the class's contract and is hard to remove later.

Clean ABAP recommends making members `PRIVATE` by default, using `PROTECTED` only when it is needed, and using `READ-ONLY` sparingly. Expose behaviour through methods (ideally through an interface, 5.4), not through attributes.

```abap
" ✅
PUBLIC SECTION.
  INTERFACES zif_zsm_order_service.
PRIVATE SECTION.
  DATA repository TYPE REF TO zif_zsm_order_repository.

" ❌
PUBLIC SECTION.
  DATA repository TYPE REF TO zif_zsm_order_repository.
  DATA last_error TYPE string.
```

### 5.7 Write small methods that do one thing at one level of abstraction

A method that reads like a list of named steps can be understood without opening each step.

Clean ABAP recommends methods that:

- do one thing;
- descend only one level of abstraction;
- stay small.

```abap
" ✅
METHOD zif_zsm_order_service~release.
  DATA(order) = repository->read( order_id ).
  validator->check_releasable( order ).
  repository->set_status( order_id = order_id
                          status   = released ).
  notifier->order_released( order ).
ENDMETHOD.
```

The ❌ version of this method would contain the `SELECT`, the validation rules, the `UPDATE` and the mail text in one body. It is left out because of its length.

### 5.8 Keep IMPORTING parameters few

Each additional parameter multiplies the combinations a caller has to understand and a test has to cover. Clean ABAP recommends few `IMPORTING` parameters, ideally fewer than three.

When the method needs more data, group parameters that belong together into a structure. Split the method instead of adding `OPTIONAL` parameters.

```abap
" ✅
METHODS create
  IMPORTING order         TYPE zsm_s_order
  RETURNING VALUE(result) TYPE zsm_e_order_id.

" ❌
METHODS create
  IMPORTING customer_id   TYPE zsm_e_customer_id
            order_type    TYPE zsm_e_order_type
            sales_org     TYPE zsm_e_sales_org
            delivery_date TYPE zsm_e_delivery_date
            priority      TYPE zsm_e_priority OPTIONAL
  RETURNING VALUE(result) TYPE zsm_e_order_id.
```

### 5.9 Return one value with RETURNING instead of EXPORTING

A `RETURNING` parameter allows functional calls (3.15) and makes it clear that the method produces one result.

Clean ABAP recommends:

- `RETURNING` over `EXPORTING`;
- naming the returning parameter `result`;
- not combining `RETURNING`, `EXPORTING` and `CHANGING` in one signature.

It also notes that returning large tables is usually acceptable.

```abap
" ✅
METHODS read_open
  RETURNING VALUE(result) TYPE zsm_tt_order.

" ❌
METHODS read_open
  EXPORTING orders TYPE zsm_tt_order.
```

### 5.10 Avoid CHANGING parameters

A `CHANGING` parameter hides the fact that the caller's data is modified, and it cannot be used in expressions. Clean ABAP recommends using `CHANGING` sparingly and only where it fits.

The case where it fits is adjusting a value in place that the caller already holds. Everything else returns a new value.

```abap
" ✅
DATA(priced_items) = pricing->price( items ).

" ❌
pricing->price( CHANGING items = items ).
```

### 5.11 Split a method instead of adding a Boolean input parameter that switches its behaviour

A flag that selects between two behaviours means the method does two things, and every call site needs a comment to explain the `abap_true`. Clean ABAP recommends splitting the method instead.

```abap
" ✅
printer->print( document ).
printer->preview( document ).

" ❌
printer->output( document = document
                 preview  = abap_true ).
```

### 5.12 Limit constructors to setup

A constructor runs on every instantiation and cannot be skipped or replaced in a test. It should only store dependencies and check its input.

Reading data, posting documents or calling remote systems belong in methods that the caller invokes on purpose. This is a team rule; Clean ABAP has no rule of its own for it.

```abap
" ✅
METHOD constructor.
  me->repository = repository.
ENDMETHOD.

" ❌
METHOD constructor.
  me->repository = repository.
  orders = repository->read_open( ).
  send_reminders( orders ).
ENDMETHOD.
```

---

## 6 Error Handling

> **Lifecycle:** `CURRENT / RECOMMENDED`. Class-based exceptions are the current mechanism. For the statements themselves, see [18-Debugging](../18-Debugging/README.md#-exception-handling).

### 6.1 Use class-based exceptions in new code

A class-based exception carries:

- a type that the caller can catch selectively;
- a translatable text;
- typed attributes;
- a cause chain.

A return code carries none of these. Clean ABAP recommends class-based exceptions and exceptions over return codes.

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. Classic exceptions (`EXCEPTIONS` in a function module interface, evaluated through `sy-subrc`) appear at every call of an existing function module. Handle them as in 6.9.

The ABAP Keyword Documentation says non-class-based exceptions should no longer be defined in new developments. Its programming guidelines call them obsolete on the raising side. Do not define new ones, except in RFC-enabled function modules: remote calls support only classic exception handling.

```abap
" ✅
METHODS read
  IMPORTING order_id      TYPE zsm_e_order_id
  RETURNING VALUE(result) TYPE zsm_s_order
  RAISING   zcx_zsm_order_not_found.

" ❌
METHODS read
  IMPORTING order_id    TYPE zsm_e_order_id
  EXPORTING order       TYPE zsm_s_order
            return_code TYPE sysubrc.
```

### 6.2 Build your own exception hierarchy below zcx_zsm_

Own superclasses let a caller catch "anything from this component" in one clause. Subclasses let it tell specific situations apart.

Clean ABAP recommends own superclasses, and subclasses for situations that callers need to distinguish. Each category you use (6.3) needs its own abstract root, because a class can inherit from only one of the three categories. Naming one root per category is a team rule.

```abap
" ✅
CLASS zcx_zsm_static_error DEFINITION PUBLIC ABSTRACT
  INHERITING FROM cx_static_check CREATE PUBLIC.

CLASS zcx_zsm_order_not_found DEFINITION PUBLIC FINAL
  INHERITING FROM zcx_zsm_static_error CREATE PUBLIC.

" ❌ every exception inherits directly from a framework class
CLASS zcx_zsm_order_not_found DEFINITION PUBLIC
  INHERITING FROM cx_static_check CREATE PUBLIC.
```

### 6.3 Choose the exception category by what the caller can do

The category decides whether the compiler forces callers to deal with the exception. Choosing it is a design decision, not a default.

| Category | Use it when | Clean ABAP |
|---|---|---|
| `CX_STATIC_CHECK` | The caller can reasonably handle the error, for example invalid input or a missing record that has a fallback. | Recommended for manageable exceptions |
| `CX_NO_CHECK` | Nobody can reasonably recover, for example a missing must-have configuration or a dependency that cannot be resolved. | Recommended for usually unrecoverable situations |
| `CX_DYNAMIC_CHECK` | Rarely. Only when the caller fully controls whether the error can occur, and the reason is written in the class's ABAP Doc. | Described as rarely needed |

A `CX_STATIC_CHECK` exception must be declared in `RAISING`, and callers must catch or forward it.

A `CX_NO_CHECK` exception does not need to be declared, because it can always propagate. It may still be declared explicitly to document that it can occur. Clean ABAP states that it cannot be declared; the ABAP Keyword Documentation takes precedence here (0.1).

### 6.4 Take exception texts from a message class through the T100 interfaces

T100 messages are translated, can be found with a where-used list, and can be passed on unchanged into `BAPIRET2` tables or the application log.

Implement `if_t100_dyn_msg` in your exception classes, and keep the texts in `zsm_msg`.

The `MESSAGE` addition of `RAISE EXCEPTION` accepts any class that implements `if_t100_message`. Its full functionality, including placeholders filled with `WITH`, requires `if_t100_dyn_msg`, which includes `if_t100_message`.

```abap
" ✅
CLASS zcx_zsm_static_error DEFINITION PUBLIC ABSTRACT
  INHERITING FROM cx_static_check CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.
ENDCLASS.

" ❌ text built in code and passed to an own string attribute: not translated, not findable
RAISE EXCEPTION NEW zcx_zsm_order_not_found( message_text = |Order { order_id } missing| ).
```

### 6.5 Raise with RAISE EXCEPTION NEW; use RAISE EXCEPTION TYPE … MESSAGE to attach a T100 message

`NEW` keeps the raise short. The `MESSAGE` addition binds the message class, number and placeholders at the raise point, where a where-used list finds them.

`MESSAGE` cannot be combined with `NEW`. `RAISE EXCEPTION NEW cx( … )` is the variant with an existing object reference, and the ABAP Keyword Documentation allows `MESSAGE` only together with `TYPE`.

Clean ABAP recommends `RAISE EXCEPTION NEW` over `RAISE EXCEPTION TYPE`. It notes that code which uses the `MESSAGE` addition heavily may stay with the `TYPE` form.

> ⚠️ **VERSION-DEPENDENT: `RAISE EXCEPTION NEW` and the `MESSAGE` addition.** Both depend on the release. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm).

```abap
" ✅ no message needed
RAISE EXCEPTION NEW zcx_zsm_order_not_found( previous = sql_error ).

" ✅ with a T100 message
RAISE EXCEPTION TYPE zcx_zsm_order_not_found
  MESSAGE e002(zsm_msg) WITH order_id.

" ❌
RAISE EXCEPTION TYPE zcx_zsm_order_not_found
  EXPORTING
    previous = sql_error.
```

### 6.6 Catch specific exceptions

A broad `CATCH` also catches programming errors and turns them into handled cases. Catch the classes you can actually handle, ordered from the most specific to the most general.

`cx_root` is caught only at an outermost boundary, such as a job step, an RFC entry point or a request handler. There it is logged and either re-raised or the processing ends cleanly. This is a team rule; see [18-Debugging](../18-Debugging/README.md#-exception-handling).

```abap
" ✅
TRY.
    order_service->release( order_id ).
  CATCH zcx_zsm_order_not_found INTO DATA(not_found).
    log->add( not_found ).
ENDTRY.

" ❌
TRY.
    order_service->release( order_id ).
  CATCH cx_root.
ENDTRY.
```

### 6.7 Never leave a CATCH block empty

An empty `CATCH` makes a failure disappear without a trace, and the next symptom shows up far from its cause.

Every `CATCH` must do at least one of three things:

- handle the error;
- convert it (6.8);
- log it.

This is a team rule.

```abap
" ✅
CATCH zcx_zsm_mail_failed INTO DATA(mail_error).
  " the order is released even if the notification fails; the log tells support
  log->add( mail_error ).

" ❌
CATCH zcx_zsm_mail_failed.
```

### 6.8 Keep the cause when converting an exception: pass it as PREVIOUS

The original exception holds the technical detail that support needs. `previous` keeps it reachable from the new one.

Clean ABAP recommends wrapping exceptions from other components in your own types instead of letting them pass through your signatures.

```abap
" ✅
CATCH cx_sy_open_sql_db INTO DATA(sql_error).
  RAISE EXCEPTION NEW zcx_zsm_order_not_saved( previous = sql_error ).

" ❌ the cause is lost
CATCH cx_sy_open_sql_db.
  RAISE EXCEPTION NEW zcx_zsm_order_not_saved( ).
```

### 6.9 Turn sy-subrc and BAPI RETURN tables into exceptions at the boundary

Classic results are read once, in the wrapper (5.1), so callers deal with only one error mechanism. Clean ABAP recommends exceptions over return codes and wrapping foreign errors.

The same applies to BAPIs: check the `RETURN` table in the wrapper and raise when it contains an error or an abort. For how to evaluate the table, see [15-BAPIs](../15-BAPIs/README.md).

```abap
" ✅
CALL FUNCTION 'ZSM_FM_READ_ORDERS'
  EXPORTING
    customer_id = customer_id
  IMPORTING
    orders      = orders
  EXCEPTIONS
    not_found   = 1
    OTHERS      = 2.
IF sy-subrc <> 0.
  RAISE EXCEPTION TYPE zcx_zsm_order_not_found
    MESSAGE e003(zsm_msg) WITH customer_id.
ENDIF.

" ❌ the return code travels on to the caller
result_code = sy-subrc.
```

### 6.10 Do not use exceptions for normal control flow

An exception says that something went wrong. Using one for an expected case hides the real errors and costs runtime. Clean ABAP states that exceptions are for errors, not for regular cases.

```abap
" ✅
IF line_exists( orders[ order_id = order_id ] ).
  ...
ENDIF.

" ❌
TRY.
    DATA(order) = orders[ order_id = order_id ].
    ...
  CATCH cx_sy_itab_line_not_found.
    " not found is a normal case here
ENDTRY.
```

### 6.11 Use MESSAGE statements only in the UI layer

What a `MESSAGE` statement does depends on the context it runs in: a dialog, a background job, an RFC call or an HTTP request. Code below the UI cannot know which context it will run in.

This is a team rule. Lower layers raise exceptions (6.5), and the UI layer turns them into messages. `MESSAGE … INTO` only fills the system fields and a variable without sending anything, so it may be used anywhere, for example to fill a log. Clean ABAP uses this form so that messages stay findable.

```abap
" ✅ below the UI
MESSAGE e004(zsm_msg) WITH order_id INTO DATA(message_text).
log->add_system_message( ).

" ❌ below the UI
MESSAGE e004(zsm_msg) WITH order_id.
```

---

## 7 Database Access and SAP LUW

> **Lifecycle:** `CURRENT / RECOMMENDED`. The explanations behind these rules are in [08-Open-SQL](../08-Open-SQL/README.md). This section only states the rules.

### 7.1 Write strict ABAP SQL: a comma-separated field list, @ host variables, INTO after the query clauses

The strict syntax is checked more thoroughly and reads like the SQL it produces. Unescaped host variables are an obsolete form (3.16). See [08-Open-SQL](../08-Open-SQL/README.md#-select--single-row--all-rows).

`INTO` follows the `WHERE`, `GROUP BY`, `HAVING` and `ORDER BY` clauses. Only `UP TO n ROWS`, `OFFSET` and the other ABAP-specific additions, such as `BYPASSING BUFFER`, come after it. The ABAP Keyword Documentation requires these additions after `INTO` whenever `INTO` is the last clause, and its newer strict modes enforce that position for `INTO`.

```abap
" ✅
SELECT order_id, status
  FROM zsm_t_order
  WHERE customer_id = @customer_id
  ORDER BY order_id
  INTO TABLE @DATA(orders)
  UP TO 100 ROWS.

" ❌
SELECT order_id status FROM zsm_t_order INTO TABLE orders
  WHERE customer_id = customer_id.
```

### 7.2 Read through released CDS views where they exist

A released CDS view is a stable interface, while a table layout can change. Apply 1.2 when targeting ABAP for Cloud Development and 1.3 in Standard ABAP. Rule 1.2 shows an example.

### 7.3 Do not SELECT inside a loop

Each statement is a round trip to the database, so the cost grows with the number of lines instead of staying constant. Read the data in one statement before the loop: a join, a subquery, `FOR ALL ENTRIES` (7.4) or an internal table as the data source.

```abap
" ✅
SELECT item~order_id, item~item_no, item~quantity
  FROM zsm_t_order_item AS item
  INNER JOIN zsm_t_order AS header ON header~order_id = item~order_id
  WHERE header~customer_id = @customer_id
  INTO TABLE @DATA(items).

" ❌
LOOP AT orders INTO DATA(order).
  SELECT item_no, quantity
    FROM zsm_t_order_item
    WHERE order_id = @order-order_id
    APPENDING TABLE @items.
ENDLOOP.
```

### 7.4 Use FOR ALL ENTRIES only with a non-empty, de-duplicated driver table

An empty driver table removes the whole `WHERE` condition, and duplicate rows cause redundant work. Where the driver can be expressed in SQL, a join or subquery is better. Where it exists only in ABAP, you can also use the internal table as a data source. See [08-Open-SQL](../08-Open-SQL/README.md#-for-all-entries-in).

> ⚠️ **VERSION-DEPENDENT: internal tables as data source (`FROM @itab`).** Available in newer releases only, with restrictions. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm).

```abap
" ✅ FOR ALL ENTRIES with a checked, de-duplicated driver
SORT order_ids BY order_id.
DELETE ADJACENT DUPLICATES FROM order_ids COMPARING order_id.
IF order_ids IS NOT INITIAL.
  SELECT order_id, item_no, quantity
    FROM zsm_t_order_item
    FOR ALL ENTRIES IN @order_ids
    WHERE order_id = @order_ids-order_id
    INTO TABLE @DATA(items).
ENDIF.

" ✅ the internal table as data source, where the release supports it
SELECT item~order_id, item~item_no, item~quantity
  FROM @order_ids AS wanted
  INNER JOIN zsm_t_order_item AS item ON item~order_id = wanted~order_id
  INTO TABLE @DATA(items).

" ❌ an empty order_ids reads every row of the table
SELECT order_id, item_no, quantity
  FROM zsm_t_order_item
  FOR ALL ENTRIES IN @order_ids
  WHERE order_id = @order_ids-order_id
  INTO TABLE @DATA(items).
```

### 7.5 Use SELECT SINGLE only with the full primary key

Without the full key, the row you get is any one of the rows that match. Which one may change between executions. When any row will do, say so with `UP TO 1 ROWS` and an `ORDER BY`. Existence checks are the exception (7.6), because there any row answers the question.

```abap
" ✅
SELECT SINGLE status
  FROM zsm_t_order
  WHERE order_id = @order_id
  INTO @DATA(status).

" ❌ several orders per customer: which one is returned is undefined
SELECT SINGLE status
  FROM zsm_t_order
  WHERE customer_id = @customer_id
  INTO @DATA(status).
```

### 7.6 Check existence with SELECT SINGLE @abap_true

The database only has to find one row, and no columns are transferred. `COUNT( * )` counts every match even when you only need to know whether there is one.

```abap
" ✅
SELECT SINGLE @abap_true
  FROM zsm_t_order
  WHERE customer_id = @customer_id
  INTO @DATA(has_orders).

" ❌
SELECT COUNT( * )
  FROM zsm_t_order
  WHERE customer_id = @customer_id
  INTO @DATA(order_count).
IF order_count > 0.
  ...
ENDIF.
```

### 7.7 List the fields you need instead of SELECT *

A field list transfers less data, documents what the code uses, and still works when someone appends columns to the table.

```abap
" ✅
SELECT order_id, status FROM zsm_t_order
  WHERE customer_id = @customer_id
  INTO TABLE @DATA(orders).

" ❌
SELECT * FROM zsm_t_order
  WHERE customer_id = @customer_id
  INTO TABLE @DATA(orders).
```

### 7.8 Let ABAP SQL handle the client

ABAP SQL restricts reads and writes to the logon client automatically. Naming the client column, or switching the handling off, opens access to other clients' data.

Use `USING CLIENT` or `USING [ALL] CLIENTS [IN]` only for an explicit cross-client requirement, and state that requirement in a comment.

`CLIENT SPECIFIED` is obsolete. It is forbidden in strict mode, and `USING` replaces it. ABAP for Cloud Development enforces client isolation.

```abap
" ✅
SELECT order_id FROM zsm_t_order
  WHERE customer_id = @customer_id
  INTO TABLE @DATA(orders).

" ❌
SELECT order_id FROM zsm_t_order CLIENT SPECIFIED
  WHERE mandt = @sy-mandt AND customer_id = @customer_id
  INTO TABLE @DATA(orders).
```

### 7.9 Write only to your own tables; change SAP standard data through BAPIs or released APIs

Standard tables are kept consistent by application logic, locks, change documents and follow-up processing. A direct `UPDATE` bypasses all of these. See [15-BAPIs](../15-BAPIs/README.md).

```abap
" ✅
UPDATE zsm_t_order SET status = @new_status WHERE order_id = @order_id.

" ✅ standard data: through the BAPI wrapper (5.1)
sales_order_api->change_delivery_date( order_id = order_id
                                       date     = new_date ).

" ❌ direct DML on a standard table
UPDATE vbak SET vdatu = @new_date WHERE vbeln = @order_id.
```

### 7.10 Let the top-level caller own the transaction; reusable units never COMMIT WORK

`COMMIT WORK` closes the whole SAP LUW, including work done by callers and other components. So only the code that owns the business transaction may decide when it ends. See [08-Open-SQL](../08-Open-SQL/README.md#-sap-luw--transaction-ownership).

```abap
" ✅ the report owns the transaction
TRY.
    order_service->release( order_id ).
    COMMIT WORK.
  CATCH zcx_zsm_static_error INTO DATA(error).
    ROLLBACK WORK.
    MESSAGE error TYPE 'E'.
ENDTRY.

" ❌ inside a reusable method
METHOD zif_zsm_order_service~release.
  repository->set_status( order_id = order_id
                          status   = released ).
  COMMIT WORK.
ENDMETHOD.
```

### 7.11 Close BAPI calls with BAPI_TRANSACTION_COMMIT or BAPI_TRANSACTION_ROLLBACK

BAPIs follow their own commit protocol, and the caller ends it with the matching BAPI. That call also belongs to the transaction owner, not to the wrapper. See [15-BAPIs](../15-BAPIs/README.md#-commit--rollback).

```abap
" ✅ at the transaction owner, after the wrapper reported success
CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
  EXPORTING
    wait = abap_true.

" ❌ in the wrapper, or a plain COMMIT WORK after a BAPI
COMMIT WORK.
```

### 7.12 Protect business transactions with enqueue locks

Database locks end with each database LUW, while a business transaction can span several of them. The SAP enqueue mechanism covers that gap.

Follow this pattern:

1. Lock before reading data that you intend to change.
2. Release the lock after the commit or the rollback.
3. Report a foreign lock as a business message.

See [08-Open-SQL](../08-Open-SQL/README.md#-sap-luw--transaction-ownership).

> 📝 **Contextual snippet** — assumes a lock object `EZSM_ORDER` on `zsm_t_order`, named as in [2.6](#26-name-development-objects-by-the-object-naming-table). The generated function module has one parameter per key field of the lock object, plus `mode_<table>` for the lock mode and `_scope` for the lock duration. A foreign lock raises the exception `foreign_lock`.

```abap
" ✅
CALL FUNCTION 'ENQUEUE_EZSM_ORDER'
  EXPORTING
    order_id       = order_id
  EXCEPTIONS
    foreign_lock   = 1
    system_failure = 2
    OTHERS         = 3.
IF sy-subrc <> 0.
  " USING MESSAGE passes the lock message from the sy-msg* fields to the exception
  RAISE EXCEPTION TYPE zcx_zsm_order_locked USING MESSAGE.
ENDIF.
```

### 7.13 Restrict the optional side of an outer join in the ON condition, not in WHERE

For each row of the left side, a `LEFT OUTER JOIN` returns at least one result row. Where no row of the right side matches, the columns of the right side contain null values.

According to the ABAP Keyword Documentation, every relational expression except `IS [NOT] NULL` has an unknown result when an operand is the null value. A comparison with a right-side column in the `WHERE` condition therefore removes exactly those rows the outer join added, and the result is the same as an inner join.

- Put restrictions on the optional side into the `ON` condition.
- In `WHERE`, test the optional side only with `IS NULL` or `IS NOT NULL`, and only when that is the intent, for example to find orders without items.

This is a team rule.

> ⚠️ **VERSION-DEPENDENT: comparisons in ON conditions.** Which operands an `ON` condition may contain, for example host variables or columns of the left side only, depends on the release and the strict mode of the syntax check. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm).

```abap
" ✅ every order of the customer, with its open items where there are any
SELECT header~order_id, item~item_no
  FROM zsm_t_order AS header
  LEFT OUTER JOIN zsm_t_order_item AS item
    ON  item~order_id = header~order_id
    AND item~status   = @status_open
  WHERE header~customer_id = @customer_id
  INTO TABLE @DATA(order_items).

" ❌ orders without an open item disappear: the result is that of an inner join
SELECT header~order_id, item~item_no
  FROM zsm_t_order AS header
  LEFT OUTER JOIN zsm_t_order_item AS item
    ON item~order_id = header~order_id
  WHERE header~customer_id = @customer_id
    AND item~status        = @status_open
  INTO TABLE @DATA(order_items).
```

### 7.14 Use COMMIT WORK AND WAIT only when the next step depends on the update

The ABAP Keyword Documentation describes the difference:

- Without `AND WAIT`, the update is asynchronous. The program continues immediately after `COMMIT WORK`, and `sy-subrc` is always 0.
- With `AND WAIT`, the program continues only after the update work process has executed the high-priority update function modules. `sy-subrc` is 0 if the update succeeded and 4 if it failed.

Waiting costs the user time, so it needs a reason:

- the next statement reads the data the update writes;
- the program must react when the update fails.

In both cases, evaluate `sy-subrc`. Otherwise, commit without waiting. The decision belongs to the transaction owner (7.10).

The same applies to the `WAIT` parameter of `BAPI_TRANSACTION_COMMIT` (7.11). **[verify: that `BAPI_TRANSACTION_COMMIT` with `WAIT` set executes `COMMIT WORK AND WAIT`]**

This is a team rule.

```abap
" ✅ the next step reads the order the update writes
COMMIT WORK AND WAIT.
IF sy-subrc <> 0.
  RAISE EXCEPTION TYPE zcx_zsm_order_not_saved
    MESSAGE e012(zsm_msg) WITH order_id.
ENDIF.
DATA(saved_order) = order_repository->read( order_id ).

" ❌ nothing after the commit depends on the update; the user waits for nothing
COMMIT WORK AND WAIT.
MESSAGE s013(zsm_msg) WITH order_id.
```

### 7.15 Qualify mass UPDATE and DELETE with WHERE, and check sy-dbcnt

According to the ABAP Keyword Documentation, `UPDATE … SET` without a `WHERE` condition changes all rows of the target, in a client-dependent table all rows of the current client. `DELETE FROM` without a condition deletes all rows. Both statements set `sy-dbcnt` to the number of rows changed or deleted.

- Every mass `UPDATE` and `DELETE` carries a `WHERE` condition that restricts it to the intended rows.
- Compare `sy-dbcnt` with the expected number where it is known, and treat a mismatch as an error before the transaction owner commits (7.10).
- Mass changes apply only to your own tables (7.9).

This is a team rule.

```abap
" ✅
UPDATE zsm_t_order SET status = @status_cancelled
  WHERE customer_id = @customer_id
    AND status      = @status_open.
IF sy-dbcnt <> lines( open_orders ).
  RAISE EXCEPTION TYPE zcx_zsm_order_not_saved
    MESSAGE e014(zsm_msg) WITH customer_id.
ENDIF.

" ❌ no WHERE: every order of the client is cancelled
UPDATE zsm_t_order SET status = @status_cancelled.
```

---

## 8 Security

> **Lifecycle:** `CURRENT / RECOMMENDED`. These rules apply in every language version. ABAP SQL on database tables performs no implicit authorization check, so most of this section is about checks that you have to write yourself.

### 8.1 Check authorization wherever business data is read or changed, and evaluate sy-subrc

`AUTHORITY-CHECK` only sets `sy-subrc`. If the code does not evaluate it, the check has no effect.

The check belongs before the read or the change, in the layer that owns the data access, so that every caller passes through it.

```abap
" ✅ generic table access: check the standard table authorization
AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
  ID 'ACTVT' FIELD activity_display
  ID 'TABLE' FIELD table_name.
IF sy-subrc <> 0.
  RAISE EXCEPTION TYPE zcx_zsm_not_authorized
    MESSAGE e010(zsm_msg) WITH table_name.
ENDIF.

" ❌ the result is never evaluated
AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
  ID 'ACTVT' FIELD activity_display
  ID 'TABLE' FIELD table_name.
SELECT * FROM (table_name) INTO TABLE @<rows>.
```

### 8.2 In guide examples, mark where the check belongs; never invent an authorization object

Authorization objects are specific to each application and each project. An invented object looks authoritative and gets copied.

Use a standard object only when the example is about exactly that object. Otherwise, put a marker comment in the place where the check belongs. CDSGuide uses the same marker. This is a team rule.

```abap
" ✅
" >>> Authorization check for the sales organization (order-sales_org) belongs here.
SELECT order_id, status FROM zsm_t_order
  WHERE sales_org = @sales_org
  INTO TABLE @DATA(orders).

" ❌ an object that does not exist, presented as if it did
AUTHORITY-CHECK OBJECT 'Z_ORDER_AUTH' ID 'ACTVT' FIELD '03'.
```

### 8.3 Use WITH PRIVILEGED ACCESS only with a written justification

The addition switches off CDS access control for the data source it is written on, so the read returns rows the user would otherwise not see.

The justification belongs in a comment directly at the statement. It names why the restriction does not apply here, and which check replaces it. This is a team rule. See CDSGuide, [Bypassing Access Control](https://github.com/serhatmercan/CDSGuide/blob/master/09-Security/AccessControl.md#bypassing-access-control-with-privileged-access).

> ⚠️ **VERSION-DEPENDENT: `WITH PRIVILEGED ACCESS`.** Availability depends on the release. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm).

```abap
" ✅
" Privileged: the totals job aggregates across all sales organizations and
" outputs no single document; access is limited by the job's own role.
SELECT FROM zsm_i_order WITH PRIVILEGED ACCESS
  FIELDS salesorg, SUM( netamount ) AS total
  GROUP BY salesorg
  INTO TABLE @DATA(totals).

" ❌ no reason given
SELECT FROM zsm_i_order WITH PRIVILEGED ACCESS
  FIELDS *
  INTO TABLE @DATA(orders).
```

### 8.4 Build dynamic SQL and other dynamic tokens only from validated input

A dynamic token is code. A token taken from input lets that input change the statement, which is how injection happens.

Prefer static SQL with host variables. Inside a dynamic token, too, naming an ABAP data object (`= @value`) is safer than building its value in as a literal.

Where names come from input, check them with `cl_abap_dyn_prg`:

- `check_whitelist_tab` against an allow list;
- `check_column_name` for a column;
- `check_table_name_str` for a table.

Any literal that you do build into a token must be escaped with `cl_abap_dyn_prg=>quote`.

```abap
" ✅ the column comes from a fixed list; the value stays a host variable
DATA(column) = cl_abap_dyn_prg=>check_whitelist_tab( val       = to_upper( requested_column )
                                                     whitelist = allowed_columns ).
DATA(condition) = |{ column } = @filter_value|.
SELECT order_id FROM zsm_t_order
  WHERE (condition)
  INTO TABLE @DATA(orders).

" ❌ input becomes part of the statement
DATA(condition) = |{ requested_column } = '{ user_input }'|.
```

> 📝 **Contextual snippet** — `allowed_columns` is of type `string_hashed_table`. A name that is not on the list raises `cx_abap_not_in_whitelist`.

### 8.5 Never hard-code credentials, hosts or destinations

Values written into code end up in transports and in version history. They are also identical in every system, which is wrong for a target that differs between development and production.

Connection details belong in an RFC destination (Standard ABAP) or a communication arrangement (ABAP Cloud). The name of the destination comes from configuration.

```abap
" ✅
DATA(destination) = configuration->order_system_destination( ).
CALL FUNCTION 'ZSM_FM_READ_ORDERS' DESTINATION destination
  EXPORTING
    customer_id           = customer_id
  IMPORTING
    orders                = orders
  EXCEPTIONS
    system_failure        = 1
    communication_failure = 2
    OTHERS                = 3.

" ❌
cl_http_client=>create_by_url( EXPORTING url    = 'https://<host>/orders'
                               IMPORTING client = DATA(client) ).
client->authenticate( username = '<user>'
                      password = '<password>' ).
```

### 8.6 Never generate passwords, tokens or one-time codes with cl_abap_random

According to the ABAP Keyword Documentation, `cl_abap_random` and its typed variants call the Mersenne Twister, a pseudo-random number generator. Their output follows from the seed and can be predicted, so it must not protect anything.

Use a cryptographically secure generator. **[verify: the recommended API for cryptographically secure random values in each language version, e.g. function module `GENERATE_SEC_RANDOM` in Standard ABAP]**

```abap
" ❌ predictable
DATA(one_time_code) = cl_abap_random_int=>create( seed = seed
                                                  min  = 100000
                                                  max  = 999999 )->get_next( ).
```

### 8.7 Resolve and validate file paths through logical file names

A path taken from input can point anywhere the application server can reach (directory traversal). A logical file name restricts it to a maintained directory. Logical file names are maintained in transactions `FILE` and `SF01`.

The ABAP Keyword Documentation names two function modules:

- `FILE_VALIDATE_NAME` checks a physical file name against a logical file name or path.
- `FILE_GET_NAME` builds physical names from logical ones. A program that only uses it usually needs no further validation.

Check file-access authorization as well. `FILE_VALIDATE_NAME` raises the classic exceptions `LOGICAL_FILENAME_NOT_FOUND` and `VALIDATION_FAILED`.

```abap
" ✅
CALL FUNCTION 'FILE_VALIDATE_NAME'
  EXPORTING
    logical_filename  = export_file_name
  CHANGING
    physical_filename = file_path
  EXCEPTIONS
    OTHERS            = 1.
IF sy-subrc <> 0.
  RAISE EXCEPTION TYPE zcx_zsm_invalid_path
    MESSAGE e011(zsm_msg) WITH file_path.
ENDIF.

" ❌ the path is used as entered
OPEN DATASET file_path FOR OUTPUT IN TEXT MODE ENCODING UTF-8.
```

### 8.8 Log no secrets, and no personal data beyond what the purpose needs

Logs are read by more people than the data they describe, and they are kept longer. Log the identifiers and the message that support needs, not the payload.

```abap
" ✅
log->add_text( |Payment for order { order_id } rejected| ).

" ❌
log->add_text( |Payment rejected: IBAN { payment-iban }, token { api_token }| ).
```

### 8.9 Call transactions WITH AUTHORITY-CHECK

The ABAP Keyword Documentation describes the additions `WITH AUTHORITY-CHECK` and `WITHOUT AUTHORITY-CHECK` of `CALL TRANSACTION`:

- **`WITH AUTHORITY-CHECK`** checks the current user's authorization before the call. The check uses the authorization object `S_TCODE` and any authorization object entered in the definition of the transaction code (transaction `SE93`). Missing authorization raises the catchable exception `CX_SY_AUTHORIZATION_ERROR`. The documentation calls this the recommended way to check authorization. It replaces earlier checks with `AUTHORITY-CHECK`, the function module `AUTHORITY_CHECK_TCODE`, or the table `TCDCOUPLES`.
- **`WITHOUT AUTHORITY-CHECK`** states that no check is necessary, and suppresses the corresponding message of the extended program check.
- **No addition:** the documentation classifies `CALL TRANSACTION` without one of the two additions as obsolete (3.16).

Write `WITH AUTHORITY-CHECK` by default. Use `WITHOUT AUTHORITY-CHECK` only with a comment at the statement that explains why the check is not needed. This is a team rule.

> ⚠️ **VERSION-DEPENDENT: `WITH|WITHOUT AUTHORITY-CHECK`.** Availability of the additions depends on the release. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm).

```abap
" ✅
TRY.
    CALL TRANSACTION 'ZSM_ORDER' WITH AUTHORITY-CHECK.
  CATCH cx_sy_authorization_error INTO DATA(authorization_error).
    MESSAGE authorization_error TYPE 'E'.
ENDTRY.

" ❌ obsolete form; whether the user's authorization matters is not stated
CALL TRANSACTION 'ZSM_ORDER'.
```

### 8.10 Check business authorizations at every RFC entry point

A remote-enabled function module can be called from another system or program. A check in the caller's UI is not part of that path.

According to the ABAP Keyword Documentation, an automatic authorization check runs for remote calls only if the profile parameter `auth/rfc_authority_check` is set to 1. That check decides whether the function module may be called at all. It says nothing about the business data the function module reads or changes. **[verify: that the automatic check uses the authorization object `S_RFC`]**

- The RFC function module, or the class it delegates to (5.1), checks the business authorizations itself, before it reads or changes data (8.1).
- A failed check is reported through the function module's classic exceptions or its return table. RFC supports only classic exceptions (6.1).

This is a team rule.

```abap
" ✅ the class behind the RFC function module checks before it reads
METHOD read_for_customer.
  " >>> Authorization check for the customer's sales organization belongs here (8.2).
  SELECT order_id, status FROM zsm_t_order
    WHERE customer_id = @customer_id
    INTO TABLE @result.
ENDMETHOD.

" ❌ the RFC function module relies on a check in the calling UI
FUNCTION zsm_fm_read_orders.
  SELECT order_id, status FROM zsm_t_order
    WHERE customer_id = @customer_id
    INTO TABLE @orders.
ENDFUNCTION.
```

---

## 9 Performance

> **Lifecycle:** `CURRENT / RECOMMENDED`. For tools and techniques, see [19-Performance](../19-Performance/README.md). Database-side optimisation is the topic of HANAGuide (planned).

### 9.1 Measure before you optimise

Intuition about where the time goes is usually wrong, and an optimisation without a measurement cannot show that it helped. Use runtime analysis (`SAT`, or the ABAP profiler in ADT) and the SQL trace (`ST05`) on realistic data volumes. This is a team rule.

### 9.2 Push set-based work to the database

Filtering, aggregating and joining where the data already is avoids moving rows that are thrown away later.

Use the `WHERE`, `GROUP BY`, aggregate functions and joins of ABAP SQL. Deeper pushdown (CDS, AMDP) is outside ABAPGuide and belongs to HANAGuide (planned).

```abap
" ✅
SELECT customer_id, SUM( net_amount ) AS total
  FROM zsm_t_order
  WHERE status = @status_completed
  GROUP BY customer_id
  INTO TABLE @DATA(totals).

" ❌ every row travels to ABAP only to be summed
SELECT customer_id, net_amount, status FROM zsm_t_order
  INTO TABLE @DATA(orders).
LOOP AT orders INTO DATA(order) WHERE status = status_completed.
  ...
ENDLOOP.
```

### 9.3 Choose table kind and keys deliberately; add secondary keys for frequent non-primary reads

Access through a sorted or hashed key avoids a full scan, and the table kind documents how the table is used. Clean ABAP recommends choosing the right table type and avoiding `DEFAULT KEY`.

A secondary key costs memory and maintenance. Add one only for reads that actually happen often. See [07-Internal-Tables](../07-Internal-Tables/README.md#-defining-table-types).

```abap
" ✅
TYPES orders_by_id TYPE SORTED TABLE OF zsm_s_order
  WITH UNIQUE KEY order_id
  WITH NON-UNIQUE SORTED KEY by_customer COMPONENTS customer_id.

" ❌ the default key is all character-like fields, rarely what you mean
TYPES orders_by_id TYPE STANDARD TABLE OF zsm_s_order WITH DEFAULT KEY.
```

### 9.4 Avoid nested loops over large tables

An inner loop over a whole table multiplies the run time by the table's size.

- Use keyed access for the inner part: a table expression, or `LOOP … WHERE` on a sorted or secondary key.
- Use `LOOP … GROUP BY` when you process lines in groups.

```abap
" ✅ the inner loop uses the sorted key on order_id
LOOP AT orders INTO DATA(order).
  LOOP AT items INTO DATA(item) USING KEY by_order WHERE order_id = order-order_id.
    ...
  ENDLOOP.
ENDLOOP.

" ❌ the inner loop scans all items for every order
LOOP AT orders INTO DATA(order).
  LOOP AT items INTO DATA(item).
    IF item-order_id = order-order_id.
      ...
    ENDIF.
  ENDLOOP.
ENDLOOP.
```

### 9.5 Loop with ASSIGNING or REFERENCE INTO for large rows and for changes

`INTO` copies every row, while a field symbol or reference works on the row in place. Clean ABAP describes when to use each target. It recommends field symbols for reading and changing rows, and references when the reference must outlive the loop.

```abap
" ✅
LOOP AT orders ASSIGNING FIELD-SYMBOL(<order>).
  <order>-status = released.
ENDLOOP.

" ❌
LOOP AT orders INTO DATA(order).
  order-status = released.
  MODIFY orders FROM order.
ENDLOOP.
```

### 9.6 Read a table line once

See [3.14](#314-read-a-line-once-not-once-per-component). Repeated table expressions on the same line are a common hidden cost inside loops.

### 9.7 Do not use SELECT … ENDSELECT to read row by row

Each pass of the loop fetches from the database cursor, and the loop body runs while the cursor is open. Read into a table with `INTO TABLE`.

For volumes too large to hold in memory, `PACKAGE SIZE` with `ENDSELECT` processes the data in blocks, and that use is accepted. See [19-Performance](../19-Performance/README.md).

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE`. Row-by-row `SELECT … ENDSELECT` is listed in [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference) with `SELECT … INTO TABLE` as the replacement.

```abap
" ✅
SELECT order_id, status FROM zsm_t_order
  WHERE customer_id = @customer_id
  INTO TABLE @DATA(orders).

" ❌
SELECT order_id, status FROM zsm_t_order
  WHERE customer_id = @customer_id
  INTO @DATA(order).
  APPEND order TO orders.
ENDSELECT.
```

### 9.8 Use COLLECT only with hashed tables or sorted tables with a unique key

`COLLECT` relies on unique entries with respect to the primary table key and on a stable key administration. Hashed tables and sorted tables have such an administration of their own, and their key decides which line the values are added to.

A standard table only gets a temporary hash administration for `COLLECT`, which other changes to the table invalidate. Every following `COLLECT` then searches linearly, and the primary key of a standard table is never unique. A sorted table with a non-unique key works correctly only as long as nothing but `COLLECT` fills it. The ABAP Programming Guidelines therefore say: only use `COLLECT` for hashed tables or sorted tables with a unique key, and not for standard tables any more.

All components outside the primary key must be numeric; their values are added up. See [06-Loops](../06-Loops/README.md#-collect--aggregating-rows).

```abap
" ✅
TYPES quantities_by_material TYPE HASHED TABLE OF zsm_s_material_quantity
                             WITH UNIQUE KEY matnr.
DATA quantities TYPE quantities_by_material.

COLLECT VALUE zsm_s_material_quantity( matnr = item-matnr quantity = item-quantity ) INTO quantities.

" ❌ standard table: temporary hash administration, linear search after other changes
DATA quantities TYPE STANDARD TABLE OF zsm_s_material_quantity WITH DEFAULT KEY.
```

## 10 Testing

> **Lifecycle:** `CURRENT / RECOMMENDED`. ABAP Unit is the test framework for ABAP code. An ABAPGuide chapter on ABAP Unit is planned. Until it exists, these rules are the reference.

### 10.1 Write ABAP Unit tests for every new class

A test fixes the intended behaviour, so the next change can be made without fear of silently breaking it.

Classes built along section 5 (interfaces, constructor injection, small methods) are testable by design. Clean ABAP recommends writing testable code, and warns against obsessing about coverage numbers.

Requiring tests for every new class is a team rule.

### 10.2 Put unit tests in local test classes with RISK LEVEL HARMLESS and DURATION SHORT

Local test classes live in the test include of the class under test. They are found and run together with that class.

`HARMLESS` and `SHORT` describe a proper unit test: it changes no persistent data and finishes quickly. Clean ABAP recommends local test classes for unit tests and names them by purpose with `ltc_` (its own convention for test classes).

The default risk level and duration are a team rule. A higher risk level or longer duration needs a comment that explains it.

```abap
" ✅
CLASS ltc_release DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.
  PRIVATE SECTION.
    DATA cut        TYPE REF TO zif_zsm_order_service.
    DATA repository TYPE REF TO zif_zsm_order_repository.
    METHODS setup.
    METHODS releases_open_order      FOR TESTING RAISING cx_static_check.
    METHODS rejects_completed_order FOR TESTING RAISING cx_static_check.
ENDCLASS.

" ❌ no reason given for the risk level
CLASS ltc_test DEFINITION FOR TESTING
  RISK LEVEL DANGEROUS
  DURATION LONG.
```

### 10.3 Test one behaviour per test method

A failing test should point to one broken behaviour. A method that checks several behaviours stops at the first failure and hides the rest.

Clean ABAP recommends that the "when" part be exactly one call, and that assertions be few and focused.

```abap
" ✅
METHODS releases_open_order      FOR TESTING RAISING cx_static_check.
METHODS rejects_completed_order FOR TESTING RAISING cx_static_check.

" ❌
METHODS test_release FOR TESTING RAISING cx_static_check.  " releases, rejects, notifies
```

### 10.4 Name test methods after the behaviour they check

The test list then reads as a specification, and a failure message says what broke. Clean ABAP recommends names that reflect the given and the expected outcome.

Within the 30-character limit for method names, an ABAP Doc comment can add what the name cannot hold.

```abap
" ✅
METHODS rejects_completed_order FOR TESTING RAISING cx_static_check.

" ❌
METHODS test_release_2 FOR TESTING RAISING cx_static_check.
```

### 10.5 Structure each test as given, when, then

The reader can see the setup, the single action and the expected outcome as three separate parts. Clean ABAP recommends the given-when-then structure, and extracting helper methods when a part grows long.

```abap
" ✅
METHOD rejects_completed_order.
  " given
  cl_abap_testdouble=>configure_call( repository )->returning( completed_order ).
  repository->read( completed_order-order_id ).

  " when
  TRY.
      cut->release( completed_order-order_id ).
      cl_abap_unit_assert=>fail( msg = 'Release of a completed order must fail' ).
    CATCH zcx_zsm_order_not_releasable INTO DATA(error).
      " then
      cl_abap_unit_assert=>assert_equals( act = error->order_id
                                          exp = completed_order-order_id ).
  ENDTRY.
ENDMETHOD.
```

> 📝 **Contextual snippet** — assumes the test class from 10.2, a test double from 10.6, a structure constant `completed_order`, and an `order_id` attribute on the exception.

### 10.6 Replace dependencies with test doubles through interfaces and cl_abap_testdouble

A double that is passed through the constructor (5.4) isolates the class under test without changing its code.

`cl_abap_testdouble` creates and configures such doubles without hand-written classes. Clean ABAP recommends dependency inversion for injecting test doubles, and suggests considering the ABAP test double framework.

```abap
" ✅
METHOD setup.
  repository = CAST zif_zsm_order_repository(
                   cl_abap_testdouble=>create( 'ZIF_ZSM_ORDER_REPOSITORY' ) ).
  cut = NEW zcl_zsm_order_service( repository ).
ENDMETHOD.

" ❌ the real repository reads the database
METHOD setup.
  cut = NEW zcl_zsm_order_service( NEW zcl_zsm_order_db_repository( ) ).
ENDMETHOD.
```

### 10.7 Use test seams only for legacy code that cannot be restructured yet

A test seam embeds test logic in production code and ties the test to private details. It is a bridge towards a refactoring, not a design. Clean ABAP recommends test seams only as a temporary workaround.

```abap
" ✅ in a legacy method that cannot be given a dependency yet
TEST-SEAM read_orders.
  SELECT order_id, status FROM zsm_t_order
    WHERE customer_id = @customer_id
    INTO TABLE @orders.
END-TEST-SEAM.

" ❌ a new class that uses a test seam instead of an injected repository (5.4)
```

### 10.8 Isolate database access with the ABAP SQL and CDS test double frameworks; never use real data

Tests against real data break when that data changes, and they can change it themselves.

The ABAP SQL test environment and the CDS test environment redirect reads to test doubles that the test fills itself. Clean ABAP points to the available test isolation tools.

> ⚠️ **VERSION-DEPENDENT: ABAP SQL and CDS test environments.** Availability and API details depend on the release. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm). Both `cl_osql_test_environment` and `cl_cds_test_environment` are released for ABAP for Cloud Development. The instances they create implement `if_osql_test_environment` and `if_cds_test_environment`, which provide `insert_test_data` (parameter `i_data`), `clear_doubles` and `destroy`. **[verify: the factory method `create` and its parameter `i_dependency_list`]**

```abap
" ✅
CLASS-METHODS class_setup.

METHOD class_setup.
  sql_environment = cl_osql_test_environment=>create(
                        i_dependency_list = VALUE #( ( 'ZSM_T_ORDER' ) ) ).
ENDMETHOD.

METHOD setup.
  sql_environment->clear_doubles( ).
  sql_environment->insert_test_data( test_orders ).
ENDMETHOD.

" ❌ depends on whatever the development system contains
METHOD finds_open_orders.
  DATA(orders) = cut->read_open( ).
  cl_abap_unit_assert=>assert_not_initial( orders ).
ENDMETHOD.
```

### 10.9 Assert with cl_abap_unit_assert, using the most specific method

A specific assertion such as `assert_equals` reports what it expected and what it got. A generic one only reports that something failed.

Clean ABAP recommends:

- the right assertion type for the check;
- asserting content, not quantity;
- `fail` for expected exceptions.

```abap
" ✅
cl_abap_unit_assert=>assert_equals( act = released_order-status
                                    exp = released ).

" ❌
cl_abap_unit_assert=>assert_true( xsdbool( released_order-status = released ) ).
```

### 10.10 Run the tests in ATC and in continuous integration

Tests that only run when someone remembers to start them stop protecting anything. ABAP Unit runs as part of the quality gates in 13.1. Where a CI pipeline exists, run them there as well. This is a team rule.

---

## 11 Comments and ABAP Doc

### 11.1 Say it in code first

A good name or an extracted method stays correct as the code changes. A comment does not.

Clean ABAP recommends:

- expressing yourself in code rather than in comments;
- not using comments as an excuse for bad names;
- using methods instead of comments to segment code.

```abap
" ✅
IF is_releasable( order ).

" ❌
" status must be open and no credit block
IF order-status = created AND order-credit_block = abap_false.
```

### 11.2 Explain why, not what; comment with " before the statement

The code already says what happens. Only a comment can say why a non-obvious decision was taken.

Clean ABAP recommends:

- comments that explain the why;
- `"` rather than `*`;
- placing the comment before the statement it refers to.

```abap
" ✅
" the partner system rejects lines without a delivery date, so drop them early
DELETE items WHERE delivery_date IS INITIAL.

" ❌
* delete items without delivery date
DELETE items WHERE delivery_date IS INITIAL.
```

### 11.3 Delete code instead of commenting it out

Version control keeps the old code. Commented-out code only adds noise and goes stale. Clean ABAP recommends deleting code instead of commenting it out, and leaving versioning to the tools.

The guides show rejected alternatives as ❌ examples, labelled as such. That is documentation, not commented-out production code, and it follows each repository's CLAUDE.md.

```abap
" ✅
DATA(fee) = fee_calculator->calculate( order ).

" ❌
DATA(fee) = fee_calculator->calculate( order ).
* DATA(fee) = order-amount * fee_rate.
* fee = fee + surcharge.
```

### 11.4 Document public classes, interfaces and methods with ABAP Doc, including @parameter and @raising

ABAP Doc appears in the ADT element information wherever the method is called, so the caller learns the contract without opening the implementation.

The rule covers global interfaces and the public section of global classes. Section 14 records how this differs from Clean ABAP.

```abap
" ✅
"! Releases an open order for delivery.
"! @parameter order_id | Order to release
"! @raising zcx_zsm_order_not_found | No order with this ID exists
"! @raising zcx_zsm_order_not_releasable | The order is not in status created
METHODS release
  IMPORTING order_id TYPE zsm_e_order_id
  RAISING   zcx_zsm_order_not_found
            zcx_zsm_order_not_releasable.

" ❌ a plain comment instead of ABAP Doc; the exceptions are not described
" release the order
METHODS release
  IMPORTING order_id TYPE zsm_e_order_id
  RAISING   zcx_zsm_order_not_found
            zcx_zsm_order_not_releasable.
```

### 11.5 Use pragmas instead of pseudo comments, each with a reason

Pragmas are checked by the compiler and are tied to a specific check. Clean ABAP recommends pragmas over pseudo comments.

A suppressed finding without a reason cannot be judged in review, so a comment explains why the finding does not apply. The reason requirement is a team rule.

```abap
" ✅
" the variable is unused on purpose: the INTO form keeps the message findable (6.11)
MESSAGE e004(zsm_msg) WITH order_id INTO DATA(message_text) ##NEEDED.

" ❌
MESSAGE e004(zsm_msg) WITH order_id INTO DATA(message_text). "#EC NEEDED
```

### 11.6 Mark open work with a ticket reference, not a personal ID

A ticket survives team changes and carries the discussion. A personal ID points to someone who may have left, and it puts personal data into the code. Section 14 records how this differs from Clean ABAP. This is a team rule.

```abap
" ✅
" TODO ticket 4711: replace with the released API once it is available
" ❌
" TODO JD: replace this
```

---

## 12 Formatting

> 💡 Most of this section is enforced by the ABAP Formatter (12.3). A team that shares formatter settings rarely discusses formatting in review.

### 12.1 Write keywords in upper case and identifiers in lower case

Upper-case keywords separate the language from the names at a glance. This is the convention in all the guides.

Clean ABAP deliberately leaves keyword case to the team. Choosing upper case is a team rule.

```abap
" ✅
LOOP AT orders ASSIGNING FIELD-SYMBOL(<order>).

" ❌
loop at ORDERS assigning field-symbol(<ORDER>).
```

### 12.2 Write no more than one statement per line

One statement per line keeps diffs, breakpoints and the debugger's line display precise. Clean ABAP recommends no more than one statement per line.

```abap
" ✅
CLEAR total.
CLEAR count.

" ❌
CLEAR total. CLEAR count.
```

### 12.3 Format with the ABAP Formatter and the team's settings before activating

The formatter makes indentation mechanical and identical for everyone.

Clean ABAP recommends running the formatter (the pretty printer in SAP GUI) before activating, with the team's shared settings. In large unformatted legacy objects, it suggests formatting only the changed lines, or formatting the whole object in a separate transport.

### 12.4 Do not chain up-front declarations

A chain implies that the declared items belong together, and it makes every edit a matter of commas and colons. Clean ABAP recommends against chaining up-front declarations.

When a declaration is needed up front at all (3.1), write one statement per item.

```abap
" ✅
DATA total TYPE zsm_e_amount.
DATA count TYPE i.

" ❌
DATA: total TYPE zsm_e_amount,
      count TYPE i.
```

> 📝 Structured constants (4.3), `BEGIN OF ENUM` (4.4) and `TYPES … BEGIN OF` stay in the colon form. There the chain holds the parts of one structure, not unrelated variables.

### 12.5 Keep lines within 120 characters

Long lines force horizontal scrolling and hide the end of a statement. Clean ABAP recommends a maximum line length of 120 characters, and mentions that ADT's print margin can be set to it.

### 12.6 Break and align parameters in calls as Clean ABAP describes

Consistent line breaks show at a glance where one parameter ends and the next begins. Clean ABAP recommends:

- keeping a single-parameter call on one line;
- putting each of several parameters on its own line, behind the call;
- aligning the `=` signs;
- if the line becomes too long, breaking after the opening parenthesis and indenting the parameters by four spaces (keywords such as `EXPORTING` by two).

```abap
" ✅
DATA(order_id) = sales_order_api->create( order ).
repository->set_status( order_id = order_id
                        status   = released ).

" ❌
repository->set_status( order_id = order_id status = released ).
repository->set_status(
order_id = order_id
status = released ).
```

---

## 13 Quality Gates

### 13.1 Release nothing that fails the syntax check, ABAP Unit or ATC with the team check variant

Release here means releasing the transport. These three checks catch most defects before they leave the development system.

A shared check variant makes the result the same for everyone. This is a team rule.

### 13.2 Fix every ATC finding or exempt it with a written reason

A finding that is merely ignored comes back in every run and teaches the team to overlook the list.

An exemption with a reason can be reviewed and later revisited. The same applies to pragmas (11.5). This is a team rule.

### 13.3 Run the cloud-readiness check wherever section 1 applies

Code that targets ABAP for Cloud Development (1.2) or is meant to stay cloud-ready (1.3) needs the matching ATC check, and the check must run before anyone calls the code cloud-ready (1.5). This is a team rule.

### 13.4 Use abaplint for offline checks of complete, abapGit-serialized objects

abaplint checks ABAP outside a system, for example in a pull request. It needs complete objects as abapGit serializes them, because it resolves definitions across files.

Align its configuration (`abaplint.json` in the repository root) with these rules. Where a rule here has an abaplint counterpart, enable it. Where they disagree, these rules win and the configuration records the difference.

| Section | abaplint rules |
|---|---|
| 2 Naming | `no_prefixes`, `object_naming` |
| 3 Modern syntax | `prefer_inline`, `use_new`, `prefer_string_template`, `use_line_exists`, `functional_writing`, `omit_receiving`, `obsolete_statement` |
| 4 Booleans | `prefer_abap_bool`, `prefer_abap_bool_values`, `prefer_xsdbool` |
| 12 Formatting | `keyword_case`, `max_one_statement`, `line_length`, `keep_single_parameter_on_one_line`, `line_break_multiple_parameters`, `align_parameters` |

This is a team rule.

### 13.5 Claim a check in the guides only after it ran, and record it

"ATC-checked" and "abaplint-checked" are factual claims about a specific run. Make them only after that run, and record them the way each repository records its review status.

Contextual snippets (0.5) are never claimed as checked: they are not complete objects, and no check can have run on them. This is a team rule.

---

## 14 Deviations from Clean ABAP

Rules 0–13 were compared against the current Clean ABAP text. The table lists only real contradictions. Points where Clean ABAP leaves the choice to the team, such as keyword case, are team additions. They are indexed after the table, followed by the rules taken from the ABAP Programming Guidelines.

| Rule | Clean ABAP says | We do | Why |
|---|---|---|---|
| [2.6](#26-name-development-objects-by-the-object-naming-table) | Avoid encodings, including prefixes such as `cl_` and `if_`. Its sub-page on encodings accepts them for global Dictionary objects only as a compromise. | Every development object carries a type infix after the namespace: `zcl_zsm_`, `zsm_tt_`, `zsm_s_` and so on. | Global objects share one Dictionary namespace. The infix shows the object type wherever only the name is visible: transport lists, where-used lists, SE11. One scheme across all guides. |
| [2.6](#26-name-development-objects-by-the-object-naming-table) (local types) | Avoid encodings. It says nothing specific about local classes and interfaces, but names its own local test classes `ltc_` and test helpers `lth_`. | Local classes take `lcl_`, local interfaces `lif_`, local test classes `ltc_` and local test helpers `lth_`. | Consistent with Clean ABAP's own `ltc_` / `lth_` practice. A short local prefix makes local types recognisable inside a program. |
| [6.11](#611-use-message-statements-only-in-the-ui-layer) | For totally unrecoverable situations, dump. Where `RAISE SHORTDUMP` is not available, use a type `X` message. | No `MESSAGE` statement below the UI layer, including type `X`. Unrecoverable situations raise a `CX_NO_CHECK` exception (6.3). | An exception reaches the boundary handler (6.6), which logs it with its cause chain (6.8). A type `X` message ends the program before anything can be logged. |
| [11.4](#114-document-public-classes-interfaces-and-methods-with-abap-doc-including-parameter-and-raising) | Write ABAP Doc only for public APIs meant for other teams or applications, and do not enforce it everywhere. | ABAP Doc for every global interface and every public section of a global class. | The public section is kept minimal (5.6), so the cost stays small. In the guides, every public method is an API for readers who copy it. |
| [11.6](#116-mark-open-work-with-a-ticket-reference-not-a-personal-id) | Add your nickname, initials or user to `TODO`, `FIXME` and `XXX` comments. | A ticket reference instead of a personal ID. | The repository rules forbid user names in content. A ticket outlives the people working on it. |

### Team additions

These rules are decisions of the team: they have no basis in Clean ABAP or the ABAP Programming Guidelines, go beyond them, or decide a point that Clean ABAP leaves open. Each is marked as a team rule where it is stated.

| Area | Rules |
|---|---|
| Language version | 1.3 |
| Modern syntax | 3.8, 3.9, 3.18, 3.19 (no new macros at all) |
| Classes and methods | 5.12 |
| Error handling | 6.2 (one abstract root per category), 6.6, 6.7, 6.11 |
| Database access and SAP LUW | 7.13, 7.14, 7.15 |
| Security | 8.2, 8.3, 8.9, 8.10 |
| Performance | 9.1 |
| Testing | 10.1, 10.2 (default risk level and duration), 10.10 |
| Comments | 11.5 (reason for each pragma), 11.6 |
| Formatting | 12.1 |
| Quality gates | 13.1, 13.2, 13.3, 13.4, 13.5 |
| AI-assisted development | 15.1–15.5 |

### Rules from the ABAP Programming Guidelines

These rules have no Clean ABAP counterpart and are not team rules. They follow a recommendation of the ABAP Programming Guidelines.

| Rule | Guideline recommendation |
|---|---|
| [3.19](#319-do-not-write-macros-use-methods-or-expressions) | Macros only in exceptional cases; methods or expressions instead; no new macros in type pools or `TRMAC`. The ban on all new macros is the team part. |
| [9.8](#98-use-collect-only-with-hashed-tables-or-sorted-tables-with-a-unique-key) | `COLLECT` only for hashed tables or sorted tables with a unique key. |

---

## 15 AI-Assisted Development

> 📝 Generated code is held to the same rules as hand-written code. This section adds only what is specific to working with an assistant. All rules in it are team rules.

### 15.1 Cite these rules by number in CLAUDE.md and similar instruction files

A number points to one maintained text. A paraphrase in each repository drifts apart.

Write, for example, `Follow docs/ABAP-Development-Rules.md; naming per Rule 2.6, transaction ownership per Rule 7.10.` Use the citation form from 0.4.

### 15.2 Review generated ABAP against this checklist before accepting it

An assistant writes plausible code quickly, including plausible names that do not exist. The checklist targets exactly those failures.

| Check | Rule |
|---|---|
| Names follow Clean ABAP naming and the object naming table | 2.1–2.6 |
| No `COMMIT WORK` in reusable units | 7.10, 7.11 |
| Authorization check present, or the marker in guide examples | 8.1, 8.2 |
| No invented objects, APIs, parameters or authorization objects: every name exists in the system or is a labelled `zsm` placeholder | 2.6, 8.2 |
| Only released APIs where the cloud language version is targeted | 1.2 |
| No release or support-package claims without verification; release-dependent content labelled `VERSION-DEPENDENT` | 1.1, 0.1 |
| The available checks ran before anything is claimed as checked | 13.1, 13.5 |

### 15.3 State the target language version in every prompt that asks for code

Without it, the assistant has to guess between Standard ABAP and ABAP for Cloud Development, and the two accept different statements and APIs (1.1, 1.4).

### 15.4 Ask the assistant to list what it did not verify

The list shows where the review effort belongs. In the guides, each item becomes a marker in the text or a question to resolve before publishing.

### 15.5 Never paste customer data into a prompt

A prompt leaves the system it came from. Use neutral placeholders instead of real data.

Customer data includes:

- customer and employer names;
- system IDs, hosts and IP addresses;
- user names;
- business documents and Customizing values.
