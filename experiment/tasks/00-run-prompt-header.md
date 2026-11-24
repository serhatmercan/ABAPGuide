# Run prompt header

The operator pastes this header, with the placeholders filled, followed by the
"Spec text" section of one task file. The header and the spec text are
identical in all three conditions; only the run ID changes.

Placeholders:
- `{RUN}`: the run ID, two or three upper-case letters and digits, for example `A1`
  (condition A, task 1) or `PB1` (pilot, condition B, task 1).
- `{DEST}`: the ADT destination named in the task file (on-premise or SAP BTP).
- `{PACKAGE}`: `$TMP` on-premise, a package of your own on SAP BTP (the experiment used one temporary package).

---

You are connected to an SAP system through the ADT MCP tools. Implement the
task below completely and on your own: do not ask questions; where the task
leaves a choice, decide yourself.

- Create every object on destination {DEST} in package {PACKAGE}. Do not
  create or use transport requests.
- In all object names, replace `<run>` with `{RUN}`.
- Do not insert, update or delete rows in any database table, and do not run
  code that does. Do not change any existing object that you did not create.
- Activate every object you create. If an activation fails, fix the cause and
  activate again; after 5 failed activation attempts for the same object,
  stop working on it and report what is left.
- When you are done, list every object you created, with its type.

Task:

