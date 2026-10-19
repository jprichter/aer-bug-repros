@IsTest
private class LookupFieldQueryReproTest {
  @IsTest
  static void staticSoqlSelectsCustomLookupField() {
    System.runAs(createAccessUser()) {
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
  }

  @IsTest
  static void dynamicUserModeSelectsCustomLookupField() {
    System.runAs(createAccessUser()) {
      assertQueryMode(AccessLevel.USER_MODE);
    }
  }

  @IsTest
  static void dynamicSystemModeSelectsCustomLookupField() {
    System.runAs(createAccessUser()) {
      assertQueryMode(AccessLevel.SYSTEM_MODE);
    }
  }

  private static User createAccessUser() {
    User u = new User(
      Alias = 'repro',
      Email = 'repro@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Repro',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
      TimeZoneSidKey = 'America/New_York',
      Username = 'repro' + System.currentTimeMillis() + '@example.com'
    );
    insert u;
    insert new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetId = [
        SELECT Id
        FROM PermissionSet
        WHERE Name = 'Lookup_Field_Repro_Access'
      ].Id
    );
    return u;
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
