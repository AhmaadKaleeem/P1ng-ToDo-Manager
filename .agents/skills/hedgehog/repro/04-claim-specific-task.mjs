#!/usr/bin/env node
// Gap 4: there was no way to claim a specific task by id — only the
// batch fan-out, which picks candidates by (priority, exclusive DESC,
// id) and cannot be steered toward one in particular.
//
// The scheduler now claims an exclusive task ahead of same-priority
// non-exclusive ones, so EXCLUSIVE_CORE's ALPHA-ZINTEGRATE no longer
// starves — the batch claims it directly. What a targeted claim still
// adds: claiming ALPHA-ZINTEGRATE specifically without also claiming
// everything else the batch would hand out, and refusing (rather than
// silently skipping) when the requested task genuinely conflicts with
// work already in flight.

import { makeProject, EXCLUSIVE_CORE, hedgehog, hedgehogAllowFail, readTask, assert, assertIncludes, runRepro } from './lib.mjs';

await runRepro('claim a specific task without claiming the whole batch', async () => {
  const { dir, dbPath, cleanup } = await makeProject({
    core: EXCLUSIVE_CORE,
    intents: ['alpha', 'beta'],
  });
  try {
    // The exclusive task is ready and unleased...
    const ready = hedgehog(dir, ['ready']);
    assertIncludes(ready.out, 'ALPHA-ZINTEGRATE', 'the exclusive task should be in the ready set');

    // A targeted claim gets exactly that task, not the rest of the ready set.
    const targeted = hedgehog(dir, ['claim', 'ALPHA-ZINTEGRATE', '--owner', 'ag2']);
    assertIncludes(targeted.out, 'Claimed', 'the targeted claim should succeed');
    assertIncludes(targeted.out, 'ALLOWED SCOPE', 'the targeted claim should print the packet');

    const claimed = readTask(dbPath, 'ALPHA-ZINTEGRATE');
    assert(claimed.status === 'building', `expected building, got ${claimed.status}`);
    assert(claimed.lease_owner === 'ag2', `expected lease to ag2, got ${claimed.lease_owner}`);
    assert(claimed.lease_expires_at !== null, 'a building task must carry a lease expiry');
    assert(
      readTask(dbPath, 'ALPHA-SCHEMA').status !== 'building',
      'the targeted claim must not also claim other ready tasks',
    );

    // A batch claim now refuses to hand out anything that conflicts with
    // the exclusive task already in flight — that is the invariant a
    // targeted claim must not be allowed to bypass.
    const refused = hedgehogAllowFail(dir, ['claim', 'ALPHA-SCHEMA', '--owner', 'ag1']);
    assert(refused.code !== 0, 'a conflicting targeted claim must exit non-zero');
    assertIncludes(refused.out, 'conflicts with work in flight', 'it should name the conflict');
    assertIncludes(refused.out, 'ALPHA-ZINTEGRATE', 'it should name the in-flight task');

    // The other refusals: already leased, and an unknown id.
    const twice = hedgehogAllowFail(dir, ['claim', 'ALPHA-ZINTEGRATE', '--owner', 'ag4']);
    assert(twice.code !== 0, 'claiming an already-leased task must exit non-zero');
    assertIncludes(twice.out, 'Not claimable', 'it should refuse a leased task');

    const missing = hedgehogAllowFail(dir, ['claim', 'NO-SUCH-TASK', '--owner', 'ag2']);
    assert(missing.code !== 0, 'claiming an unknown id must exit non-zero');
    assertIncludes(missing.out, 'No such task', 'it should say the id matched nothing');
  } finally {
    await cleanup();
  }
});

// The dependency refusal needs the default (chained) core.
await runRepro('a targeted claim refuses a task whose dependencies are open', async () => {
  const { dir, cleanup } = await makeProject();
  try {
    const refused = hedgehogAllowFail(dir, ['claim', 'ALPHA-SERVICE', '--owner', 'ag1']);
    assert(refused.code !== 0, 'a targeted claim must not bypass dependency order');
    assertIncludes(refused.out, 'waiting on', 'it should say what the task waits on');
    assertIncludes(refused.out, 'ALPHA-SCHEMA', 'it should name the open dependency');
  } finally {
    await cleanup();
  }
});
