# SObject.put() on a non-editable field

> **✅ FIXED in AER v1.4.30.** All 11 tests pass.
>
> **❌ NOT in the v1.5.x line:** on v1.5.9, `put()` still succeeds on
> `PermissionSet.IsOwnedByProfile` and on the `Account` audit and `IsDeleted`
> fields, so the six tests that expect a throw still fail.

This project checks what `SObject.put()` does when the field is not editable.
It covers several kinds of read-only field:

- a read-only standard field on a setup object (`PermissionSet.IsOwnedByProfile`)
- audit fields (`CreatedDate`, `CreatedById`, `LastModifiedDate`, `SystemModstamp`)
- the `IsDeleted` system field
- a custom formula field, a custom roll-up summary field, and an auto-number
  `Name` field, on the `Repro_Item__c` object included here

Run with AER from this directory:

```sh
aer test force-app
```

To run it in an org, deploy `force-app` and run `NonEditableFieldPutTest`.

## Results

| Test | Field | Salesforce | AER |
| --- | --- | --- | --- |
| `putOnEditableFieldSucceeds` (control) | `Repro_Item__c.Quantity__c` | PASS | PASS |
| `putOnNonEditableFieldThrows` | `PermissionSet.IsOwnedByProfile` | PASS | **FAIL** |
| `putOnCreatedDateThrows` | `Account.CreatedDate` | PASS | **FAIL** |
| `putOnCreatedByIdThrows` | `Account.CreatedById` | PASS | **FAIL** |
| `putOnLastModifiedDateThrows` | `Account.LastModifiedDate` | PASS | **FAIL** |
| `putOnSystemModstampThrows` | `Account.SystemModstamp` | PASS | **FAIL** |
| `putOnIsDeletedThrows` | `Account.IsDeleted` | PASS | **FAIL** |
| `putOnFormulaFieldThrows` | `Repro_Item__c.Double_Quantity__c` (formula) | PASS | PASS |
| `putOnRollUpSummaryFieldThrows` | `Repro_Item__c.Line_Count__c` (roll-up summary) | PASS | PASS |
| `putOnAutoNumberNameThrows` | `Repro_Item__c.Name` (auto-number) | PASS | PASS |
| `deserializeCanSetNonEditableField` | `PermissionSet.IsOwnedByProfile` via `JSON.deserialize` | PASS | PASS |

Salesforce: Developer Edition scratch org, API 68.0. AER: v1.4.16, v1.4.29,
v1.5.8 and v1.5.9 give the results in the table; v1.4.30 passes every test.

On Salesforce, every `put()` on a non-editable field throws
`System.SObjectException: Field <name> is not editable`. AER already throws for
custom formula, roll-up summary and auto-number fields. For the read-only
standard and system fields above, AER lets the call succeed and sets the value,
so those tests' assertions fail.

## Impact

A test that builds an in-memory record with `put()` on a read-only standard
field passes in AER but fails when the same test runs in an org. Setting audit
fields this way is a common shortcut for faking record age.
`JSON.deserialize` can set these fields on both runtimes and is the portable
way to build such a record. For inserted records, `Test.setCreatedDate` is the
supported way to change `CreatedDate`.

## Expected behavior

AER should apply the same editability check it already uses for custom
formula, roll-up summary and auto-number fields to standard read-only fields,
audit fields and system fields, and throw
`SObjectException: Field <name> is not editable`. `JSON.deserialize` should
still be able to set such fields.
