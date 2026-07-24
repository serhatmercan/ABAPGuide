# 17 — Enhancements

## 📖 Introduction

Beyond BAdIs ([16-BADIs](../16-BADIs/README.md)), SAP provides several other **enhancement techniques** to add custom logic to standard programs without modifying them directly. This chapter is a conceptual overview to complement the BAdI chapter, since enhancements are a closely related and frequently confused topic.

## 🧭 Enhancement Techniques Overview

| Technique | Introduced | Modifies Standard Code? | Multiple Implementations? | Typical Use |
|---|---|---|---|---|
| **User Exit** (`CALL CUSTOMER-FUNCTION`) | Classic (SD/MM legacy modules) | ❌ No (calls a predefined "hook") | ❌ No (one implementation via SMOD/CMOD) | Legacy SD/MM enhancements (e.g., `SAPMV45A` exits) |
| **BAdI** (Business Add-In) | 4.6+ | ❌ No | ✅ Yes (filter-dependent) | Modern, object-oriented enhancement points |
| **Enhancement Point / Section** | ECC 6.0+ (Enhancement Framework) | ❌ No (implicit "slots" in standard code) | ✅ Yes | Inserting custom code inside standard logic at pre-defined points |
| **Explicit Enhancement Spot** | ECC 6.0+ | ❌ No | ✅ Yes | Similar to enhancement points, but explicitly designed by SAP for extension |
| **Modification (Access Key)** | Classic | ✅ Yes (direct SAP object change) | N/A | Last resort — changes standard SAP code directly, at risk during upgrades |

## 🔧 User Exits (Classic)

User exits are empty `FORM` routines (`CALL CUSTOMER-FUNCTION 'xxx'`) built into certain standard programs, activated via a project in transaction `CMOD` referencing an SAP enhancement (`SMOD`).

```abap
" Inside a standard SAP program (not modifiable directly):
CALL CUSTOMER-FUNCTION '001'.

" Your implementation lives in an include like ZXVBFU01/EXIT_SAPMV45A_001,
" assigned via a CMOD project.
```

## 🧵 Enhancement Points & Implicit Enhancements

Implicit enhancement points/options exist automatically at the start/end of nearly every `FORM`, `METHOD`, and `PROGRAM` in the SAP system, viewable directly in the ABAP Editor via **Edit → Enhancement Operations → Show Implicit Enhancement Options**.

```abap
FORM standard_form.
  " ENHANCEMENT-POINT ep_standard_form_01 SPOTS es_standard_form.
  " your custom coding can be inserted here via an enhancement implementation
ENDFORM.
```

## 🆚 BAdI vs. User Exit vs. Enhancement Point

- **User Exit**: oldest, procedural, one implementation only, tied to a specific `SMOD` enhancement.
- **BAdI**: object-oriented, supports multiple filter-dependent implementations, the modern standard for "planned" extension points.
- **Enhancement Point/Spot**: allows inserting code almost *anywhere* in standard code (not just pre-planned hooks), even where SAP didn't explicitly design an extension point.

## ✅ Best Practices

- Always prefer the **least invasive** technique available: BAdI > Enhancement Spot/Point > User Exit > Modification.
- Never modify standard SAP objects directly (Access Key modifications) unless absolutely no other technique is available — modifications complicate every future upgrade/support package.
- Document every enhancement implementation with a clear comment referencing the business requirement/ticket number.
- Keep enhancement implementations thin — call out to your own Z classes/methods rather than embedding large blocks of logic directly in the enhancement include.

## ⚠️ Common Mistakes

- Using a modification when a BAdI or enhancement point would have worked — creates unnecessary upgrade risk.
- Forgetting that a classic user exit (`SMOD`/`CMOD`) only allows **one active project** per enhancement — conflicts arise if two teams try to implement the same user exit separately.
- Not testing enhancement implementations against the *unenhanced* standard flow, missing edge cases the enhancement doesn't cover.

## 🎤 Interview Tips

- Be ready to rank enhancement techniques by "upgrade safety" (BAdI/enhancement point > user exit > modification).
- Explain what SPAU/SPDD are used for during an upgrade (adjusting modifications).
- Explain the relationship between `SMOD` (enhancement) and `CMOD` (project) for classic user exits.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SMOD | Display/manage classic SAP enhancements |
| CMOD | Create a project to implement a classic user exit |
| SE18 / SE19 | Define/implement a BAdI |
| SPAU / SPDD | Adjust modifications and enhancements during an upgrade |

## 🔗 Related Chapters

- [16-BADIs](../16-BADIs/README.md)
- [10-Objects](../10-Objects/README.md)
