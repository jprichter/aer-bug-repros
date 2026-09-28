# AsyncApexJob status after Queueable failure

This project checks the `AsyncApexJob` record after a Queueable throws an
unhandled exception while `Test.stopTest()` runs it.

Run with AER from this directory:

```sh
aer test force-app
```

The test catches the exception surfaced by `Test.stopTest()` and then expects
the job status to be `Failed`. AER 1.4.16 reports that state; Salesforce leaves
the job `Processing` with `NumberOfErrors = 0` during the test execution
context.

See `~/wiki/aer-asyncapexjob-status-bug.md` for the full bug report,
environment details, and expected behavior discussion.
