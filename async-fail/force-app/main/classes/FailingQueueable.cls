public with sharing class FailingQueueable implements Queueable {
  public void execute(QueueableContext context) {
    throw new IllegalArgumentException('Simulated queueable failure');
  }
}
