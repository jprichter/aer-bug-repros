@IsTest
private class NonEditableFieldPutTest {
  @IsTest
  static void putOnNonEditableFieldThrows() {
    PermissionSet ps = new PermissionSet(Name = 'Repro', Label = 'Repro');
    Boolean threw = false;
    try {
      ps.put('IsOwnedByProfile', false);
    } catch (SObjectException ex) {
      threw = true;
      System.debug(ex.getMessage());
    }
    // Salesforce: SObjectException "Field IsOwnedByProfile is not editable".
    // AER: put() succeeds and the value is set.
    System.Assert.isTrue(threw, 'put() on a non-editable field should throw');
  }

  @IsTest
  static void deserializeCanSetNonEditableField() {
    // The supported way to build such a row in memory works on both runtimes.
    PermissionSet ps = (PermissionSet) JSON.deserialize(
      '{"Name":"Repro","Label":"Repro","IsOwnedByProfile":false}',
      PermissionSet.class
    );
    System.Assert.isFalse(ps.IsOwnedByProfile);
  }
}
