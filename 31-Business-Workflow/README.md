# 31 — Business Workflow and My Inbox

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. SAP Business Workflow, its business objects (BOR) and ABAP classes that implement `IF_WORKFLOW` run the approval and follow-up processes of many Standard ABAP systems; SAP's object classification lists their APIs as classic APIs, not released for ABAP for Cloud Development. Flexible workflow is the approval mechanism of SAP S/4HANA applications. In ABAP for Cloud Development, SAP Build Process Automation and RAP business events take this role: `ABAP CLOUD / MODERN CONTEXT`. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

An order above a limit needs a second approval. Someone has to be asked, the request has to reach them, they may be absent, and after a deadline someone else should be reminded. SAP Business Workflow models such processes: it creates **work items** for the right people, waits for their decisions and continues the process.

Workflow fits processes that span several people, steps and days. It does not fit a single synchronous check, which belongs in code, or mass processing, which belongs in a background job.

This chapter covers:

- the building blocks: workflow definitions, steps, the container, tasks and work items;
- business objects: BOR object types and ABAP classes that implement `IF_WORKFLOW`;
- events and how they start workflows;
- agent determination;
- work items in the Business Workplace and My Inbox;
- deadlines, administration and error handling, as far as a developer needs them;
- flexible workflow in SAP S/4HANA, as far as it was verified;
- what replaces classic workflow in ABAP for Cloud Development, up to the hand-over to other guides;
- testing workflow-related ABAP without starting a workflow.

## 🗺️ Standard ABAP and ABAP for Cloud Development at a Glance

| Topic | Standard ABAP | ABAP for Cloud Development |
|---|---|---|
| Process engine | SAP Business Workflow; flexible workflow in SAP S/4HANA applications | SAP Build Process Automation |
| Business object | BOR object type (`SWO1`) or ABAP class with `IF_WORKFLOW` | RAP business object (RAPGuide) |
| Start | Event through an event linkage (`SWE2`), or a start from code | API trigger or event of SAP Build Process Automation; RAP business events |
| Raising events in ABAP | `CL_SWF_EVT_EVENT`, `SAP_WAPI_CREATE_EVENT` | `RAISE ENTITY EVENT` in a RAP behavior pool; `IF_SWF_CPWF_API` |
| Inbox | Business Workplace (`SBWP`), My Inbox | SAP Build Process Automation inbox **[verify: the inbox of SAP Build Process Automation for tasks started from ABAP]** |
| Release state | `IF_WORKFLOW`, `BI_OBJECT`, `BI_PERSISTENT`, `SAP_WAPI_*`, `SWO_*`: classic API; `CL_SWF_EVT_EVENT`: not listed | `IF_SWF_CPWF_API`, `IF_SWF_CPWF_API_FACTORY`, `IF_SWF_CPWF_CALLBACK`, `CL_SWF_CPWF_API_FACTORY_A4C`: released |

The release states come from SAP's lists of released and classified objects. Workflow definitions, tasks, BOR object types and event linkages cannot be created through ADT in the systems used for this chapter; they are maintained in SAP GUI.

## 🧩 Building Blocks

- **Workflow definition** (Workflow Builder, `SWDD`): the process as a sequence of steps — activities, user decisions, conditions, loops, waits for events.
- **Workflow container**: the process's variables, for example the order. Data moves between the workflow and its steps through **bindings**. Each container element is flagged for import, export or both; according to SAP's support content (*Getting started with ABAP OO for Workflow*), a task based on a class automatically gets a container element for the class instance, marked for import and export **[verify: container element types and binding rules in your release]**.
- **Task** (`PFTC`): a reusable unit of work that calls one method of a business object; a step executes a task. A task names its possible agents.
- **Work item**: the runtime instance of a step, for example "Approve order 42" in someone's inbox.

Workflow definitions and tasks are repository objects that travel in workbench requests ([29-Transport-Quality-Gates](../29-Transport-Quality-Gates/README.md#-the-change-and-transport-system)).

## 🧱 Business Objects: BOR and ABAP Classes

A workflow works on business objects: it passes them between steps, calls their methods and reacts to their events.

- **BOR object types** (Business Object Builder, `SWO1`) are the original form. Many delivered workflows use them, and existing ones are maintained there. SAP's object classification lists the BOR runtime (`SWO_CREATE`, `SWO_INVOKE` and related modules) as classic API.
- **ABAP classes** can be used in the workflow engine's definition and runtime in the same way as BOR object types, according to SAP's documentation, if they implement **`IF_WORKFLOW`**. This guide uses classes for new workflow objects, because they are ordinary ABAP that ADT edits and ABAP Unit tests.

`IF_WORKFLOW` contains `BI_PERSISTENT`, which contains `BI_OBJECT`:

| Method | Purpose |
|---|---|
| `BI_PERSISTENT~FIND_BY_LPOR` | Static. The engine passes a persistent object reference (LPOR) and gets the instance back |
| `BI_PERSISTENT~LPOR` | Returns the LPOR of the instance |
| `BI_PERSISTENT~REFRESH` | Refreshes buffered data |
| `BI_OBJECT~DEFAULT_ATTRIBUTE_VALUE` | Returns a reference to the value shown for the object |
| `BI_OBJECT~EXECUTE_DEFAULT_METHOD` | Runs the object's default method |
| `BI_OBJECT~RELEASE` | Releases the instance |

The LPOR is the structure `SIBFLPOR`: `CATID` (`CL` for ABAP classes), `TYPEID` (the class name) and `INSTID` (the key, at most 32 characters). According to SAP's documentation, `FIND_BY_LPOR` should always return the same instance for the same key, because the engine manages no instances itself for classes with their own persistence; two instances of one order would show different data, overwrite each other or collide on locks.

SAP's documentation also advises that application classes should not implement `IF_WORKFLOW` themselves: implementing it releases the class for any workflow, after which it may change only compatibly. A separate workflow class calls the application's classes instead ([Rule 5.14](../docs/ABAP-Development-Rules.md#514-keep-business-logic-out-of-workflow-definitions-bor-methods-and-task-bindings-workflow-steps-call-methods-of-tested-classes)).

**Example E1 — the order as a workflow object.** Target: Standard ABAP (`IF_WORKFLOW` is not released for ABAP for Cloud Development).

```abap
"! The order as the workflow engine sees it. It only maps an order to a
"! persistent object reference and back, and declares the events that
"! start workflows; decisions live in tested classes (Rule 5.14).
CLASS zcl_zsm_wf_order DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    INTERFACES if_workflow.

    TYPES order_key TYPE c LENGTH 10.

    "! An order was released
    EVENTS released.
    "! An order waits for a second approval
    EVENTS approval_requested.

    DATA order_id TYPE order_key READ-ONLY.

    "! Returns the one instance for an order, so that every workflow
    "! step works on the same object
    "! @parameter order_id | Order
    "! @parameter result | Instance for the order
    CLASS-METHODS get_instance
      IMPORTING order_id      TYPE order_key
      RETURNING VALUE(result) TYPE REF TO zcl_zsm_wf_order.

  PRIVATE SECTION.
    TYPES: BEGIN OF buffered_instance,
             order_id TYPE order_key,
             instance TYPE REF TO zcl_zsm_wf_order,
           END OF buffered_instance.

    " Object category of ABAP classes in a persistent object reference
    CONSTANTS category_class TYPE sibfcatid VALUE 'CL'.

    CLASS-DATA instances TYPE HASHED TABLE OF buffered_instance WITH UNIQUE KEY order_id.

    METHODS constructor
      IMPORTING order_id TYPE order_key.
ENDCLASS.


CLASS zcl_zsm_wf_order IMPLEMENTATION.
  METHOD get_instance.
    " The workflow engine manages no instances itself; one per key avoids
    " diverging data and lock collisions between steps
    result = VALUE #( instances[ order_id = order_id ]-instance OPTIONAL ).
    IF result IS NOT BOUND.
      result = NEW #( order_id ).
      INSERT VALUE #( order_id = order_id instance = result ) INTO TABLE instances.
    ENDIF.
  ENDMETHOD.

  METHOD constructor.
    me->order_id = order_id.
  ENDMETHOD.

  METHOD bi_persistent~find_by_lpor.
    result = get_instance( CONV #( lpor-instid ) ).
  ENDMETHOD.

  METHOD bi_persistent~lpor.
    result = VALUE #( catid  = category_class
                      typeid = 'ZCL_ZSM_WF_ORDER'
                      instid = order_id ).
  ENDMETHOD.

  METHOD bi_persistent~refresh.
    " Nothing to refresh: the object holds only its key
    RETURN.
  ENDMETHOD.

  METHOD bi_object~default_attribute_value.
    result = REF #( order_id ).
  ENDMETHOD.

  METHOD bi_object~execute_default_method.
    " No default method: displaying an order belongs to the application UI
    RETURN.
  ENDMETHOD.

  METHOD bi_object~release.
    " Instances stay buffered for the session; nothing to release
    RETURN.
  ENDMETHOD.
ENDCLASS.
```

> ⚠️ **A type and an attribute of one class cannot share a name.** The first version declared `TYPES order_id` next to `DATA order_id`; the editor rejected it, and the type became `order_key`. The same happened in chapter 28.

A workflow step that needs a decision calls a method of this class, which passes the question on to a tested class such as E2 below. According to SAP's support content (*Getting started with ABAP OO for Workflow*), when a task names the method, the Workflow Builder offers to copy the method's importing and exporting parameters into the task container; functional methods, those with a `RETURNING` parameter, can also be used directly in bindings.

## 📣 Events and How They Start Workflows

> ⚠️ **A workflow event is not an ABAP class event.** `RAISE EVENT` in [10-Objects](../10-Objects/README.md#-events) calls the handlers registered in the same program. A workflow event goes to the **event manager**, which looks for linkages and starts or continues workflows, often in another process.

According to SAP's documentation:

- A **type linkage** assigns a receiver to a combination of object type and event; it is used to start workflows or tasks whenever that event occurs. An **instance linkage** continues a running work item that waits for an event of one object.
- For each active linkage, the event manager may call a **receiver type function module** (determines the receiver at runtime), then a **check function module** (if it raises an exception, the linkage is not executed), and finally the **receiver function module** with the event, the receiver type and the event container. The receiver function module must be remote-enabled and passes no return values or exceptions back.
- If no linkage is active, the event has no effect.

Type linkages are maintained in `SWE2` (*Maintain Event Type Linkages*). For own developments they are set up by hand; this chapter creates none.

**Raising an event from ABAP.** In Standard ABAP, `CL_SWF_EVT_EVENT` raises events for ABAP classes (object category `CL`) and BOR object types. `RAISE` raises immediately; `RAISE_IN_UPDATE_TASK` registers the event so that it is raised with the caller's `COMMIT WORK`. Both raise `CX_SWF_EVT_INVALID_OBJTYPE` and `CX_SWF_EVT_INVALID_EVENT`. The classic `SAP_WAPI_CREATE_EVENT` raises an event as well, but its parameter `COMMIT_WORK` defaults to `'X'`: called with defaults, it commits the caller's transaction ([Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work)).

Raise events only for committed data ([Rule 7.20](../docs/ABAP-Development-Rules.md#720-raise-a-workflow-event-only-for-committed-data-in-the-update-task-or-after-the-callers-commit)). A workflow started for an order that is rolled back afterwards asks someone to approve something that does not exist.

**Example E3 — announcing order events.** Target: interface and exception class Standard ABAP and ABAP for Cloud Development; the implementation Standard ABAP. The exception class keeps the inherited constructor, as in [24-Mail](../24-Mail/README.md#-design-compose-the-mail-send-it-through-an-interface).

```abap
"! Raised when a business event about an order cannot be announced.
"! The cause travels as PREVIOUS. No message class: the class keeps the
"! inherited constructor (TEXTID, PREVIOUS).
CLASS zcx_zsm_order_event_failed DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
ENDCLASS.


CLASS zcx_zsm_order_event_failed IMPLEMENTATION.
ENDCLASS.
```

```abap
"! Announces business events about orders. Implementations announce
"! only committed data: they raise in the update task or after the
"! caller's commit (Rule 7.20), and they never commit themselves.
INTERFACE zif_zsm_order_events PUBLIC.
  TYPES order_id TYPE c LENGTH 10.

  "! @parameter order_id | Released order
  "! @raising zcx_zsm_order_event_failed | The event could not be announced
  METHODS order_released
    IMPORTING order_id TYPE order_id
    RAISING   zcx_zsm_order_event_failed.

  "! @parameter order_id | Order that waits for a second approval
  "! @raising zcx_zsm_order_event_failed | The event could not be announced
  METHODS approval_requested
    IMPORTING order_id TYPE order_id
    RAISING   zcx_zsm_order_event_failed.
ENDINTERFACE.
```

```abap
"! Announces order events as workflow events of the class ZCL_ZSM_WF_ORDER.
"! The events are raised in the update task, so they exist only after the
"! caller's COMMIT WORK (Rule 7.20).
CLASS zcl_zsm_order_events_wf DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_zsm_order_events.

  PRIVATE SECTION.
    CONSTANTS workflow_class TYPE seoclsname VALUE 'ZCL_ZSM_WF_ORDER'.

    METHODS raise_workflow_event
      IMPORTING event    TYPE csequence
                order_id TYPE zif_zsm_order_events=>order_id
      RAISING   zcx_zsm_order_event_failed.
ENDCLASS.


CLASS zcl_zsm_order_events_wf IMPLEMENTATION.
  METHOD zif_zsm_order_events~order_released.
    raise_workflow_event( event = 'RELEASED' order_id = order_id ).
  ENDMETHOD.

  METHOD zif_zsm_order_events~approval_requested.
    raise_workflow_event( event = 'APPROVAL_REQUESTED' order_id = order_id ).
  ENDMETHOD.

  METHOD raise_workflow_event.
    TRY.
        cl_swf_evt_event=>raise_in_update_task( im_objcateg = cl_swf_evt_event=>mc_objcateg_cl
                                                im_objtype  = workflow_class
                                                im_event    = event
                                                im_objkey   = order_id ).

      CATCH cx_swf_evt_invalid_objtype cx_swf_evt_invalid_event INTO DATA(event_error).
        RAISE EXCEPTION NEW zcx_zsm_order_event_failed( previous = event_error ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
```

The event names are the events declared in E1. Which workflow starts on them is decided by the type linkage, not by the code. According to SAP's support content (*Getting started with ABAP OO for Workflow*), the workflow definition names its start event with object category `CL`, the class and the event; the Workflow Builder generates the binding from the event container and activates the linkage, which `SWE2` then lists.

## 👥 Agent Determination

A task names its **possible agents**: who may execute it at all. A step narrows this to the **responsible agents** for one process instance, often through a **rule** **[verify: the agent types and their precedence in your release]**.

A rule can be implemented by a function module with a fixed interface. SAP's delivered rule function module `SWX_GET_MANAGER` shows it: `TABLES actor_tab LIKE swhactor` (the agents found, each with an object type such as user or position, and an ID), `TABLES ac_container LIKE swcont` (the rule's input), and the exception `nobody_found`.

- Determine agents from organizational assignments or from configuration, never from user IDs in code ([Rule 8.16](../docs/ABAP-Development-Rules.md#816-determine-workflow-agents-through-rules-and-organizational-assignments-never-hard-code-user-ids)). People change roles; a user ID in code sends work to someone who left.
- Raise `nobody_found` when no agent can be determined, instead of returning an empty table that leaves the work item without anyone to process it.

**Example E5 — a rule function module.**

> 📝 **Contextual snippet** — a function module in a function group, registered as a rule; `zsm_t_approver` is a placeholder Customizing table that assigns an approving position per plant, and the container element `PLANT` is assumed. The workflow container macros of older code are replaced by a plain table read. Standard ABAP only.

```abap
FUNCTION zsm_fm_order_approvers
  TABLES
    actor_tab    STRUCTURE swhactor
    ac_container STRUCTURE swcont
  EXCEPTIONS
    nobody_found.

  " The rule reads its input from the container and its answer from
  " configuration (Rule 8.16)
  DATA(plant) = VALUE #( ac_container[ element = 'PLANT' ]-value OPTIONAL ).

  SELECT SINGLE approver_position
    FROM zsm_t_approver
    WHERE plant = @plant
    INTO @DATA(position).
  IF sy-subrc <> 0.
    RAISE nobody_found.
  ENDIF.

  actor_tab[] = VALUE #( ( otype = 'S' objid = position ) ).
ENDFUNCTION.
```

**[verify: the container structure `SWCONT` and the object type of a position in your release]**

## 📥 Work Items, Business Workplace and My Inbox

Users process work items in the **Business Workplace** (`SBWP`) in SAP GUI, or in the SAP Fiori app **My Inbox**. My Inbox shows the work items of the tasks that the user's business roles expose and needs the task processing service to be available **[verify: the roles and services My Inbox needs in your release]**. A custom task UI in My Inbox is built as a Fiori application; see the future UIGuide.

From ABAP, the classic `SAP_WAPI_*` modules read and process work items (for example `SAP_WAPI_GET_WORKITEM_DETAIL`, `SAP_WAPI_WORKITEM_COMPLETE`). SAP's classification lists them as classic API. Like `SAP_WAPI_CREATE_EVENT`, `SAP_WAPI_START_WORKFLOW` commits by default: its parameter `DO_COMMIT` defaults to `'X'`. Check the commit parameter of every `SAP_WAPI_*` module you call, and call them only where the program owns the transaction, or pass the parameter explicitly.

## ⏰ Deadlines and Escalation

A step can carry deadlines, for example for the start or the end of processing; when a deadline is missed, the workflow can notify someone or take another path. For flexible workflow, SAP Help (*Create a Scenario*) describes that a step whose deadline is reached is marked *Overdue*, that the agents can be notified before that, and that a deadline of 0 time units sends the notification as soon as the work item is created **[verify: the deadline types of SAP Business Workflow steps and their monitoring in your release]**. A notification mail follows the patterns of [24-Mail](../24-Mail/README.md): addresses from configuration, no personal data beyond what the recipient needs.

## 🛠️ Administration and Error Handling for Developers

The transactions a developer meets when a workflow does not start or stops:

| T-code | Purpose |
|---|---|
| `SWEL` | Display the event trace: was the event raised, and which linkage reacted? |
| `SWUE` | Trigger an event by hand, in a development system |
| `SWE2` | Event type linkages: active or not, receiver, check function module |
| `SWU3` | Automatic workflow Customizing: checks the basic setup |
| `SWI1` | Select work items |
| `SWIA` | Administer work items |
| `SWPR` | Restart erroneous workflows |

- **An event that starts nothing** usually means an inactive or missing linkage, or a check function module that raised an exception; the event trace shows which.
- **A workflow in error** shows the failing step and its message in the workflow log. Fix the cause, then restart it with `SWPR` — in production only through the support process.
- **Trigger events by hand** (`SWUE`) only in development or test systems.
- **Switch the event trace on before you need it.** According to SAP's support content (*Workflow Diagnosis*), `SWEL` shows events only while the event log is active, which is checked in `SWELS`; it can stay on while a new workflow goes live but should not stay on in production, and the same applies to the workflow trace.

## 🔄 Flexible Workflow in SAP S/4HANA

SAP S/4HANA applications deliver approval processes as **flexible workflows**. A developer defines a **scenario** in the scenario editor (`SWDD_SCENARIO`). According to SAP Help (*Create a Scenario*), the scenario's flexible block holds the process data such as the leading object and its events, the activities (dialog and background steps), the conditions, the agent rules, value helps, reference times for deadlines, mail templates and deadline actions, plus callback classes and optional pre-delivered content. Agent rules of the rule type are maintained in `PFAC` and roles in `PFCG`; when no agent is found, the scenario's runtime class can supply one in `MITIGATE_AGENT_RULE_EVALUATION`, and otherwise the callback `ON_NO_AGENT_FOUND` is called.

Business experts then model the actual workflows from the scenario in the SAP Fiori app *Manage Workflows*. According to SAP Help (*Flexible Workflow*, SAP S/4HANA on-premise), the definitions are created and activated there; when the scenario starts, exactly one active definition whose start conditions apply is selected, in the order set in the app, and a pre-delivered definition can be shipped by the developer. SAP describes flexible workflow as an extension of SAP Business Workflow and as the default workflow engine in SAP S/4HANA for approval scenarios such as purchase requisitions, purchase orders and journal entries.

Extensions use released interfaces and BAdIs, among them:

| BAdI definition | Interface | Purpose |
|---|---|---|
| `SWF_WORKFLOW_CONDITION_DEF` | `IF_SWF_FLEX_IFS_CONDITION_DEF` | Define additional start or step conditions |
| `SWF_WORKFLOW_CONDITION_EVAL` | `IF_SWF_FLEX_IFS_CONDITION_EVAL` | Evaluate those conditions; called for a `start` or a `step` context |
| `SWF_FORWARD_AGENTS_GET_CUSTOM` | `IF_SWF_FLEX_IFS_WI_FORWARD_CUS` | Determine agents for forwarding |
| `SWF_CHECK_ACTION_ALLOWED` | — | Allow or prevent inbox actions **[verify: its interface]** |

SAP's release information lists these as released. Implementing a BAdI is shown in [16-BADIs](../16-BADIs/README.md).

## ☁️ ABAP for Cloud Development: What Replaces Classic Workflow

ABAP for Cloud Development has no Workflow Builder, no BOR and no released `IF_WORKFLOW`. Two mechanisms take its place; this guide names them and hands over:

- **SAP Build Process Automation** models processes outside the ABAP system. A process starts through a trigger: a form, an API call or an event; the external system can be SAP S/4HANA or the SAP BTP ABAP environment, according to SAP's tutorial. From ABAP, the released `IF_SWF_CPWF_API` (created through `CL_SWF_CPWF_API_FACTORY_A4C`) offers, among others, `START_WORKFLOW`, `REGISTER_WORKFLOW`, `CANCEL_WORKFLOW`, `GET_WORKFLOW_STATUS`, `GET_WORKFLOW_LOG`, `GET_USER_TASK_INSTANCES`, `RAISE_EVENT` and `API_TRIGGER`; results come back through a class that implements `IF_SWF_CPWF_CALLBACK` **[verify: setup, parameters and communication arrangement]**. Process modelling belongs to the planned SAP-Architecture-Guide.
- **RAP business events.** A RAP business object raises an event with `RAISE ENTITY EVENT` in its behavior pool, according to the ABAP Keyword Documentation preferably in the saver methods, and consumers react to it. RAP is outside this guide ([21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-scope-boundary)); see the future RAPGuide.

## 🧪 Testing Workflow-Related ABAP

A unit test never raises a workflow event, starts a workflow or creates a work item: those reach the event manager and other users' inboxes. What can be tested is the ABAP around the workflow ([22-ABAP-Unit](../22-ABAP-Unit/README.md#-test-doubles-through-interfaces)):

- the decisions, in plain classes behind interfaces (E2);
- the business service that announces events, with a double for the events interface (E4);
- the workflow class's LPOR round trip and its one instance per key (E1's tests).

**Example E2 — the approval rule.** Target: Standard ABAP and ABAP for Cloud Development.

```abap
"! Decides whether an order needs a second approval.
INTERFACE zif_zsm_order_approval PUBLIC.
  TYPES amount TYPE p LENGTH 15 DECIMALS 2.

  "! @parameter amount | Order value in the company currency
  "! @parameter result | abap_true if a second approval is needed
  METHODS needs_second_approval
    IMPORTING amount        TYPE amount
    RETURNING VALUE(result) TYPE abap_bool.
ENDINTERFACE.
```

```abap
"! Orders above a limit need a second approval. The limit comes from
"! configuration, for example a Customizing table (Rule 7.16).
CLASS zcl_zsm_order_approval DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_zsm_order_approval.

    "! @parameter limit | Highest order value released without a second approval
    METHODS constructor
      IMPORTING limit TYPE zif_zsm_order_approval=>amount.

  PRIVATE SECTION.
    DATA limit TYPE zif_zsm_order_approval=>amount.
ENDCLASS.


CLASS zcl_zsm_order_approval IMPLEMENTATION.
  METHOD constructor.
    me->limit = limit.
  ENDMETHOD.

  METHOD zif_zsm_order_approval~needs_second_approval.
    result = xsdbool( amount > limit ).
  ENDMETHOD.
ENDCLASS.
```

```abap
CLASS ltc_order_approval DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_zsm_order_approval.

    METHODS setup.
    METHODS releases_order_below_limit FOR TESTING.
    METHODS releases_order_at_limit FOR TESTING.
    METHODS asks_approval_above_limit FOR TESTING.
ENDCLASS.


CLASS ltc_order_approval IMPLEMENTATION.
  METHOD setup.
    cut = NEW zcl_zsm_order_approval( limit = 1000 ).
  ENDMETHOD.

  METHOD releases_order_below_limit.
    cl_abap_unit_assert=>assert_false( cut->needs_second_approval( 999 ) ).
  ENDMETHOD.

  METHOD releases_order_at_limit.
    cl_abap_unit_assert=>assert_false( cut->needs_second_approval( 1000 ) ).
  ENDMETHOD.

  METHOD asks_approval_above_limit.
    cl_abap_unit_assert=>assert_true( cut->needs_second_approval( '1000.01' ) ).
  ENDMETHOD.
ENDCLASS.
```

**Example E4 — the release service.** Target: Standard ABAP and ABAP for Cloud Development. It decides with E2 and announces the result through E3's interface; it never commits.

```abap
"! Releases orders: small orders directly, large ones after a second
"! approval. It announces the result through an interface and never
"! commits; the caller commits, and with it the event goes out
"! (Rules 7.10, 7.20).
CLASS zcl_zsm_order_release DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ENUM outcome,
             none,
             released,
             approval_requested,
           END OF ENUM outcome.

    METHODS constructor
      IMPORTING approval TYPE REF TO zif_zsm_order_approval
                events   TYPE REF TO zif_zsm_order_events.

    "! @parameter order_id | Order to release
    "! @parameter amount | Order value in the company currency
    "! @parameter result | Whether the order was released or waits for approval
    "! @raising zcx_zsm_order_event_failed | The event could not be announced
    METHODS release
      IMPORTING order_id      TYPE zif_zsm_order_events=>order_id
                amount        TYPE zif_zsm_order_approval=>amount
      RETURNING VALUE(result) TYPE outcome
      RAISING   zcx_zsm_order_event_failed.

  PRIVATE SECTION.
    DATA approval TYPE REF TO zif_zsm_order_approval.
    DATA events   TYPE REF TO zif_zsm_order_events.
ENDCLASS.


CLASS zcl_zsm_order_release IMPLEMENTATION.
  METHOD constructor.
    me->approval = approval.
    me->events   = events.
  ENDMETHOD.

  METHOD release.
    IF approval->needs_second_approval( amount ).
      events->approval_requested( order_id ).
      result = approval_requested.
    ELSE.
      events->order_released( order_id ).
      result = released.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

E4's test include, with a double for the events:

```abap
"! Test double for the events: records what was announced and can fail.
"! It never raises a workflow event.
CLASS lth_order_events DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_zsm_order_events.

    TYPES announcements TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    DATA announced TYPE announcements READ-ONLY.

    METHODS fail_on_announce.

  PRIVATE SECTION.
    DATA fail TYPE abap_bool.

    METHODS announce
      IMPORTING text TYPE string
      RAISING   zcx_zsm_order_event_failed.
ENDCLASS.


CLASS lth_order_events IMPLEMENTATION.
  METHOD fail_on_announce.
    fail = abap_true.
  ENDMETHOD.

  METHOD zif_zsm_order_events~order_released.
    announce( |RELEASED { order_id }| ).
  ENDMETHOD.

  METHOD zif_zsm_order_events~approval_requested.
    announce( |APPROVAL_REQUESTED { order_id }| ).
  ENDMETHOD.

  METHOD announce.
    IF fail = abap_true.
      RAISE EXCEPTION NEW zcx_zsm_order_event_failed( ).
    ENDIF.
    INSERT text INTO TABLE announced.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_order_release DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA events TYPE REF TO lth_order_events.
    DATA cut    TYPE REF TO zcl_zsm_order_release.

    METHODS setup.
    METHODS releases_small_order FOR TESTING RAISING cx_static_check.
    METHODS asks_approval_for_large_order FOR TESTING RAISING cx_static_check.
    METHODS passes_event_failure_on FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_order_release IMPLEMENTATION.
  METHOD setup.
    events = NEW #( ).
    cut = NEW #( approval = NEW zcl_zsm_order_approval( limit = 1000 )
                 events   = events ).
  ENDMETHOD.

  METHOD releases_small_order.
    " when
    DATA(outcome) = cut->release( order_id = '0000000042'
                                  amount   = 500 ).

    " then
    cl_abap_unit_assert=>assert_equals( act = outcome
                                        exp = zcl_zsm_order_release=>released ).
    cl_abap_unit_assert=>assert_equals( act = events->announced
                                        exp = VALUE lth_order_events=>announcements( ( `RELEASED 0000000042` ) ) ).
  ENDMETHOD.

  METHOD asks_approval_for_large_order.
    " when
    DATA(outcome) = cut->release( order_id = '0000000042'
                                  amount   = 5000 ).

    " then
    cl_abap_unit_assert=>assert_equals( act = outcome
                                        exp = zcl_zsm_order_release=>approval_requested ).
    cl_abap_unit_assert=>assert_equals( act = events->announced
                                        exp = VALUE lth_order_events=>announcements( ( `APPROVAL_REQUESTED 0000000042` ) ) ).
  ENDMETHOD.

  METHOD passes_event_failure_on.
    " given
    events->fail_on_announce( ).

    TRY.
        " when
        cut->release( order_id = '0000000042'
                      amount   = 500 ).
        cl_abap_unit_assert=>fail( 'An event failure must reach the caller' ).

      CATCH zcx_zsm_order_event_failed INTO DATA(failed).
        " then
        cl_abap_unit_assert=>assert_bound( failed ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
```

E1's test include checks the workflow class without the engine:

```abap
CLASS ltc_wf_order DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS lpor_names_class_and_key FOR TESTING.
    METHODS finds_same_instance_by_lpor FOR TESTING.
    METHODS one_instance_per_order FOR TESTING.
ENDCLASS.


CLASS ltc_wf_order IMPLEMENTATION.
  METHOD lpor_names_class_and_key.
    " when
    DATA(lpor) = zcl_zsm_wf_order=>get_instance( '0000000042' )->bi_persistent~lpor( ).

    " then
    cl_abap_unit_assert=>assert_equals( act = lpor-catid  exp = 'CL' ).
    cl_abap_unit_assert=>assert_equals( act = lpor-typeid exp = 'ZCL_ZSM_WF_ORDER' ).
    cl_abap_unit_assert=>assert_equals( act = lpor-instid exp = '0000000042' ).
  ENDMETHOD.

  METHOD finds_same_instance_by_lpor.
    " given
    DATA(order) = zcl_zsm_wf_order=>get_instance( '0000000042' ).

    " when
    DATA(found) = zcl_zsm_wf_order=>bi_persistent~find_by_lpor( order->bi_persistent~lpor( ) ).

    " then
    cl_abap_unit_assert=>assert_true( xsdbool( found = order ) ).
  ENDMETHOD.

  METHOD one_instance_per_order.
    " when
    DATA(first) = zcl_zsm_wf_order=>get_instance( '0000000042' ).
    DATA(other) = zcl_zsm_wf_order=>get_instance( '0000000043' ).

    " then
    cl_abap_unit_assert=>assert_true( xsdbool( first = zcl_zsm_wf_order=>get_instance( '0000000042' ) ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( first = other ) ).
  ENDMETHOD.
ENDCLASS.
```

> 📝 **Activation record.** E2 (`zif_zsm_order_approval`, `zcl_zsm_order_approval` with its test include), E3's interface and exception class (`zif_zsm_order_events`, `zcx_zsm_order_event_failed`) and E4 (`zcl_zsm_order_release` with its test include) were activated in both ABAP language versions: Standard ABAP and ABAP for Cloud Development. E1 (`zcl_zsm_wf_order` with its test include) and E3's implementation (`zcl_zsm_order_events_wf`) were activated in Standard ABAP; E1's first version failed because a type and an attribute shared a name (callout above). The tests of E1 (3 methods, Standard ABAP), E2 (3) and E4 (3) were run, E2 and E4 in both versions, and the test runs passed. The active versions were read back and matched the sources; the check tools returned no warnings. No unit test calls `CL_SWF_EVT_EVENT` or a `SAP_WAPI_*` module; E3's implementation was not run. No event was raised, no workflow started and no work item created; no event linkage, agent assignment, task, BOR object or workflow definition was created or changed. E5 is a contextual snippet.

## 🧭 Scope Note

Not covered in this chapter:

- **Modelling in the Workflow Builder** in depth: step types, loops, forks, container expressions.
- **Organizational management** (organizational units, positions) behind agent determination.
- **A custom task UI in My Inbox** — the future UIGuide.
- **SAP Build Process Automation modelling** — the planned SAP-Architecture-Guide.
- **RAP business events** — the future RAPGuide.
- **Release strategies** in purchasing and other functional approval Customizing.
- **Workflow container macros** (`SWC_*`) of older code.

## ✅ Best Practices

- Use workflow for multi-person, multi-step processes; keep single checks in code.
- Write new workflow objects as ABAP classes with `IF_WORKFLOW`, kept thin, separate from the application classes.
- Return one instance per key from `FIND_BY_LPOR`.
- Put decisions into tested classes; workflow steps call them ([Rule 5.14](../docs/ABAP-Development-Rules.md#514-keep-business-logic-out-of-workflow-definitions-bor-methods-and-task-bindings-workflow-steps-call-methods-of-tested-classes)).
- Raise events in the update task or after the commit ([Rule 7.20](../docs/ABAP-Development-Rules.md#720-raise-a-workflow-event-only-for-committed-data-in-the-update-task-or-after-the-callers-commit)).
- Determine agents through rules and configuration; raise `nobody_found` when there is no agent ([Rule 8.16](../docs/ABAP-Development-Rules.md#816-determine-workflow-agents-through-rules-and-organizational-assignments-never-hard-code-user-ids)).
- Put event raising behind an interface so that callers are tested with a double.
- Check the event trace before changing code when a workflow does not start.

## ⚠️ Common Mistakes

- Confusing ABAP class events (`RAISE EVENT`) with workflow events.
- Raising a workflow event before the data is committed.
- Calling `SAP_WAPI_CREATE_EVENT` or `SAP_WAPI_START_WORKFLOW` with defaults inside a reusable unit, which commits the caller's transaction.
- Implementing `IF_WORKFLOW` in an application class, which then can no longer change freely.
- `FIND_BY_LPOR` creating a new instance on every call.
- Hard-coding user IDs as agents, or returning an empty agent table instead of `nobody_found`.
- Business rules in workflow conditions, task bindings or BOR methods that no test reaches.
- Triggering events by hand or restarting workflows in production outside the support process.
- Unit tests that raise events or start workflows.

## 🎤 Interview & Review Checkpoints

- When does a process need a workflow, and when is code enough?
- What is the difference between a workflow definition, a task and a work item?
- What must an ABAP class implement to be used in workflow, and why should `FIND_BY_LPOR` return the same instance?
- How does an event start a workflow? Name the function modules a linkage can call.
- Why raise events in the update task?
- How are agents determined, and what should a rule do when it finds nobody?
- Which transactions show why a workflow did not start?
- What replaces classic workflow in ABAP for Cloud Development?
- How do you test workflow-related code without starting a workflow?

## 🖥️ Related Transaction Codes

| T-code | Purpose |
|---|---|
| `SWDD` | Workflow Builder |
| `SWDD_SCENARIO` | Flexible workflow: scenario editor |
| `PFTC` | Task maintenance |
| `SWO1` | Business Object Builder |
| `SWE2` | Event type linkages |
| `SWEL` | Event trace |
| `SWUE` | Trigger an event |
| `SWU3` | Automatic workflow Customizing |
| `SBWP` | Business Workplace |
| `SWI1` | Work item selection |
| `SWIA` | Work item administration |
| `SWPR` | Restart erroneous workflows |

## 🔗 Related Chapters

- [10-Objects](../10-Objects/README.md) — ABAP class events, which are not workflow events
- [16-BADIs](../16-BADIs/README.md) — implementing the flexible-workflow BAdIs
- [22-ABAP-Unit](../22-ABAP-Unit/README.md) — test doubles for the events interface
- [24-Mail](../24-Mail/README.md) — notification mails
- [29-Transport-Quality-Gates](../29-Transport-Quality-Gates/README.md) — transporting workflow definitions and tasks
- [30-Tools-AI-Assistance](../30-Tools-AI-Assistance/README.md) — the previous chapter; SAP GUI tools that remain
- [32-IDoc-ALE](../32-IDoc-ALE/README.md) — the next chapter: IDoc and ALE, and the error workflow of inbound IDocs
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle of classic workflow and what replaces it
