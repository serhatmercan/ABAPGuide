# 35 — Number Ranges and Change Documents

> **Lifecycle:** `CURRENT / RECOMMENDED`. Number range objects and change document objects, with the released classes `CL_NUMBERRANGE_*` and `CL_CHDO_*`, work in Standard ABAP and in ABAP for Cloud Development. The classic function modules are labelled where they appear. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

Two services of the ABAP platform appear in almost every application that creates or changes business documents:

- A **number range object** hands out document numbers: unique, from defined intervals, and safe when many users save at the same time. Reading the highest key and adding one is not ([27-Lock-Objects](../27-Lock-Objects/README.md#-common-mistakes)).
- A **change document object** records who changed which field of a document, when, and from which old value to which new one. SAP's own applications write change documents for their business objects, and a direct `UPDATE` on their tables bypasses them ([Rule 7.9](../docs/ABAP-Development-Rules.md#79-write-only-to-your-own-tables-change-sap-standard-data-through-bapis-or-released-apis)).

The chapter covers both for your own tables: the objects, the APIs to use, where they belong in the SAP LUW ([08-Open-SQL](../08-Open-SQL/README.md#-sap-luw--transaction-ownership)), and how to test code that uses them without drawing a number or writing a change document.

## 🗺️ Standard ABAP and ABAP for Cloud Development at a Glance

| Topic | Standard ABAP | ABAP for Cloud Development |
|---|---|---|
| Number range object | `SNRO`, or ADT | ADT (created in the SAP BTP ABAP environment for this chapter) |
| Intervals | `SNUM`, `SNRO`, `CL_NUMBERRANGE_INTERVALS` | `CL_NUMBERRANGE_INTERVALS`; an app **[verify: the interval app in your release]** |
| Drawing a number | `NUMBER_GET_NEXT` (classic), `CL_NUMBERRANGE_RUNTIME` | `CL_NUMBERRANGE_RUNTIME` |
| Change document object | `SCDO`, or ADT | ADT (created in the SAP BTP ABAP environment for this chapter) |
| Writing | The generated write class or function module; `CHANGEDOCUMENT_*` (classic) | The generated write class |
| Reading | `CHANGEDOCUMENT_READ` (classic), `CL_CHDO_READ_TOOLS`, `RSSCD100` | `CL_CHDO_READ_TOOLS` |

SAP's release information lists the `CL_NUMBERRANGE_*` and `CL_CHDO_*` classes as released, and it classifies `NUMBER_GET_NEXT`, the other number range function modules, the `CHANGEDOCUMENT_*` function modules and the tables `CDHDR` and `CDPOS` as not to be released, naming those classes as successors ([Rule 1.3](../docs/ABAP-Development-Rules.md#13-in-standard-abap-prefer-a-released-api-over-an-unreleased-one-when-both-exist)).

## 🔢 Number Range Objects and Intervals

A **number range object** describes how numbers are formed; its **intervals** hold the numbers. SAP's ABAP file format for number range objects, read in both systems used for this chapter, names these properties:

| Property | Meaning |
|---|---|
| Number length domain | A domain of type `NUMC` or `CHAR`, length 1 to 20, that sets how long the numbers are |
| Percentage warning | When this share of an interval is left, drawing a number reports it |
| Subtype | A data element with a check table, for intervals per value of a field, for example per company code |
| Until fiscal year | Intervals per fiscal year |
| Rolling | Whether an interval starts again at its first number once it is used up |
| Prefix | Whether the number carries the subobject as a prefix |
| Buffering and buffered numbers | See the next section |

An interval has a number (for example `01`), a first and a last number, and the current level. Internal intervals are filled by the system; external intervals check numbers that the user enters **[verify: internal and external intervals in your release]**. The intervals are client-specific data in table `NRIV`, not repository objects.

**Example O1 — the number range object.** The ADT tool used for this guide created `ZSM_ORDNR` in both systems. Its settings:

| Setting | On-premise | SAP BTP ABAP environment |
|---|---|---|
| Number length domain | `NUMC10` | `AUFNR` (a released domain; the tool cannot create domains, [33-ABAP-Dictionary](../33-ABAP-Dictionary/README.md)) |
| Buffering, buffered numbers | main memory, 10 | main memory, 10 |
| Rolling | off | off |

> 📝 **Activation record.** `ZSM_ORDNR` was created and activated in both ABAP language versions, and its definition was read back. The new object started with no buffering and 0 buffered numbers in both systems, with rolling switched off on-premise and on in the SAP BTP ABAP environment; the settings above were set afterwards. No interval was defined and no number was drawn.

## 🧮 Buffering and Gaps

SAP's ABAP file format for number range objects describes three kinds of buffering:

| Buffering | According to the file format |
|---|---|
| **Main memory** | The most efficient, and the one almost all number range objects use. Numbers are no longer assigned in chronological order, and gaps can occur. |
| **Parallel** | Works like main memory buffering, but keeps the number packages in table `NRIVSHADOW`. |
| **None** | Each number is taken from `NRIV`; the row stays locked until the application ends with `COMMIT WORK` or `ROLLBACK WORK`. |

Whatever the buffering, a number that was drawn is used up even if the document is never saved ([Rule 7.25](../docs/ABAP-Development-Rules.md#725-draw-document-numbers-from-a-number-range-object-as-late-as-possible-in-the-sap-luw)). Where the business or the law requires numbers without gaps, the usual answer is no buffering, with the lock that comes with it **[verify: SAP's guidance on gap-free numbering in your release]**.

## ⏱️ Drawing a Number

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` for `NUMBER_GET_NEXT`. Most existing code calls it; SAP classifies it as not to be released and names `CL_NUMBERRANGE_RUNTIME` as its successor.

`NUMBER_GET_NEXT`, read in the on-premise system, takes the interval number, the object, a quantity, the subobject and the fiscal year, returns the number, the quantity and a return code, and signals errors through classic exceptions such as `INTERVAL_NOT_FOUND`, `OBJECT_NOT_FOUND` and `INTERVAL_OVERFLOW`.

The released `CL_NUMBERRANGE_RUNTIME=>NUMBER_GET` has the same parameters as a class method and raises `CX_NR_OBJECT_NOT_FOUND` and `CX_NUMBER_RANGES` (the first inherits from the second). According to its documentation, the return code means:

| Return code | Meaning |
|---|---|
| space | Number returned |
| 1 | The number is in the critical range set by the percentage warning |
| 2 | The last number of the interval was returned |
| 3 | Fewer numbers than requested were returned; `RETURNED_QUANTITY` says how many |

**Example E1 — the number source.** Target: Standard ABAP and ABAP for Cloud Development.

```abap
"! Hands out the next order number.
INTERFACE zif_zsm_number_source
  PUBLIC.

  "! Draws the next number; call it as late as possible before the save.
  "! @parameter result                     | The new order ID
  "! @raising   zcx_zsm_number_unavailable | No number could be drawn
  METHODS next_number
    RETURNING VALUE(result) TYPE zsm_e_order_id
    RAISING   zcx_zsm_number_unavailable.
ENDINTERFACE.
```

```abap
"! No number could be drawn from the number range.
CLASS zcx_zsm_number_unavailable DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING !previous LIKE previous OPTIONAL.
ENDCLASS.


CLASS zcx_zsm_number_unavailable IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
  ENDMETHOD.
ENDCLASS.
```

> 📝 ADT adds the pragma `##ADT_SUPPRESS_GENERATION` to a hand-written exception constructor, as observed in [34-Authorization-Checks](../34-Authorization-Checks/README.md); the source above includes it.

```abap
"! Order numbers from the number range object ZSM_ORDNR.
CLASS zcl_zsm_number_source DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_zsm_number_source.

  PRIVATE SECTION.
    CONSTANTS number_range_object TYPE cl_numberrange_runtime=>nr_object VALUE 'ZSM_ORDNR'.
    CONSTANTS interval TYPE cl_numberrange_runtime=>nr_interval VALUE '01'.
ENDCLASS.


CLASS zcl_zsm_number_source IMPLEMENTATION.
  METHOD zif_zsm_number_source~next_number.
    DATA number TYPE cl_numberrange_runtime=>nr_number.
    DATA returned_quantity TYPE cl_numberrange_runtime=>nr_returned_quantity.

    TRY.
        cl_numberrange_runtime=>number_get( EXPORTING nr_range_nr       = interval
                                                      object            = number_range_object
                                            IMPORTING number            = number
                                                      returned_quantity = returned_quantity ).
      CATCH cx_number_ranges INTO DATA(error).
        RAISE EXCEPTION NEW zcx_zsm_number_unavailable( previous = error ).
    ENDTRY.

    " Return code 3 with nothing returned: the interval is used up
    IF returned_quantity = 0.
      RAISE EXCEPTION NEW zcx_zsm_number_unavailable( ).
    ENDIF.

    " The interval has at most 10 digits; the order ID takes the last 10
    result = substring( val = number off = strlen( number ) - 10 len = 10 ).
  ENDMETHOD.
ENDCLASS.
```

> 📝 **Activation record.** E1 was activated in both ABAP language versions and read back. It was not run: no interval exists, and no number was drawn.

## 🔐 The Number and the SAP LUW

Draw the number as the last step before the save ([Rule 7.25](../docs/ABAP-Development-Rules.md#725-draw-document-numbers-from-a-number-range-object-as-late-as-possible-in-the-sap-luw)):

- everything that can fail, validation, authorization and locks, comes first;
- the number is used up when it is drawn, so a later failure leaves a gap;
- without buffering, the interval stays locked until the transaction owner commits or rolls back ([Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work)), so keep that time short.

**Example E2 — numbering a new order.** Target: Standard ABAP and ABAP for Cloud Development.

```abap
"! Creates a new order record and gives it its number.
CLASS zcl_zsm_order_numbering DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! @parameter number_source | Hands out the order numbers
    METHODS constructor
      IMPORTING number_source TYPE REF TO zif_zsm_number_source.

    "! The new order, numbered last, after everything else is in place.
    "! @parameter note                       | Free text of the order
    "! @parameter result                     | The order to be saved by the caller
    "! @raising   zcx_zsm_number_unavailable | No number could be drawn
    METHODS new_order
      IMPORTING note          TYPE zsm_t_ordhdr-note
      RETURNING VALUE(result) TYPE zsm_t_ordhdr
      RAISING   zcx_zsm_number_unavailable.

  PRIVATE SECTION.
    CONSTANTS status_new TYPE zsm_e_order_status VALUE 'N'.

    DATA number_source TYPE REF TO zif_zsm_number_source.
ENDCLASS.


CLASS zcl_zsm_order_numbering IMPLEMENTATION.
  METHOD constructor.
    me->number_source = number_source.
  ENDMETHOD.

  METHOD new_order.
    result = VALUE #( status = status_new
                      note   = note ).

    " The number comes last: a failure before this point wastes none
    result-order_id = number_source->next_number( ).
  ENDMETHOD.
ENDCLASS.
```

The tests use a double, so no number is drawn:

```abap
"! Double for the number source: no number is drawn from a real interval.
CLASS lth_number_source DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_zsm_number_source.

    DATA next TYPE zsm_e_order_id.
    DATA exhausted TYPE abap_bool.
    DATA calls TYPE i READ-ONLY.
ENDCLASS.


CLASS lth_number_source IMPLEMENTATION.
  METHOD zif_zsm_number_source~next_number.
    calls += 1.
    IF exhausted = abap_true.
      RAISE EXCEPTION NEW zcx_zsm_number_unavailable( ).
    ENDIF.
    result = next.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_order_numbering DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA numbers TYPE REF TO lth_number_source.
    DATA cut TYPE REF TO zcl_zsm_order_numbering.

    METHODS setup.
    METHODS numbers_the_new_order FOR TESTING RAISING cx_static_check.
    METHODS passes_on_an_exhausted_range FOR TESTING.
ENDCLASS.


CLASS ltc_order_numbering IMPLEMENTATION.
  METHOD setup.
    numbers = NEW #( ).
    cut = NEW #( numbers ).
  ENDMETHOD.

  METHOD numbers_the_new_order.
    numbers->next = '0000000042'.

    DATA(order) = cut->new_order( `Rush` ).

    cl_abap_unit_assert=>assert_equals( act = order-order_id
                                        exp = '0000000042' ).
    cl_abap_unit_assert=>assert_equals( act = order-status
                                        exp = 'N' ).
    cl_abap_unit_assert=>assert_equals( act = numbers->calls
                                        exp = 1 ).
  ENDMETHOD.

  METHOD passes_on_an_exhausted_range.
    numbers->exhausted = abap_true.

    TRY.
        cut->new_order( `Rush` ).
        cl_abap_unit_assert=>fail( msg = 'An exhausted range must stop the order' ).
      CATCH zcx_zsm_number_unavailable.
        " expected
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
```

> 📝 **Activation record.** E2 was activated in both ABAP language versions, and its two tests passed in both. The active versions were read back and matched the sources.

## 🛠️ Maintaining Intervals

On-premise, intervals are maintained in `SNUM` or from `SNRO`; the system also has `SNUM_FIORI` for interval maintenance. In code, `CL_NUMBERRANGE_INTERVALS` offers `CREATE`, `READ`, `UPDATE` and `DELETE`; SAP names it as the successor of the `NUMBER_RANGE_INTERVAL_*` function modules. Their parameters were not read for this chapter **[verify: CL_NUMBERRANGE_INTERVALS parameters in your release]**.

How intervals reach the other systems of a landscape, and which app maintains them in the SAP BTP ABAP environment, is **[verify: transport of number range intervals, and interval maintenance in the SAP BTP ABAP environment]**. No interval was defined for this chapter.

## 📝 Change Document Objects

A **change document object** names the tables whose changes are logged and generates the code that writes the change documents. SAP's ABAP file format for change document objects names these properties:

- **Tables and structures**, each with a reference table for currencies and units, whether multiple changes are logged, and whether field values (and initial values) are logged for insertions and deletions;
- the **generated object**, a class or a function module;
- a **category**: standard, or for a behavior definition (RAP);
- an **error message**.

Only fields whose data element is marked *change document relevant* are logged **[verify: the effect of the flag on the generated code]**. For this chapter, both data elements of `zsm_t_ordhdr` were marked; the flag was read back in both systems ([33-ABAP-Dictionary](../33-ABAP-Dictionary/README.md#-data-elements)).

The change documents themselves are stored in `CDHDR` (header) and `CDPOS` (items). SAP classifies both tables as not to be released.

**Example O4 — the change document object.** The ADT tool created `ZSM_ORDHDR` in both systems for the table `ZSM_T_ORDHDR`, logging values on insertion and deletion, without multiple changes. On activation, the generator created the class `ZCL_ZSM_ORDHDR_CHDO` in both systems, with:

- a constant `OBJECTCLASS` with the object's name;
- the interface `IF_CHDO_ENHANCEMENTS`;
- a static method `WRITE` with the object ID, time, date and user, the change indicators, the old and the new state of the table (`O_ZSM_T_ORDHDR`, `N_ZSM_T_ORDHDR`) and the table's change indicator (`UPD_ZSM_T_ORDHDR`); it returns the change number and raises `CX_CHDO_WRITE_ERROR`.

> ⚠️ **VERSION-DEPENDENT: the generated `WRITE`.** In the on-premise system, the generated method also has a mandatory parameter `TCODE`; in the SAP BTP ABAP environment it has none. Read the generated class in your system before you call it.

The generated `WRITE` calls `CL_CHDO_WRITE_TOOLS` in three steps: `CHANGEDOCUMENT_OPEN`, `CHANGEDOCUMENT_SINGLE_CASE` for the table (only when the old or the new state is filled), and `CHANGEDOCUMENT_CLOSE`, which returns the change number. In the on-premise system, `CL_CHDO_WRITE_TOOLS=>CHANGEDOCUMENT_CLOSE` calls the classic function module `CHANGEDOCUMENT_CLOSE`.

> 📝 **Activation record.** `ZSM_ORDHDR` was created and activated in both ABAP language versions; its definition and the generated class were read back. No change document was written.

The generated class belongs to the change document object. In the on-premise system, deleting `ZSM_ORDHDR` by hand in ADT also deleted `ZCL_ZSM_ORDHDR_CHDO`; delete the object, not the class. Whether the SAP BTP ABAP environment does the same was not observed **[verify: deleting a change document object in the SAP BTP ABAP environment]**.

## ✍️ Writing Change Documents

Write the change document through the generated object, in the same SAP LUW as the change of the table, and leave the commit to the transaction owner ([Rule 7.26](../docs/ABAP-Development-Rules.md#726-write-change-documents-through-the-generated-write-object-read-them-through-the-released-api), [Rule 7.10](../docs/ABAP-Development-Rules.md#710-let-the-top-level-caller-own-the-transaction-reusable-units-never-commit-work)). Whether the change document reaches the database at once or with the commit, and how it behaves in the update task, is **[verify: when change documents are written to the database, and their use in the update task]**.

**Example E3 — the change log.** Target: ABAP for Cloud Development as shown; the Standard ABAP version passes `tcode = sy-tcode` in addition.

```abap
"! Records a change of an order as a change document.
INTERFACE zif_zsm_order_change_log
  PUBLIC.

  "! Logs the old and the new state; an initial state means insert or delete.
  "! @parameter old                 | State before the change
  "! @parameter new                 | State after the change
  "! @raising   cx_chdo_write_error | The change document could not be written
  METHODS log_change
    IMPORTING old TYPE zsm_t_ordhdr
              new TYPE zsm_t_ordhdr
    RAISING   cx_chdo_write_error.
ENDINTERFACE.
```

```abap
"! Writes order changes through the class generated for ZSM_ORDHDR.
CLASS zcl_zsm_order_change_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_zsm_order_change_log.
ENDCLASS.


CLASS zcl_zsm_order_change_log IMPLEMENTATION.
  METHOD zif_zsm_order_change_log~log_change.
    " I insert, D delete, U update: the same indicator for the object and the table
    DATA(indicator) = COND if_chdo_object_tools_rel=>ty_cdchngindh(
                        WHEN old IS INITIAL THEN 'I'
                        WHEN new IS INITIAL THEN 'D'
                        ELSE 'U' ).
    DATA(order_id) = COND zsm_e_order_id( WHEN new IS INITIAL THEN old-order_id
                                          ELSE new-order_id ).

    zcl_zsm_ordhdr_chdo=>write(
      EXPORTING objectid                = CONV #( order_id )
                utime                   = cl_abap_context_info=>get_system_time( )
                udate                   = cl_abap_context_info=>get_system_date( )
                username                = CONV #( cl_abap_context_info=>get_user_technical_name( ) )
                object_change_indicator = indicator
                o_zsm_t_ordhdr          = old
                n_zsm_t_ordhdr          = new
                upd_zsm_t_ordhdr        = indicator ).
  ENDMETHOD.
ENDCLASS.
```

> 📝 **Activation record.** E3 was activated in both ABAP language versions, with the `tcode` line in Standard ABAP. It was not run: no change document was written.

**Example E4 — a business class that records its change.** Target: Standard ABAP and ABAP for Cloud Development.

```abap
"! Changes the status of an order and records the change.
CLASS zcl_zsm_order_status_change DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! @parameter change_log | Records the change as a change document
    METHODS constructor
      IMPORTING change_log TYPE REF TO zif_zsm_order_change_log.

    "! The order with its new status; the caller saves it in the same SAP LUW.
    "! @parameter order               | Order as read
    "! @parameter status              | New status
    "! @parameter result              | Order with the new status
    "! @raising   cx_chdo_write_error | The change document could not be written
    METHODS set_status
      IMPORTING order         TYPE zsm_t_ordhdr
                status        TYPE zsm_e_order_status
      RETURNING VALUE(result) TYPE zsm_t_ordhdr
      RAISING   cx_chdo_write_error.

  PRIVATE SECTION.
    DATA change_log TYPE REF TO zif_zsm_order_change_log.
ENDCLASS.


CLASS zcl_zsm_order_status_change IMPLEMENTATION.
  METHOD constructor.
    me->change_log = change_log.
  ENDMETHOD.

  METHOD set_status.
    result = order.
    result-status = status.

    " No change, no change document
    IF result = order.
      RETURN.
    ENDIF.

    change_log->log_change( old = order
                            new = result ).
  ENDMETHOD.
ENDCLASS.
```

```abap
"! Double for the change log: records the calls instead of writing change documents.
CLASS lth_change_log DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_zsm_order_change_log.

    TYPES: BEGIN OF logged_change,
             old TYPE zsm_t_ordhdr,
             new TYPE zsm_t_ordhdr,
           END OF logged_change.

    DATA changes TYPE STANDARD TABLE OF logged_change WITH EMPTY KEY READ-ONLY.
ENDCLASS.


CLASS lth_change_log IMPLEMENTATION.
  METHOD zif_zsm_order_change_log~log_change.
    INSERT VALUE #( old = old new = new ) INTO TABLE changes.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_order_status_change DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA change_log TYPE REF TO lth_change_log.
    DATA cut TYPE REF TO zcl_zsm_order_status_change.

    METHODS setup.
    METHODS logs_old_and_new_state FOR TESTING RAISING cx_static_check.
    METHODS logs_nothing_without_change FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_order_status_change IMPLEMENTATION.
  METHOD setup.
    change_log = NEW #( ).
    cut = NEW #( change_log ).
  ENDMETHOD.

  METHOD logs_old_and_new_state.
    DATA(order) = VALUE zsm_t_ordhdr( order_id = '0000000042' status = 'N' ).

    DATA(changed) = cut->set_status( order  = order
                                     status = 'R' ).

    cl_abap_unit_assert=>assert_equals( act = lines( change_log->changes )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = change_log->changes[ 1 ]-old-status
                                        exp = 'N' ).
    cl_abap_unit_assert=>assert_equals( act = change_log->changes[ 1 ]-new
                                        exp = changed ).
  ENDMETHOD.

  METHOD logs_nothing_without_change.
    DATA(order) = VALUE zsm_t_ordhdr( order_id = '0000000042' status = 'N' ).

    cut->set_status( order  = order
                     status = 'N' ).

    cl_abap_unit_assert=>assert_initial( change_log->changes ).
  ENDMETHOD.
ENDCLASS.
```

> 📝 **Activation record.** E4 was activated in both ABAP language versions, and its two tests passed in both. The active versions were read back and matched the sources.

## 🔍 Reading Change Documents

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` for `CHANGEDOCUMENT_READ` and the other read function modules. SAP classifies them as not to be released and names `CL_CHDO_READ_TOOLS` as the successor.

`CL_CHDO_READ_TOOLS=>CHANGEDOCUMENT_READ` takes the change document object, a range of object IDs, a date and time window and a range of users, and returns the changes in a display structure; it raises `CX_CHDO_READ_ERROR`. On-premise, the report and transaction `RSSCD100` display change documents.

> 📝 **Contextual snippet** — reads the changes of one order; not run.

```abap
TRY.
    cl_chdo_read_tools=>changedocument_read(
      EXPORTING i_objectclass   = zcl_zsm_ordhdr_chdo=>objectclass
                it_objectid     = VALUE #( ( sign = 'I' option = 'EQ' low = order_id ) )
      IMPORTING et_cdredadd_tab = DATA(changes) ).
  CATCH cx_chdo_read_error INTO DATA(read_error).
    RAISE EXCEPTION NEW zcx_zsm_history_unavailable( previous = read_error ).
ENDTRY.
```

> 📝 `zcx_zsm_history_unavailable` is a placeholder exception class. For SAP's own business objects, SAP's release lists for SAP S/4HANA Cloud also contain released CDS views over change documents, for example `I_CHANGEDOCUMENTFORCHGDOCOBJ`; it is not in the list for the SAP BTP ABAP environment.

## ☁️ ABAP for Cloud Development and RAP

> **Lifecycle:** `ABAP CLOUD / MODERN CONTEXT`.

- **Objects in ADT.** Number range objects and change document objects were created and activated in ABAP for Cloud Development; the change document object generated its write class there as well.
- **Released APIs.** `CL_NUMBERRANGE_RUNTIME`, `CL_NUMBERRANGE_INTERVALS`, `CL_CHDO_WRITE_TOOLS` and `CL_CHDO_READ_TOOLS` are released.
- **RAP numbering.** According to the ABAP Keyword Documentation, a RAP business object assigns keys by managed, early or late numbering. Late numbering assigns the final key in the saver method `adjust_numbers`, just before the save, which allows keys without gaps; early numbering in an unmanaged scenario uses a handler method `FOR NUMBERING`. RAP belongs to the future RAPGuide.
- **RAP change documents.** The change document file format has a category for behavior definitions, and SAP's release lists contain XCO objects for change document logging options of behavior definitions. How a behavior definition declares change documents is **[verify: change documents in RAP behavior definitions]** and belongs to the future RAPGuide.

## 🧪 Testing

Code that draws numbers or writes change documents must not do either in a test: a drawn number is gone, and a change document carries a user name and stays in the system. Both services therefore sit behind interfaces ([Rule 10.6](../docs/ABAP-Development-Rules.md#106-replace-dependencies-with-test-doubles-through-interfaces-and-cl_abap_testdouble)):

- the business class receives `zif_zsm_number_source` or `zif_zsm_order_change_log`;
- its tests pass a double that returns a fixed number, or records the changes it receives (E2, E4);
- the classes that call `CL_NUMBERRANGE_RUNTIME` and the generated `WRITE` stay thin and are not unit-tested; they are covered by an integration test in a test system with its own interval **[verify: an integration test setup for number ranges and change documents]**.

## 🧭 Scope Note

Not covered in this chapter:

- **Defining, changing and transporting intervals**, and their monitoring (`SNUM_CCMS`).
- **Archiving and deleting change documents** (`CL_CHANGEDOCU_ARCHIVE`, `CL_CHDO_DELETE_TOOLS` are released).
- **Change pointers** for ALE, which are built on change documents ([32-IDoc-ALE](../32-IDoc-ALE/README.md)).
- **RAP numbering and RAP change documents** (RAPGuide).

## ✅ Best Practices

- Draw numbers from a number range object with `CL_NUMBERRANGE_RUNTIME`, as late as possible before the save — [Rule 7.25](../docs/ABAP-Development-Rules.md#725-draw-document-numbers-from-a-number-range-object-as-late-as-possible-in-the-sap-luw).
- Choose the buffering deliberately; use no buffering only where gaps are not allowed.
- Write change documents through the generated object in the same SAP LUW, and read them with `CL_CHDO_READ_TOOLS` — [Rule 7.26](../docs/ABAP-Development-Rules.md#726-write-change-documents-through-the-generated-write-object-read-them-through-the-released-api).
- Mark the data elements of logged fields as change-document relevant.
- Read the generated `WRITE` before calling it; its parameters differ between systems.
- Put both services behind interfaces and test with doubles.

## ⚠️ Common Mistakes

- Reading the highest key and adding one, or keeping a counter table of your own.
- Drawing the number at the start of a long dialog, so that every cancelled document leaves a gap.
- Promising gap-free numbers with a buffered number range object.
- Calling `NUMBER_GET_NEXT` or the `CHANGEDOCUMENT_*` function modules in new code.
- Selecting from `CDHDR` and `CDPOS` instead of using `CL_CHDO_READ_TOOLS`.
- Writing a change document in a separate commit from the change it describes.
- Unit tests that draw real numbers or write real change documents.

## 🎤 Interview & Review Checkpoints

- Why is "highest key plus one" wrong, and what does a number range object do instead?
- What does buffering change about the numbers, and when do you switch it off?
- Where in the SAP LUW do you draw a number, and what happens to it after a rollback?
- What does a change document object generate, and what do you pass to it?
- Which APIs replace `NUMBER_GET_NEXT` and `CHANGEDOCUMENT_READ`?
- How do you test a class that draws numbers and writes change documents?

## 🖥️ Related Transaction Codes

| T-code | Purpose |
|---|---|
| `SNRO` | Number range objects |
| `SNUM` | Number range intervals |
| `SNUM_FIORI` | Number range intervals (by its title in the system) |
| `SCDO` | Change document objects |
| `RSSCD100` | Display change documents |

## 🔗 Related Chapters

- [08-Open-SQL](../08-Open-SQL/README.md#-sap-luw--transaction-ownership) — the SAP LUW and the update task
- [27-Lock-Objects](../27-Lock-Objects/README.md) — locks around the save, and why the highest key is not a number
- [15-BAPIs](../15-BAPIs/README.md) — SAP's own objects write their change documents through their BAPIs
- [26-Maintenance-Views](../26-Maintenance-Views/README.md#-logging-table-changes-scu3) — table logging, the other way to record changes
- [33-ABAP-Dictionary](../33-ABAP-Dictionary/README.md) — domains for the number length, and data elements marked change-document relevant
- [22-ABAP-Unit](../22-ABAP-Unit/README.md#-test-doubles-through-interfaces) — doubles instead of real numbers and change documents
- [32-IDoc-ALE](../32-IDoc-ALE/README.md) — change pointers built on change documents
- [29-Transport-Quality-Gates](../29-Transport-Quality-Gates/README.md) — transporting the objects
- [34-Authorization-Checks](../34-Authorization-Checks/README.md) — the previous chapter
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle of the classic function modules
