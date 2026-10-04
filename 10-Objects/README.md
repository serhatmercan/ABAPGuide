# 10 — Objects & OOP

## 📖 Introduction

Object-oriented ABAP (`CLASS`/`METHODS`) is the recommended approach for all new development. This chapter covers class definition basics (visibility sections, static vs. instance members), inheritance, and working with classic OLE/legacy objects (`ole2_object`) as well as OData model objects.

## 🧱 Defining and Using a Class

```abap
" GLOBAL CLASS
DATA total   TYPE int4.
DATA product TYPE int4.

START-OF-SELECTION.
  DATA(calculator) = NEW zcl_zsm_calculator( ).

  " Instance method with an IMPORTING (returned) parameter
  calculator->sum_two_numbers( EXPORTING first_number  = 10
                                         second_number = 20
                               IMPORTING total         = total ).

  " Static method
  zcl_zsm_calculator=>multiply_two_numbers( EXPORTING first_number  = 10
                                                      second_number = 20
                                            IMPORTING product       = product ).

  " A method with a RETURNING parameter can be used directly in an expression,
  " and its result can be captured with an inline declaration
  DATA(returned_product) = zcl_zsm_calculator=>multiply( first_number  = 10
                                                         second_number = 20 ).
```

> ⚠️ `DATA(total) TYPE int4.` is **not** valid. An inline declaration derives its type from the assignment, so it cannot carry a `TYPE` addition — and a variable that is only filled through an `IMPORTING` parameter has no assignment to derive from. Declare it classically, as above.

## 🔐 Visibility Sections (Encapsulation)

```abap
CLASS lcl_parent DEFINITION.
  PUBLIC SECTION.
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
CLASS lcl_child DEFINITION INHERITING FROM lcl_parent.
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

`lcl_child` inherits all `PUBLIC` and `PROTECTED` members of `lcl_parent`. Use `INHERITING FROM` for "is-a" relationships; prefer composition (holding a reference to another object) for "has-a" relationships.

> 💡 Every `CLASS ... DEFINITION` needs a matching `CLASS ... IMPLEMENTATION` containing a `METHOD ... ENDMETHOD` block for each declared method — a declaration without an implementation does not activate.

## 🧭 Instance vs. Static Members

| | Instance (`METHODS`, `DATA`) | Static (`CLASS-METHODS`, `CLASS-DATA`) |
|---|---|---|
| Belongs to | A specific object instance | The class itself (shared) |
| Call syntax | `object->method( )` | `zcl_zsm_calculator=>method( )` |
| Needs `NEW #( )`? | ✅ Yes | ❌ No |
| Typical use | Business object state & behavior | Utility/factory methods, singletons |

## 🧰 Legacy & Interop Objects (OLE, OData Model)

```abap
DATA excel       TYPE ole2_object.
DATA workbooks   TYPE ole2_object.
DATA model       TYPE REF TO /iwbep/if_mgw_odata_model.
DATA entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.

" 1. Create the OLE Automation object FIRST
CREATE OBJECT excel 'EXCEL.APPLICATION'.
IF sy-subrc <> 0.
  MESSAGE 'Could not start Excel' TYPE 'S' DISPLAY LIKE 'E'.
  RETURN.
ENDIF.

" 2. Then call methods on it
CALL METHOD OF excel 'Workbooks' = workbooks.
CALL METHOD OF workbooks 'Add'.

" 3. Always release OLE objects when finished
FREE OBJECT excel.

" Guard an object reference BEFORE using it: return when it is NOT bound
IF model IS NOT BOUND.
  RETURN.
ENDIF.

" Getting entity metadata from an OData model (SAP Gateway)
entity_type = model->get_entity_type( iv_entity_name = 'PurchaseOrder' ).
```

> ⚠️ Two easy mistakes in the block above, both worth internalising: an OLE object must be **created before** any method is called on it, and an `IS BOUND` guard must return when the reference is **not** bound. Writing `IF model IS BOUND. RETURN. ENDIF.` exits precisely when the object *is* usable.

> 📝 **Lifecycle:** `ole2_object` automation (driving Excel/Word from ABAP) is `LEGACY / HISTORICAL REFERENCE`. It is tied to SAP GUI for Windows and does not work with SAP GUI for HTML/Java, in background jobs, or over headless RFC. For export needs prefer generating a file (CSV, or XLSX via `cl_salv_bs_*` / an OpenXML library) rather than automating a desktop application.

## 🧭 Scope Note

This chapter covers class definition, visibility, inheritance and static-vs-instance members. **Interfaces, polymorphism, constructors, events and exception classes are not covered here** — they are core ABAP Objects topics that deserve more room than this chapter currently gives them. For interface implementation in practice see [16-BADIs](../16-BADIs/README.md); for exception handling see [18-Debugging](../18-Debugging/README.md#-exception-handling); for events see the `cl_gui_alv_grid` handlers in [13-ALV](../13-ALV/README.md).

## ✅ Best Practices

- Default to `PRIVATE SECTION` for attributes; expose behavior via `PUBLIC` methods (encapsulation).
- Prefer composition over inheritance unless there is a genuine "is-a" relationship.
- Check `IS BOUND` before calling a method on a reference that might not have been created — and make sure the guard returns when it is **not** bound.
- Use `NEW #( )` (inline instantiation) instead of the older `CREATE OBJECT calculator TYPE zcl_zsm_calculator.` syntax in modern ABAP. (`CREATE OBJECT` is still required for `ole2_object`.)

## ⚠️ Common Mistakes

- Making all attributes `PUBLIC` "for convenience" — this breaks encapsulation and makes future refactoring risky.
- Misunderstanding the scope of static attributes. `CLASS-DATA` is shared by all instances **within the same internal session** — not across users, and not across external sessions (modes). Sharing state beyond the session requires shared-memory-enabled classes or the database; assuming `CLASS-DATA` does it is a subtle and expensive bug.
- Calling a method on an unbound reference, which raises `CX_SY_REF_IS_INITIAL`.
- Adding `TYPE` to an inline `DATA(...)` declaration.

## 🎤 Interview & Review Checkpoints

- Explain encapsulation, inheritance, and polymorphism with ABAP-specific syntax examples.
- Explain the difference between `METHODS` and `CLASS-METHODS`, and the exact scope of `CLASS-DATA`.
- Explain `REDEFINITION` and when you would call `super->`.
- Be ready to discuss when to use interfaces (`INTERFACE`/`IMPLEMENTS`) vs. class inheritance.

## 🔗 Related Chapters

- [09-Modularization](../09-Modularization/README.md)
- [13-ALV](../13-ALV/README.md) — a full OOP ALV example, including event handlers
- [16-BADIs](../16-BADIs/README.md) — interface implementation in practice
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md)
