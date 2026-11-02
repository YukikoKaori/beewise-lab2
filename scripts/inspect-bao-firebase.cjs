// Read-only access probe. Never reads credential files or emits account/token data.
const {spawnSync} = require('node:child_process');
const {writeFileSync, mkdirSync} = require('node:fs');
const {resolve} = require('node:path');
const root = resolve(__dirname, '..');
const projectId = 'beewise-lab-3';
const result = spawnSync(process.execPath, [
  resolve(root, 'firebase/node_modules/firebase-tools/lib/bin/firebase.js'),
  'projects:list', '--project', projectId, '--json', '--non-interactive',
], {cwd: root, encoding: 'utf8', timeout: 60000});
let payload;
try { payload = JSON.parse(result.stdout); } catch { payload = {}; }
const projects = Array.isArray(payload.result) ? payload.result : [];
const found = projects.some(project => project.projectId === projectId);
const record = {
  projectId,
  timestampUtc: new Date().toISOString(),
  command: 'firebase projects:list --project beewise-lab-3 --json --non-interactive',
  nativeExitCode: result.status,
  status: result.status === 0 && found ? 'PASS' : 'BLOCKED',
  projectAccessVerified: result.status === 0 && found,
  summary: result.status === 0 ? (found ? 'Correct project is accessible.' : 'Correct project absent from accessible projects.') : 'Authenticated project listing failed; reauthenticate CLI and retry. Raw output omitted to protect account data.',
  mutations: [],
};
mkdirSync(resolve(root, 'evidence/cloud'), {recursive: true});
writeFileSync(resolve(root, 'evidence/cloud/management-access.json'), JSON.stringify(record, null, 2) + '\n');
console.log(JSON.stringify(record));
process.exitCode = record.status === 'PASS' ? 0 : 1;
