# 19 — Performance & Memory

## 📖 Introduction

Performance problems in ABAP usually come from three sources: inefficient database access, inefficient internal table processing, or unnecessary memory usage. This chapter covers ABAP Memory (`EXPORT`/`IMPORT`/`SUBMIT ... AND RETURN`) and consolidates performance guidance referenced throughout this guide.

## 💾 ABAP Memory — Passing Data Between Programs

ABAP Memory (`MEMORY ID`) lets you pass data between an `EXPORT`ing and `SUBMIT`ted/called program within the same session/user context — useful for passing data to a called report without database round trips.

```abap
" Standard EXPORT/IMPORT via ABAP Memory
EXPORT lt_deliveries TO MEMORY ID 'ZSM_DELIVERIES'.
IMPORT lt_deliveries FROM MEMORY ID 'ZSM_DELIVERIES'.

" Calling another report and collecting its result:
" clear the ID, run the report (which EXPORTs to it), then IMPORT.
DATA lt_result TYPE zsm_tt_export.

FREE MEMORY ID 'ZSM_EXPORT'.

SUBMIT zsm_r_export
       WITH s_vkorg  IN it_vkorg
       WITH p_from   EQ lv_date_from
       WITH p_to     EQ lv_date_to
       WITH p_export EQ abap_true
       AND RETURN.

IMPORT lt_result FROM MEMORY ID 'ZSM_EXPORT'.
IF sy-subrc <> 0.
  " nothing was exported - handle explicitly rather than using stale data
ENDIF.
```

> ⚠️ **Scope:** ABAP Memory (`MEMORY ID`) belongs to the **current external session (mode)** and its internal session hierarchy — it survives across `SUBMIT` and `CALL TRANSACTION` within that mode, but it is not shared with other modes or other users. Always `FREE MEMORY ID '...'` before reusing an ID, or you will silently read the previous run's data. Do not confuse it with:
> - **SAP Memory** (`SET`/`GET PARAMETER ID`) — user-wide parameter values, shared across modes;
> - **Shared memory** (shared-memory-enabled classes) — the mechanism for genuinely cross-session data.
>
> For passing data within one call stack, prefer normal method parameters. Reserve ABAP Memory for genuinely decoupled program-to-program communication.
>
> **Lifecycle:** `CLASSIC BUT STILL RELEVANT` — legitimate for `SUBMIT`-based decoupling on-premise, restricted under ABAP Cloud.

## 🚀 Internal Table Performance

| Technique | Why It Helps |
|---|---|
| Add a **secondary sorted/hashed key** | Turns O(n) linear scans into O(log n) or O(1) lookups for non-primary-key reads (see [07-Internal-Tables](../07-Internal-Tables/README.md#-defining-table-types)) |
| Use `FIELD-SYMBOLS`/`REFERENCE INTO` instead of `INTO` | Avoids copying large structures on every loop iteration |
| `SORT` + `DELETE ADJACENT DUPLICATES` before `FOR ALL ENTRIES` | Reduces redundant database work (see [08-Open-SQL](../08-Open-SQL/README.md#-for-all-entries-in)) |
| Prefer a `SORTED`/`HASHED` table or a secondary key over `READ TABLE ... BINARY SEARCH` | Both give you fast access, but the table type *guarantees* the ordering. `BINARY SEARCH` requires you to have sorted the table by exactly the right components in exactly the right sequence — and if you have not, it returns a **wrong result silently** rather than failing. Use it only when you must work with an existing standard table you cannot retype. |
| Prefer `LOOP ... WHERE` over `LOOP` + `IF` | Clearer, and the runtime can use a sorted or hashed key to narrow the iteration. Against a plain standard table it is still a full scan — the gain there is readability, not complexity. |
| Select only required fields / rows (`WHERE`, field list) | Reduces network and memory overhead from the database |

## 🗄️ Database Performance

- Avoid `SELECT *`; select only the columns you need.
- Avoid `SELECT` inside a `LOOP` ("SELECT in a loop") — replace with a single bulk `SELECT ... FOR ALL ENTRIES` or a `JOIN`.
- Use `SELECT SINGLE @abap_true` (or `COUNT(*)` only when the exact count matters) for existence checks.
- Index custom (Z) tables on the fields most frequently used in `WHERE` clauses, in coordination with the Basis/DBA team.
- Use `ST05` (SQL trace) to verify the actual number of database round trips and rows fetched.
- Read large result sets in blocks with `SELECT ... PACKAGE SIZE n ... ENDSELECT` rather than pulling millions of rows into memory at once.
- Do the aggregation and filtering **in the database**, not in ABAP. `SUM`, `COUNT`, `GROUP BY`, `CASE` and joins in ABAP SQL move the work to where the data already is; reading everything and looping is the classic mistake.

## 🧭 Scope Note

This chapter covers **ABAP-side** performance: internal tables, memory, and how you write your database access. It does **not** cover the code-pushdown toolset — CDS view entities, AMDP, and HANA-specific optimisation — which is a substantial topic in its own right and outside this guide's scope (see [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md#6-scope-boundary)). The principle that matters here is the general one above: let the database do the work it is good at.

## ✅ Best Practices

- Profile before optimizing — use `SAT` (Runtime Analysis; `SE30` is its predecessor) and `ST05` (SQL Trace) to find the actual bottleneck rather than guessing.
- `FREE MEMORY ID` when done with ABAP Memory, and avoid using it as a general-purpose "pass data anywhere" mechanism — it makes program dependencies implicit and hard to trace.
- Batch database writes and reads: one `COMMIT WORK` at the transaction boundary rather than one per row, and `FOR ALL ENTRIES` or a join instead of a select inside a loop.
- Prefer a typed `SORTED`/`HASHED` table or a secondary key over `BINARY SEARCH`.
- Hold locks for as short a time as possible — a long-running loop that holds an enqueue blocks other users for its entire duration.

## ⚠️ Common Mistakes

- `SELECT` statements inside `LOOP`s — the most common ABAP performance anti-pattern.
- Reading all rows and aggregating in ABAP when the database could have done it.
- Using `BINARY SEARCH` on a table that is not sorted by exactly the right key, which returns wrong results without any error.
- `COMMIT WORK` once per row inside a loop.
- Forgetting `FREE MEMORY` before reusing a `MEMORY ID`, so old data leaks into a new run.
- Adding secondary keys to internal tables that are only ever read via the primary key — the key has to be maintained, so it costs without paying back.

## 🎤 Interview & Review Checkpoints

- Name the top ABAP performance anti-patterns and their fixes (SELECT in loop, `SELECT *`, missing `FOR ALL ENTRIES` safeguards, aggregating in ABAP).
- Explain how a secondary table key improves read performance, and what it costs.
- Explain why `BINARY SEARCH` is riskier than a sorted table type.
- Explain the danger of relying on ABAP Memory across independent programs.
- Explain how commit frequency and lock duration affect throughput in a mass-processing job.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| ST05 | SQL Trace |
| SAT | ABAP Runtime Analysis (profiling; successor to `SE30`) |
| ST22 | Short dump analysis (e.g. `TSV_TNEW_PAGE_ALLOC_FAILED` for memory issues) |
| ST02 | Buffer/memory statistics |
| SM12 | Display and manage lock entries |

## 🔗 Related Chapters

- [07-Internal-Tables](../07-Internal-Tables/README.md)
- [08-Open-SQL](../08-Open-SQL/README.md) — including SAP LUW and commit frequency
- [20-Best-Practices](../20-Best-Practices/README.md)
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md)
