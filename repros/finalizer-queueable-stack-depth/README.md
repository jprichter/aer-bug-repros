# Queueable stack depth for a job enqueued from a Finalizer

> **✅ FIXED in AER v1.4.30** (the bug was present in v1.4.16, v1.4.29 and
> v1.5.8; also passes on v1.5.9). Both tests now pass, matching Salesforce.

This project checks whether a Queueable enqueued from a Transaction Finalizer
keeps the `AsyncOptions.MaximumQueueableStackDepth` of the job that attached
the Finalizer.

Run with AER from this directory:

```sh
aer test force-app
```

## What the tests do

`finalizerChainedJobDoesNotInheritStackDepth` (the bug):

1. The test enqueues `DepthProbeJob` (step 1) with
   `MaximumQueueableStackDepth = 100`, between `Test.startTest()` and
   `Test.stopTest()`.
2. Step 1 attaches itself as a Finalizer and tries to enqueue a child job.
3. Step 1's Finalizer enqueues step 2 (no `AsyncOptions`). Step 2 also tries
   to enqueue a child job.
4. Each step records the result of its `System.enqueueJob` call as an Account
   name.

`finalizerPassingStackDepthRestoresAllowance` (the workaround): the same
flow, except that the Finalizer passes its own `AsyncOptions` with
`MaximumQueueableStackDepth = 100` when it enqueues step 2.

## Results

| Test | Salesforce (Developer Edition scratch org, API 68.0) | AER v1.4.16, v1.4.29, v1.5.8 | AER v1.5.9 |
| --- | --- | --- | --- |
| `finalizerChainedJobDoesNotInheritStackDepth` | PASS: `Depth step 1: enqueued`, `Depth step 2: Maximum stack depth has been reached.` | FAIL: `Depth step 1: enqueued`, `Depth step 2: enqueued` | **PASS** (fixed) |
| `finalizerPassingStackDepthRestoresAllowance` | PASS: `Depth step 1: enqueued`, `Depth step 2: enqueued` | PASS: same | PASS |

Both runtimes run the Finalizer-enqueued job during `Test.stopTest()`. In the
first test they differ only in step 2's stack-depth allowance:

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

## Workaround

On Salesforce, a Finalizer can give the job it enqueues its own allowance by
passing `AsyncOptions` with `MaximumQueueableStackDepth` to
`System.enqueueJob`. The second test shows this: step 2's child enqueue then
succeeds on Salesforce, and on AER too. Code that does this behaves the same
on both runtimes.
