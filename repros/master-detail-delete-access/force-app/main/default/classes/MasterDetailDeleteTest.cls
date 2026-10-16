/**
 * Setup shared by every test:
 * - Repro_Parent__c has a Public Read/Write org-wide default.
 * - Repro_Child__c is its master-detail child (sharing Controlled by Parent).
 * - The runner is a Standard User who does not own the parent. Through the
 *   Repro_Detail_Editor permission set they have Read/Create/Edit (no Delete)
 *   on the parent object and full CRUD on the child object.
 *
 * Deleting a detail record needs only Edit access on its master record, so
 * every test passes in a real org.
 */
@IsTest
private class MasterDetailDeleteTest {
  @IsTest
  static void nonOwnerUserModeDeleteOfDetail() {
    User runner = runnerWithPermSet();
    Repro_Child__c child = insertParentAndChildAsAdmin();

    System.runAs(runner) {
      Database.delete(
        new List<SObject>{ new Repro_Child__c(Id = child.Id) },
        true,
        AccessLevel.USER_MODE
      );
    }
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM Repro_Child__c WHERE Id = :child.Id]
    );
  }

  @IsTest
  static void nonOwnerWithSharingDeleteOfDetail() {
    User runner = runnerWithPermSet();
    Repro_Child__c child = insertParentAndChildAsAdmin();

    System.runAs(runner) {
      new WithSharing().updateChild(child.Id); // succeeds on both runtimes
      new WithSharing().deleteChild(child.Id);
    }
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM Repro_Child__c WHERE Id = :child.Id]
    );
  }

  @IsTest
  static void nonOwnerDeletesDetailItCreated() {
    User runner = runnerWithPermSet();
    Repro_Parent__c parent = new Repro_Parent__c(Name = 'P');
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert parent;
    }
    Id childId;
    System.runAs(runner) {
      childId = new WithSharing().insertChild(parent.Id);
      new WithSharing().deleteChild(childId);
    }
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM Repro_Child__c WHERE Id = :childId]
    );
  }

  private static Repro_Child__c insertParentAndChildAsAdmin() {
    Repro_Child__c child;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Repro_Parent__c parent = new Repro_Parent__c(Name = 'P');
      insert parent;
      child = new Repro_Child__c(Name = 'C', Repro_Parent__c = parent.Id);
      insert child;
    }
    return child;
  }

  private static User runnerWithPermSet() {
    User runner = new User(
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
      LastName = 'Runner',
      Email = 'mdrepro@example.com',
      Username = 'mdrepro' + System.now().getTime() + '@example.com',
      Alias = 'mdrepro',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    // Setup rows in their own runAs block avoid MIXED_DML_OPERATION.
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert runner;
      insert new PermissionSetAssignment(
        AssigneeId = runner.Id,
        PermissionSetId = [
          SELECT Id
          FROM PermissionSet
          WHERE Name = 'Repro_Detail_Editor'
        ]
        .Id
      );
    }
    return runner;
  }

  public with sharing class WithSharing {
    public Id insertChild(Id parentId) {
      Repro_Child__c child = new Repro_Child__c(
        Name = 'C',
        Repro_Parent__c = parentId
      );
      insert child;
      return child.Id;
    }
    public void updateChild(Id childId) {
      update new Repro_Child__c(Id = childId, Name = 'C2');
    }
    public void deleteChild(Id childId) {
      delete new Repro_Child__c(Id = childId);
    }
  }
}
