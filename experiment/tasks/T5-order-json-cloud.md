# T5 — Order as JSON (ABAP for Cloud Development)

## Run metadata (operator only; not given to the assistant)

| Item | Value |
|---|---|
| Target system | SAP BTP ABAP environment |
| Language version | ABAP for Cloud Development |
| Package | `{PACKAGE}`: a package of your own |
| Objects the spec requires | `ZCL_ZSM_X<run>_ORDER_JSON` |
| Acceptance test | `acceptance/T5/` → shell class `ZCL_ZSM_X<run>_AT_JSON` |
| What the run must not do | Write table rows, use a transport |
| Rubric focus | R-C11 activation attempts, R-T5 items (unreleased API attempts in the transcript) |

## Spec text (paste after the run prompt header)

An external shop system receives our orders as JSON. Create the class
`ZCL_ZSM_X<run>_ORDER_JSON` with exactly this public section:

```abap
  PUBLIC SECTION.
    TYPES: BEGIN OF order,
             id         TYPE c LENGTH 10,
             customer   TYPE string,
             order_date TYPE d,
             amount     TYPE p LENGTH 15 DECIMALS 2,
             currency   TYPE c LENGTH 5,
           END OF order.

    METHODS to_json
      IMPORTING order         TYPE order
      RETURNING VALUE(result) TYPE string.
```

`to_json` returns one JSON object without any whitespace outside string
values, with the members in exactly this order:

| Member | Value |
|---|---|
| `id` | The order ID as a JSON string without leading zeros; `0000004711` becomes `"4711"`, and an ID of only zeros becomes `"0"` |
| `customer` | The customer as a JSON string; a quotation mark is written as `\"` and a backslash as `\\` |
| `orderDate` | The date as a JSON string in the form `YYYY-MM-DD`, or `null` if the date is initial |
| `amount` | The amount as a JSON number with exactly two decimals and a point as decimal separator, for example `1234.50` or `-5.00` |
| `currency` | The currency as a JSON string |

Example: an order with ID `0000004711`, customer `ACME "Ltd"`, date
2026-03-15, amount 1234.5 and currency `EUR` gives

```json
{"id":"4711","customer":"ACME \"Ltd\"","orderDate":"2026-03-15","amount":1234.50,"currency":"EUR"}
```

The class must be written in ABAP for Cloud Development.

## Objects and names

The name with `<run>` replaced by the run ID. The object goes to package
`{PACKAGE}` on the SAP BTP destination.
