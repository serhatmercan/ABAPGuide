# Safety

- **Systems.** Only the two destinations used for this guide: the on-premise
  development system (`$TMP`) and the SAP BTP ABAP environment (a
  package of your own, `{PACKAGE}`). Never a customer system. Destination
  names are filled in at run time and are not written into the kit.
- **Run prefixes.** Every object name contains `ZSM_X<run>_` (for example
  `ZCL_ZSM_XB3_RESERVER`), so each run's objects can be found and deleted
  without touching anything else. Search with `*ZSM_X<run>_*`: the shorter
  `*X<run>_*` also matches SAP objects. The package `{PACKAGE}` itself is
  never listed for deletion.
- **No data writes.** The run header forbids inserting, updating or deleting
  rows and running code that does. The tasks are built so that no real BAPI,
  mail, lock or table write is needed: the acceptance tests replace them with
  doubles or the ABAP SQL test double. T4's table stays empty.
- **No test runs in the runs.** The run configuration denies the unit test
  tool, so a test the assistant writes cannot reach the real BAPI, mail or
  table; only the evaluation session runs the acceptance tests, which use
  doubles only.
- **No commits beyond the task.** No task needs a real commit; any commit
  statement the assistant writes is only counted (R-C1), and no test runs it
  against real data.
- **No transports.** Objects in `$TMP` cannot be transported; in SAP BTP the
  header forbids transport requests.
- **No authorizations changed.** T3's tests use the ABAP Unit authorization
  test environment, which restricts the tester's authorizations for the test
  session only.
- **Deletion lists.** After each evaluation, a fresh read-only search for
  `*ZSM_X<run>_*` on the run's destination produces the deletion list; the operator
  deletes by hand and confirms with a second search. Nothing is deleted by an
  assistant.
- **Transcripts.** Transcripts contain system names and user names; they stay
  on the local machine and are never copied into a repository. Results tables
  contain numbers and object names with run prefixes only.
