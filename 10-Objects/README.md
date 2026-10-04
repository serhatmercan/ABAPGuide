# 10 — Objects & OOP

> **Lifecycle:** `CURRENT / RECOMMENDED`. ABAP Objects is the default for new code. OLE automation is labelled where it appears. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

Object-oriented ABAP (`CLASS`/`METHODS`) is the recommended approach for all new development. This chapter covers class definition basics (visibility sections, static vs. instance members), inheritance, interfaces, constructors and events, and working with classic OLE/legacy objects (`ole2_object`) as well as OData model objects.

The rules for designing classes are in [section 5 of the rule set](../docs/ABAP-Development-Rules.md#5-classes-and-methods); this chapter shows the syntax and links the rules where they apply.

## 🧱 Defining and Using a Class

```abap
REPORT zsm_r_calculator.

CLASS lcl_calculator DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS add
      IMPORTING first_number  TYPE i
                second_number TYPE i
      RETURNING VALUE(result) TYPE i.

    " Static only to show the call syntax; Rule 5.3 prefers instance methods
    CLASS-METHODS multiply
      IMPORTING first_number  TYPE i
                second_number TYPE i
      RETURNING VALUE(result) TYPE i.

    " Two results, so EXPORTING parameters instead of RETURNING (Rule 5.9)
    METHODS divide
      IMPORTING dividend  TYPE i
                divisor   TYPE i
      EXPORTING quotient  TYPE i
                remainder TYPE i.
ENDCLASS.


CLASS lcl_calculator IMPLEMENTATION.
  METHOD add.
    result = first_number + second_number.
  ENDMETHOD.

  METHOD multiply.
    result = first_number * second_number.
  ENDMETHOD.

  METHOD divide.
    quotient  = dividend DIV divisor.
    remainder = dividend MOD divisor.
  ENDMETHOD.
ENDCLASS.


START-OF-SELECTION.
  DATA(calculator) = NEW lcl_calculator( ).

  " A RETURNING parameter lets the call stand where a value is expected (Rule 3.15)
  DATA(total) = calculator->add( first_number  = 10
                                 second_number = 20 ).

  DATA(product) = lcl_calculator=>multiply( first_number  = 10
                                            second_number = 20 ).

  " A standalone call accepts inline declarations for its output parameters
  calculator->divide( EXPORTING dividend  = 17
                                divisor   = 5
                      IMPORTING quotient  = DATA(quotient)
                                remainder = DATA(remainder) ).

  " Demo output only; cl_demo_output is not meant for productive code
  cl_demo_output=>display( |{ total } { product } { quotient } { remainder }| ).
```

> ⚠️ **`DATA(total) TYPE int4.` is not valid.** `DATA(...)` is a declaration expression in a write position, and it takes its type from that position, so it cannot carry a `TYPE` addition.

> 📝 Inline declarations work for the output parameters of a **standalone** method call, as in `divide` above; the type comes from the formal parameter. They are not possible in a functional call, for `CHANGING` parameters, or with `CALL FUNCTION`. There, declare the variable up front.

## 🔐 Visibility Sections (Encapsulation)

```abap
CLASS lcl_parent DEFINITION.
  PUBLIC SECTION.
    " A public attribute only to show the section; Rule 5.6 keeps attributes private
    DATA public_value TYPE i.

    METHODS set_values.

  PROTECTED SECTION.
    DATA protected_value TYPE i.

  PRIVATE SECTION.
    DATA private_value TYPE i.
ENDCLASS.


CLASS lcl_parent IMPLEMENTATION.
  METHOD set_values.
    public_value = 1.
    protected_value = 2.
    private_value = 3.
  ENDMETHOD.
ENDCLASS.
```

| Section | Visible From |
|---|---|
| `PUBLIC SECTION` | Anywhere (the class's external interface) |
| `PROTECTED SECTION` | The class itself and its subclasses |
| `PRIVATE SECTION` | Only the class itself |

## 🧬 Inheritance

```abap
CLASS lcl_child DEFINITION INHERITING FROM lcl_parent FINAL.
  PUBLIC SECTION.
    " REDEFINITION overrides an inherited method; the parameters are inherited
    " and must not be repeated.
    METHODS set_values REDEFINITION.
ENDCLASS.

CLASS lcl_child IMPLEMENTATION.
  METHOD set_values.
    super->set_values( ).   " call the inherited implementation first
    protected_value = 20.   " PROTECTED members are visible here
  ENDMETHOD.
ENDCLASS.
```

`lcl_child` contains all components of `lcl_parent`. It can use the `PUBLIC` and `PROTECTED` ones; the `PRIVATE` ones exist in the subclass but are not visible there. Use `INHERITING FROM` for "is-a" relationships; prefer composition (holding a reference to another object) for "has-a" relationships — [Rule 5.5](../docs/ABAP-Development-Rules.md#55-prefer-composition-to-inheritance).

A redefinition stays in the visibility section where the superclass declares the method. Private methods, final methods and the instance constructor cannot be redefined.

`lcl_parent` is open for inheritance because the example derives from it. `lcl_child` is `FINAL`, like every class that is not designed for inheritance — [Rule 5.2](../docs/ABAP-Development-Rules.md#52-make-classes-final-unless-they-are-designed-for-inheritance).

> 💡 Every concrete method declared in `CLASS ... DEFINITION`, including each `REDEFINITION`, needs its own `METHOD ... ENDMETHOD` block in `CLASS ... IMPLEMENTATION`. Abstract methods have none.

## 🧭 Instance vs. Static Members

| | Instance (`METHODS`, `DATA`) | Static (`CLASS-METHODS`, `CLASS-DATA`) |
|---|---|---|
| Belongs to | A specific object instance | The class itself (shared) |
| Call syntax | `calculator->add( )` | `lcl_calculator=>multiply( )` |
| Needs an instance (`NEW`)? | ✅ Yes | ❌ No |
| Typical use | Business object state & behavior | Factory methods and stateless type utilities — [Rule 5.3](../docs/ABAP-Development-Rules.md#53-prefer-instance-methods-to-static-methods) |

## 🔌 Interfaces

An interface declares components — mostly methods — without implementing them. A class takes it over with `INTERFACES` in its public section and implements each method as `interface~method`. Callers that hold a reference typed with the interface work with every class that implements it; they see only the components the interface declares **[verify]**. That is polymorphism in ABAP Objects without inheritance, and it is how a test hands in a double instead of the database access — [Rule 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor).

> 📝 **Contextual snippet** — assumes the data elements `zsm_e_order_id` and `zsm_e_order_status` and a custom table `zsm_t_order`.

```abap
INTERFACE lif_order_repository.
  METHODS read_status
    IMPORTING order_id      TYPE zsm_e_order_id
    RETURNING VALUE(result) TYPE zsm_e_order_status.
ENDINTERFACE.


CLASS lcl_db_order_repository DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_order_repository.
ENDCLASS.


CLASS lcl_db_order_repository IMPLEMENTATION.
  METHOD lif_order_repository~read_status.
    " >>> Authorization check for the order (order_id) belongs here.
    SELECT SINGLE status
      FROM zsm_t_order
      WHERE order_id = @order_id
      INTO @result.
  ENDMETHOD.
ENDCLASS.
```

An interface can also declare attributes, constants, types and events, and include other interfaces. It has no constructor. For interfaces that SAP defines and you implement, see [16-BADIs](../16-BADIs/README.md).

## 🏗️ Constructors

The instance constructor is the method `constructor`. `NEW` and `CREATE OBJECT` call it once for each new object; it cannot be called explicitly. It may have only `IMPORTING` parameters, plus exceptions. Declare it in the public section; a global class requires that.

Keep it to setup: store the dependencies it receives and check its input — [Rule 5.12](../docs/ABAP-Development-Rules.md#512-limit-constructors-to-setup). Receiving the dependency as an interface reference is constructor injection — [Rule 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor).

> 📝 **Contextual snippet** — continues the Interfaces snippet; `order_id` is assumed to be declared.

```abap
CLASS lcl_order_service DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING repository TYPE REF TO lif_order_repository.

    METHODS is_released
      IMPORTING order_id      TYPE zsm_e_order_id
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    CONSTANTS released TYPE zsm_e_order_status VALUE 'R'.

    DATA repository TYPE REF TO lif_order_repository.
ENDCLASS.


CLASS lcl_order_service IMPLEMENTATION.
  METHOD constructor.
    " Setup only: no reads, no postings, no remote calls (Rule 5.12)
    me->repository = repository.
  ENDMETHOD.

  METHOD is_released.
    result = xsdbool( repository->read_status( order_id ) = released ).
  ENDMETHOD.
ENDCLASS.


START-OF-SELECTION.
  " Production wiring; a test passes its own implementation of lif_order_repository
  DATA(service) = NEW lcl_order_service( repository = NEW lcl_db_order_repository( ) ).
  DATA(order_is_released) = service->is_released( order_id ).
```

> ⚠️ **A subclass constructor must call `super->constructor( )`.** Until it has done so, it cannot use the instance components of its own object. The only exception is a direct subclass of `object`, the root class.

The static constructor `class_constructor` is declared with `CLASS-METHODS` in the public section and has no parameters. ABAP calls it exactly once per class and internal session, before the class is first used; accessing only a type or a constant of the class does not trigger it.

## 📣 Events

A class declares an event with `EVENTS` and triggers it with `RAISE EVENT`. Other objects register handler methods for it with `SET HANDLER`. The raising class does not know who listens, which keeps the two sides independent.

- **Parameters:** an event has only output parameters, passed by value. Every instance event also passes the implicit parameter `sender`, the object that raised it.
- **Handlers:** a handler method names the event with `FOR EVENT … OF` and lists the parameters it wants after `IMPORTING`; their types come from the event.
- **Execution:** `RAISE EVENT` runs all registered handlers before the next statement. The order in which they run is undefined.

> 📝 **Contextual snippet** — assumes the data element `zsm_e_order_id` and a variable `order_id`.

```abap
CLASS lcl_order_releaser DEFINITION FINAL.
  PUBLIC SECTION.
    EVENTS order_released
      EXPORTING VALUE(order_id) TYPE zsm_e_order_id.

    METHODS release
      IMPORTING order_id TYPE zsm_e_order_id.
ENDCLASS.


CLASS lcl_order_releaser IMPLEMENTATION.
  METHOD release.
    " The status change itself is left out here
    RAISE EVENT order_released EXPORTING order_id = order_id.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_release_log DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_order_released
      FOR EVENT order_released OF lcl_order_releaser
      IMPORTING order_id.

  PRIVATE SECTION.
    DATA released_orders TYPE STANDARD TABLE OF zsm_e_order_id WITH EMPTY KEY.
ENDCLASS.


CLASS lcl_release_log IMPLEMENTATION.
  METHOD on_order_released.
    APPEND order_id TO released_orders.
  ENDMETHOD.
ENDCLASS.


START-OF-SELECTION.
  DATA(releaser)    = NEW lcl_order_releaser( ).
  DATA(release_log) = NEW lcl_release_log( ).

  " Register for this one releaser; FOR ALL INSTANCES registers for every instance
  SET HANDLER release_log->on_order_released FOR releaser.

  releaser->release( order_id ).
```

> ⚠️ **Do not make handlers depend on each other.** The documentation leaves the order of handler execution undefined, so a handler that needs another handler's result has to be one method, or the raising class has to call both in order.

> 💡 The ALV grid is the event source you will meet most often in classic code: `cl_gui_alv_grid` raises events such as a double-click, and the report registers a local handler class for them — see [13-ALV](../13-ALV/README.md).

## 🧰 Legacy & Interop Objects (OLE, OData Model)

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE` for `ole2_object` automation (driving Excel/Word from ABAP). It is tied to SAP GUI for Windows and does not work with SAP GUI for HTML/Java, in background jobs, or over headless RFC. Generate a file on the server instead (CSV, or XLSX via `cl_salv_bs_*` / an OpenXML library). See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference).

> 📝 **Contextual snippet** — `zsm_msg` is the placeholder message class.

```abap
DATA excel     TYPE ole2_object.
DATA workbooks TYPE ole2_object.

" 1. Create the OLE Automation object FIRST
CREATE OBJECT excel 'EXCEL.APPLICATION'.
IF sy-subrc <> 0.
  MESSAGE s040(zsm_msg) DISPLAY LIKE 'E'.
  RETURN.
ENDIF.

" 2. Then call methods on it
CALL METHOD OF excel 'Workbooks' = workbooks.
CALL METHOD OF workbooks 'Add'.

" 3. Always release OLE objects when finished
FREE OBJECT excel.
```

> ⚠️ **An OLE object must be created before any method is called on it.** `CREATE OBJECT` sets `sy-subrc` to a value other than 0 when the SAP GUI cannot create it, so check it before the first `CALL METHOD OF`.

> 📝 **Contextual snippet** — `model` is the OData model reference of a SAP Gateway (SEGW) service, set elsewhere; `iv_entity_name` is fixed by the SAP interface ([Rule 2.4](../docs/ABAP-Development-Rules.md#24-keep-names-that-are-fixed-by-a-signature-you-do-not-own)). SEGW services are covered in [GWGuide](https://github.com/serhatmercan/GWGuide).

```abap
DATA model       TYPE REF TO /iwbep/if_mgw_odata_model.
DATA entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.

" Guard an object reference BEFORE using it: return when it is NOT bound
IF model IS NOT BOUND.
  RETURN.
ENDIF.

" Getting entity metadata from an OData model (SAP Gateway)
entity_type = model->get_entity_type( iv_entity_name = 'PurchaseOrder' ).
```

> ⚠️ **An `IS BOUND` guard must return when the reference is not bound.** Writing `IF model IS BOUND. RETURN. ENDIF.` exits precisely when the object *is* usable — [Rule 3.18](../docs/ABAP-Development-Rules.md#318-check-references-with-is-bound-and-field-symbols-with-is-assigned-where-they-can-be-empty).

## 🧭 Scope Note

**Exception classes are not covered here.** Their design rules are in [section 6 of the rule set](../docs/ABAP-Development-Rules.md#6-error-handling), and raising and handling them is shown in [18-Debugging](../18-Debugging/README.md#-exception-handling).

## ✅ Best Practices

- Write new logic in classes, and make them `FINAL` unless they are designed for inheritance — [Rules 5.1](../docs/ABAP-Development-Rules.md#51-write-new-logic-in-classes-wrap-function-modules-and-bapis) and [5.2](../docs/ABAP-Development-Rules.md#52-make-classes-final-unless-they-are-designed-for-inheritance).
- Default to `PRIVATE SECTION` for attributes; expose behavior via `PUBLIC` methods (encapsulation) — [Rule 5.6](../docs/ABAP-Development-Rules.md#56-keep-the-public-section-minimal).
- Prefer composition over inheritance unless there is a genuine "is-a" relationship — [Rule 5.5](../docs/ABAP-Development-Rules.md#55-prefer-composition-to-inheritance).
- Prefer instance methods; keep static methods for factories and stateless type utilities — [Rule 5.3](../docs/ABAP-Development-Rules.md#53-prefer-instance-methods-to-static-methods).
- Return one value with `RETURNING` and call the method functionally — [Rules 5.9](../docs/ABAP-Development-Rules.md#59-return-one-value-with-returning-instead-of-exporting) and [3.15](../docs/ABAP-Development-Rules.md#315-call-methods-functionally).
- Check `IS BOUND` before calling a method on a reference that might not have been created — and make sure the guard returns when it is **not** bound — [Rule 3.18](../docs/ABAP-Development-Rules.md#318-check-references-with-is-bound-and-field-symbols-with-is-assigned-where-they-can-be-empty).
- Depend on interfaces and receive dependencies through the constructor — [Rule 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor).
- Keep constructors to setup: store dependencies, check input — [Rule 5.12](../docs/ABAP-Development-Rules.md#512-limit-constructors-to-setup).
- Use `NEW #( )` (inline instantiation) instead of the older `CREATE OBJECT calculator TYPE lcl_calculator.` syntax in modern ABAP — [Rule 3.6](../docs/ABAP-Development-Rules.md#36-create-objects-with-new). (`CREATE OBJECT` is still required for `ole2_object`.)

## ⚠️ Common Mistakes

- Making all attributes `PUBLIC` "for convenience" — this breaks encapsulation and makes future refactoring risky.
- Misunderstanding the scope of static attributes. `CLASS-DATA` is shared by all instances **within the same internal session** — not across users, and not across external sessions (modes). Sharing state beyond the session requires shared-memory-enabled classes or the database; assuming `CLASS-DATA` does it is a subtle and expensive bug.
- Using an unbound reference. Calling a method through it raises a catchable exception (`CX_SY_REF_IS_INITIAL` [verify]); reading an attribute through it ends the program with a runtime error that cannot be caught.
- Adding `TYPE` to an inline `DATA(...)` declaration.
- Expecting inline declarations in a functional method call or a `CALL FUNCTION`; only standalone method calls accept them for output parameters.
- Reading data, posting or calling other systems in a constructor; it runs on every `NEW` and cannot be skipped in a test.
- Forgetting `super->constructor( )` in a subclass constructor.
- Relying on the order in which event handlers run — it is undefined.

## 🎤 Interview & Review Checkpoints

- Explain encapsulation, inheritance, and polymorphism with ABAP-specific syntax examples.
- Explain the difference between `METHODS` and `CLASS-METHODS`, and the exact scope of `CLASS-DATA`.
- Explain `REDEFINITION` and when you would call `super->`.
- Explain why a class is `FINAL` unless it is designed for inheritance.
- Be ready to discuss when to use interfaces (`INTERFACE`/`INTERFACES`) vs. class inheritance.
- Explain the difference between `constructor` and `class_constructor`, and when each runs.
- Explain how an event reaches its handlers, and what `sender` contains.

## 🔗 Related Chapters

- [09-Modularization](../09-Modularization/README.md) — where function modules are still needed next to classes
- [13-ALV](../13-ALV/README.md) — a full OOP ALV example, including event handlers
- [16-BADIs](../16-BADIs/README.md) — interface implementation in practice
- [18-Debugging](../18-Debugging/README.md) — exception classes and their handling
- [20-Best-Practices](../20-Best-Practices/README.md) — Clean ABAP names and review checklist for classes
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle of `CREATE OBJECT` and OLE automation
