# 19 — Performance & Memory

## 📖 Introduction

Performance problems in ABAP usually come from three sources: inefficient database access, inefficient internal table processing, or unnecessary memory usage. This chapter covers ABAP Memory (`EXPORT`/`IMPORT`/`SUBMIT ... AND RETURN`) and consolidates performance guidance referenced throughout this guide.

## 💾 ABAP Memory — Passing Data Between Programs

ABAP Memory (`MEMORY ID`) lets you pass data between an `EXPORT`ing and `SUBMIT`ted/called program within the same session/user context — useful for passing data to a called report without database round trips.

```abap
" Standard EXPORT/IMPORT via ABAP Memory
IMPORT mem_likp FROM MEMORY ID 'MEM_LIKP'.
EXPORT mem_likp TO MEMORY ID 'MEM_LIKP'.

" Reading data from memory (custom pattern): clear old memory, call another
" report to populate it via export, then import
DATA et_alv TYPE zsd_tt_0061.

FREE MEMORY ID 'ZSD_P_0001'.

CLEAR et_alv[].

SUBMIT zsd_p_0001
       WITH cb_epdk EQ cb_epdk
       WITH s_vkorg IN it_vkorg
       WITH p_ihrack EQ i_ihrack
       WITH p_export EQ 'X'
       AND RETURN.

IMPORT et_alv FROM MEMORY ID 'ZSD_P_0001'.
```

> ⚠️ **Warning:** ABAP Memory (`MEMORY ID`) is valid for the **entire user session** (across multiple `SUBMIT`/`CALL TRANSACTION` calls) unless explicitly cleared with `FREE MEMORY`. Always `FREE MEMORY ID '...'` before reusing an ID to avoid picking up stale data from a previous run. For passing data purely within one call stack, prefer normal method/function parameters — ABAP Memory should be reserved for genuinely decoupled program-to-program communication.

## 🚀 Internal Table Performance

| Technique | Why It Helps |
|---|---|
| Add a **secondary sorted/hashed key** | Turns O(n) linear scans into O(log n) or O(1) lookups for non-primary-key reads (see [07-Internal-Tables](../07-Internal-Tables/README.md#-defining-table-types)) |
| Use `FIELD-SYMBOLS`/`REFERENCE INTO` instead of `INTO` | Avoids copying large structures on every loop iteration |
| `SORT` + `DELETE ADJACENT DUPLICATES` before `FOR ALL ENTRIES` | Reduces redundant database work (see [08-Open-SQL](../08-Open-SQL/README.md#-for-all-entries-in)) |
| Use `BINARY SEARCH` with `READ TABLE` on a sorted table | Avoids full linear scans on large standard tables |
| Prefer `LOOP ... WHERE` over `LOOP` + `IF` | The `WHERE` condition can leverage a table's sorted/hashed key |
| Select only required fields / rows (`WHERE`, field list) | Reduces network and memory overhead from the database |

## 🗄️ Database Performance

- Avoid `SELECT *`; select only the columns you need.
- Avoid `SELECT` inside a `LOOP` ("SELECT in a loop") — replace with a single bulk `SELECT ... FOR ALL ENTRIES` or a `JOIN`.
- Use `SELECT SINGLE 1` (or `COUNT(*)` only when the exact count matters) for existence checks.
- Always index custom (Z) tables on the fields most frequently used in `WHERE` clauses, in coordination with the Basis/DBA team.
- Use `ST05` (SQL trace) to verify the actual number of database round trips and rows fetched.

## ✅ Best Practices

- Profile before optimizing — use `SE30`/`SAT` (Runtime Analysis) and `ST05` (SQL Trace) to find the actual bottleneck rather than guessing.
- `FREE MEMORY ID` when done with ABAP Memory, and avoid using it as a general-purpose "pass data anywhere" mechanism — it makes program dependencies implicit and hard to trace.
- Batch database writes (`COMMIT WORK` outside loops) and reads (`FOR ALL ENTRIES`/joins instead of loop-selects).

## ⚠️ Common Mistakes

- `SELECT` statements inside `LOOP`s — one of the most common ABAP performance anti-patterns.
- Forgetting `FREE MEMORY` before reusing a `MEMORY ID`, causing subtle bugs where old data "leaks" into a new run.
- Adding secondary keys to internal tables that are only ever read via the primary key — unnecessary overhead with no benefit.

## 🎤 Interview Tips

- Be ready to name the top 3 ABAP performance anti-patterns and their fixes (SELECT in loop, missing FOR ALL ENTRIES safeguards, SELECT *).
- Explain how a secondary table key improves internal table read performance.
- Explain the danger of relying on ABAP Memory across independent programs.

## 🖥️ Related Transaction Codes

| T-Code | Purpose |
|---|---|
| ST05 | SQL Trace |
| SE30 / SAT | ABAP Runtime Analysis (profiling) |
| ST22 | Short dump analysis (e.g., `TSV_TNEW_PAGE_ALLOC_FAILED` for memory issues) |
| ST02 | Buffer/memory statistics |

## 🔗 Related Chapters

- [07-Internal-Tables](../07-Internal-Tables/README.md)
- [08-Open-SQL](../08-Open-SQL/README.md)
- [20-Best-Practices](../20-Best-Practices/README.md)
