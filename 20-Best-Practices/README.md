# 20 — Best Practices & Clean ABAP

## 📖 Introduction

This closing chapter distills recurring best practices, naming conventions, and clean-code guidance referenced throughout the previous 19 chapters — a quick checklist to review before submitting code for review/transport.

## 🏷️ Naming Conventions (Classic Enterprise ABAP)

> 📝 **On prefixes.** This guide uses the classic prefix notation (`lv_`, `lt_`, `ls_`, `lo_`, …) because it is near-universal in existing SAP code and you need to read it fluently. Modern style guides — including SAP's own Clean ABAP — recommend *against* encoding the type in the name, preferring semantic names such as `order_items` over `lt_order_items`. Both positions are defensible; what matters is that a codebase is consistent. Know the convention your team uses, and know that these two schools exist.

| Prefix | Meaning | Example |
|---|---|---|
| `lv_` | Local variable | `lv_count` |
| `gv_` | Global variable | `gv_flag` |
| `ls_` | Local structure | `ls_data` |
| `gs_` | Global structure | `gs_layout` |
| `lt_` / `gt_` | Local/global internal table | `lt_mara` |
| `lr_` | Range table | `lr_matnr` |
| `lo_` / `go_` | Local/global object reference | `lo_alv` |
| `is_` / `it_` / `iv_` | Importing structure/table/value parameter | `iv_matnr` |
| `es_` / `et_` / `ev_` | Exporting structure/table/value parameter | `et_return` |
| `cs_` / `ct_` / `cv_` | Changing structure/table/value parameter | `ct_data` |
| `rs_` / `rt_` / `rv_` | Returning structure/table/value | `rv_result` |
| `lc_` / `gc_` | Constant | `lc_number` |
| `<fs_...>` | Field symbol | `<fs_data>` |

## ✅ Code Review Checklist

**Correctness & data access**
- [ ] No hardcoded literals for business-relevant values — use constants or Customizing tables.
- [ ] `SELECT` statements avoid `SELECT *`; only needed fields are read.
- [ ] `SELECT SINGLE` is qualified by the full key.
- [ ] No `SELECT` inside a `LOOP`.
- [ ] `FOR ALL ENTRIES` driver tables are checked for `IS NOT INITIAL` and de-duplicated; the implicit `DISTINCT` has been considered.
- [ ] Restrictions on the optional side of an outer join are in the `ON` clause, not `WHERE`.
- [ ] No explicit client (`mandt`) predicates.

**Transactions & safety**
- [ ] The transaction boundary is owned by the top-level caller; reusable units do not commit.
- [ ] `AND WAIT` is used only where synchronous completion is genuinely required.
- [ ] BAPI return tables are fully checked (`E`, `A`, `X`) before `BAPI_TRANSACTION_COMMIT`.
- [ ] No direct DML against SAP standard application tables.
- [ ] Mass `UPDATE`/`DELETE` statements are key-qualified; `sy-dbcnt` is checked.
- [ ] Locking is considered wherever concurrent changes are possible.

**Security**
- [ ] Dynamic table/field names come from validated sources.
- [ ] Generic table access is authorization-checked, not just existence-checked.
- [ ] `CALL TRANSACTION` states its authorization intent explicitly.
- [ ] RFC entry points authorization-check the caller.

**Structure & error handling**
- [ ] Methods have a single, clear responsibility (no "god methods").
- [ ] Exceptions are caught **specifically**, ordered most-specific first; any `cx_root` catch is at a boundary and logs or re-raises.
- [ ] `CHECK` is not used where `IF` is meant.
- [ ] Field symbols and references are checked with `IS ASSIGNED`/`IS BOUND`, and `sy-subrc` is checked after `ASSIGN`.
- [ ] Table expressions are guarded (`line_exists`, `OPTIONAL`, `TRY`, or `ASSIGN`).
- [ ] No macros for logic beyond trivial repetition — prefer methods.
- [ ] Comments explain **why**, not **what** (the code already shows "what").
- [ ] Classic technologies used deliberately, not by habit — see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 🧹 General Code Style

- Prefer **modern ABAP** (`VALUE`, `COND`, `SWITCH`, `REDUCE`, `FOR`, inline `DATA(...)`) over classical statements (`MOVE`, `CONCATENATE`, `APPEND ... TO` in a loop) when it improves readability — but understand classical syntax too, since most production systems still contain plenty of it.
- Keep global state to a minimum; prefer method parameters and class attributes over global `DATA` declarations.
- Structure programs with a clear separation of concerns: **selection screen** → **data retrieval** → **business logic/transformation** → **presentation** (ALV/output).
- Favor small, named, single-purpose methods over long procedural blocks — improves testability and readability.

## 🎯 Where to Apply Each Guideline (Cross-References)

| Guideline | See Chapter |
|---|---|
| Use `COND`/`SWITCH` for value assignment | [05-Control-Statements](../05-Control-Statements/README.md) |
| Add secondary keys to large internal tables | [07-Internal-Tables](../07-Internal-Tables/README.md) |
| Guard table expressions correctly | [07-Internal-Tables](../07-Internal-Tables/README.md) |
| Avoid `SELECT *` / `SELECT` in loops | [08-Open-SQL](../08-Open-SQL/README.md) |
| Let the transaction owner commit | [08-Open-SQL](../08-Open-SQL/README.md#-sap-luw--transaction-ownership) |
| Authorization-check generic table access | [11-Classical-Reports](../11-Classical-Reports/README.md) |
| Prefer classes over `FORM`/macros | [09-Modularization](../09-Modularization/README.md) |
| Check `BAPIRET2` fully before commit | [15-BAPIs](../15-BAPIs/README.md) |
| Order `CATCH` clauses most-specific first | [18-Debugging](../18-Debugging/README.md) |
| Profile before optimizing | [19-Performance](../19-Performance/README.md) |
| Decide classic vs. modern deliberately | [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) |

## 🎤 Interview & Review Checkpoints

- Be ready to discuss the **Clean ABAP** style guide and name a few core rules — including where it disagrees with classic enterprise convention.
- Explain the trade-off between prefix notation and semantic naming, and why consistency within a codebase matters more than which one you pick.
- Explain who owns the transaction boundary in a layered application, and what goes wrong when a reusable unit commits.
- Be prepared to walk through refactoring a messy snippet (a long procedural `FORM` with a `SELECT` in a loop) into clean, modern ABAP — and to say which parts you would deliberately leave alone.

## 📚 Further Reading

- [SAP's Clean ABAP style guide (GitHub)](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md)
- [ABAP Keyword Documentation (SAP Help Portal)](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) — the authoritative reference for syntax and release availability

## 🔗 Related Chapters

This chapter ties together guidance from every previous chapter — when in doubt, revisit:
- [07-Internal-Tables](../07-Internal-Tables/README.md)
- [08-Open-SQL](../08-Open-SQL/README.md)
- [19-Performance](../19-Performance/README.md)
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md)
