# 17 — Enhancements

## 📖 Introduction

> **Lifecycle:** labelled per technique in the table below, consistent with [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md): BAdIs `CURRENT / RECOMMENDED`, enhancement points and spots `CLASSIC BUT STILL RELEVANT`, user exits, customer exits and modifications `LEGACY / HISTORICAL REFERENCE`.

Beyond BAdIs ([16-BADIs](../16-BADIs/README.md)), SAP provides several other **enhancement techniques** to add custom logic to standard programs without modifying them directly. This chapter is a conceptual overview to complement the BAdI chapter, since enhancements are a closely related and frequently confused topic.

## 🧭 Enhancement Techniques Overview

| Technique | Era | Modifies Standard Code? | Multiple Implementations? | Typical Use | Lifecycle |
|---|---|---|---|---|---|
| **User Exit** (`USEREXIT_*` form routines) | Oldest — classic SD | ⚠️ Effectively yes — you edit a delivered include | ❌ No | Classic SD enhancements in includes such as `MV45AFZZ` | `LEGACY / HISTORICAL REFERENCE` |
| **Customer Exit / Function Exit** (`CALL CUSTOMER-FUNCTION`) | Classic (SMOD/CMOD) | ❌ No — a pre-planned hook | ❌ No (one CMOD project per enhancement) | Function, menu and screen exits in older modules | `LEGACY / HISTORICAL REFERENCE` |
| **BAdI** (Business Add-In) | Classic BAdIs replaced function exits; new BAdIs belong to the Enhancement Framework | ❌ No | ✅ Yes (multiple-use and/or filter-dependent) | The standard object-oriented extension point | `CURRENT / RECOMMENDED` |
| **Enhancement Point / Section** (Enhancement Framework) | Enhancement Framework | ❌ No — inserted at explicit or implicit positions | ✅ Yes | Inserting code inside standard logic | `CLASSIC BUT STILL RELEVANT` |
| **Explicit Enhancement Spot** | Enhancement Framework | ❌ No | ✅ Yes | Extension positions SAP designed deliberately | `CLASSIC BUT STILL RELEVANT` |
| **Modification (access key)** | Classic | ✅ Yes — direct change to an SAP object | N/A | Last resort only | `LEGACY / HISTORICAL REFERENCE` |

> ⚠️ **VERSION-DEPENDENT: when each technique became available.** The table gives the order of the techniques, not release numbers. Check the [ABAP Keyword Documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm) and SAP Help for your target release before you quote a version.

## 🔧 User Exits vs. Customer Exits

These two are constantly confused, including in job interviews. They are different mechanisms.

**User exits** (classic SD) are empty `FORM` routines that SAP delivers inside modification-enabled includes such as `MV45AFZZ`. You write your code directly into the delivered include:

> 📝 **Contextual snippet** — shows where the code goes, not what it does.

```abap
" In include MV45AFZZ (delivered by SAP, intended to be edited)
FORM userexit_save_document_prepare.
  " your validation / defaulting logic
ENDFORM.
```

Because you are editing an SAP object, these are registered as modifications in some landscapes and show up in `SPAU` during an upgrade.

**Customer exits** (also called function exits) are a genuine hook mechanism: SAP calls `CALL CUSTOMER-FUNCTION 'nnn'` from standard code, and you implement the corresponding function module — activated through a project in `CMOD` that references an SAP enhancement in `SMOD`. You never edit standard code:

```abap
" Inside standard SAP code (not modified by you):
CALL CUSTOMER-FUNCTION '001'.

" This calls the function module EXIT_<program>_001. You write its code in
" the customer include (ZX...) that the function module contains, and
" activate the enhancement through a CMOD project.
```

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE`. The ABAP Keyword Documentation lists `CALL CUSTOMER-FUNCTION` among the obsolete calls and calls enhancements through `CMOD` obsolete; it names the Enhancement Framework and `CALL BADI` as the replacement. If the exit is not active, the statement is ignored and `sy-subrc` keeps its previous value. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference).

Customer exits come in three kinds: **function exits** (logic), **menu exits** (extra menu entries) and **screen exits**. A screen exit gives you a subscreen area on a standard screen: you create the subscreen with your fields in the exit's function group, write its PBO/PAI modules in the customer include, and pass the data through the accompanying function exits. The screen logic itself is ordinary dynpro programming — see [12-Selection-Screens](../12-Selection-Screens/README.md#-custom-screens-dynpros).

## 🧵 Enhancement Points & Implicit Enhancements

**Explicit** enhancement options are statements SAP placed in its own code: `ENHANCEMENT-POINT` marks a position where your code is inserted, and `ENHANCEMENT-SECTION … END-ENHANCEMENT-SECTION` marks a block that one implementation can replace. Your code goes into a source code plug-in (`ENHANCEMENT … ENDENHANCEMENT`), which the ABAP Workbench creates and stores in an include of its own; the statements cannot be typed in directly.

> 📝 **Contextual snippet** — names are placeholders; the first part stands for SAP's code, the second for the plug-in the Workbench shows in your enhancement implementation.

```abap
" In SAP's code: an explicit enhancement point belonging to a spot
FORM check_document.
  ENHANCEMENT-POINT ep_check_document_01 SPOTS es_document_checks.
ENDFORM.

" In your enhancement implementation: the source code plug-in
ENHANCEMENT 1 zsm_ei_document_checks.
  " your custom coding, ideally one call into your own class
ENDENHANCEMENT.
```

**Implicit** enhancement options need no statement. According to the ABAP Keyword Documentation they exist, among other places, at the start and end of procedures, after the last line of programs and includes, at the end of visibility sections and parameter lists of local classes, and before `END OF` in structure definitions — but not in AMDP methods. The ABAP Editor displays them through its enhancement operations.

> 💡 Enhancement implementations and BAdI implementations can be assigned to switches of the Switch Framework; only implementations whose switch is on take effect.

## 🆚 Choosing Between Them

- **User exit** (`USEREXIT_*`): oldest, procedural, one implementation, and you edit a delivered include — so it carries modification-like upgrade cost.
- **Customer exit** (`CALL CUSTOMER-FUNCTION` + SMOD/CMOD): a real hook, but one active project per enhancement, procedural, and obsolete according to the ABAP Keyword Documentation.
- **BAdI**: object-oriented, can support multiple filter-dependent implementations. The standard answer for a planned extension point.
- **Enhancement point/spot**: lets you insert code at explicit positions SAP designed, or at *implicit* positions that exist almost everywhere. Powerful, and correspondingly easy to abuse.

## ☁️ Under ABAP Cloud

Most of this chapter describes on-premise techniques. In the ABAP Cloud development model the picture narrows sharply: according to the ABAP Keyword Documentation, only released APIs can be used or extended, so extension happens through **released** extension points — released BAdIs and released APIs — and through the extensibility options SAP documents for the cloud model. That is the practical meaning of "keep the core clean". The techniques above remain correct and necessary for the on-premise systems that run today; they simply are not the path for a cloud-model extension. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-what-changes-under-abap-cloud).

## ✅ Best Practices

- Prefer the **least invasive** technique available: released BAdI > BAdI > enhancement spot/point > customer exit > user exit > modification.
- Never modify standard SAP objects directly unless no other technique exists — modifications complicate every future upgrade and support package.
- Prefer **explicit** enhancement spots over implicit enhancement options. Implicit enhancements attach to code SAP never designed as an interface, so they break silently when that code changes.
- Document every enhancement with a comment referencing the business requirement or ticket.
- Keep enhancement implementations thin — call out to your own Z classes, behind an interface where tests need a double, rather than embedding large blocks of logic in an enhancement include — [Rules 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor) and [5.7](../docs/ABAP-Development-Rules.md#57-write-small-methods-that-do-one-thing-at-one-level-of-abstraction).
- Never `COMMIT WORK` in an exit or enhancement; SAP's surrounding code owns the transaction — [Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work).
- Report errors the way the hook provides (a return parameter, a message table, an exception); do not end SAP's processing with your own `MESSAGE … TYPE 'E'` unless the hook is meant for it — [section 6](../docs/ABAP-Development-Rules.md#6-error-handling).
- Code in an enhancement that reads or changes business data needs its own authorization check; SAP's checks around the hook do not cover what you add — [Rule 8.1](../docs/ABAP-Development-Rules.md#81-check-authorization-wherever-business-data-is-read-or-changed-and-evaluate-sy-subrc).
- Keep a register of your enhancements. They are the single easiest thing to lose track of before an upgrade.

## ⚠️ Common Mistakes

- Using a modification where a BAdI or enhancement point would have worked.
- **Confusing user exits with customer exits** — different mechanisms, different upgrade consequences.
- Forgetting that a customer exit (`SMOD`/`CMOD`) allows only **one active project** per enhancement, so two teams cannot implement it independently.
- Relying on implicit enhancement options in code that SAP may restructure at any support package.
- Committing inside an exit or enhancement, which closes SAP's transaction half-way.
- Not testing the enhanced flow against the *unenhanced* standard flow.

## 🎤 Interview & Review Checkpoints

- Rank the enhancement techniques by upgrade safety and justify the ranking.
- Explain the difference between a user exit, a customer exit, and a BAdI — precisely.
- Explain the difference between an explicit and an implicit enhancement, and why the latter is riskier.
- Explain what `SPAU` and `SPDD` are used for during an upgrade.
- Explain the relationship between `SMOD` (enhancement) and `CMOD` (project).
- Explain what changes about all of this under ABAP Cloud.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SMOD | Display/manage SAP enhancements (customer exits) |
| CMOD | Create the project that activates a customer exit |
| SE18 / SE19 | Define / implement a BAdI |
| SE80 | Enhancement spots and enhancement implementations |
| SPAU / SPDD | Adjust modifications (repository / Dictionary) during an upgrade |

## 🔗 Related Chapters

- [16-BADIs](../16-BADIs/README.md) — the preferred enhancement technique
- [10-Objects](../10-Objects/README.md) — interfaces for thin implementations
- [12-Selection-Screens](../12-Selection-Screens/README.md) — dynpro logic for screen exits
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle of exits, enhancements and modifications
