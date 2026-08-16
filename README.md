# ABAPGuide — A Practical SAP ABAP Engineering Reference

A working reference for SAP ABAP as it is actually written in productive landscapes — from classic procedural and dynpro code through ABAP Objects to modern expression syntax and ABAP SQL. Built from accumulated real SAP project notes, patterns and examples, and organised so that each technology carries an explicit **lifecycle status**: what is current, what is classic but still live, and what is there for historical reference.

That last part is the point. Real SAP systems run several generations of ABAP at once. A reference that shows only the newest syntax is no help when you open a twelve-year-old pricing routine; one that shows everything without saying which is which is no help either.

### Scope

- **Covers:** ABAP language fundamentals, internal tables, ABAP SQL, modularization, ABAP Objects, classical reports, selection screens and dynpro, three generations of ALV, BAPIs, BAdIs and the enhancement framework, messages and exceptions, and performance — including the modern (7.40-generation) expression syntax throughout.
- **Does not cover:** RAP, CDS, AMDP, ABAP Unit, or ABAP Cloud beyond the boundary explained in [Chapter 21](21-Classic-vs-Modern-ABAP/README.md). That is a deliberate boundary, not an oversight.
- **Examples are illustrative.** They are written to teach a pattern, not to be dropped into production unchanged. See [How to Use](#-how-to-use).
- **Not official SAP documentation.** For anything version-sensitive, the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) is the authority.

## ✨ Highlights

- **21 structured chapters** plus a quick-reference Examples section
- **100+ annotated ABAP examples** drawn from real project work
- **Explicit classic-to-modern lifecycle guidance** on every major technology
- **Internal tables and modern expressions** — `VALUE`, `FOR`, `REDUCE`, `FILTER`, `COND`, table expressions, secondary keys
- **ABAP SQL in depth** — joins, subqueries, aggregation, `FOR ALL ENTRIES` and its pitfalls, dynamic SQL
- **Three ALV generations side by side** — `CL_SALV_TABLE`, `REUSE_ALV_*`, `CL_GUI_ALV_GRID`
- **Integration and extensibility** — BAPIs, BAdIs, enhancements, BDC, RFC, with the transaction and authorization implications spelled out

## 🧭 Classic vs Modern ABAP

**→ [Chapter 21 — Classic vs Modern ABAP](21-Classic-vs-Modern-ABAP/README.md)**

The chapter that ties the rest together: why productive landscapes contain several ABAP generations, what to use for new on-premise development, what remains classic but relevant, what is historical reference, and what changes under ABAP Cloud. Includes a decision table for the common maintenance and greenfield scenarios.

## 🔍 Find It Fast

| I need to… | Chapters |
|---|---|
| Get the language fundamentals right | [01](01-ABAP-Basics/README.md) · [02](02-Data-Types/README.md) · [03](03-Variables/README.md) · [04](04-Operators/README.md) · [05](05-Control-Statements/README.md) |
| Work with internal tables and modern expressions | [06](06-Loops/README.md) · [07](07-Internal-Tables/README.md) |
| Read or write database data safely | [08](08-Open-SQL/README.md) · [15](15-BAPIs/README.md) |
| Structure and reuse code | [09](09-Modularization/README.md) · [10](10-Objects/README.md) |
| Build a report or a screen | [11](11-Classical-Reports/README.md) · [12](12-Selection-Screens/README.md) · [13](13-ALV/README.md) |
| Integrate or extend standard SAP | [14](14-Function-Modules/README.md) · [15](15-BAPIs/README.md) · [16](16-BADIs/README.md) · [17](17-Enhancements/README.md) |
| Handle errors, log, and tune | [18](18-Debugging/README.md) · [19](19-Performance/README.md) |
| Review code against a checklist | [20](20-Best-Practices/README.md) |
| Decide between classic and modern | [21](21-Classic-vs-Modern-ABAP/README.md) |

## 🏷️ Lifecycle Legend

Chapters and examples are labelled with one of these. Full definitions in [Chapter 21](21-Classic-vs-Modern-ABAP/README.md#-the-five-categories-used-in-this-guide).

| Label | Meaning |
|---|---|
| **CURRENT / RECOMMENDED** | Reach for this in new on-premise development |
| **CLASSIC BUT STILL RELEVANT** | Widespread and supported; you must be able to maintain it |
| **LEGACY / HISTORICAL REFERENCE** | Superseded — read it, don't write it |
| **ABAP CLOUD / MODERN CONTEXT** | Belongs to, or explains, the ABAP Cloud development model |
| **VERSION-DEPENDENT** | Availability depends on your release — verify before relying on it |

## 📂 Chapter Reference

| Folder | Topic | Description | Context |
|---|---|---|---|
| [01-ABAP-Basics](01-ABAP-Basics/README.md) | ABAP Basics | Program structure, report events, syntax fundamentals | Current |
| [02-Data-Types](02-Data-Types/README.md) | Data Types | Elementary types, structures, type conversions | Current |
| [03-Variables](03-Variables/README.md) | Variables | `DATA`, `CONSTANTS`, inline declarations, `FORM`/`PERFORM` | Current + legacy |
| [04-Operators](04-Operators/README.md) | Operators | Arithmetic, comparison, built-in math functions | Current |
| [05-Control-Statements](05-Control-Statements/README.md) | Control Statements | `IF`, `CASE`, `CHECK`, `COND`, `SWITCH` | Current |
| [06-Loops](06-Loops/README.md) | Loops | `LOOP`, `DO`, `WHILE`, control breaks, `GROUP BY`, `COLLECT`, ranges | Current + classic |
| [07-Internal-Tables](07-Internal-Tables/README.md) | Internal Tables | Table types, keys, `VALUE`/`FOR`/`REDUCE`/`FILTER`, field symbols | Current |
| [08-Open-SQL](08-Open-SQL/README.md) | ABAP SQL | `SELECT`, joins, aggregation, CRUD, **SAP LUW & transaction ownership** | Current + version-dependent |
| [09-Modularization](09-Modularization/README.md) | Modularization | Function modules, conversion exits, RFC, macros, `SUBMIT` | Classic + legacy |
| [10-Objects](10-Objects/README.md) | Objects / OOP | Classes, visibility, inheritance, static vs. instance | Current |
| [11-Classical-Reports](11-Classical-Reports/README.md) | Classical Reports | List events, `WRITE`, dynamic tables + authorization | Classic |
| [12-Selection-Screens](12-Selection-Screens/README.md) | Selection Screens & Dynpro | Selection screens, PBO/PAI, screen modification, popups | Classic |
| [13-ALV](13-ALV/README.md) | ALV | `CL_SALV_TABLE`, `REUSE_ALV_*`, `CL_GUI_ALV_GRID`, field catalogs, events | Current + classic |
| [14-Function-Modules](14-Function-Modules/README.md) | BDC / Batch Input | `CALL TRANSACTION`, BDC tables, message handling, authorization | Classic |
| [15-BAPIs](15-BAPIs/README.md) | BAPIs | `BAPIRET2`, transaction control, standard call pattern | Classic, still relevant |
| [16-BADIs](16-BADIs/README.md) | BAdIs | Classic vs. new BAdIs, filters, implementation pattern | Current + classic |
| [17-Enhancements](17-Enhancements/README.md) | Enhancements | User exits vs. customer exits, enhancement points, modifications | Classic + legacy |
| [18-Debugging](18-Debugging/README.md) | Messages & Exceptions | `MESSAGE`, exception handling, application log | Current |
| [19-Performance](19-Performance/README.md) | Performance & Memory | Internal table tuning, ABAP Memory, database access | Current |
| [20-Best-Practices](20-Best-Practices/README.md) | Best Practices | Naming conventions, code review checklist | Current |
| [21-Classic-vs-Modern-ABAP](21-Classic-vs-Modern-ABAP/README.md) | **Classic vs Modern** | **Lifecycle map, ABAP Cloud boundary, decision table** | **Start here for context** |
| [Examples](Examples/README.md) | Examples | Strings, dates/times, conversions | Current + legacy |

## 🚀 How to Use

1. Jump to the chapter matching your need via [Find It Fast](#-find-it-fast), or read [Chapter 21](21-Classic-vs-Modern-ABAP/README.md) first for the lifecycle map.
2. Each chapter follows the same shape: introduction → examples → best practices → common mistakes → interview & review checkpoints → related transaction codes.
3. **Understand what kind of snippet you are reading:**
   - **Complete examples** — self-contained programs or classes (for instance the ALV reports in [Chapter 13](13-ALV/README.md)). These show a full working structure.
   - **Contextual snippets** — the majority. They demonstrate one statement or pattern and assume surrounding declarations. Adapt the names and types to your own program.
4. **Examples are illustrative, not production-ready as-is.** They are simplified to make the pattern visible: error handling, authorization checks and locking are shown where they are the point being made, and abbreviated where they are not. Review any snippet against your own standards before using it, and syntax-check it in your target system.

## ⚙️ Compatibility & Version Notes

- This guide uses the **modern expression syntax introduced across the ABAP 7.40 generation** — inline declarations, `VALUE`, `NEW`, `CONV`, `CORRESPONDING`, `COND`, `SWITCH`, `REDUCE`, `FILTER`, `FOR`, table expressions and string templates.
- **Individual ABAP SQL features require later releases.** SQL expressions in the field list, host expressions, and internal tables as data sources all arrived progressively across the 7.4x/7.5x releases, not all at once. These are flagged **VERSION-DEPENDENT** where they appear.
- **This guide deliberately states no exact minimum release or support-package numbers.** Verify each feature against the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) for your target system before relying on it.
- **Terminology:** SAP's current umbrella term for the SQL statements is **ABAP SQL**; "Open SQL" is the historical name and is still in wide use. Both appear here. The chapter folder keeps its `08-Open-SQL` name so existing links continue to work.
- **Tooling:** ABAP Development Tools (ADT) for Eclipse is recommended; the classic workbench (SE38/SE80/SE24/SE37) is assumed knowledge where transaction codes are referenced.

## 👥 Who This Is For

- **SAP developers maintaining productive ABAP** who need a working example fast, with the context to know whether the pattern is still the right one.
- **Engineers modernizing classic ABAP** who need to tell deliberate legacy from accidental legacy before they change anything.
- **Developers working across SAP GUI and modern ABAP syntax**, where both generations sit in the same program.
- **Technical leads reviewing implementation patterns** — the per-chapter review checkpoints and the [Chapter 20 checklist](20-Best-Practices/README.md) are written for that use.

Newcomers to ABAP will find the chapters readable in order, but the reference is written for people who already program.

## 🤝 Contributing

Corrections and additions are welcome — particularly anything that fixes a technical inaccuracy or clarifies a lifecycle classification.

1. Fork the repository and create a branch (`git checkout -b improvement/topic-name`).
2. Keep the existing chapter structure and lifecycle labelling.
3. For anything version-sensitive, cite the ABAP Keyword Documentation rather than asserting a release number.
4. Open a pull request describing the change.

## 📄 License

Licensed under the [MIT License](LICENSE) — free to use for learning, teaching and reference.

## 👤 Author

**Serhat Mercan** — SAP Technical Lead · Enterprise SAP Engineering · ABAP / ABAP Cloud · SAP BTP

- GitHub: [github.com/serhatmercan](https://github.com/serhatmercan)
- LinkedIn: [linkedin.com/in/serhat-mercan](https://www.linkedin.com/in/serhat-mercan/)
