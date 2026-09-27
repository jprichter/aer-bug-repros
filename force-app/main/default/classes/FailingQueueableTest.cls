@IsTest
private class FailingQueueableTest {
  @IsTest
  static void testFailedQueueableStatus() {
    Test.startTest();
    Id jobId = System.enqueueJob(new FailingQueueable());
    try {
      Test.stopTest();
    } catch (Exception ex) {
      // Test.stopTest() rethrows an unhandled exception from the Queueable.
    }

    AsyncApexJob job = [
      SELECT Status, NumberOfErrors
      FROM AsyncApexJob
      WHERE Id = :jobId
    ];

    System.assertEquals('Failed', job.Status);
  }
}
