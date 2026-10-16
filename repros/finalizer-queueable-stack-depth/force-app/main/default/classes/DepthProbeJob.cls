public with sharing class DepthProbeJob implements Queueable, Finalizer {
  private Integer step;
  private Boolean isInner;
  public DepthProbeJob(Integer step, Boolean isInner) {
    this.step = step;
    this.isInner = isInner;
  }
  public void execute(QueueableContext context) {
    if (isInner) {
      return;
    }
    System.attachFinalizer(this);
    String outcome = 'enqueued';
    try {
      System.enqueueJob(new DepthProbeJob(step, true));
    } catch (AsyncException ex) {
      outcome = ex.getMessage();
    }
    insert as user new Account(Name = 'Depth step ' + step + ': ' + outcome);
  }
  public void execute(FinalizerContext context) {
    if (step == 1) {
      System.enqueueJob(new DepthProbeJob(2, false));
    }
  }
}
