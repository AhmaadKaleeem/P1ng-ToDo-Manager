#!/usr/bin/env node
// Repro: an unrecognized `pattern` value must throw at parse time, naming
// the valid set — never silently degrade to "unset", which would turn
// conformance checking off with no signal anything is wrong.
//
// Run: node repro/pattern-rejects-unknown-value.mjs

import { check, finish } from './papercuts-lib.mjs';
import { parseCoreYaml } from '../src/db/core.mjs';

console.log('repro: pattern-rejects-unknown-value');

const CORE = `id: demo
pattern: hexagnoal
layers:
  - id: only
    scope: ["src/**"]
    verify: "true"
    commit: "feat: only"
`;

try {
  parseCoreYaml(CORE);
  check('a typo\'d pattern value throws', false, {
    expected: 'throws',
    actual: 'parsed without error',
  });
} catch (err) {
  check('a typo\'d pattern value throws', true, {});
  check('message names the typo\'d value', err.message.includes('hexagnoal'), {
    expected: 'message containing "hexagnoal"',
    actual: err.message,
  });
  for (const valid of ['hexagonal', 'layered', 'vertical-slice', 'none']) {
    check(`message names valid value "${valid}"`, err.message.includes(valid), {
      expected: `message containing "${valid}"`,
      actual: err.message,
    });
  }
}

finish('pattern-rejects-unknown-value');
