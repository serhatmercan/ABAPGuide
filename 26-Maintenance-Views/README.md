# 26 — Table Maintenance and Maintenance Views

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. The table maintenance generator (`SE54`), maintenance in `SM30`, maintenance views and view clusters are how Standard ABAP lets users maintain Customizing, and most landscapes are full of them. In ABAP for Cloud Development, a business configuration maintenance object and a Fiori app take their place; that part is `ABAP CLOUD / MODERN CONTEXT` and labelled where it appears. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

Many decisions in an application should not be code: how many days until an order counts as late, which order types escalate, which sales office gets a copy. Values like these change without a release, and they differ between clients and systems. They belong in **Customizing tables**, and the code reads them ([Rule 8.5](../docs/ABAP-Development-Rules.md#85-never-hard-code-credentials-hosts-or-destinations), [Rule 8.11](../docs/ABAP-Development-Rules.md#811-take-mail-recipients-and-senders-from-configuration-never-write-addresses-into-code)).

Someone then has to maintain these entries, with the right authorization, and the entries have to travel from development to production in a controlled way. This chapter covers that whole path:

- the Customizing table itself: delivery class, client, maintenance setting;
- generating a maintenance dialog in `SE54` and maintaining entries in `SM30`;
- maintenance views and view clusters;
- authorization groups and the authorization objects behind table maintenance;
- the events of a maintenance dialog, and where custom code belongs;
- regenerating after a table change;
- recording and transporting Customizing, and logging changes;
- the business configuration maintenance that replaces all of this in ABAP for Cloud Development;
- reading Customizing in code, and testing that code without real entries.

The example throughout is one Customizing table, `zsm_t_ord_prio`: per order type, the number of days until an order is late, and whether late orders escalate.

## 🗺️ Standard ABAP and ABAP for Cloud Development at a Glance

| Topic | Standard ABAP | ABAP for Cloud Development |
|---|---|---|
| Customizing table | Database table, delivery class C | Database table, delivery class C |
| Maintenance UI | Generated dialog (dynpro), started in `SM30`, a parameter transaction or `VIEW_MAINTENANCE_CALL` | Business configuration maintenance object, maintained in the *Custom Business Configurations* app |
| How it is built | Table maintenance generator `SE54` | A RAP business object generated in ADT, plus the maintenance object (`SMBC`) |
| Several tables as one unit | Maintenance view; view cluster (`SM34`) | Several entities in one RAP business object |
| Custom logic | Event routines (`FORM`s) in the generated function group | Validations and determinations of the RAP business object |
| Authorization | `S_TABU_DIS` with the authorization group, `S_TABU_NAM`, `S_TABU_CLI`, `S_TABU_LIN` | `S_TABU_NAM` in the generated business object |
| Transport of entries | Customizing request (client-specific) or workbench request (cross-client) | Recorded through the released API `MBC_CP_API`; exported with the *Export Customizing Transports* app |
| Release state | `VIEW_MAINTENANCE_CALL`, `VIEWCLUSTER_MAINTENANCE_CALL`, `VIEW_AUTHORITY_CHECK`: classified as classic APIs | `MBC_CP_API`, `IF_MBC_CP_RAP_TABLE_CTS`, `IF_MBC_CP_RAP_TDAT_CTS`, `S_TABU_NAM`: released |

The release states come from SAP's lists of released and classified objects. The cloud column is described in [Business Configuration Maintenance in ABAP for Cloud Development](#-business-configuration-maintenance-in-abap-for-cloud-development).

## 🗄️ Customizing Tables: Delivery Class and Client

A Customizing table is an ordinary database table. Three settings make it one.

### Delivery class

The delivery class says who owns the entries, and so how they are transported. The ABAP Keyword Documentation describes these classes:

| Class | Who owns the data | Typical handling of the entries |
|---|---|---|
| **A** | Application data: master and transaction data | Written by the application in each system |
| **C** | Customizing that only the customer maintains | Maintained in development and transported |
| **L** | Local, temporary data; delivered empty | Never transported |
| **G** | Customizing, protected against changes by SAP | Obsolete: can no longer be specified; use C |
| **E** | Control table in which SAP and the customer have separate key ranges | Transported; each side stays in its key range |
| **S** | System table; maintained only by SAP | Handled like repository objects |
| **W** | System table whose content travels with its own repository objects | Not transported through table maintenance |

The decision for your own tables is almost always between C and A ([Rule 7.16](../docs/ABAP-Development-Rules.md#716-give-every-custom-table-the-delivery-class-of-the-people-who-own-its-data-c-for-customizing-a-for-application-data)): settings that are maintained in development and transported get C; data that is created in each system by the application gets A. L is for buffers and logs that no one transports.

> ⚠️ **ADT creates a new table with delivery class A.** On both systems used for this chapter, a new database table started with `#A` and `#RESTRICTED`. A Customizing table that keeps these defaults is maintained in production instead of being transported. Set the class when you create the table.

> 📝 In ABAP for Cloud Development, delivery class C activated, and the syntax check rejected G as "not supported". Which other classes that language version accepts is **[verify: delivery classes allowed in ABAP for Cloud Development]**.

### Client

A table whose first key field has the type `CLNT` is client-dependent: each client has its own entries, and ABAP SQL restricts every access to the logon client ([Rule 7.8](../docs/ABAP-Development-Rules.md#78-let-abap-sql-handle-the-client)). Without that field the table is cross-client: one set of entries for the whole system. Cross-client Customizing needs a separate client setting and authorization before anyone may change it (see [Recording and Transporting Customizing](#-recording-and-transporting-customizing)). Make a Customizing table client-dependent unless the setting is truly the same for every client.

### Maintenance setting

The annotation `@AbapCatalog.dataMaintenance` decides what the generic tools may do with the table. According to the ABAP Keyword Documentation:

| Value | Data Browser (`SE16`) | Generated dialog |
|---|---|---|
| `#ALLOWED` | Display and change | Usable in `SM30`, `SM31` and in view clusters (`SM34`) |
| `#RESTRICTED` | Display | Can be generated, but used only in view clusters |
| `#DISPLAY` | Display | Can be generated, but not used in `SM30`, `SM31` or `SM34` |
| `#NOT_ALLOWED` | None | `SE54` cannot generate one |

A table that users maintain in `SM30` needs `#ALLOWED`.

### Field labels and names

The generated screens take their column headings from the field labels of the data elements. A table built on predefined types shows technical names to the user; give every field a data element with labels.

The names of database tables and views have at most 16 characters (ABAP Keyword Documentation, and the creation limit in ADT on both systems). With the namespace infix `zsm_t_` that leaves ten characters ([Rule 2.6](../docs/ABAP-Development-Rules.md#26-name-development-objects-by-the-object-naming-table)).

**Example E1 — the Customizing table.** The data elements `zsm_e_order_type` (`CHAR 4`) and `zsm_e_days_late` (`INT2`) carry the field labels; `abap_boolean` is SAP's data element for a flag.

```abap
@EndUserText.label : 'Order priority rules'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
define table zsm_t_ord_prio {

  key client     : abap.clnt not null;
  key order_type : zsm_e_order_type not null;
  days_late      : zsm_e_days_late;
  escalate       : abap_boolean;

}
```

## 🛠️ Generating a Maintenance Dialog (SE54)

The table maintenance generator builds a complete dynpro application for one table or maintenance view. It is started in `SE54`, or in `SE11` under *Utilities → Table Maintenance Generator*. These are the settings you choose:

1. **Authorization group.** Names the group the table belongs to; `S_TABU_DIS` checks it (see [Authorization Groups](#-authorization-groups-and-authorization-objects)).
2. **Function group.** The generated screens, modules and includes go into a function group, which the generator creates if it does not exist. Give it its own name per table ([Rule 2.6](../docs/ABAP-Development-Rules.md#26-name-development-objects-by-the-object-naming-table), for example `zsm_fg_ord_prio`), so a regeneration never touches another table's dialog.
3. **Maintenance type.** *One step*: one overview screen with all fields. *Two step*: an overview screen and a detail screen for one entry with all fields. One step suits narrow tables; two step suits tables with many or long fields.
4. **Screen numbers.** The overview screen, and for two step the detail screen. The generator can propose free numbers.
5. **Recording routine.** Whether, and how, changed entries are written to a transport request. The standard routine is right for a Customizing table.

The generator then creates the function group with its screens and a main program, and registers the dialog in the view directory `TVDIR`, which holds the function group, the screen numbers and the maintenance type for each table or view.

> 📝 The dialog's objects are repository objects. In a development package they go into a workbench request like any other development; the entries maintained later go into Customizing requests. Keep the two apart in your head: one transports the tool, the other the data.

> ⚠️ **Generating a dialog is a GUI step.** It cannot be done through ADT; neither the dialog nor a maintenance view, view cluster or transaction could be created through the ADT tools used for this chapter.

## 🖥️ Maintaining Entries: SM30 and Parameter Transactions

`SM30` takes the table or view name and opens the generated dialog to display or maintain entries. Users should not have to know table names, so give each dialog a transaction of its own.

### A parameter transaction on SM30

In `SE93`, create a transaction of the type *parameter transaction* with `SM30` as the default transaction. According to SAP's documentation, its default values are `VIEWNAME` (the table or view) and exactly one action set to `X`: `UPDATE` to maintain, `SHOW` to display, or `TRANSPORT`. The initial screen of `SM30` can be skipped, because all its fields then have values. Name the transaction by the naming table, for example `zsm_ord_prio` ([Rule 2.6](../docs/ABAP-Development-Rules.md#26-name-development-objects-by-the-object-naming-table)).

The user then needs `S_TCODE` for the new transaction, and the dialog still checks the table authorization (see below), so one role can open the transaction and still be limited to display.

### Calling the dialog from code

`VIEW_MAINTENANCE_CALL` opens the dialog from a program. Its parameter `action` takes `U` (change), `S` (display) or `T` (transport); a selection table of type `VIMSELLIST` restricts the entries shown. `VIEW_RANGETAB_TO_SELLIST` turns a range table into that format. SAP classifies `VIEW_MAINTENANCE_CALL` as a classic API: usable in Standard ABAP, not released for ABAP for Cloud Development.

**Example E3 — opening the dialog for selected order types.**

> 📝 **Target:** Standard ABAP.

```abap
REPORT zsm_r_ord_prio_maintain.

" Opens the maintenance dialog of ZSM_T_ORD_PRIO for the selected
" order types only; the dialog itself checks the authorization.

CONSTANTS: maintained_table TYPE tabname VALUE 'ZSM_T_ORD_PRIO',
           filter_field     TYPE vimsellist-viewfield VALUE 'ORDER_TYPE',
           conjunction_and  TYPE vimsellist-and_or VALUE 'AND',
           action_change    TYPE c LENGTH 1 VALUE 'U'.

DATA order_type TYPE zsm_e_order_type.
SELECT-OPTIONS s_type FOR order_type.

START-OF-SELECTION.
  DATA selection TYPE STANDARD TABLE OF vimsellist WITH EMPTY KEY.

  " Turns the range into the selection format of the dialog
  CALL FUNCTION 'VIEW_RANGETAB_TO_SELLIST'
    EXPORTING
      fieldname          = filter_field
      append_conjunction = conjunction_and
    TABLES
      sellist            = selection
      rangetab           = s_type[].

  CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
    EXPORTING
      action                       = action_change
      view_name                    = maintained_table
    TABLES
      dba_sellist                  = selection
    EXCEPTIONS
      client_reference             = 1
      foreign_lock                 = 2
      invalid_action               = 3
      no_clientindependent_auth    = 4
      no_database_function         = 5
      no_editor_function           = 6
      no_show_auth                 = 7
      no_tvdir_entry               = 8
      no_upd_auth                  = 9
      only_show_allowed            = 10
      system_failure               = 11
      unknown_field_in_dba_sellist = 12
      view_not_found               = 13
      maintenance_prohibited       = 14
      OTHERS                       = 15.
  IF sy-subrc <> 0.
    " The dialog raises its exceptions with a message, so show that one
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            DISPLAY LIKE 'E'.
  ENDIF.
```

Without a generated dialog the call ends with `no_tvdir_entry`: the table has no entry in the view directory. The dialog sets its own enqueue locks; a table already being maintained by someone else ends in `foreign_lock`.

> 💡 A report like E3 is only worth it when the filter matters. For plain maintenance, a parameter transaction needs no code at all.

## 🔗 Maintenance Views and View Clusters (SE54, SM34)

### Maintenance views

A maintenance view lets users maintain entries of several tables on one screen as if they were one. According to the ABAP Keyword Documentation and SAP's ABAP Dictionary documentation:

- The tables are joined through their foreign key relationships. The first table is the primary table; every further table must have an N:1 relationship to the primary table or to the table before it.
- The view is an inner join and contains all key fields of the primary table.
- It exists only in the ABAP Dictionary, not on the database, and ABAP SQL cannot read it. Code reads the tables, not the view.
- A **maintenance status** decides what the dialog allows: read only; read, change, delete and insert; read and change; or read and change of time-dependent entries.
- View fields can be marked read only, hidden, or as a subset field that restricts the entries shown.
- Like a table, the view needs a dialog generated in `SE54` before it can be maintained in `SM30`, and the dialog must be regenerated whenever the view changes.

A typical use is a Customizing table with a text table: the view shows the setting and its language-dependent text together.

### View clusters

A view cluster groups several maintenance dialogs into one unit with a navigation tree, for settings that only make sense together. A higher-level entry and its dependent entries are maintained, and deleted, together. According to SAP's documentation:

- Each table or view first gets its own generated dialog; the cluster is then defined in `SE54` (*Edit View Cluster*) and maintained in `SM34`.
- The cluster defines the hierarchy and which key fields the levels share.
- A cluster has its own events, separate from the events of each dialog.
- From code, `VIEWCLUSTER_MAINTENANCE_CALL` opens it; SAP classifies it as a classic API.

Name clusters by the naming table, for example `zsm_vc_order`, and maintenance views like `zsm_v_ord_prio` ([Rule 2.6](../docs/ABAP-Development-Rules.md#26-name-development-objects-by-the-object-naming-table)).

## 🔐 Authorization Groups and Authorization Objects

Table maintenance checks standard authorization objects. Which one applies depends on the table, so understand all four:

| Object | Fields | What it protects |
|---|---|---|
| `S_TABU_DIS` | `ACTVT` (02 change, 03 display), `DICBERCLS` (authorization group) | Maintenance with `SM30`, `SM31` and display in the Data Browser, for every table of a group |
| `S_TABU_NAM` | `ACTVT`, `TABLE` | The same access for named tables |
| `S_TABU_CLI` | `CLIIDMAINT` | The additional permission to change cross-client tables |
| `S_TABU_LIN` | Organizational criteria | Line-oriented access, for example only the entries of one country |

According to SAP's documentation, the authorization group of a table is read from table `TDDAT`; the groups themselves are defined in table `TBRG`. On the on-premise system used for this chapter, the data element of the group, `DICBERCLS`, has 14 characters; older releases used shorter groups.

> ⚠️ **VERSION-DEPENDENT: length of the authorization group.** Check the data element `DICBERCLS` in your system before you design group names.

Practical consequences:

- **Assign every maintained table to a group** that matches its business owner ([Rule 8.14](../docs/ABAP-Development-Rules.md#814-assign-an-authorization-group-to-every-table-that-users-maintain-protect-sensitive-tables-additionally-with-s_tabu_nam)). A table left without a deliberate group falls under whatever the roles grant for ungrouped tables. **[verify: how tables without an authorization group are checked in your release]**
- **Protect sensitive tables by name as well**, with `S_TABU_NAM`, so that a broad group authorization does not open them.
- **A parameter transaction is not a security boundary.** `S_TCODE` decides who may start it; the table authorization decides what they may do ([Rule 8.9](../docs/ABAP-Development-Rules.md#89-call-transactions-with-authority-check)).
- A program that reads or changes arbitrary tables checks the same authorization itself, for example with `VIEW_AUTHORITY_CHECK` as in [11-Classical-Reports](../11-Classical-Reports/README.md) ([Rule 8.1](../docs/ABAP-Development-Rules.md#81-check-authorization-wherever-business-data-is-read-or-changed-and-evaluate-sy-subrc)).

Event 25 of the dialog is the place for an additional check of your own (see the next section). Use only real authorization objects there; in guide examples, mark the place ([Rule 8.2](../docs/ABAP-Development-Rules.md#82-in-guide-examples-mark-where-the-check-belongs-never-invent-an-authorization-object)).

## 🧩 Maintenance Dialog Events: Where Custom Code Belongs

The generated dialog calls your code at fixed points, called events. You register a `FORM` routine per event in `SE54` under *Environment → Modification → Events*; the registrations are stored in table `TVIMF` (table name, event, routine name). The routines live in an include of the dialog's function group that you create.

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. `FORM` is obsolete in general ([21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md)), but the event mechanism calls `FORM` routines and nothing else. Keep each routine a thin shell and put the logic into a class.

### The events used most

The full list is in SAP's documentation of extended table maintenance events, and in the fixed values of the event domain `MAINTEVENT`. These are the ones you meet most:

| Event | When it runs | Typical use |
|---|---|---|
| 01 | Before the changed entries are saved | Validate; stop the save |
| 02 | After the entries were saved | Follow-up work that does not change the maintained table |
| 03 / 04 | Before / after displayed entries are deleted | Warn before a deletion |
| 05 | When a new entry is created | Default values |
| 21 | When hidden fields are filled | Fill fields the user does not see, such as a changed-by field |
| 25 | When the dialog starts | An additional authorization check of your own |
| 26 | Before the displayed data is output as a list | Adjust the list |
| AA, AB, … | Instead of a standard routine (read the data, change the database, …) | Rarely justified; you then own what the standard did |

### The dialog's data

The routines run inside the generated program and work with its global data:

- the internal tables `TOTAL` (all entries read from the database) and `EXTRACT` (the entries currently displayed). They are `TABLES` parameters of the generated function module `TABLEPROC_<table or view>`, typed as generic standard tables, so each has a header line; `LOOP AT total` fills the header line of `TOTAL`;
- field symbols for the current line of each table: `<vim_total_struc>` (the table fields of the current `TOTAL` line), `<action>` (what happened to that line) and `<mark>` (whether it is marked); for the current `EXTRACT` line, the framework uses `<xact>` and `<xmark>`;
- action values defined by the framework as constants, among them `neuer_eintrag` (`N`, new), `aendern` (`U`, changed), `geloescht` (`D`, deleted), `update_geloescht` (`Y`, changed and then deleted), `neuer_geloescht` (`X`, new and then deleted, so nothing to save) and `leer` (`L`, an empty line offered for a new entry);
- the flag `vim_abort_saving`: when an event 01 routine sets it, the dialog does not save.

These names come from SAP's maintenance framework (function group `SVIM`), read on the on-premise system used for this chapter. They are not a released API; check them in your release before you rely on one.

> 💡 The framework stops at the checkpoint group `SVIM_MAINTENANCE_EVENTS` before it calls an event 01 routine. Activate that group to debug your routine ([23-Debugging-Troubleshooting](../23-Debugging-Troubleshooting/README.md#checkpoint-groups)).

### The dialog owns the save

The generated dialog reads the entries, keeps them in its tables, writes the changes to the database, records them in a transport request and commits. An event routine that writes to the maintained table or commits breaks all four ([Rule 7.17](../docs/ABAP-Development-Rules.md#717-in-table-maintenance-events-change-only-the-dialogs-own-data-the-generated-dialog-saves-and-commits), [Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work)):

```abap
" ❌ event 01 saves and commits on its own
FORM zsm_ord_prio_before_save.
  LOOP AT total.
    ...
    MODIFY zsm_t_ord_prio FROM entry.
    COMMIT WORK AND WAIT.
  ENDLOOP.
ENDFORM.
```

The entries are now written before the dialog has saved, committed one by one, and not recorded in the transport request; a later error in the dialog cannot undo them.

### Logic in a class, the event as a shell

**Example E4a — the rules as a class.** The class knows nothing about the dialog, so it can be unit-tested and reused, for example by an upload program.

```abap
"! Rules that every order priority entry must follow. The events of the
"! maintenance dialog call them; the class itself knows no dialog.
CLASS zcl_zsm_ord_prio_rules DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES entries     TYPE STANDARD TABLE OF zsm_t_ord_prio WITH EMPTY KEY.
    TYPES order_types TYPE STANDARD TABLE OF zsm_e_order_type WITH EMPTY KEY.

    CONSTANTS max_days_late TYPE zsm_e_days_late VALUE 365.

    "! Returns the order types of all entries that break a rule
    "! @parameter entries | Entries to be saved
    "! @parameter result | Order types of the invalid entries
    METHODS invalid_entries
      IMPORTING entries       TYPE entries
      RETURNING VALUE(result) TYPE order_types.

    "! Tells whether deleting an entry needs the user's confirmation
    "! @parameter entry | Entry to be deleted
    "! @parameter result | abap_true if the entry escalates late orders
    METHODS needs_delete_confirmation
      IMPORTING entry         TYPE zsm_t_ord_prio
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_zsm_ord_prio_rules IMPLEMENTATION.
  METHOD invalid_entries.
    result = VALUE #( FOR entry IN entries
                      WHERE ( days_late < 1 OR days_late > max_days_late )
                      ( entry-order_type ) ).
  ENDMETHOD.

  METHOD needs_delete_confirmation.
    " Deleting an escalating rule silently stops all its escalations
    result = entry-escalate.
  ENDMETHOD.
ENDCLASS.
```

**Example E4a (continued) — the test include of `zcl_zsm_ord_prio_rules`.**

```abap
CLASS ltc_ord_prio_rules DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_zsm_ord_prio_rules.

    METHODS setup.
    METHODS accepts_days_within_range FOR TESTING.
    METHODS rejects_zero_and_too_many_days FOR TESTING.
    METHODS confirms_delete_of_escalation FOR TESTING.
    METHODS deletes_plain_rule_directly FOR TESTING.
ENDCLASS.


CLASS ltc_ord_prio_rules IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD accepts_days_within_range.
    " given
    DATA(entries) = VALUE zcl_zsm_ord_prio_rules=>entries(
        ( order_type = 'STD'  days_late = 1 )
        ( order_type = 'SLOW' days_late = zcl_zsm_ord_prio_rules=>max_days_late ) ).

    " when
    DATA(invalid) = cut->invalid_entries( entries ).

    " then
    cl_abap_unit_assert=>assert_initial( invalid ).
  ENDMETHOD.

  METHOD rejects_zero_and_too_many_days.
    " given
    DATA(entries) = VALUE zcl_zsm_ord_prio_rules=>entries(
        ( order_type = 'ZERO' days_late = 0 )
        ( order_type = 'STD'  days_late = 10 )
        ( order_type = 'LONG' days_late = zcl_zsm_ord_prio_rules=>max_days_late + 1 ) ).

    " when
    DATA(invalid) = cut->invalid_entries( entries ).

    " then
    cl_abap_unit_assert=>assert_equals(
        act = invalid
        exp = VALUE zcl_zsm_ord_prio_rules=>order_types( ( 'ZERO' ) ( 'LONG' ) ) ).
  ENDMETHOD.

  METHOD confirms_delete_of_escalation.
    " given
    DATA(entry) = VALUE zsm_t_ord_prio( order_type = 'RUSH' escalate = abap_true ).

    " when / then
    cl_abap_unit_assert=>assert_true( cut->needs_delete_confirmation( entry ) ).
  ENDMETHOD.

  METHOD deletes_plain_rule_directly.
    " given
    DATA(entry) = VALUE zsm_t_ord_prio( order_type = 'STD' escalate = abap_false ).

    " when / then
    cl_abap_unit_assert=>assert_false( cut->needs_delete_confirmation( entry ) ).
  ENDMETHOD.
ENDCLASS.
```

**Example E4b — the event 01 routine.** It collects the new, changed and deleted entries, asks the class, and stops the save when needed. The dialog then writes, records and commits, or does nothing.

> 📝 **Contextual snippet** — assumes the generated dialog of `zsm_t_ord_prio` with this routine registered for event 01, a message class `zsm_msg` with messages 010 and 011, a text symbol `q01` with the question, and the framework names described above; `POPUP_TO_CONFIRM` sets `answer` to `1` for the first button, to `2` for the second and to `A` for cancel.

```abap
" Event 01: runs before the dialog saves; setting vim_abort_saving
" keeps all changes on the screen and saves nothing
FORM zsm_ord_prio_before_save.
  DATA changed_entries TYPE zcl_zsm_ord_prio_rules=>entries.
  DATA deleted_entries TYPE zcl_zsm_ord_prio_rules=>entries.
  DATA entry           TYPE zsm_t_ord_prio.
  DATA answer          TYPE c LENGTH 1.

  LOOP AT total.
    MOVE-CORRESPONDING <vim_total_struc> TO entry.
    CASE <action>.
      WHEN neuer_eintrag OR aendern.
        APPEND entry TO changed_entries.
      WHEN geloescht OR update_geloescht.
        APPEND entry TO deleted_entries.
    ENDCASE.
  ENDLOOP.

  DATA(rules) = NEW zcl_zsm_ord_prio_rules( ).

  DATA(invalid) = rules->invalid_entries( changed_entries ).
  IF invalid IS NOT INITIAL.
    MESSAGE s010(zsm_msg) WITH invalid[ 1 ] DISPLAY LIKE 'E'.
    vim_abort_saving = abap_true.
    RETURN.
  ENDIF.

  LOOP AT deleted_entries INTO entry.
    IF rules->needs_delete_confirmation( entry ).
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          text_question         = TEXT-q01
          display_cancel_button = abap_false
        IMPORTING
          answer                = answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0 OR answer <> '1'.
        MESSAGE s011(zsm_msg) WITH entry-order_type.
        vim_abort_saving = abap_true.
        RETURN.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.
```

The routine never touches the database. Everything it knows about rules comes from the class; everything it knows about the dialog stays in the routine. `MESSAGE` is correct here: an event routine is part of the UI ([Rule 6.11](../docs/ABAP-Development-Rules.md#611-use-message-statements-only-in-the-ui-layer)).

### Field control on the screen

Sometimes a field should be ready for input only in some lines, for example `escalate` only in new entries. That needs a module in the flow logic of a generated screen.

> 📝 **Contextual snippet** — a PBO module of the generated function group, called inside the generated `LOOP AT EXTRACT` of the overview screen after the generated module `LISTE_SHOW_LISTE`. Inside that loop the framework's own module reads the current line through `<xact>` and `<xmark>`, not through `<action>`, which belongs to `TOTAL`. Screen field names follow the pattern `table-field`. **[verify: which action value a newly typed line carries in `EXTRACT` before it is first saved]**

```abap
MODULE zsm_escalate_only_when_new OUTPUT.
  " Escalation is decided when the rule is created, not changed later
  LOOP AT SCREEN INTO DATA(screen_field).
    IF screen_field-name = 'ZSM_T_ORD_PRIO-ESCALATE'
       AND <xact> <> neuer_eintrag AND <xact> <> leer.
      screen_field-input = 0.
      MODIFY SCREEN FROM screen_field.
    ENDIF.
  ENDLOOP.
ENDMODULE.
```

> ⚠️ **A change to a generated screen survives a regeneration only if you exclude that screen.** Prefer events; when a screen change is unavoidable, record it, and exclude the screen every time you regenerate (next section). `LOOP AT SCREEN` itself is explained in [12-Selection-Screens](../12-Selection-Screens/README.md).

## ♻️ Regenerating After a Table Change

The generated screens and modules copy the table's fields at generation time. After a field is added, removed or changed, the dialog no longer matches the table, and the next `SM30` call can end in a screen generation error ([23-Debugging-Troubleshooting](../23-Debugging-Troubleshooting/README.md#-common-errors-and-fixes) lists it as `DYNPRO_SYNTAX_ERROR`).

According to SAP's documentation, the fix is a selective regeneration:

1. In `SE54`, choose *Generated Objects → Create/Change*, then *Change*.
2. The generator asks for the reasons for the change, for example a new or removed field, a changed maintenance type, a text table, changed selection conditions or field attributes. It regenerates only what those reasons require.
3. Exclude screens, the GUI status or the main program that you changed by hand.
4. Avoid the *Expert* mode unless you know exactly what to regenerate; SAP's documentation warns that it can delete modules or leave the generation incomplete.

Event routines and your own includes are not affected by the regeneration. That is the second reason to keep custom code in events and classes rather than in generated screens.

Regenerating changes repository objects, so it goes into a workbench request with the table change. Transport both together, or the target system has a table and a dialog that do not match.

## 🚚 Recording and Transporting Customizing

Every client has a setting for changes to client-specific Customizing. According to SAP's documentation it is one of: changes without automatic recording, automatic recording of changes, no changes allowed, or changes without transports. A separate setting decides whether cross-client objects may be changed. In development clients, automatic recording is normal; production clients allow no changes.

With automatic recording, saving in `SM30` asks for a request:

- entries of a **client-specific** Customizing table go into a **Customizing request**;
- entries of a **cross-client** table, like repository objects, go into a **workbench request**.

The request records the keys of the changed entries, not the table definition. The table and its dialog are repository objects and travel separately.

Practical rules:

- **Maintain Customizing in the development client and transport it.** Changing Customizing directly in production, where a client allows it at all, leaves systems that no longer match, and the next transport overwrites the change.
- **Transport the table before its entries.** A request whose table does not exist in the target system fails when it is imported. The same happens when a table is deleted while old requests still contain its keys.
- **Keep transport recording in the dialog.** An event routine that writes to the table bypasses it ([Rule 7.17](../docs/ABAP-Development-Rules.md#717-in-table-maintenance-events-change-only-the-dialogs-own-data-the-generated-dialog-saves-and-commits)).
- **Use L only for data that must never travel.** `SM30` entries of a class L table cannot be transported.

## 📜 Logging Table Changes (SCU3)

For audits, the system can log every change to a table. According to the ABAP Keyword Documentation and SAP's documentation, two things must both be true:

- the table has the technical setting *Log data changes*;
- the profile parameter `rec/client` switches logging on, for all clients, a list of clients, or not at all. Profile parameters belong to system administration.

The log is evaluated in `SCU3`. Logging slows down every change to the table and fills a log table, so use it for Customizing that matters for audits, not for tables that change all day. Whether changes made through a maintenance view or view cluster are logged for its tables is **[verify: logging of changes through maintenance views]**; logging is defined per table.

## ☁️ Business Configuration Maintenance in ABAP for Cloud Development

> **Lifecycle:** `ABAP CLOUD / MODERN CONTEXT`. Described up to the point where the RAP business object begins; building it belongs to the future RAPGuide.

ABAP for Cloud Development has no dynpros ([21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-what-changes-under-abap-cloud)), so there is no generated dialog and no `SM30`. Customizing is maintained in a Fiori app instead. According to SAP's documentation for the SAP BTP ABAP environment, the pieces are:

1. **The Customizing table.** Client-dependent, delivery class C, `dataMaintenance` allowed or restricted, and a field for the last-changed time stamp that the generated business object needs.
2. **A RAP business object** for the table: managed, with draft, generated in ADT by the wizard *Generate ABAP Repository Objects* under *Business Configuration Management*. It checks authorization with `S_TABU_NAM` and records changed entries in a transport request through the released class `MBC_CP_API`.
3. **A business configuration maintenance object** (object type `SMBC`), which makes the business object appear in the *Custom Business Configurations* app.
4. **Transport.** Entries are recorded in a Customizing request and released with the *Export Customizing Transports* app.

`MBC_CP_API` offers `rap_table_cts` and `rap_tdat_cts` for recording entries; both, and their interfaces, are released. SAP's documentation shows `rap_tdat_cts`.

According to SAP Help for the SAP BTP ABAP environment (*Generating a Business Configuration Maintenance Object with the Generate ABAP Repository Objects Wizard* and *Custom Business Configurations App*):

- **The wizard** starts from the context menu of a database table in an ABAP project. Besides the basis table it can include tables with a `#KEY` foreign key to it and text tables with a `#TEXT_KEY` foreign key; all of them need a client field, delivery class C and data maintenance allowed or restricted, and the software components of the target package and of the table must be changeable. It cannot overwrite existing objects or generate only some of them, and it asks for a transport request. Options include a copy action and a transport selection strip in the app's header.
- **The app** *Custom Business Configurations* needs the business catalog `SAP_CORE_BC_BCT_MBC_PC`, contained in the business role template `SAP_BR_BPC_EXPERT`. A maintenance object only appears in the list when the user is authorized for its business configuration service.

**[verify: the prerequisites of the *Export Customizing Transports* app in your release]**

> ⚠️ **VERSION-DEPENDENT: business configuration maintenance in Standard ABAP.** On the on-premise system used for this chapter, `SMBC` objects could be created and `MBC_CP_API` existed. Whether your release supports the full path, apps included, is release-specific; check SAP's documentation for your product.

Two things stay the same: the Customizing table with delivery class C, and business code that reads it through an interface (next section). What changes is only how people maintain it.

## 🧪 Reading Customizing in Code and Testing It

Business code reads Customizing; it never opens a maintenance dialog. The pattern is the one from [24-Mail](../24-Mail/README.md#-addresses-from-configuration) and [25-HTTP-REST](../25-HTTP-REST/README.md#-destinations-credentials-and-tokens): an interface describes the settings, one class reads them from the table, and tests use the ABAP SQL test environment, so no test depends on entries in the system ([Rule 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor), [Rule 10.8](../docs/ABAP-Development-Rules.md#108-isolate-database-access-with-the-abap-sql-and-cds-test-double-frameworks-never-use-real-data)).

**Example E2 — reading the rules.** Target: Standard ABAP and ABAP for Cloud Development. The exception class inherits from `CX_STATIC_CHECK` so the example stands alone; in a real system it inherits from the team's root ([Rule 6.2](../docs/ABAP-Development-Rules.md#62-build-your-own-exception-hierarchy-below-zcx_zsm_)).

```abap
"! Raised when no priority rule is maintained for an order type.
"! ORDER_TYPE names the order type that has no entry.
CLASS zcx_zsm_ord_prio_missing DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA order_type TYPE zsm_e_order_type READ-ONLY.

    METHODS constructor
      IMPORTING textid     LIKE textid OPTIONAL
                previous   LIKE previous OPTIONAL
                order_type TYPE zsm_e_order_type OPTIONAL.
ENDCLASS.


CLASS zcx_zsm_ord_prio_missing IMPLEMENTATION.
  METHOD constructor.
    super->constructor( textid   = textid
                        previous = previous ).
    me->order_type = order_type.
  ENDMETHOD.
ENDCLASS.
```

```abap
"! Priority rules per order type, maintained as Customizing.
"! Business code reads them here, never through the maintenance dialog.
INTERFACE zif_zsm_ord_prio_settings PUBLIC.
  TYPES: BEGIN OF rule,
           order_type TYPE zsm_e_order_type,
           days_late  TYPE zsm_e_days_late,
           escalate   TYPE abap_boolean,
         END OF rule.

  "! Returns the rule of one order type
  "! @parameter order_type | Order type
  "! @parameter result | The maintained rule
  "! @raising zcx_zsm_ord_prio_missing | No rule is maintained for the order type
  METHODS rule_for
    IMPORTING order_type    TYPE zsm_e_order_type
    RETURNING VALUE(result) TYPE rule
    RAISING   zcx_zsm_ord_prio_missing.
ENDINTERFACE.
```

```abap
"! Reads the order priority rules from the Customizing table
"! ZSM_T_ORD_PRIO of the logon client
CLASS zcl_zsm_ord_prio_settings DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_zsm_ord_prio_settings.
ENDCLASS.


CLASS zcl_zsm_ord_prio_settings IMPLEMENTATION.
  METHOD zif_zsm_ord_prio_settings~rule_for.
    SELECT SINGLE order_type, days_late, escalate
      FROM zsm_t_ord_prio
      WHERE order_type = @order_type
      INTO @result.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_zsm_ord_prio_missing( order_type = order_type ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

`SELECT SINGLE` reads with the full key: the client is added by ABAP SQL ([Rule 7.5](../docs/ABAP-Development-Rules.md#75-use-select-single-only-with-the-full-primary-key), [Rule 7.8](../docs/ABAP-Development-Rules.md#78-let-abap-sql-handle-the-client)). A missing entry is a situation the caller can handle, so it is a checked exception, not an empty rule that silently means "never late" ([Rule 6.3](../docs/ABAP-Development-Rules.md#63-choose-the-exception-category-by-what-the-caller-can-do)).

**Example E2 (continued) — the test include of `zcl_zsm_ord_prio_settings`.** The test double of the table holds the only entries the test sees ([22-ABAP-Unit](../22-ABAP-Unit/README.md)).

```abap
CLASS ltc_ord_prio_settings DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.
    DATA cut TYPE REF TO zif_zsm_ord_prio_settings.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS returns_rule_of_order_type FOR TESTING RAISING cx_static_check.
    METHODS raises_for_missing_rule FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_ord_prio_settings IMPLEMENTATION.
  METHOD class_setup.
    sql_environment = cl_osql_test_environment=>create(
                          i_dependency_list = VALUE #( ( 'ZSM_T_ORD_PRIO' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    " Every test method starts with an empty test double of the table
    sql_environment->clear_doubles( ).
    cut = NEW zcl_zsm_ord_prio_settings( ).
  ENDMETHOD.

  METHOD returns_rule_of_order_type.
    " given
    DATA rules TYPE STANDARD TABLE OF zsm_t_ord_prio WITH EMPTY KEY.
    rules = VALUE #( ( order_type = 'RUSH' days_late = 2  escalate = abap_true )
                     ( order_type = 'STD'  days_late = 10 escalate = abap_false ) ).
    sql_environment->insert_test_data( rules ).

    " when
    DATA(rule) = cut->rule_for( 'RUSH' ).

    " then
    cl_abap_unit_assert=>assert_equals(
        act = rule
        exp = VALUE zif_zsm_ord_prio_settings=>rule( order_type = 'RUSH'
                                                     days_late  = 2
                                                     escalate   = abap_true ) ).
  ENDMETHOD.

  METHOD raises_for_missing_rule.
    " given: no rule in the test double

    TRY.
        " when
        cut->rule_for( 'NONE' ).
        cl_abap_unit_assert=>fail( 'No rule is maintained, so the call must raise' ).

      CATCH zcx_zsm_ord_prio_missing INTO DATA(missing).
        " then
        cl_abap_unit_assert=>assert_equals( act = missing->order_type
                                            exp = 'NONE' ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
```

**To try it:** create the two data elements, E1, and E2's three objects with the test include as local objects, activate, and run the unit tests. Both tests should pass without a single entry in the real table. Then change `days_late` of `RUSH` in the test data and watch `returns_rule_of_order_type` fail.

> 📝 **Activation record.** E1 (with the data elements `zsm_e_order_type` and `zsm_e_days_late`), E2 (`zcx_zsm_ord_prio_missing`, `zif_zsm_ord_prio_settings`, `zcl_zsm_ord_prio_settings` with its test include) and E4a (`zcl_zsm_ord_prio_rules` with its test include) were activated in both ABAP language versions: Standard ABAP and ABAP for Cloud Development. The unit tests of `zcl_zsm_ord_prio_settings` and `zcl_zsm_ord_prio_rules` (6 test methods) were run in both versions, and the test run passed. E3 was activated in Standard ABAP and not run. E4b and the field-control module were not activated: they need a generated maintenance dialog, and none was created. No table entry was written outside the ABAP SQL test double, and no transport request was created.

## 🧭 Scope Note

- **Business Configuration Sets (BC sets)**, the IMG and `SPRO`, and IMG activities are not covered.
- **Client copy and client comparison** are administration and not covered.
- **Mass upload of Customizing** is not covered; a rules class such as E4a is the part an upload program would reuse.
- **The RAP business object** behind a business configuration app belongs to the future RAPGuide; this chapter describes the pieces and stops.
- **Custom lock handling in maintenance dialogs** belongs with lock objects; see [27-Lock-Objects](../27-Lock-Objects/README.md#-locks-in-maintenance-dialogs) and [Rule 7.12](../docs/ABAP-Development-Rules.md#712-protect-business-transactions-with-enqueue-locks).

## ✅ Best Practices

- Keep values that change without a release in Customizing tables, and read them through an interface — [Rule 8.5](../docs/ABAP-Development-Rules.md#85-never-hard-code-credentials-hosts-or-destinations), [Rule 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor).
- Give a Customizing table delivery class C and `#ALLOWED`, and make it client-dependent unless the setting is the same for every client — [Rule 7.16](../docs/ABAP-Development-Rules.md#716-give-every-custom-table-the-delivery-class-of-the-people-who-own-its-data-c-for-customizing-a-for-application-data).
- Name tables, views, clusters, function groups and transactions by the naming table, within 16 characters for tables and views — [Rule 2.6](../docs/ABAP-Development-Rules.md#26-name-development-objects-by-the-object-naming-table).
- Give every dialog its own function group and its own parameter transaction.
- Assign every maintained table to an authorization group, and protect sensitive tables by name — [Rule 8.14](../docs/ABAP-Development-Rules.md#814-assign-an-authorization-group-to-every-table-that-users-maintain-protect-sensitive-tables-additionally-with-s_tabu_nam).
- Keep event routines thin: collect the entries, call a class, set `vim_abort_saving` — [Rule 5.1](../docs/ABAP-Development-Rules.md#51-write-new-logic-in-classes-wrap-function-modules-and-bapis).
- Let the dialog save, record and commit — [Rule 7.17](../docs/ABAP-Development-Rules.md#717-in-table-maintenance-events-change-only-the-dialogs-own-data-the-generated-dialog-saves-and-commits).
- Regenerate selectively after every table change, and transport the dialog with the table.
- Maintain Customizing in development and transport it.
- Test code that reads Customizing with the ABAP SQL test environment — [Rule 10.8](../docs/ABAP-Development-Rules.md#108-isolate-database-access-with-the-abap-sql-and-cds-test-double-frameworks-never-use-real-data).

## ⚠️ Common Mistakes

- A Customizing table left at delivery class A, so its entries are maintained in every system instead of transported.
- A setting hard-coded in a constant "until there is time for a table".
- `MODIFY` or `DELETE` on the maintained table and `COMMIT WORK` inside an event routine.
- Business logic written straight into an event routine or a generated module, where no test reaches it.
- A table maintained without an authorization group, or sensitive tables only in a broad group.
- Treating the parameter transaction as the authorization check.
- Hand-made changes to generated screens that the next regeneration silently overwrites.
- A table field added without regenerating the dialog, found by the users as a short dump.
- Customizing changed directly in production, or cross-client Customizing changed in a test client.
- A table deleted while old requests still contain its keys, so their import fails.
- Change logging switched on for a table that changes all day.
- Business code that reads a Customizing table directly in many places instead of through one settings class.

## 🎤 Interview & Review Checkpoints

- Explain the delivery classes A, C and L, and how the entries of each travel.
- Explain the difference between a client-dependent and a cross-client Customizing table, and which request each change goes into.
- Walk through generating a maintenance dialog: function group, authorization group, maintenance type, screens.
- Explain what a maintenance view can do that a table dialog cannot, and when a view cluster is the better choice.
- Name the authorization objects of table maintenance and what each protects.
- Explain which event you use to validate before saving, how you stop the save, and why the routine must not commit.
- Explain what happens after a field is added to a table with a generated dialog, and how you fix it.
- Explain what replaces `SM30` in ABAP for Cloud Development, and what stays the same.
- Explain how you test code that reads Customizing without depending on the entries of a system.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| SE11 | ABAP Dictionary: tables, views, technical settings |
| SE54 | Generate table maintenance dialogs; edit events and view clusters |
| SM30 | Maintain table and view entries through the generated dialog |
| SM31 | Table maintenance, older entry point to the same dialogs |
| SM34 | Maintain view clusters |
| SE93 | Create a parameter transaction on `SM30` |
| SCU3 | Evaluate table change logs |
| SCC4 | Client settings for Customizing changes (administration) |

## 🔗 Related Chapters

- [08-Open-SQL](../08-Open-SQL/README.md) — client handling and the SAP LUW the dialog owns
- [11-Classical-Reports](../11-Classical-Reports/README.md) — `VIEW_AUTHORITY_CHECK` for generic table access
- [12-Selection-Screens](../12-Selection-Screens/README.md) — dynpro flow logic and `LOOP AT SCREEN`
- [18-Debugging](../18-Debugging/README.md) — Customizing instead of system-dependent code
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — where table maintenance and its cloud replacement sit in the lifecycle map
- [22-ABAP-Unit](../22-ABAP-Unit/README.md) — the ABAP SQL test environment
- [23-Debugging-Troubleshooting](../23-Debugging-Troubleshooting/README.md) — `DYNPRO_SYNTAX_ERROR` and checkpoint groups
- [24-Mail](../24-Mail/README.md) — mail settings from a Customizing table
- [25-HTTP-REST](../25-HTTP-REST/README.md) — destination names from configuration
- [27-Lock-Objects](../27-Lock-Objects/README.md) — the next chapter: the SAP lock concept, and how the dialog locks
- [33-ABAP-Dictionary](../33-ABAP-Dictionary/README.md) — tables, text tables, foreign keys and changing an active table
- [34-Authorization-Checks](../34-Authorization-Checks/README.md) — `AUTHORITY-CHECK`, tracing and testing beyond table maintenance
- [35-Number-Ranges-Change-Documents](../35-Number-Ranges-Change-Documents/README.md) — change documents as the application-level record of changes
