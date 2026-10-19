# AER bug reproductions

## Status (re-checked with AER v1.4.30 and v1.5.9)

| Repro | v1.4.30 | v1.5.9 |
| --- | --- | --- |
| `async-apexjob-status` | ✅ Fixed | ✅ Fixed |
| `finalizer-queueable-stack-depth` | ✅ Fixed | ✅ Fixed |
| `dynamic-user-mode-soql` | ℹ️ Not a bug: the test needed `System.runAs` | ℹ️ Not a bug |
| `master-detail-delete-access` | ✅ Fixed | ❌ Still failing |
| `sobject-put-non-editable-field` | ✅ Fixed | ❌ Still failing |

## Reproductions

| Repro | What it covers | Details |
| --- | --- | --- |
| [`async-apexjob-status`](repros/async-apexjob-status/) | `AsyncApexJob.Status` after a Queueable throws during `Test.stopTest()` |
| [`dynamic-user-mode-soql`](repros/dynamic-user-mode-soql/) | Custom-field resolution in dynamic user-mode SOQL |
| [`master-detail-delete-access`](repros/master-detail-delete-access/) | Non-owner with Edit on the master cannot delete a detail record |
| [`finalizer-queueable-stack-depth`](repros/finalizer-queueable-stack-depth/) | Queueable stack depth for a job enqueued from a Finalizer in a test |
| [`sobject-put-non-editable-field`](repros/sobject-put-non-editable-field/) | `SObject.put()` on a read-only standard or system field (audit fields, `IsDeleted`, `PermissionSet.IsOwnedByProfile`) does not throw |

## Run a reproduction

Change to the repro's directory and run its project with AER:

```sh
cd repros/<repro-name>
aer test force-app
```

Each project has its own `sfdx-project.json`. Use that directory when
deploying the source or running tests against a Salesforce org.
