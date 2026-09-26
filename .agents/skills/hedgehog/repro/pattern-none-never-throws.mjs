#!/usr/bin/env node
// Repro: `pattern: none` is explicitly "no enforced direction" — the
// adopted-repo default (hedgehog-adopt records exactly this for a repo
// whose owner never asked for an architecture review). It must never
// produce a finding, no matter how messy the layer graph actually is.
//
// Run: node repro/pattern-none-never-throws.mjs

import { check, finish } from './papercuts-lib.mjs';
import { validateCore } from '../src/db/core.mjs';

console.log('repro: pattern-none-never-throws');

// Deliberately messy: branching (b and c both depend_on a) *and* a
// 2-cycle disconnected from the head (x/y) — exactly the two shapes
// pattern: layered rejects. none must wave both through.
const MESSY = {
  id: 'messy',
  pattern: 'none',
  layers: [
    { id: 'a', scope: ['a/**'], verify: 'true', commit: 'feat: a' },
    { id: 'b', depends_on: 'a', scope: ['b/**'], verify: 'true', commit: 'feat: b' },
    { id: 'c', depends_on: 'a', scope: ['c/**'], verify: 'true', commit: 'feat: c' },
    { id: 'x', depends_on: 'y', scope: ['x/**'], verify: 'true', commit: 'feat: x' },
    { id: 'y', depends_on: 'x', scope: ['y/**'], verify: 'true', commit: 'feat: y' },
  ],
};

try {
  validateCore(MESSY);
  check('pattern: none never throws, even on a messy graph', true, {});
} catch (err) {
  check('pattern: none never throws, even on a messy graph', false, {
    expected: 'no error',
    actual: err.message,
  });
}

finish('pattern-none-never-throws');
