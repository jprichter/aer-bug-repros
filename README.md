# AsyncApexJob status reproduction

This project reproduces a difference in `AsyncApexJob.Status` after a Queueable throws an unhandled exception while `Test.stopTest()` runs it.

The test expects `Failed`. AER 1.4.16 reports that state, while the Salesforce runtime described in the bug report leaves the job `Processing` with `NumberOfErrors = 0` during the test execution context.

Run the test with AER:

```sh
aer test force-app
```

Deploy the source to a scratch org and run the test with Salesforce CLI:

```sh
sfq project deploy start --source-dir force-app --target-org warden-dev
sfq apex test run -w 10 -o warden-dev
```

The Salesforce run is expected to fail at the status assertion if the reported behavior is present.
