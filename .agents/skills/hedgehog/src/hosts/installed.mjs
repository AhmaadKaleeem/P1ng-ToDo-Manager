// Which hosts a project has Hedgehog installed for.
//
// `init` records them so `update` refreshes every host the project
// actually uses without being told again. A project installed before
// this file existed is read off the filesystem instead, by looking for
// the directories each host's payload lands in.

import { readFile, writeFile, mkdir, access } from 'node:fs/promises';
import { constants } from 'node:fs';
import { dirname, join } from 'node:path';
import { HOSTS, DEFAULT_HOST } from './index.mjs';

const HOSTS_PATH = '.hedgehog/hosts.json';

const exists = (p) =>
  access(p, constants.F_OK).then(
    () => true,
    () => false,
  );

export async function recordHosts(root, hosts) {
  const path = join(root, HOSTS_PATH);
  const known = new Set(await readRecorded(root));
  for (const h of hosts) known.add(h);
  const merged = [...known].sort();
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, `${JSON.stringify({ hosts: merged }, null, 2)}\n`);
  return merged;
}

async function readRecorded(root) {
  try {
    const { hosts } = JSON.parse(await readFile(join(root, HOSTS_PATH), 'utf8'));
    return Array.isArray(hosts) ? hosts.filter((h) => h in HOSTS) : [];
  } catch {
    return [];
  }
}

// A host counts as installed when its agents directory is on disk.
async function detectHosts(root) {
  const found = [];
  for (const [name, h] of Object.entries(HOSTS)) {
    if (await exists(join(root, h.agentsDir))) found.push(name);
  }
  return found;
}

/**
 * The hosts `update` should refresh: what `init` recorded, else what's on
 * disk, else the default.
 */
export async function installedHosts(root) {
  const recorded = await readRecorded(root);
  if (recorded.length) return recorded;
  const detected = await detectHosts(root);
  return detected.length ? detected : [DEFAULT_HOST];
}
