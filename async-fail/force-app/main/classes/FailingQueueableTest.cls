@IsTest
private class FailingQueueableTest {
  @IsTest
  static void testFailedQueueableStatus() {
    Test.startTest();
    Id jobId = System.enqueueJob(new FailingQueueable());
    Boolean stopTestThrew = false;
    try {
      Test.stopTest();
    } catch (Exception ex) {
      // Test.stopTest() rethrows an unhandled exception from the Queueable.
      stopTestThrew = true;
    }
    System.assert(stopTestThrew, 'Test.stopTest() should surface the Queueable failure.');

    AsyncApexJob job = [
      SELECT Status, NumberOfErrors
      FROM AsyncApexJob
      WHERE Id = :jobId
    ];

    System.assertEquals('Failed', job.Status);
  }
}
