# CLAUDE.md — ABAPGuide

Coding rules: docs/ABAP-Development-Rules.md. Cite rules by number (Rule 2.6).

## Purpose and scope
- Practical ABAP engineering reference for productive on-premise landscapes,
  classic through modern (7.40-generation expression syntax and ABAP SQL).
- Out of scope: RAP, CDS, AMDP/code pushdown, ABAP Cloud beyond the
  boundary in Chapter 21 "What Changes Under ABAP Cloud". Do not add
  chapters on these; link to Chapter 21 "Scope Boundary" instead.
- ABAP Unit is Chapter 22 (`22-ABAP-Unit`); rule section 10 summarises,
  the chapter teaches.
- Mail is Chapter 24 (`24-Mail`). A reusable mail component belongs to
  the future ABAP-Cookbook; the chapter describes its design only.
- HTTP and REST is Chapter 25 (`25-HTTP-REST`). OData belongs to GWGuide
  and the future RAPGuide; link them, do not cover OData. A reusable REST
  client or handler component belongs to the future ABAP-Cookbook.
- Table maintenance is Chapter 26 (`26-Maintenance-Views`): Customizing
  tables, SE54/SM30, maintenance views, view clusters and the business
  configuration maintenance of ABAP Cloud. The RAP business object behind
  a business configuration app belongs to the future RAPGuide; the
  chapter describes the hand-over only.
- Lock objects are Chapter 27 (`27-Lock-Objects`): the SAP lock concept,
  generated ENQUEUE_/DEQUEUE_ modules and the released lock API. Locking
  in RAP belongs to the future RAPGuide; the chapter names the terms only.
- Adobe forms are Chapter 28 (`28-Adobe-Forms`): form interface and form in
  SFP, calling a form and getting the PDF, ADS as a prerequisite, and the
  released forms API of ABAP for Cloud Development. Layout design, ADS
  configuration and output management (NAST, PPF, BRF+ determination) stay
  out of scope; Smart Forms and SAPscript appear as lifecycle reference only.
- Transports and quality gates are Chapter 29 (`29-Transport-Quality-Gates`):
  packages and `$TMP`, the Change and Transport System, object locks in
  requests, transport in the SAP BTP ABAP environment, ATC and abaplint.
  Transport administration (routes, import queues, ChaRM) stays Basis
  work and out of scope.
- Development tools and AI assistance are Chapter 30
  (`30-Tools-AI-Assistance`): ADT, SAP GUI tools, source search, ABAP
  Cleaner, abapGit, AI assistants and MCP servers for ADT. Observed tool
  behaviour is VERSION-DEPENDENT and carries no system details or dates;
  community MCP servers are not named.
- Business workflow is Chapter 31 (`31-Business-Workflow`): SAP Business
  Workflow, BOR and IF_WORKFLOW classes, events and linkages, agents,
  work items, flexible workflow, and testing without a workflow. The My
  Inbox task UI belongs to UIGuide, RAP business events to RAPGuide, and
  SAP Build Process Automation to the SAP-Architecture-Guide; the chapter
  describes the hand-over only.
- IDoc and ALE are Chapter 32 (`32-IDoc-ALE`): IDoc structure, ports,
  partner profiles and the distribution model as configuration, outbound
  and inbound processing, monitoring, and testing without an IDoc. SAP
  Integration Suite and EDI landscapes belong to the SAP-Architecture-Guide,
  OData to GWGuide and RAP business events to RAPGuide; the chapter
  describes the hand-over only.
- The ABAP Dictionary is Chapter 33 (`33-ABAP-Dictionary`): domains, data
  elements, structures, table types, database tables with technical
  settings and indexes, foreign keys, check and text tables, search
  helps, changing an active table, enhancement categories and appends,
  classic Dictionary views as lifecycle reference, and what applies in
  ABAP for Cloud Development. CDS views, simple and enumerated types
  belong to CDSGuide, database-specific features to HANAGuide; buffering
  rules stay in 19 and table change logs in 26.
- Authorization checks are Chapter 34 (`34-Authorization-Checks`): the
  authorization concept, `AUTHORITY-CHECK`, where the check belongs, the
  check behind an interface, testing with the ABAP Unit authorization
  test environment, tracing a failed check, and authorization in ABAP
  for Cloud Development. Examples use the standard object `S_TABU_NAM`
  (Rule 8.2). CDS access control belongs to CDSGuide, RAP authorization
  to RAPGuide, business roles and catalogs to UIGuide; role and user
  administration are Basis work.
- Debugging is Chapter 23 (`23-Debugging-Troubleshooting`).
- Keep the folder name `18-Debugging`; its title is "Messages, Exceptions &
  Logging".
- Keep the folder name `14-Function-Modules`; its title is "Batch Input
  (BDC) & Calling Transactions".
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
  to the ABAP Keyword Documentation, or to SAP's documentation for the
  product when the feature is not a language feature.
- Callouts: `> ⚠️ **Bold claim.**` for pitfalls, `> 💡` for tips,
  `> 📝` for notes. One idea per callout.

## Code examples
- Fences are always ```` ```abap ````; mermaid only for flow diagrams.
  Configuration examples (JSON, Markdown) use ```` ```json ```` or
  ```` ```markdown ```` and carry `> 📝 **Configuration example** — …`.
- Snippets that assume surrounding declarations get
  `> 📝 **Contextual snippet** — <what is assumed>.` directly above or below.
  Self-contained programs need no label.
- Placeholder object names per Rule 2.6.
- Identifiers per Rules 2.1–2.5; legacy-labelled examples keep their
  construct but use current naming.
- Chapter 20 is Clean ABAP first; classic prefixes are described
  there as `CLASSIC BUT STILL RELEVANT`, because readers meet them in
  existing code.
- Comments in code use `"` and explain why, not what.
- DML examples target only custom Z tables; for SAP standard data point to
  BAPIs (Chapter 15). Reusable units never `COMMIT WORK`; only the caller does.
- Legacy constructs may be shown, but always labelled and paired with the
  current alternative.

## Links
- Relative links only: `[08-Open-SQL](../08-Open-SQL/README.md)`; link text
  is the folder name; for a file outside a chapter folder, the link text
  is its path, e.g. `docs/ABAP-Development-Rules.md`. Anchors use GitHub
  slugs including the emoji dash, e.g. `#-sap-luw--transaction-ownership`.
- Related Chapters list: `- [NN-Folder](../NN-Folder/README.md) — reason`;
  include Chapter 21 when the chapter carries lifecycle notes.
- For version questions link the ABAP Keyword Documentation (latest index
  URL as in the root README).
- External links are limited to official SAP documentation (help.sap.com,
  ABAP Keyword Documentation), SAP's Clean ABAP style guide, the sibling
  guides in github.com/serhatmercan, and the established open-source ABAP
  projects listed here:
  - abap2xlsx (https://github.com/abap2xlsx/abap2xlsx)
  - abapGit (https://github.com/abapGit/abapGit)
  - abaplint (https://github.com/abaplint/abaplint)
  - ABAP Cleaner (https://github.com/SAP/abap-cleaner)
  Link such a project instead of copying its code; add a project to this
  list before linking it.
