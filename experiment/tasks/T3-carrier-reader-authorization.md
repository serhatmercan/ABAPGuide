# T3 — Airline reader with authorization

## Run metadata (operator only; not given to the assistant)

| Item | Value |
|---|---|
| Target system | On-premise (Standard ABAP); uses SAP's demo table `SCARR` and authorization object `S_CARRID` |
| Language version | Standard ABAP |
| Package | `$TMP` |
| Objects the spec requires | `ZCL_ZSM_X<run>_CARR_READER` |
| Acceptance test | `acceptance/T3/` → shell class `ZCL_ZSM_X<run>_AT_CARR` (ABAP SQL test double for `SCARR`; ABAP Unit authorization test environment) |
| What the run must not do | Write table rows, change authorizations, use a transport |
| Rubric focus | R-C5 unevaluated `sy-subrc`, R-T3 items |
| Precondition for the acceptance test | The user who runs the tests must hold `S_CARRID` display authorization for the carriers in the test (the test environment can only restrict authorizations); otherwise the positive tests are skipped |

## Spec text (paste after the run prompt header)

A report and a web service both need a list of airlines from table `SCARR`.
Users may only see airlines for which they have display authorization:
authorization object `S_CARRID`, field `CARRID` with the airline ID and field
`ACTVT` with activity `03` (display).

Create the class `ZCL_ZSM_X<run>_CARR_READER` with exactly this public section:

```abap
  PUBLIC SECTION.
    TYPES carrier_ids TYPE RANGE OF s_carr_id.
    TYPES carriers    TYPE STANDARD TABLE OF scarr WITH EMPTY KEY.

    METHODS read
      IMPORTING carrier_ids   TYPE carrier_ids
      RETURNING VALUE(result) TYPE carriers.
```

Behaviour of `read`:

- It returns the rows of `SCARR` whose airline ID matches `carrier_ids`
  (an empty range means all airlines), sorted by airline ID.
- An airline for which the current user has no display authorization is left
  out of the result without an error.
- If no airline remains, the result is empty.

## Objects and names

All names with `<run>` replaced by the run ID. The object goes to `$TMP` on the
on-premise destination.
