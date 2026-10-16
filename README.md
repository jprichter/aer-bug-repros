# AER bug reproductions

## Reproductions

| Repro | What it covers | Details |
| --- | --- | --- |
| [`async-apexjob-status`](repros/async-apexjob-status/) | `AsyncApexJob.Status` after a Queueable throws during `Test.stopTest()` |
| [`dynamic-user-mode-soql`](repros/dynamic-user-mode-soql/) | Custom-field resolution in dynamic user-mode SOQL |
| [`master-detail-delete-access`](repros/master-detail-delete-access/) | Non-owner with Edit on the master cannot delete a detail record |

## Run a reproduction

Change to the repro's directory and run its project with AER:

```sh
cd repros/<repro-name>
aer test force-app
```

Each project has its own `sfdx-project.json`. Use that directory when
deploying the source or running tests against a Salesforce org.
