@IsTest
private class LookupFieldQueryReproTest {
  @IsTest
  static void staticSoqlSelectsCustomLookupField() {
    Id userId = UserInfo.getUserId();
    insert new Lookup_Field_Repro__c(Target_User__c = userId);

    List<Lookup_Field_Repro__c> rows = [
      SELECT Target_User__c
      FROM Lookup_Field_Repro__c
      WHERE Target_User__c = :userId
    ];

    System.assertEquals(1, rows.size());
    System.assertEquals(userId, rows[0].Target_User__c);
  }

  @IsTest
  static void dynamicUserModeSelectsCustomLookupField() {
    assertQueryMode(AccessLevel.USER_MODE);
  }

  @IsTest
  static void dynamicSystemModeSelectsCustomLookupField() {
    assertQueryMode(AccessLevel.SYSTEM_MODE);
  }

  private static void assertQueryMode(AccessLevel accessLevel) {
    Id userId = UserInfo.getUserId();
    insert new Lookup_Field_Repro__c(Target_User__c = userId);

    List<SObject> rows = Database.queryWithBinds(
      'SELECT Target_User__c FROM Lookup_Field_Repro__c ' +
        'WHERE Target_User__c = :userId',
      new Map<String, Object>{ 'userId' => userId },
      accessLevel
    );

    System.assertEquals(1, rows.size());
    System.assertEquals(userId, rows[0].get('Target_User__c'));
  }
}
