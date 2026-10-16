# SObject.put() on a non-editable field

This project checks what `SObject.put()` does when the field is not editable.
Its example is `PermissionSet.IsOwnedByProfile`.

Run with AER from this directory:

```sh
aer test force-app
```

| Runtime | `putOnNonEditableFieldThrows` | `deserializeCanSetNonEditableField` |
| --- | --- | --- |
| Salesforce (Developer Edition scratch org, API 68.0) | PASS | PASS |
| AER v1.4.16, v1.4.29, v1.5.8 | FAIL | PASS |

On Salesforce, `put()` throws
`System.SObjectException: Field IsOwnedByProfile is not editable`. AER lets the
call succeed and sets the value, so the test's assertion fails.

## Impact

A test that builds an in-memory record with `put()` on a read-only field
passes in AER but fails when the same test runs in an org.
`JSON.deserialize` can set the field on both runtimes, and it is the portable
way to build such a record.

## Expected behavior

AER should check whether a field is editable in `SObject.put()` and throw
`SObjectException: Field <name> is not editable`, as Salesforce does.
`JSON.deserialize` should still be able to set such fields.

## Open question

Only `PermissionSet.IsOwnedByProfile` was checked. It is not known whether
other read-only fields, such as formula, roll-up and audit fields, behave the
same way.
