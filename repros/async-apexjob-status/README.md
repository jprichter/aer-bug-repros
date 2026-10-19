# AsyncApexJob status after Queueable failure

> **✅ FIXED in AER v1.4.30** (the bug was present in v1.4.16; also passes on v1.5.9). AER now leaves
> the job `Processing` with `NumberOfErrors = 0`, as Salesforce does, and the
> test asserts that behavior.

This project checks the `AsyncApexJob` record after a Queueable throws an
unhandled exception while `Test.stopTest()` runs it.

Run with AER from this directory:

```sh
aer test force-app
```

The test catches the exception surfaced by `Test.stopTest()` and then asserts
that the job status is `Processing` with `NumberOfErrors = 0`, as Salesforce
reports during the test execution context. AER 1.4.16 incorrectly reported
`Failed`.

See `~/wiki/aer-asyncapexjob-status-bug.md` for the full bug report,
environment details, and expected behavior discussion.
