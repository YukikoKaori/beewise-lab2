// Read-only fixed-project release/index evidence; never exports user documents.
const {resolve} = require('node:path');
const {readFileSync, writeFileSync} = require('node:fs');
const {createHash} = require('node:crypto');
const root = resolve(__dirname, '..');
const base = resolve(root, 'firebase/node_modules/firebase-tools/lib');
require(resolve(base, 'logger')).logger.silent = true;
const {Client} = require(resolve(base, 'apiv2'));
const rules = require(resolve(base, 'gcp/rules'));
const firebase = require(resolve(base, 'index'));
const project = 'beewise-lab-3';
const hash = value => createHash('sha256').update(value.replace(/\r\n/g, '\n').trim()).digest('hex');
(async () => {
  const accessible = await firebase.projects.list({project, nonInteractive: true});
  if (!accessible.some(item => item.projectId === project)) throw Error('Expected project not accessible.');
  const releases = await rules.listAllReleases(project);
  const rulesetName = await rules.getLatestRulesetName(project, 'cloud.firestore', releases);
  if (!rulesetName?.startsWith(`projects/${project}/rulesets/`)) throw Error('Unexpected release.');
  const files = await rules.getRulesetContent(rulesetName);
  const deployed = files.map(file => file.content ?? '').join('\n');
  const local = readFileSync(resolve(root, 'firebase/firestore.rules'), 'utf8');
  const {body} = await new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'})
    .get(`/projects/${project}/databases/(default)/collectionGroups/-/indexes`, {timeout: 30000});
  const receipt = {timestampUtc: new Date().toISOString(), projectId: project, readOnly: true,
    rulesetName, deployedNormalizedSha256: hash(deployed), repositoryNormalizedSha256: hash(local),
    matchesRepository: hash(deployed) === hash(local),
    tutorApplicationsMatch: /match\s+\/tutorApplications\/\{[^}]+\}/.test(deployed),
    indexes: (body.indexes ?? []).map(index => ({name: index.name, state: index.state, queryScope: index.queryScope, fields: index.fields})),
    complete: !body.nextPageToken};
  writeFileSync(resolve(root, 'evidence/cloud/firestore-release-state.json'), JSON.stringify(receipt, null, 2) + '\n');
  console.log(JSON.stringify(receipt, null, 2));
})().catch(() => { console.log(JSON.stringify({status: 'BLOCKED', summary: 'Release/index inspection failed; do not deploy using stale evidence.'})); process.exitCode = 1; });
