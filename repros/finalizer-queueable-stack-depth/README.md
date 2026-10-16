# Queueable stack depth for a job enqueued from a Finalizer

This project checks whether a Queueable enqueued from a Transaction Finalizer
keeps the `AsyncOptions.MaximumQueueableStackDepth` of the job that attached
the Finalizer.

Run with AER from this directory:

```sh
aer test force-app
```

## What the test does

1. The test enqueues `DepthProbeJob` (step 1) with
   `MaximumQueueableStackDepth = 100`, between `Test.startTest()` and
   `Test.stopTest()`.
2. Step 1 attaches itself as a Finalizer and tries to enqueue a child job.
3. Step 1's Finalizer enqueues step 2 (no `AsyncOptions`). Step 2 also tries
   to enqueue a child job.
4. Each step records the result of its `System.enqueueJob` call as an Account
   name.

## Results

| Runtime | Accounts after `Test.stopTest()` | Result |
| --- | --- | --- |
| Salesforce (Developer Edition scratch org, API 68.0) | `Depth step 1: enqueued`, `Depth step 2: Maximum stack depth has been reached.` | PASS |
| AER v1.4.16, v1.4.29, v1.5.8 | `Depth step 1: enqueued`, `Depth step 2: enqueued` | FAIL |

Both runtimes run the Finalizer-enqueued job during `Test.stopTest()`. They
differ only in step 2's stack-depth allowance:

- Salesforce does not carry the original job's allowance over. Step 2's
  `enqueueJob` throws
  `System.AsyncException: Maximum stack depth has been reached.`
- AER keeps the allowance, so step 2's `enqueueJob` succeeds.

Without `AsyncOptions`, the step 1 enqueue fails the same way on both
runtimes. AER does model the default test-context depth; it only gets the
Finalizer case wrong.

## Impact

Consider a service that processes work one Queueable at a time and chains the
next batch from a Finalizer, where each batch enqueues a further job. Its
tests pass in AER. In an org, the second batch's enqueue throws, its work
rolls back, and the tests fail.

## Expected behavior

In a test context, AER should not give a job enqueued from a Finalizer the
`MaximumQueueableStackDepth` of the job that attached the Finalizer. That
job's `System.enqueueJob` should throw
`AsyncException: Maximum stack depth has been reached.`, as Salesforce does.

## Open question

Untested: whether passing `AsyncOptions` with `MaximumQueueableStackDepth` to
the Finalizer's own `enqueueJob` restores the allowance on Salesforce.
