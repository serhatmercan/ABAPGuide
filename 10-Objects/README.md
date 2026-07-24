# 10 — Objects & OOP

## 📖 Introduction

Object-oriented ABAP (`CLASS`/`METHODS`) is the recommended approach for all new development. This chapter covers class definition basics (visibility sections, static vs. instance members), inheritance, and working with classic OLE/legacy objects (`ole2_object`) as well as OData model objects.

## 🧱 Defining and Using a Class

```abap
" GLOBAL CLASS
START-OF-SELECTION.
  DATA(lo_class) = NEW zsm_cl_test( ).
  DATA(lv_sum) TYPE int4.
  DATA(lv_result) TYPE int4.

  " Instance Method
  lo_class->sum_two_numbers( EXPORTING iv_first_number  = 10
                                       iv_second_number = 20
                             IMPORTING ev_sum           = lv_sum ).

  " Static Method
  zsm_cl_test=>multipy_two_numbers( EXPORTING iv_first_number  = 10
                                              iv_second_number = 20
                                    IMPORTING ev_result        = lv_result ).
```

## 🔐 Visibility Sections (Encapsulation)

```abap
CLASS lcl_class DEFINITION.
  PUBLIC SECTION.
    DATA lv_public TYPE i.

    METHODS data_declaration.

  PROTECTED SECTION.
    DATA lv_protected TYPE i.

  PRIVATE SECTION.
    DATA lv_private TYPE i.
ENDCLASS.


CLASS lcl_class IMPLEMENTATION.
  METHOD data_declaration.
    lv_public = 1.
    lv_protected = 2.
    lv_private = 3.
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
CLASS lcl_sub DEFINITION INHERITING FROM lcl_class.
  PUBLIC SECTION.
    METHODS data_redeclaration.
ENDCLASS.
```

`lcl_sub` inherits all `PUBLIC` and `PROTECTED` members of `lcl_class`. Use `INHERITING FROM` for "is-a" relationships; prefer composition (holding a reference to another object) for "has-a" relationships.

## 🧭 Instance vs. Static Members

| | Instance (`METHODS`, `DATA`) | Static (`CLASS-METHODS`, `CLASS-DATA`) |
|---|---|---|
| Belongs to | A specific object instance | The class itself (shared) |
| Call syntax | `lo_object->method( )` | `zcl_class=>method( )` |
| Needs `NEW #( )`? | ✅ Yes | ❌ No |
| Typical use | Business object state & behavior | Utility/factory methods, singletons |

## 🧰 Legacy & Interop Objects (OLE, OData Model)

```abap
DATA lo_data        TYPE ole2_object.
DATA lo_value       TYPE ole2_object.
DATA lo_model       TYPE REF TO /iwbep/if_mgw_odata_model.
DATA lo_property    TYPE REF TO /iwbep/if_mgw_odata_property.
DATA lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.

" Check whether an object reference is bound (instantiated)
IF lo_entity_type IS BOUND.
  RETURN.
ENDIF.

" Call an OLE Automation method (e.g., driving Microsoft Excel)
CALL METHOD OF lo_data 'Add' = lo_data.
IF sy-subrc <> 0.
  MESSAGE TEXT-001 TYPE 'S' DISPLAY LIKE 'E'.
  EXIT.
ENDIF.

" Create an OLE Automation object
CREATE OBJECT lo_data 'EXCEL.APPLICATION'.

" Getting entity/property metadata from an OData model (SAP Gateway)
lo_entity_type = model->get_entity_type( iv_entity_name = 'POMedia' ).
```

> 📝 `ole2_object`-based automation (driving Excel/Word from ABAP) is a **legacy technique** tied to SAP GUI for Windows — it does not work with SAP GUI for HTML/Java or headless RFC calls. For modern reporting/export needs prefer generating files (CSV, XLSX via `cl_salv_bs_*` or OpenXML) rather than automating a desktop application.

## ✅ Best Practices

- Default to `PRIVATE SECTION` for attributes; expose behavior via `PUBLIC` methods (encapsulation).
- Prefer composition over inheritance unless there is a genuine "is-a" relationship.
- Always check `IS BOUND` (or `IS INITIAL` for object references) before calling methods on an object reference that might not have been created.
- Use `NEW #( )` (inline instantiation) instead of the older `CREATE OBJECT lo_x TYPE zcl_x.` syntax in modern ABAP.

## ⚠️ Common Mistakes

- Making all attributes `PUBLIC` "for convenience" — this breaks encapsulation and makes future refactoring risky.
- Forgetting that static (`CLASS-DATA`) attributes are shared across **all** instances and even across sessions in some contexts — a common source of subtle bugs.
- Calling a method on an object reference that was never instantiated (`IS INITIAL`), causing a `NULL object reference` short dump.

## 🎤 Interview Tips

- Explain encapsulation, inheritance, and polymorphism with ABAP-specific syntax examples.
- Explain the difference between `METHODS` and `CLASS-METHODS`.
- Be ready to discuss when to use interfaces (`INTERFACE`/`IMPLEMENTS`) vs. class inheritance.

## 🔗 Related Chapters

- [09-Modularization](../09-Modularization/README.md)
- [13-ALV](../13-ALV/README.md) — a full OOP ALV example
- [16-BADIs](../16-BADIs/README.md) — interface implementation in practice
