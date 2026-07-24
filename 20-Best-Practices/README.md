# 20 — Best Practices & Clean ABAP

## 📖 Introduction

This closing chapter distills recurring best practices, naming conventions, and clean-code guidance referenced throughout the previous 19 chapters — a quick checklist to review before submitting code for review/transport.

## 🏷️ Naming Conventions (Common Convention Used in This Guide)

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

## ✅ Clean ABAP Checklist

- [ ] No hardcoded literals for business-relevant values — use constants or Customizing tables.
- [ ] `SELECT` statements avoid `SELECT *`; only needed fields are read.
- [ ] No `SELECT` inside a `LOOP`.
- [ ] `FOR ALL ENTRIES` driver tables are checked for `IS NOT INITIAL` and de-duplicated.
- [ ] Methods/forms have a single, clear responsibility (avoid "god methods").
- [ ] Exceptions are handled with `TRY`/`CATCH`, ending with a `cx_root` catch-all.
- [ ] BAPI/return tables are fully checked (`E`, `A`, `X`) before commit.
- [ ] Field symbols/data references are checked with `IS ASSIGNED`/`IS BOUND` before use.
- [ ] No macros for logic beyond trivial repetition — prefer methods.
- [ ] Comments explain **why**, not just **what** (the code already shows "what").

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
| Avoid `SELECT *`/`SELECT` in loops | [08-Open-SQL](../08-Open-SQL/README.md) |
| Prefer classes over `FORM`/macros | [09-Modularization](../09-Modularization/README.md) |
| Check `BAPIRET2` fully before commit | [15-BAPIs](../15-BAPIs/README.md) |
| Catch `cx_root` last | [18-Debugging](../18-Debugging/README.md) |
| Profile before optimizing | [19-Performance](../19-Performance/README.md) |

## 🎤 Interview Tips

- Be ready to discuss the **Clean ABAP** style guide (SAP's official open-source guidelines) and name a few core rules.
- Explain why naming conventions (`lv_`, `ls_`, `lt_`, etc.) matter for readability and code reviews, even though the compiler doesn't require them.
- Be prepared to walk through refactoring a "messy" snippet (long procedural `FORM` with `SELECT` in a loop) into clean, modern ABAP.

## 📚 Further Reading

- [SAP's Clean ABAP style guide (GitHub)](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md)
- [ABAP Programming Guidelines (SAP Help Portal)](https://help.sap.com/)

## 🔗 Related Chapters

This chapter ties together guidance from every previous chapter — when in doubt, revisit:
- [07-Internal-Tables](../07-Internal-Tables/README.md)
- [08-Open-SQL](../08-Open-SQL/README.md)
- [19-Performance](../19-Performance/README.md)
