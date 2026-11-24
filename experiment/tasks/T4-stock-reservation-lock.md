# T4 — Stock reservation with a lock

## Run metadata (operator only; not given to the assistant)

| Item | Value |
|---|---|
| Target system | SAP BTP ABAP environment |
| Language version | ABAP for Cloud Development |
| Package | `{PACKAGE}`: a package of your own |
| Objects the spec requires | table `ZSM_X<run>_STOCK`, lock object `EZSM_X<run>_STOCK`, `ZIF_ZSM_X<run>_STOCK_LOCK`, `ZCX_ZSM_X<run>_LOCKED`, `ZCX_ZSM_X<run>_NO_STOCK`, `ZCL_ZSM_X<run>_STOCK_LOCK`, `ZCL_ZSM_X<run>_RESERVER` |
| Acceptance test | `acceptance/T4/` → shell class `ZCL_ZSM_X<run>_AT_RES` (ABAP SQL test double for `ZSM_X<run>_STOCK`, a hand-written lock double) |
| What the run must not do | Write rows into `ZSM_X<run>_STOCK` (the table stays empty), use a transport |
| Rubric focus | R-C1a commit, R-C1b rollback, R-T4 items |

## Spec text (paste after the run prompt header)

Sales reserves stock per material and plant. Two users must never reserve the
same stock at the same time.

Create the database table `ZSM_X<run>_STOCK` exactly as given:

```abap
@EndUserText.label : 'Stock for reservations'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zsm_x<run>_stock {
  key client   : abap.clnt not null;
  key material : abap.char(18) not null;
  key plant    : abap.char(4) not null;
  available    : abap.int4;
  reserved     : abap.int4;
}
```

Create a lock object `EZSM_X<run>_STOCK` for this table, with an exclusive lock
on the key fields.

Create the following objects exactly as given (you may add ABAP Doc comments):

```abap
CLASS zcx_zsm_x<run>_locked DEFINITION PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING previous LIKE previous OPTIONAL.
ENDCLASS.
```

```abap
CLASS zcx_zsm_x<run>_no_stock DEFINITION PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING previous LIKE previous OPTIONAL.
ENDCLASS.
```

```abap
INTERFACE zif_zsm_x<run>_stock_lock PUBLIC.
  "! Locks the stock of one material in one plant for the current user.
  METHODS lock
    IMPORTING material TYPE zsm_x<run>_stock-material
              plant    TYPE zsm_x<run>_stock-plant
    RAISING   zcx_zsm_x<run>_locked.
  "! Releases the lock set by lock.
  METHODS unlock
    IMPORTING material TYPE zsm_x<run>_stock-material
              plant    TYPE zsm_x<run>_stock-plant.
ENDINTERFACE.
```

Then create:

1. `ZCL_ZSM_X<run>_STOCK_LOCK`, which implements `zif_zsm_x<run>_stock_lock`
   with the lock object `EZSM_X<run>_STOCK`. If another user holds the lock,
   `lock` raises `zcx_zsm_x<run>_locked`.
2. `ZCL_ZSM_X<run>_RESERVER` with exactly this public section:

```abap
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING lock TYPE REF TO zif_zsm_x<run>_stock_lock.

    METHODS reserve
      IMPORTING material TYPE zsm_x<run>_stock-material
                plant    TYPE zsm_x<run>_stock-plant
                quantity TYPE i
      RAISING   zcx_zsm_x<run>_locked
                zcx_zsm_x<run>_no_stock.
```

Behaviour of `reserve`:

- It locks the stock of the material in the plant while it reserves: the lock
  is set before the row is read.
- If the lock cannot be set, it raises `zcx_zsm_x<run>_locked` and changes
  nothing.
- If there is no row for the material and plant, or if `available` minus
  `reserved` is less than `quantity`, it raises `zcx_zsm_x<run>_no_stock` and
  changes nothing.
- Otherwise it increases `reserved` of that row by `quantity`.
- If the reservation fails, nothing stays locked.

## Objects and names

All names with `<run>` replaced by the run ID. Every object goes to package
`{PACKAGE}` on the SAP BTP destination.
