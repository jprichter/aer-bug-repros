# Dynamic user-mode SOQL reproduction

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

Observed with AER v1.4.16 and v1.5.4: static SOQL and dynamic system-mode
SOQL pass, but dynamic user-mode SOQL fails with:

```text
QueryException: No such column 'Target_User__c' on entity 'Lookup_Field_Repro__c'.
```

The field exists in the source metadata. This project reduces the failure to a
single lookup field and `Database.queryWithBinds` call.

To verify on Salesforce, deploy `force-app` to a scratch org, then run
`LookupFieldQueryReproTest` there.

See `~/wiki/aer-user-mode-dynamic-soql-bug.md` for the full bug report,
environment details, and impact.
