@IsTest
private class DepthProbeJobTest {
  @IsTest
  static void finalizerChainedJobDoesNotInheritStackDepth() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      AsyncOptions options = new AsyncOptions();
      options.MaximumQueueableStackDepth = 100;
      Test.startTest();
      System.enqueueJob(new DepthProbeJob(1, false), options);
      Test.stopTest();
      Map<String, Account> byName = new Map<String, Account>();
      for (Account a : [SELECT Name FROM Account WHERE Name LIKE 'Depth step %']) {
        byName.put(a.Name, a);
      }
      // Both jobs run on Salesforce and in AER.
      System.assertEquals(2, byName.size(), byName.keySet());
      // The first job's enqueue succeeds on both.
      System.assert(byName.containsKey('Depth step 1: enqueued'), byName.keySet());
      // Salesforce: the job enqueued from the Finalizer does not keep
      // MaximumQueueableStackDepth, so its enqueueJob throws.
      // AER: the enqueue succeeds ('Depth step 2: enqueued').
      System.assert(
        byName.containsKey('Depth step 2: Maximum stack depth has been reached.'),
        byName.keySet()
      );
    }
  }
}
