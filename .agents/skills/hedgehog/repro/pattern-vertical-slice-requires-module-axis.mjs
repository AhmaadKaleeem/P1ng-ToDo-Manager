#!/usr/bin/env node
// Repro: `pattern: vertical-slice` claims a chain instantiated per module
// — a core declaring it with no `{module}` anywhere in scope is a
// mislabel, and validateCore must reject it, naming why.
//
// Run: node repro/pattern-vertical-slice-requires-module-axis.mjs

import { check, finish } from './papercuts-lib.mjs';
import { validateCore } from '../src/db/core.mjs';

console.log('repro: pattern-vertical-slice-requires-module-axis');

// No layer's scope contains {module} — not module-axis at all.
const NOT_MODULE_AXIS = {
  id: 'not-module-axis',
  pattern: 'vertical-slice',
  layers: [
    { id: 'domain', scope: ['src/domain/**'], verify: 'true', commit: 'feat: domain' },
    {
      id: 'io',
      depends_on: 'domain',
      scope: ['src/io/**'],
      verify: 'true',
      commit: 'feat: io',
    },
  ],
};

try {
  validateCore(NOT_MODULE_AXIS);
  check('vertical-slice with no {module} throws', false, {
    expected: 'throws',
    actual: 'validated without error',
  });
} catch (err) {
  check('vertical-slice with no {module} throws', true, {});
  check('message names the offending layer or the pattern', err.message.includes('vertical-slice'), {
    expected: 'message mentioning vertical-slice',
    actual: err.message,
  });
  check('message names {module}', err.message.includes('{module}'), {
    expected: 'message mentioning {module}',
    actual: err.message,
  });
}

// A genuinely module-axis core with pattern: vertical-slice must validate
// clean — the check above must be a real check, not always-throw.
const MODULE_AXIS = {
  id: 'module-axis',
  pattern: 'vertical-slice',
  layers: [
    {
      id: 'schema',
      scope: ['libs/{module}/schema/**'],
      verify: 'true',
      commit: 'feat({module}): schema',
    },
    {
      id: 'service',
      depends_on: 'schema',
      scope: ['libs/{module}/service/**'],
      verify: 'true',
      commit: 'feat({module}): service',
    },
  ],
};

try {
  validateCore(MODULE_AXIS);
  check('vertical-slice with a real module axis validates clean', true, {});
} catch (err) {
  check('vertical-slice with a real module axis validates clean', false, {
    expected: 'no error',
    actual: err.message,
  });
}

finish('pattern-vertical-slice-requires-module-axis');
