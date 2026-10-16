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

On Salesforce, deleting a detail record needs only **Edit** access to its
master record. The org-wide default gives the runner that access, so every
test passes in an org.

## Results

| Runtime | `nonOwnerUserModeDeleteOfDetail` | `nonOwnerWithSharingDeleteOfDetail` | `nonOwnerDeletesDetailItCreated` |
| --- | --- | --- | --- |
| Salesforce (Developer Edition scratch org, API 68.0) | PASS | PASS | PASS |
| AER v1.4.16, v1.5.0–v1.5.4 | PASS | FAIL | FAIL |
| AER v1.4.17–v1.4.29, v1.5.5–v1.5.8 | FAIL | FAIL | FAIL |

What each test does:

- `nonOwnerUserModeDeleteOfDetail`: calls
  `Database.delete(records, true, AccessLevel.USER_MODE)`.
- `nonOwnerWithSharingDeleteOfDetail`: first updates the record, then uses a
  `delete` statement in a `with sharing` class. The update succeeds in AER;
  only the delete fails.
- `nonOwnerDeletesDetailItCreated`: the runner inserts the detail record
  itself, then deletes it. AER rejects the delete even then.

Every failure is:

```text
System.DmlException: Delete failed. First exception on row 0 with id a00aer000000001AAA; first error: INSUFFICIENT_ACCESS_OR_READONLY, insufficient access rights on object id: []
```

So the `with sharing` delete has always failed in AER. User-mode deletes
started failing in v1.4.17 (2026-09-28) and v1.5.5 (2026-09-30), which makes
them a regression. The release notes for those versions list no change to DML
access checks.

AER seems to require Delete-level access to the master record, which only the
owner (or a user above them) has, instead of Edit access.

## Expected behavior

AER should allow a detail record to be deleted when the user has:

- Delete permission on the detail object, and
- Edit access to the master record.

This should hold for `with sharing` DML and for `AccessLevel.USER_MODE` DML,
as it does on Salesforce.

## Open question

Untested: a Private master org-wide default where the master is shared
Read/Write with the runner (manual share or sharing rule). That would show
whether AER checks the access level on the master or only ownership.
