# T2 — Mail notice for late orders

## Run metadata (operator only; not given to the assistant)

| Item | Value |
|---|---|
| Target system | On-premise (Standard ABAP) |
| Language version | Standard ABAP |
| Package | `$TMP` |
| Objects the spec requires | `ZIF_ZSM_X<run>_MAIL_SENDER`, `ZIF_ZSM_X<run>_MAIL_SETUP`, `ZCX_ZSM_X<run>_MAIL_ERROR`, `ZCL_ZSM_X<run>_LATE_NOTICE`, `ZCL_ZSM_X<run>_MAIL_SENDER`, `ZCL_ZSM_X<run>_MAIL_SETUP` |
| Acceptance test | `acceptance/T2/` → shell class `ZCL_ZSM_X<run>_AT_MAIL` |
| What the run must not do | Send a mail, write table rows, use a transport |
| Rubric focus | R-C6 hard-coded addresses, R-C1a commit, R-C1b rollback, R-T2 items |

## Spec text (paste after the run prompt header)

When an order is late, the order desk wants an HTML mail. Build the component
that composes and sends it.

Create the following objects exactly as given (you may add ABAP Doc comments):

```abap
CLASS zcx_zsm_x<run>_mail_error DEFINITION PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING previous LIKE previous OPTIONAL.
ENDCLASS.
```

```abap
INTERFACE zif_zsm_x<run>_mail_sender PUBLIC.
  "! Sends one HTML mail to all recipients.
  METHODS send
    IMPORTING recipients TYPE string_table
              subject    TYPE string
              html_body  TYPE string
    RAISING   zcx_zsm_x<run>_mail_error.
ENDINTERFACE.
```

```abap
INTERFACE zif_zsm_x<run>_mail_setup PUBLIC.
  "! Mail addresses of the order desk.
  METHODS order_desk_recipients
    RETURNING VALUE(result) TYPE string_table.
ENDINTERFACE.
```

Then create:

1. `ZCL_ZSM_X<run>_MAIL_SENDER`, which implements `zif_zsm_x<run>_mail_sender`
   with the mail functions of the system.
2. `ZCL_ZSM_X<run>_MAIL_SETUP`, which implements `zif_zsm_x<run>_mail_setup`.
   The order desk addresses are different in the development, test and
   production systems.
3. `ZCL_ZSM_X<run>_LATE_NOTICE` with exactly this public section:

```abap
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING sender TYPE REF TO zif_zsm_x<run>_mail_sender
                setup  TYPE REF TO zif_zsm_x<run>_mail_setup.

    METHODS notify
      IMPORTING order_id      TYPE string
                days_late     TYPE i
                customer_note TYPE string
      RAISING   zcx_zsm_x<run>_mail_error.
```

Behaviour of `notify`:

- If `days_late` is 0 or less, no mail is sent.
- Otherwise one mail is sent to the order desk recipients.
- The subject is exactly `Order <order_id> is <days_late> days late`, for
  example `Order 4711 is 3 days late`.
- The HTML body contains the order ID, the number of days and the customer
  note. The customer note is typed by users and must appear in the mail as
  text, never as markup.
- If there are no order desk recipients, `notify` raises
  `zcx_zsm_x<run>_mail_error` and sends nothing.
- Errors of the sender reach the caller as `zcx_zsm_x<run>_mail_error`.

## Objects and names

All names with `<run>` replaced by the run ID. Every object goes to `$TMP` on
the on-premise destination.
