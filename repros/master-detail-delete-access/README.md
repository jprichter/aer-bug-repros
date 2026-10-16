# Deleting a master-detail child without owning the master

This project checks whether a user can delete a detail record when they have
Edit access to its master record but do not own it.

Run with AER from this directory:

```sh
aer test force-app
```

## Setup

- `Repro_Parent__c` has a Public Read/Write org-wide default.
- `Repro_Child__c` is its detail object, through the master-detail field
  `Repro_Child__c.Repro_Parent__c`. Its sharing is Controlled by Parent.
- The `Repro_Detail_Editor` permission set grants:
  - Read/Create/Edit (no Delete) on `Repro_Parent__c`
  - full CRUD on `Repro_Child__c`
- The test runs as a Standard User with that permission set. The parent
  record is owned by the user who runs the tests.
- A second pair, `Repro_Private_Parent__c` (Private org-wide default) and its
  detail `Repro_Private_Child__c`, is set up the same way. The runner gets
  access to that master only through a manual share
  (`Repro_Private_Parent__Share`, `RowCause = Manual`) with
  `AccessLevel = 'Edit'` or `'Read'`.

On Salesforce, deleting a detail record needs only **Edit** access to its
master record. The org-wide default or the Edit share gives the runner that
access, and a Read share does not. Every test passes in an org.

## Results

| Test | Salesforce (Developer Edition scratch org, API 68.0) | AER v1.4.16, v1.5.0–v1.5.4 | AER v1.4.17–v1.4.29, v1.5.5–v1.5.8 |
| --- | --- | --- | --- |
| `nonOwnerUserModeDeleteOfDetail` | PASS | PASS | FAIL |
| `nonOwnerWithSharingDeleteOfDetail` | PASS | FAIL | FAIL |
| `nonOwnerDeletesDetailItCreated` | PASS | FAIL | FAIL |
| `privateMasterEditShareUserModeDelete` | PASS | PASS | FAIL |
| `privateMasterEditShareWithSharingDelete` | PASS | FAIL | FAIL |
| `privateMasterReadShareDeleteIsDenied` | PASS | PASS | PASS |

What each test does:

- `nonOwnerUserModeDeleteOfDetail`: calls
  `Database.delete(records, true, AccessLevel.USER_MODE)`.
- `nonOwnerWithSharingDeleteOfDetail`: first updates the record, then uses a
  `delete` statement in a `with sharing` class. The update succeeds in AER;
  only the delete fails.
- `nonOwnerDeletesDetailItCreated`: the runner inserts the detail record
  itself, then deletes it. AER rejects the delete even then.
- `privateMasterEditShareUserModeDelete` and
  `privateMasterEditShareWithSharingDelete`: the same two deletes, on the
  Private master that is shared to the runner with Edit access.
- `privateMasterReadShareDeleteIsDenied` (control): the master is shared with
  Read access only. The `with sharing` delete must fail with
  `INSUFFICIENT_ACCESS_OR_READONLY`, and it does on both runtimes.

Every failure is:

```text
System.DmlException: Delete failed. First exception on row 0 with id a00aer000000001AAA; first error: INSUFFICIENT_ACCESS_OR_READONLY, insufficient access rights on object id: []
```

So the `with sharing` delete has always failed in AER. User-mode deletes
started failing in v1.4.17 (2026-09-28) and v1.5.5 (2026-09-30), which makes
them a regression. The release notes for those versions list no change to DML
access checks.

Edit access from a manual share behaves exactly like Edit access from the
org-wide default: in every AER version, the Edit-share tests fail wherever
the matching Public Read/Write tests fail. AER does tell access levels apart,
since the Read-share delete is correctly denied. But it does not accept Edit
as enough to delete a detail record, whatever grants the Edit. AER seems to
require Delete-level access to the master record, which only the owner (or a
user above them) has.

## Not a test-user permissions issue

AER's default test user has no access to custom objects or fields unless a
permission set is assigned with `--assign-perms`. That does not cause these
failures:

- Every delete runs inside `System.runAs` as a user who has the
  `Repro_Detail_Editor` permission set. The inserts and updates in the same
  tests succeed; only the delete fails.
- `aer test force-app --assign-perms Repro_Detail_Editor` gives the same
  results as the table above (checked on v1.5.4 and v1.5.8).
- Granting Delete on both master objects in the permission set, with or
  without `--assign-perms`, also gives the same results and the same
  `INSUFFICIENT_ACCESS_OR_READONLY` error. AER is not missing an object
  permission on the master. It rejects the delete based on the runner's
  record access to the master.

## Expected behavior

AER should allow a detail record to be deleted when the user has:

- Delete permission on the detail object, and
- Edit access to the master record.

This should hold for `with sharing` DML and for `AccessLevel.USER_MODE` DML,
as it does on Salesforce.
