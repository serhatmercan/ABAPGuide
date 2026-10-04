# 21 — Classic vs Modern ABAP

> **Lifecycle:** `CURRENT / RECOMMENDED`. This chapter is the lifecycle map of the guide: every lifecycle label in the other chapters points here, and every classification below is checked against the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) and the [ABAP Development Rules](../docs/ABAP-Development-Rules.md).

## 📖 Introduction

A productive SAP landscape is not written in one dialect. Open almost any system that has been live for more than a few years and you will find, side by side and all of it running:

- procedural ABAP — `FORM`/`PERFORM`, macros, header-line tables;
- function modules and BAPIs, some RFC-enabled, most not;
- dynpro screens, classical `WRITE` lists, and two or three generations of ALV;
- classic extensibility — user exits, customer exits, BAdIs, enhancement points;
- ABAP Objects;
- modern expression syntax and modern ABAP SQL;
- and, increasingly, code written under the constraints of the ABAP Cloud development model.

None of this is an accident, and very little of it is a mistake. Each layer was the right answer when it was written, and most of it still does its job. The engineering skill that matters is **not** knowing the newest syntax — it is knowing, for any given piece of code, whether you should leave it alone, extend it in place, or replace it.

That is what this chapter is for. It is a **map**, not a migration mandate. Existing code is aligned when it is changed anyway, not rewritten just to comply ([Rule 0.2](../docs/ABAP-Development-Rules.md#02-apply-the-rules-to-new-and-modified-code-in-every-abap-side-guide)).

> 📝 **S/4HANA is not a language version.** An on-premise S/4HANA system runs Standard ABAP. The restricted dialect is a property of each development object, its ABAP language version — see [What Changes Under ABAP Cloud](#-what-changes-under-abap-cloud).

> ⚠️ **Read this before you "modernise" anything.** Rewriting working, tested, business-critical code to use newer syntax is a cost with no business benefit and a real regression risk. Modernise when you are touching the code anyway, when the old construct is genuinely blocking you, or when the target platform requires it.

## 🗂️ The Five Categories Used in This Guide

Throughout this repository, technologies are labelled with one of these:

| Label | Meaning |
|---|---|
| **CURRENT / RECOMMENDED** | What to reach for in new on-premise ABAP development. |
| **CLASSIC BUT STILL RELEVANT** | Not the first choice for new code, but present throughout productive systems, still supported, and sometimes still the only option. You must be able to read and maintain it. |
| **LEGACY / HISTORICAL REFERENCE** | Superseded. Read it, understand it, maintain it where it exists — but do not write new code with it. |
| **ABAP CLOUD / MODERN CONTEXT** | Belongs to the ABAP Cloud development model, or describes how that model changes the picture. |
| **VERSION-DEPENDENT** | Availability depends on the release or the ABAP language version. Verify against your target system. |

> ⚠️ **"Deprecated" is deliberately absent from that list.** It is a specific claim, and this guide only uses SAP's own terminology where SAP's documentation supports it. Where the ABAP Keyword Documentation calls something *obsolete*, that word is used. The one place "deprecated" appears is as the **release state of an API**, the sense in which SAP's list of released objects uses it ([Rule 1.2](../docs/ABAP-Development-Rules.md#12-when-targeting-abap-for-cloud-development-use-only-released-apis)).

## 🟢 Current / Recommended On-Premise ABAP

What a new on-premise development should look like today.

| Area | Recommendation | Rules | Chapter |
|---|---|---|---|
| **Program structure** | ABAP Objects — classes and methods, small and single-purpose. Even a classical report benefits from a local class holding the logic. | 5.1, 5.7 | [10](../10-Objects/README.md), [01](../01-ABAP-Basics/README.md) |
| **Naming** | Descriptive names without type or scope prefixes; object names by the naming table. | 2.1–2.6 | [20](../20-Best-Practices/README.md) |
| **Expressions** | `VALUE`, `NEW`, `CONV`, `CORRESPONDING`, `COND`, `SWITCH`, `REDUCE`, `FILTER`, `FOR`, table expressions, string templates, inline declarations. | 3.1–3.15 | [03](../03-Variables/README.md), [05](../05-Control-Statements/README.md), [07](../07-Internal-Tables/README.md) |
| **Constants and Booleans** | Named constants, enumeration types for closed value sets *(VERSION-DEPENDENT)*, `abap_bool` and `xsdbool`. | 4.1–4.8 | [20](../20-Best-Practices/README.md) |
| **Database access** | Modern ABAP SQL: comma-separated field lists, `@` host escaping, SQL expressions, joins and subqueries, aggregation in the database. | 7.1–7.8, 7.13 | [08](../08-Open-SQL/README.md) |
| **Internal tables** | Typed table categories, `SORTED`/`HASHED` where appropriate, secondary keys for frequent reads that do not use the primary key. | 9.3, 9.4 | [07](../07-Internal-Tables/README.md), [19](../19-Performance/README.md) |
| **Writing data** | The supported API for the object — a BAPI or a released interface. Never direct DML against SAP standard application tables. | 7.9, 7.15 | [15](../15-BAPIs/README.md) |
| **Transactions** | Explicit ownership: the top-level caller commits; reusable units do not. | 7.10–7.12, 7.14 | [08](../08-Open-SQL/README.md#-sap-luw--transaction-ownership) |
| **Authorization** | Explicit checks at entry points, including RFC; `WITH AUTHORITY-CHECK` on `CALL TRANSACTION`; authorization checks on generic table access. | 8.1, 8.9, 8.10 | [11](../11-Classical-Reports/README.md), [14](../14-Function-Modules/README.md) |
| **Error handling** | Class-based exceptions, caught specifically, ordered most-specific first. | 6.1–6.11 | [18](../18-Debugging/README.md) |
| **Extensibility** | BAdIs — preferably released ones — over enhancement points, over exits, over modifications. | 1.3 | [16](../16-BADIs/README.md), [17](../17-Enhancements/README.md) |
| **Reporting UI** | `cl_salv_table` for display-oriented reports; `cl_gui_alv_grid` where you genuinely need editable cells and rich events. | — | [13](../13-ALV/README.md) |
| **Design for testability** | Small methods, dependencies passed in rather than reached for, `cl_abap_context_info` instead of `sy-` fields where it matters. | 5.4, 5.12 | [20](../20-Best-Practices/README.md) |
| **ABAP Unit** | Local test classes for every new class, test doubles through interfaces, the ABAP SQL and CDS test environments for database access. | 10.1–10.10 | [22](../22-ABAP-Unit/README.md) |
| **Documentation in code** | ABAP Doc for public APIs; pragmas, each with a reason, instead of pseudo comments. | 11.4, 11.5 | [20](../20-Best-Practices/README.md) |

> 📝 **On testing.** [22-ABAP-Unit](../22-ABAP-Unit/README.md) teaches ABAP Unit; [section 10 of the rules](../docs/ABAP-Development-Rules.md#10-testing) summarises the rules.

## 🟡 Classic but Still Relevant

These are not going away, they are not mistakes, and a technical lead who cannot read them cannot review most of the code in their own landscape.

| Technology | Why it still matters | Rules | Chapter |
|---|---|---|---|
| **Function modules** | Enormous installed base. Still the unit of RFC-callable logic, and the form every BAPI takes. | 5.1 | [09](../09-Modularization/README.md), [14](../14-Function-Modules/README.md) |
| **RFC** | The backbone of system-to-system integration on-premise. Carries real authorization and trust implications you must understand. | 8.10 | [09](../09-Modularization/README.md#-calling-a-function-module-via-rfc-destination) |
| **BAPIs** | Many remain the supported, released write interface for their business object. Prefer them over anything you would write yourself. | 6.9, 7.11 | [15](../15-BAPIs/README.md) |
| **Classic exceptions** (`EXCEPTIONS`, `sy-subrc`) | Raised by every existing function module, and the only exception handling RFC supports. Do not define new ones outside RFC. | 6.1, 6.9 | [18](../18-Debugging/README.md) |
| **Selection screens** | The standard input mechanism for on-premise reports. `SELECT-OPTIONS` and range tables have no direct modern equivalent. | — | [12](../12-Selection-Screens/README.md) |
| **Dynpro (PBO/PAI)** | Every classic transaction is built on it. You cannot maintain SAP GUI applications without it. | — | [12](../12-Selection-Screens/README.md#-custom-screens-dynpros) |
| **`CL_GUI_ALV_GRID`** | Still the only on-premise option for an editable, event-rich grid inside a dynpro. | — | [13](../13-ALV/README.md) |
| **`REUSE_ALV_*`** | Not the choice for new code, but present in thousands of existing reports you will be asked to change. | — | [13](../13-ALV/README.md) |
| **Classical reports (`WRITE`)** | Background jobs, spool output, quick internal tools. | — | [11](../11-Classical-Reports/README.md) |
| **BDC / `CALL TRANSACTION`** | The practical fallback for mass loads into transactions with no API. A last resort — but a real one. Always with an explicit authority addition. | 8.9 | [14](../14-Function-Modules/README.md) |
| **Classic BAdIs, enhancement points** | The extension mechanism holding most existing customer logic. | — | [16](../16-BADIs/README.md), [17](../17-Enhancements/README.md) |
| **`TABLES`** | Not allowed in classes, but still **required** for dynpro and selection-screen structures such as `SSCRFIELDS`. Only the variant `TABLES *` is obsolete. | — | [12](../12-Selection-Screens/README.md) |
| **`FOR ALL ENTRIES`** | Not obsolete. Joins and subqueries are usually better, but FAE remains the right tool when the driver set comes from ABAP. | 7.4 | [08](../08-Open-SQL/README.md#-for-all-entries-in) |
| **ABAP Memory** (`EXPORT`/`IMPORT … TO`/`FROM MEMORY ID`, named parameters) | Legitimate for `SUBMIT`-based decoupling between programs of one call sequence. Not classified as obsolete in the named form; the short forms are (see the legacy table). | — | [19](../19-Performance/README.md#-abap-memory--passing-data-between-programs) |
| **Dynamic programming** (`ASSIGN`, RTTS, dynamic SQL) | Powerful and necessary for generic frameworks — and security-sensitive. | 8.4 | [07](../07-Internal-Tables/README.md), [11](../11-Classical-Reports/README.md) |
| **Prefix notation** (`lv_`, `lt_`, `iv_` …) | Everywhere in existing code, so it must be read fluently. New code uses Clean ABAP names; a change inside a prefixed object keeps that object's style. | 2.1, 2.5 | [20](../20-Best-Practices/README.md#-reading-classic-prefix-notation) |
| **`CHECK` outside the start of a method** | Common in existing loops and processing blocks. Its effect depends on where it stands, so new code uses `IF … RETURN` and, in loops, `IF` with `CONTINUE`. | 3.17 | [05](../05-Control-Statements/README.md) |
| **`CREATE OBJECT`** | Not obsolete and found in most existing code. New code uses `NEW`. | 3.6 | [10](../10-Objects/README.md) |
| **Length in parentheses** (`DATA text(10) TYPE c`) | Not classified as obsolete. The ABAP Keyword Documentation recommends `LENGTH` for legibility, so new code writes `DATA text TYPE c LENGTH 10`. Only length specifications for `d`, `f`, `i` and `t` are obsolete. | 3.16 | [02](../02-Data-Types/README.md) |
| **Test seams** | A bridge for testing legacy code that cannot take a dependency yet, not a design for new code. | 10.7 | [22](../22-ABAP-Unit/README.md#-test-seams-for-legacy-code), [20](../20-Best-Practices/README.md#-refactoring-legacy-code) |
| **`*&` program header block** | Found at the top of many existing programs. New code states its purpose in a comment or ABAP Doc; the version history records author and date. | 11.4, 11.6 | [20](../20-Best-Practices/README.md#-comments-abap-doc-and-program-headers) |

## 🕰️ Legacy / Historical Reference

Superseded, but preserved in this guide because you will meet all of it. Knowing *why* each was replaced is more useful than knowing that it was. Entries marked **obsolete** are classified that way by the ABAP Keyword Documentation; the others are the guide's own classification.

| Technology | Superseded by | Why it was replaced | Rules |
|---|---|---|---|
| **`FORM` / `PERFORM`** (obsolete) | Methods | No encapsulation, weak or absent parameter typing, no interfaces, no polymorphism. | 3.16 |
| **Macros (`DEFINE`)** | Methods or expressions | Text substitution before compilation: no context, no signature, and the debugger cannot step through them. Not classified as obsolete; the ABAP Programming Guidelines allow them only in exceptional cases. | 3.19 |
| **Header-line tables / `OCCURS`** (obsolete) | Explicit work areas | The table and its work area share a name, which makes code ambiguous to read and impossible to use in ABAP Objects contexts. | 3.16 |
| **`MOVE a TO b`** (obsolete) | `b = a` | The assignment operator is shorter and works in expressions. | 3.16 |
| **`EXPORT`/`IMPORT` without parameter names, `… TO MEMORY` / `FREE MEMORY` without `ID`** (obsolete) | `EXPORT p1 = dobj1 … TO MEMORY ID id`, `FREE MEMORY ID id` | Without names each object is stored under its own name, which is error-prone; without an ID, every export overwrites the same anonymous area. | 3.16 |
| **`REFRESH itab`** (obsolete) | `CLEAR itab` | `CLEAR` does the same for a table without a header line. | 3.16 |
| **Static `CALL METHOD`** (obsolete) | Functional method call | A functional call can be used in expressions and reads like a function. | 3.15 |
| **Host variables without `@`** (obsolete) | Strict ABAP SQL with `@` | The strict syntax is checked more thoroughly and separates ABAP data from columns. | 7.1 |
| **`CLIENT SPECIFIED`** (obsolete) | `USING CLIENT` / `USING [ALL] CLIENTS` | Implicit client handling is the default; cross-client access must be explicit. | 7.8 |
| **`CALL TRANSACTION` without `WITH`/`WITHOUT AUTHORITY-CHECK`** (obsolete) | `WITH AUTHORITY-CHECK` | The call should state whether the user's authorization is checked. | 8.9 |
| **Pseudo comments for the extended program check (`"#EC …`)** (obsolete) | Pragmas (`##…`) | Pragmas are checked by the compiler and tied to a specific check. | 11.5 |
| **Pseudo comments for test classes (`"#AU Risk_Level`, `"#AU Duration`)** (obsolete) | The additions `RISK LEVEL` and `DURATION` of `CLASS … FOR TESTING` | The additions are real syntax; a misspelt pseudo comment only produces a warning when the tests run. Existing pseudo comments still take effect. | 10.2 |
| **`SEARCH`** (obsolete) | `FIND` | `FIND` offers match offset, length, line and regular-expression support, and is far clearer about what it did. | 3.16 |
| **`REPLACE f1 WITH f2 INTO g`** (obsolete) | `REPLACE ... IN ...`, `replace( )` | The short form's operand order is unmemorable and its behaviour surprising. | 3.16 |
| **`REGEX` addition** (POSIX syntax, obsolete) | `PCRE` addition *(VERSION-DEPENDENT)* | A more complete and standard regular-expression syntax. Verify availability on your release. | 3.16 |
| **`TYPE-POOLS`** (obsolete) | Nothing — no longer required | The statement is checked for syntax but otherwise ignored. | 3.16 |
| **`END-OF-SELECTION`** (obsolete) | No replacement needed; process in `START-OF-SELECTION` | Intended only for programs linked to a logical database; without one it is raised directly after `START-OF-SELECTION`. | 3.16 |
| **User exits (`USEREXIT_*`)** | BAdIs, enhancement points | You edit a delivered include, so it carries modification-like upgrade cost. | — |
| **Customer exits (SMOD/CMOD)** (obsolete) | BAdIs | One active project per enhancement; procedural; no filtering. The ABAP Keyword Documentation lists `CALL CUSTOMER-FUNCTION` among the obsolete calls and names the Enhancement Framework and `CALL BADI` instead. | — |
| **Modifications (access key)** | Any of the above | Every upgrade becomes an adjustment project. | — |
| **Reading domain fixed values from `DD07L`/`DD07T` or with `DD_DOMVALUES_GET`** | RTTS (`get_ddic_fixed_values`) | RTTS reads the fixed values through the data element's own type description, without a table read or a function module call. | — |
| **Frontend function modules `WS_FILENAME_GET`, `WS_UPLOAD`, `WS_DOWNLOAD`, `UPLOAD`** | Methods of `cl_gui_frontend_services` | One class covers the file dialogs and the transfer, with a typed signature and one exception per failure. | — |
| **OLE automation (`ole2_object`)** | Server-side file generation | Requires SAP GUI for Windows on the user's desktop; fails in background jobs and over RFC. | — |
| **`SELECT ... ENDSELECT`** row by row | `SELECT ... INTO TABLE` | Row-by-row round trips to the database. `PACKAGE SIZE` with `ENDSELECT` for very large volumes remains accepted. | 9.7 |

> 💡 **Historical knowledge has real value.** When you are debugging a twelve-year-old pricing routine at two in the morning, being fluent in header lines and `PERFORM ... USING` is worth considerably more than knowing the newest constructor expression. Keep both.

## ☁️ What Changes Under ABAP Cloud

> **Lifecycle:** `ABAP CLOUD / MODERN CONTEXT`. This section explains the *shape* of the change; it does not attempt a compatibility matrix, because every row of such a matrix would need verifying against a specific release.

**The three things that actually change:**

1. **A restricted ABAP language version.** Every ABAP program and many other repository objects carry an ABAP language version. The ABAP Keyword Documentation names Standard ABAP (unrestricted), ABAP for Cloud Development, and ABAP for Key Users. ABAP for Cloud Development covers a subset of the language, and the syntax check enforces it — see [Rule 1.1](../docs/ABAP-Development-Rules.md#11-know-the-language-version-of-every-object-you-change).

2. **You may only use *released* APIs.** In Standard ABAP you can call almost any SAP object you can find. In ABAP for Cloud Development you may only use objects released for that language version — in general with the release contract C1 — plus objects of your own software component. A released object has the release state *Released* or *Deprecated*; a deprecated one names its successor where one exists. An object existing is no longer the same as an object being usable — see [Rules 1.2](../docs/ABAP-Development-Rules.md#12-when-targeting-abap-for-cloud-development-use-only-released-apis) and [1.3](../docs/ABAP-Development-Rules.md#13-in-standard-abap-prefer-a-released-api-over-an-unreleased-one-when-both-exist).

3. **Extension happens at defined extension points.** You extend through released BAdIs, released APIs, and the defined extensibility options. According to the ABAP Keyword Documentation, only released APIs can be used or extended. This is the practical content of "keep the core clean". The extensibility options themselves are described in SAP's extensibility documentation on the [SAP Help Portal](https://help.sap.com/).

**What this means for the technologies in this guide:**

- **Not allowed in ABAP for Cloud Development:** dynpro statements, classical list output (`WRITE`), selection screens (`PARAMETERS`, `SELECT-OPTIONS`), `CALL TRANSACTION` and therefore BDC, macros (`DEFINE`), and header-line tables (`WITH HEADER LINE`, `OCCURS`). These belong to the on-premise model.
- **`FORM` / `PERFORM`:** obsolete; technically allowed in ABAP for Cloud Development; not written in new code.
- **`REUSE_ALV_*` and `CL_GUI_ALV_GRID`:** these are APIs, not statements, so the language version alone does not decide. `CL_GUI_ALV_GRID` and `CL_SALV_TABLE` are not in the list of released APIs of the ABAP Keyword Documentation *(VERSION-DEPENDENT: the list changes with the release)*. **[verify: the release state of the `REUSE_ALV_*` function modules for ABAP for Cloud Development]**
- **Checkpoint statements:** `BREAK-POINT` and `LOG-POINT` are not allowed in ABAP for Cloud Development; `ASSERT`, `RAISE SHORTDUMP` and `THROW SHORTDUMP` are, according to the overview of language elements per language version in the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) *(VERSION-DEPENDENT)*. See [23-Debugging-Troubleshooting](../23-Debugging-Troubleshooting/README.md).
- **Carries over:** ABAP Objects, modern expressions and modern ABAP SQL. Individual additions can still differ, so check the language-element list for your release.
- **Direct access to SAP standard tables** is replaced by released APIs, for example released CDS views ([Rule 7.2](../docs/ABAP-Development-Rules.md#72-read-through-released-cds-views-where-they-exist)).

**How to check, rather than guess:**

- Run ATC with the check variant `ABAP_CLOUD_READINESS`, which is itself a released object. Call code cloud-ready only after that check or a compile under ABAP for Cloud Development passed — see [Rules 1.5](../docs/ABAP-Development-Rules.md#15-never-call-code-cloud-ready-unless-it-was-checked) and [13.3](../docs/ABAP-Development-Rules.md#133-run-the-cloud-readiness-check-wherever-section-1-applies).
- Look up an object's release state and successor before designing around it. The program `ABAP_DOCU_RELEASED_APIS` lists the released objects of a system; SAP also publishes this information for its products.
- Exempt an ATC finding only with a written reason ([Rule 13.2](../docs/ABAP-Development-Rules.md#132-fix-every-atc-finding-or-exempt-it-with-a-written-reason)).

> ⚠️ **Migration is an architecture question, not a syntax question.** The work is not "translate this statement into a newer one". It is: *what is this code actually for, is there a released interface that does it, and if there is not, what is the supported extension point?* Sometimes the answer is that the functionality moves somewhere else entirely. Budget accordingly.

> 📝 **Verify before you commit to anything specific.** Which APIs are released, and what a given ABAP language version permits, both depend on your release and change over time. Check the ABAP Keyword Documentation and the released-API information for your target system. This chapter deliberately states no release numbers.

## 🔀 Decision Table

| Scenario | What to preserve / understand | Preferred direction | Notes |
|---|---|---|---|
| **Maintaining an existing classic on-premise application** | The existing style. Read `FORM`s, macros, header lines and dynpro fluently. | Leave working code alone. Improve what you touch: type a parameter, extract a method, fix a real defect. Keep the object's naming style ([Rule 2.5](../docs/ABAP-Development-Rules.md#25-in-legacy-code-keep-naming-consistent-within-a-development-object)) and format only what you changed ([Rule 12.3](../docs/ABAP-Development-Rules.md#123-format-with-the-abap-formatter-and-the-teams-settings-before-activating)). | A "modernisation" that changes nothing functional is pure regression risk. Don't. |
| **New development on-premise** | Where the surrounding code sits, so your new code fits its neighbours. | ABAP Objects, Clean ABAP names, modern expressions, modern ABAP SQL, explicit transaction ownership, explicit authorization checks, ABAP Unit tests. | Use SALV unless you genuinely need an editable grid. |
| **Existing BAPI-based integration** | The BAPI protocol: `BAPIRET2` handling, `BAPI_TRANSACTION_COMMIT`/`ROLLBACK`, caller-owned LUW. | Keep the BAPI. Wrap it in a class if the calling code needs a cleaner interface. | Check whether the BAPI is released before assuming it is available in a cloud context. |
| **Maintaining a SAP GUI transaction (dynpro)** | PBO/PAI, the Screen Painter, `MODIF ID` and `LOOP AT SCREEN`, and the split between flow logic and ABAP source. | Keep it. Move business logic out of modules into classes so it becomes testable and reusable. | Thinning the modules is valuable even when the screen stays exactly as it is. |
| **Building an ABAP Cloud extension** | Why the classic API exists and what business rules it enforces — you still need to know what you are replacing. | A released API or a released extension point. Fiori/UI5 over OData for the UI. | If no released interface exists, that is a genuine finding to raise, not a gap to work around. |
| **Reviewing someone else's code** | All of the above. | Ask whether each classic construct is *deliberate* or *habitual*, and use the [Chapter 20 checklist](../20-Best-Practices/README.md#-best-practices). | "It's old" is not a review finding. "It's wrong", "it's unsafe", or "it's not the supported interface" are. |

## 🚧 Scope Boundary

**ABAPGuide is an ABAP engineering reference.** It covers the language, its data access, the classic UI and extensibility technologies, the modern expression and SQL syntax that came in with the 7.40 generation, and ABAP Unit — as those things are actually used in productive landscapes.

It is **not**:

- a RAP course — behaviour definitions, EML, managed and unmanaged scenarios are not covered;
- a CDS course — view entities, associations and annotations are not covered; see [CDSGuide](https://github.com/serhatmercan/CDSGuide);
- an AMDP or code-pushdown guide;
- an ABAP Cloud migration handbook — [What Changes Under ABAP Cloud](#-what-changes-under-abap-cloud) sets out the boundary and stops there;
- a substitute for SAP's official documentation. For anything version-sensitive, the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) is the authority.

Stating this plainly is deliberate. A reference that is honest about its edges is more useful than one that gestures at everything — and the material this guide *does* cover is the material most SAP landscapes are actually built from.

## ✅ Best Practices

- Call a construct obsolete only when the ABAP Keyword Documentation does, and use its wording — [Rule 3.16](../docs/ABAP-Development-Rules.md#316-do-not-write-statements-the-abap-keyword-documentation-classifies-as-obsolete).
- Modernise code when you change it anyway, not as a project of its own — [Rule 0.2](../docs/ABAP-Development-Rules.md#02-apply-the-rules-to-new-and-modified-code-in-every-abap-side-guide).
- Check an object's release state and successor before designing around it — [Rule 1.2](../docs/ABAP-Development-Rules.md#12-when-targeting-abap-for-cloud-development-use-only-released-apis).
- State the target language version wherever an example's validity depends on it — [Rule 1.4](../docs/ABAP-Development-Rules.md#14-state-the-target-language-version-when-it-matters).
- Call code cloud-ready or checked only after the check ran, and record it — [Rules 1.5](../docs/ABAP-Development-Rules.md#15-never-call-code-cloud-ready-unless-it-was-checked) and [13.5](../docs/ABAP-Development-Rules.md#135-claim-a-check-in-the-guides-only-after-it-ran-and-record-it).
- When a classification changes, update this chapter's tables together with the chapter that uses the label.

## ⚠️ Common Mistakes

- Calling something "obsolete" or "deprecated" that the documentation does not, such as macros or the length in parentheses.
- Rewriting working code only to use newer syntax.
- Assuming an SAP object is usable in ABAP for Cloud Development because it exists in the system.
- Treating "S/4HANA" and "ABAP Cloud" as the same thing; the restriction comes from the ABAP language version of the object.
- Concluding from the language-element list alone that an API is available; statements and released APIs are checked separately.

## 🎤 Interview & Review Checkpoints

- Explain the five lifecycle labels, and why the guide avoids the word "deprecated" except for the release state of an API.
- Explain the difference between a release and an ABAP language version, and name the three language versions.
- Explain what a release contract is, and what it means that an object is released or deprecated.
- Describe when you would leave classic code alone, and what you would still improve while you are in it.
- Name constructs the ABAP Keyword Documentation classifies as obsolete, and one that people often call obsolete but that is not.

## 🔗 Related Chapters

Every chapter in this guide carries a lifecycle note that points back here:

- [05-Control-Statements](../05-Control-Statements/README.md) — `CHECK` and its replacements
- [09-Modularization](../09-Modularization/README.md) — function modules, subroutines and macros
- [11-Classical-Reports](../11-Classical-Reports/README.md) — classical lists and generic table access
- [12-Selection-Screens](../12-Selection-Screens/README.md) — selection screens and dynpro
- [13-ALV](../13-ALV/README.md) — the three ALV generations
- [14-Function-Modules](../14-Function-Modules/README.md) — batch input and `CALL TRANSACTION`
- [15-BAPIs](../15-BAPIs/README.md) — the released write interfaces
- [16-BADIs](../16-BADIs/README.md) — classic and new BAdIs
- [17-Enhancements](../17-Enhancements/README.md) — exits, enhancement points and modifications
- [20-Best-Practices](../20-Best-Practices/README.md) — the review checklist that applies all of this
- [docs/ABAP-Development-Rules.md](../docs/ABAP-Development-Rules.md) — the rules every classification cites
