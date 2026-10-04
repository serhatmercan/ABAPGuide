# 16 — BADIs (Business Add-Ins)

## 📖 Introduction

> **Lifecycle:** `CURRENT / RECOMMENDED` as an enhancement technique. BAdIs are the preferred way to extend standard SAP behaviour on-premise, and released BAdIs remain the supported extension point under ABAP Cloud. The **classic** BAdI mechanism (SE18/SE19 adapter classes) is `CLASSIC BUT STILL RELEVANT` — you will maintain plenty of it. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

A **BAdI** is SAP's object-oriented enhancement technique for injecting custom logic into standard SAP processes without modifying standard code. Unlike classic exits, BAdIs are interface-based and can support multiple, filter-dependent implementations.

## 🧩 Implementing a BAdI Interface Method

This example implements `IF_EX_ME_PROCESS_PO_CUST~PROCESS_ITEM`, a well-known Purchasing BAdI used to default and validate purchase order item data:

> 📝 **Contextual snippet** — the method of a BAdI implementing class for `ME_PROCESS_PO_CUST`; `im_item` and the other parameter names are fixed by the SAP interface ([Rule 2.4](../docs/ABAP-Development-Rules.md#24-keep-names-that-are-fixed-by-a-signature-you-do-not-own)). `'NB'` is SAP's standard purchase order type; the tolerance is a placeholder value.

```abap
METHOD if_ex_me_process_po_cust~process_item.
  CONSTANTS standard_order_type    TYPE esart VALUE 'NB'.
  CONSTANTS overdelivery_tolerance TYPE uebto VALUE '8.0'.

  DATA header             TYPE REF TO if_purchase_order_mm.
  DATA header_data        TYPE mepoheader.
  DATA item_data          TYPE mepoitem.
  DATA previous_item_data TYPE mepoitem.

  header      = im_item->get_header( ).
  header_data = header->get_data( ).
  item_data   = im_item->get_data( ).

  " A brand-new item has no previous version; the method reports that
  " through its classic exception NO_DATA
  im_item->get_previous_data( IMPORTING  ex_data = previous_item_data
                              EXCEPTIONS no_data = 1
                                         OTHERS  = 2 ).
  DATA(is_new_item) = xsdbool( sy-subrc = 1 ).

  IF header_data-bsart = standard_order_type AND is_new_item = abap_true.
    item_data-uebto = overdelivery_tolerance.
    item_data-webre = abap_true.

    " WRITE THE DATA BACK. get_data( ) returns a COPY - changing item_data
    " alone has no effect on the document.
    im_item->set_data( item_data ).
  ENDIF.
ENDMETHOD.
```

> ⚠️ **The get / modify / `set_data( )` cycle is the whole pattern.** `get_data( )` hands you a copy of the item's data. Without the closing `set_data( )` call the BAdI runs, does its work, and silently changes nothing — a defect that passes code review easily because the business logic above it looks correct.

## 🧠 How This BAdI Implementation Works

1. `im_item->get_header( )` retrieves the PO header object, from which header-level data (`header_data`, e.g. `bsart` — purchasing document type) can be read.
2. `im_item->get_data( )` retrieves the current item's data.
3. `im_item->get_previous_data( )` retrieves the item's data **before** the current change. On a brand-new item there is no previous version, and the method raises its classic exception `NO_DATA`, which sets `sy-subrc`.
4. The business logic then conditionally defaults fields (`uebto` — over-delivery tolerance, `webre` — GR-based invoice verification flag) only for new items of document type `'NB'` (standard PO).

> 💡 The same BAdI separates the steps: the process methods change data, and its `CHECK` method validates the whole document and reports a failed check through its changing parameter `CH_FAILED`. Put each piece of logic into the method meant for it.

## 🛠️ Implementing a BAdI in SE19

1. Find the BAdI and display its definition in `SE18`: the interface, whether it is single- or multiple-use, its filters and, for a new BAdI, its enhancement spot.
2. In `SE19`, create an enhancement implementation for the enhancement spot (for a classic BAdI, a classic implementation), with a name in your namespace and a short text.
3. Create the BAdI implementation and its implementing class. If the BAdI provides an example class, the dialog offers to start with an empty class, to copy the example class, or to inherit from it.
4. Implement the interface methods you need, set filter values if the BAdI has filters, and activate the implementation.

> 💡 Some BAdIs extend screens instead of logic: the implementation returns the program and screen number of a subscreen of your own, which the standard screen then shows, for example as an extra tab.

## 🧱 BAdI Concepts Cheat Sheet

Two things are often conflated here, so keep them apart. **Which mechanism** a BAdI uses (classic vs. new) and **how many implementations** it permits (single-use vs. multiple-use) are independent properties.

**Mechanism — classic vs. new:**

| Concept | Description | Lifecycle |
|---|---|---|
| **Classic BAdI** | The original mechanism (SE18/SE19), based on generated adapter classes and processed in the BAdI Builder. Called via `CL_EXITHANDLER=>GET_INSTANCE`, which returns the instance in its changing parameter `INSTANCE`. | `CLASSIC BUT STILL RELEVANT` — widely present in existing systems |
| **New BAdI** | Part of the Enhancement Framework, defined inside an **enhancement spot** and called with the `GET BADI` / `CALL BADI` statements. Supports fallback classes and the Switch Framework. | `CURRENT / RECOMMENDED` for on-premise enhancement |

**Cardinality and filtering — applies to either mechanism:**

| Concept | Description |
|---|---|
| **Single-use** | Exactly one implementation must be available for each use; without one (and without a fallback class) `GET BADI` raises `CX_BADI_NOT_IMPLEMENTED` |
| **Multiple-use** | Several implementations may be active simultaneously; `CALL BADI` calls them in the same order every time, and the predefined BAdI `BADI_SORTER` sets that order explicitly |
| **Filter-dependent** | Implementations are activated only for specific filter values (e.g. per company code or document type); `GET BADI` must supply a value for every filter |
| **Fallback class** | (New BAdIs) Part of the BAdI definition; used when no implementation matches. The ABAP Keyword Documentation recommends one for single-use BAdIs |

**Objects involved:**

| Concept | Description |
|---|---|
| **BAdI Definition** | Declares the interface, the cardinality and any filters (SE18, or an enhancement spot in SE80) |
| **BAdI Implementation** | Your class implementing that interface (SE19) |

> 📝 BAdIs are not limited to business processes. The classic BAdI `CTS_REQUEST_CHECK`, for example, offers the method `CHECK_BEFORE_RELEASE` for checks before a transport request is released; it receives the request and its objects and can stop the release with its exception `CANCEL`.

> 📝 **Contextual snippet** — `zsm_badi_pricing` is a placeholder single-use BAdI with the filter `doc_type` and the method `adjust_price`; `header_data`, `item_data` and `price` are assumed.

```abap
" Calling a NEW BAdI from your own code
DATA pricing_badi TYPE REF TO zsm_badi_pricing.

TRY.
    GET BADI pricing_badi
      FILTERS doc_type = header_data-bsart.

    CALL BADI pricing_badi->adjust_price
      EXPORTING item  = item_data
      CHANGING  price = price.

  CATCH cx_badi_not_implemented.
    " no active implementation and no fallback class - continue with the standard price
ENDTRY.
```

> 📝 For a multiple-use BAdI, `GET BADI` raises no exception when there is no implementation, and `CALL BADI` then simply has no effect.

## ✅ Best Practices

- Always check whether the current context justifies your logic (as in the example: `bsart = 'NB'` and "only for new items"). BAdIs run for **every** call of the enhancement point, so guard your logic carefully to avoid side effects on unrelated document types.
- **Write your changes back** with the interface's setter (`set_data( )` and friends). Getters return copies.
- Keep BAdI implementations thin: map the BAdI parameters and call a class that holds the logic behind an interface, so it can be tested with a double — [Rules 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor) and [5.7](../docs/ABAP-Development-Rules.md#57-write-small-methods-that-do-one-thing-at-one-level-of-abstraction).
- Never `COMMIT WORK` in a BAdI implementation; it runs inside SAP's transaction, which SAP's code owns — [Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work).
- Handle the classic exceptions and the `sy-subrc` of the methods you call, and report errors the way the BAdI interface provides (a failure parameter, a message table or an exception) — [section 6](../docs/ABAP-Development-Rules.md#6-error-handling).
- Use constants rather than magic values for document types, tolerances and flags — [Rule 4.1](../docs/ABAP-Development-Rules.md#41-replace-magic-literals-with-named-constants).
- Give single-use BAdIs you define a fallback class.
- Document *why* a BAdI was implemented (business requirement, ticket) in the implementing class — BAdIs are easy to lose track of during upgrades.

## ⚠️ Common Mistakes

- **Modifying a local copy and never calling the setter** — the implementation appears correct and does nothing.
- Forgetting to handle the case where `get_previous_data( )` finds no previous version (new item), so the exception `NO_DATA` goes unhandled.
- Changing data without setting the "changed" indicator that some BAdIs expect in a `CHANGING` parameter.
- Implementing overly broad logic that fires for all document types when only one case should be affected.
- Conflating "classic vs. new BAdI" with "single-use vs. multiple-use" — they are independent properties.
- Relying on a particular order of multiple implementations without defining it through `BADI_SORTER`.
- Not testing with **both** create and change scenarios, since previous-data handling differs between them.

## 🎤 Interview & Review Checkpoints

- Explain the difference between a **BAdI**, a **customer exit** and a **classic user exit** (see [17-Enhancements](../17-Enhancements/README.md)).
- Explain the difference between the classic and new BAdI mechanisms, and separately between single-use and multiple-use.
- Explain what a fallback class is and when it applies.
- Walk through the get / modify / set cycle and say what happens if the set is missing.
- Explain when `GET BADI` raises `CX_BADI_NOT_IMPLEMENTED`, and why a multiple-use BAdI does not.
- Know the transactions to define (SE18) and implement (SE19) a BAdI.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE18 | BAdI Builder — define a BAdI / display an enhancement spot |
| SE19 | BAdI Builder — create and manage a BAdI implementation |
| SE80 | Enhancement spots and enhancement implementations |
| SPRO | Customizing activation for some BAdIs |

## 🔗 Related Chapters

- [10-Objects](../10-Objects/README.md) — interfaces and OOP concepts used by BAdIs
- [12-Selection-Screens](../12-Selection-Screens/README.md) — subscreens for screen-enhancing BAdIs
- [17-Enhancements](../17-Enhancements/README.md) — exits, enhancement points and modifications
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — where BAdIs sit, and extension under ABAP Cloud
