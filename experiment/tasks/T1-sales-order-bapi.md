# T1 — Create a sales order through a BAPI

## Run metadata (operator only; not given to the assistant)

| Item | Value |
|---|---|
| Target system | On-premise (Standard ABAP) |
| Language version | Standard ABAP |
| Package | `$TMP` |
| Objects the spec requires | `ZIF_ZSM_X<run>_SO_API`, `ZCX_ZSM_X<run>_SO_ERROR`, `ZCL_ZSM_X<run>_SO_CREATOR`, `ZCL_ZSM_X<run>_SO_BAPI` |
| Acceptance test | `acceptance/T1/` → shell class `ZCL_ZSM_X<run>_AT_SO` |
| What the run must not do | Call the BAPI (it would create an order), write table rows, use a transport |
| Rubric focus | R-C1a commit and R-C1b rollback in a reusable class, R-T1 items |

## Spec text (paste after the run prompt header)

Our order intake needs a small ABAP component that creates a standard sales
order for one customer and one material.

Create the following objects exactly as given (you may add ABAP Doc comments):

```abap
INTERFACE zif_zsm_x<run>_so_api PUBLIC.
  TYPES items    TYPE STANDARD TABLE OF bapisditm WITH EMPTY KEY.
  TYPES partners TYPE STANDARD TABLE OF bapiparnr WITH EMPTY KEY.
  TYPES messages TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY.

  "! Creates a sales order in the system and returns the result as the system reports it.
  METHODS create_sales_order
    IMPORTING header         TYPE bapisdhd1
              items          TYPE items
              partners       TYPE partners
    EXPORTING sales_document TYPE bapivbeln-vbeln
              messages       TYPE messages.
ENDINTERFACE.
```

```abap
CLASS zcx_zsm_x<run>_so_error DEFINITION PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    DATA messages TYPE zif_zsm_x<run>_so_api=>messages READ-ONLY.
    METHODS constructor
      IMPORTING messages LIKE messages OPTIONAL
                previous LIKE previous OPTIONAL.
ENDCLASS.
```

Then create:

1. `ZCL_ZSM_X<run>_SO_BAPI`, which implements `zif_zsm_x<run>_so_api` with the
   function module `BAPI_SALESORDER_CREATEFROMDAT2`.
2. `ZCL_ZSM_X<run>_SO_CREATOR` with exactly this public section:

```abap
  PUBLIC SECTION.
    TYPES: BEGIN OF request,
             order_type TYPE auart,
             sales_org  TYPE vkorg,
             distr_chan TYPE vtweg,
             division   TYPE spart,
             customer   TYPE kunnr,
             material   TYPE matnr,
             quantity   TYPE i,
           END OF request.

    METHODS constructor
      IMPORTING api TYPE REF TO zif_zsm_x<run>_so_api.

    METHODS create
      IMPORTING request       TYPE request
      RETURNING VALUE(result) TYPE bapivbeln-vbeln
      RAISING   zcx_zsm_x<run>_so_error.
```

Behaviour of `create`:

- It passes one order to the API: the header carries order type, sales
  organization, distribution channel and division from the request (fields
  `DOC_TYPE`, `SALES_ORG`, `DISTR_CHAN`, `DIVISION`); one item with
  `ITM_NUMBER` `000010`, the material in `MATERIAL_LONG` and the quantity
  in `TARGET_QTY`; one partner with `PARTN_ROLE` `AG` (sold-to party) and the
  customer in `PARTN_NUMB`.
- It returns the sales order number that the API reports.
- If the API reports at least one message of type `E` or `A`, or if it reports
  no sales order number, `create` raises `zcx_zsm_x<run>_so_error`, and the
  exception carries all messages the API returned.
- Messages of type `S`, `I` and `W` alone do not make the creation fail.

## Objects and names

All names with `<run>` replaced by the run ID. Every object goes to `$TMP` on
the on-premise destination.
