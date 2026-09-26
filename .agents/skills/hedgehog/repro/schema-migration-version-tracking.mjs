#!/usr/bin/env node
// Repro: the build graph's schema is versioned via PRAGMA user_version.
// `hedgehog db migrate` brings a graph created by an older CLI up to the
// current schema on demand and reports what moved; a graph newer than
// this installed CLI knows about (e.g. downgraded, or shared with a
// teammate on a newer Hedgehog) fails with a plain-English message
// instead of every later query failing confusingly on a column or table
// shape this code has never heard of.
//
// Before this, a graph's schema had no version at all: the only way to
// bring an old graph's shape up to date was to open it writably and hope
// whatever command did so happened to call applySchema, and there was no
// way to tell "you're behind" from "you're ahead" — both looked like the
// same raw SQL error.

import { DatabaseSync } from 'node:sqlite';
import { join } from 'node:path';
import { makeFixture, assertIncludes, report } from './packet-lib.mjs';

const fx = makeFixture();
try {
  const dbPath = join(fx.dir, '.hedgehog/hedgehog.db');

  // A freshly-init'd fixture is already at the latest schema.
  const alreadyLatest = fx.run(['db', 'migrate']);
  console.log('--- hedgehog db migrate (already latest) ---');
  console.log(alreadyLatest);
  assertIncludes(alreadyLatest, 'already at the latest schema', 'a fresh graph reports nothing to do');

  // Roll the graph back to an unversioned (pre-migration-tracking) state
  // and drop the decisions table, simulating a graph created by an older
  // CLI that predates both.
  {
    const raw = new DatabaseSync(dbPath);
    raw.exec('PRAGMA user_version = 0');
    raw.exec('DROP TABLE IF EXISTS decisions');
    raw.close();
  }

  // Every writable-open command self-heals the schema as a side effect
  // (that's the point of the fix in #299/#301), so the very next command
  // run against this rolled-back graph — whichever it is — is what
  // actually performs the migration. `db migrate` is that first command
  // here, run immediately after the rollback, so its report reflects the
  // real transition rather than a graph some other command already
  // silently brought back up to date.
  const migrated = fx.run(['db', 'migrate']);
  console.log('--- hedgehog db migrate (from v0) ---');
  console.log(migrated);
  assertIncludes(migrated, 'Migrated', 'a behind graph reports that it migrated');
  assertIncludes(migrated, 'v0', 'the report names the version it migrated from');

  const decisionAfterMigrate = fx.run(['decision', 'add', 'CARD-DOMAIN-MODEL', 'test note']);
  console.log('--- hedgehog decision add (after migrate) ---');
  console.log(decisionAfterMigrate);
  assertIncludes(decisionAfterMigrate, 'declared', 'the decisions table exists and accepts a row after migrating');

  // Running migrate again is a no-op — it's already at CURRENT_SCHEMA_VERSION.
  const migrateAgain = fx.run(['db', 'migrate']);
  console.log('--- hedgehog db migrate (second run) ---');
  console.log(migrateAgain);
  assertIncludes(migrateAgain, 'already at the latest schema', 'migrating an up-to-date graph again is a no-op');

  // A graph newer than this CLI knows about must fail loudly and
  // legibly, not with a raw SQLite error several layers down.
  {
    const raw = new DatabaseSync(dbPath);
    raw.exec('PRAGMA user_version = 999');
    raw.close();
  }

  try {
    fx.run(['status']);
    console.error('  FAIL  `hedgehog status` did not reject a graph newer than this CLI');
    process.exit(1);
  } catch (err) {
    const output = (err.stdout ?? '') + (err.stderr ?? '');
    assertIncludes(output, 'newer version of Hedgehog', 'a too-new graph fails with a plain-English message');
  }
} finally {
  fx.cleanup();
}

report('schema-migration-version-tracking');
