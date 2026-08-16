# 16 — BADIs (Business Add-Ins)

## 📖 Introduction

> **Lifecycle:** `CURRENT / RECOMMENDED` as an enhancement technique. BAdIs are the preferred way to extend standard SAP behaviour on-premise, and released BAdIs remain the supported extension point under ABAP Cloud. The **classic** BAdI mechanism (SE18/SE19 adapter classes) is `CLASSIC BUT STILL RELEVANT` — you will maintain plenty of it. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

A **BAdI** is SAP's object-oriented enhancement technique for injecting custom logic into standard SAP processes without modifying standard code. Unlike classic exits, BAdIs are interface-based and can support multiple, filter-dependent implementations.

## 🧩 Implementing a BAdI Interface Method

This example implements `IF_EX_ME_PROCESS_PO_CUST~PROCESS_ITEM`, a well-known Purchasing BAdI used to default and validate purchase order item data:

```abap
METHOD if_ex_me_process_po_cust~process_item.
  CONSTANTS lc_doc_type_standard   TYPE esart VALUE 'NB'.
  CONSTANTS lc_overdelivery_tol    TYPE uebto VALUE '8.0'.

  DATA lo_header   TYPE REF TO if_purchase_order_mm.
  DATA ls_header   TYPE mepoheader.
  DATA ls_item     TYPE mepoitem.
  DATA ls_previous TYPE mepoitem.

  lo_header = im_item->get_header( ).
  ls_header = lo_header->get_data( ).
  ls_item   = im_item->get_data( ).

  " On a brand-new item there is no previous version yet
  TRY.
      im_item->get_previous_data( IMPORTING ex_data = ls_previous ).
    CATCH cx_sy_itab_line_not_found.
      CLEAR ls_previous.
  ENDTRY.

  IF ls_header-bsart = lc_doc_type_standard AND ls_previous IS INITIAL.
    ls_item-uebto = lc_overdelivery_tol.
    ls_item-webre = abap_true.

    " WRITE THE DATA BACK. get_data( ) returns a COPY - changing ls_item
    " alone has no effect on the document.
    im_item->set_data( ls_item ).
  ENDIF.
ENDMETHOD.
```

> ⚠️ **The get / modify / `set_data( )` cycle is the whole pattern.** `get_data( )` hands you a copy of the item's data. Without the closing `set_data( )` call the BAdI runs, does its work, and silently changes nothing — a defect that passes code review easily because the business logic above it looks correct.

> 📝 **NEEDS OFFICIAL VERIFICATION** — check the exact signature of `get_previous_data( )` and the exception it raises in SE24 (`IF_PURCHASE_ORDER_ITEM_MM`) for your release before copying this pattern.

## 🧠 How This BAdI Implementation Works

1. `im_item->get_header( )` retrieves the PO header object, from which header-level data (`ls_header`, e.g. `bsart` — purchasing document type) can be read.
2. `im_item->get_data( )` retrieves the current item's data.
3. `im_item->get_previous_data( )` retrieves the item's data **before** the current change — wrapped in `TRY...CATCH cx_sy_itab_line_not_found` because on a brand-new item, there is no "previous" version yet.
4. The business logic then conditionally defaults fields (`uebto` — over-delivery tolerance, `webre` — GR-based invoice verification flag) only for new items (`ls_previous IS INITIAL`) of document type `'NB'` (standard PO).

## 🧱 BAdI Concepts Cheat Sheet

Two things are often conflated here, so keep them apart. **Which mechanism** a BAdI uses (classic vs. new) and **how many implementations** it permits (single-use vs. multiple-use) are independent properties.

**Mechanism — classic vs. new:**

| Concept | Description | Lifecycle |
|---|---|---|
| **Classic BAdI** | The original mechanism (SE18/SE19), based on generated adapter classes. Called via `CL_EXITHANDLER=>GET_INSTANCE`. | `CLASSIC BUT STILL RELEVANT` — widely present in existing systems |
| **New BAdI** | Part of the Enhancement Framework, defined inside an **enhancement spot** and called with the `GET BADI` / `CALL BADI` statements. Kernel-supported, faster, and supports fallback classes. | `CURRENT / RECOMMENDED` for on-premise enhancement |

**Cardinality and filtering — applies to either mechanism:**

| Concept | Description |
|---|---|
| **Single-use** | At most one implementation may be active at a time |
| **Multiple-use** | Several implementations may be active simultaneously; the order is not guaranteed |
| **Filter-dependent** | Implementations are activated only for specific filter values (e.g. per company code or document type) |
| **Fallback class** | (New BAdIs) A default implementation used when no customer implementation is active |

**Objects involved:**

| Concept | Description |
|---|---|
| **BAdI Definition** | Declares the interface, the cardinality and any filters (SE18, or an enhancement spot in SE80) |
| **BAdI Implementation** | Your class implementing that interface (SE19) |

```abap
" Calling a NEW BAdI from your own code
DATA lo_badi TYPE REF TO zsm_badi_pricing.

TRY.
    GET BADI lo_badi
      FILTERS doc_type = ls_header-bsart.

    CALL BADI lo_badi->adjust_price
      EXPORTING is_item  = ls_item
      CHANGING  cv_price = lv_price.

  CATCH cx_badi_not_implemented.
    " no active implementation - continue with the standard price
ENDTRY.
```

## ✅ Best Practices

- Always check whether the current context justifies your logic (as in the example: `bsart = 'NB'` and "only for new items"). BAdIs run for **every** call of the enhancement point, so guard your logic carefully to avoid side effects on unrelated document types.
- **Write your changes back** with the interface's setter (`set_data( )` and friends). Getters return copies.
- Keep BAdI implementations thin — delegate to a well-tested class/method rather than embedding complex logic in the implementation.
- Use constants rather than magic values for document types, tolerances and flags.
- Document *why* a BAdI was implemented (business requirement, ticket) in the implementing class — BAdIs are easy to lose track of during upgrades.

## ⚠️ Common Mistakes

- **Modifying a local copy and never calling the setter** — the implementation appears correct and does nothing.
- Forgetting to handle the case where `get_previous_data( )` finds no previous version (new item), causing an unhandled exception.
- Implementing overly broad logic that fires for all document types when only one case should be affected.
- Conflating "classic vs. new BAdI" with "single-use vs. multiple-use" — they are independent properties.
- Not testing with **both** create and change scenarios, since previous-data handling differs between them.

## 🎤 Interview & Review Checkpoints

- Explain the difference between a **BAdI**, a **customer exit** and a **classic user exit** (see [17-Enhancements](../17-Enhancements/README.md)).
- Explain the difference between the classic and new BAdI mechanisms, and separately between single-use and multiple-use.
- Explain what a fallback class is and when it applies.
- Walk through the get / modify / set cycle and say what happens if the set is missing.
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
- [17-Enhancements](../17-Enhancements/README.md)
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md)
