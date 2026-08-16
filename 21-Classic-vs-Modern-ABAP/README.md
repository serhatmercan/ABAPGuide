# 21 — Classic vs Modern ABAP

## 📖 Why Multiple Generations Matter

A productive SAP landscape is not written in one dialect. Open almost any system that has been live for more than a few years and you will find, side by side and all of it running:

- procedural ABAP — `FORM`/`PERFORM`, macros, header-line tables;
- function modules and BAPIs, some RFC-enabled, most not;
- dynpro screens, classical `WRITE` lists, and two or three generations of ALV;
- classic extensibility — user exits, customer exits, BAdIs, enhancement points;
- ABAP Objects;
- modern expression syntax and modern ABAP SQL;
- and, increasingly, code written under the constraints of the ABAP Cloud development model.

None of this is an accident, and very little of it is a mistake. Each layer was the right answer when it was written, and most of it still does its job. The engineering skill that matters is **not** knowing the newest syntax — it is knowing, for any given piece of code, whether you should leave it alone, extend it in place, or replace it.

That is what this chapter is for. It is a **map**, not a migration mandate.

> **Read this before you "modernise" anything.** Rewriting working, tested, business-critical code to use newer syntax is a cost with no business benefit and a real regression risk. Modernise when you are touching the code anyway, when the old construct is genuinely blocking you, or when the target platform requires it.

## 🗂️ The Five Categories Used in This Guide

Throughout this repository, technologies are labelled with one of these:

| Label | Meaning |
|---|---|
| **CURRENT / RECOMMENDED** | What to reach for in new on-premise ABAP development. |
| **CLASSIC BUT STILL RELEVANT** | Not the first choice for new code, but present throughout productive systems, still supported, and sometimes still the only option. You must be able to read and maintain it. |
| **LEGACY / HISTORICAL REFERENCE** | Superseded. Read it, understand it, maintain it where it exists — but do not write new code with it. |
| **ABAP CLOUD / MODERN CONTEXT** | Belongs to the ABAP Cloud development model, or describes how that model changes the picture. |
| **VERSION-DEPENDENT** | Availability depends on the release or the ABAP language version. Verify against your target system. |

> ⚠️ **"Deprecated" is deliberately absent from that list.** It is a specific claim, and this guide only uses SAP's own terminology where SAP's documentation supports it. Where the ABAP Keyword Documentation calls something *obsolete*, that word is used. Everything else is described by what it is, not by a label it may not carry.

---

## 1. Current / Recommended On-Premise ABAP

What a new on-premise development should look like today.

| Area | Recommendation | Chapter |
|---|---|---|
| **Program structure** | ABAP Objects — classes and methods, small and single-purpose. Even a classical report benefits from a local class holding the logic. | [10](../10-Objects/README.md), [01](../01-ABAP-Basics/README.md) |
| **Expressions** | `VALUE`, `NEW`, `CONV`, `CORRESPONDING`, `COND`, `SWITCH`, `REDUCE`, `FILTER`, `FOR`, table expressions, string templates, inline declarations. | [03](../03-Variables/README.md), [05](../05-Control-Statements/README.md), [07](../07-Internal-Tables/README.md) |
| **Database access** | Modern ABAP SQL: comma-separated field lists, `@` host escaping, SQL expressions, joins and subqueries, aggregation in the database. | [08](../08-Open-SQL/README.md) |
| **Internal tables** | Typed table categories, `SORTED`/`HASHED` where appropriate, secondary keys instead of `BINARY SEARCH`. | [07](../07-Internal-Tables/README.md), [19](../19-Performance/README.md) |
| **Writing data** | The supported API for the object — a BAPI or a released interface. Never direct DML against SAP standard application tables. | [15](../15-BAPIs/README.md) |
| **Transactions** | Explicit ownership: the top-level caller commits; reusable units do not. | [08](../08-Open-SQL/README.md#-sap-luw--transaction-ownership) |
| **Authorization** | Explicit checks at entry points; `WITH AUTHORITY-CHECK` on `CALL TRANSACTION`; authorization checks on generic table access. | [11](../11-Classical-Reports/README.md), [14](../14-Function-Modules/README.md) |
| **Error handling** | Class-based exceptions, caught specifically, ordered most-specific first. | [18](../18-Debugging/README.md) |
| **Extensibility** | BAdIs — preferably released ones — over enhancement points, over exits, over modifications. | [16](../16-BADIs/README.md), [17](../17-Enhancements/README.md) |
| **Reporting UI** | `cl_salv_table` for display-oriented reports; `cl_gui_alv_grid` where you genuinely need editable cells and rich events. | [13](../13-ALV/README.md) |
| **Design for testability** | Small methods, dependencies passed in rather than reached for, `cl_abap_context_info` instead of `sy-` fields where it matters. | [20](../20-Best-Practices/README.md) |

> 📝 **On testing.** Designing for testability is listed above because it changes how you structure code. This guide does **not** cover ABAP Unit itself — writing test classes, test doubles, and test-seam techniques is a substantial topic and is outside its scope. See the [scope boundary](#6-scope-boundary) at the end of this chapter.

---

## 2. Classic but Still Relevant

These are not going away, they are not mistakes, and a technical lead who cannot read them cannot review most of the code in their own landscape.

| Technology | Why it still matters | Chapter |
|---|---|---|
| **Function modules** | Enormous installed base. Still the unit of RFC-callable logic, and the form every BAPI takes. | [09](../09-Modularization/README.md), [14](../14-Function-Modules/README.md) |
| **RFC** | The backbone of system-to-system integration on-premise. Carries real authorization and trust implications you must understand. | [09](../09-Modularization/README.md#-calling-a-function-module-via-rfc-destination) |
| **BAPIs** | Many remain the supported, released write interface for their business object. Prefer them over anything you would write yourself. | [15](../15-BAPIs/README.md) |
| **Selection screens** | The standard input mechanism for on-premise reports. `SELECT-OPTIONS` and range tables have no direct modern equivalent. | [12](../12-Selection-Screens/README.md) |
| **Dynpro (PBO/PAI)** | Every classic transaction is built on it. You cannot maintain SAP GUI applications without it. | [12](../12-Selection-Screens/README.md#-custom-screens-dynpros) |
| **`CL_GUI_ALV_GRID`** | Still the only on-premise option for an editable, event-rich grid inside a dynpro. | [13](../13-ALV/README.md) |
| **`REUSE_ALV_*`** | Not the choice for new code, but present in thousands of existing reports you will be asked to change. | [13](../13-ALV/README.md) |
| **Classical reports (`WRITE`)** | Background jobs, spool output, quick internal tools. | [11](../11-Classical-Reports/README.md) |
| **BDC / `CALL TRANSACTION`** | The practical fallback for mass loads into transactions with no API. A last resort — but a real one. | [14](../14-Function-Modules/README.md) |
| **Classic BAdIs, enhancement points** | The extension mechanism holding most existing customer logic. | [16](../16-BADIs/README.md), [17](../17-Enhancements/README.md) |
| **`TABLES`** | Obsolete generally, but still **required** for dynpro and selection-screen structures such as `SSCRFIELDS`. | [12](../12-Selection-Screens/README.md) |
| **`FOR ALL ENTRIES`** | Not obsolete. Joins and subqueries are usually better, but FAE remains the right tool when the driver set comes from ABAP. | [08](../08-Open-SQL/README.md#-for-all-entries-in) |
| **ABAP Memory** | Legitimate for `SUBMIT`-based decoupling between programs. | [19](../19-Performance/README.md) |
| **Dynamic programming** (`ASSIGN`, RTTS, dynamic SQL) | Powerful and necessary for generic frameworks — and security-sensitive. | [07](../07-Internal-Tables/README.md), [11](../11-Classical-Reports/README.md) |

---

## 3. Legacy / Historical Reference

Superseded, but preserved in this guide because you will meet all of it. Knowing *why* each was replaced is more useful than knowing that it was.

| Technology | Superseded by | Why it was replaced |
|---|---|---|
| **`FORM` / `PERFORM`** | Methods | No encapsulation, weak or absent parameter typing, no interfaces, no polymorphism. |
| **Macros (`DEFINE`)** | Methods | Text substitution before compilation: no type checking, no signature, and the debugger steps over the whole thing as one statement. |
| **Header-line tables / `OCCURS`** | Explicit work areas | The table and its work area share a name, which makes code ambiguous to read and impossible to use in ABAP Objects contexts. |
| **`SEARCH`** | `FIND` | `FIND` offers match offset, length, line and regular-expression support, and is far clearer about what it did. |
| **`REPLACE f1 WITH f2 INTO g`** | `REPLACE ... IN ...`, `replace( )` | The short form's operand order is unmemorable and its behaviour surprising. |
| **`REGEX` addition** | `PCRE` addition *(VERSION-DEPENDENT)* | A more complete and standard regular-expression syntax. Verify availability on your release. |
| **`DATA lv_x(10)`** | `DATA lv_x TYPE c LENGTH 10.` | Explicit and unambiguous. |
| **`TYPE-POOLS`** | Nothing — no longer required | Type pools are loaded automatically. |
| **User exits (`USEREXIT_*`)** | BAdIs, enhancement points | You edit a delivered include, so it carries modification-like upgrade cost. |
| **Customer exits (SMOD/CMOD)** | BAdIs | One active project per enhancement; procedural; no filtering. |
| **Modifications (access key)** | Any of the above | Every upgrade becomes an adjustment project. |
| **OLE automation (`ole2_object`)** | Server-side file generation | Requires SAP GUI for Windows on the user's desktop; fails in background jobs and over RFC. |
| **`SELECT ... ENDSELECT`** | `SELECT ... INTO TABLE` | Row-by-row round trips to the database. |

> 💡 **Historical knowledge has real value.** When you are debugging a twelve-year-old pricing routine at two in the morning, being fluent in header lines and `PERFORM ... USING` is worth considerably more than knowing the newest constructor expression. Keep both.

---

## 4. What Changes Under ABAP Cloud

Kept deliberately brief and conservative. This section explains the *shape* of the change; it does not attempt a compatibility matrix, because every row of such a matrix would need verifying against a specific release.

**The three things that actually change:**

1. **A restricted ABAP language version.** ABAP for Cloud Development permits a subset of the language. Constructs tied to the SAP GUI, to direct Dictionary access, or to older procedural styles are outside it. This is enforced by the syntax check, not by convention.

2. **You may only use *released* APIs.** In classic on-premise ABAP you can call almost any SAP object you can find. In the cloud model you may only use objects SAP has explicitly released for cloud development, with a stability contract attached. An object existing is no longer the same as an object being usable.

3. **Extension happens at defined extension points.** Modifications, implicit enhancements, and edits to delivered includes are not part of the model. You extend through released BAdIs, released APIs, and the defined extensibility options. This is the practical content of "keep the core clean".

**What this means for the technologies in this guide, at a high level:** the SAP GUI–bound and procedural layers — dynpro, classical lists, `REUSE_ALV_*`, `CL_GUI_ALV_GRID`, `CALL TRANSACTION`, BDC, macros, `FORM`/`PERFORM`, header-line tables — belong to the on-premise model and are outside the cloud development model. ABAP Objects, modern expressions and modern ABAP SQL carry over. Direct access to SAP standard tables is replaced by released APIs.

> ⚠️ **Migration is an architecture question, not a syntax question.** The work is not "translate this statement into a newer one". It is: *what is this code actually for, is there a released interface that does it, and if there is not, what is the supported extension point?* Sometimes the answer is that the functionality moves somewhere else entirely. Budget accordingly.

> 📝 **Verify before you commit to anything specific.** Which APIs are released, and what a given ABAP language version permits, both depend on your release and change over time. Check the ABAP Keyword Documentation and the released-API information for your target system. This chapter deliberately states no release numbers.

---

## 5. Decision Table

| Scenario | What to preserve / understand | Preferred direction | Notes |
|---|---|---|---|
| **Maintaining an existing classic on-premise application** | The existing style. Read `FORM`s, macros, header lines and dynpro fluently. | Leave working code alone. Improve what you touch: type a parameter, extract a method, fix a real defect. | A "modernisation" that changes nothing functional is pure regression risk. Don't. |
| **New development on-premise** | Where the surrounding code sits, so your new code fits its neighbours. | ABAP Objects, modern expressions, modern ABAP SQL, explicit transaction ownership, explicit authorization checks. | Use SALV unless you genuinely need an editable grid. |
| **Existing BAPI-based integration** | The BAPI protocol: `BAPIRET2` handling, `BAPI_TRANSACTION_COMMIT`/`ROLLBACK`, caller-owned LUW. | Keep the BAPI. Wrap it in a class if the calling code needs a cleaner interface. | Check whether the BAPI is released before assuming it is available in a cloud context. |
| **Maintaining a SAP GUI transaction (dynpro)** | PBO/PAI, the Screen Painter, `MODIF ID` and `LOOP AT SCREEN`, and the split between flow logic and ABAP source. | Keep it. Move business logic out of modules into classes so it becomes testable and reusable. | Thinning the modules is valuable even when the screen stays exactly as it is. |
| **Building an ABAP Cloud extension** | Why the classic API exists and what business rules it enforces — you still need to know what you are replacing. | A released API or a released extension point. Fiori/UI5 over OData for the UI. | If no released interface exists, that is a genuine finding to raise, not a gap to work around. |
| **Reviewing someone else's code** | All of the above. | Ask whether each classic construct is *deliberate* or *habitual*. | "It's old" is not a review finding. "It's wrong", "it's unsafe", or "it's not the supported interface" are. |

---

## 6. Scope Boundary

**ABAPGuide is an ABAP engineering reference.** It covers the language, its data access, the classic UI and extensibility technologies, and the modern expression and SQL syntax that came in with the 7.40 generation — as those things are actually used in productive landscapes.

It is **not**:

- a RAP course — behaviour definitions, EML, managed and unmanaged scenarios are not covered;
- a CDS course — view entities, associations and annotations are not covered;
- an AMDP or code-pushdown guide;
- an ABAP Unit or test-driven-development guide;
- an ABAP Cloud migration handbook — [section 4](#4-what-changes-under-abap-cloud) sets out the boundary and stops there;
- a substitute for SAP's official documentation. For anything version-sensitive, the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) is the authority.

Stating this plainly is deliberate. A reference that is honest about its edges is more useful than one that gestures at everything — and the material this guide *does* cover is the material most SAP landscapes are actually built from.

## 🔗 Related Chapters

Every chapter in this guide carries a lifecycle note that points back here:

- [09-Modularization](../09-Modularization/README.md) · [11-Classical-Reports](../11-Classical-Reports/README.md) · [12-Selection-Screens](../12-Selection-Screens/README.md) · [13-ALV](../13-ALV/README.md)
- [14-Function-Modules](../14-Function-Modules/README.md) · [15-BAPIs](../15-BAPIs/README.md) · [16-BADIs](../16-BADIs/README.md) · [17-Enhancements](../17-Enhancements/README.md)
- [20-Best-Practices](../20-Best-Practices/README.md) — the review checklist that applies all of this
