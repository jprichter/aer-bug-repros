public with sharing class DepthProbeJob implements Queueable, Finalizer {
  private Integer step;
  private Boolean isInner;
  // When set, the Finalizer passes this MaximumQueueableStackDepth to the
  // step 2 enqueue.
  private Integer finalizerDepth;
  public DepthProbeJob(Integer step, Boolean isInner) {
    this(step, isInner, null);
  }
  public DepthProbeJob(Integer step, Boolean isInner, Integer finalizerDepth) {
    this.step = step;
    this.isInner = isInner;
    this.finalizerDepth = finalizerDepth;
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
    if (step != 1) {
      return;
    }
    try {
      if (finalizerDepth == null) {
        System.enqueueJob(new DepthProbeJob(2, false));
      } else {
        AsyncOptions options = new AsyncOptions();
        options.MaximumQueueableStackDepth = finalizerDepth;
        System.enqueueJob(new DepthProbeJob(2, false), options);
      }
    } catch (Exception ex) {
      insert as user new Account(
        Name = 'Finalizer enqueue: ' + ex.getTypeName() + ': ' + ex.getMessage()
      );
    }
  }
}
