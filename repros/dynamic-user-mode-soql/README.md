# Dynamic user-mode SOQL reproduction

> **ℹ️ NOT A BUG: a test error, not an AER defect (checked with AER v1.4.30 and v1.5.9).**
> The original test ran as the default test user, which has no access to the
> custom object or field, so user-mode SOQL correctly rejected the query. The
> test now creates a user with the `Lookup_Field_Repro_Access` permission set
> and runs inside `System.runAs`. All three tests pass on both versions with no flags.

This minimal Salesforce DX project checks whether AER resolves a custom lookup
field in dynamic SOQL that runs in user mode.

The metadata defines `Lookup_Field_Repro__c.Target_User__c` as a lookup to the
standard `User` object. Tests issue equivalent static SOQL and dynamic SOQL
with `AccessLevel.SYSTEM_MODE` and `AccessLevel.USER_MODE`.

Run the test with AER:

```sh
aer test force-app
```

Expected: all three queries return the inserted row and all tests pass.

Each test creates a user, assigns the included `Lookup_Field_Repro_Access`
permission set, and runs its DML and queries inside `System.runAs`.

The original test ran as the default test user instead. With AER v1.4.16 and
v1.5.4, static SOQL and dynamic system-mode SOQL passed, but dynamic user-mode
SOQL failed with:

```text
QueryException: No such column 'Target_User__c' on entity 'Lookup_Field_Repro__c'.
```

The field exists in the source metadata, but user-mode SOQL enforces the
running user's object and field permissions, and the default test user has no
explicit access to this custom object or field. AER's "No such column" message
is how a user-mode query reports a field the user cannot read. The test should
have used `System.runAs` with a user holding the permission set, which it now
does.

To verify on Salesforce, deploy `force-app` to a scratch org, then run
`LookupFieldQueryReproTest` there.

See `~/wiki/aer-user-mode-dynamic-soql-bug.md` for the full bug report,
environment details, and impact.
