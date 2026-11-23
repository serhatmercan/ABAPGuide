# 32 — IDoc and ALE

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. IDocs and Application Link Enabling (ALE) connect many Standard ABAP systems with each other and with EDI partners. SAP's object classification lists the IDoc and ALE function modules as classic APIs; none is released for ABAP for Cloud Development. In SAP S/4HANA Cloud and the SAP BTP ABAP environment, released APIs, business events and SAP Integration Suite take this role: `ABAP CLOUD / MODERN CONTEXT`. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

An **IDoc** (intermediate document) is a container for business data in a fixed, system-independent format: an order, a delivery, a material master. **ALE** distributes IDocs between SAP systems, and the same IDoc interface exchanges them with external partners through EDI. The exchange is asynchronous: the sender stores the IDoc and hands it on; the receiver stores it and posts it when it can.

IDocs fit when documents must travel reliably between systems that are not always available at the same time, when partners already speak IDoc or EDI, and when every document needs a trace and a way to reprocess it. They fit less when the caller needs an answer at once; a synchronous API ([25-HTTP-REST](../25-HTTP-REST/README.md), RFC in [09-Modularization](../09-Modularization/README.md#-calling-a-function-module)) does that.

This chapter covers:

- the structure of an IDoc and its message type;
- ports, logical systems, partner profiles and the distribution model, as far as a developer needs them;
- outbound processing, including change pointers and sending from ABAP;
- inbound processing, status handling and posting through BAPIs;
- custom IDoc types and extensions;
- monitoring, reprocessing and the test tool;
- what replaces IDocs in ABAP for Cloud Development and SAP S/4HANA Cloud, up to the hand-over;
- testing IDoc-related ABAP without creating or processing an IDoc.

## 🗺️ Standard ABAP and ABAP for Cloud Development at a Glance

| Topic | Standard ABAP | ABAP for Cloud Development / SAP S/4HANA Cloud |
|---|---|---|
| Document exchange | IDocs through ALE or EDI | Released APIs (OData, SOAP), business events, SAP Integration Suite **[verify: which replaces a given IDoc in your scenario]** |
| Configuration | `SALE`, `BD54`, `WE21`, `WE20`, `BD64` (SAP GUI) | Communication arrangements and integration content **[verify]** |
| Sending from ABAP | `MASTER_IDOC_DISTRIBUTE` | A released API or event of the business object |
| Receiving | Inbound function module behind a process code | Released inbound API |
| Monitoring | `WE02`, `WE05`, `BD87` | Monitoring of the integration platform **[verify]** |
| Release state | IDoc and ALE function modules: classic API; `EDIDC`, `EDIDD`: not listed | No IDoc API released; the ATC check `ATC_IDOC_CONS` is released |

The release states come from SAP's lists of released and classified objects. In the SAP BTP ABAP environment used for this chapter, `MASTER_IDOC_DISTRIBUTE` and `EDIDC` exist but are not released.

## 🧩 IDoc Structure

An IDoc consists of three kinds of records:

| Record | Structure | Content |
|---|---|---|
| Control record | `EDIDC` | One per IDoc: IDoc number (`DOCNUM`), current status, direction, sender and receiver (port, partner type, partner number), message type (`MESTYP`), basic type (`IDOCTP`), extension (`CIMTYP`) |
| Data records | `EDIDD` | One per segment: segment number (`SEGNUM`), segment name (`SEGNAM`), parent segment (`PSGNUM`), hierarchy level (`HLEVEL`) and the segment data (`SDATA`, 1,000 characters) |
| Status records | `EDIDS`; `BDIDOCSTAT` in inbound processing | The status history: status value, message, the segment and field that caused it |

- A **basic type** defines the segments, their order, hierarchy and how often each may occur. An **extension** adds segments to a basic type without copying it.
- A **segment** is a flat structure of character-like fields; its definition carries versions. Segments are developed in `WE31`, basic types and extensions in `WE30`.
- A **message type** names the business meaning, such as an order; `WE81` defines message types and `WE82` assigns them to basic types and extensions.

Changing a delivered basic type is a modification; extend it instead **[verify: the release and versioning rules for segments in your system]**.

## 🔌 Ports, Logical Systems, Partner Profiles, Distribution Model

These are configuration, set up by Basis or the integration team, not by code ([Rule 8.5](../docs/ABAP-Development-Rules.md#85-never-hard-code-credentials-hosts-or-destinations)):

| Object | Transaction | Purpose |
|---|---|---|
| Logical system | `BD54` (in `SALE`) | The name under which a system takes part in ALE |
| Port | `WE21` | How IDocs leave the system, for example through an RFC destination ([09-Modularization](../09-Modularization/README.md#-calling-a-function-module-via-rfc-destination)) **[verify: the port types and their settings]** |
| Partner profile | `WE20` | Per partner and message type: outbound port and basic type, or inbound process code; immediate or collected processing |
| Distribution model | `BD64` | Which message types go from which logical system to which |
| Process code | `WE41` (outbound), `WE42` (inbound) | The processing behind a message type, for example an inbound function module |

Programs read none of these from literals. The sender in this chapter receives the message type and basic type from configuration; the receivers come from the distribution model.

## 📤 Outbound Processing

An outbound IDoc starts in one of three ways:

- **Output control:** an application's output determination creates the IDoc as one kind of output, next to print or mail **[verify: output determination per application]**.
- **Change pointers** for master data: according to SAP's documentation, change pointers are switched on in general (`BD61`) and per message type (`BD50`); the program `RBDMIDOC` (or `BD21`) reads them, creates IDocs and marks the pointers as processed, usually as a scheduled job with a variant per message type. `RBDCPCLR` (`BD22`) deletes processed and obsolete change pointers, so that the change pointer tables stay small.
- **Directly from ABAP** with `MASTER_IDOC_DISTRIBUTE`: the program passes a control record template (`MASTER_IDOC_CONTROL`) and the data records (`MASTER_IDOC_DATA`); the function module determines the receivers and returns one control record per IDoc created (`COMMUNICATION_IDOC_CONTROL`). Its classic exceptions are `ERROR_IN_IDOC_CONTROL`, `ERROR_WRITING_IDOC_STATUS`, `ERROR_IN_IDOC_DATA` and `SENDING_LOGICAL_SYSTEM_UNKNOWN`.

Whether an IDoc is passed to the port at once or collected and sent later by `RSEOUT00` is set in the partner profile **[verify: immediate and collected dispatch, and whether the dispatch waits for the caller's COMMIT WORK]**. Either way, a reusable unit never commits; the program that owns the transaction does ([Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work)).

**Example E1 — sending an order.** Target: interface and exception class Standard ABAP and ABAP for Cloud Development; the implementation Standard ABAP.

```abap
"! Raised when an order cannot be handed to the IDoc interface. A
"! classic error keeps its message through the T100 interfaces.
CLASS zcx_zsm_order_send_failed DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.

    DATA order_id TYPE c LENGTH 10 READ-ONLY.

    METHODS constructor
      IMPORTING textid   LIKE if_t100_message=>t100key OPTIONAL
                previous LIKE previous OPTIONAL
                order_id TYPE csequence OPTIONAL.
ENDCLASS.


CLASS zcx_zsm_order_send_failed IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
    me->order_id = order_id.
  ENDMETHOD.
ENDCLASS.
```

```abap
"! Sends an order to the systems that receive it. Implementations never
"! commit; the caller's COMMIT WORK completes the hand-over (Rule 7.10).
INTERFACE zif_zsm_order_sender PUBLIC.
  TYPES: BEGIN OF item,
           position TYPE n LENGTH 6,
           product  TYPE c LENGTH 18,
           quantity TYPE p LENGTH 13 DECIMALS 3,
         END OF item.
  TYPES items TYPE STANDARD TABLE OF item WITH EMPTY KEY.
  TYPES: BEGIN OF order,
           order_id TYPE c LENGTH 10,
           customer TYPE c LENGTH 10,
           items    TYPE items,
         END OF order.

  "! @parameter order | Order to send
  "! @parameter result | Number of documents created, one per receiver
  "! @raising zcx_zsm_order_send_failed | The order could not be handed over
  METHODS send
    IMPORTING order         TYPE order
    RETURNING VALUE(result) TYPE i
    RAISING   zcx_zsm_order_send_failed.
ENDINTERFACE.
```

```abap
"! Sends an order as an IDoc through ALE. The distribution model decides
"! the receivers; MASTER_IDOC_DISTRIBUTE creates one IDoc per receiver.
"! Nothing is committed here (Rule 7.10).
CLASS zcl_zsm_order_sender_idoc DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_zsm_order_sender.

    "! @parameter message_type | Message type, from configuration
    "! @parameter idoc_type | Basic type, from configuration
    METHODS constructor
      IMPORTING message_type TYPE edi_mestyp
                idoc_type    TYPE edi_idoctp.

  PRIVATE SECTION.
    DATA message_type TYPE edi_mestyp.
    DATA idoc_type    TYPE edi_idoctp.
ENDCLASS.


CLASS zcl_zsm_order_sender_idoc IMPLEMENTATION.
  METHOD constructor.
    me->message_type = message_type.
    me->idoc_type    = idoc_type.
  ENDMETHOD.

  METHOD zif_zsm_order_sender~send.
    DATA(control) = VALUE edidc( mestyp = message_type
                                 idoctp = idoc_type ).
    DATA(segments) = NEW zcl_zsm_order_idoc_mapper( )->to_segments( order ).
    DATA receivers TYPE STANDARD TABLE OF edidc WITH EMPTY KEY.

    CALL FUNCTION 'MASTER_IDOC_DISTRIBUTE'
      EXPORTING
        master_idoc_control            = control
      TABLES
        communication_idoc_control     = receivers
        master_idoc_data               = segments
      EXCEPTIONS
        error_in_idoc_control          = 1
        error_writing_idoc_status      = 2
        error_in_idoc_data             = 3
        sending_logical_system_unknown = 4
        OTHERS                         = 5.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_zsm_order_send_failed USING MESSAGE
        EXPORTING
          order_id = order-order_id.
    ENDIF.

    " One control record per receiver; none if the model names no receiver
    result = lines( receivers ).
  ENDMETHOD.
ENDCLASS.
```

**Example E2 — mapping an order to segments.** Target: Standard ABAP (`EDIDD` is not released). The segment names are placeholders for segments created in `WE31`; the mapper fills `SDATA` from character-like structures that match the segments.

```abap
"! Maps an order to the data records of an IDoc and back: one header
"! segment, then one item segment per position below it. The segment
"! names are placeholders for segments defined in WE31.
CLASS zcl_zsm_order_idoc_mapper DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES segments TYPE STANDARD TABLE OF edidd WITH EMPTY KEY.

    CONSTANTS: BEGIN OF segment_name,
                 header TYPE edilsegtyp VALUE 'Z1ZSM_ORD_HDR',
                 item   TYPE edilsegtyp VALUE 'Z1ZSM_ORD_ITM',
               END OF segment_name.

    "! @parameter order | Order
    "! @parameter result | Data records, header first
    METHODS to_segments
      IMPORTING order         TYPE zif_zsm_order_sender=>order
      RETURNING VALUE(result) TYPE segments.

    "! @parameter segments | Data records of one IDoc
    "! @parameter result | Order rebuilt from the segments
    METHODS from_segments
      IMPORTING segments      TYPE segments
      RETURNING VALUE(result) TYPE zif_zsm_order_sender=>order.

  PRIVATE SECTION.
    " Segment fields are character-like, so SDATA can hold them directly
    TYPES: BEGIN OF header_data,
             order_id TYPE c LENGTH 10,
             customer TYPE c LENGTH 10,
           END OF header_data.
    TYPES: BEGIN OF item_data,
             position TYPE n LENGTH 6,
             product  TYPE c LENGTH 18,
             quantity TYPE c LENGTH 17,
           END OF item_data.
ENDCLASS.


CLASS zcl_zsm_order_idoc_mapper IMPLEMENTATION.
  METHOD to_segments.
    DATA(header) = VALUE header_data( order_id = order-order_id
                                      customer = order-customer ).
    INSERT VALUE #( segnum = 1
                    segnam = segment_name-header
                    hlevel = '01'
                    sdata  = header ) INTO TABLE result.

    LOOP AT order-items INTO DATA(item).
      DATA(item_segment) = VALUE item_data( position = item-position
                                            product  = item-product
                                            quantity = |{ item-quantity }| ).
      INSERT VALUE #( segnum = lines( result ) + 1
                      segnam = segment_name-item
                      psgnum = 1
                      hlevel = '02'
                      sdata  = item_segment ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD from_segments.
    DATA header       TYPE header_data.
    DATA item_segment TYPE item_data.

    LOOP AT segments INTO DATA(segment).
      CASE segment-segnam.
        WHEN segment_name-header.
          header = segment-sdata.
          result-order_id = header-order_id.
          result-customer = header-customer.
        WHEN segment_name-item.
          item_segment = segment-sdata.
          INSERT VALUE #( position = item_segment-position
                          product  = item_segment-product
                          quantity = CONV #( condense( item_segment-quantity ) ) ) INTO TABLE result-items.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
```

## 📥 Inbound Processing

The partner profile assigns an inbound **process code** (`WE42`) to a message type, and the process code names the processing, typically an **inbound function module**. The module is called immediately or later by `RBDAPP01`, depending on the partner profile. Its interface is fixed; SAP's own `IDOC_INPUT_ORDERS` shows it:

| Parameter | Kind | Content |
|---|---|---|
| `INPUT_METHOD`, `MASS_PROCESSING` | IMPORTING | How the module is called |
| `WORKFLOW_RESULT` | EXPORTING | According to SAP's documentation, `99999` when an event is to trigger error handling |
| `APPLICATION_VARIABLE`, `IN_UPDATE_TASK`, `CALL_TRANSACTION_DONE` | EXPORTING | Further indicators for the caller |
| `IDOC_CONTRL` (`EDIDC`), `IDOC_DATA` (`EDIDD`) | TABLES | The IDocs to process |
| `IDOC_STATUS` (`BDIDOCSTAT`) | TABLES | One status record per IDoc, with message |
| `RETURN_VARIABLES` (`BDWFRETVAR`) | TABLES | IDoc and document numbers for the workflow, for example as `Processed_IDOCs` or `Error_IDOCs` |
| `SERIALIZATION_INFO` (`BDI_SER`) | TABLES | Serialization data |

The module reads the data records of each IDoc, posts the business document and writes a status record. According to SAP's documentation, status **53** means the application document was posted and **51** that it was not; **64** means ready to be passed to the application, and **63** an error passing it **[verify: the complete list of status values in your system]**.

**Posting through BAPIs.** SAP's documentation describes how inbound processing calls a BAPI from the IDoc's data: if the BAPI's return table contains a message of type `A` or `E`, the IDoc gets status 51; otherwise status 53, and the framework commits. A posting through a BAPI follows [15-BAPIs](../15-BAPIs/README.md#-commit--rollback): the BAPI never commits, the caller does.

Set the success status only for a posted document, and report every failure as status 51 with the application's messages ([Rule 7.21](../docs/ABAP-Development-Rules.md#721-set-an-idocs-success-status-only-for-a-posted-application-document-report-every-failure-as-an-error-status-with-the-applications-messages)). A 53 for a document that was not posted hides the error from everyone who monitors the interface.

**Example E3 — the inbound decision.** Target: Standard ABAP and ABAP for Cloud Development. The class knows nothing about IDocs: it validates the order, posts it through an interface and decides `posted` or `rejected`.

```abap
"! Posts an incoming order in the application, for example through a
"! BAPI. Implementations never commit (Rule 7.10).
INTERFACE zif_zsm_order_poster PUBLIC.
  TYPES: BEGIN OF message,
           severity TYPE c LENGTH 1,
           code     TYPE string,
         END OF message.
  TYPES messages TYPE STANDARD TABLE OF message WITH EMPTY KEY.
  TYPES: BEGIN OF posting,
           document TYPE c LENGTH 10,
           messages TYPE messages,
         END OF posting.

  "! @parameter order | Validated order
  "! @parameter result | Document number, and the application's messages
  METHODS post
    IMPORTING order         TYPE zif_zsm_order_sender=>order
    RETURNING VALUE(result) TYPE posting.
ENDINTERFACE.
```

```abap
"! Decides what an incoming order leads to: it rejects incomplete orders,
"! posts the others and reports rejected as soon as the application
"! returns an error. The inbound function module turns the outcome into
"! the IDoc status (Rule 7.21).
CLASS zcl_zsm_order_inbound DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ENUM outcome,
             none,
             posted,
             rejected,
           END OF ENUM outcome.
    TYPES: BEGIN OF processing_result,
             outcome  TYPE outcome,
             document TYPE c LENGTH 10,
             messages TYPE zif_zsm_order_poster=>messages,
           END OF processing_result.

    CONSTANTS: BEGIN OF code,
                 no_customer TYPE string VALUE `NO_CUSTOMER`,
                 no_items    TYPE string VALUE `NO_ITEMS`,
               END OF code.

    METHODS constructor
      IMPORTING poster TYPE REF TO zif_zsm_order_poster.

    "! @parameter order | Order taken from the IDoc
    "! @parameter result | Outcome, document number and messages
    METHODS process
      IMPORTING order         TYPE zif_zsm_order_sender=>order
      RETURNING VALUE(result) TYPE processing_result.

  PRIVATE SECTION.
    DATA poster TYPE REF TO zif_zsm_order_poster.
ENDCLASS.


CLASS zcl_zsm_order_inbound IMPLEMENTATION.
  METHOD constructor.
    me->poster = poster.
  ENDMETHOD.

  METHOD process.
    IF order-customer IS INITIAL.
      INSERT VALUE #( severity = 'E' code = code-no_customer ) INTO TABLE result-messages.
    ENDIF.
    IF order-items IS INITIAL.
      INSERT VALUE #( severity = 'E' code = code-no_items ) INTO TABLE result-messages.
    ENDIF.
    IF result-messages IS NOT INITIAL.
      result-outcome = rejected.
      RETURN.
    ENDIF.

    DATA(posting) = poster->post( order ).
    result-messages = posting-messages.

    " Posted only if the application reported no error (Rule 7.21)
    IF line_exists( posting-messages[ severity = 'E' ] )
    OR line_exists( posting-messages[ severity = 'A' ] ).
      result-outcome = rejected.
    ELSE.
      result-outcome  = posted.
      result-document = posting-document.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

**Example E4 — the inbound function module.**

> 📝 **Contextual snippet** — a function module in a function group, registered behind an inbound process code; `zcl_zsm_order_poster_bapi` is a placeholder class that implements `zif_zsm_order_poster` with a BAPI, and `zsm_msg` is the placeholder message class with messages 030 (posted) and 031 (not posted). The interface is the standard one shown above. Who commits in direct inbound processing depends on how the module is called **[verify: the commit handling of direct inbound processing in your release]**. Standard ABAP only.

```abap
FUNCTION zsm_fm_idoc_input_order
  IMPORTING
    VALUE(input_method)          LIKE bdwfap_par-inputmethd
    VALUE(mass_processing)       LIKE bdwfap_par-mass_proc
  EXPORTING
    VALUE(workflow_result)       LIKE bdwfap_par-result
    VALUE(application_variable)  LIKE bdwfap_par-appl_var
    VALUE(in_update_task)        LIKE bdwfap_par-updatetask
    VALUE(call_transaction_done) LIKE bdwfap_par-calltrans
  TABLES
    idoc_contrl                  LIKE edidc
    idoc_data                    LIKE edidd
    idoc_status                  LIKE bdidocstat
    return_variables             LIKE bdwfretvar
    serialization_info           LIKE bdi_ser.

  DATA(mapper)  = NEW zcl_zsm_order_idoc_mapper( ).
  DATA(inbound) = NEW zcl_zsm_order_inbound( NEW zcl_zsm_order_poster_bapi( ) ).

  LOOP AT idoc_contrl INTO DATA(control).
    DATA(segments) = VALUE zcl_zsm_order_idoc_mapper=>segments(
                       FOR line IN idoc_data[] WHERE ( docnum = control-docnum ) ( line ) ).
    DATA(result) = inbound->process( mapper->from_segments( segments ) ).

    " Status 53 only for a posted document (Rule 7.21)
    IF result-outcome = zcl_zsm_order_inbound=>posted.
      APPEND VALUE #( docnum = control-docnum status = '53'
                      msgty = 'S' msgid = 'ZSM_MSG' msgno = '030'
                      msgv1 = result-document ) TO idoc_status.
      APPEND VALUE #( wf_param = 'Processed_IDOCs' doc_number = control-docnum ) TO return_variables.
    ELSE.
      APPEND VALUE #( docnum = control-docnum status = '51'
                      msgty = 'E' msgid = 'ZSM_MSG' msgno = '031'
                      msgv1 = VALUE #( result-messages[ 1 ]-code OPTIONAL ) ) TO idoc_status.
      APPEND VALUE #( wf_param = 'Error_IDOCs' doc_number = control-docnum ) TO return_variables.
      workflow_result = 99999.
    ENDIF.
  ENDLOOP.
ENDFUNCTION.
```

The module only translates: segments to an order, the outcome to a status. Everything that decides is in E3, which is tested without an IDoc.

## 🧱 Custom IDoc Types and Extensions

- **Extend before you create.** When a delivered basic type carries almost everything, add the missing fields in a segment of an extension, and fill it in the user exit or BAdI that the outbound or inbound processing of that message type offers **[verify: the enhancement points of the message type you extend]**.
- **Create a basic type** only for your own messages. Name segments, basic types and message types in the customer namespace; the segment names in this chapter (`Z1ZSM_ORD_HDR`, `Z1ZSM_ORD_ITM`) are placeholders.
- **Segments are character-like.** Numbers, amounts and dates travel as text; the mapper converts them, as E2 does with the quantity.
- **Released segment versions change only compatibly**: partners may still send the old version **[verify]**.

IDoc types, segments and message types are repository and Customizing objects that travel in transport requests ([29-Transport-Quality-Gates](../29-Transport-Quality-Gates/README.md)). This chapter creates none.

## 🛠️ Monitoring and Reprocessing

| T-code | Purpose |
|---|---|
| `WE02`, `WE05` | Display IDocs and their status history |
| `BD87` | Status monitor for ALE messages: IDocs grouped by status, message type or partner; processing of selected IDocs |
| `WE19` | Test tool for IDoc processing |

- According to SAP's documentation, `BD87` can process IDocs directly; inbound IDocs in status 51 can be posted again there once the cause is fixed. The program `RBDMANI2` reposts inbound IDocs in status 51 or 63 and can run as a periodic job, for example to catch lock collisions.
- **`WE19` creates real IDocs.** SAP's documentation describes editing an IDoc in the inbound test tool and then checking the new IDoc and its status 53 or 51. A test IDoc in production posts a real document.
- **Reprocessing posts real documents as well.** An IDoc reposted after a partial fix can create a second document if the first attempt already posted part of it.

Use the test tool and reprocessing in development and test systems; in production only through the support process (see [Best Practices](#-best-practices)).

## 🧯 Errors and Status Handling

- **Status records carry the message.** Fill the message fields of the status record from the application's message, so that the monitor shows why a document was not posted.
- **Error workflow.** According to SAP's documentation, an inbound error stops the IDoc and starts an error work item in the responsible users' inboxes; a successful posting closes it. Outbound errors in the ALE layer also lead to a workflow. The settings are made in `WE46` **[verify]**; the workflow concepts are in [31-Business-Workflow](../31-Business-Workflow/README.md). SAP's classification lists `IDOC_ERROR_WORKFLOW_START` as classic API.
- **Convert classic exceptions at the boundary**, as E1 does with the exceptions of `MASTER_IDOC_DISTRIBUTE` ([Rule 6.9](../docs/ABAP-Development-Rules.md#69-turn-sy-subrc-and-bapi-return-tables-into-exceptions-at-the-boundary)).

## ☁️ ABAP for Cloud Development and SAP S/4HANA Cloud

ABAP for Cloud Development has no released IDoc API: neither `MASTER_IDOC_DISTRIBUTE` nor the inbound framework nor the record structures. Integration uses:

- **released APIs** of the business objects, for example OData and SOAP services ([GWGuide](https://github.com/serhatmercan/GWGuide) for OData);
- **business events**, which notify other systems of changes (RAP business events: the future RAPGuide);
- **SAP Integration Suite** for mappings, routing and partner connectivity, including EDI (the planned SAP-Architecture-Guide).

Which API or event replaces a given IDoc is a per-scenario decision **[verify: SAP's statements on replacing specific IDoc message types]**. SAP S/4HANA also delivers application-specific EDI content for sales and purchasing with its own released structures and BAdIs; it belongs to those applications and is not the IDoc API. In Standard ABAP, the released ATC check `ATC_IDOC_CONS` (category "S/4HANA: Idoc Check") examines IDoc usage **[verify: what the check reports]**.

## 🧪 Testing IDoc-Related ABAP

A unit test never creates, sends or processes an IDoc. What can be tested is the ABAP on both sides of the interface ([22-ABAP-Unit](../22-ABAP-Unit/README.md#-test-doubles-through-interfaces)):

- the **mapping** between business data and segments (E2), as a round trip;
- the **inbound decision** (E3), with a double for the poster;
- callers of the **sender** (E1), with a double for `zif_zsm_order_sender`.

**E2's test include:**

```abap
CLASS ltc_order_idoc_mapper DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut   TYPE REF TO zcl_zsm_order_idoc_mapper.
    DATA order TYPE zif_zsm_order_sender=>order.

    METHODS setup.
    METHODS puts_header_before_items FOR TESTING.
    METHODS hangs_items_below_header FOR TESTING.
    METHODS round_trip_keeps_order FOR TESTING.
ENDCLASS.


CLASS ltc_order_idoc_mapper IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
    order = VALUE #( order_id = '0000000042'
                     customer = 'C100'
                     items    = VALUE #( ( position = 10 product = 'P-1' quantity = '2.5' )
                                         ( position = 20 product = 'P-2' quantity = 4 ) ) ).
  ENDMETHOD.

  METHOD puts_header_before_items.
    " when
    DATA(segments) = cut->to_segments( order ).

    " then
    cl_abap_unit_assert=>assert_equals( act = lines( segments ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = segments[ 1 ]-segnam
                                        exp = zcl_zsm_order_idoc_mapper=>segment_name-header ).
    cl_abap_unit_assert=>assert_equals( act = segments[ 3 ]-segnam
                                        exp = zcl_zsm_order_idoc_mapper=>segment_name-item ).
  ENDMETHOD.

  METHOD hangs_items_below_header.
    " when
    DATA(segments) = cut->to_segments( order ).

    " then
    cl_abap_unit_assert=>assert_equals( act = segments[ 2 ]-psgnum exp = segments[ 1 ]-segnum ).
    cl_abap_unit_assert=>assert_equals( act = segments[ 2 ]-hlevel exp = '02' ).
    cl_abap_unit_assert=>assert_equals( act = segments[ 3 ]-segnum exp = 3 ).
  ENDMETHOD.

  METHOD round_trip_keeps_order.
    " when
    DATA(rebuilt) = cut->from_segments( cut->to_segments( order ) ).

    " then
    cl_abap_unit_assert=>assert_equals( act = rebuilt exp = order ).
  ENDMETHOD.
ENDCLASS.
```

**E3's test include:**

```abap
"! Test double for the poster: returns a prepared result and records
"! whether it was called. It posts nothing.
CLASS lth_order_poster DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_zsm_order_poster.

    DATA called TYPE abap_bool READ-ONLY.

    METHODS constructor
      IMPORTING answer TYPE zif_zsm_order_poster=>posting.

  PRIVATE SECTION.
    DATA answer TYPE zif_zsm_order_poster=>posting.
ENDCLASS.


CLASS lth_order_poster IMPLEMENTATION.
  METHOD constructor.
    me->answer = answer.
  ENDMETHOD.

  METHOD zif_zsm_order_poster~post.
    called = abap_true.
    result = answer.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_order_inbound DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA order TYPE zif_zsm_order_sender=>order.

    METHODS setup.
    METHODS posts_valid_order FOR TESTING.
    METHODS rejects_order_without_items FOR TESTING.
    METHODS rejects_when_posting_fails FOR TESTING.
ENDCLASS.


CLASS ltc_order_inbound IMPLEMENTATION.
  METHOD setup.
    order = VALUE #( order_id = '0000000042'
                     customer = 'C100'
                     items    = VALUE #( ( position = 10 product = 'P-1' quantity = 1 ) ) ).
  ENDMETHOD.

  METHOD posts_valid_order.
    " given
    DATA(poster) = NEW lth_order_poster( VALUE #( document = '4711' ) ).

    " when
    DATA(result) = NEW zcl_zsm_order_inbound( poster )->process( order ).

    " then
    cl_abap_unit_assert=>assert_equals( act = result-outcome exp = zcl_zsm_order_inbound=>posted ).
    cl_abap_unit_assert=>assert_equals( act = result-document exp = '4711' ).
  ENDMETHOD.

  METHOD rejects_order_without_items.
    " given
    DATA(poster) = NEW lth_order_poster( VALUE #( document = '4711' ) ).
    CLEAR order-items.

    " when
    DATA(result) = NEW zcl_zsm_order_inbound( poster )->process( order ).

    " then
    cl_abap_unit_assert=>assert_equals( act = result-outcome exp = zcl_zsm_order_inbound=>rejected ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( result-messages[ code = zcl_zsm_order_inbound=>code-no_items ] ) ) ).
    cl_abap_unit_assert=>assert_false( poster->called ).
  ENDMETHOD.

  METHOD rejects_when_posting_fails.
    " given: the application answers with an error
    DATA(poster) = NEW lth_order_poster( VALUE #( messages = VALUE #( ( severity = 'E' code = `CREDIT_LIMIT` ) ) ) ).

    " when
    DATA(result) = NEW zcl_zsm_order_inbound( poster )->process( order ).

    " then
    cl_abap_unit_assert=>assert_equals( act = result-outcome exp = zcl_zsm_order_inbound=>rejected ).
    cl_abap_unit_assert=>assert_initial( result-document ).
    cl_abap_unit_assert=>assert_equals( act = result-messages
                                        exp = VALUE zif_zsm_order_poster=>messages( ( severity = 'E' code = `CREDIT_LIMIT` ) ) ).
  ENDMETHOD.
ENDCLASS.
```

> 📝 **Activation record.** E1's interface and exception class (`zif_zsm_order_sender`, `zcx_zsm_order_send_failed`) and E3 (`zif_zsm_order_poster`, `zcl_zsm_order_inbound` with its test include) were activated in both ABAP language versions: Standard ABAP and ABAP for Cloud Development. E1's implementation (`zcl_zsm_order_sender_idoc`) and E2 (`zcl_zsm_order_idoc_mapper` with its test include) were activated in Standard ABAP. All activations passed at the first attempt. The tests of E2 (3 methods, Standard ABAP) and E3 (3 methods, both versions) were run, and the test runs passed. The active versions were read back and matched the sources; the check tools returned no warnings. No unit test calls `MASTER_IDOC_DISTRIBUTE` or any IDoc or ALE function module; E1's implementation was not run. No IDoc was created, sent, tested in `WE19` or reprocessed; no partner profile, port, logical system, distribution model, process code or change-pointer setting was created or changed. E4 is a contextual snippet.

## 🧭 Scope Note

Not covered in this chapter:

- **EDI subsystems and converters**, and the EDI standards themselves.
- **Setting up** ports, partner profiles, logical systems and the distribution model step by step.
- **Serialization** of IDocs (`OBJ_TYPE`, `CHNUM`, `SERIALIZATION_INFO`) and IDoc archiving.
- **Output determination** of the individual applications.
- **SAP Integration Suite** mappings and EDI — the planned SAP-Architecture-Guide.

## ✅ Best Practices

- Choose IDocs for asynchronous, traceable document exchange; choose an API when the caller needs an answer at once.
- Keep ports, partners, receivers and message types in configuration, never in code.
- Put the mapping between business data and segments into a tested class.
- Keep the inbound function module thin: segments to business data, outcome to status; decisions live in a tested class.
- Set status 53 only for a posted document; give every 51 the application's message ([Rule 7.21](../docs/ABAP-Development-Rules.md#721-set-an-idocs-success-status-only-for-a-posted-application-document-report-every-failure-as-an-error-status-with-the-applications-messages)).
- Extend a delivered basic type instead of copying or modifying it.
- Run `RBDCPCLR` regularly where change pointers are used.
- Use the IDoc test tool and reprocessing in production only through the support process.

## ⚠️ Common Mistakes

- Setting status 53 although the document was not posted, or 51 without a message.
- `COMMIT WORK` inside a reusable unit that calls `MASTER_IDOC_DISTRIBUTE`.
- Hard-coding receivers, ports or partner numbers instead of using the distribution model and partner profiles.
- Business rules inside the inbound function module, where no unit test reaches them.
- Copying a delivered basic type instead of extending it.
- Testing with `WE19` in production, or reposting IDocs without checking whether part of the document was already posted.
- Letting change pointer tables grow without clean-up.
- Building new integrations on IDocs where the target is SAP S/4HANA Cloud or ABAP for Cloud Development.

## 🎤 Interview & Review Checkpoints

- What are the three record types of an IDoc, and what is in each?
- Basic type, extension, segment, message type: how do they relate?
- What do a port, a partner profile and the distribution model decide?
- Name three ways an outbound IDoc is created.
- What does an inbound function module return, and when may it set status 53?
- How does inbound processing derive the status from a BAPI's return messages?
- How do you reprocess an IDoc in status 51, and what is the risk?
- What replaces IDocs in ABAP for Cloud Development?
- How do you test IDoc-related code without creating an IDoc?

## 🖥️ Related Transaction Codes

| T-code | Purpose |
|---|---|
| `SALE` | ALE Customizing |
| `BD54` | Logical systems |
| `WE21` | Ports |
| `WE20` | Partner profiles |
| `BD64` | Distribution model |
| `WE30`, `WE31` | Basic types and extensions; segments |
| `WE81`, `WE82` | Message types; assignment to basic types |
| `WE41`, `WE42` | Process codes, outbound and inbound |
| `BD50`, `BD52`, `BD21`, `BD22` | Change pointers: activation per message type, change-relevant fields, IDoc creation, clean-up |
| `WE02`, `WE05` | Display IDocs |
| `BD87` | Status monitor for ALE messages |
| `WE19` | Test tool |

## 🔗 Related Chapters

- [15-BAPIs](../15-BAPIs/README.md) — posting inbound IDocs through BAPIs, and the commit protocol
- [09-Modularization](../09-Modularization/README.md) — function modules and RFC destinations behind ports
- [25-HTTP-REST](../25-HTTP-REST/README.md) — synchronous alternatives over HTTP
- [22-ABAP-Unit](../22-ABAP-Unit/README.md) — test doubles for the sender and the poster
- [29-Transport-Quality-Gates](../29-Transport-Quality-Gates/README.md) — transporting IDoc types and configuration
- [31-Business-Workflow](../31-Business-Workflow/README.md) — the previous chapter; the error workflow of inbound IDocs
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle of IDoc and ALE and what replaces them
