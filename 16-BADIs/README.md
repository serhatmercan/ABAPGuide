# 16 — BADIs (Business Add-Ins)

## 📖 Introduction

A **BAdI** is SAP's modern enhancement technique for injecting custom logic into standard SAP processes without modifying standard code. Unlike classic user exits, BAdIs are object-oriented (interface-based) and support multiple, filter-dependent implementations.

## 🧩 Implementing a BAdI Interface Method

This example implements `IF_EX_ME_PROCESS_PO_CUST~PROCESS_ITEM`, a well-known Purchasing BAdI used to default/validate purchase order item data:

```abap
METHOD if_ex_me_process_po_cust~process_item.
  DATA lo_header   TYPE REF TO if_purchase_order_mm.
  DATA ls_header   TYPE mepoheader.
  DATA ls_item     TYPE mepoitem.
  DATA ls_previous TYPE mepoitem.

  lo_header = im_item->get_header( ).
  ls_header = lo_header->get_data( ).
  ls_item = im_item->get_data( ).

  TRY.
      im_item->get_previous_data( IMPORTING ex_data = ls_previous ).
    CATCH cx_sy_itab_line_not_found.
      CLEAR ls_previous.
  ENDTRY.

  IF ls_header-bsart = 'NB' AND ls_previous IS INITIAL.
    ls_item-uebto = 8.
    ls_item-webre = 'X'.
  ENDIF.
ENDMETHOD.
```

## 🧠 How This BAdI Implementation Works

1. `im_item->get_header( )` retrieves the PO header object, from which header-level data (`ls_header`, e.g. `bsart` — purchasing document type) can be read.
2. `im_item->get_data( )` retrieves the current item's data.
3. `im_item->get_previous_data( )` retrieves the item's data **before** the current change — wrapped in `TRY...CATCH cx_sy_itab_line_not_found` because on a brand-new item, there is no "previous" version yet.
4. The business logic then conditionally defaults fields (`uebto` — over-delivery tolerance, `webre` — GR-based invoice verification flag) only for new items (`ls_previous IS INITIAL`) of document type `'NB'` (standard PO).

## 🧱 BAdI Concepts Cheat Sheet

| Concept | Description |
|---|---|
| **BAdI Definition** | Declares the interface and enhancement spot (done by SAP or a custom developer via SE18/`transaction`) |
| **BAdI Implementation** | Your custom class implementing the interface (SE19) |
| **Filter-dependent BAdI** | Allows multiple implementations, active only for specific filter values (e.g., per company code) |
| **Classic (single-use) BAdI** | Only one active implementation allowed system-wide |
| **New BAdI (Enhancement Spot)** | Supports multiple simultaneous active implementations |

## ✅ Best Practices

- Always check whether the current context justifies your logic (as in the example: `bsart = 'NB'` and "only for new items") — BAdIs run for **every** call of the enhancement spot, so guard your logic carefully to avoid unintended side effects on unrelated document types.
- Keep BAdI implementations thin — delegate to a well-tested class/method rather than embedding complex logic directly in the implementation.
- Document *why* a BAdI was implemented (business requirement) directly in the implementing class, since BAdIs are easy to "lose track of" during upgrades.

## ⚠️ Common Mistakes

- Forgetting to handle the case where `get_previous_data` raises `cx_sy_itab_line_not_found` (new item) — causes an unhandled exception/dump.
- Implementing overly broad logic that fires for all document types/scenarios when only one specific case should be affected.
- Not testing the BAdI implementation with **both** create and change scenarios, since `im_item->get_previous_data` behaves differently in each.

## 🎤 Interview Tips

- Explain the difference between a **BAdI** and a **classic user exit** (see [17-Enhancements](../17-Enhancements/README.md)).
- Be ready to explain filter-dependent vs. classic BAdIs, and multiple-use vs. single-use.
- Know the transaction codes to define (SE18) and implement (SE19) a BAdI.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE18 | Define a BAdI (Enhancement Spot) |
| SE19 | Create/manage a BAdI implementation |
| SPRO | Business Add-Ins customizing activation (for some BAdIs) |

## 🔗 Related Chapters

- [10-Objects](../10-Objects/README.md) — interfaces and OOP concepts used by BAdIs
- [17-Enhancements](../17-Enhancements/README.md)
