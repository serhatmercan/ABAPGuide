# 20 — Best Practices & Clean ABAP

> **Lifecycle:** `CURRENT / RECOMMENDED`. This chapter is a readable digest of the [ABAP Development Rules](../docs/ABAP-Development-Rules.md); the rules document is the binding text and holds the full reasoning and examples.

## 📖 Introduction

This chapter collects the guidance that applies to every ABAP program in this guide: how to name things, how to shape classes and methods, how to comment, format and refactor, and what a reviewer checks before a transport is released.

It does not repeat the rules. Each section gives one line per rule and links to it, so the chapter and the rules document cannot drift apart. Cite rules by number in reviews and commit messages, for example `Rule 7.10` (see [Rule 0.4](../docs/ABAP-Development-Rules.md#04-cite-rules-by-number)).

The rules build on SAP's [Clean ABAP style guide](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md). Where they deliberately differ from it, the reason is recorded in [section 14 of the rules](../docs/ABAP-Development-Rules.md#14-deviations-from-clean-abap). Facts about the language come from the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm).

## 🏷️ Naming

- Use descriptive snake_case names without type or scope prefixes — [Rule 2.1](../docs/ABAP-Development-Rules.md#21-use-descriptive-snake_case-names-without-type-or-scope-prefixes).
- Use plural nouns for tables, nouns for classes, verbs for methods, and questions for Booleans — [Rule 2.2](../docs/ABAP-Development-Rules.md#22-use-plural-nouns-for-tables-nouns-for-classes-and-verbs-for-methods).
- Avoid abbreviations and noise words such as `data` or `info` — [Rule 2.3](../docs/ABAP-Development-Rules.md#23-avoid-abbreviations-and-noise-words-abbreviate-the-same-way-everywhere-when-length-forces-it).
- Keep names fixed by a signature you do not own, such as SEGW-generated or BAPI parameters — [Rule 2.4](../docs/ABAP-Development-Rules.md#24-keep-names-that-are-fixed-by-a-signature-you-do-not-own).
- Name development objects by the object naming table (`zcl_zsm_`, `zsm_t_`, `zsm_tt_` …) — [Rule 2.6](../docs/ABAP-Development-Rules.md#26-name-development-objects-by-the-object-naming-table).

> 📝 **Contextual snippet** — assumes the table type `zsm_tt_order`, the data element `zsm_e_order_id` and a `customer_id` in scope.

```abap
" ✅ the name says what the data means
DATA open_orders TYPE zsm_tt_order.
METHODS cancel_order IMPORTING order_id TYPE zsm_e_order_id.
DATA(has_open_orders) = xsdbool( open_orders IS NOT INITIAL ).

" ❌ the prefixes repeat the type; the names do not say what is inside
DATA gt_data TYPE zsm_tt_order.
METHODS cancel IMPORTING iv_id TYPE zsm_e_order_id.
DATA(lv_flag) = xsdbool( gt_data IS NOT INITIAL ).
```

## 🕰️ Reading Classic Prefix Notation

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. Prefixes such as `lv_`, `lt_` and `iv_` are everywhere in existing code, so readers must be able to read them. New code does not use them ([Rule 2.1](../docs/ABAP-Development-Rules.md#21-use-descriptive-snake_case-names-without-type-or-scope-prefixes)); see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-classic-but-still-relevant).

| Prefix | Meaning | Classic example | Clean ABAP name |
|---|---|---|---|
| `lv_` / `gv_` | Local / global variable | `lv_order_count` | `order_count` |
| `ls_` / `gs_` | Local / global structure | `ls_order` | `order` |
| `lt_` / `gt_` | Local / global internal table | `lt_open_orders` | `open_orders` |
| `lr_` | Range table | `lr_order_dates` | `order_dates` |
| `lo_` / `go_` | Local / global object reference | `lo_order_service` | `order_service` |
| `iv_` / `is_` / `it_` | Importing value / structure / table | `iv_order_id` | `order_id` |
| `ev_` / `es_` / `et_` | Exporting value / structure / table | `et_messages` | `messages` |
| `cv_` / `cs_` / `ct_` | Changing value / structure / table | `ct_items` | `items` |
| `rv_` / `rs_` / `rt_` | Returning value / structure / table | `rv_is_valid` | `result` |
| `lc_` / `gc_` | Local / global constant | `lc_status_open` | `status-open` (structured constant, Rule 4.3) |
| `<fs_…>` | Field symbol | `<fs_order>` | `<order>` |

When you change an existing development object that uses prefixes throughout, keep its style, including in new methods. Rename the whole object to Clean ABAP names only when you refactor it as a whole — [Rule 2.5](../docs/ABAP-Development-Rules.md#25-in-legacy-code-keep-naming-consistent-within-a-development-object).

## 🧱 Classes and Methods in Short

- Write new logic in classes; wrap function modules and BAPIs — [Rule 5.1](../docs/ABAP-Development-Rules.md#51-write-new-logic-in-classes-wrap-function-modules-and-bapis).
- Make classes `FINAL` unless they are designed for inheritance — [Rule 5.2](../docs/ABAP-Development-Rules.md#52-make-classes-final-unless-they-are-designed-for-inheritance).
- Prefer instance methods to static methods — [Rule 5.3](../docs/ABAP-Development-Rules.md#53-prefer-instance-methods-to-static-methods).
- Depend on interfaces and receive dependencies through the constructor — [Rule 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor).
- Prefer composition to inheritance — [Rule 5.5](../docs/ABAP-Development-Rules.md#55-prefer-composition-to-inheritance).
- Keep the public section minimal — [Rule 5.6](../docs/ABAP-Development-Rules.md#56-keep-the-public-section-minimal).
- Write small methods that do one thing at one level of abstraction — [Rule 5.7](../docs/ABAP-Development-Rules.md#57-write-small-methods-that-do-one-thing-at-one-level-of-abstraction).
- Keep `IMPORTING` parameters few — [Rule 5.8](../docs/ABAP-Development-Rules.md#58-keep-importing-parameters-few).
- Return one value with `RETURNING`, named `result` — [Rule 5.9](../docs/ABAP-Development-Rules.md#59-return-one-value-with-returning-instead-of-exporting).
- Avoid `CHANGING` parameters — [Rule 5.10](../docs/ABAP-Development-Rules.md#510-avoid-changing-parameters).
- Split a method instead of adding a Boolean switch parameter — [Rule 5.11](../docs/ABAP-Development-Rules.md#511-split-a-method-instead-of-adding-a-boolean-input-parameter-that-switches-its-behaviour).
- Limit constructors to setup — [Rule 5.12](../docs/ABAP-Development-Rules.md#512-limit-constructors-to-setup).

## 🔤 Constants, Enumerations and Booleans

- Replace magic literals with named constants — [Rule 4.1](../docs/ABAP-Development-Rules.md#41-replace-magic-literals-with-named-constants).
- Keep user-facing text in message classes or text symbols — [Rule 4.2](../docs/ABAP-Development-Rules.md#42-keep-user-facing-text-out-of-literals).
- Declare constants in the class that owns the concept, grouped by topic — [Rule 4.3](../docs/ABAP-Development-Rules.md#43-declare-constants-in-the-class-or-interface-that-owns-the-concept-grouped-by-topic).
- Use enumeration types for a closed set of values — [Rule 4.4](../docs/ABAP-Development-Rules.md#44-use-enumeration-types-for-a-closed-set-of-values); give them a base type only when the value is stored — [Rule 4.5](../docs/ABAP-Development-Rules.md#45-give-an-enumeration-a-base-type-and-explicit-values-only-when-the-value-is-stored-or-exchanged).
- Type Booleans as `abap_bool` and compare with `abap_true` / `abap_false` — [Rule 4.6](../docs/ABAP-Development-Rules.md#46-type-booleans-as-abap_bool-and-compare-with-abap_true-and-abap_false).
- Derive a Boolean from a condition with `xsdbool` — [Rule 4.7](../docs/ABAP-Development-Rules.md#47-derive-a-boolean-from-a-condition-with-xsdbool).
- Do not model more than two states with Booleans — [Rule 4.8](../docs/ABAP-Development-Rules.md#48-do-not-model-more-than-two-states-with-booleans).

> ⚠️ **VERSION-DEPENDENT: enumeration types (`BEGIN OF ENUM`).** Not available in older releases; grouped constants are the fallback. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm).

## 🚨 Error Handling in Short

- Use class-based exceptions; classic exceptions only where RFC requires them — [Rule 6.1](../docs/ABAP-Development-Rules.md#61-use-class-based-exceptions-in-new-code).
- Build your own hierarchy below `zcx_zsm_` and choose the category by what the caller can do — [Rules 6.2](../docs/ABAP-Development-Rules.md#62-build-your-own-exception-hierarchy-below-zcx_zsm_) and [6.3](../docs/ABAP-Development-Rules.md#63-choose-the-exception-category-by-what-the-caller-can-do).
- Take exception texts from a message class — [Rules 6.4](../docs/ABAP-Development-Rules.md#64-take-exception-texts-from-a-message-class-through-the-t100-interfaces) and [6.5](../docs/ABAP-Development-Rules.md#65-raise-with-raise-exception-new-use-raise-exception-type--message-to-attach-a-t100-message).
- Catch specific exceptions, never leave a `CATCH` empty, and pass the cause as `previous` — [Rules 6.6](../docs/ABAP-Development-Rules.md#66-catch-specific-exceptions), [6.7](../docs/ABAP-Development-Rules.md#67-never-leave-a-catch-block-empty) and [6.8](../docs/ABAP-Development-Rules.md#68-keep-the-cause-when-converting-an-exception-pass-it-as-previous).
- Turn `sy-subrc` and BAPI return tables into exceptions at the boundary — [Rule 6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary).
- Do not use exceptions for normal control flow — [Rule 6.10](../docs/ABAP-Development-Rules.md#610-do-not-use-exceptions-for-normal-control-flow).
- Send `MESSAGE` statements only from the UI layer — [Rule 6.11](../docs/ABAP-Development-Rules.md#611-use-message-statements-only-in-the-ui-layer).

The statements themselves are explained in [18-Debugging](../18-Debugging/README.md#-exception-handling).

## 💬 Comments, ABAP Doc and Program Headers

- Say it in code first: a good name beats a comment — [Rule 11.1](../docs/ABAP-Development-Rules.md#111-say-it-in-code-first).
- Explain why, not what; comment with `"` before the statement — [Rule 11.2](../docs/ABAP-Development-Rules.md#112-explain-why-not-what-comment-with--before-the-statement).
- Delete code instead of commenting it out — [Rule 11.3](../docs/ABAP-Development-Rules.md#113-delete-code-instead-of-commenting-it-out).
- Document public classes, interfaces and methods with ABAP Doc — [Rule 11.4](../docs/ABAP-Development-Rules.md#114-document-public-classes-interfaces-and-methods-with-abap-doc-including-parameter-and-raising).
- Use pragmas instead of pseudo comments, each with a reason — [Rule 11.5](../docs/ABAP-Development-Rules.md#115-use-pragmas-instead-of-pseudo-comments-each-with-a-reason).
- Mark open work with a ticket reference, not a personal ID — [Rule 11.6](../docs/ABAP-Development-Rules.md#116-mark-open-work-with-a-ticket-reference-not-a-personal-id).

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. Many existing programs start with a boxed `*&` header that records author, date and purpose. Read it, but do not add one to new code: the object's version history already records who changed it and when, and the purpose belongs in a comment or ABAP Doc.

```abap
" ❌ classic header block: personal data in code, history that goes stale
*&---------------------------------------------------------------------*
*& Report     : <program name>
*& Author     : <author>
*& Created on : <date>
*& Purpose    : <one-line purpose>
*&---------------------------------------------------------------------*
```

> 📝 **Contextual snippet** — shows only the opening lines of a report and of a class definition.

```abap
" ✅ report: one sentence on purpose; the logic lives in a class
REPORT zsm_r_order_overview.
" Lists open orders per customer for the sales desk; see zcl_zsm_order_overview.

" ✅ class: ABAP Doc, shown wherever the class is used
"! Builds the open-order overview for one customer.
CLASS zcl_zsm_order_overview DEFINITION PUBLIC FINAL CREATE PUBLIC.
```

## 📐 Formatting

- Write keywords in upper case and identifiers in lower case — [Rule 12.1](../docs/ABAP-Development-Rules.md#121-write-keywords-in-upper-case-and-identifiers-in-lower-case).
- Write no more than one statement per line — [Rule 12.2](../docs/ABAP-Development-Rules.md#122-write-no-more-than-one-statement-per-line).
- Format with the ABAP Formatter and the team's settings before activating — [Rule 12.3](../docs/ABAP-Development-Rules.md#123-format-with-the-abap-formatter-and-the-teams-settings-before-activating).
- Do not chain up-front declarations — [Rule 12.4](../docs/ABAP-Development-Rules.md#124-do-not-chain-up-front-declarations).
- Keep lines within 120 characters — [Rule 12.5](../docs/ABAP-Development-Rules.md#125-keep-lines-within-120-characters).
- Break and align call parameters as Clean ABAP describes — [Rule 12.6](../docs/ABAP-Development-Rules.md#126-break-and-align-parameters-in-calls-as-clean-abap-describes).

## 🔁 Refactoring Legacy Code

Refactoring changes the structure, not the behaviour. A typical candidate is a subroutine that reads data with a `SELECT` inside a loop.

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE`. Subroutines (`FORM` / `PERFORM`) are obsolete; methods replace them ([Rule 3.16](../docs/ABAP-Development-Rules.md#316-do-not-write-statements-the-abap-keyword-documentation-classifies-as-obsolete)). See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference).

> 📝 **Contextual snippet** — assumes the custom tables `zsm_t_order` and `zsm_t_order_item`, the table types `zsm_tt_order` and `zsm_tt_item` (with `order_id`, `item_no` and `quantity`) and the data element `zsm_e_customer_id`.

```abap
" ❌ before: a subroutine, a CHANGING parameter and one SELECT per order
FORM read_items USING    customer_id TYPE zsm_e_customer_id
                CHANGING items       TYPE zsm_tt_item.
  DATA orders TYPE zsm_tt_order.
  SELECT order_id FROM zsm_t_order
    WHERE customer_id = @customer_id
    INTO CORRESPONDING FIELDS OF TABLE @orders.
  LOOP AT orders INTO DATA(order).
    SELECT order_id, item_no, quantity FROM zsm_t_order_item
      WHERE order_id = @order-order_id
      APPENDING CORRESPONDING FIELDS OF TABLE @items.
  ENDLOOP.
ENDFORM.
```

```abap
" ✅ after: a final class, one RETURNING method, one statement for all items
CLASS zcl_zsm_order_item_reader DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Reads all items of the orders of one customer.
    "! @parameter customer_id | Customer whose order items are read
    "! @parameter result      | Items of all orders of the customer
    METHODS read_for_customer
      IMPORTING customer_id   TYPE zsm_e_customer_id
      RETURNING VALUE(result) TYPE zsm_tt_item.
ENDCLASS.

CLASS zcl_zsm_order_item_reader IMPLEMENTATION.
  METHOD read_for_customer.
    " >>> Authorization check for the customer's orders belongs here (Rule 8.2).
    SELECT item~order_id, item~item_no, item~quantity
      FROM zsm_t_order_item AS item
      INNER JOIN zsm_t_order AS header ON header~order_id = item~order_id
      WHERE header~customer_id = @customer_id
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
```

What changed, and why:

- The `SELECT` in the loop became one join — [Rule 7.3](../docs/ABAP-Development-Rules.md#73-do-not-select-inside-a-loop).
- The subroutine became a method of a `FINAL` class — [Rules 5.1](../docs/ABAP-Development-Rules.md#51-write-new-logic-in-classes-wrap-function-modules-and-bapis) and [5.2](../docs/ABAP-Development-Rules.md#52-make-classes-final-unless-they-are-designed-for-inheritance).
- The `CHANGING` table became a `RETURNING` result — [Rules 5.9](../docs/ABAP-Development-Rules.md#59-return-one-value-with-returning-instead-of-exporting) and [5.10](../docs/ABAP-Development-Rules.md#510-avoid-changing-parameters).
- In a real component, the method would also belong to an interface so that callers can be tested with a double — [Rule 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor). It is left out here to keep the example short.

What to leave alone:

- Pin the current behaviour with a test before you change anything; if the code cannot take a dependency yet, a test seam is the bridge — [Rules 10.1](../docs/ABAP-Development-Rules.md#101-write-abap-unit-tests-for-every-new-class) and [10.7](../docs/ABAP-Development-Rules.md#107-use-test-seams-only-for-legacy-code-that-cannot-be-restructured-yet).
- Keep the naming style of an object you only partly change — [Rule 2.5](../docs/ABAP-Development-Rules.md#25-in-legacy-code-keep-naming-consistent-within-a-development-object).
- Format only the lines you changed, or format the whole object in a separate transport — [Rule 12.3](../docs/ABAP-Development-Rules.md#123-format-with-the-abap-formatter-and-the-teams-settings-before-activating).
- Leave callers and unrelated code untouched; one refactoring per change.

## 🧪 Testability and Quality Gates

- Receive dependencies through the constructor so that tests can pass doubles — [Rules 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor) and [10.6](../docs/ABAP-Development-Rules.md#106-replace-dependencies-with-test-doubles-through-interfaces-and-cl_abap_testdouble).
- Write ABAP Unit tests for every new class, in local test classes with `RISK LEVEL HARMLESS` and `DURATION SHORT` — [Rules 10.1](../docs/ABAP-Development-Rules.md#101-write-abap-unit-tests-for-every-new-class) and [10.2](../docs/ABAP-Development-Rules.md#102-put-unit-tests-in-local-test-classes-with-risk-level-harmless-and-duration-short).
- Test one behaviour per method, named after that behaviour, in given-when-then form — [Rules 10.3](../docs/ABAP-Development-Rules.md#103-test-one-behaviour-per-test-method)–[10.5](../docs/ABAP-Development-Rules.md#105-structure-each-test-as-given-when-then).
- Isolate database access with the ABAP SQL and CDS test environments — [Rule 10.8](../docs/ABAP-Development-Rules.md#108-isolate-database-access-with-the-abap-sql-and-cds-test-double-frameworks-never-use-real-data).
- Release nothing that fails the syntax check, ABAP Unit or ATC; fix or exempt every finding with a reason — [Rules 13.1](../docs/ABAP-Development-Rules.md#131-release-nothing-that-fails-the-syntax-check-abap-unit-or-atc-with-the-team-check-variant) and [13.2](../docs/ABAP-Development-Rules.md#132-fix-every-atc-finding-or-exempt-it-with-a-written-reason).
- Call code cloud-ready or checked only after the check ran — [Rules 1.5](../docs/ABAP-Development-Rules.md#15-never-call-code-cloud-ready-unless-it-was-checked) and [13.5](../docs/ABAP-Development-Rules.md#135-claim-a-check-in-the-guides-only-after-it-ran-and-record-it).

## 🧭 Scope Note

- This chapter summarises; the reasoning, the examples and the Clean ABAP deviations are in the [rules document](../docs/ABAP-Development-Rules.md).
- A dedicated ABAP Unit chapter is planned. Until it exists, [section 10 of the rules](../docs/ABAP-Development-Rules.md#10-testing) is the reference.
- RAP, CDS beyond ABAP SQL reads, AMDP and ABAP Cloud are outside this guide — see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-scope-boundary).

## ✅ Best Practices

The review checklist. Each item names the rule it comes from and the chapter that explains the technique.

**Correctness & data access**
- [ ] No magic literals for business-relevant values — [Rule 4.1](../docs/ABAP-Development-Rules.md#41-replace-magic-literals-with-named-constants).
- [ ] Only the needed fields are read, no `SELECT *` — [Rule 7.7](../docs/ABAP-Development-Rules.md#77-list-the-fields-you-need-instead-of-select-), [08-Open-SQL](../08-Open-SQL/README.md).
- [ ] `SELECT SINGLE` uses the full key, except for existence checks with `@abap_true` — [Rules 7.5](../docs/ABAP-Development-Rules.md#75-use-select-single-only-with-the-full-primary-key) and [7.6](../docs/ABAP-Development-Rules.md#76-check-existence-with-select-single-abap_true), [08-Open-SQL](../08-Open-SQL/README.md).
- [ ] No `SELECT` inside a loop — [Rule 7.3](../docs/ABAP-Development-Rules.md#73-do-not-select-inside-a-loop), [08-Open-SQL](../08-Open-SQL/README.md).
- [ ] `FOR ALL ENTRIES` drivers are non-empty and de-duplicated — [Rule 7.4](../docs/ABAP-Development-Rules.md#74-use-for-all-entries-only-with-a-non-empty-de-duplicated-driver-table), [08-Open-SQL](../08-Open-SQL/README.md#-for-all-entries-in).
- [ ] Restrictions on the optional side of an outer join are in the `ON` condition — [Rule 7.13](../docs/ABAP-Development-Rules.md#713-restrict-the-optional-side-of-an-outer-join-in-the-on-condition-not-in-where), [08-Open-SQL](../08-Open-SQL/README.md).
- [ ] No explicit client handling — [Rule 7.8](../docs/ABAP-Development-Rules.md#78-let-abap-sql-handle-the-client), [08-Open-SQL](../08-Open-SQL/README.md).
- [ ] Table expressions handle a miss — [Rule 3.13](../docs/ABAP-Development-Rules.md#313-read-with-a-table-expression-only-when-a-miss-is-handled), [07-Internal-Tables](../07-Internal-Tables/README.md).
- [ ] References and field symbols that can be empty are checked with `IS BOUND` / `IS ASSIGNED` — [Rule 3.18](../docs/ABAP-Development-Rules.md#318-check-references-with-is-bound-and-field-symbols-with-is-assigned-where-they-can-be-empty), [07-Internal-Tables](../07-Internal-Tables/README.md#-field-symbols--data-references).

**Transactions & locking**
- [ ] Only the top-level caller commits; reusable units never do — [Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work), [08-Open-SQL](../08-Open-SQL/README.md#-sap-luw--transaction-ownership).
- [ ] `COMMIT WORK AND WAIT` only where the next step depends on the update, with `sy-subrc` checked — [Rule 7.14](../docs/ABAP-Development-Rules.md#714-use-commit-work-and-wait-only-when-the-next-step-depends-on-the-update), [08-Open-SQL](../08-Open-SQL/README.md#-sap-luw--transaction-ownership).
- [ ] BAPI return tables are checked before `BAPI_TRANSACTION_COMMIT` — [Rules 6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary) and [7.11](../docs/ABAP-Development-Rules.md#711-close-bapi-calls-with-bapi_transaction_commit-or-bapi_transaction_rollback), [15-BAPIs](../15-BAPIs/README.md).
- [ ] No direct DML on SAP standard tables — [Rule 7.9](../docs/ABAP-Development-Rules.md#79-write-only-to-your-own-tables-change-sap-standard-data-through-bapis-or-released-apis), [15-BAPIs](../15-BAPIs/README.md).
- [ ] Mass `UPDATE` / `DELETE` carry a `WHERE` condition and check `sy-dbcnt` — [Rule 7.15](../docs/ABAP-Development-Rules.md#715-qualify-mass-update-and-delete-with-where-and-check-sy-dbcnt), [08-Open-SQL](../08-Open-SQL/README.md).
- [ ] Concurrent changes are protected with enqueue locks — [Rule 7.12](../docs/ABAP-Development-Rules.md#712-protect-business-transactions-with-enqueue-locks), [08-Open-SQL](../08-Open-SQL/README.md#-sap-luw--transaction-ownership).

**Security**
- [ ] Business data access is authorization-checked and `sy-subrc` is evaluated — [Rule 8.1](../docs/ABAP-Development-Rules.md#81-check-authorization-wherever-business-data-is-read-or-changed-and-evaluate-sy-subrc), [11-Classical-Reports](../11-Classical-Reports/README.md).
- [ ] Examples mark where a check belongs instead of inventing an authorization object — [Rule 8.2](../docs/ABAP-Development-Rules.md#82-in-guide-examples-mark-where-the-check-belongs-never-invent-an-authorization-object).
- [ ] `WITH PRIVILEGED ACCESS` carries a written justification — [Rule 8.3](../docs/ABAP-Development-Rules.md#83-use-with-privileged-access-only-with-a-written-justification).
- [ ] Dynamic tokens are built only from validated input — [Rule 8.4](../docs/ABAP-Development-Rules.md#84-build-dynamic-sql-and-other-dynamic-tokens-only-from-validated-input), [08-Open-SQL](../08-Open-SQL/README.md).
- [ ] No credentials, hosts or destinations in code — [Rule 8.5](../docs/ABAP-Development-Rules.md#85-never-hard-code-credentials-hosts-or-destinations).
- [ ] `CALL TRANSACTION` uses `WITH AUTHORITY-CHECK`, or `WITHOUT` with a comment — [Rule 8.9](../docs/ABAP-Development-Rules.md#89-call-transactions-with-authority-check), [14-Function-Modules](../14-Function-Modules/README.md).
- [ ] RFC entry points check business authorizations themselves — [Rule 8.10](../docs/ABAP-Development-Rules.md#810-check-business-authorizations-at-every-rfc-entry-point), [14-Function-Modules](../14-Function-Modules/README.md).
- [ ] Logs contain no secrets and no unneeded personal data — [Rule 8.8](../docs/ABAP-Development-Rules.md#88-log-no-secrets-and-no-personal-data-beyond-what-the-purpose-needs).

**Structure & error handling**
- [ ] Classes are `FINAL` and methods small and single-purpose — [Rules 5.2](../docs/ABAP-Development-Rules.md#52-make-classes-final-unless-they-are-designed-for-inheritance) and [5.7](../docs/ABAP-Development-Rules.md#57-write-small-methods-that-do-one-thing-at-one-level-of-abstraction), [10-Objects](../10-Objects/README.md).
- [ ] Dependencies come in through the constructor as interfaces — [Rule 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor), [10-Objects](../10-Objects/README.md).
- [ ] Exceptions are caught specifically; `cx_root` only at a boundary that logs or re-raises — [Rule 6.6](../docs/ABAP-Development-Rules.md#66-catch-specific-exceptions), [18-Debugging](../18-Debugging/README.md#-exception-handling).
- [ ] No empty `CATCH`, and converted exceptions keep their cause — [Rules 6.7](../docs/ABAP-Development-Rules.md#67-never-leave-a-catch-block-empty) and [6.8](../docs/ABAP-Development-Rules.md#68-keep-the-cause-when-converting-an-exception-pass-it-as-previous), [18-Debugging](../18-Debugging/README.md#-exception-handling).
- [ ] `ASSERT` guards only internal assumptions; anything a caller or user can act on raises an exception — [Rule 6.12](../docs/ABAP-Development-Rules.md#612-state-the-internal-assumptions-of-a-program-with-assert-raise-exceptions-for-situations-a-caller-or-user-can-act-on), [23-Debugging-Troubleshooting](../23-Debugging-Troubleshooting/README.md).
- [ ] `MESSAGE` statements appear only in the UI layer — [Rule 6.11](../docs/ABAP-Development-Rules.md#611-use-message-statements-only-in-the-ui-layer), [18-Debugging](../18-Debugging/README.md).
- [ ] `CHECK` only as an input check at the start of a method; loops use `IF` with `CONTINUE` — [Rule 3.17](../docs/ABAP-Development-Rules.md#317-use-check-only-as-an-input-check-at-the-start-of-a-method-prefer-if--return), [05-Control-Statements](../05-Control-Statements/README.md).
- [ ] No new macros — [Rule 3.19](../docs/ABAP-Development-Rules.md#319-do-not-write-macros-use-methods-or-expressions), [09-Modularization](../09-Modularization/README.md).
- [ ] No statements classified as obsolete — [Rule 3.16](../docs/ABAP-Development-Rules.md#316-do-not-write-statements-the-abap-keyword-documentation-classifies-as-obsolete), [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).
- [ ] Comments explain why, not what — [Rule 11.2](../docs/ABAP-Development-Rules.md#112-explain-why-not-what-comment-with--before-the-statement).

**Quality**
- [ ] New classes have ABAP Unit tests — [Rule 10.1](../docs/ABAP-Development-Rules.md#101-write-abap-unit-tests-for-every-new-class).
- [ ] No always-active breakpoint (`BREAK-POINT` without `ID`, `BREAK` with a user name) and no `LOG-POINT` in released code — [Rule 13.6](../docs/ABAP-Development-Rules.md#136-release-no-always-active-breakpoint-no-break-point-without-id-and-no-break-user-macro).
- [ ] Syntax check, ABAP Unit and ATC passed; every finding is fixed or exempted with a reason — [Rules 13.1](../docs/ABAP-Development-Rules.md#131-release-nothing-that-fails-the-syntax-check-abap-unit-or-atc-with-the-team-check-variant) and [13.2](../docs/ABAP-Development-Rules.md#132-fix-every-atc-finding-or-exempt-it-with-a-written-reason).
- [ ] AI-generated code was reviewed against the checklist for generated ABAP — [Rule 15.2](../docs/ABAP-Development-Rules.md#152-review-generated-abap-against-this-checklist-before-accepting-it).

## ⚠️ Common Mistakes

- Using prefixes in a new development object because the surrounding code has them. The legacy exception covers only existing objects — [Rules 2.1](../docs/ABAP-Development-Rules.md#21-use-descriptive-snake_case-names-without-type-or-scope-prefixes) and [2.5](../docs/ABAP-Development-Rules.md#25-in-legacy-code-keep-naming-consistent-within-a-development-object).
- Mixing prefixed and Clean ABAP names inside one development object — [Rule 2.5](../docs/ABAP-Development-Rules.md#25-in-legacy-code-keep-naming-consistent-within-a-development-object).
- Leaving a `CATCH` empty "for now" — [Rule 6.7](../docs/ABAP-Development-Rules.md#67-never-leave-a-catch-block-empty).
- Putting `COMMIT WORK` into a reusable method because the first caller needed it — [Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work).
- Filtering the optional side of an outer join in `WHERE`, which silently turns it into an inner join — [Rule 7.13](../docs/ABAP-Development-Rules.md#713-restrict-the-optional-side-of-an-outer-join-in-the-on-condition-not-in-where).
- Calling code "ATC-checked" or "cloud-ready" without a recorded run — [Rules 1.5](../docs/ABAP-Development-Rules.md#15-never-call-code-cloud-ready-unless-it-was-checked) and [13.5](../docs/ABAP-Development-Rules.md#135-claim-a-check-in-the-guides-only-after-it-ran-and-record-it).
- Writing author names, initials or user IDs into program headers and `TODO` comments — [Rule 11.6](../docs/ABAP-Development-Rules.md#116-mark-open-work-with-a-ticket-reference-not-a-personal-id).
- Copying a rule's text into a chapter instead of linking it; the two copies drift apart — [Rule 0.4](../docs/ABAP-Development-Rules.md#04-cite-rules-by-number).

## 🎤 Interview & Review Checkpoints

- Be ready to discuss the **Clean ABAP** style guide and name a few core rules — including where it disagrees with classic enterprise convention.
- Explain why new code uses Clean ABAP names without prefixes, and why a change inside an existing prefixed object keeps that object's style.
- Explain who owns the transaction boundary in a layered application, and what goes wrong when a reusable unit commits.
- Be prepared to walk through refactoring a messy snippet (a long procedural `FORM` with a `SELECT` in a loop) into clean, modern ABAP — and to say which parts you would deliberately leave alone.

## 🔗 Related Chapters

- [05-Control-Statements](../05-Control-Statements/README.md) — `COND`, `SWITCH` and `CHECK` in context
- [07-Internal-Tables](../07-Internal-Tables/README.md) — table keys, table expressions and field symbols
- [08-Open-SQL](../08-Open-SQL/README.md) — ABAP SQL, the SAP LUW and transaction ownership
- [09-Modularization](../09-Modularization/README.md) — methods instead of subroutines and macros
- [10-Objects](../10-Objects/README.md) — classes, interfaces and `FINAL`
- [15-BAPIs](../15-BAPIs/README.md) — evaluating BAPI return tables and committing
- [18-Debugging](../18-Debugging/README.md) — messages and exception handling
- [19-Performance](../19-Performance/README.md) — measuring before optimising
- [23-Debugging-Troubleshooting](../23-Debugging-Troubleshooting/README.md) — assertions, checkpoints and reading short dumps
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — the lifecycle labels used in this chapter and the scope boundary
- [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) — the authority for syntax and release availability
