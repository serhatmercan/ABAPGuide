# 19 — Performance & Memory

> **Lifecycle:** `CURRENT / RECOMMENDED` for the performance techniques. ABAP memory (`EXPORT`/`IMPORT … MEMORY ID`) is `CLASSIC BUT STILL RELEVANT` and labelled where it appears. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

Performance problems in ABAP usually come from three sources: inefficient database access, inefficient internal table processing, or unnecessary memory usage. This chapter covers ABAP Memory (`EXPORT`/`IMPORT`/`SUBMIT ... AND RETURN`) and consolidates performance guidance referenced throughout this guide. The rules behind it are in [section 9 of the rule set](../docs/ABAP-Development-Rules.md#9-performance); the first one is to measure before you optimise ([Rule 9.1](../docs/ABAP-Development-Rules.md#91-measure-before-you-optimise)).

## 💾 ABAP Memory — Passing Data Between Programs

ABAP Memory (`MEMORY ID`) lets you pass data between an `EXPORT`ing and `SUBMIT`ted/called program within the same session/user context — useful for passing data to a called report without database round trips.

> 📝 **Contextual snippet** — `deliveries`, `sales_org_range`, `date_from` and `date_to` are assumed; `zsm_r_export` is a placeholder report that exports its result under the name `orders`, and its selection-screen names are fixed by that report ([Rule 2.4](../docs/ABAP-Development-Rules.md#24-keep-names-that-are-fixed-by-a-signature-you-do-not-own)).

```abap
" Name each parameter: the short form without "name =" is obsolete
EXPORT deliveries = deliveries TO MEMORY ID 'ZSM_DELIVERIES'.
IMPORT deliveries = deliveries FROM MEMORY ID 'ZSM_DELIVERIES'.

" Calling another report and collecting its result:
" clear the ID, run the report (which exports ORDERS to it), then import.
DATA exported_orders TYPE zsm_tt_export.

FREE MEMORY ID 'ZSM_EXPORT'.

SUBMIT zsm_r_export
       WITH s_vkorg  IN sales_org_range
       WITH p_from   EQ date_from
       WITH p_to     EQ date_to
       WITH p_export EQ abap_true
       AND RETURN.

IMPORT orders = exported_orders FROM MEMORY ID 'ZSM_EXPORT'.
IF sy-subrc <> 0.
  " sy-subrc 4: nothing was exported - handle explicitly rather than using stale data
ENDIF.
```

> ⚠️ **Scope:** according to the ABAP Keyword Documentation, ABAP memory belongs to the **call sequence** in the current ABAP session: the programs linked by `SUBMIT … AND RETURN` or `CALL TRANSACTION` share it, and `LEAVE TO TRANSACTION` ends it. It is not shared with other sessions or other users. Always `FREE MEMORY ID '...'` before reusing an ID, or you will silently read the previous run's data. Object references cannot be stored there. Do not confuse it with:
> - **SAP Memory** (`SET`/`GET PARAMETER ID`) — the user memory. The documentation notes that the statements work on a local copy that is synchronised only at certain points, so they are suitable for passing data within one ABAP session, not between parallel sessions;
> - **Shared memory** (shared-memory-enabled classes) — the mechanism for genuinely cross-session data.
>
> For passing data within one call stack, prefer normal method parameters. Reserve ABAP Memory for genuinely decoupled program-to-program communication.

> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` — legitimate for `SUBMIT`-based decoupling on-premise. `EXPORT`/`IMPORT` without parameter names, `TO MEMORY` without `ID` and `FREE MEMORY` without `ID` are obsolete according to the ABAP Keyword Documentation. Which of these statements ABAP for Cloud Development allows is listed in the documentation's overview of language elements per language version **[verify]**.

## 🚀 Internal Table Performance

| Technique | Why It Helps |
|---|---|
| Add a **secondary sorted/hashed key** | Turns O(n) linear scans into O(log n) or O(1) lookups for non-primary-key reads (see [07-Internal-Tables](../07-Internal-Tables/README.md#-defining-table-types)) — [Rule 9.3](../docs/ABAP-Development-Rules.md#93-choose-table-kind-and-keys-deliberately-add-secondary-keys-for-frequent-non-primary-reads) |
| Use `FIELD-SYMBOLS`/`REFERENCE INTO` instead of `INTO` | Avoids copying large structures on every loop iteration — [Rule 9.5](../docs/ABAP-Development-Rules.md#95-loop-with-assigning-or-reference-into-for-large-rows-and-for-changes) |
| Replace a nested loop with keyed access or `LOOP … GROUP BY` | An inner loop over the whole table multiplies the run time — [Rule 9.4](../docs/ABAP-Development-Rules.md#94-avoid-nested-loops-over-large-tables) |
| Read a line once, not once per component | Repeated table expressions on the same line cost a search each — [Rule 9.6](../docs/ABAP-Development-Rules.md#96-read-a-table-line-once) |
| `SORT` + `DELETE ADJACENT DUPLICATES` before `FOR ALL ENTRIES` | Reduces redundant database work (see [08-Open-SQL](../08-Open-SQL/README.md#-for-all-entries-in)) — [Rule 7.4](../docs/ABAP-Development-Rules.md#74-use-for-all-entries-only-with-a-non-empty-de-duplicated-driver-table) |
| Prefer a `SORTED`/`HASHED` table or a secondary key over `READ TABLE ... BINARY SEARCH` | Both give you fast access, but the table type *guarantees* the ordering. `BINARY SEARCH` requires you to have sorted the table by exactly the right components in exactly the right sequence — and if you have not, it returns a **wrong result silently** rather than failing. Use it only when you must work with an existing standard table you cannot retype. |
| Prefer `LOOP ... WHERE` over `LOOP` + `IF` | Clearer, and the runtime can use a sorted or hashed key to narrow the iteration. Against a plain standard table it is still a full scan — the gain there is readability, not complexity. |
| `COLLECT` only into hashed tables or sorted tables with a unique key | A standard table falls back to linear searches — [Rule 9.8](../docs/ABAP-Development-Rules.md#98-use-collect-only-with-hashed-tables-or-sorted-tables-with-a-unique-key) |
| Select only required fields / rows (`WHERE`, field list) | Reduces network and memory overhead from the database |

### Read Once, Look Up by Key

> 📝 **Contextual snippet** — `items` is assumed, with the components `material`, `storage_location` and `batch`; `zsm_tt_location` is a placeholder table type with `material` and `storage_location`, and `zsm_t_stock` a placeholder table.

```abap
TYPES: BEGIN OF stock_line,
         material         TYPE matnr,
         storage_location TYPE lgort_d,
         batch            TYPE charg_d,
       END OF stock_line.

" A secondary sorted key for the lookup inside the loop (Rule 9.3)
TYPES stock_lines TYPE STANDARD TABLE OF stock_line WITH EMPTY KEY
                  WITH NON-UNIQUE SORTED KEY by_location COMPONENTS material storage_location.

DATA stock TYPE stock_lines.

" 1. One read for all items instead of one per item (Rules 7.3, 7.4)
DATA(locations) = VALUE zsm_tt_location( FOR item IN items
                                         ( material         = item-material
                                           storage_location = item-storage_location ) ).
SORT locations BY material storage_location.
DELETE ADJACENT DUPLICATES FROM locations COMPARING material storage_location.

IF locations IS NOT INITIAL.
  SELECT material, storage_location, batch
    FROM zsm_t_stock
    FOR ALL ENTRIES IN @locations
    WHERE material         = @locations-material
      AND storage_location = @locations-storage_location
    INTO TABLE @stock.
ENDIF.

" 2. Keyed access inside the loop instead of a nested scan (Rule 9.4)
LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
  <item>-batch = VALUE #( stock[ KEY by_location
                                 material         = <item>-material
                                 storage_location = <item>-storage_location ]-batch OPTIONAL ).
ENDLOOP.
```

## 🗄️ Database Performance

- Avoid `SELECT *`; select only the columns you need — [Rule 7.7](../docs/ABAP-Development-Rules.md#77-list-the-fields-you-need-instead-of-select-).
- Avoid `SELECT` inside a `LOOP` ("SELECT in a loop") — read the data in one statement before the loop: a join or subquery first, `FOR ALL ENTRIES` with a non-empty, de-duplicated driver where the driver exists only in ABAP — [Rules 7.3](../docs/ABAP-Development-Rules.md#73-do-not-select-inside-a-loop) and [7.4](../docs/ABAP-Development-Rules.md#74-use-for-all-entries-only-with-a-non-empty-de-duplicated-driver-table).
- Use `SELECT SINGLE @abap_true` (or `COUNT(*)` only when the exact count matters) for existence checks — [Rule 7.6](../docs/ABAP-Development-Rules.md#76-check-existence-with-select-single-abap_true).
- Index custom (Z) tables on the fields most frequently used in `WHERE` clauses, in coordination with the Basis/DBA team.
- Use `ST05` (SQL trace) to verify the actual number of database round trips and rows fetched.
- Read large result sets in blocks with `SELECT ... PACKAGE SIZE n ... ENDSELECT` rather than pulling millions of rows into memory at once. According to the ABAP Keyword Documentation this limits the memory per block; `FOR ALL ENTRIES` cancels the effect, because all rows are read first. Row-by-row `SELECT … ENDSELECT` without it is legacy — [Rule 9.7](../docs/ABAP-Development-Rules.md#97-do-not-use-select--endselect-to-read-row-by-row).
- Do the aggregation and filtering **in the database**, not in ABAP. `SUM`, `COUNT`, `GROUP BY`, `CASE` and joins in ABAP SQL move the work to where the data already is; reading everything and looping is the classic mistake — [Rule 9.2](../docs/ABAP-Development-Rules.md#92-push-set-based-work-to-the-database).

## 📊 Table Buffering

Tables whose technical settings allow buffering are read from the table buffer of the application server instance instead of the database. According to the ABAP Keyword Documentation:

- **Many reads bypass the buffer:** `BYPASSING BUFFER`, joins, aggregate functions (except a single `COUNT( * )`), `GROUP BY` and `HAVING`, `DISTINCT`, `FOR UPDATE`, most subqueries, and — for single-record buffering — any read without the full primary key in `=` conditions. Write `BYPASSING BUFFER` explicitly where you need the database state, instead of relying on one of these side effects.
- **Other instances see changes late:** a write invalidates the local buffer at once; the other application server instances pick the change up only at their next synchronisation, so they can read outdated data in between.
- **Buffering suits tables that are read often and changed rarely.** The documentation advises against it when more than about 1% of the accesses are writes.

Transaction `AL12` shows the contents and statistics of the buffers, `ST02` the overall buffer and memory statistics.

## 🧭 Scope Note

This chapter covers **ABAP-side** performance: internal tables, memory, and how you write your database access. It does **not** cover the code-pushdown toolset — CDS view entities, AMDP, and HANA-specific optimisation — which is a substantial topic in its own right and outside this guide's scope (see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#-scope-boundary)). The principle that matters here is the general one above: let the database do the work it is good at.

## ✅ Best Practices

- Profile before optimizing — use `SAT` (Runtime Analysis; `SE30` is its predecessor) and `ST05` (SQL Trace) to find the actual bottleneck rather than guessing — [Rule 9.1](../docs/ABAP-Development-Rules.md#91-measure-before-you-optimise).
- `FREE MEMORY ID` when done with ABAP Memory, and avoid using it as a general-purpose "pass data anywhere" mechanism — it makes program dependencies implicit and hard to trace.
- Batch database writes and reads: one `COMMIT WORK` at the transaction boundary rather than one per row, and a join or `FOR ALL ENTRIES` instead of a select inside a loop.
- Prefer a typed `SORTED`/`HASHED` table or a secondary key over `BINARY SEARCH`, and use keyed access instead of nested loops.
- Hold locks for as short a time as possible — a long-running loop that holds an enqueue blocks other users for its entire duration.

## ⚠️ Common Mistakes

- `SELECT` statements inside `LOOP`s — the most common ABAP performance anti-pattern.
- Reading all rows and aggregating in ABAP when the database could have done it.
- Nested loops over two large tables without a key on the inner one.
- Using `BINARY SEARCH` on a table that is not sorted by exactly the right key, which returns wrong results without any error.
- `COMMIT WORK` once per row inside a loop.
- Forgetting `FREE MEMORY` before reusing a `MEMORY ID`, so old data leaks into a new run.
- Writing `EXPORT itab TO MEMORY ID …` without parameter names — an obsolete form.
- Expecting a buffered table to show another server's change immediately.
- Adding secondary keys to internal tables that are only ever read via the primary key — the key has to be maintained, so it costs without paying back.

## 🎤 Interview & Review Checkpoints

- Name the top ABAP performance anti-patterns and their fixes (SELECT in loop, `SELECT *`, missing `FOR ALL ENTRIES` safeguards, aggregating in ABAP, nested loops).
- Explain how a secondary table key improves read performance, and what it costs.
- Explain why `BINARY SEARCH` is riskier than a sorted table type.
- Explain the danger of relying on ABAP Memory across independent programs.
- Explain which reads bypass the table buffer, and why buffered data can be outdated.
- Explain how commit frequency and lock duration affect throughput in a mass-processing job.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| ST05 | SQL Trace |
| SAT | ABAP Runtime Analysis (profiling; successor to `SE30`) |
| ST22 | Short dump analysis (e.g. `TSV_TNEW_PAGE_ALLOC_FAILED` for memory issues) |
| ST02 | Buffer/memory statistics |
| AL12 | Buffer monitor — contents and statistics of the table buffer and other buffers |
| SM12 | Display and manage lock entries |

## 🔗 Related Chapters

- [06-Loops](../06-Loops/README.md) — `LOOP … GROUP BY` and `COLLECT`
- [07-Internal-Tables](../07-Internal-Tables/README.md) — table kinds and secondary keys
- [08-Open-SQL](../08-Open-SQL/README.md) — including SAP LUW and commit frequency
- [09-Modularization](../09-Modularization/README.md) — `SUBMIT` with parameters
- [20-Best-Practices](../20-Best-Practices/README.md) — the review checklist
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — scope boundary and lifecycle of ABAP memory
