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
 *
 * The privateMaster* tests use a second pair, Repro_Private_Parent__c
 * (Private org-wide default) and its detail Repro_Private_Child__c. The
 * runner gets access to the master only through a manual share, which
 * separates the access level on the master from ownership.
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

  @IsTest
  static void privateMasterEditShareUserModeDelete() {
    User runner = runnerWithPermSet();
    Repro_Private_Child__c child = insertPrivateParentAndChild(runner, 'Edit');

    System.runAs(runner) {
      Database.delete(
        new List<SObject>{ new Repro_Private_Child__c(Id = child.Id) },
        true,
        AccessLevel.USER_MODE
      );
    }
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM Repro_Private_Child__c WHERE Id = :child.Id]
    );
  }

  @IsTest
  static void privateMasterEditShareWithSharingDelete() {
    User runner = runnerWithPermSet();
    Repro_Private_Child__c child = insertPrivateParentAndChild(runner, 'Edit');

    System.runAs(runner) {
      new WithSharing().deletePrivateChild(child.Id);
    }
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM Repro_Private_Child__c WHERE Id = :child.Id]
    );
  }

  @IsTest
  static void privateMasterReadShareDeleteIsDenied() {
    User runner = runnerWithPermSet();
    Repro_Private_Child__c child = insertPrivateParentAndChild(runner, 'Read');

    String error;
    System.runAs(runner) {
      try {
        new WithSharing().deletePrivateChild(child.Id);
      } catch (DmlException ex) {
        error = ex.getDmlStatusCode(0);
      }
    }
    // Read access on the master is not enough to delete its detail.
    System.Assert.areEqual('INSUFFICIENT_ACCESS_OR_READONLY', error);
    System.Assert.areEqual(
      1,
      [SELECT COUNT() FROM Repro_Private_Child__c WHERE Id = :child.Id]
    );
  }

  private static Repro_Private_Child__c insertPrivateParentAndChild(
    User runner,
    String accessLevel
  ) {
    Repro_Private_Child__c child;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Repro_Private_Parent__c parent = new Repro_Private_Parent__c(Name = 'P');
      insert parent;
      child = new Repro_Private_Child__c(
        Name = 'C',
        Repro_Private_Parent__c = parent.Id
      );
      insert child;
      insert new Repro_Private_Parent__Share(
        ParentId = parent.Id,
        UserOrGroupId = runner.Id,
        AccessLevel = accessLevel,
        RowCause = Schema.Repro_Private_Parent__Share.RowCause.Manual
      );
    }
    return child;
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
    public void deletePrivateChild(Id childId) {
      delete new Repro_Private_Child__c(Id = childId);
    }
  }
}
