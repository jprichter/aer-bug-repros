@IsTest
private class NonEditableFieldPutTest {
  // Salesforce throws SObjectException "Field <name> is not editable" for
  // every case below. Each test fails when put() succeeds instead.
  private static void assertPutThrows(SObject record, String field, Object value) {
    Boolean threw = false;
    try {
      record.put(field, value);
    } catch (SObjectException ex) {
      threw = true;
      System.debug(ex.getMessage());
    }
    System.Assert.isTrue(
      threw,
      'put() on non-editable field ' + field + ' should throw'
    );
  }

  // Control: put() on an ordinary editable field works on both runtimes.
  @IsTest
  static void putOnEditableFieldSucceeds() {
    Repro_Item__c item = new Repro_Item__c();
    item.put('Quantity__c', 5);
    System.Assert.areEqual(5, item.Quantity__c);
  }

  // Standard read-only field on a setup object.
  @IsTest
  static void putOnNonEditableFieldThrows() {
    assertPutThrows(
      new PermissionSet(Name = 'Repro', Label = 'Repro'),
      'IsOwnedByProfile',
      false
    );
  }

  @IsTest
  static void putOnFormulaFieldThrows() {
    assertPutThrows(new Repro_Item__c(), 'Double_Quantity__c', 10);
  }

  @IsTest
  static void putOnRollUpSummaryFieldThrows() {
    assertPutThrows(new Repro_Item__c(), 'Line_Count__c', 3);
  }

  @IsTest
  static void putOnAutoNumberNameThrows() {
    assertPutThrows(new Repro_Item__c(), 'Name', 'RI-9999');
  }

  @IsTest
  static void putOnCreatedDateThrows() {
    assertPutThrows(new Account(Name = 'Repro'), 'CreatedDate', Datetime.now());
  }

  @IsTest
  static void putOnCreatedByIdThrows() {
    assertPutThrows(new Account(Name = 'Repro'), 'CreatedById', UserInfo.getUserId());
  }

  @IsTest
  static void putOnLastModifiedDateThrows() {
    assertPutThrows(new Account(Name = 'Repro'), 'LastModifiedDate', Datetime.now());
  }

  @IsTest
  static void putOnSystemModstampThrows() {
    assertPutThrows(new Account(Name = 'Repro'), 'SystemModstamp', Datetime.now());
  }

  @IsTest
  static void putOnIsDeletedThrows() {
    assertPutThrows(new Account(Name = 'Repro'), 'IsDeleted', true);
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
