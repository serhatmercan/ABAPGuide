# 10 — Objects & OOP

> **Lifecycle:** `CURRENT / RECOMMENDED`. ABAP Objects is the default for new code. OLE automation is labelled where it appears. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

Object-oriented ABAP (`CLASS`/`METHODS`) is the recommended approach for all new development. This chapter covers class definition basics (visibility sections, static vs. instance members), inheritance, and working with classic OLE/legacy objects (`ole2_object`) as well as OData model objects.

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

This chapter covers class definition, visibility, inheritance and static-vs-instance members. **Interfaces, polymorphism, constructors, events and exception classes are not covered here** — they are core ABAP Objects topics that deserve more room than this chapter currently gives them. For interface implementation in practice see [16-BADIs](../16-BADIs/README.md); for exception handling see [18-Debugging](../18-Debugging/README.md#-exception-handling); for events see the `cl_gui_alv_grid` handlers in [13-ALV](../13-ALV/README.md).

The rule set states the design rules for these topics: interfaces and constructor injection in [Rule 5.4](../docs/ABAP-Development-Rules.md#54-depend-on-interfaces-and-receive-dependencies-through-the-constructor), constructors in [Rule 5.12](../docs/ABAP-Development-Rules.md#512-limit-constructors-to-setup), and exception classes in [section 6](../docs/ABAP-Development-Rules.md#6-error-handling).

## ✅ Best Practices

- Write new logic in classes, and make them `FINAL` unless they are designed for inheritance — [Rules 5.1](../docs/ABAP-Development-Rules.md#51-write-new-logic-in-classes-wrap-function-modules-and-bapis) and [5.2](../docs/ABAP-Development-Rules.md#52-make-classes-final-unless-they-are-designed-for-inheritance).
- Default to `PRIVATE SECTION` for attributes; expose behavior via `PUBLIC` methods (encapsulation) — [Rule 5.6](../docs/ABAP-Development-Rules.md#56-keep-the-public-section-minimal).
- Prefer composition over inheritance unless there is a genuine "is-a" relationship — [Rule 5.5](../docs/ABAP-Development-Rules.md#55-prefer-composition-to-inheritance).
- Prefer instance methods; keep static methods for factories and stateless type utilities — [Rule 5.3](../docs/ABAP-Development-Rules.md#53-prefer-instance-methods-to-static-methods).
- Return one value with `RETURNING` and call the method functionally — [Rules 5.9](../docs/ABAP-Development-Rules.md#59-return-one-value-with-returning-instead-of-exporting) and [3.15](../docs/ABAP-Development-Rules.md#315-call-methods-functionally).
- Check `IS BOUND` before calling a method on a reference that might not have been created — and make sure the guard returns when it is **not** bound — [Rule 3.18](../docs/ABAP-Development-Rules.md#318-check-references-with-is-bound-and-field-symbols-with-is-assigned-where-they-can-be-empty).
- Use `NEW #( )` (inline instantiation) instead of the older `CREATE OBJECT calculator TYPE lcl_calculator.` syntax in modern ABAP — [Rule 3.6](../docs/ABAP-Development-Rules.md#36-create-objects-with-new). (`CREATE OBJECT` is still required for `ole2_object`.)

## ⚠️ Common Mistakes

- Making all attributes `PUBLIC` "for convenience" — this breaks encapsulation and makes future refactoring risky.
- Misunderstanding the scope of static attributes. `CLASS-DATA` is shared by all instances **within the same internal session** — not across users, and not across external sessions (modes). Sharing state beyond the session requires shared-memory-enabled classes or the database; assuming `CLASS-DATA` does it is a subtle and expensive bug.
- Using an unbound reference. Calling a method through it raises a catchable exception (`CX_SY_REF_IS_INITIAL` [verify]); reading an attribute through it ends the program with a runtime error that cannot be caught.
- Adding `TYPE` to an inline `DATA(...)` declaration.
- Expecting inline declarations in a functional method call or a `CALL FUNCTION`; only standalone method calls accept them for output parameters.

## 🎤 Interview & Review Checkpoints

- Explain encapsulation, inheritance, and polymorphism with ABAP-specific syntax examples.
- Explain the difference between `METHODS` and `CLASS-METHODS`, and the exact scope of `CLASS-DATA`.
- Explain `REDEFINITION` and when you would call `super->`.
- Explain why a class is `FINAL` unless it is designed for inheritance.
- Be ready to discuss when to use interfaces (`INTERFACE`/`IMPLEMENTS`) vs. class inheritance.

## 🔗 Related Chapters

- [09-Modularization](../09-Modularization/README.md) — where function modules are still needed next to classes
- [13-ALV](../13-ALV/README.md) — a full OOP ALV example, including event handlers
- [16-BADIs](../16-BADIs/README.md) — interface implementation in practice
- [18-Debugging](../18-Debugging/README.md) — exception handling
- [20-Best-Practices](../20-Best-Practices/README.md) — Clean ABAP names and review checklist for classes
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle of `CREATE OBJECT` and OLE automation
