# 29 — Transport and Quality Gates

> **Lifecycle:** `CURRENT / RECOMMENDED`. The Change and Transport System and the ABAP Test Cockpit are how Standard ABAP moves changes and checks them on the way. In the SAP BTP ABAP environment, changes travel as software components with Git underneath: `ABAP CLOUD / MODERN CONTEXT`. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

A change is written once, in a development system. It reaches the test and production systems only as part of a transport request. What leaves the development system therefore decides what production runs, and the moment of release is the last place where a team can stop a defect cheaply.

This chapter covers:

- packages, `$TMP` and local objects;
- the Change and Transport System: requests, tasks, release and import;
- object locks in requests, and the system change option;
- request hygiene and the errors that block a release;
- transport in the SAP BTP ABAP environment, as far as it was verified;
- ATC: checks, check variants, exemptions and the check at release;
- abaplint and continuous integration as optional additions.

Transport administration (transport routes, import queues, file transfer) belongs to Basis and is outside this guide; see the [Scope Note](#-scope-note). The tools that developers use every day are the topic of [30-Tools-AI-Assistance](../30-Tools-AI-Assistance/README.md).

## 🗺️ Standard ABAP and SAP BTP ABAP Environment at a Glance

| Topic | Standard ABAP | SAP BTP ABAP environment |
|---|---|---|
| Unit of transport | Transport request with tasks | Software component, transported through Git **[verify: the transport flow and apps in your SAP BTP ABAP environment]** |
| Tools | `SE09`/`SE10`, `SE01`, `SE03`, `STMS` | ADT and the administration apps **[verify]** |
| Local objects | `$TMP` (software component `LOCAL`) | Observed: creating an object in `$TMP` was refused; development took place in a package below `ZLOCAL` |
| Static checks | ATC, Code Inspector (`SCI`), extended program check | ATC |
| Check variants | Team variant; `ABAP_CLOUD_READINESS` for cloud readiness | `ABAP_CLOUD_DEVELOPMENT_DEFAULT` and further SAP variants |
| Release-file status | `TR_*` function modules and table `TADIR`: not to be released | Released: the CTS classes of the XCO library, `CL_SATC_API` |

The release states come from SAP's lists of released and classified objects.

## 📦 Packages, `$TMP` and Local Objects

Every repository object belongs to a **package**. A package names its software component and its transport layer, and those two decide whether and where its objects travel. In the on-premise system used for this chapter, the package `$TMP` belongs to the software component `LOCAL`, has no transport layer, and its own description says that its objects are never transported.

- **Local objects** (`$TMP`) are for experiments and test objects. They cannot be transported. Work that should reach another system starts in a transportable package, or is moved into one with `SE03` *Change Object Directory Entries* before anyone builds on it.
- **Transportable packages** are created with the team's software component and transport layer. The naming table of the rules applies to packages as well ([Rule 2.6](../docs/ABAP-Development-Rules.md#26-name-development-objects-by-the-object-naming-table)).
- **SAP BTP ABAP environment:** in the system used for this chapter, creating a class in `$TMP` was refused for lack of authorization; test objects were created in a package below `ZLOCAL`, whose software component is `ZLOCAL` and whose default ABAP language version is ABAP for Cloud Development.

> ⚠️ **Do not change the object directory with your own code.** A report that updates `TADIR` to "fix" a package or an original system bypasses the Transport Organizer and its checks. SAP's release information classifies `TADIR` as not to be released and names `I_CUSTABAPOBJDIRECTORYENTRY` as its successor for reading. To change a package assignment, use `SE03`.

## 🚚 The Change and Transport System

According to SAP's documentation, the Transport Organizer records changes in **change requests** of two kinds:

- **Workbench requests** record repository objects and cross-client Customizing.
- **Customizing requests** record client-specific Customizing, from the client in which it was changed. Whether changes are recorded automatically is set per client; table entries maintained through a generated dialog are recorded as shown in [26-Maintenance-Views](../26-Maintenance-Views/README.md#-recording-and-transporting-customizing).

Developers work in **tasks** that belong to a request; the tasks are released first, then the request **[verify: request types, task types and the release sequence in your release]**. **Transports of copies** are a further request type; SAP's documentation names them as an exception to the rule that all objects of a request must be locked before release. Local change requests, which have no target system, exist as well **[verify]**.

The transactions:

| T-code | Purpose |
|---|---|
| `SE09`, `SE10` | Transport Organizer: your requests and tasks |
| `SE01` | Transport Organizer, extended view |
| `SE03` | Transport Organizer Tools: search, object directory, unlock, system change option |
| `STMS` | Transport Management System: import queues and routes (Basis) |

Releasing a request ends the work on it; importing it into the next system is done in `STMS`, usually by Basis or by an approved process **[verify: what release and import do in detail in your landscape]**. The checks therefore happen before the release.

## 🔒 Object Locks in Requests (SE03)

According to SAP's documentation, the first user who changes a lockable object assigns it to a change request, and the object is then locked: only users with a task in that request can change it. The lock ends when the request is released. Objects entered in an object list by hand are not locked until someone locks them in `SE09`, and a request can normally be released only when all its objects are locked.

The lock protects the order of changes: two requests cannot carry two versions of one object into production in the wrong sequence.

`SE03` offers *Unlock Objects (Expert Tool)*, which removes these locks from a request **[verify: what the tool changes, the authorization it needs and the risks SAP states]**. Use it only when the owner of the request agrees and the consequences in the target systems are understood; never to get around a colleague's lock.

**System change option.** Whether objects may be changed at all is set per system, software component and namespace (`SE03` → *Set System Change Option*, or `SE06`). The error that the system setting does not allow changes means this option, not a missing authorization. Changing it is a Basis task **[verify: the menu path in your release]**.

## 🔧 Request Hygiene and Common Release Errors

- **One logical change per request.** A request that mixes two changes cannot be imported, tested or rolled back separately ([Rule 13.7](../docs/ABAP-Development-Rules.md#137-bundle-one-logical-change-per-transport-request-and-release-it-only-after-the-checks-of-131)).
- **The checks run before the release.** Syntax check, ABAP Unit and ATC with the team variant ([Rule 13.1](../docs/ABAP-Development-Rules.md#131-release-nothing-that-fails-the-syntax-check-abap-unit-or-atc-with-the-team-check-variant)).
- **A syntax error in one object blocks the release** of the request. Fix the object; do not move it to another request to get the rest through.
- **Deleted objects in a request:** a request can still contain an object that was deleted in the meantime; the release reports it. Remove the entry or keep it with its deletion flag, as the message says.
- **Objects created without a request** (for example as local objects) need a transport entry before they can travel; in the Object Navigator, the context menu offers *Write Transport Entry* **[verify: the menu path in your release]**.
- **Standard texts** (`SO10`) are not recorded automatically; the program `RSTXTRAN`, titled as taking SAPscript texts into a request, adds them.
- **Check what a request overwrites** before release: `SE03` analyses the objects in requests; a self-written report that reads `TADIR` or the `TR_*` modules is not needed and relies on objects that SAP classifies as not to be released.

**Checks before release in code.** Standard ABAP has a classic BAdI for checks around requests; its interface `IF_EX_CTS_REQUEST_CHECK` has, among others, the method `CHECK_BEFORE_RELEASE`, which receives the request, its type, owner and objects, can change the short text and raises `CANCEL` to stop the release. Keep the implementation thin and put the rule into a class that can be tested.

**Example X4 — the release rule behind an interface.** Target: Standard ABAP and ABAP for Cloud Development. The rule: every request names its ticket, for example `ZSM-123`.

```abap
"! Checks the short text of a transport request before it is released.
INTERFACE zif_zsm_request_check PUBLIC.
  TYPES: BEGIN OF ENUM problem,
           none,
           missing_short_text,
           missing_ticket_reference,
         END OF ENUM problem.
  TYPES problems TYPE STANDARD TABLE OF problem WITH EMPTY KEY.

  "! @parameter short_text | Short text of the request
  "! @parameter result | Problems found; empty if the request may be released
  METHODS problems_of
    IMPORTING short_text    TYPE csequence
    RETURNING VALUE(result) TYPE problems.
ENDINTERFACE.
```

```abap
"! The team's release rule for transport requests: every request names
"! the ticket it belongs to, for example ZSM-123 (Rule 13.7).
CLASS zcl_zsm_request_check DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_zsm_request_check.

  PRIVATE SECTION.
    " A ticket reference: project key in capitals, hyphen, number
    CONSTANTS ticket_pattern TYPE string VALUE `\b[A-Z][A-Z0-9]+-[0-9]+\b`.
ENDCLASS.


CLASS zcl_zsm_request_check IMPLEMENTATION.
  METHOD zif_zsm_request_check~problems_of.
    IF condense( short_text ) = ``.
      result = VALUE #( ( zif_zsm_request_check=>missing_short_text ) ).
      RETURN.
    ENDIF.

    IF find( val = short_text pcre = ticket_pattern ) = -1.
      INSERT zif_zsm_request_check=>missing_ticket_reference INTO TABLE result.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

> ⚠️ **A built-in function cannot be the operand of `IS INITIAL`.** The first version wrote `IF condense( short_text ) IS INITIAL`, and activation failed in both systems with "Unexpected operator IS"; the comparison with an empty string replaced it.

The test include:

```abap
CLASS ltc_request_check DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_zsm_request_check.

    METHODS setup.
    METHODS accepts_text_with_ticket FOR TESTING.
    METHODS reports_missing_ticket FOR TESTING.
    METHODS reports_empty_text FOR TESTING.
    METHODS rejects_lowercase_key FOR TESTING.
ENDCLASS.


CLASS ltc_request_check IMPLEMENTATION.
  METHOD setup.
    cut = NEW zcl_zsm_request_check( ).
  ENDMETHOD.

  METHOD accepts_text_with_ticket.
    " when
    DATA(problems) = cut->problems_of( `ZSM-123 Order release: check credit limit` ).

    " then
    cl_abap_unit_assert=>assert_initial( problems ).
  ENDMETHOD.

  METHOD reports_missing_ticket.
    " when
    DATA(problems) = cut->problems_of( `Order release: check credit limit` ).

    " then
    cl_abap_unit_assert=>assert_equals(
        act = problems
        exp = VALUE zif_zsm_request_check=>problems( ( zif_zsm_request_check=>missing_ticket_reference ) ) ).
  ENDMETHOD.

  METHOD reports_empty_text.
    " when
    DATA(problems) = cut->problems_of( `   ` ).

    " then
    cl_abap_unit_assert=>assert_equals(
        act = problems
        exp = VALUE zif_zsm_request_check=>problems( ( zif_zsm_request_check=>missing_short_text ) ) ).
  ENDMETHOD.

  METHOD rejects_lowercase_key.
    " when: the project key must be written as the ticket system writes it
    DATA(problems) = cut->problems_of( `zsm-123 order release` ).

    " then
    cl_abap_unit_assert=>assert_equals(
        act = problems
        exp = VALUE zif_zsm_request_check=>problems( ( zif_zsm_request_check=>missing_ticket_reference ) ) ).
  ENDMETHOD.
ENDCLASS.
```

**The BAdI method stays thin.**

> 📝 **Contextual snippet** — the method of a class that implements the classic BAdI interface `IF_EX_CTS_REQUEST_CHECK` (created in `SE19`, [16-BADIs](../16-BADIs/README.md)); `zsm_msg` is the placeholder message class with message 020. The method raises the classic exception `CANCEL`, which the BAdI interface defines, with `MESSAGE … RAISING`, so the message reaches the Transport Organizer. Standard ABAP only.

```abap
METHOD if_ex_cts_request_check~check_before_release.
  " The rule lives in a tested class; this method only connects it
  DATA(problems) = NEW zcl_zsm_request_check( )->zif_zsm_request_check~problems_of( text ).
  IF problems IS NOT INITIAL.
    MESSAGE e020(zsm_msg) WITH request RAISING cancel.
  ENDIF.
ENDMETHOD.
```

> 📝 **Activation record.** X4 (`zif_zsm_request_check`, `zcl_zsm_request_check` with its test include) was activated in both ABAP language versions: Standard ABAP and ABAP for Cloud Development. The first activation of the class failed in both with "Unexpected operator IS" (callout above) and passed after the fix. The 4 test methods were run in both versions, and the test run passed. The active versions were read back after activation and matched the sources. The check tools returned no warnings. The BAdI method is a contextual snippet and was not created. No transport request was created, changed or released.

## ☁️ Transport in the SAP BTP ABAP Environment

The SAP BTP ABAP environment has no `STMS`. Development objects belong to software components, and each software component is backed by a Git repository that SAP manages; releasing a transport request in such a system pushes the change to that repository, and a target system pulls it **[verify: the release, export and import steps and the apps that perform them in your SAP BTP ABAP environment]**. The package in which test objects were created for this chapter belongs to the software component `ZLOCAL`, which is meant for local development.

In Standard ABAP, Git-based transport exists as the Git-enabled Change and Transport System (gCTS), next to the classic CTS **[verify: availability in your release]**. Released ABAP APIs for transports are the CTS classes of the XCO library (for example `CL_XCO_CTS_CHANGE`); the `TR_*` function modules are classified as not to be released.

## ✅ ATC: Checks, Variants and Exemptions

The **ABAP Test Cockpit** runs static checks, ABAP Unit tests and further checks on a set of objects and shows the findings in one list. It builds on the checks of the Code Inspector (`SCI`), which remains available on-premise, together with the extended program check, for example its warning about a field read before it is written.

- **Check variants** decide which checks run. A team uses one shared variant, so that every developer sees the same result ([Rule 13.1](../docs/ABAP-Development-Rules.md#131-release-nothing-that-fails-the-syntax-check-abap-unit-or-atc-with-the-team-check-variant)). SAP delivers variants such as `ABAP_CLOUD_READINESS` (found on both systems used for this chapter) and, in the SAP BTP ABAP environment, `ABAP_CLOUD_DEVELOPMENT_DEFAULT`. SAP's release information marks `SAP_CLOUD_PLATFORM_ATC_DEFAULT` as deprecated, with `ABAP_CLOUD_DEVELOPMENT_DEFAULT` as successor. Cloud readiness is discussed in [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-what-changes-under-abap-cloud) ([Rule 13.3](../docs/ABAP-Development-Rules.md#133-run-the-cloud-readiness-check-wherever-section-1-applies)).
- **Object sets** select what is checked: a package, a request, a list of objects.
- **Running ATC:** from the editor or the project in ADT, from transaction `ATC` (administration) on-premise, or in a pipeline ([22-ABAP-Unit](../22-ABAP-Unit/README.md#-running-the-tests)).
- **Exemptions:** a finding that is correct but must stay is exempted, not ignored ([Rule 13.2](../docs/ABAP-Development-Rules.md#132-fix-every-atc-finding-or-exempt-it-with-a-written-reason)). According to SAP's documentation, the exemption request names at least an approver and a reason, and a quality manager approves it. Exemptions can cover one finding or larger scopes; choose the smallest that fits.
- **ATC at release:** according to SAP's documentation, ATC can check the objects of a request when it is released, as a quality gate for code leaving the development system; in a landscape with a central check system, mass checks and exemptions are managed there. Whether findings block the release is a setting of the landscape **[verify: the release policy options in your release]**.
- **Quick fixes** offered by ATC change code; review them like any other change.

Claim a check only after it ran ([Rule 13.5](../docs/ABAP-Development-Rules.md#135-claim-a-check-in-the-guides-only-after-it-ran-and-record-it)), and never call code cloud-ready without the check ([Rule 1.5](../docs/ABAP-Development-Rules.md#15-never-call-code-cloud-ready-unless-it-was-checked)).

## 🔁 abaplint and Continuous Integration

[abaplint](https://github.com/abaplint/abaplint) is an open-source static analysis tool for ABAP that has been serialized with [abapGit](https://github.com/abapGit/abapGit). It runs outside the SAP system, for example on a pull request, and needs complete objects. Its configuration lives in `abaplint.json`; Rule 13.4 maps the guide's rules to abaplint rules ([Rule 13.4](../docs/ABAP-Development-Rules.md#134-use-abaplint-for-offline-checks-of-complete-abapgit-serialized-objects)).

**Example X3 — a minimal abaplint configuration.**

> 📝 **Configuration example** — a starting point that enables some of the rules named in Rule 13.4; the structure follows abaplint's documentation **[verify: the configuration format of the abaplint version you use]**.

```json
{
  "global": {
    "files": "/src/**/*.*"
  },
  "syntax": {
    "version": "v758",
    "errorNamespace": "^(Z|Y|LCL_|TY_|LIF_)"
  },
  "rules": {
    "keyword_case": true,
    "line_length": { "length": 120 },
    "prefer_inline": true,
    "use_new": true,
    "prefer_xsdbool": true,
    "obsolete_statement": true
  }
}
```

Continuous integration runs ATC, including ABAP Unit, for every change, so that a red test stops the change before it is transported ([Rule 10.10](../docs/ABAP-Development-Rules.md#1010-run-the-tests-in-atc-and-in-continuous-integration)). How a pipeline connects to a system depends on the landscape and is not covered here.

## 🧭 Scope Note

Not covered in this chapter:

- **Transport administration:** transport routes, import queues, `STMS` configuration, and moving transport files between systems by hand.
- **Change Request Management (ChaRM)** and other process tools around transports.
- **Translation** (`SE63`, `SLXT`) and the transport of translations.
- **Repository comparison** across systems (`SREPO`) beyond a mention in [30-Tools-AI-Assistance](../30-Tools-AI-Assistance/README.md#-sap-gui-tools-that-still-matter).
- **ATC administration:** central check systems, remote checks, and the setup of release checks.

## ✅ Best Practices

- Start transportable work in a transportable package; keep `$TMP` for experiments.
- One logical change per request, released only after syntax check, ABAP Unit and ATC ([Rules 13.7](../docs/ABAP-Development-Rules.md#137-bundle-one-logical-change-per-transport-request-and-release-it-only-after-the-checks-of-131) and [13.1](../docs/ABAP-Development-Rules.md#131-release-nothing-that-fails-the-syntax-check-abap-unit-or-atc-with-the-team-check-variant)).
- Use one shared ATC check variant; fix each finding or exempt it with a reason and an approver.
- Put release rules into a tested class and keep the BAdI method thin.
- Analyse a request's objects in `SE03` before release.
- Use the released XCO classes for transport information in ABAP for Cloud Development.

## ⚠️ Common Mistakes

- Building transportable work in `$TMP` and copying it later by hand.
- Updating `TADIR` or the request tables with own code to change a package or original system.
- Unlocking objects in a colleague's request to get one's own change through.
- Releasing with open ATC findings, or exempting them without a reason.
- Mixing unrelated changes in one request.
- Moving an object with a syntax error to another request instead of fixing it.
- Forgetting standard texts or other objects that are not recorded automatically.
- Reading requests with the `TR_*` function modules in new code.

## 🎤 Interview & Review Checkpoints

- What decides whether an object can be transported?
- Workbench request vs Customizing request: what goes where?
- What is a task, and what happens when a request is released?
- Why are objects locked in requests, and when is `SE03`'s unlock tool acceptable?
- What does the system change option control?
- How would you enforce a team rule at release, and where does the rule live?
- How is transport organised in the SAP BTP ABAP environment?
- What is an ATC check variant, and what does an exemption need?

## 🖥️ Related Transaction Codes

| T-code | Purpose |
|---|---|
| `SE09`, `SE10` | Transport Organizer |
| `SE01` | Transport Organizer, extended view |
| `SE03` | Transport Organizer Tools |
| `SE06` | Set up the Transport Organizer |
| `SE07` | CTS status display |
| `STMS` | Transport Management System |
| `ATC` | ATC administration |
| `SCI` | Code Inspector |
| `SO10` | Standard texts |

## 🔗 Related Chapters

- [30-Tools-AI-Assistance](../30-Tools-AI-Assistance/README.md) — the next chapter: development tools, abapGit and AI assistants
- [31-Business-Workflow](../31-Business-Workflow/README.md) — workflow definitions and tasks, which travel in workbench requests
- [32-IDoc-ALE](../32-IDoc-ALE/README.md) — IDoc types and ALE configuration in transports
- [20-Best-Practices](../20-Best-Practices/README.md) — the review checklist that a release completes
- [22-ABAP-Unit](../22-ABAP-Unit/README.md) — running the tests in ADT, ATC and pipelines
- [26-Maintenance-Views](../26-Maintenance-Views/README.md) — recording and transporting Customizing
- [16-BADIs](../16-BADIs/README.md) — implementing a classic BAdI
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — cloud readiness and released APIs
- [28-Adobe-Forms](../28-Adobe-Forms/README.md) — the previous chapter
