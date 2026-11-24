# 33 — ABAP Dictionary

> **Lifecycle:** `CURRENT / RECOMMENDED`. Data elements, structures, table types and database tables are the type and table layer of every ABAP system, in Standard ABAP and in ABAP for Cloud Development. Classic Dictionary views and appends on SAP tables are labelled where they appear. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

The **ABAP Dictionary** holds the global types and the database tables of a system. A type defined there can be used by any program, by screens and by CDS. A table defined there becomes a table on the database when it is activated. The language types themselves, and how a program declares its own types, are the subject of [02-Data-Types](../02-Data-Types/README.md); this chapter covers the Dictionary objects.

The tools:

- **ADT** edits tables and structures as source code (`define table`, `define structure`). Data elements are edited in a form-based editor. Technical settings and secondary indexes are maintained in a form-based tool as well, according to the ABAP Keyword Documentation.
- **SAP GUI** offers `SE11` (maintain) and `SE12` (display) for all Dictionary objects in Standard ABAP, and `SE14` as the database utility. [30-Tools-AI-Assistance](../30-Tools-AI-Assistance/README.md) lists what still needs SAP GUI.

The chapter covers:

- domains, data elements, structures and table types;
- database tables: keys, client, delivery class, technical settings, indexes;
- foreign keys, check tables, value tables, text tables and search helps;
- reading a table definition, and changing an active table;
- enhancement categories, append structures and includes;
- classic Dictionary views, and what applies in ABAP for Cloud Development.

Every section says what applies in Standard ABAP and in ABAP for Cloud Development ([Rule 1.1](../docs/ABAP-Development-Rules.md#11-know-the-language-version-of-every-object-you-change)).

## 🗺️ Standard ABAP and ABAP for Cloud Development at a Glance

| Object | Standard ABAP | ABAP for Cloud Development | Created with the ADT tool used for this guide |
|---|---|---|---|
| Domain | `SE11`, ADT | Exists in SAP BTP; SAP's `ABAP_BOOLEAN` is released **[verify: creating your own domains]** | No (not offered) |
| Data element | `SE11`, ADT | Yes (activated in SAP BTP) | Yes, both systems |
| Structure | `SE11`, ADT source | Yes (activated in SAP BTP) | Yes, both systems |
| Table type | `SE11`, ADT | Exists in SAP BTP **[verify: creating your own table types]** | No (not offered) |
| Database table | `SE11`, ADT source | Yes (activated in SAP BTP) | Yes, both systems |
| Append structure | `SE11`, ADT source (`extend type`) | Yes on an own table (activated in SAP BTP) | Yes, both systems |
| Search help | `SE11`, ADT | Exists in SAP BTP **[verify: creating your own search helps]** | No (not offered) |
| Classic Dictionary view | `SE11` | **[verify]** | No (not offered) |
| Lock object | `SE11`, ADT | Yes ([27-Lock-Objects](../27-Lock-Objects/README.md)) | Yes |

The last column records what the tool used for this guide offered on both systems; ADT itself may offer more. Names: database tables have at most 16 characters, data elements, structures and table types at most 30, according to the ABAP Keyword Documentation; domains have their own namespace. The naming table of the rules gives the prefixes ([Rule 2.6](../docs/ABAP-Development-Rules.md#26-name-development-objects-by-the-object-naming-table)).

## 🏷️ Domains

A domain describes the technical side of a value: the built-in Dictionary type, the length and the decimals. Data elements refer to it, so one domain can serve many data elements. According to the ABAP Keyword Documentation, a domain also carries semantic properties:

| Property | What it does |
|---|---|
| **Fixed values** | Single values and intervals, each with a short text shown in the input help. For `CHAR` a fixed value has at most 10 characters; for numeric types it must be a non-negative integer. |
| **Value table** | A proposal: it becomes the default check table when a foreign key is defined on a field of this domain. On its own it checks nothing. |
| **Conversion routine** | A conversion exit whose `_INPUT` and `_OUTPUT` function modules convert between the screen format and the stored format; see [09-Modularization](../09-Modularization/README.md#-conversion-exits). |
| **Output length** | Overrides the length used for output; the tools check it against the type. |
| **Lower case, sign** | Keep lower-case letters on screens, and allow negative numbers on screens. Both can only be set on a domain. |

**Example E1 — a domain with fixed values.** Domains are not offered by the tool used for this guide, so E1 is shown as its settings, not as source:

| Setting | Value |
|---|---|
| Name | `zsm_d_order_status` |
| Data type, length | `CHAR`, 1 |
| Fixed values | `N` New, `R` Released, `C` Closed |

> 💡 **Read fixed values through the type, not the tables.** RTTS reads a data element's fixed values without touching Dictionary tables ([02-Data-Types](../02-Data-Types/README.md#-reading-domain-fixed-values-at-runtime-rtts)). SAP's release information classifies `DD07L` as not to be released and names the CDS view `DDCDS_CUSTOMER_DOMAIN_VALUE` as its successor; the RTTS classes are released.

> 📝 The ABAP Keyword Documentation names CDS enumerated types as the newer way to define a closed value set, and CDS simple types next to data elements. They belong to [CDSGuide](https://github.com/serhatmercan/CDSGuide); in ABAP, an enumeration type covers the same need ([Rule 4.4](../docs/ABAP-Development-Rules.md#44-use-enumeration-types-for-a-closed-set-of-values)).

## 🔤 Data Elements

A data element gives a field its meaning. It is typed either through a domain or directly with a built-in type; a data element can also be a reference type, which cannot be used for table fields. According to the ABAP Keyword Documentation, its semantic properties are:

- **Field labels:** short, medium, long and heading. Screens, ALV and generated maintenance dialogs take their texts from here ([26-Maintenance-Views](../26-Maintenance-Views/README.md#field-labels-and-names)); they are translatable texts ([18-Debugging](../18-Debugging/README.md#-translatable-texts)). In the ABAP file format of the systems used for this chapter, the maximum lengths were 10, 20, 40 and 55 characters.
- **Documentation:** shown as field help (`F1`).
- **Search help and parameter ID:** a search help for the input help, and an SPA/GPA parameter that pre-fills screen fields. Both only for elementary data elements.
- **Default component name:** the name proposed when the data element is used in a structure or table.

**Example E2 — two data elements.** In ADT they are form-based objects; their settings:

| Data element | Type | Short / medium / long / heading label |
|---|---|---|
| `zsm_e_order_status` | `CHAR` 1 | Status / Order Status / Order Status / St |
| `zsm_e_order_id` | `CHAR` 10 | Order / Order ID / Order ID / Order ID |

> 📝 In practice `zsm_e_order_status` would use the domain E1; it is typed directly here because the tool could not create domains.

## 🧩 Structures and Includes

A Dictionary structure is a global structured type. It can contain elementary fields, other structures (nested) and table types (deep). An **include** copies the components of another structure into this one, without a substructure; according to the ABAP Keyword Documentation:

- includes can be nested up to a depth of nine;
- a **group name** lets a program address the included components together;
- a **suffix** of three characters renames the included components to avoid name clashes.

**Example E3 — a structure with an include.**

```abap
@EndUserText.label : 'Audit fields'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
define structure zsm_s_audit {

  created_on : abap.dats;
  created_by : abap.char(12);

}
```

```abap
@EndUserText.label : 'Order item'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
define structure zsm_s_order_item {

  order_id : zsm_e_order_id;
  item_no  : abap.numc(4);
  quantity : abap.int4;
  include zsm_s_audit;

}
```

> ⚠️ **Includes copy fields silently.** A field added to `zsm_s_audit` appears in every structure and table that includes it, at the next activation. The ABAP Keyword Documentation calls includes error-prone and prefers substructures; in database tables it advises a suffix. Use an include where the fields really belong to every user of it.

A structure that only one program needs belongs in that program as `TYPES ... BEGIN OF` ([02-Data-Types](../02-Data-Types/README.md#-structures)). Put it in the Dictionary when several programs, a screen or an interface share it.

## 📚 Table Types

A Dictionary table type describes an internal table: line type, table category (standard, sorted, hashed) and key. The choices are the same as for a local table type ([07-Internal-Tables](../07-Internal-Tables/README.md#-defining-table-types), [Rule 9.3](../docs/ABAP-Development-Rules.md#93-choose-table-kind-and-keys-deliberately-add-secondary-keys-for-frequent-non-primary-reads)).

A **ranges table type** is a standard table whose line has the components `SIGN`, `OPTION`, `LOW` and `HIGH`, like `TYPES ... RANGE OF`. According to the ABAP Keyword Documentation, `LOW` and `HIGH` must be elementary, and the line structure is a Dictionary structure of its own that the tool can generate. Ranges tables are used with `IN` in conditions and in ABAP SQL ([02-Data-Types](../02-Data-Types/README.md#-ranges-tables)).

**Example E6 — a table type.** Table types are not offered by the tool used for this guide; the settings of `zsm_tt_order_item` are line type `zsm_s_order_item`, category standard, key `order_id` and `item_no`.

> 📝 **Contextual snippet** — the local declaration with the same shape; `zsm_s_order_item` is E3.

```abap
TYPES order_items TYPE STANDARD TABLE OF zsm_s_order_item
                  WITH NON-UNIQUE KEY order_id item_no.
```

## 🗄️ Database Tables in ADT

A database table is defined in ADT with `define table` and a set of annotations. The structure of the source:

- **Header annotations:** `@EndUserText.label`, `@AbapCatalog.enhancement.category`, `@AbapCatalog.tableCategory` (`#TRANSPARENT`, or `#GLOBAL_TEMPORARY` for a global temporary table), `@AbapCatalog.deliveryClass` and `@AbapCatalog.dataMaintenance`.
- **Key fields:** at the start of the table, at least one and at most 16, together at most 900 bytes on the database, according to the ABAP Keyword Documentation. Key fields cannot be null. Above 120 bytes, the table cannot be the base of a lock object.
- **Client:** a table whose first key field has the type `CLNT` is client-dependent, and ABAP SQL restricts every access to the logon client ([Rule 7.8](../docs/ABAP-Development-Rules.md#78-let-abap-sql-handle-the-client)).
- **Delivery class and data maintenance:** who owns the entries, and what `SE16` and `SM30` may do with them. Both are explained in [26-Maintenance-Views](../26-Maintenance-Views/README.md#-customizing-tables-delivery-class-and-client) ([Rule 7.16](../docs/ABAP-Development-Rules.md#716-give-every-custom-table-the-delivery-class-of-the-people-who-own-its-data-c-for-customizing-a-for-application-data)).

> ⚠️ **ADT starts every new table with delivery class A and `#RESTRICTED`.** This was observed again on both systems for every table of this chapter. A check table that holds settings needs C; set it before the first activation.

### Technical Settings

The technical settings belong to the table but are maintained, activated and transported separately from it, according to the ABAP Keyword Documentation:

| Setting | Meaning |
|---|---|
| **Data class** | Chooses the physical storage area. Only the Oracle database evaluates it. `APPL0` for master data, `APPL1` for transaction data, `APPL2` for Customizing, `USR`/`USR1` for customer data. |
| **Size category** | 0 to 9: the expected number of rows, which sets the first storage area. More space is added automatically when it is exceeded. |
| **Buffering** | Not allowed, allowed but switched off, or switched on; types single record, generic and full. Which reads bypass the buffer, and when buffering pays off, is in [19-Performance](../19-Performance/README.md#-table-buffering). |
| **Logging** | Records changes in the log table `DBTABLOG`, shown in `SCU3` ([26-Maintenance-Views](../26-Maintenance-Views/README.md#-logging-table-changes-scu3)). |

How ADT shows the technical settings in your release is **[verify: the technical settings editor in ADT, and in the SAP BTP ABAP environment]**.

### Secondary Indexes

A secondary index speeds up reads that do not use the primary key. According to the ABAP Keyword Documentation:

- an index has a three-character ID; customer indexes on SAP tables start with `Y` or `Z`, and are transported as extension indexes of their own;
- the full text index is deprecated and not available in ABAP Cloud; the documentation points to the fuzzy search index instead.

Add an index only after a measurement shows the need ([Rule 9.1](../docs/ABAP-Development-Rules.md#91-measure-before-you-optimise), [19-Performance](../19-Performance/README.md)); every index costs time on every write.

## 🔗 Foreign Keys, Check Tables, Value Tables and Text Tables

A **foreign key** links fields of one table, the foreign key table, to the primary key of a **check table**. According to the ABAP Keyword Documentation, the Dictionary uses it:

- for the input check on dynpro and Web Dynpro fields, which can be switched on or off (`@AbapCatalog.foreignKey.screenCheck`);
- for the input help, for maintenance and help views, and for lock objects with secondary tables ([27-Lock-Objects](../27-Lock-Objects/README.md#-lock-objects-in-the-abap-dictionary)).

> ⚠️ **ABAP SQL does not check foreign keys.** According to the ABAP Keyword Documentation, nothing checks a foreign key when ABAP SQL writes a row; the program has to. A screen check protects the dialog, not the table ([Rule 7.24](../docs/ABAP-Development-Rules.md#724-do-not-rely-on-foreign-keys-in-abap-sql-check-the-referenced-value-in-code-before-writing)).

The parts of a foreign key in `define table`:

- **Cardinality** `[n,m]`, for example `[0..*,1]`. Mainly documentation; maintenance and help views use it.
- **Key type** `@AbapCatalog.foreignKey.keyType`: `#NON_KEY` or `#KEY` (documentation only), or `#TEXT_KEY` for a text table.
- A **value table** of the domain is only proposed as check table when the foreign key is created.

A **text table** holds the language-dependent texts of a check table. According to the ABAP Keyword Documentation, it has the same key as the check table plus a language field of type `LANG`, and a foreign key of key type text table to the check table. A check table has at most one text table.

**Example E4 — check table, text table and order table.**

```abap
@EndUserText.label : 'Order status values'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zsm_t_ordstat {

  key client : abap.clnt not null;
  key status : zsm_e_order_status not null;

}
```

```abap
@EndUserText.label : 'Order status texts'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zsm_t_ordstatt {

  key client   : abap.clnt not null;
  @AbapCatalog.textLanguage
  key language : abap.lang not null;
  @AbapCatalog.foreignKey.keyType : #TEXT_KEY
  @AbapCatalog.foreignKey.screenCheck : true
  key status   : zsm_e_order_status not null
    with foreign key [0..*,1] zsm_t_ordstat
      where client = zsm_t_ordstatt.client
        and status = zsm_t_ordstatt.status;
  description  : abap.char(40);

}
```

```abap
@EndUserText.label : 'Orders (Dictionary example)'
@AbapCatalog.enhancement.category : #EXTENSIBLE_CHARACTER_NUMERIC
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zsm_t_ordhdr {

  key client   : abap.clnt not null;
  key order_id : zsm_e_order_id not null;
  @AbapCatalog.foreignKey.keyType : #NON_KEY
  @AbapCatalog.foreignKey.screenCheck : true
  status       : zsm_e_order_status
    with foreign key [0..*,1] zsm_t_ordstat
      where client = zsm_t_ordhdr.client
        and status = zsm_t_ordhdr.status;
  note         : abap.char(40);
  include zsm_s_audit;

}
```

`zsm_t_ordhdr` allows character-like and numeric extensions on purpose, because E5 appends a field to it ([Rule 7.23](../docs/ABAP-Development-Rules.md#723-give-every-custom-table-and-structure-a-deliberate-enhancement-category)). The field `note` was added after the first activation; see [Changing an Active Table](#-changing-an-active-table).

> 📝 **Activation record.** E2, E3 and E4 were activated in both ABAP language versions: Standard ABAP and ABAP for Cloud Development. The active versions were read back and matched the sources above; ADT aligned the colons of the text table on its own. No row was written to any of the tables.

## 🔍 Search Helps

A search help defines the input help (`F4`) of a field. An **elementary** search help reads the values from one table or view and defines the hit list and the parameters that exchange values with the screen; a **collective** search help offers several elementary ones as tabs. A search help is attached to a data element, to a check table, or to a single field of a table or structure. Using a search help on a selection screen is shown in [12-Selection-Screens](../12-Selection-Screens/README.md#from-a-dictionary-search-help).

The ABAP Keyword Documentation names search helps as Dictionary objects but describes them only in SAP's ABAP Dictionary documentation, whose pages could not be read for this chapter **[verify: elementary and collective search helps, the order in which attached search helps apply, and search helps in ABAP for Cloud Development]**.

## 📖 Reading a Table Definition in ADT

ADT opens a table as `define table` source, SAP's tables included. Reading one answers most design questions without `SE11`:

1. **Header annotations:** enhancement category, delivery class, data maintenance.
2. **Key fields and client:** which fields identify a row, and whether the table is client-dependent.
3. **Foreign keys:** the check tables, the key type (`#TEXT_KEY` marks a text table), and whether the screen check is on.
4. **Includes and appends:** included structures appear as `include`; append structures do not appear in the table's source. ADT marks an appended table with an icon, according to the ABAP Keyword Documentation; the where-used list of the table finds the append.
5. **Technical settings:** in their own editor (see above).

In the on-premise system used for this chapter, the SAP demo table `SCARR` showed `#EXTENSIBLE_CHARACTER_NUMERIC` and foreign keys of key type `#KEY` and `#NON_KEY`; the SAP text table `TVAKT` showed `@AbapCatalog.textLanguage` on its language field and `#TEXT_KEY` on its foreign key. Reading a definition reads no data.

**Reading a definition at runtime.** The released class `XCO_CP_ABAP_DICTIONARY` returns a handle for a table, with its fields, key fields, included and appended fields.

**Example E7 — reading the fields of a table.** Target: ABAP for Cloud Development.

```abap
"! Reads the definition of a database table from the ABAP Dictionary.
CLASS zcl_zsm_table_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Whether an active version of the table exists.
    "! @parameter table_name | Name of the database table
    "! @parameter result     | abap_true if the table is active
    METHODS exists
      IMPORTING table_name    TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! Names of the key fields, in their order in the table.
    "! @parameter table_name | Name of the database table
    "! @parameter result     | Field names in upper case
    METHODS key_fields
      IMPORTING table_name    TYPE string
      RETURNING VALUE(result) TYPE string_table.

    "! Names of all fields, including included and appended ones.
    "! @parameter table_name | Name of the database table
    "! @parameter result     | Field names in upper case
    METHODS all_fields
      IMPORTING table_name    TYPE string
      RETURNING VALUE(result) TYPE string_table.

    "! Names of the fields that append structures add.
    "! @parameter table_name | Name of the database table
    "! @parameter result     | Field names in upper case
    METHODS appended_fields
      IMPORTING table_name    TYPE string
      RETURNING VALUE(result) TYPE string_table.

  PRIVATE SECTION.
    METHODS to_strings
      IMPORTING field_names   TYPE sxco_t_ad_field_names
      RETURNING VALUE(result) TYPE string_table.
ENDCLASS.


CLASS zcl_zsm_table_reader IMPLEMENTATION.
  METHOD exists.
    result = xco_cp_abap_dictionary=>database_table( CONV #( table_name ) )->exists( ).
  ENDMETHOD.

  METHOD key_fields.
    result = to_strings( xco_cp_abap_dictionary=>database_table( CONV #( table_name )
                           )->fields->key->get_names( ) ).
  ENDMETHOD.

  METHOD all_fields.
    result = to_strings( xco_cp_abap_dictionary=>database_table( CONV #( table_name )
                           )->fields->all->get_names( ) ).
  ENDMETHOD.

  METHOD appended_fields.
    result = to_strings( xco_cp_abap_dictionary=>database_table( CONV #( table_name )
                           )->fields->appended->get_names( ) ).
  ENDMETHOD.

  METHOD to_strings.
    result = VALUE #( FOR field_name IN field_names ( CONV string( field_name ) ) ).
  ENDMETHOD.
ENDCLASS.
```

The tests read only the definition of E4 and E5:

```abap
"! Reads only the definition of the example tables; no row is read or written.
CLASS ltc_table_reader DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS order_table TYPE string VALUE `ZSM_T_ORDHDR`.

    DATA cut TYPE REF TO zcl_zsm_table_reader.

    METHODS setup.
    METHODS finds_the_example_table FOR TESTING.
    METHODS misses_an_unknown_table FOR TESTING.
    METHODS lists_the_key_in_order FOR TESTING.
    METHODS lists_included_fields FOR TESTING.
    METHODS lists_the_appended_field FOR TESTING.
ENDCLASS.


CLASS ltc_table_reader IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD finds_the_example_table.
    cl_abap_unit_assert=>assert_true( cut->exists( order_table ) ).
  ENDMETHOD.

  METHOD misses_an_unknown_table.
    cl_abap_unit_assert=>assert_false( cut->exists( `ZSM_T_NOTHERE` ) ).
  ENDMETHOD.

  METHOD lists_the_key_in_order.
    cl_abap_unit_assert=>assert_equals( act = cut->key_fields( order_table )
                                        exp = VALUE string_table( ( `CLIENT` ) ( `ORDER_ID` ) ) ).
  ENDMETHOD.

  METHOD lists_included_fields.
    DATA(fields) = cut->all_fields( order_table ).

    cl_abap_unit_assert=>assert_table_contains( line  = `NOTE`
                                                table = fields ).
    cl_abap_unit_assert=>assert_table_contains( line  = `CREATED_BY`
                                                table = fields ).
  ENDMETHOD.

  METHOD lists_the_appended_field.
    cl_abap_unit_assert=>assert_equals( act = cut->appended_fields( order_table )
                                        exp = VALUE string_table( ( `ZZ_PRIORITY` ) ) ).
  ENDMETHOD.
ENDCLASS.
```

> 📝 **Activation record.** E7 was activated in both ABAP language versions: Standard ABAP and ABAP for Cloud Development, and the active versions were read back. In the SAP BTP ABAP environment, all five test methods passed; they confirm the key order, the included fields, the field `note` and the appended field `zz_priority` from the active runtime definition.

> ⚠️ **VERSION-DEPENDENT: `XCO_CP_ABAP_DICTIONARY` in Standard ABAP.** In the on-premise system used for this chapter, the same tests failed: the API reported that the table `ZSM_T_ORDHDR` does not exist, although it was active. Only `misses_an_unknown_table` passed. The class behind the API hides objects that its cloud filter does not list; the example table there was a Standard ABAP object in `$TMP`. Which objects the API shows in Standard ABAP is **[verify: the visibility rules of the XCO cloud APIs in Standard ABAP]**. In Standard ABAP, RTTS reads the same information; see E7b.

**Example E7b — the same in Standard ABAP with RTTS.** Target: Standard ABAP. `cl_abap_typedescr=>describe_by_name` returns the type description of a Dictionary table, and `get_ddic_field_list` of `cl_abap_structdescr` returns its fields with the key flag and with includes resolved. RTTS is introduced in [02-Data-Types](../02-Data-Types/README.md#-reading-domain-fixed-values-at-runtime-rtts).

```abap
"! Reads the fields of a Dictionary table with RTTS (Standard ABAP).
CLASS zcl_zsm_table_reader_rtts DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Whether the name denotes an active Dictionary structure or table.
    "! @parameter table_name | Name of the database table
    "! @parameter result     | abap_true if the type exists in the Dictionary
    METHODS exists
      IMPORTING table_name    TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! Names of the key fields, in their order in the table.
    "! @parameter table_name | Name of the database table
    "! @parameter result     | Field names in upper case; empty if unknown
    METHODS key_fields
      IMPORTING table_name    TYPE string
      RETURNING VALUE(result) TYPE string_table.

    "! Names of all fields, with the fields of includes resolved.
    "! @parameter table_name | Name of the database table
    "! @parameter result     | Field names in upper case; empty if unknown
    METHODS all_fields
      IMPORTING table_name    TYPE string
      RETURNING VALUE(result) TYPE string_table.

  PRIVATE SECTION.
    METHODS structure_of
      IMPORTING table_name    TYPE string
      RETURNING VALUE(result) TYPE REF TO cl_abap_structdescr.

    METHODS ddic_fields
      IMPORTING table_name    TYPE string
      RETURNING VALUE(result) TYPE ddfields.
ENDCLASS.


CLASS zcl_zsm_table_reader_rtts IMPLEMENTATION.
  METHOD exists.
    result = xsdbool( structure_of( table_name ) IS BOUND ).
  ENDMETHOD.

  METHOD key_fields.
    result = VALUE #( FOR field IN ddic_fields( table_name ) WHERE ( keyflag = abap_true )
                      ( CONV string( field-fieldname ) ) ).
  ENDMETHOD.

  METHOD all_fields.
    result = VALUE #( FOR field IN ddic_fields( table_name )
                      ( CONV string( field-fieldname ) ) ).
  ENDMETHOD.

  METHOD structure_of.
    DATA type TYPE REF TO cl_abap_typedescr.

    " The classic exception tells an unknown name apart from a known one
    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = table_name
                                         RECEIVING  p_descr_ref    = type
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF type->kind <> cl_abap_typedescr=>kind_struct OR type->is_ddic_type( ) = abap_false.
      RETURN.
    ENDIF.

    result = CAST #( type ).
  ENDMETHOD.

  METHOD ddic_fields.
    DATA(structure) = structure_of( table_name ).
    IF structure IS NOT BOUND.
      RETURN.
    ENDIF.

    structure->get_ddic_field_list( RECEIVING  p_field_list = result
                                    EXCEPTIONS not_found    = 1
                                               no_ddic_type = 2
                                               OTHERS       = 3 ).
    IF sy-subrc <> 0.
      CLEAR result.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

```abap
"! Reads only the definition of the example table; no row is read or written.
CLASS ltc_table_reader_rtts DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS order_table TYPE string VALUE `ZSM_T_ORDHDR`.

    DATA cut TYPE REF TO zcl_zsm_table_reader_rtts.

    METHODS setup.
    METHODS finds_the_example_table FOR TESTING.
    METHODS misses_an_unknown_table FOR TESTING.
    METHODS lists_the_key_in_order FOR TESTING.
    METHODS resolves_the_include FOR TESTING.
ENDCLASS.


CLASS ltc_table_reader_rtts IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD finds_the_example_table.
    cl_abap_unit_assert=>assert_true( cut->exists( order_table ) ).
  ENDMETHOD.

  METHOD misses_an_unknown_table.
    cl_abap_unit_assert=>assert_false( cut->exists( `ZSM_T_NOTHERE` ) ).
    cl_abap_unit_assert=>assert_initial( cut->key_fields( `ZSM_T_NOTHERE` ) ).
  ENDMETHOD.

  METHOD lists_the_key_in_order.
    cl_abap_unit_assert=>assert_equals( act = cut->key_fields( order_table )
                                        exp = VALUE string_table( ( `CLIENT` ) ( `ORDER_ID` ) ) ).
  ENDMETHOD.

  METHOD resolves_the_include.
    DATA(fields) = cut->all_fields( order_table ).

    cl_abap_unit_assert=>assert_table_contains( line  = `NOTE`
                                                table = fields ).
    cl_abap_unit_assert=>assert_table_contains( line  = `CREATED_BY`
                                                table = fields ).
  ENDMETHOD.
ENDCLASS.
```

> 📝 **Activation record.** E7b was activated in Standard ABAP on-premise, with `zsm_t_ordhdr` and the objects it uses (E2, `zsm_s_audit`, `zsm_t_ordstat`) recreated for the test. All four test methods passed, and the active version was read back and matched the source.

> ⚠️ **`get_ddic_field_list` is Standard ABAP only.** The RTTS classes are released, but the method's own documentation says that a call from ABAP for Cloud Development ends in a runtime error. In that language version, use E7.

## ♻️ Changing an Active Table

When a table that already exists on the database is changed and activated, the database table has to be **adjusted** to the new definition. According to the ABAP Keyword Documentation, some changes lose data:

| Change | Effect on existing data |
|---|---|
| Add a non-key field | Not among the data-loss cases the documentation names |
| Add a client field | The data is copied into every client of the system |
| Rename a field | The old column is dropped and a new one added: the data of the field is lost |
| Delete a key field | Rows that are no longer unique can be lost |
| Change technical properties of a field | Triggers an adjustment; how expensive it is depends on the change and the database |

The documentation also warns that adjusting a large table takes long and can leave foreign keys inconsistent, and it advises a where-used list before changing a domain or a data element that many tables use.

On-premise, transaction `SE14` is the database utility for Dictionary tables. The ABAP Keyword Documentation does not describe it; what it does in detail, and how a failed adjustment is analysed and restarted, is in SAP's ABAP Dictionary documentation **[verify: SE14 adjustment and conversion, the conversion log and restart]**. This guide neither ran nor tested a conversion.

**Example E8 — adding a field to an empty table.** In the on-premise system used for this chapter, the field `note` was added to the empty table `zsm_t_ordhdr` (E4) in `$TMP`:

- The check and the activation returned no message. Because the tools used for this guide returned no editor warnings in earlier work either, that alone proves nothing ([Rule 15.7](../docs/ABAP-Development-Rules.md#157-treat-a-tools-success-message-as-a-claim-read-back-the-result)).
- The read-back showed the field in the active version, and no separate inactive version.
- The runtime definition with `note` was confirmed by E7 in the SAP BTP ABAP environment, where the table was created with the field. In the on-premise system, E7 could not read the table (see above).

> ⚠️ **Plan a change as a migration once the table holds data.** Renaming, shortening or deleting a field, and any change to the key, are data migrations: copy, convert and verify, in that order, with a tested way back ([Rule 7.22](../docs/ABAP-Development-Rules.md#722-change-a-table-that-holds-data-only-by-adding-fields-treat-every-other-change-as-a-data-migration-with-a-plan)). Transport the table change together with every object that depends on it ([29-Transport-Quality-Gates](../29-Transport-Quality-Gates/README.md), [Rule 13.7](../docs/ABAP-Development-Rules.md#137-bundle-one-logical-change-per-transport-request-and-release-it-only-after-the-checks-of-131)).

## 🧷 Enhancement Categories, Appends and Extension Includes

The **enhancement category** of a structure or table says how it may be extended later. The program check uses it to warn where an extension could break a program, for example an offset access on a structure that may grow. According to the ABAP Keyword Documentation:

| Category | Annotation value | Allows |
|---|---|---|
| Not classified | `#NOT_CLASSIFIED` | Only for existing objects; new and changed structures get a category |
| Cannot be enhanced | `#NOT_EXTENSIBLE` | No extension |
| Can be enhanced (character-like) | `#EXTENSIBLE_CHARACTER` | Flat, character-like components and extensions only |
| Can be enhanced (character-like or numeric) | `#EXTENSIBLE_CHARACTER_NUMERIC` | Flat components and extensions |
| Can be enhanced (deep) | `#EXTENSIBLE_ANY` | Any type |

ADT proposed `#NOT_EXTENSIBLE` for every new object of this chapter. Keep it unless others are meant to extend the object ([Rule 7.23](../docs/ABAP-Development-Rules.md#723-give-every-custom-table-and-structure-a-deliberate-enhancement-category)).

The ways to extend a structure or table without changing it:

- **Append structure.** A structure that adds fields to exactly one table or structure. In ADT it is written as `extend type <table> with <append>`. According to the ABAP Keyword Documentation, appends work only on transparent tables, not on tables with `LCHR` or `LRAW` fields; the append is a separate object with its own transport; and the field order in the database can differ from the Dictionary, because existing tables are not rebuilt.
- **Customizing include.** An empty include (`CI_` for customers) that SAP reserves in its own tables; the customer fills it through Customizing.
- **Fixed-value append.** Adds fixed values to a domain.
- **Extension include in ABAP for Cloud Development.** According to the ABAP Keyword Documentation, only Dictionary database tables and structures can be released with the release contract C0 (extend). A C0 release needs extension annotations, which are maintained only in ADT: `@AbapCatalog.enhancement.fieldSuffix` and quotas for the number and size of extension fields. How SAP prepares its tables for extension in ABAP Cloud is **[verify: extension includes of released SAP tables and how they are extended]**.

**Example E5 — an append structure on our own table.** Target: Standard ABAP and ABAP for Cloud Development.

```abap
@EndUserText.label : 'Append to the order table'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
extend type zsm_t_ordhdr with zsm_a_ordhdr {

  zz_priority : abap.int1;

}
```

> 📝 **Activation record.** E5 was activated in both ABAP language versions: Standard ABAP on-premise and ABAP for Cloud Development in the SAP BTP ABAP environment. The source of `zsm_t_ordhdr` did not change. In the SAP BTP ABAP environment, E7's test confirmed `zz_priority` as an appended field of the active table.

> ⚠️ **Appends on SAP tables are an enhancement of SAP's object.** They are `CLASSIC BUT STILL RELEVANT` in Standard ABAP: modification-free, but tied to SAP's table and adjusted at every upgrade. In ABAP for Cloud Development, extend only what SAP released for extension ([21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-clean-core-and-extensibility-options), [17-Enhancements](../17-Enhancements/README.md)). This guide created appends only on its own tables.

## 🕰️ Classic Dictionary Views

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT`. According to the ABAP Keyword Documentation, CDS entities replace data modelling with Dictionary views; Dictionary views are not called obsolete, except external views. New views are CDS view entities ([CDSGuide](https://github.com/serhatmercan/CDSGuide)).

| View | What it is | ABAP SQL |
|---|---|---|
| **Database view** | An inner join of tables, created as an SQL view on the database | Read; a view on one table can also be written |
| **Projection view** | Hides fields of one table; no database object | Read; only ABAP SQL can use it |
| **Maintenance view** | Joins tables through foreign keys for a generated maintenance dialog ([26-Maintenance-Views](../26-Maintenance-Views/README.md#-maintenance-views-and-view-clusters-se54-sm34)) | No |
| **Help view** | An outer join for a search help | No |

> **Lifecycle:** `LEGACY / HISTORICAL REFERENCE`. The ABAP Keyword Documentation lists **Dictionary external views**, which belonged to SAP HANA XS classic, as obsolete; they are not supported on SAP HANA Cloud. There is no replacement in this guide. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-legacy--historical-reference).

Whether Dictionary views can be created in ABAP for Cloud Development is **[verify: Dictionary views in ABAP for Cloud Development]**; the tool used for this guide offered none on either system.

## ☁️ The Dictionary in ABAP for Cloud Development

> **Lifecycle:** `ABAP CLOUD / MODERN CONTEXT`.

- **Works, observed:** data elements, structures with includes, database tables with foreign keys and a text table, and an append structure on an own table were activated in ABAP for Cloud Development in the SAP BTP ABAP environment.
- **SAP's own tables are not released.** Read SAP data through released CDS views ([Rule 7.2](../docs/ABAP-Development-Rules.md#72-read-through-released-cds-views-where-they-exist)); `DD07L` and the other Dictionary tables are no exception.
- **Released APIs for type information:** the RTTS classes `CL_ABAP_TYPEDESCR`, `CL_ABAP_STRUCTDESCR`, `CL_ABAP_ELEMDESCR`, `CL_ABAP_TABLEDESCR`, and `XCO_CP_ABAP_DICTIONARY`.
- **Extension:** only tables and structures released with C0 can be extended from outside their software component (see above).
- **Not available:** the full text index, according to the ABAP Keyword Documentation.
- **Open:** domains, table types, search helps and Dictionary views of your own (see the table at the start of the chapter).

## 🧭 Scope Note

Not covered in this chapter:

- **CDS:** view entities, simple and enumerated types, DDIC-based CDS views and access control belong to [CDSGuide](https://github.com/serhatmercan/CDSGuide).
- **Database-specific features:** fuzzy search indexes, HANA-specific storage and AMDP belong to the HANAGuide.
- **Running `SE14`:** adjustments and conversions of tables with data, and the repair of failed conversions.
- **The Switch Framework**, replacement objects and tuning objects; global temporary tables are only named.

## ✅ Best Practices

- Give every field a data element with field labels; reuse a domain where several data elements share a value set.
- Set the delivery class and the enhancement category when you create a table, not later — [Rules 7.16](../docs/ABAP-Development-Rules.md#716-give-every-custom-table-the-delivery-class-of-the-people-who-own-its-data-c-for-customizing-a-for-application-data) and [7.23](../docs/ABAP-Development-Rules.md#723-give-every-custom-table-and-structure-a-deliberate-enhancement-category).
- Make the client the first key field unless the data is truly cross-client — [Rule 7.8](../docs/ABAP-Development-Rules.md#78-let-abap-sql-handle-the-client).
- Check foreign-key values in code before writing — [Rule 7.24](../docs/ABAP-Development-Rules.md#724-do-not-rely-on-foreign-keys-in-abap-sql-check-the-referenced-value-in-code-before-writing).
- Change a table with data only by adding fields; plan every other change as a migration — [Rule 7.22](../docs/ABAP-Development-Rules.md#722-change-a-table-that-holds-data-only-by-adding-fields-treat-every-other-change-as-a-data-migration-with-a-plan).
- Read the `define table` source of a table before designing around it.
- Read type information through RTTS or XCO, not through the Dictionary tables.

## ⚠️ Common Mistakes

- Keeping the defaults of a new table: delivery class A and `#NOT_EXTENSIBLE` without thinking about either.
- Relying on a foreign key to keep wrong values out of a table written by ABAP SQL.
- Renaming a field of a table with data, and losing the column.
- Building fields from built-in types only, so that screens and ALV show technical names.
- Adding an include to many tables and forgetting that every later change reaches all of them.
- Creating new Dictionary database views instead of CDS view entities.
- Reading `DD02L`, `DD03L` or `DD07L` in new code instead of using RTTS or XCO.

## 🎤 Interview & Review Checkpoints

- Explain the difference between a domain and a data element, and what each one carries.
- What makes a table client-dependent, and what does ABAP SQL do with the client?
- What does a foreign key check, and what does it not check?
- What is a text table, and how is it linked to its check table?
- Which changes to an active table can lose data?
- Name the enhancement categories, and explain why the category matters for programs that use the structure.
- What is an append structure, and what is the cloud way to extend an SAP table?
- Why are new views CDS view entities rather than Dictionary views?

## 🖥️ Related Transaction Codes

| T-code | Purpose |
|---|---|
| `SE11` | ABAP Dictionary: maintain |
| `SE12` | ABAP Dictionary: display |
| `SE13` | Technical settings of a table |
| `SE14` | Database utility: adjustment and conversion |
| `SE16`, `SE16N` | Data browser |
| `AL12` | Table buffer ([19-Performance](../19-Performance/README.md#-table-buffering)) |
| `SCU3` | Table change logs ([26-Maintenance-Views](../26-Maintenance-Views/README.md#-logging-table-changes-scu3)) |

## 🔗 Related Chapters

- [02-Data-Types](../02-Data-Types/README.md) — language types, local structures and RTTS
- [07-Internal-Tables](../07-Internal-Tables/README.md) — local table types and keys
- [08-Open-SQL](../08-Open-SQL/README.md) — reading and writing the tables defined here
- [12-Selection-Screens](../12-Selection-Screens/README.md) — using a search help on a screen
- [17-Enhancements](../17-Enhancements/README.md) — enhancement techniques around SAP objects
- [19-Performance](../19-Performance/README.md) — table buffering and indexes
- [26-Maintenance-Views](../26-Maintenance-Views/README.md) — delivery class, maintenance dialogs and change logs
- [27-Lock-Objects](../27-Lock-Objects/README.md) — lock objects on the tables defined here
- [29-Transport-Quality-Gates](../29-Transport-Quality-Gates/README.md) — transporting Dictionary objects
- [30-Tools-AI-Assistance](../30-Tools-AI-Assistance/README.md) — ADT and `SE11`
- [32-IDoc-ALE](../32-IDoc-ALE/README.md) — the previous chapter
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — lifecycle of Dictionary views, appends and extension
