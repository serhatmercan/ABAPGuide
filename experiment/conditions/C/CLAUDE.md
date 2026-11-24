# ABAP Development Rules — compact

One line per rule. Cite rules by number (Rule 3.12). Apply them to new and changed ABAP code.

## 1 Language Version
- 1.1 Know the ABAP language version of every object you change
- 1.2 When targeting ABAP for Cloud Development, use only released APIs
- 1.3 In Standard ABAP, prefer a released API over an unreleased one when both exist
- 1.4 State the target language version when it matters
- 1.5 Never call code cloud-ready unless it was checked

## 2 Naming
- 2.1 Use descriptive snake_case names without type or scope prefixes
- 2.2 Use plural nouns for tables, nouns for classes, verbs for methods, and questions for Booleans
- 2.3 Avoid abbreviations and noise words such as `data` or `info`
- 2.4 Keep names fixed by a signature you do not own, such as SEGW-generated or BAPI parameters
- 2.5 In legacy code, keep naming consistent within a development object
- 2.6 Name development objects by the object naming table (`zcl_zsm_`, `zsm_t_`, `zsm_tt_` …)

## 3 Modern Syntax
- 3.1 Declare variables inline at first use
- 3.2 Give an inline declaration an explicit type when the initial value would infer the wrong one
- 3.3 Declare values that are never reassigned with `FINAL`
- 3.4 Build structures and tables with `VALUE`
- 3.5 Map with `CORRESPONDING`; add `BASE` when target values must survive
- 3.6 Create objects with `NEW`
- 3.7 Convert inline with `CONV`; use `EXACT` when data must not be lost
- 3.8 Use `COND` or `SWITCH` when a condition only selects a value
- 3.9 Use `REDUCE` for one aggregated result; switch to `LOOP` when the logic grows
- 3.10 Use `FILTER` only with a suitable table key; otherwise `VALUE` with `FOR … WHERE`
- 3.11 Assemble text with string templates
- 3.12 Check existence with `line_exists`
- 3.13 Read with a table expression only when a miss is handled
- 3.14 Read a line once, not once per component
- 3.15 Call methods functionally
- 3.16 Do not write statements the ABAP Keyword Documentation classifies as obsolete
- 3.17 Use `CHECK` only as an input check at the start of a method; prefer `IF … RETURN`
- 3.18 Check references with `IS BOUND` and field symbols with `IS ASSIGNED` where they can be empty
- 3.19 Do not write macros; use methods or expressions

## 4 Constants, Enumerations and Booleans
- 4.1 Replace magic literals with named constants
- 4.2 Keep user-facing text in message classes or text symbols
- 4.3 Declare constants in the class that owns the concept, grouped by topic
- 4.4 Use enumeration types for a closed set of values
- 4.5 Give an enumeration a base type and explicit values only when the value is stored or exchanged
- 4.6 Type Booleans as `abap_bool` and compare with `abap_true` / `abap_false`
- 4.7 Derive a Boolean from a condition with `xsdbool`
- 4.8 Do not model more than two states with Booleans

## 5 Classes and Methods
- 5.1 Write new logic in classes; wrap function modules and BAPIs
- 5.2 Make classes `FINAL` unless they are designed for inheritance
- 5.3 Prefer instance methods to static methods
- 5.4 Depend on interfaces and receive dependencies through the constructor
- 5.5 Prefer composition to inheritance
- 5.6 Keep the public section minimal
- 5.7 Write small methods that do one thing at one level of abstraction
- 5.8 Keep `IMPORTING` parameters few
- 5.9 Return one value with `RETURNING`, named `result`
- 5.10 Avoid `CHANGING` parameters
- 5.11 Split a method instead of adding a Boolean switch parameter
- 5.12 Limit constructors to setup
- 5.13 Prepare form data in ABAP; keep selections and business logic out of forms
- 5.14 Keep business logic out of workflow definitions; workflow steps call methods of tested classes

## 6 Error Handling
- 6.1 Use class-based exceptions; classic exceptions only where RFC requires them
- 6.2 Build your own exception hierarchy below `zcx_zsm_`
- 6.3 Choose the exception category by what the caller can do
- 6.4 Take exception texts from a message class through the T100 interfaces
- 6.5 Raise with `RAISE EXCEPTION NEW`; use `RAISE EXCEPTION TYPE … MESSAGE` to attach a T100 message
- 6.6 Catch specific exceptions
- 6.7 Never leave a `CATCH` block empty
- 6.8 Keep the cause when converting an exception: pass it as `previous`
- 6.9 Turn `sy-subrc` and BAPI return tables into exceptions at the boundary
- 6.10 Do not use exceptions for normal control flow
- 6.11 Send `MESSAGE` statements only from the UI layer
- 6.12 State internal assumptions with `ASSERT`; raise exceptions for situations a caller or user can act on

## 7 Database Access and SAP LUW
- 7.1 Write strict ABAP SQL: comma-separated field list, `@` host variables, `INTO` after the query clauses
- 7.2 Read through released CDS views where they exist
- 7.3 Do not `SELECT` inside a loop
- 7.4 Use `FOR ALL ENTRIES` only with a non-empty, de-duplicated driver table
- 7.5 Use `SELECT SINGLE` only with the full primary key
- 7.6 Check existence with `SELECT SINGLE @abap_true`
- 7.7 List the fields you need instead of `SELECT *`
- 7.8 Let ABAP SQL handle the client
- 7.9 Write only to your own tables; change SAP standard data through BAPIs or released APIs
- 7.10 Let the top-level caller own the transaction; reusable units never `COMMIT WORK`
- 7.11 Close BAPI calls with `BAPI_TRANSACTION_COMMIT` or `BAPI_TRANSACTION_ROLLBACK`
- 7.12 Protect business transactions with enqueue locks, with the lock mode set and checked
- 7.13 Restrict the optional side of an outer join in `ON`, not in `WHERE`
- 7.14 Use `COMMIT WORK AND WAIT` only when the next step depends on the update
- 7.15 Qualify mass `UPDATE` and `DELETE` with `WHERE`, and check `sy-dbcnt`
- 7.16 Give a custom table the delivery class of its data owners: C for Customizing, A for application data
- 7.17 In table maintenance events, change only the dialog's own data; the dialog saves and commits
- 7.18 Lock with the complete key; leave a key field initial only for an intended generic lock
- 7.19 Without a lock between reading and writing, check that the data is unchanged when you write
- 7.20 Raise a workflow event only for committed data
- 7.21 Set an IDoc's success status only for a posted document; report every failure as an error status
- 7.22 Change a table that holds data only by adding fields; treat every other change as a data migration with a plan
- 7.23 Give every custom table and structure a deliberate enhancement category
- 7.24 Do not rely on foreign keys in ABAP SQL; check the referenced value in code before writing
- 7.25 Draw document numbers from a number range object, as late as possible in the SAP LUW
- 7.26 Write change documents through the generated write object; read them through the released API

## 8 Security
- 8.1 Check authorization wherever business data is read or changed, and evaluate `sy-subrc`
- 8.2 In guide examples, mark where the check belongs; never invent an authorization object
- 8.3 Use `WITH PRIVILEGED ACCESS` only with a written justification
- 8.4 Build dynamic SQL and other dynamic tokens only from validated input
- 8.5 Never hard-code credentials, hosts, destinations or any other value that differs per system or user
- 8.6 Never generate passwords, tokens or one-time codes with `cl_abap_random`
- 8.7 Resolve and validate file paths through logical file names
- 8.8 Log no secrets, and no personal data beyond what the purpose needs
- 8.9 Call transactions `WITH AUTHORITY-CHECK`
- 8.10 Check business authorizations at every RFC entry point
- 8.11 Take mail recipients and senders from configuration
- 8.12 Put no personal data into a mail beyond what the recipient needs
- 8.13 Check business authorizations in every HTTP handler, and store no logon data in a service
- 8.14 Assign an authorization group to every table that users maintain; protect sensitive tables with `S_TABU_NAM`
- 8.15 Take output devices and form names from configuration
- 8.16 Determine workflow agents through rules and organizational assignments, never user IDs
- 8.17 Put authorization checks behind an interface; test the business logic with a double and the check with the ABAP Unit authorization test environment
- 8.18 Use DUMMY only for a field that does not matter for the decision, and say why

## 9 Performance
- 9.1 Measure before you optimise
- 9.2 Push set-based work to the database
- 9.3 Choose table kind and keys deliberately; add secondary keys for frequent non-primary reads
- 9.4 Avoid nested loops over large tables
- 9.5 Loop with `ASSIGNING` or `REFERENCE INTO` for large rows and for changes
- 9.6 Read a table line once
- 9.7 Do not use `SELECT … ENDSELECT` to read row by row
- 9.8 Use `COLLECT` only with hashed tables or sorted tables with a unique key

## 10 Testing
- 10.1 Pin the current behaviour with a test before you change anything; if the code cannot take a dependency yet, a test seam is the bridge
- 10.2 Put unit tests in local test classes with `RISK LEVEL HARMLESS` and `DURATION SHORT`
- 10.3 Test one behaviour per test method
- 10.4 Name test methods after the behaviour they check
- 10.5 Structure each test as given, when, then
- 10.6 Replace dependencies with test doubles through interfaces and `cl_abap_testdouble`
- 10.7 Use test seams only for legacy code that cannot be restructured yet
- 10.8 Isolate database access with the ABAP SQL and CDS test environments; never use real data
- 10.9 Assert with `cl_abap_unit_assert`, using the most specific method
- 10.10 Run the tests in ATC and in continuous integration

## 11 Comments and ABAP Doc
- 11.1 Say it in code first: a good name beats a comment
- 11.2 Explain why, not what; comment with `"` before the statement
- 11.3 Delete code instead of commenting it out
- 11.4 Document public classes, interfaces and methods with ABAP Doc
- 11.5 Use pragmas instead of pseudo comments, each with a reason
- 11.6 Mark open work with a ticket reference, not a personal ID

## 12 Formatting
- 12.1 Write keywords in upper case and identifiers in lower case
- 12.2 Write no more than one statement per line
- 12.3 Format with the ABAP Formatter and the team's settings before activating
- 12.4 Do not chain up-front declarations
- 12.5 Keep lines within 120 characters
- 12.6 Break and align call parameters as Clean ABAP describes

## 13 Quality Gates
- 13.1 Release nothing that fails the syntax check, ABAP Unit or ATC with the team check variant
- 13.2 Fix every ATC finding or exempt it with a written reason
- 13.3 Run the cloud-readiness check wherever section 1 applies
- 13.4 Use abaplint for offline checks of complete, abapGit-serialized objects
- 13.5 Claim a check in the guides only after it ran, and record it
- 13.6 Release no always-active breakpoint: no `BREAK-POINT` without `ID` and no `BREAK` macro
- 13.7 Bundle one logical change per transport request, released only after the checks of 13.1

## 15 AI-Assisted Development
- 15.1 Cite the rules by number in CLAUDE.md and similar instruction files
- 15.2 Review generated ABAP against the checklist before accepting it
- 15.3 State the target language version in every prompt that asks for code
- 15.4 Ask the assistant to list what it did not verify
- 15.5 Never paste customer data into a prompt
- 15.6 Connect an assistant only to your own sandbox, and restrict what it may write
- 15.7 Treat a tool's success message as a claim; read back the result
