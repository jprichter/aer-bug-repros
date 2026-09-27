# AsyncApexJob status reproduction

This project reproduces a difference in `AsyncApexJob.Status` after a Queueable throws an unhandled exception while `Test.stopTest()` runs it.

The test catches the exception rethrown by `Test.stopTest()` so it can query the async job afterward, and asserts that the exception was surfaced. It then expects `AsyncApexJob.Status` to be `Failed`. AER 1.4.16 reports that state, while the Salesforce runtime leaves the job `Processing` with `NumberOfErrors = 0` during the test execution context.

Run the test with AER:

```sh
aer test force-app
```

Deploy the source to a scratch org and run the test with Salesforce CLI:

```sh
sf project deploy start --source-dir force-app --target-org scratchOrg
sf apex test run -w 10 -o scratchOrg
```

The Salesforce run is expected to pass the `stopTest()` exception assertion and fail at the status assertion if the reported behavior is present.
