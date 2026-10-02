# CLAUDE.md — ABAPGuide

Coding rules: docs/ABAP-Development-Rules.md (planned; until it exists, follow the existing chapters).

## Purpose and scope
- Practical ABAP engineering reference for productive on-premise landscapes,
  classic through modern (7.40-generation expression syntax and ABAP SQL).
- Out of scope: RAP, CDS, AMDP/code pushdown, ABAP Unit/TDD, ABAP Cloud
  beyond the boundary in Chapter 21 "What Changes Under ABAP Cloud". Do not
  add chapters on these; link to Chapter 21 "Scope Boundary" instead.
- CDS appears in this guide only as a data source of ABAP SQL reads;
  anything beyond that links to CDSGuide
  (https://github.com/serhatmercan/CDSGuide).
- Chapter 21 is the lifecycle map. Any new or reclassified technology must
  fit its tables; update Chapter 21 when a classification changes.
- Call a construct "obsolete" or "deprecated" only when the ABAP Keyword
  Documentation does, and use its wording.
- Write SQL as "ABAP SQL"; "Open SQL" only as the historical name. Keep the
  folder name `08-Open-SQL`.

## Structure
- Chapter folder `NN-Title-Words/README.md`; title `# NN — Title` (em dash).
- Section order: `## 📖 Introduction` → topic sections → `## ✅ Best Practices`
  → `## ⚠️ Common Mistakes` → `## 🎤 Interview & Review Checkpoints`
  → `## 🖥️ Related Transaction Codes` (optional) → `## 🔗 Related Chapters`.
- Every `##` heading starts with one emoji.
- Deliberate gaps inside a chapter go in a `## 🧭 Scope Note` section,
  normally placed before Best Practices.
- Topic snippets that span chapters belong in `Examples/`; add them to the
  table in `Examples/README.md`.
- New chapters: add a row to the root README Chapter Reference table and,
  if relevant, to Find It Fast.

## Labels
- Exactly five lifecycle labels: `CURRENT / RECOMMENDED`,
  `CLASSIC BUT STILL RELEVANT`, `LEGACY / HISTORICAL REFERENCE`,
  `ABAP CLOUD / MODERN CONTEXT`, `VERSION-DEPENDENT`.
- Lifecycle note format: ``> **Lifecycle:** `LABEL`. <one or two sentences>``.
  Chapter-level notes go directly under the title or Introduction; legacy
  notes state what replaces the construct and link to Chapter 21.
- Version notes: `> ⚠️ **VERSION-DEPENDENT: <feature>.** <text>` and point
  to the ABAP Keyword Documentation.
- Callouts: `> ⚠️ **Bold claim.**` for pitfalls, `> 💡` for tips,
  `> 📝` for notes. One idea per callout.

## Code examples
- Fences are always ```` ```abap ````; mermaid only for flow diagrams.
- Snippets that assume surrounding declarations get
  `> 📝 **Contextual snippet** — <what is assumed>.` directly above or below.
  Self-contained programs need no label.
- Placeholder objects use `ZSM_` plus a type infix: `zsm_t_` database
  table only, `zsm_tt_` table type, `zsm_s_` structure, `zsm_e_` data
  element, `zsm_r_` report, `zsm_msg` message class; classes `zcl_`,
  exceptions `zcx_`, interfaces `zif_`.
- ABAP naming follows SAP's Clean ABAP style guide: descriptive names
  without type or scope prefixes (`sales_orders`, not `lt_vbak`).
  Exceptions: names fixed by a signature you do not own (SEGW-generated
  methods and types, BAPI and function module interfaces, inherited or
  interface methods) stay as they are. Existing examples are migrated in
  the planned chapter pass; legacy-labelled examples keep their construct
  but use current naming.
- Chapter 20 becomes Clean ABAP first; classic prefixes are described
  there as `CLASSIC BUT STILL RELEVANT`, because readers meet them in
  existing code.
- Comments in code use `"` and explain why, not what.
- DML examples target only custom Z tables; for SAP standard data point to
  BAPIs (Chapter 15). Reusable units never `COMMIT WORK`; only the caller does.
- Legacy constructs may be shown, but always labelled and paired with the
  current alternative.

## Links
- Relative links only: `[08-Open-SQL](../08-Open-SQL/README.md)`; link text
  is the folder name. Anchors use GitHub slugs including the emoji dash,
  e.g. `#-sap-luw--transaction-ownership`.
- Related Chapters list: `- [NN-Folder](../NN-Folder/README.md) — reason`;
  include Chapter 21 when the chapter carries lifecycle notes.
- For version questions link the ABAP Keyword Documentation (latest index
  URL as in the root README).
- External links are limited to official SAP documentation (help.sap.com,
  ABAP Keyword Documentation), SAP's Clean ABAP style guide, and the
  sibling guides in github.com/serhatmercan.
